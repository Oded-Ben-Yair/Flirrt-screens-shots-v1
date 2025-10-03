import SwiftUI

struct PersonalizationQuestionnaireView: View {
    @Binding var isPresented: Bool
    let onComplete: () -> Void

    @State private var currentStep = 0
    @State private var answers: [String: Any] = [:]
    @State private var isLoading = false

    private let questions = PersonalizationQuestion.allQuestions

    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.black, Color.gray.opacity(0.3)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Progress header
                    ProgressHeader(currentStep: currentStep, totalSteps: questions.count)

                    // Question content
                    TabView(selection: $currentStep) {
                        ForEach(questions.indices, id: \.self) { index in
                            QuestionView(
                                question: questions[index],
                                answer: Binding(
                                    get: { answers[questions[index].id] },
                                    set: { answers[questions[index].id] = $0 }
                                )
                            )
                            .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .animation(.easeInOut(duration: 0.3), value: currentStep)

                    // Navigation buttons
                    NavigationButtons(
                        currentStep: currentStep,
                        totalSteps: questions.count,
                        canProceed: canProceedToNext(),
                        isLoading: isLoading,
                        onPrevious: {
                            withAnimation {
                                currentStep = max(0, currentStep - 1)
                            }
                        },
                        onNext: {
                            if currentStep < questions.count - 1 {
                                withAnimation {
                                    currentStep += 1
                                }
                            } else {
                                completeQuestionnaire()
                            }
                        },
                        onSkip: {
                            completeQuestionnaire()
                        }
                    )
                }
            }
            .navigationBarHidden(true)
        }
        .preferredColorScheme(.dark)
        .interactiveDismissDisabled()
    }

    private func canProceedToNext() -> Bool {
        let currentQuestion = questions[currentStep]
        let answer = answers[currentQuestion.id]

        switch currentQuestion.type {
        case .multipleChoice, .singleChoice:
            return answer != nil
        case .slider:
            return answer != nil
        case .text:
            if let text = answer as? String {
                return !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            return false
        case .multiSelect:
            if let selections = answer as? [String] {
                return !selections.isEmpty
            }
            return false
        }
    }

    private func completeQuestionnaire() {
        isLoading = true

        // Save preferences
        Task {
            do {
                try await savePersonalizationData()
                await MainActor.run {
                    UserDefaults.standard.set(true, forKey: "personalization_complete")
                    isLoading = false
                    onComplete()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    // Handle error - for now just complete anyway
                    onComplete()
                }
            }
        }
    }

    private func savePersonalizationData() async throws {
        // TODO: Implement API call to save personalization data
        // try await apiClient.savePersonalizationData(answers)

        // For now, just save locally
        for (key, value) in answers {
            UserDefaults.standard.set(value, forKey: "personalization_\(key)")
        }

        // Simulate network delay
        try await Task.sleep(nanoseconds: 2_000_000_000)
    }
}

// MARK: - Supporting Views

struct ProgressHeader: View {
    let currentStep: Int
    let totalSteps: Int

    private var progress: Double {
        Double(currentStep + 1) / Double(totalSteps)
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Setup")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Spacer()

                Text("\(currentStep + 1) of \(totalSteps)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .pink))
                .scaleEffect(y: 2)
        }
        .padding()
        .background(Color.black.opacity(0.3))
    }
}

struct QuestionView: View {
    let question: PersonalizationQuestion
    @Binding var answer: Any?

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Question header
                VStack(spacing: 16) {
                    if let icon = question.icon {
                        Image(systemName: icon)
                            .font(.system(size: 50))
                            .foregroundColor(.pink)
                    }

                    Text(question.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    if let subtitle = question.subtitle {
                        Text(subtitle)
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.top, 20)

                // Answer input based on question type
                Group {
                    switch question.type {
                    case .multipleChoice, .singleChoice:
                        ChoiceSelector(
                            options: question.options,
                            selectedOption: Binding(
                                get: { answer as? String },
                                set: { answer = $0 }
                            ),
                            allowMultiple: question.type == .multipleChoice
                        )

                    case .multiSelect:
                        MultiSelectView(
                            options: question.options,
                            selectedOptions: Binding(
                                get: { answer as? [String] ?? [] },
                                set: { answer = $0 }
                            )
                        )

                    case .slider:
                        SliderSelector(
                            range: question.range ?? (0...10),
                            value: Binding(
                                get: { answer as? Double ?? Double(question.range?.lowerBound ?? 0) },
                                set: { answer = $0 }
                            ),
                            labels: question.sliderLabels
                        )

                    case .text:
                        TextInputView(
                            placeholder: question.placeholder ?? "Enter your answer...",
                            text: Binding(
                                get: { answer as? String ?? "" },
                                set: { answer = $0 }
                            ),
                            isMultiline: question.isMultiline
                        )
                    }
                }

                Spacer(minLength: 40)
            }
            .padding(.horizontal)
        }
    }
}

struct ChoiceSelector: View {
    let options: [String]
    @Binding var selectedOption: String?
    let allowMultiple: Bool

    var body: some View {
        VStack(spacing: 12) {
            ForEach(options, id: \.self) { option in
                ChoiceButton(
                    text: option,
                    isSelected: selectedOption == option,
                    action: {
                        selectedOption = option
                    }
                )
            }
        }
    }
}

struct MultiSelectView: View {
    let options: [String]
    @Binding var selectedOptions: [String]

    var body: some View {
        VStack(spacing: 12) {
            ForEach(options, id: \.self) { option in
                ChoiceButton(
                    text: option,
                    isSelected: selectedOptions.contains(option),
                    action: {
                        if selectedOptions.contains(option) {
                            selectedOptions.removeAll { $0 == option }
                        } else {
                            selectedOptions.append(option)
                        }
                    }
                )
            }
        }
    }
}

struct ChoiceButton: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(text)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .gray)
                    .multilineTextAlignment(.leading)

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isSelected ? .pink : .gray)
            }
            .padding()
            .background(
                isSelected ?
                Color.pink.opacity(0.2) :
                Color.black.opacity(0.3)
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.pink : Color.clear, lineWidth: 1)
            )
        }
        .accessibilityLabel(text)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct SliderSelector: View {
    let range: ClosedRange<Int>
    @Binding var value: Double
    let labels: (String, String)?

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("\(Int(value))")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.pink)

                Slider(
                    value: $value,
                    in: Double(range.lowerBound)...Double(range.upperBound),
                    step: 1
                )
                .tint(.pink)
                .accessibilityLabel("Slider from \(range.lowerBound) to \(range.upperBound), current value \(Int(value))")
            }

            if let labels = labels {
                HStack {
                    Text(labels.0)
                        .font(.caption)
                        .foregroundColor(.gray)

                    Spacer()

                    Text(labels.1)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal)
    }
}

struct TextInputView: View {
    let placeholder: String
    @Binding var text: String
    let isMultiline: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if isMultiline {
                TextEditor(text: $text)
                    .font(.body)
                    .foregroundColor(.white)
                    .frame(minHeight: 100)
                    .padding(12)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .overlay(
                        Group {
                            if text.isEmpty {
                                Text(placeholder)
                                    .font(.body)
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 20)
                                    .allowsHitTesting(false)
                            }
                        },
                        alignment: .topLeading
                    )
            } else {
                TextField(placeholder, text: $text)
                    .font(.body)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            }
        }
    }
}

struct NavigationButtons: View {
    let currentStep: Int
    let totalSteps: Int
    let canProceed: Bool
    let isLoading: Bool
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onSkip: () -> Void

    private var isLastStep: Bool {
        currentStep == totalSteps - 1
    }

    var body: some View {
        VStack(spacing: 16) {
            // Skip button
            if !isLastStep {
                HStack {
                    Spacer()
                    Button("Skip") {
                        onSkip()
                    }
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .disabled(isLoading)
                }
                .padding(.horizontal)
            }

            // Main navigation
            HStack(spacing: 16) {
                // Previous button
                if currentStep > 0 {
                    Button(action: onPrevious) {
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
                    .disabled(isLoading)
                    .accessibilityLabel("Previous question")
                } else {
                    Spacer()
                        .frame(width: 100)
                }

                Spacer()

                // Next/Complete button
                Button(action: onNext) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }

                        Text(isLastStep ? "Complete" : "Next")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(width: 120, height: 50)
                    .background(
                        canProceed && !isLoading ?
                        LinearGradient(
                            colors: [Color.pink, Color.purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        ) :
                        LinearGradient(
                            colors: [Color.gray, Color.gray],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                .disabled(!canProceed || isLoading)
                .accessibilityLabel(isLastStep ? "Complete setup" : "Next question")
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 40)
        .background(Color.black.opacity(0.3))
    }
}

// MARK: - Data Models

struct PersonalizationQuestion: Identifiable {
    let id: String
    let title: String
    let subtitle: String?
    let type: QuestionType
    let options: [String]
    let range: ClosedRange<Int>?
    let sliderLabels: (String, String)?
    let placeholder: String?
    let isMultiline: Bool
    let icon: String?

    enum QuestionType {
        case multipleChoice
        case singleChoice
        case multiSelect
        case slider
        case text
    }

    static let allQuestions: [PersonalizationQuestion] = [
        PersonalizationQuestion(
            id: "dating_experience",
            title: "What's your dating experience level?",
            subtitle: "This helps us personalize your suggestions",
            type: .singleChoice,
            options: [
                "New to dating",
                "Some experience",
                "Pretty experienced",
                "Dating expert"
            ],
            range: nil,
            sliderLabels: nil,
            placeholder: nil,
            isMultiline: false,
            icon: "heart.circle"
        ),

        PersonalizationQuestion(
            id: "dating_goals",
            title: "What are you looking for?",
            subtitle: "Select all that apply",
            type: .multiSelect,
            options: [
                "Casual dating",
                "Serious relationship",
                "Marriage",
                "Just having fun",
                "Making friends",
                "Networking"
            ],
            range: nil,
            sliderLabels: nil,
            placeholder: nil,
            isMultiline: false,
            icon: "target"
        ),

        PersonalizationQuestion(
            id: "communication_style",
            title: "How would you describe your communication style?",
            subtitle: nil,
            type: .singleChoice,
            options: [
                "Direct and straightforward",
                "Playful and flirty",
                "Thoughtful and deep",
                "Funny and lighthearted",
                "Mysterious and intriguing"
            ],
            range: nil,
            sliderLabels: nil,
            placeholder: nil,
            isMultiline: false,
            icon: "message.circle"
        ),

        PersonalizationQuestion(
            id: "confidence_level",
            title: "How confident are you in conversations?",
            subtitle: "Be honest - we're here to help!",
            type: .slider,
            options: [],
            range: 1...10,
            sliderLabels: ("Not confident", "Very confident"),
            placeholder: nil,
            isMultiline: false,
            icon: "star.circle"
        ),

        PersonalizationQuestion(
            id: "interests",
            title: "What are your main interests?",
            subtitle: "Select your top interests to help personalize conversations",
            type: .multiSelect,
            options: [
                "Sports & Fitness",
                "Music & Concerts",
                "Movies & TV",
                "Travel & Adventure",
                "Food & Cooking",
                "Art & Culture",
                "Technology",
                "Books & Reading",
                "Gaming",
                "Nature & Outdoors",
                "Photography",
                "Dancing"
            ],
            range: nil,
            sliderLabels: nil,
            placeholder: nil,
            isMultiline: false,
            icon: "heart.text.square"
        ),

        PersonalizationQuestion(
            id: "ideal_first_date",
            title: "Describe your ideal first date",
            subtitle: "This helps us suggest conversation starters",
            type: .text,
            options: [],
            range: nil,
            sliderLabels: nil,
            placeholder: "Tell us about your perfect first date...",
            isMultiline: true,
            icon: "calendar.circle"
        ),

        PersonalizationQuestion(
            id: "conversation_topics",
            title: "What topics do you love talking about?",
            subtitle: "Select all that apply",
            type: .multiSelect,
            options: [
                "Career & Ambitions",
                "Travel Stories",
                "Family & Relationships",
                "Hobbies & Interests",
                "Current Events",
                "Philosophy & Life",
                "Pop Culture",
                "Personal Growth",
                "Humor & Jokes",
                "Future Plans"
            ],
            range: nil,
            sliderLabels: nil,
            placeholder: nil,
            isMultiline: false,
            icon: "bubble.left.and.bubble.right"
        ),

        PersonalizationQuestion(
            id: "flirting_comfort",
            title: "How comfortable are you with flirting?",
            subtitle: "This helps us calibrate our suggestions",
            type: .slider,
            options: [],
            range: 1...10,
            sliderLabels: ("Very shy", "Total flirt"),
            placeholder: nil,
            isMultiline: false,
            icon: "flame.circle"
        )
    ]
}

// MARK: - Preview
struct PersonalizationQuestionnaireView_Previews: PreviewProvider {
    static var previews: some View {
        PersonalizationQuestionnaireView(
            isPresented: .constant(true),
            onComplete: {}
        )
    }
}