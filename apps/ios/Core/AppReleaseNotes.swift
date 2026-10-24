import Foundation

/// Bundled iPhone release notes. These are app metadata, not learning records.
public struct AppReleaseHighlight: Identifiable, Equatable, Sendable {
    public let id: String
    public let symbol: String
    public let title: String
    public let detail: String
}

public struct AppReleaseNote: Identifiable, Equatable, Sendable {
    public let version: String
    public let build: Int
    public let name: String
    public let date: String
    public let highlights: [AppReleaseHighlight]
    public var id: Int { build }
}

public enum AppReleaseNotes {
    /// Keep every shipped entry, newest first. Build numbers increase across versions.
    public static let all: [AppReleaseNote] = [
        AppReleaseNote(version: "1.0", build: 10, name: "Updates at a glance", date: "24 October 2026", highlights: [
            AppReleaseHighlight(id: "whats-new", symbol: "sparkles", title: "A home for what’s new",
                detail: "Open What’s New in Settings to see what changed, the build you’re using, and earlier updates. It works offline, whenever you need it.")
        ]),
        AppReleaseNote(version: "1.0", build: 9, name: "More ways to practise", date: "24 October 2026", highlights: [
            AppReleaseHighlight(id: "listening", symbol: "speaker.wave.2", title: "Listen at your pace",
                detail: "Hear saved words and conversation examples at normal or slower speed. Find Listen and Slow in Words and on your flashcards."),
            AppReleaseHighlight(id: "daily-review", symbol: "arrow.clockwise", title: "A little recall, every day",
                detail: "Choose Daily review in Words for up to ten due words. Think of the word from its meaning, reveal it, then save how well you remembered."),
            AppReleaseHighlight(id: "conversation-recap", symbol: "text.bubble", title: "Give that sentence another try",
                detail: "Open a past conversation to create a recap with a useful wording suggestion and a short explanation. Try again lets you practise without changing the original transcript."),
            AppReleaseHighlight(id: "swedish-forms", symbol: "character.book.closed", title: "Swedish forms, close at hand",
                detail: "Open a Swedish noun or verb in Words to save its forms for that meaning. Saved forms stay available offline. Creating a recap or forms uses your personal key.")
        ])
    ]

    /// Never label an older release as the update for an unknown running build.
    public static func current(version: String, build: String) -> AppReleaseNote? {
        guard let number = Int(build) else { return nil }
        return all.first { $0.version == version && $0.build == number }
    }

    /// Hide future entries when this catalog is used by an older build.
    public static func history(beforeBuild build: String) -> [AppReleaseNote] {
        guard let number = Int(build) else { return [] }
        return all.filter { $0.build < number }.sorted { $0.build > $1.build }
    }
}
