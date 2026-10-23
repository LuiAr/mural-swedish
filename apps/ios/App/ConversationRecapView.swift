import SwiftUI
import MuralCore

struct ConversationRecapView: View {
    let sessionID: UUID
    let coordinator: ConversationCoordinator
    @Environment(\.dismiss) private var dismiss
    @State private var service = StudyMaterialService()
    @State private var practising = false
    @State private var answer = ""
    @State private var revealed = false
    @FocusState private var answerFocused: Bool

    private var session: SessionRecord? { coordinator.store.sessions.first { $0.id == sessionID } }
    private var recap: ConversationRecap? { session.flatMap { session in session.recap.flatMap { $0.isValid(for: session) ? $0 : nil } } }
    private var context: String {
        let source = session.map { ConversationRecap.revisions(in: $0).joined(separator: "|") } ?? "deleted"
        return [source, coordinator.language.id, coordinator.conversationProvider.rawValue,
                String(coordinator.hasAIConsent), String(coordinator.isRunning)].joined(separator: "::")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if let recap {
                        recapContent(recap)
                    } else if session == nil {
                        Text("This conversation is no longer saved.").foregroundStyle(MuralColor.secondary)
                    } else {
                        Text("One small thing to practise.").font(.system(.title2, design: .rounded, weight: .semibold))
                        Text("Find a useful correction in your saved conversation, with a short English explanation and a chance to try again.")
                        if let reason = StudyMaterialService.unavailableReason(for: session, coordinator: coordinator) {
                            Text(reason).font(.footnote).foregroundStyle(MuralColor.secondary)
                        }
                        Button {
                            service.generateRecap(sessionID: sessionID, coordinator: coordinator)
                        } label: {
                            HStack {
                                if service.isLoading { ProgressView() }
                                Text(service.isLoading ? "Preparing your recap…" : "Create recap")
                            }.frame(maxWidth: .infinity, minHeight: 44)
                        }.buttonStyle(.borderedProminent).tint(MuralColor.orange)
                            .disabled(service.isLoading || StudyMaterialService.unavailableReason(for: session, coordinator: coordinator) != nil)
                            .accessibilityIdentifier("generate-recap")
                        Text("Uses this saved conversation and your personal API key. Generated suggestions can be mistaken.")
                            .font(.footnote).foregroundStyle(MuralColor.secondary)
                        if let error = service.error {
                            Text(error).font(.footnote).foregroundStyle(MuralColor.secondary).accessibilityIdentifier("recap-error")
                        }
                    }
                }.padding(26).frame(maxWidth: .infinity, alignment: .leading)
            }.scrollDismissesKeyboard(.interactively).background(MuralColor.cream).foregroundStyle(MuralColor.ink)
                .navigationTitle("Conversation recap").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }.accessibilityIdentifier("close-recap")
                    }
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") { answerFocused = false }
                    }
                }
        }.presentationDetents([.large])
            .onChange(of: context) { _, _ in service.cancel(); coordinator.pronunciation.stop(); dismiss() }
            .onDisappear { service.cancel(); coordinator.pronunciation.stop() }
    }

    @ViewBuilder private func recapContent(_ recap: ConversationRecap) -> some View {
        if recap.status == .noCorrection {
            Text("Nothing clear to correct this time.").font(.system(.title2, design: .rounded, weight: .semibold))
            Text(recap.explanation).accessibilityIdentifier("recap-no-correction")
            Text("You can keep practising in another conversation.").foregroundStyle(MuralColor.secondary)
        } else {
            Text(practising ? "Try the sentence again." : "A useful next step.")
                .font(.system(.title2, design: .rounded, weight: .semibold))
            Text("You said").font(.caption).foregroundStyle(MuralColor.secondary)
            Text(recap.quote).font(.title3).textSelection(.enabled).accessibilityIdentifier("recap-original")
            if practising {
                Text("Type your sentence before revealing the suggestion.").font(.subheadline)
                TextField("Your sentence", text: $answer, axis: .vertical)
                    .textInputAutocapitalization(.sentences).autocorrectionDisabled()
                    .focused($answerFocused)
                    .lineLimit(2...6).padding(16).background(.white, in: RoundedRectangle(cornerRadius: 16))
                    .onChange(of: answer) { _, value in if value.count > 1000 { answer = String(value.prefix(1000)) } }
                    .accessibilityIdentifier("recap-practice-answer")
                if !revealed {
                    Button("Compare with the suggestion") { answerFocused = false; revealed = true }
                        .disabled(answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .accessibilityIdentifier("recap-reveal-answer")
                }
            }
            if !practising || revealed {
                Text("One way to say it").font(.caption).foregroundStyle(MuralColor.secondary)
                Text(recap.suggestedSentence).font(.title3).textSelection(.enabled).accessibilityIdentifier("recap-suggestion")
                VocabularyPlaybackControls(player: coordinator.pronunciation, text: recap.suggestedSentence,
                    language: coordinator.language, id: "recap-pronunciation", allowed: !coordinator.isRunning)
                Text(recap.explanation).accessibilityIdentifier("recap-explanation")
                Button(practising ? "Try once more" : "Try again") {
                    coordinator.pronunciation.stop(); practising = true; revealed = false; answer = ""
                }.buttonStyle(.borderedProminent).tint(MuralColor.orange).accessibilityIdentifier("recap-try-again")
            }
            Text("This is self-check practice. It doesn’t change your spoken-recall bars. Other natural wording may also be correct.")
                .font(.footnote).foregroundStyle(MuralColor.secondary)
        }
    }
}
