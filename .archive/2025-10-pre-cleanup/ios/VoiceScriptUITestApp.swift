import SwiftUI

// Test app to demonstrate Voice Script Selector UI states
@main
struct VoiceScriptUITestApp: App {
    var body: some Scene {
        WindowGroup {
            VoiceScriptDemoView()
                .preferredColorScheme(.dark)
        }
    }
}

struct VoiceScriptDemoView: View {
    @State private var selectedDemo = 0

    let demos = [
        "Main Selector",
        "Introduction Category",
        "Conversation Category",
        "Storytelling Category",
        "Practice Category",
        "Script Detail",
        "Empty State",
        "Search Results"
    ]

    var body: some View {
        TabView(selection: $selectedDemo) {
            // Main Selector View
            VoiceScriptSelectorView()
                .tabItem {
                    Image(systemName: "1.circle")
                    Text("Main")
                }
                .tag(0)

            // Introduction Category
            VoiceScriptSelectorViewWithCategory(.introduction)
                .tabItem {
                    Image(systemName: "2.circle")
                    Text("Intro")
                }
                .tag(1)

            // Conversation Category
            VoiceScriptSelectorViewWithCategory(.conversation)
                .tabItem {
                    Image(systemName: "3.circle")
                    Text("Conv")
                }
                .tag(2)

            // Storytelling Category
            VoiceScriptSelectorViewWithCategory(.storytelling)
                .tabItem {
                    Image(systemName: "4.circle")
                    Text("Story")
                }
                .tag(3)

            // Practice Category
            VoiceScriptSelectorViewWithCategory(.practice)
                .tabItem {
                    Image(systemName: "5.circle")
                    Text("Practice")
                }
                .tag(4)

            // Script Detail View
            ScriptDetailView(script: VoiceScript.predefinedScripts[0])
                .tabItem {
                    Image(systemName: "6.circle")
                    Text("Detail")
                }
                .tag(5)

            // Empty State View
            VoiceScriptEmptyStateDemo()
                .tabItem {
                    Image(systemName: "7.circle")
                    Text("Empty")
                }
                .tag(6)

            // Search Results View
            VoiceScriptSearchDemo()
                .tabItem {
                    Image(systemName: "8.circle")
                    Text("Search")
                }
                .tag(7)
        }
        .accentColor(.pink)
    }
}

struct VoiceScriptSelectorViewWithCategory: View {
    @State private var selectedCategory: ScriptCategory
    @State private var searchText = ""

    init(_ category: ScriptCategory) {
        self._selectedCategory = State(initialValue: category)
    }

    var filteredScripts: [VoiceScript] {
        return VoiceScript.predefinedScripts.filter { $0.category == selectedCategory }
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
                                selectedCategory = category
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)

                // Script Cards
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredScripts) { script in
                            ScriptCard(script: script) {
                                // Demo action
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Voice Scripts")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct VoiceScriptEmptyStateDemo: View {
    @State private var selectedCategory: ScriptCategory = .custom
    @State private var searchText = "nonexistent"

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
                                selectedCategory = category
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)

                // Empty State
                Spacer()
                EmptyStateView(
                    icon: "doc.text.magnifyingglass",
                    title: "No Scripts Found",
                    description: "Try adjusting your search or selecting a different category"
                )
                Spacer()
            }
            .navigationTitle("Voice Scripts")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct VoiceScriptSearchDemo: View {
    @State private var selectedCategory: ScriptCategory = .introduction
    @State private var searchText = "confident"

    var filteredScripts: [VoiceScript] {
        return VoiceScript.predefinedScripts.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.content.localizedCaseInsensitiveContains(searchText) ||
            $0.tags.joined(separator: " ").localizedCaseInsensitiveContains(searchText)
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
                                selectedCategory = category
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)

                // Search Results Header
                HStack {
                    Text("Search Results")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Spacer()

                    Text("\(filteredScripts.count) found")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)

                // Search Results
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredScripts) { script in
                            ScriptCard(script: script) {
                                // Demo action
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Voice Scripts")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Preview
struct VoiceScriptDemoView_Previews: PreviewProvider {
    static var previews: some View {
        VoiceScriptDemoView()
            .preferredColorScheme(.dark)
    }
}