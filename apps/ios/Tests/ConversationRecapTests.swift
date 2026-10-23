import XCTest
@testable import MuralCore

final class ConversationRecapTests: XCTestCase {
    private let date = Date(timeIntervalSinceReferenceDate: 1_000_000)
    private let quote = "Jag läser en bok igår."

    private func session() -> SessionRecord {
        var session = SessionRecord(languageID: "sv")
        session.startedAt = date; session.endedAt = date.addingTimeInterval(30)
        session.append(Fragment(id: "learner", speaker: .user, text: quote, startMS: 100_000,
            endMS: 103_000, receivedAt: date))
        session.append(Fragment(id: "teacher", speaker: .assistant, text: "Du läste en bok igår.",
            startMS: 104_000, endMS: 106_000, receivedAt: date))
        let passage = session.passages[0]
        session.assessments = [Assessment(passageID: passage.id, revisionKey: passage.revisionKey,
            outcome: .partial, suggestedLevel: 1, nextGoal: "Talk about yesterday", capability: "",
            words: [WordProposal(lemma: "en bok", meaning: "book", form: "bok", kind: .assisted,
                confidence: 0.95, sourceIDs: ["learner"], quote: quote, language: "sv")], createdAt: date)]
        return session
    }

    private func response() -> ConversationRecapResponse {
        ConversationRecapResponse(status: .correction, passageID: "learner", quote: quote,
            suggestedSentence: "Jag läste en bok igår.", explanation: "Use the past tense läste with igår, yesterday.")
    }

    func testCorrectionRequiresExactCurrentLearnerQuote() throws {
        let session = session()
        let valid = try XCTUnwrap(response().validated(for: session, at: date))
        XCTAssertTrue(valid.isValid(for: session))
        var wrong = response(); wrong.quote = "jag läser en bok igår."
        XCTAssertNil(wrong.validated(for: session, at: date))
        wrong = response(); wrong.quote = "A sentence the learner never said."
        XCTAssertNil(wrong.validated(for: session, at: date))
        wrong = response(); wrong.passageID = "teacher"; wrong.quote = "Du läste en bok igår."
        XCTAssertNil(wrong.validated(for: session, at: date))
        wrong = response(); wrong.suggestedSentence = quote
        XCTAssertNil(wrong.validated(for: session, at: date))
    }

    func testEditedOrExtendedTranscriptInvalidatesRecap() throws {
        var session = session()
        let recap = try XCTUnwrap(response().validated(for: session, at: date))
        session.recap = recap
        session.correctFragment(id: "learner", text: "Jag läste en bok igår.")
        XCTAssertNil(session.recap)
        XCTAssertFalse(recap.isValid(for: session))
        XCTAssertTrue(session.assessments.isEmpty)

        session = self.session(); session.recap = response().validated(for: session, at: date)
        session.append(Fragment(id: "later", speaker: .assistant, text: "Berätta mer.", startMS: 110_000,
            endMS: 111_000, receivedAt: date))
        XCTAssertNil(session.recap)

        session = self.session(); session.recap = response().validated(for: session, at: date)
        session.endedAt = nil; session.invalidateChangedAssessments()
        XCTAssertNil(session.recap)
    }

    func testNoCorrectionIsExplicitAndStillRequiresAnEndedLearnerConversation() throws {
        let noCorrection = ConversationRecapResponse(status: .noCorrection, passageID: "", quote: "",
            suggestedSentence: "", explanation: "No clear correction was found in the saved wording.")
        let session = session()
        XCTAssertEqual(try XCTUnwrap(noCorrection.validated(for: session, at: date)).status, .noCorrection)
        var active = session; active.endedAt = nil
        XCTAssertNil(noCorrection.validated(for: active, at: date))
        var empty = session; empty.fragments.removeAll()
        XCTAssertNil(noCorrection.validated(for: empty, at: date))
        var invented = noCorrection; invented.quote = quote
        XCTAssertNil(invented.validated(for: session, at: date))
    }

    func testLanguageSessionRevisionAndBoundsAreChecked() throws {
        let session = session()
        var recap = try XCTUnwrap(response().validated(for: session, at: date))
        recap.sessionID = UUID(); XCTAssertFalse(recap.isValid(for: session))
        recap = try XCTUnwrap(response().validated(for: session, at: date))
        recap.languageID = "nb"; XCTAssertFalse(recap.isValid(for: session))
        recap = try XCTUnwrap(response().validated(for: session, at: date))
        recap.sourceRevisions = ["learner:99"]; XCTAssertFalse(recap.isValid(for: session))
        var long = response(); long.explanation = String(repeating: "x", count: 801)
        XCTAssertNil(long.validated(for: session, at: date))
        long = response(); long.suggestedSentence = String(repeating: "x", count: 1001)
        XCTAssertNil(long.validated(for: session, at: date))
    }

    func testLegacyBackupRoundTripAndImportKeepStudySeparateFromLearning() throws {
        var original = Archive(); original.sessions = [session()]
        XCTAssertNil(try Archive.decode(original.encoded()).sessions[0].recap)
        let before = LearningEngine.project(original.sessions, languageID: "sv", now: date).words
        var studied = original
        studied.sessions[0].recap = response().validated(for: studied.sessions[0], at: date)
        let restored = try Archive.decode(studied.encoded())
        XCTAssertEqual(restored.sessions[0].recap, studied.sessions[0].recap)
        XCTAssertEqual(restored.sessions[0].assessments.count, original.sessions[0].assessments.count)
        XCTAssertEqual(restored.sessions[0].fragments, original.sessions[0].fragments)
        let after = LearningEngine.project(restored.sessions, languageID: "sv", now: date).words
        XCTAssertEqual(before.map(\.id), after.map(\.id))
        XCTAssertEqual(before.map(\.bars), after.map(\.bars))
        XCTAssertEqual(before.map(\.independentCount), after.map(\.independentCount))
        XCTAssertEqual(try Archive().merging(restored).sessions[0].recap, studied.sessions[0].recap)

        var invalid = studied
        invalid.sessions[0].recap?.quote = "Invented source."
        XCTAssertThrowsError(try Archive.decode(invalid.encoded()))
    }

    func testSameSessionImportMergesOnlyNewerMatchingRecap() throws {
        var current = Archive(); current.sessions = [session()]
        current.sessions[0].inputTokens = 40
        var incoming = current
        incoming.sessions[0].recap = response().validated(for: incoming.sessions[0], at: date)
        incoming.sessions[0].inputTokens = 100
        incoming.sessions[0].assessments.removeAll()
        incoming.preferences.learningLanguageID = "sv"
        let filled = try current.merging(incoming)
        XCTAssertEqual(filled.sessions[0].recap, incoming.sessions[0].recap)
        XCTAssertEqual(filled.sessions[0].inputTokens, 40)
        XCTAssertEqual(filled.sessions[0].assessments.count, current.sessions[0].assessments.count)
        XCTAssertEqual(filled.preferences.learningLanguageID, current.preferences.learningLanguageID)
        var newer = incoming
        newer.sessions[0].recap?.createdAt = date.addingTimeInterval(1)
        XCTAssertEqual(try filled.merging(newer).sessions[0].recap, newer.sessions[0].recap)
        XCTAssertEqual(try filled.merging(newer).merging(incoming).sessions[0].recap, newer.sessions[0].recap)
        current.sessions[0].correctFragment(id: "learner", text: "Jag läste en bok igår.")
        XCTAssertNil(try current.merging(incoming).sessions[0].recap)
        XCTAssertEqual(try current.merging(incoming).sessions[0].fragments, current.sessions[0].fragments)
    }
}
