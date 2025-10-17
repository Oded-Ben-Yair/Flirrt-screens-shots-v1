import SwiftUI

@MainActor
struct BackgroundNoisePickerView: View {
    @State private var selectedNoise: BackgroundNoise?
    @State private var isPlaying = false
    @State private var volume: Double = 0.5
    @State private var showingCustomNoise = false
    @Namespace private var noiseAnimation

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "waveform.path.ecg.rectangle")
                            .font(.system(size: 48))
                            .foregroundColor(.pink)

                        Text("Background Noise")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Choose ambient sounds to enhance your voice recording")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top)

                    // Volume Control
                    if selectedNoise != nil {
                        VolumeControlSection(volume: $volume, isPlaying: $isPlaying)
                            .transition(.scale.combined(with: .opacity))
                    }

                    // None/Silence Option
                    NoiseCard(
                        noise: nil,
                        isSelected: selectedNoise == nil,
                        onSelect: {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                selectedNoise = nil
                                isPlaying = false
                            }
                        }
                    )
                    .matchedGeometryEffect(id: "none", in: noiseAnimation)

                    // Predefined Noise Options
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 150), spacing: 16)
                    ], spacing: 16) {
                        ForEach(BackgroundNoise.predefinedNoises) { noise in
                            NoiseCard(
                                noise: noise,
                                isSelected: selectedNoise?.id == noise.id,
                                onSelect: {
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                        selectedNoise = noise
                                        isPlaying = true
                                    }
                                }
                            )
                            .matchedGeometryEffect(id: noise.id, in: noiseAnimation)
                        }
                    }

                    // Custom Noise Option
                    CustomNoiseCard {
                        showingCustomNoise = true
                    }

                    Spacer(minLength: 20)
                }
                .padding(.horizontal)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        // Handle completion
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .sheet(isPresented: $showingCustomNoise) {
            CustomNoiseImportView()
        }
    }
}

@MainActor
struct VolumeControlSection: View {
    @Binding var volume: Double
    @Binding var isPlaying: Bool

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Volume")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isPlaying.toggle()
                    }
                }) {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.title)
                        .foregroundColor(.pink)
                        .scaleEffect(isPlaying ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: isPlaying)
                }
            }

            HStack {
                Image(systemName: "speaker.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Slider(value: $volume, in: 0...1) {
                    Text("Volume")
                }
                .accentColor(.pink)

                Image(systemName: "speaker.wave.3.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(String(format: "%.0f%%", volume * 100))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(20)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

@MainActor
struct NoiseCard: View {
    let noise: BackgroundNoise?
    let isSelected: Bool
    let onSelect: () -> Void
    @State private var isAnimating = false

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 12) {
                // Icon with animation
                ZStack {
                    Circle()
                        .fill(backgroundColor)
                        .frame(width: 60, height: 60)

                    if isSelected && noise != nil {
                        // Animated waves for selected noise
                        ForEach(0..<3) { index in
                            Circle()
                                .stroke(iconColor.opacity(0.3), lineWidth: 2)
                                .frame(width: CGFloat(60 + index * 20))
                                .scaleEffect(isAnimating ? 1.5 : 0.8)
                                .opacity(isAnimating ? 0 : 1)
                                .animation(
                                    .easeInOut(duration: 1.5)
                                    .delay(Double(index) * 0.2)
                                    .repeatForever(autoreverses: false),
                                    value: isAnimating
                                )
                        }
                    }

                    Image(systemName: iconName)
                        .font(.title2)
                        .foregroundColor(iconColor)
                        .scaleEffect(isSelected ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
                }

                VStack(spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    if let description = description {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? iconColor : Color.clear, lineWidth: 2)
                    )
                    .shadow(
                        color: .black.opacity(isSelected ? 0.1 : 0.05),
                        radius: isSelected ? 12 : 8,
                        x: 0,
                        y: isSelected ? 6 : 4
                    )
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            if isSelected && noise != nil {
                isAnimating = true
            }
        }
        .onChange(of: isSelected) { selected in
            withAnimation {
                isAnimating = selected && noise != nil
            }
        }
    }

    private var title: String {
        noise?.name ?? "Silence"
    }

    private var description: String? {
        noise?.description ?? "No background noise"
    }

    private var iconName: String {
        noise?.icon ?? "speaker.slash"
    }

    private var iconColor: Color {
        if let noise = noise {
            return Color(noise.category.color)
        }
        return .gray
    }

    private var backgroundColor: Color {
        if let noise = noise {
            return Color(noise.category.color).opacity(0.2)
        }
        return Color.gray.opacity(0.2)
    }
}

@MainActor
struct CustomNoiseCard: View {
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 60, height: 60)

                    Image(systemName: "plus.circle")
                        .font(.title2)
                        .foregroundColor(.blue)
                }

                VStack(spacing: 4) {
                    Text("Custom Noise")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Text("Import your own audio")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

@MainActor
struct CustomNoiseImportView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Image(systemName: "folder.badge.plus")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)

                VStack(spacing: 12) {
                    Text("Import Custom Audio")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Choose an audio file from your device to use as background noise")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                VStack(spacing: 16) {
                    Button("Browse Files") {
                        // Handle file import
                    }
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .cornerRadius(12)

                    Button("Record New Audio") {
                        // Handle recording
                    }
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding()
            .navigationTitle("Custom Audio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Background Noise Model
struct BackgroundNoise: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let category: NoiseCategory
    let icon: String
    let audioFileName: String
    let duration: TimeInterval?
    let isLooping: Bool

    init(id: String = UUID().uuidString, name: String, description: String, category: NoiseCategory, icon: String, audioFileName: String, duration: TimeInterval? = nil, isLooping: Bool = true) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.icon = icon
        self.audioFileName = audioFileName
        self.duration = duration
        self.isLooping = isLooping
    }
}

enum NoiseCategory: String, CaseIterable, Codable {
    case nature = "nature"
    case urban = "urban"
    case cafe = "cafe"
    case white = "white"
    case music = "music"

    var displayName: String {
        switch self {
        case .nature:
            return "Nature"
        case .urban:
            return "Urban"
        case .cafe:
            return "Café"
        case .white:
            return "White Noise"
        case .music:
            return "Ambient Music"
        }
    }

    var color: String {
        switch self {
        case .nature:
            return "green"
        case .urban:
            return "gray"
        case .cafe:
            return "brown"
        case .white:
            return "purple"
        case .music:
            return "orange"
        }
    }
}

extension BackgroundNoise {
    static let predefinedNoises: [BackgroundNoise] = [
        BackgroundNoise(
            name: "Rain",
            description: "Gentle rainfall sounds",
            category: .nature,
            icon: "cloud.rain",
            audioFileName: "rain_gentle.mp3"
        ),

        BackgroundNoise(
            name: "Ocean Waves",
            description: "Calming ocean waves",
            category: .nature,
            icon: "water.waves",
            audioFileName: "ocean_waves.mp3"
        ),

        BackgroundNoise(
            name: "Forest Birds",
            description: "Morning bird songs",
            category: .nature,
            icon: "leaf",
            audioFileName: "forest_birds.mp3"
        ),

        BackgroundNoise(
            name: "Coffee Shop",
            description: "Busy café ambience",
            category: .cafe,
            icon: "cup.and.saucer",
            audioFileName: "coffee_shop.mp3"
        ),

        BackgroundNoise(
            name: "City Traffic",
            description: "Urban street sounds",
            category: .urban,
            icon: "car",
            audioFileName: "city_traffic.mp3"
        ),

        BackgroundNoise(
            name: "White Noise",
            description: "Pure white noise",
            category: .white,
            icon: "waveform",
            audioFileName: "white_noise.mp3"
        ),

        BackgroundNoise(
            name: "Pink Noise",
            description: "Softer frequency balance",
            category: .white,
            icon: "waveform.path",
            audioFileName: "pink_noise.mp3"
        ),

        BackgroundNoise(
            name: "Jazz Club",
            description: "Smooth jazz atmosphere",
            category: .music,
            icon: "music.note",
            audioFileName: "jazz_club.mp3"
        )
    ]
}

// MARK: - Preview
struct BackgroundNoisePickerView_Previews: PreviewProvider {
    static var previews: some View {
        BackgroundNoisePickerView()
            .preferredColorScheme(.dark)

        BackgroundNoisePickerView()
            .preferredColorScheme(.light)
    }
}