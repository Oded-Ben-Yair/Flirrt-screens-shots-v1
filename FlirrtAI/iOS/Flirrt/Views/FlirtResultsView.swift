//
//  FlirtResultsView.swift
//  Vibe8 (formerly Flirrt)
//
//  Flirt Results Display with Quality Indicators
//  Created by: AI/ML Engineer Agent
//  Uses: Vibe8 Design System from Phase 1
//
//  Features:
//  - Analysis context display
//  - Primary flirt with quality scores
//  - Alternative flirts
//  - Copy to clipboard
//  - User rating feedback
//  - Quality visualization
//

import SwiftUI

struct FlirtResultsView: View {

    @Bindable var viewModel: ScreenshotAnalysisViewModel
    @State private var copiedFlirtId: UUID?
    @State private var showCopiedAlert = false

    // Gamification integration (Phase 3)
    @State private var gamificationModel = GamificationModel()
    @State private var showTutorial = false
    @State private var showMilestoneCelebration: Milestone? = nil

    // Check if gamification is enabled in settings
    private var isGamificationEnabled: Bool {
        UserDefaults.standard.bool(forKey: "gamification.enabled")
    }

    var body: some View {
        ZStack {
            Vibe8Colors.lightGray
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Gamification HUD (sticky header) - only if enabled
                if isGamificationEnabled {
                    GamificationProgressBar(model: gamificationModel)
                        .padding(.top, Vibe8Spacing.sm)
                        .padding(.bottom, Vibe8Spacing.xs)
                        .background(Vibe8Colors.lightGray)
                }

                ScrollView {
                    VStack(spacing: Vibe8Spacing.lg) {

                    // Header
                    VStack(spacing: Vibe8Spacing.sm) {
                        Text("Your Flirts")
                            .font(Vibe8Typography.headline)
                            .foregroundStyle(Vibe8Colors.primaryGradient)

                        Text("AI-generated conversation starters")
                            .font(Vibe8Typography.bodyMedium)
                            .foregroundColor(Vibe8Colors.darkGray)
                    }
                    .padding(.top, Vibe8Spacing.md)

                    // Analysis Context (collapsible)
                    if let analysis = viewModel.analysisResult {
                        AnalysisContextCard(analysis: analysis)
                    }

                    // Primary Flirt (with gamification)
                    if let primary = viewModel.primaryFlirt {
                        VStack(alignment: .leading, spacing: Vibe8Spacing.sm) {
                            HStack {
                                Vibe8Badge("Recommended", color: Vibe8Colors.orangeGradientStart)
                                Spacer()
                                if let scores = primary.qualityScores {
                                    QualityBadge(score: scores.overall)
                                }
                            }

                            FlirtCardWithReveal(
                                flirt: primary,
                                gamificationModel: gamificationModel
                            )

                            // Action buttons (only when revealed)
                            if gamificationModel.isRevealed(primary.id) {
                                HStack {
                                    // Copy button
                                    Button(action: {
                                        copyFlirt(primary)
                                        gamificationModel.awardPoints(for: .copyFlirt)
                                    }) {
                                        HStack(spacing: Vibe8Spacing.xs) {
                                            Image(systemName: "doc.on.doc")
                                            Text("Copy")
                                                .font(Vibe8Typography.small())
                                        }
                                        .foregroundColor(Vibe8Colors.darkGray)
                                    }
                                    .buttonStyle(.plain)

                                    Spacer()

                                    // Star rating
                                    HStack(spacing: 4) {
                                        ForEach(1...5, id: \.self) { star in
                                            Button {
                                                viewModel.rateFlirt(primary, rating: star)
                                                if star >= 4 {
                                                    gamificationModel.awardPoints(for: .rateFlirt)
                                                }
                                            } label: {
                                                Image(systemName: "star.fill")
                                                    .foregroundStyle(Vibe8Colors.primaryGradient)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                                .padding(.horizontal, Vibe8Spacing.md)
                                .padding(.top, Vibe8Spacing.sm)
                            }
                        }
                    }

                    // Alternative Flirts (with gamification)
                    if !viewModel.alternativeFlirts.isEmpty {
                        VStack(alignment: .leading, spacing: Vibe8Spacing.md) {
                            Text("Alternatives")
                                .font(Vibe8Typography.subheadline)
                                .foregroundColor(Vibe8Colors.darkGray)
                                .padding(.horizontal, Vibe8Spacing.md)

                            ForEach(viewModel.alternativeFlirts) { flirt in
                                VStack(spacing: Vibe8Spacing.sm) {
                                    FlirtCardWithReveal(
                                        flirt: flirt,
                                        gamificationModel: gamificationModel
                                    )

                                    // Action buttons (only when revealed)
                                    if gamificationModel.isRevealed(flirt.id) {
                                        HStack {
                                            // Copy button
                                            Button(action: {
                                                copyFlirt(flirt)
                                                gamificationModel.awardPoints(for: .copyFlirt)
                                            }) {
                                                HStack(spacing: Vibe8Spacing.xs) {
                                                    Image(systemName: "doc.on.doc")
                                                    Text("Copy")
                                                        .font(Vibe8Typography.small())
                                                }
                                                .foregroundColor(Vibe8Colors.darkGray)
                                            }
                                            .buttonStyle(.plain)

                                            Spacer()

                                            // Star rating
                                            HStack(spacing: 4) {
                                                ForEach(1...5, id: \.self) { star in
                                                    Button {
                                                        viewModel.rateFlirt(flirt, rating: star)
                                                        if star >= 4 {
                                                            gamificationModel.awardPoints(for: .rateFlirt)
                                                        }
                                                    } label: {
                                                        Image(systemName: "star.fill")
                                                            .foregroundStyle(Vibe8Colors.primaryGradient)
                                                    }
                                                    .buttonStyle(.plain)
                                                }
                                            }
                                        }
                                        .padding(.horizontal, Vibe8Spacing.md)
                                        .padding(.top, Vibe8Spacing.sm)
                                    }
                                }
                            }
                        }
                    }

                    // Actions
                    VStack(spacing: Vibe8Spacing.md) {
                        Button {
                            viewModel.reset()
                        } label: {
                            Text("Analyze Another Screenshot")
                        }
                        .buttonStyle(Vibe8ButtonStyle())
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, Vibe8Spacing.lg)
                    .padding(.top, Vibe8Spacing.md)

                    }
                    .padding(.bottom, Vibe8Spacing.xxl)
                }
                .coordinateSpace(name: "scroll")
                .trackScrollOffset(in: "scroll") { offset in
                    gamificationModel.updateScrollOffset(offset)
                }
            }
        }
        .navigationTitle("Results")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Setup gamification on view appear
            setupGamification()
        }
        .overlay(alignment: .top) {
            if showCopiedAlert {
                CopiedAlert()
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                showCopiedAlert = false
                            }
                        }
                    }
            }
        }
        .overlay {
            // Tutorial overlay (first-time users)
            if showTutorial {
                GamificationTutorialView {
                    withAnimation {
                        showTutorial = false
                    }
                }
                .transition(.opacity)
            }

            // Milestone celebration
            if let milestone = showMilestoneCelebration {
                MilestonesCelebrationView(milestone: milestone) {
                    withAnimation {
                        showMilestoneCelebration = nil
                    }
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
    }

    // MARK: - Helper Methods

    private func copyFlirt(_ flirt: GeneratedFlirt) {
        viewModel.copyFlirt(flirt)
        copiedFlirtId = flirt.id

        withAnimation {
            showCopiedAlert = true
        }

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    /// Setup gamification system with pre-calculated thresholds (60fps optimization)
    private func setupGamification() {
        // Update streak status
        gamificationModel.updateStreakStatus()

        // Pre-calculate reveal thresholds for all flirts
        var allFlirts: [GeneratedFlirt] = []
        if let primary = viewModel.primaryFlirt {
            allFlirts.append(primary)
        }
        allFlirts.append(contentsOf: viewModel.alternativeFlirts)

        gamificationModel.setupRevealThresholds(for: allFlirts)

        // Show tutorial for first-time users
        if GamificationTutorialManager.shared.shouldShowTutorial {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    showTutorial = true
                }
            }
        }

        // Check for milestone achievements (show celebration if any)
        checkForMilestoneAchievements()
    }

    /// Check if any milestones were achieved and show celebration
    private func checkForMilestoneAchievements() {
        for milestone in Milestone.allMilestones {
            if !gamificationModel.achievedMilestones.contains(milestone.id) &&
               gamificationModel.totalFlirtsRevealed >= milestone.requirement {
                // Show celebration for first unachieved milestone
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation {
                        showMilestoneCelebration = milestone
                    }
                }
                break // Only show one at a time
            }
        }
    }
}

// MARK: - Analysis Context Card

struct AnalysisContextCard: View {
    let analysis: ScreenshotAnalysis
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: Vibe8Spacing.md) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: Vibe8Spacing.xs) {
                        Text("Analysis")
                            .font(Vibe8Typography.subheadline)
                            .foregroundColor(Vibe8Colors.darkGray)

                        HStack(spacing: Vibe8Spacing.sm) {
                            Text("Confidence:")
                                .font(Vibe8Typography.small())
                                .foregroundColor(Vibe8Colors.darkGray.opacity(0.7))

                            Text("\(Int(analysis.confidence * 100))%")
                                .font(Vibe8Typography.caption())
                                .foregroundColor(confidenceColor(analysis.confidence))
                        }
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(Vibe8Colors.darkGray)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                Vibe8Divider()

                VStack(alignment: .leading, spacing: Vibe8Spacing.sm) {
                    Text(analysis.context)
                        .font(Vibe8Typography.bodyMedium)
                        .foregroundColor(Vibe8Colors.darkGray)

                    if let personality = analysis.personality {
                        DetailSection(title: "Personality", items: [
                            personality.energyLevel,
                            personality.socialStyle,
                            personality.confidenceLevel
                        ].compactMap { $0 })
                    }

                    if let scene = analysis.scene {
                        DetailSection(title: "Scene", items: [
                            scene.photoType,
                            scene.mood,
                            scene.socialContext
                        ].compactMap { $0 })
                    }
                }
            }
        }
        .vibe8Card()
    }

    private func confidenceColor(_ confidence: Double) -> Color {
        switch confidence {
        case 0.9...: return .green
        case 0.75..<0.9: return .green
        case 0.6..<0.75: return .orange
        default: return .red
        }
    }
}

struct DetailSection: View {
    let title: String
    let items: [String]

    var body: some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: Vibe8Spacing.xs) {
                Text(title)
                    .font(Vibe8Typography.small())
                    .foregroundColor(Vibe8Colors.darkGray.opacity(0.7))

                ForEach(items, id: \.self) { item in
                    HStack {
                        Circle()
                            .fill(Vibe8Colors.primaryGradient)
                            .frame(width: 4, height: 4)
                        Text(item)
                            .font(Vibe8Typography.small())
                            .foregroundColor(Vibe8Colors.darkGray)
                    }
                }
            }
        }
    }
}

// MARK: - Flirt Card

struct FlirtCard: View {
    let flirt: GeneratedFlirt
    let showQualityDetails: Bool
    let onCopy: () -> Void
    let onRate: (Int) -> Void

    @State private var userRating: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: Vibe8Spacing.md) {

            // Flirt text
            Text(flirt.flirt)
                .font(Vibe8Typography.body)
                .foregroundColor(Vibe8Colors.darkGray)
                .fixedSize(horizontal: false, vertical: true)

            // Quality details (if enabled)
            if showQualityDetails, let scores = flirt.qualityScores {
                QualityScoresView(scores: scores)
            }

            Vibe8Divider()

            // Actions
            HStack {
                // Copy button
                Button(action: onCopy) {
                    HStack(spacing: Vibe8Spacing.xs) {
                        Image(systemName: "doc.on.doc")
                        Text("Copy")
                            .font(Vibe8Typography.small())
                    }
                    .foregroundColor(Vibe8Colors.darkGray)
                }
                .buttonStyle(.plain)

                Spacer()

                // Star rating
                HStack(spacing: 4) {
                    ForEach(1...5, id: \.self) { star in
                        Button {
                            userRating = star
                            onRate(star)
                        } label: {
                            Image(systemName: star <= userRating ? "star.fill" : "star")
                                .foregroundStyle(Vibe8Colors.primaryGradient)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Reasoning (if available)
            if let reasoning = flirt.reasoning, !reasoning.isEmpty {
                Text(reasoning)
                    .font(Vibe8Typography.small())
                    .foregroundColor(Vibe8Colors.darkGray.opacity(0.6))
                    .italic()
            }
        }
        .vibe8Card()
    }
}

// MARK: - Quality Scores View

struct QualityScoresView: View {
    let scores: QualityScores

    var body: some View {
        VStack(spacing: Vibe8Spacing.sm) {
            Text("Quality Breakdown")
                .font(Vibe8Typography.small())
                .foregroundColor(Vibe8Colors.darkGray.opacity(0.7))

            VStack(spacing: Vibe8Spacing.xs) {
                QualityBar(label: "Sentiment", score: scores.sentiment)
                QualityBar(label: "Creativity", score: scores.creativity)
                QualityBar(label: "Relevance", score: scores.relevance)
                QualityBar(label: "Tone Match", score: scores.toneMatching)
            }
        }
        .padding(Vibe8Spacing.sm)
        .background(Vibe8Colors.lightGray)
        .cornerRadius(Vibe8CornerRadius.small)
    }
}

struct QualityBar: View {
    let label: String
    let score: Double

    var body: some View {
        HStack {
            Text(label)
                .font(Vibe8Typography.small())
                .foregroundColor(Vibe8Colors.darkGray)
                .frame(width: 80, alignment: .leading)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    Rectangle()
                        .fill(Vibe8Colors.borderGray)
                        .frame(height: 6)
                        .cornerRadius(3)

                    // Fill
                    Rectangle()
                        .fill(scoreColor(score))
                        .frame(width: geometry.size.width * score, height: 6)
                        .cornerRadius(3)
                }
            }
            .frame(height: 6)

            Text("\(Int(score * 100))%")
                .font(Vibe8Typography.small())
                .foregroundColor(Vibe8Colors.darkGray)
                .frame(width: 40, alignment: .trailing)
        }
    }

    private func scoreColor(_ score: Double) -> LinearGradient {
        if score >= 0.8 {
            return Vibe8Colors.primaryGradient
        } else if score >= 0.6 {
            return LinearGradient(colors: [.orange, .yellow], startPoint: .leading, endPoint: .trailing)
        } else {
            return LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing)
        }
    }
}

// MARK: - Quality Badge

struct QualityBadge: View {
    let score: Double

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .font(.system(size: 10))
            Text(qualityText)
                .font(Vibe8Typography.small())
        }
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(qualityColor)
        .cornerRadius(Vibe8CornerRadius.small)
    }

    private var qualityText: String {
        switch score {
        case 0.85...: return "Excellent"
        case 0.75..<0.85: return "Good"
        case 0.65..<0.75: return "Fair"
        default: return "Okay"
        }
    }

    private var qualityColor: Color {
        switch score {
        case 0.85...: return .green
        case 0.75..<0.85: return .green
        case 0.65..<0.75: return .orange
        default: return .gray
        }
    }
}

// MARK: - Copied Alert

struct CopiedAlert: View {
    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text("Copied to clipboard!")
                .font(Vibe8Typography.bodyMedium)
                .foregroundColor(.white)
        }
        .padding()
        .background(Vibe8Colors.darkGray)
        .cornerRadius(Vibe8CornerRadius.medium)
        .shadow(color: Vibe8Shadow.large, radius: 12, x: 0, y: 4)
        .padding(.top, 60)
    }
}

#if DEBUG
struct FlirtResultsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            FlirtResultsView(viewModel: {
                let vm = ScreenshotAnalysisViewModel()
                // Mock data for preview
                return vm
            }())
        }
    }
}
#endif
