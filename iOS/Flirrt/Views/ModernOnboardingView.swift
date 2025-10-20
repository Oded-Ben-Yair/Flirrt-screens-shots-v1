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
            icon: "keyboard",
            title: "Enable Flirrt Keyboard",
            subtitle: "Go to Settings → General → Keyboard → Add Flirrt",
            color: .pink,
            animation: "keyboard"
        ),
        OnboardingPage(
            icon: "camera.viewfinder",
            title: "Take a Screenshot",
            subtitle: "Open Tinder/Bumble and screenshot your chat",
            color: .purple,
            animation: "screenshot"
        ),
        OnboardingPage(
            icon: "sparkles",
            title: "AI Analyzes Instantly",
            subtitle: "Flirrt's AI reads the screenshot and generates perfect replies",
            color: .blue,
            animation: "ai"
        ),
        OnboardingPage(
            icon: "hand.tap.fill",
            title: "Tap to Insert",
            subtitle: "Switch to Flirrt keyboard and tap any suggestion",
            color: .yellow,
            animation: "tap"
        ),
        OnboardingPage(
            icon: "heart.fill",
            title: "Start Getting Dates!",
            subtitle: "Your AI wingman works automatically in the background",
            color: .orange,
            animation: "ready"
        )
    ]
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.black, Color.black.opacity(0.9)],
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
            if page.animation == "keyboard" {
                keyboardDemo
            } else if page.animation == "tap" {
                tapDemo
            }
            
            Spacer()
        }
        .onAppear {
            isAnimating = true
        }
    }
    
    private var keyboardDemo: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "gearshape.fill")
                    .foregroundColor(.gray)
                Text("Settings → General → Keyboard")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
                .frame(height: 50)
                .overlay(
                    HStack {
                        Image(systemName: "keyboard")
                            .foregroundColor(.pink)
                        Text("Flirrt Keyboard")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                    .padding(.horizontal)
                )
        }
        .padding(.horizontal, 40)
    }

    private var tapDemo: some View {
        VStack(spacing: 12) {
            // Mock keyboard suggestion
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.pink.opacity(0.2))
                .frame(height: 60)
                .overlay(
                    VStack(spacing: 4) {
                        HStack {
                            Image(systemName: "sparkles")
                                .font(.caption)
                                .foregroundColor(.pink)
                            Text("Hey! Love your profile pic 😊")
                                .font(.caption)
                                .foregroundColor(.white)
                            Spacer()
                        }

                        HStack {
                            Image(systemName: "hand.tap.fill")
                                .font(.caption2)
                                .foregroundColor(.yellow)
                            Text("Tap to insert")
                                .font(.caption2)
                                .foregroundColor(.gray)
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 12)
                )
        }
        .padding(.horizontal, 40)
    }
}

// MARK: - Preview

struct ModernOnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        ModernOnboardingView()
    }
}

