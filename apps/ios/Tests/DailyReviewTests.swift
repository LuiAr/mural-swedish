import XCTest
@testable import MuralCore

final class DailyReviewTests: XCTestCase {
    private let date = Date(timeIntervalSinceReferenceDate: 1_000_000)
    private let day: TimeInterval = 86_400

    private func word(_ id: String = "sv|en bok|book", seen: Date? = nil) -> WordState {
        WordState(id: id, lemma: "en bok", meaning: "book", form: "bok", example: "Jag läser en bok.",
                  bars: 2, understandingCount: 1, independentCount: 2, lastSeen: seen ?? date, dueAt: date.addingTimeInterval(day))
    }
    private func archive() -> Archive {
        var session = SessionRecord(languageID: "sv")
        session.startedAt = date; session.endedAt = date.addingTimeInterval(20)
        session.append(Fragment(speaker: .user, text: "Jag läser en bok.", startMS: 100_000, endMS: 103_000, receivedAt: date))
        let passage = session.passages[0]
        session.assessments = [Assessment(passageID: passage.id, revisionKey: passage.revisionKey, outcome: .success,
            suggestedLevel: 1, nextGoal: "Talk about a book", capability: "Describes a book",
            words: [WordProposal(lemma: "en bok", meaning: "book", form: "bok", kind: .independent,
                confidence: 0.95, sourceIDs: passage.fragments.map(\.id), quote: "Jag läser en bok.", language: "sv")], createdAt: date)]
        var archive = Archive(); archive.sessions = [session]; return archive
    }

    func testQueueUsesSeparateScheduleDeduplicatesAndSeparatesLanguages() {
        let book = word(), other = word("nb|en bok|book")
        let reviewed = DailyReview.record(wordID: book.id, languageID: "sv", grade: .remembered, previous: nil, at: date)
        XCTAssertEqual(DailyReview.queue(words: [book, other, book], reviews: [], languageID: "sv", now: date).map(\.id), [book.id])
        XCTAssertTrue(DailyReview.queue(words: [book, other], reviews: [reviewed], languageID: "sv", now: date).isEmpty)
        XCTAssertEqual(DailyReview.queue(words: [book], reviews: [reviewed], languageID: "sv", now: reviewed.dueAt).map(\.id), [book.id])
        XCTAssertTrue(DailyReview.queue(words: [book], reviews: [], languageID: "sv", now: date.addingTimeInterval(-1)).isEmpty)
    }

    func testQueueHasStableOldestFirstOrderAndTenWordLimit() {
        let words = (0..<12).reversed().map { word("sv|word\($0)|meaning", seen: date.addingTimeInterval(Double($0))) }
        let queue = DailyReview.queue(words: words, reviews: [], languageID: "sv", now: date.addingTimeInterval(20))
        XCTAssertEqual(queue.count, 10)
        XCTAssertEqual(queue.map(\.id), (0..<10).map { "sv|word\($0)|meaning" })
        let ties = [word("sv|b|b"), word("sv|a|a")]
        XCTAssertEqual(DailyReview.queue(words: ties, reviews: [], languageID: "sv", now: date).map(\.id), ["sv|a|a", "sv|b|b"])
    }

    func testImportedUnicodeWordIdentityKeepsItsReviewSchedule() {
        let word = word("sv|å|river")
        let review = DailyReview.record(wordID: word.id.decomposedStringWithCanonicalMapping, languageID: "sv", grade: .remembered, previous: nil, at: date)
        XCTAssertTrue(DailyReview.queue(words: [word], reviews: [review], languageID: "sv", now: date).isEmpty)
    }

    func testRememberedIntervalsAdvanceOnlyWhenDueAndNeedPracticeResets() {
        var previous: WordReview?
        var at = date
        for expectedDays in [1, 3, 7, 14, 14] {
            let review = DailyReview.record(wordID: word().id, languageID: "sv", grade: .remembered, previous: previous, at: at)
            XCTAssertEqual(review.dueAt.timeIntervalSince(at), Double(expectedDays) * day)
            XCTAssertTrue(review.isValid)
            previous = review; at = review.dueAt
        }
        let reset = DailyReview.record(wordID: word().id, languageID: "sv", grade: .needsPractice, previous: previous, at: at)
        XCTAssertEqual(reset.consecutiveRemembered, 0)
        XCTAssertEqual(reset.dueAt.timeIntervalSince(at), day)
        let next = DailyReview.record(wordID: word().id, languageID: "sv", grade: .remembered, previous: reset, at: reset.dueAt)
        XCTAssertEqual(next.consecutiveRemembered, 1)
        let early = DailyReview.record(wordID: next.wordID, languageID: "sv", grade: .remembered, previous: next, at: reset.dueAt.addingTimeInterval(1))
        XCTAssertEqual(early.consecutiveRemembered, 1)
        let differentWord = DailyReview.record(wordID: "sv|ett hus|house", languageID: "sv", grade: .remembered, previous: previous, at: at)
        XCTAssertEqual(differentWord.consecutiveRemembered, 1)
    }

    func testLegacyBackupAndReviewRoundTripPreserveConversationEvidence() throws {
        let original = archive()
        XCTAssertNil(try Archive.decode(original.encoded()).wordReviews)
        let before = LearningEngine.project(original.sessions, languageID: "sv", now: date).words[0]
        var reviewed = original
        reviewed.wordReviews = [DailyReview.record(wordID: before.id, languageID: "sv", grade: .remembered, previous: nil, at: date)]
        let restored = try Archive.decode(reviewed.encoded())
        XCTAssertEqual(restored.wordReviews, reviewed.wordReviews)
        let after = LearningEngine.project(restored.sessions, languageID: "sv", now: date).words[0]
        XCTAssertEqual(before.bars, after.bars)
        XCTAssertEqual(before.independentCount, after.independentCount)
        XCTAssertEqual(before.dueAt, after.dueAt)
        XCTAssertEqual(restored.sessions[0].assessments.count, original.sessions[0].assessments.count)
    }

    func testImportMergesNewestReviewWithoutReplacingCurrentPreferences() throws {
        var current = archive(), incoming = current
        let first = DailyReview.record(wordID: word().id, languageID: "sv", grade: .remembered, previous: nil, at: date)
        let second = DailyReview.record(wordID: word().id, languageID: "sv", grade: .remembered, previous: first, at: first.dueAt)
        current.wordReviews = [first]; incoming.wordReviews = [second]
        incoming.preferences.learningLanguageID = "sv"
        let merged = try current.merging(incoming)
        XCTAssertEqual(merged.wordReviews, [second])
        XCTAssertEqual(merged.sessions.count, 1)
        XCTAssertEqual(merged.preferences.learningLanguageID, current.preferences.learningLanguageID)
        XCTAssertEqual(try merged.merging(current).wordReviews, [second])
        XCTAssertEqual(try merged.merging(archive()).wordReviews, [second])
    }

    func testHiddenDeletedAndUnsupportedWordReferencesCannotResurrectVocabulary() throws {
        var archive = archive()
        let review = DailyReview.record(wordID: word().id, languageID: "sv", grade: .remembered, previous: nil, at: date)
        archive.wordReviews = [review]
        archive.preferences.hiddenWords = [review.wordID]
        XCTAssertNil(try Archive.decode(archive.encoded()).wordReviews)
        archive.preferences.hiddenWords = []
        archive.sessions = []; archive.pruneWordReviews()
        XCTAssertNil(archive.wordReviews)
        archive.wordReviews = [review]
        XCTAssertNil(try Archive.decode(archive.encoded()).wordReviews)
        XCTAssertTrue(DailyReview.queue(words: [], reviews: [review], languageID: "sv", now: review.dueAt).isEmpty)
    }

    func testMalformedAndDuplicateReviewRecordsAreRejected() throws {
        var archive = archive()
        let good = DailyReview.record(wordID: word().id, languageID: "sv", grade: .remembered, previous: nil, at: date)
        archive.wordReviews = [good, good]
        XCTAssertThrowsError(try Archive.decode(archive.encoded()))
        var invalid = good; invalid.languageID = "nb"
        archive.wordReviews = [invalid]; XCTAssertThrowsError(try Archive.decode(archive.encoded()))
        invalid = good; invalid.dueAt = date.addingTimeInterval(-1)
        archive.wordReviews = [invalid]; XCTAssertThrowsError(try Archive.decode(archive.encoded()))
        invalid = good; invalid.consecutiveRemembered = 5
        archive.wordReviews = [invalid]; XCTAssertThrowsError(try Archive.decode(archive.encoded()))
    }
}
