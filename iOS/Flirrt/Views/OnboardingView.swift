import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    // ✅ REMOVED: No longer showing questionnaire
    @Binding var isOnboardingComplete: Bool

    private let pages = OnboardingPage.allPages

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.black, Color.gray.opacity(0.3)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button("Skip") {
                        completeOnboarding()
                    }
                    .font(.headline)
                    .foregroundColor(.gray)
                    .padding()
                    .accessibilityLabel("Skip onboarding")
                }

                // Page content
                TabView(selection: $currentPage) {
                    ForEach(pages.indices, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.5), value: currentPage)

                // Bottom section with page indicator and navigation
                VStack(spacing: 30) {
                    // Page indicator
                    HStack(spacing: 8) {
                        ForEach(pages.indices, id: \.self) { index in
                            Circle()
                                .fill(index == currentPage ? Color.pink : Color.gray.opacity(0.5))
                                .frame(width: 8, height: 8)
                                .scaleEffect(index == currentPage ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 0.3), value: currentPage)
                        }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Page \(currentPage + 1) of \(pages.count)")

                    // Navigation buttons
                    HStack(spacing: 16) {
                        // Previous button
                        if currentPage > 0 {
                            Button(action: {
                                withAnimation {
                                    currentPage -= 1
                                }
                            }) {
                                Text("Previous")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                    .frame(width: 100, height: 50)
                                    .background(Color.clear)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                    )
                            }
                            .accessibilityLabel("Previous page")
                        } else {
                            Spacer()
                                .frame(width: 100)
                        }

                        Spacer()

                        // Next/Get Started button
                        Button(action: {
                            if currentPage < pages.count - 1 {
                                withAnimation {
                                    currentPage += 1
                                }
                            } else {
                                // ✅ SIMPLIFIED: Skip questionnaire, go straight to app
                                completeOnboarding()
                            }
                        }) {
                            Text(currentPage == pages.count - 1 ? "Get Started" : "Next")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(width: 120, height: 50)
                                .background(
                                    LinearGradient(
                                        colors: [Color.pink, Color.purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                        }
                        .accessibilityLabel(currentPage == pages.count - 1 ? "Get started with Vibe8" : "Next page")
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.dark)
        // ✅ REMOVED: No questionnaire sheet
        .gesture(
            DragGesture()
                .onEnded { value in
                    let threshold: CGFloat = 50
                    if value.translation.width > threshold && currentPage > 0 {
                        withAnimation {
                            currentPage -= 1
                        }
                    } else if value.translation.width < -threshold && currentPage < pages.count - 1 {
                        withAnimation {
                            currentPage += 1
                        }
                    }
                }
        )
    }

    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: AppConstants.UserDefaultsKeys.onboardingComplete)
        withAnimation {
            isOnboardingComplete = true
        }
    }
}

// MARK: - Onboarding Page View

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // Icon/Image
            VStack(spacing: 20) {
                if let systemImage = page.systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 80))
                        .foregroundStyle(page.iconColor, page.iconColor.opacity(0.7))
                        .accessibilityLabel(page.iconAccessibilityLabel)
                } else if let imageName = page.imageName {
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 200)
                        .accessibilityLabel(page.iconAccessibilityLabel)
                }

                // Optional animation or additional visual element
                if page.showAnimation {
                    AnimatedElement(page: page)
                }
            }

            Spacer()

            // Content
            VStack(spacing: 20) {
                Text(page.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text(page.description)
                    .font(.title3)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .padding(.horizontal)

                // Features list for specific pages
                if !page.features.isEmpty {
                    VStack(spacing: 12) {
                        ForEach(page.features, id: \.self) { feature in
                            FeatureRow(text: feature)
                        }
                    }
                    .padding(.top, 10)
                }
            }

            Spacer()
        }
        .padding()
    }
}

// MARK: - Supporting Views

struct AnimatedElement: View {
    let page: OnboardingPage
    @State private var isAnimating = false

    var body: some View {
        Group {
            switch page.title {
            case "Voice Cloning":
                HStack(spacing: 4) {
                    ForEach(0..<5) { index in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.pink)
                            .frame(width: 4, height: CGFloat.random(in: 10...30))
                            .scaleEffect(y: isAnimating ? CGFloat.random(in: 0.5...1.5) : 1.0)
                            .animation(
                                Animation.easeInOut(duration: 0.5)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.1),
                                value: isAnimating
                            )
                    }
                }
                .onAppear {
                    isAnimating = true
                }

            case "AI Analysis":
                Circle()
                    .stroke(Color.pink, lineWidth: 2)
                    .frame(width: 40, height: 40)
                    .scaleEffect(isAnimating ? 1.2 : 1.0)
                    .opacity(isAnimating ? 0.5 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 1.0)
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
                    .onAppear {
                        isAnimating = true
                    }

            default:
                EmptyView()
            }
        }
    }
}

struct FeatureRow: View {
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.title3)

            Text(text)
                .font(.body)
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)

            Spacer()
        }
        .padding(.horizontal)
    }
}

// MARK: - Onboarding Page Model

struct OnboardingPage: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let systemImage: String?
    let imageName: String?
    let iconColor: Color
    let features: [String]
    let showAnimation: Bool
    let iconAccessibilityLabel: String

    // ✅ SIMPLIFIED: Reduced from 5 pages to 1 page for faster onboarding
    static let allPages: [OnboardingPage] = [
        OnboardingPage(
            title: "Welcome to Vibe8 AI",
            description: "Your AI-powered flirting assistant. Take a screenshot of any dating profile, open the Vibe8 keyboard, and get instant personalized suggestions.",
            systemImage: "heart.text.square.fill",
            imageName: nil,
            iconColor: .pink,
            features: [
                "Screenshot dating profiles for instant analysis",
                "Get AI-powered conversation starters",
                "Use the keyboard in any dating app"
            ],
            showAnimation: false,
            iconAccessibilityLabel: "Vibe8 AI heart logo"
        )
    ]
}

// MARK: - Preview
struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(isOnboardingComplete: .constant(false))
    }
}