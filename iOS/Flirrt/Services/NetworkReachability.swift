import Foundation
import Network
import Combine

class NetworkReachability: ObservableObject {
    static let shared = NetworkReachability()

    @Published var isConnected: Bool = true
    @Published var connectionType: ConnectionType = .unknown
    @Published var isExpensive: Bool = false
    @Published var isConstrained: Bool = false

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkReachability", qos: .background)
    private var cancellables = Set<AnyCancellable>()

    enum ConnectionType: String {
        case wifi = "Wi-Fi"
        case cellular = "Cellular"
        case ethernet = "Ethernet"
        case unknown = "Unknown"
        case none = "No Connection"

        var icon: String {
            switch self {
            case .wifi:
                return "wifi"
            case .cellular:
                return "cellularbars"
            case .ethernet:
                return "cable.coaxial"
            case .unknown:
                return "questionmark.circle"
            case .none:
                return "wifi.slash"
            }
        }
    }

    private init() {
        startMonitoring()
    }

    deinit {
        stopMonitoring()
    }

    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.updateConnectionStatus(path)
            }
        }
        monitor.start(queue: queue)
    }

    func stopMonitoring() {
        monitor.cancel()
    }

    private func updateConnectionStatus(_ path: NWPath) {
        isConnected = path.status == .satisfied
        isExpensive = path.isExpensive
        isConstrained = path.isConstrained

        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .ethernet
        } else if path.status == .satisfied {
            connectionType = .unknown
        } else {
            connectionType = .none
        }

        // Log connection changes
        print("Network status: \(connectionType.rawValue), Connected: \(isConnected)")

        // Post notification for other parts of the app
        NotificationCenter.default.post(
            name: .networkStatusChanged,
            object: nil,
            userInfo: [
                "isConnected": isConnected,
                "connectionType": connectionType.rawValue
            ]
        )
    }

    func checkConnectivity() -> Bool {
        return isConnected
    }

    func waitForConnection() async -> Bool {
        if isConnected {
            return true
        }

        // Wait up to 10 seconds for connection
        for _ in 0..<20 {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            if isConnected {
                return true
            }
        }
        return false
    }

    // Check if we can reach a specific host
    func canReachHost(_ host: String = "api.vibe8.ai", port: Int = 443) async -> Bool {
        return await withCheckedContinuation { continuation in
            let host = NWEndpoint.Host(host)
            let port = NWEndpoint.Port(integerLiteral: UInt16(port))

            let connection = NWConnection(host: host, port: port, using: .tcp)

            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    connection.cancel()
                    continuation.resume(returning: true)
                case .failed(_), .cancelled:
                    continuation.resume(returning: false)
                default:
                    break
                }
            }

            connection.start(queue: queue)

            // Timeout after 5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                connection.cancel()
                continuation.resume(returning: false)
            }
        }
    }

    // Check if API is reachable
    func checkAPIReachability() async -> Bool {
        guard isConnected else { return false }

        // Try to reach the backend API
        let apiURL = URL(string: "\(AppConstants.apiBaseURL.replacingOccurrences(of: "/api/v1", with: ""))/health")!
        var request = URLRequest(url: apiURL)
        request.httpMethod = "GET"
        request.timeoutInterval = 5

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode == 200
            }
        } catch {
            print("API reachability check failed: \(error)")
        }

        return false
    }

    // Show network alert if needed
    func showNetworkAlert(in viewController: UIViewController?) {
        guard !isConnected else { return }

        let alert = UIAlertController(
            title: "No Internet Connection",
            message: "Please check your network settings and try again.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })

        alert.addAction(UIAlertAction(title: "OK", style: .cancel))

        viewController?.present(alert, animated: true)
    }
}

// MARK: - Notification Extension
extension Notification.Name {
    static let networkStatusChanged = Notification.Name("networkStatusChanged")
}

// MARK: - View Modifier for Network Status
import SwiftUI

struct NetworkAwareModifier: ViewModifier {
    @ObservedObject private var reachability = NetworkReachability.shared
    let showBanner: Bool

    func body(content: Content) -> some View {
        ZStack {
            content

            if showBanner && !reachability.isConnected {
                VStack {
                    NetworkStatusBanner()
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.easeInOut, value: reachability.isConnected)
            }
        }
    }
}

struct NetworkStatusBanner: View {
    @ObservedObject private var reachability = NetworkReachability.shared

    var body: some View {
        HStack {
            Image(systemName: reachability.connectionType.icon)
                .foregroundColor(.white)

            Text(reachability.isConnected ? "Connected" : "No Connection")
                .font(.caption)
                .foregroundColor(.white)

            if reachability.isExpensive {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundColor(.yellow)
                    .font(.caption)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(reachability.isConnected ? Color.green : Color.red)
        .cornerRadius(20)
        .shadow(radius: 2)
        .padding(.top, 50)
    }
}

extension View {
    func networkAware(showBanner: Bool = true) -> some View {
        modifier(NetworkAwareModifier(showBanner: showBanner))
    }
}

// MARK: - API Request Helper
extension NetworkReachability {
    func performAPIRequest<T: Decodable>(
        _ request: URLRequest,
        retryCount: Int = 3
    ) async throws -> T {
        guard isConnected else {
            throw NetworkError.noConnection
        }

        var lastError: Error?

        for attempt in 0..<retryCount {
            do {
                let (data, response) = try await URLSession.shared.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }

                guard (200...299).contains(httpResponse.statusCode) else {
                    throw NetworkError.httpError(httpResponse.statusCode)
                }

                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode(T.self, from: data)

            } catch {
                lastError = error
                if attempt < retryCount - 1 {
                    // Wait before retry
                    try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(attempt))) * 1_000_000_000)
                }
            }
        }

        throw lastError ?? NetworkError.unknown
    }
}

enum NetworkError: LocalizedError {
    case noConnection
    case invalidResponse
    case httpError(Int)
    case unknown

    var errorDescription: String? {
        switch self {
        case .noConnection:
            return "No internet connection available"
        case .invalidResponse:
            return "Invalid server response"
        case .httpError(let code):
            return "Server error: \(code)"
        case .unknown:
            return "An unknown network error occurred"
        }
    }
}