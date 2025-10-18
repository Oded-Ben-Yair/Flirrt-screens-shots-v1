//
//  ModernOnboardingView.swift
//  Vibe8
//
//  Modern onboarding flow with interactive demos
//  Based on Grok-4 UX recommendations
//

import SwiftUI

struct ModernOnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0
    @State private var showingMainApp = false
    
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "sparkles.rectangle.stack",
            title: "AI-Powered Flirting",
            subtitle: "Get personalized, spicy suggestions that actually work",
            color: .pink,
            animation: "hero"
        ),
        OnboardingPage(
            icon: "photo.stack",
            title: "Analyze Screenshots",
            subtitle: "Upload 1-3 chat or profile screenshots for instant tips",
            color: .purple,
            animation: "screenshots"
        ),
        OnboardingPage(
            icon: "lightbulb.fill",
            title: "AI Coaching",
            subtitle: "Learn why each suggestion works and level up your game",
            color: .yellow,
            animation: "coaching"
        ),
        OnboardingPage(
            icon: "waveform",
            title: "Voice Messages",
            subtitle: "Turn your flirts into natural-sounding voice messages",
            color: .blue,
            animation: "voice"
        ),
        OnboardingPage(
            icon: "flame.fill",
            title: "Ready to Vibe?",
            subtitle: "Let's boost your dating confidence in seconds",
            color: .orange,
            animation: "ready"
        )
    ]
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.black, Color(hex: "1a1a1a")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button("Skip") {
                            completeOnboarding()
                        }
                        .foregroundColor(.gray)
                        .padding()
                    }
                }
                
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(pages.indices, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)
                
                // Page indicator
                HStack(spacing: 8) {
                    ForEach(pages.indices, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? pages[index].color : Color.gray.opacity(0.3))
                            .frame(width: currentPage == index ? 10 : 8, height: currentPage == index ? 10 : 8)
                            .animation(.spring(), value: currentPage)
                    }
                }
                .padding(.bottom, 20)
                
                // Action button
                Button {
                    if currentPage < pages.count - 1 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        completeOnboarding()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text(currentPage < pages.count - 1 ? "Continue" : "Get Started")
                            .fontWeight(.semibold)
                        Image(systemName: currentPage < pages.count - 1 ? "arrow.right" : "checkmark")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [pages[currentPage].color, pages[currentPage].color.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
        }
        .fullScreenCover(isPresented: $showingMainApp) {
            ContentView()
        }
    }
    
    private func completeOnboarding() {
        hasCompletedOnboarding = true
        showingMainApp = true
    }
}

// MARK: - Onboarding Page Model

struct OnboardingPage {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let animation: String
}

// MARK: - Onboarding Page View

struct OnboardingPageView: View {
    let page: OnboardingPage
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Animated icon
            ZStack {
                Circle()
                    .fill(page.color.opacity(0.2))
                    .frame(width: 200, height: 200)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 2.0)
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
                
                Image(systemName: page.icon)
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [page.color, page.color.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(isAnimating ? 1.0 : 0.9)
                    .animation(
                        Animation.easeInOut(duration: 2.0)
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
            }
            
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(page.subtitle)
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            // Interactive demo based on page
            if page.animation == "screenshots" {
                screenshotDemo
            } else if page.animation == "coaching" {
                coachingDemo
            }
            
            Spacer()
        }
        .onAppear {
            isAnimating = true
        }
    }
    
    private var screenshotDemo: some View {
        HStack(spacing: 12) {
            ForEach(0..<3) { index in
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 120)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(page.color, lineWidth: 2)
                    )
            }
        }
    }
    
    private var coachingDemo: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Why This Works")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.yellow)
            }
            
            Text("This suggestion builds intrigue and shows genuine interest in their hobbies")
                .font(.caption)
                .foregroundColor(.gray)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
        }
        .padding(.horizontal, 40)
    }
}

// MARK: - Tone Button Component

struct ToneButton: View {
    let emoji: String
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(emoji)
                    .font(.title2)
                Text(label)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .frame(width: 80, height: 80)
            .background(
                isSelected ?
                LinearGradient(
                    colors: [.pink, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ) :
                LinearGradient(
                    colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.pink : Color.clear, lineWidth: 2)
            )
        }
    }
}

// MARK: - Preview

struct ModernOnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        ModernOnboardingView()
    }
}

