import SwiftUI

@main
struct BackgroundNoiseAnimationDemoApp: App {
    var body: some Scene {
        WindowGroup {
            BackgroundNoiseAnimationDemo()
                .preferredColorScheme(.dark)
        }
    }
}

struct BackgroundNoiseAnimationDemo: View {
    @State private var currentStep = 0
    @State private var timer: Timer?

    let steps = [
        "Initial State",
        "Select Rain",
        "Volume Control Appears",
        "Select Ocean Waves",
        "Select White Noise",
        "Deselect to Silence",
        "Select Coffee Shop",
        "Show Custom Import"
    ]

    var body: some View {
        TabView(selection: $currentStep) {
            // Step 0: Initial State
            BackgroundNoisePickerView()
                .tabItem {
                    Text("Initial")
                }
                .tag(0)

            // Step 1-7: Different states
            ForEach(1..<steps.count, id: \.self) { step in
                BackgroundNoisePickerViewWithState(step: step)
                    .tabItem {
                        Text("Step \(step)")
                    }
                    .tag(step)
            }
        }
        .overlay(alignment: .top) {
            VStack {
                Text("Background Noise Animation Demo")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, 60)

                Text(steps[currentStep])
                    .font(.headline)
                    .foregroundColor(.pink)
                    .padding(.top, 4)

                HStack(spacing: 4) {
                    ForEach(0..<steps.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentStep ? Color.pink : Color.gray)
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut(duration: 0.3), value: currentStep)
                    }
                }
                .padding(.top, 8)
            }
            .padding()
            .background(Color.black.opacity(0.3))
            .cornerRadius(16)
            .padding()
        }
        .onAppear {
            startAutoPlay()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    private func startAutoPlay() {
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                currentStep = (currentStep + 1) % steps.count
            }
        }
    }
}

struct BackgroundNoisePickerViewWithState: View {
    let step: Int
    @State private var selectedNoise: BackgroundNoise?
    @State private var isPlaying = false
    @State private var volume: Double = 0.5
    @State private var showingCustomNoise = false

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
                    NoiseCardDemo(
                        noise: nil,
                        isSelected: selectedNoise == nil,
                        step: step
                    ) {
                        selectedNoise = nil
                        isPlaying = false
                    }

                    // Predefined Noise Options
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 150), spacing: 16)
                    ], spacing: 16) {
                        ForEach(Array(BackgroundNoise.predefinedNoises.enumerated()), id: \.element.id) { index, noise in
                            NoiseCardDemo(
                                noise: noise,
                                isSelected: shouldBeSelected(noise: noise, index: index),
                                step: step
                            ) {
                                selectedNoise = noise
                                isPlaying = true
                            }
                        }
                    }

                    // Custom Noise Option
                    CustomNoiseCard {
                        showingCustomNoise = true
                    }
                    .opacity(step == 7 ? 1.0 : 0.7)
                    .scaleEffect(step == 7 ? 1.1 : 1.0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: step)

                    Spacer(minLength: 20)
                }
                .padding(.horizontal)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            updateStateForStep()
        }
        .onChange(of: step) { _ in
            updateStateForStep()
        }
        .sheet(isPresented: $showingCustomNoise) {
            CustomNoiseImportView()
        }
    }

    private func shouldBeSelected(noise: BackgroundNoise, index: Int) -> Bool {
        switch step {
        case 1: return noise.name == "Rain"
        case 3: return noise.name == "Ocean Waves"
        case 4: return noise.name == "White Noise"
        case 6: return noise.name == "Coffee Shop"
        default: return false
        }
    }

    private func updateStateForStep() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            switch step {
            case 1:
                selectedNoise = BackgroundNoise.predefinedNoises.first { $0.name == "Rain" }
                isPlaying = true
            case 2:
                // Keep Rain selected, show volume control
                selectedNoise = BackgroundNoise.predefinedNoises.first { $0.name == "Rain" }
                isPlaying = true
            case 3:
                selectedNoise = BackgroundNoise.predefinedNoises.first { $0.name == "Ocean Waves" }
                isPlaying = true
            case 4:
                selectedNoise = BackgroundNoise.predefinedNoises.first { $0.name == "White Noise" }
                isPlaying = true
            case 5:
                selectedNoise = nil
                isPlaying = false
            case 6:
                selectedNoise = BackgroundNoise.predefinedNoises.first { $0.name == "Coffee Shop" }
                isPlaying = true
            case 7:
                // Show custom import highlight
                selectedNoise = BackgroundNoise.predefinedNoises.first { $0.name == "Coffee Shop" }
                isPlaying = true
                showingCustomNoise = true
            default:
                selectedNoise = nil
                isPlaying = false
            }
        }
    }
}

struct NoiseCardDemo: View {
    let noise: BackgroundNoise?
    let isSelected: Bool
    let step: Int
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

struct BackgroundNoiseAnimationDemo_Previews: PreviewProvider {
    static var previews: some View {
        BackgroundNoiseAnimationDemo()
            .preferredColorScheme(.dark)
    }
}