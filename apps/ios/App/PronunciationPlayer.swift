import AVFoundation
import Observation
import SwiftUI
import MuralCore

/// Vocabulary listening owns audio only while Talk is disconnected.
@MainActor @Observable final class PronunciationPlayer: NSObject, AVSpeechSynthesizerDelegate {
    private(set) var activeID: String?
    private(set) var errorID: String?
    private(set) var error: String?
    @ObservationIgnored private let synthesizer = AVSpeechSynthesizer()
    @ObservationIgnored private var utterance: AVSpeechUtterance?
    @ObservationIgnored private var ownsAudioSession = false
    @ObservationIgnored private var previewTask: Task<Void, Never>?

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func play(_ text: String, language: LanguageModule, id: String, slow: Bool, allowed: Bool) {
        let requestID = id + (slow ? ":slow" : ":normal")
        if activeID == requestID { stop(); return }
        stop()
        error = nil; errorID = nil
        guard allowed else { return }
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        #if DEBUG && targetEnvironment(simulator)
        // Offline interface fixture: never requests a voice download or API audio.
        if ProcessInfo.processInfo.arguments.contains("--preview-pronunciation") {
            activeID = requestID
            previewTask = Task { [weak self] in
                do { try await Task.sleep(for: .seconds(5)) } catch { return }
                self?.stop()
            }
            return
        }
        #endif
        let voices = AVSpeechSynthesisVoice.speechVoices()
        let primary = language.locale.split(separator: "-").first.map(String.init) ?? language.id
        let voice = voices.first { $0.language == language.locale }
            ?? voices.first { $0.language.split(separator: "-").first.map(String.init) == primary }
        guard let voice else {
            errorID = id
            error = "Download a \(language.name) voice in your iPhone’s accessibility settings, then try again."
            return
        }
        do {
            let audio = AVAudioSession.sharedInstance()
            try audio.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try audio.setActive(true)
            ownsAudioSession = true
            let next = AVSpeechUtterance(string: text)
            next.voice = voice
            next.rate = slow ? AVSpeechUtteranceDefaultSpeechRate * 0.7 : AVSpeechUtteranceDefaultSpeechRate
            utterance = next; activeID = requestID
            synthesizer.speak(next)
        } catch {
            stop()
            errorID = id; self.error = "Audio couldn’t start. Check your audio output and try again."
        }
    }

    func stop() {
        error = nil; errorID = nil
        previewTask?.cancel(); previewTask = nil
        utterance = nil; activeID = nil
        synthesizer.stopSpeaking(at: .immediate)
        if ownsAudioSession {
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            ownsAudioSession = false
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor [weak self] in
            guard self?.utterance === utterance else { return }
            self?.stop()
        }
    }
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor [weak self] in
            guard self?.utterance === utterance else { return }
            self?.stop()
        }
    }
}

struct VocabularyPlaybackControls: View {
    let player: PronunciationPlayer
    let text: String
    let language: LanguageModule
    let id: String
    var allowed = true
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 16) { playButton(slow: false); playButton(slow: true) }
                VStack(alignment: .leading, spacing: 8) { playButton(slow: false); playButton(slow: true) }
            }
            if player.errorID == id, let error = player.error {
                Text(error).font(.footnote).foregroundStyle(MuralColor.secondary).accessibilityIdentifier(id + "-error")
            }
        }.disabled(!allowed || text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }
    private func playButton(slow: Bool) -> some View {
        let active = player.activeID == id + (slow ? ":slow" : ":normal")
        return Button {
            player.play(text, language: language, id: id, slow: slow, allowed: allowed)
        } label: {
            Label(active ? "Stop" : slow ? "Slow" : "Listen", systemImage: active ? "stop.fill" : slow ? "tortoise" : "speaker.wave.2")
                .font(.subheadline).frame(minHeight: 44)
        }.accessibilityLabel(active ? "Stop pronunciation" : slow ? "Hear slowly" : "Hear pronunciation")
            .accessibilityIdentifier(id + (slow ? "-slow" : "-play"))
    }
}
