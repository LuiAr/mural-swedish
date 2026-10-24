import Foundation

/// Self-reported vocabulary practice is kept separate from conversation evidence.
public enum ReviewGrade: String, Codable, Sendable { case remembered, needsPractice }

public struct WordReview: Codable, Equatable, Sendable {
    public var wordID: String
    public var languageID: String
    public var reviewedAt: Date
    public var dueAt: Date
    public var consecutiveRemembered: Int

    public init(wordID: String, languageID: String, reviewedAt: Date, dueAt: Date, consecutiveRemembered: Int) {
        self.wordID = wordID; self.languageID = languageID
        self.reviewedAt = reviewedAt; self.dueAt = dueAt; self.consecutiveRemembered = consecutiveRemembered
    }

    public var isValid: Bool {
        let interval = dueAt.timeIntervalSince(reviewedAt)
        return LanguageRegistry.module(for: languageID) != nil
            && wordID.hasPrefix(languageID + "|") && wordID.count > languageID.count + 1 && wordID.count <= 500
            && reviewedAt >= .distantPast && dueAt <= .distantFuture
            && reviewedAt.timeIntervalSinceReferenceDate.isFinite && dueAt.timeIntervalSinceReferenceDate.isFinite
            && (0...4).contains(consecutiveRemembered) && (86_400...1_209_600).contains(interval)
    }
}

public enum DailyReview {
    public static let maximumWords = 10
    public static let maximumSeconds = 300
    private static let intervals = [1, 3, 7, 14]

    /// New saved words are available immediately. Later dates belong to this
    /// practice schedule, never to the spoken-recall bars in LearningEngine.
    public static func queue(words: [WordState], reviews: [WordReview], languageID: String, now: Date = .now) -> [WordState] {
        let progress = Dictionary(reviews.filter { $0.languageID == languageID && $0.isValid }.map { ($0.wordID, $0) },
                                  uniquingKeysWith: { $0.reviewedAt >= $1.reviewedAt ? $0 : $1 })
        return FlashcardDeck(words: words, languageID: languageID).words
            .filter { (progress[$0.id]?.dueAt ?? $0.lastSeen) <= now }
            .sorted {
                let first = progress[$0.id]?.dueAt ?? $0.lastSeen
                let second = progress[$1.id]?.dueAt ?? $1.lastSeen
                return first == second ? $0.id < $1.id : first < second
            }.prefix(maximumWords).map { $0 }
    }

    public static func record(wordID: String, languageID: String, grade: ReviewGrade,
                              previous: WordReview?, at date: Date = .now) -> WordReview {
        let previous = previous.flatMap { $0.wordID == wordID && $0.languageID == languageID && $0.isValid ? $0 : nil }
        let count: Int
        if grade == .needsPractice { count = 0 }
        else if let previous, date < previous.dueAt {
            // Reopening a sheet or practising early cannot jump through intervals.
            count = max(1, previous.consecutiveRemembered)
        } else { count = min(4, (previous?.consecutiveRemembered ?? 0) + 1) }
        let days = intervals[max(0, count - 1)]
        return WordReview(wordID: wordID, languageID: languageID, reviewedAt: date,
                          dueAt: date.addingTimeInterval(Double(days) * 86_400), consecutiveRemembered: count)
    }
}
