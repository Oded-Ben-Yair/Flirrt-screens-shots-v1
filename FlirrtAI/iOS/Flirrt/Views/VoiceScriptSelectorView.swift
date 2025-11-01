import SwiftUI

@MainActor
struct VoiceScriptSelectorView: View {
    @State private var selectedScript: VoiceScript?
    @State private var selectedCategory: ScriptCategory = .introduction
    @State private var showingScriptDetail = false
    @State private var searchText = ""
    @Namespace private var scriptAnimation

    var filteredScripts: [VoiceScript] {
        let scripts = VoiceScript.predefinedScripts.filter { $0.category == selectedCategory }

        if searchText.isEmpty {
            return scripts
        } else {
            return scripts.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.content.localizedCaseInsensitiveContains(searchText) ||
                $0.tags.joined(separator: " ").localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search scripts...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                .padding(.top)

                // Category Selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(ScriptCategory.allCases, id: \.self) { category in
                            CategoryChip(
                                category: category,
                                isSelected: category == selectedCategory
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedCategory = category
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)

                // Script Cards
                if filteredScripts.isEmpty {
                    Spacer()
                    EmptyStateView(
                        icon: "doc.text.magnifyingglass",
                        title: "No Scripts Found",
                        description: "Try adjusting your search or selecting a different category"
                    )
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredScripts) { script in
                                ScriptCard(script: script) {
                                    selectedScript = script
                                    showingScriptDetail = true
                                }
                                .matchedGeometryEffect(id: script.id, in: scriptAnimation)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Voice Scripts")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingScriptDetail) {
                if let script = selectedScript {
                    ScriptDetailView(script: script)
                }
            }
        }
    }
}

@MainActor
struct CategoryChip: View {
    let category: ScriptCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: 8) {
                Circle()
                    .fill(category.color)
                    .frame(width: 8, height: 8)

                Text(category.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? category.color.opacity(0.2) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(isSelected ? category.color : Color.clear, lineWidth: 2)
                    )
            )
            .foregroundColor(isSelected ? category.color : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

@MainActor
struct ScriptCard: View {
    let script: VoiceScript
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button {
            action()
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    HStack(spacing: 12) {
                        Image(systemName: script.icon)
                            .font(.title2)
                            .foregroundColor(script.category.color)
                            .frame(width: 40, height: 40)
                            .background(script.category.color.opacity(0.2))
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 4) {
                            Text(script.title)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)

                            HStack(spacing: 8) {
                                Label(script.formattedDuration, systemImage: "clock")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                DifficultyStars(difficulty: script.difficulty)
                            }
                        }
                    }

                    Spacer()

                    EmotionBadge(emotion: script.emotion)
                }

                // Content Preview
                Text(script.content)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)

                // Tags
                if !script.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(script.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color(.systemGray5))
                                    .cornerRadius(8)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(
                        color: .black.opacity(isPressed ? 0.1 : 0.05),
                        radius: isPressed ? 8 : 12,
                        x: 0,
                        y: isPressed ? 4 : 6
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                        isPressed = false
                    }
                }
        )
    }
}

@MainActor
struct DifficultyStars: View {
    let difficulty: ScriptDifficulty

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...3, id: \.self) { index in
                Image(systemName: "star.fill")
                    .font(.caption2)
                    .foregroundColor(index <= difficulty.stars ? difficulty.color : Color(.systemGray4))
            }
        }
    }
}

@MainActor
struct EmotionBadge: View {
    let emotion: VoiceEmotion

    var body: some View {
        Text(emotion.displayName)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(emotionColor.opacity(0.2))
            )
            .foregroundColor(emotionColor)
            .overlay(
                Capsule()
                    .stroke(emotionColor.opacity(0.5), lineWidth: 1)
            )
    }

    private var emotionColor: Color {
        switch emotion {
        case .confident:
            return .blue
        case .playful:
            return .green
        case .seductive:
            return .red
        case .mysterious:
            return .purple
        case .casual:
            return .gray
        case .excited:
            return .orange
        }
    }
}

@MainActor
struct EmptyStateView: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.gray)

            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
    }
}

@MainActor
struct ScriptDetailView: View {
    let script: VoiceScript
    @Environment(\.dismiss) private var dismiss
    @State private var isRecording = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: script.icon)
                                .font(.largeTitle)
                                .foregroundColor(script.category.color)
                                .frame(width: 60, height: 60)
                                .background(script.category.color.opacity(0.2))
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 8) {
                                Text(script.title)
                                    .font(.title2)
                                    .fontWeight(.bold)

                                HStack(spacing: 16) {
                                    Label(script.formattedDuration, systemImage: "clock")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)

                                    HStack(spacing: 4) {
                                        Text("Difficulty:")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        DifficultyStars(difficulty: script.difficulty)
                                    }
                                }
                            }

                            Spacer()

                            EmotionBadge(emotion: script.emotion)
                        }

                        Text(script.category.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }

                    Divider()

                    // Script Content
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Script Content")
                            .font(.headline)

                        Text(script.content)
                            .font(.body)
                            .lineSpacing(4)
                            .padding(16)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }

                    // Tags
                    if !script.tags.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Tags")
                                .font(.headline)

                            LazyVGrid(columns: [
                                GridItem(.adaptive(minimum: 80))
                            ], spacing: 8) {
                                ForEach(script.tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color(.systemGray5))
                                        .cornerRadius(16)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }

                    Spacer(minLength: 20)
                }
                .padding(24)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isRecording.toggle()
                    }) {
                        Image(systemName: isRecording ? "stop.circle.fill" : "record.circle")
                            .font(.title2)
                            .foregroundColor(isRecording ? .red : .blue)
                    }
                }
            }
            .overlay(alignment: .bottom) {
                // Record Button
                if !isRecording {
                    Button(action: {
                        isRecording = true
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "record.circle")
                                .font(.title2)

                            Text("Start Recording")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        .background(Color.red)
                        .cornerRadius(50)
                        .shadow(color: .red.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .padding(.bottom, 40)
                }
            }
        }
    }
}

// MARK: - Preview
struct VoiceScriptSelectorView_Previews: PreviewProvider {
    static var previews: some View {
        VoiceScriptSelectorView()
            .preferredColorScheme(.light)

        VoiceScriptSelectorView()
            .preferredColorScheme(.dark)

        ScriptDetailView(script: VoiceScript.predefinedScripts[0])
    }
}