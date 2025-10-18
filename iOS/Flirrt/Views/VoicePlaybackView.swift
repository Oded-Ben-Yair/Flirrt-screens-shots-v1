//
//  VoicePlaybackView.swift
//  Vibe8
//
//  Voice cloning UI with audio playback
//  Based on GPT-4O and Grok-4 best practices
//

import SwiftUI
import AVFoundation

// MARK: - Audio Player Manager

class AudioPlayerManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var isLoading = false
    @Published var error: String?
    
    private var player: AVAudioPlayer?
    private var timer: Timer?
    
    func playAudio(from url: URL) {
        isLoading = true
        error = nil
        
        // Download audio if remote URL
        if url.scheme == "http" || url.scheme == "https" {
            downloadAndPlay(url: url)
        } else {
            playLocal(url: url)
        }
    }
    
    private func downloadAndPlay(url: URL) {
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.error = error.localizedDescription
                    return
                }
                
                guard let data = data else {
                    self?.error = "No audio data received"
                    return
                }
                
                self?.playAudioData(data)
            }
        }.resume()
    }
    
    private func playLocal(url: URL) {
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = self
            setupPlayer()
            player?.play()
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }
    
    private func playAudioData(_ data: Data) {
        do {
            player = try AVAudioPlayer(data: data)
            player?.delegate = self
            setupPlayer()
            player?.play()
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    private func setupPlayer() {
        guard let player = player else { return }
        
        duration = player.duration
        isPlaying = true
        isLoading = false
        
        // Start timer for progress updates
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.currentTime = player.currentTime
        }
    }
    
    func pause() {
        player?.pause()
        isPlaying = false
        timer?.invalidate()
    }
    
    func resume() {
        player?.play()
        isPlaying = true
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.player else { return }
            self.currentTime = player.currentTime
        }
    }
    
    func stop() {
        player?.stop()
        player?.currentTime = 0
        isPlaying = false
        currentTime = 0
        timer?.invalidate()
    }
    
    func seek(to time: TimeInterval) {
        player?.currentTime = time
        currentTime = time
    }
    
    // MARK: - AVAudioPlayerDelegate
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isPlaying = false
            self.currentTime = 0
            self.timer?.invalidate()
        }
    }
}

// MARK: - Voice Playback View

struct VoicePlaybackView: View {
    let message: String
    @StateObject private var audioPlayer = AudioPlayerManager()
    @EnvironmentObject private var apiClient: APIClient
    @State private var isGenerating = false
    @State private var audioURL: URL?
    @State private var showError = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "waveform")
                    .foregroundColor(.pink)
                Text("Voice Message")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }
            
            // Audio player UI
            if let _ = audioURL {
                audioPlayerUI
            } else if isGenerating {
                generatingView
            } else {
                generateButton
            }
            
            // Error message
            if let error = audioPlayer.error {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.15))
        .cornerRadius(12)
    }
    
    private var generateButton: some View {
        Button {
            generateVoice()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "mic.fill")
                Text("Generate Voice Message")
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.pink.opacity(0.2))
            .foregroundColor(.pink)
            .cornerRadius(10)
        }
    }
    
    private var generatingView: some View {
        HStack(spacing: 12) {
            ProgressView()
                .tint(.pink)
            Text("Generating voice...")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
    
    private var audioPlayerUI: some View {
        VStack(spacing: 12) {
            // Waveform visualization (simplified)
            waveformView
            
            // Progress slider
            VStack(spacing: 4) {
                Slider(
                    value: Binding(
                        get: { audioPlayer.currentTime },
                        set: { audioPlayer.seek(to: $0) }
                    ),
                    in: 0...max(audioPlayer.duration, 0.1)
                )
                .tint(.pink)
                
                HStack {
                    Text(timeString(audioPlayer.currentTime))
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                    Text(timeString(audioPlayer.duration))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            // Playback controls
            HStack(spacing: 24) {
                // Rewind 10s
                Button {
                    audioPlayer.seek(to: max(0, audioPlayer.currentTime - 10))
                } label: {
                    Image(systemName: "gobackward.10")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                
                // Play/Pause
                Button {
                    if audioPlayer.isPlaying {
                        audioPlayer.pause()
                    } else if audioPlayer.currentTime > 0 {
                        audioPlayer.resume()
                    } else if let url = audioURL {
                        audioPlayer.playAudio(from: url)
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.pink)
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: audioPlayer.isPlaying ? "pause.fill" : "play.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
                
                // Forward 10s
                Button {
                    audioPlayer.seek(to: min(audioPlayer.duration, audioPlayer.currentTime + 10))
                } label: {
                    Image(systemName: "goforward.10")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    private var waveformView: some View {
        HStack(spacing: 2) {
            ForEach(0..<40) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.pink.opacity(waveformOpacity(for: index)))
                    .frame(width: 3, height: waveformHeight(for: index))
            }
        }
        .frame(height: 40)
    }
    
    private func waveformOpacity(for index: Int) -> Double {
        let progress = audioPlayer.duration > 0 ? audioPlayer.currentTime / audioPlayer.duration : 0
        let barProgress = Double(index) / 40.0
        return barProgress <= progress ? 1.0 : 0.3
    }
    
    private func waveformHeight(for index: Int) -> CGFloat {
        // Simulate waveform pattern
        let pattern: [CGFloat] = [10, 25, 35, 30, 20, 15, 30, 40, 35, 25]
        return pattern[index % pattern.count]
    }
    
    private func timeString(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func generateVoice() {
        isGenerating = true
        
        Task {
            do {
                let response = try await apiClient.synthesizeVoice(text: message)
                
                await MainActor.run {
                    isGenerating = false
                    audioURL = response.audioURL
                    
                    // Auto-play after generation
                    if let url = response.audioURL {
                        audioPlayer.playAudio(from: url)
                    }
                }
            } catch {
                await MainActor.run {
                    isGenerating = false
                    audioPlayer.error = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Voice Button for Suggestion Card

struct VoiceButton: View {
    let message: String
    @State private var showVoicePlayer = false
    
    var body: some View {
        Button {
            showVoicePlayer = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "waveform")
                Text("Voice")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.purple.opacity(0.2))
            .foregroundColor(.purple)
            .cornerRadius(8)
        }
        .sheet(isPresented: $showVoicePlayer) {
            NavigationView {
                VoicePlaybackView(message: message)
                    .navigationTitle("Voice Message")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showVoicePlayer = false
                            }
                        }
                    }
            }
        }
    }
}

// MARK: - Preview

struct VoicePlaybackView_Previews: PreviewProvider {
    static var previews: some View {
        VoicePlaybackView(message: "Hey there! Want to grab coffee this weekend?")
            .environmentObject(APIClient())
            .preferredColorScheme(.dark)
    }
}

