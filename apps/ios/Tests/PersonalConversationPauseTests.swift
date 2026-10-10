import XCTest
@testable import MuralCore

final class PersonalConversationPauseTests: XCTestCase {
    private func paused() -> SessionRecord {
        var record = SessionRecord(languageID: "sv", themeID: "restaurant", title: "Table for two")
        record.append(Fragment(id: "old", speaker: .assistant, text: "Ett bord för två?", startMS: 0, endMS: 2000))
        record.append(Fragment(speaker: .user, text: "Ja, tack.", startMS: 2500, endMS: 3000))
        record.endedAt = .now; record.endReason = "Paused"; record.voiceSeconds = 90; record.usageFinal = true
        record.translations["saved"] = "A table for two?"
        return record
    }

    func testCheckpointRoundTripKeepsConversationAndNoCredentialOrTranscriptCopy() throws {
        let record = paused()
        let checkpoint = PersonalConversationPause(sessionID: record.id, estimatedVoiceSeconds: 90, closureConfirmed: true)
        let encoded = try JSONEncoder().encode(checkpoint)
        let restored = try JSONDecoder().decode(PersonalConversationPause.self, from: encoded)
        let recovered = try XCTUnwrap(restored.recover(from: [record], languageID: "sv"))
        XCTAssertEqual(recovered.id, record.id)
        XCTAssertEqual(recovered.themeID, "restaurant")
        XCTAssertEqual(recovered.passages.map(\.text), ["Ett bord för två?", "Ja, tack."])
        XCTAssertEqual(recovered.translations["saved"], "A table for two?")
        XCTAssertEqual(restored.estimatedVoiceSeconds, 90)
        XCTAssertEqual(try JSONSerialization.jsonObject(with: encoded) as? [String: Any] != nil, true)
        XCTAssertFalse(String(decoding: encoded, as: UTF8.self).contains("Ett bord"))
    }

    func testDeletedWrongLanguageActiveAndCompletedRecordsCannotResume() {
        var record = paused()
        let checkpoint = PersonalConversationPause(sessionID: record.id, estimatedVoiceSeconds: 90, closureConfirmed: true)
        XCTAssertNil(checkpoint.recover(from: [], languageID: "sv"))
        XCTAssertNil(checkpoint.recover(from: [record], languageID: "zh"))
        record.endedAt = nil
        XCTAssertNil(checkpoint.recover(from: [record], languageID: "sv"))
        record.endedAt = .now; record.endReason = "Ended by you"
        XCTAssertNil(checkpoint.recover(from: [record], languageID: "sv"))
    }

    func testUnconfirmedCloseStillAllowsResumeWithoutClaimingConfirmation() {
        let record = paused()
        let checkpoint = PersonalConversationPause(sessionID: record.id, estimatedVoiceSeconds: 91.5, closureConfirmed: false)
        XCTAssertNotNil(checkpoint.recover(from: [record], languageID: "sv"))
        XCTAssertFalse(checkpoint.closureConfirmed)
        XCTAssertNil(PersonalConversationPause(sessionID: record.id, estimatedVoiceSeconds: -.infinity, closureConfirmed: false).recover(from: [record], languageID: "sv"))
    }

    func testFreshProviderClockCannotMergeOrOverwriteOldTranscript() throws {
        var record = paused()
        let connection = UUID()
        let raw = Fragment(id: "old", speaker: .assistant, text: "Vad vill du äta?", startMS: 0, endMS: 1000)
        let fragment = try XCTUnwrap(PersonalConversationPause.fragment(raw, offset: PersonalConversationPause.transcriptOffset(for: record), connectionID: connection))
        record.append(fragment)
        record.append(fragment) // repeated provider delivery remains idempotent
        XCTAssertEqual(record.fragments.count, 3)
        XCTAssertEqual(record.passages.map(\.text), ["Ett bord för två?", "Ja, tack.", "Vad vill du äta?"])
        XCTAssertEqual(fragment.startMS, 6000)
        XCTAssertEqual(record.fragments[0].id, "old")
        let history = ConversationContinuation.history(record.passages.map { ($0.speaker, $0.text) })
        XCTAssertEqual(history.count, 3)
    }

    func testMalformedProviderTimestampCannotOverflowArchiveTimeline() {
        let raw = Fragment(speaker: .assistant, text: "test", startMS: Int.max - 1, endMS: Int.max)
        XCTAssertNil(PersonalConversationPause.fragment(raw, offset: 3000, connectionID: UUID()))
    }

    func testTwoConnectionsExcludeLongBreakAndCreditEachCreation() {
        var first = VoiceCostMeter()
        first.started(now: 100)
        first.update(seconds: 120, now: 220, final: true)
        first.finish(now: 220)
        let saved = first.estimatedSeconds(now: 820)!
        var second = VoiceCostMeter()
        second.created(); second.started(now: 820)
        second.update(seconds: 180, now: 1000, final: true)
        XCTAssertEqual((saved + second.estimatedSeconds(now: 1000)!) * VoiceCostMeter.usdPerMinute / 60, 0.25, accuracy: 0.000001)
    }
}
