import SwiftUI
import MuralCore

struct DailyReviewSession: Identifiable {
    let id = UUID()
    let words: [WordState]
    let languageID: String
}

struct DailyReviewView: View {
    // A fixed deck for this sitting. Every grade is checked against current saved words.
    let review: DailyReviewSession
    let coordinator: ConversationCoordinator
    @Environment(\.dismiss) private var dismiss
    @State private var selection = 0
    @State private var revealed = false
    @State private var draft = ""
    @State private var startedAt = Date()
    @State private var message: String?
    private var language: LanguageModule { LanguageRegistry.module(for: review.languageID)! }

    var body: some View {
        NavigationStack {
            TimelineView(.periodic(from: startedAt, by: 1)) { context in
                let expired = context.date.timeIntervalSince(startedAt) >= 300
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        if selection >= review.words.count || expired {
                            Image(systemName: "checkmark.circle").font(.largeTitle).foregroundStyle(MuralColor.orange)
                            Text(expired ? "A little practice goes a long way." : "That’s today’s review.")
                                .font(.system(.title, design: .rounded, weight: .semibold))
                            Text("\(selection) of \(review.words.count) words reviewed. Your next review is saved.")
                                .accessibilityIdentifier("daily-review-summary")
                            Text("These are your own recall checks. Your spoken-recall bars still come from conversations.")
                                .font(.footnote).foregroundStyle(MuralColor.secondary)
                            Button("Done") { dismiss() }.buttonStyle(.borderedProminent).tint(MuralColor.orange)
                        } else {
                            reviewCard(review.words[selection])
                            if let message { Text(message).font(.footnote).foregroundStyle(MuralColor.secondary) }
                        }
                    }.padding(28).frame(maxWidth: .infinity, alignment: .leading)
                }
                .onChange(of: expired) { _, value in if value { coordinator.pronunciation.stop() } }
            }
            .background(MuralColor.cream).foregroundStyle(MuralColor.ink)
            .navigationTitle("Daily review").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Close") { dismiss() }.accessibilityIdentifier("close-daily-review") } }
        }.presentationDetents([.large])
            .onDisappear { coordinator.pronunciation.stop() }
            .onChange(of: coordinator.language.id) { _, id in if id != review.languageID { dismiss() } }
    }

    private func reviewCard(_ word: WordState) -> some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("\(selection + 1) of \(review.words.count) · Up to five minutes")
                .font(.caption).foregroundStyle(MuralColor.secondary).accessibilityIdentifier("daily-review-progress")
            Text("Recall in \(language.name)").font(.headline)
            Text(word.meaning).font(.system(.title, design: .rounded, weight: .medium))
                .accessibilityIdentifier("daily-review-cue")
            if revealed {
                Text(word.lemma).font(.system(.title2, design: .rounded, weight: .semibold))
                    .accessibilityIdentifier("daily-review-answer")
                if !draft.isEmpty { Text("Your answer: \(draft)").font(.body) }
                VocabularyPlaybackControls(player: coordinator.pronunciation, text: word.lemma, language: language,
                                           id: "daily-review-pronunciation", allowed: !coordinator.isRunning)
                if !word.example.isEmpty {
                    Text("From your conversation").font(.caption).foregroundStyle(MuralColor.secondary)
                    Text(word.example).font(.body)
                }
                Text("How did that feel before you revealed the answer?").font(.subheadline)
                ViewThatFits(in: .horizontal) {
                    HStack { gradeButton(.needsPractice); gradeButton(.remembered) }
                    VStack(alignment: .leading) { gradeButton(.needsPractice); gradeButton(.remembered) }
                }
            } else {
                Text("Think of the word or phrase before revealing it. You can also type it below.")
                    .font(.subheadline).foregroundStyle(MuralColor.secondary)
                TextField("Your answer (optional)", text: $draft, axis: .vertical)
                    .textFieldStyle(.roundedBorder).autocorrectionDisabled().textInputAutocapitalization(.never)
                    .accessibilityIdentifier("daily-review-draft")
                    .onChange(of: draft) { _, value in if value.count > 500 { draft = String(value.prefix(500)) } }
                Button("Reveal \(language.name)") { revealed = true }
                    .buttonStyle(.borderedProminent).tint(MuralColor.orange).accessibilityIdentifier("daily-review-reveal")
            }
        }
    }

    private func gradeButton(_ grade: ReviewGrade) -> some View {
        Button(grade == .remembered ? "Remembered" : "Needs practice") {
            guard revealed, selection < review.words.count, Date().timeIntervalSince(startedAt) < 300 else { return }
            coordinator.pronunciation.stop()
            guard coordinator.store.recordReview(wordID: review.words[selection].id, grade: grade) else {
                message = coordinator.store.error ?? "This word has changed. Close the review and try again."
                return
            }
            selection += 1; revealed = false; draft = ""; message = nil
        }.buttonStyle(.bordered).frame(minHeight: 44)
            .accessibilityIdentifier(grade == .remembered ? "daily-review-remembered" : "daily-review-needs-practice")
    }
}
