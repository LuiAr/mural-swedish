import XCTest
@testable import MuralCore

final class SwedishWordFormsTests: XCTestCase {
    private let date = Date(timeIntervalSinceReferenceDate: 1_000_000)

    private func word() -> WordState {
        WordState(id: "sv|en bok|book", lemma: "en bok", meaning: "book", form: "bok",
                  example: "Jag läser en bok.", bars: 2, understandingCount: 1, independentCount: 2,
                  lastSeen: date, dueAt: date.addingTimeInterval(86_400))
    }
    private func noun() -> SwedishWordFormsResponse {
        SwedishWordFormsResponse(kind: .noun, forms: [
            .init(slot: .indefiniteSingular, text: "en bok"), .init(slot: .definiteSingular, text: "boken"),
            .init(slot: .indefinitePlural, text: "böcker"), .init(slot: .definitePlural, text: "böckerna")
        ], note: "Bok has the irregular plural böcker.")
    }
    private func archive() -> Archive {
        var session = SessionRecord(languageID: "sv")
        session.startedAt = date; session.endedAt = date.addingTimeInterval(20)
        session.append(Fragment(id: "learner", speaker: .user, text: word().example,
                                startMS: 100_000, endMS: 103_000, receivedAt: date))
        let passage = session.passages[0]
        session.assessments = [Assessment(passageID: passage.id, revisionKey: passage.revisionKey,
            outcome: .success, suggestedLevel: 1, nextGoal: "Talk about a book", capability: "",
            words: [WordProposal(lemma: "en bok", meaning: "book", form: "bok", kind: .independent,
                confidence: 0.95, sourceIDs: ["learner"], quote: word().example, language: "sv")], createdAt: date)]
        var archive = Archive(); archive.sessions = [session]; return archive
    }

    func testNounSlotsPreserveDiacriticsAndExplicitMissingForms() throws {
        let card = try XCTUnwrap(noun().validated(for: word(), at: date))
        XCTAssertEqual(card.forms.map(\.text), ["en bok", "boken", "böcker", "böckerna"])
        var partial = noun(); partial.forms[2].text = nil; partial.forms[3].text = nil
        XCTAssertNotNil(partial.validated(for: word(), at: date))
        partial.forms[0].text = nil; partial.forms[1].text = nil
        XCTAssertNil(partial.validated(for: word(), at: date))
    }

    func testVerbParticlesAndReflexivesRemainIntact() throws {
        var verb = word()
        verb.id = "sv|att känna sig|to feel"; verb.lemma = "att känna sig"; verb.meaning = "to feel"
        verb.form = "känner mig"; verb.example = "Jag känner mig lugn."
        let response = SwedishWordFormsResponse(kind: .verb, forms: [
            .init(slot: .infinitive, text: "att känna sig"), .init(slot: .present, text: "känner sig"),
            .init(slot: .past, text: "kände sig"), .init(slot: .supine, text: "känt sig")
        ], note: "Keep the reflexive pronoun with the verb.")
        let card = try XCTUnwrap(response.validated(for: verb, at: date))
        XCTAssertEqual(card.forms.map(\.text), ["att känna sig", "känner sig", "kände sig", "känt sig"])
        XCTAssertEqual(try JSONDecoder().decode(SwedishWordForms.self, from: JSONEncoder().encode(card)), card)
    }

    func testUnavailableResultDoesNotInventAParadigm() throws {
        let response = SwedishWordFormsResponse(kind: .unavailable, forms: [], note: "This sense is not a noun or verb.")
        let card = try XCTUnwrap(response.validated(for: word(), at: date))
        XCTAssertTrue(card.forms.isEmpty)
        var invented = response; invented.forms = noun().forms
        XCTAssertNil(invented.validated(for: word(), at: date))
        let unknownKind = Data(#"{"kind":"adjective","forms":[],"note":"Not a noun or verb."}"#.utf8)
        XCTAssertThrowsError(try JSONDecoder().decode(SwedishWordFormsResponse.self, from: unknownKind))
    }

    func testInvalidSlotsTextAndMetadataAreRejected() throws {
        var response = noun(); response.forms.reverse()
        XCTAssertNil(response.validated(for: word(), at: date))
        response = noun(); response.forms[1].slot = .indefiniteSingular
        XCTAssertNil(response.validated(for: word(), at: date))
        response = noun(); response.forms.removeLast()
        XCTAssertNil(response.validated(for: word(), at: date))
        response = noun(); response.forms[0].text = String(repeating: "x", count: 121)
        XCTAssertNil(response.validated(for: word(), at: date))
        response = noun(); response.forms[0].text = "  "
        XCTAssertNil(response.validated(for: word(), at: date))
        response = noun(); response.note = String(repeating: "x", count: 601)
        XCTAssertNil(response.validated(for: word(), at: date))
        var card = try XCTUnwrap(noun().validated(for: word(), at: date))
        card.createdAt = Date(timeIntervalSinceReferenceDate: .infinity)
        XCTAssertFalse(card.isWellFormed)
    }

    func testCacheReusesSameSenseAfterFreshPracticeButSeparatesOtherSenses() throws {
        let card = try XCTUnwrap(noun().validated(for: word(), at: date))
        var fresh = word(); fresh.lastSeen = date.addingTimeInterval(86_400)
        fresh.example = "Boken ligger på bordet."; fresh.form = "boken"; fresh.bars = 3
        XCTAssertTrue(card.isValid(for: fresh))
        fresh.meaning = "a booking"; XCTAssertFalse(card.isValid(for: fresh))
        fresh = word(); fresh.id = "nb|en bok|book"; XCTAssertFalse(card.isValid(for: fresh))
        fresh = word(); fresh.lemma = "ett hus"; XCTAssertFalse(card.isValid(for: fresh))
    }

    func testLegacyBackupAndFormsRoundTripDoNotChangeLearningEvidence() throws {
        let original = archive()
        XCTAssertNil(try Archive.decode(original.encoded()).swedishWordForms)
        let before = LearningEngine.project(original.sessions, languageID: "sv", now: date).words
        var studied = original
        studied.swedishWordForms = [try XCTUnwrap(noun().validated(for: before[0], at: date))]
        let restored = try Archive.decode(studied.encoded())
        XCTAssertEqual(restored.swedishWordForms, studied.swedishWordForms)
        XCTAssertEqual(restored.sessions[0].fragments, original.sessions[0].fragments)
        XCTAssertEqual(restored.sessions[0].assessments.count, original.sessions[0].assessments.count)
        let after = LearningEngine.project(restored.sessions, languageID: "sv", now: date).words
        XCTAssertEqual(before.map(\.bars), after.map(\.bars))
        XCTAssertEqual(before.map(\.independentCount), after.map(\.independentCount))
    }

    func testImportMergesNewestMatchingCardWithoutReplacingSourceOrPreferences() throws {
        var current = archive(), incoming = current
        let available = LearningEngine.project(current.sessions, languageID: "sv", now: date).words[0]
        let first = try XCTUnwrap(noun().validated(for: available, at: date))
        var second = first; second.createdAt = date.addingTimeInterval(60); second.note = "A newer checked reference card."
        current.swedishWordForms = [first]; incoming.swedishWordForms = [second]
        incoming.preferences.learningLanguageID = "sv"
        let merged = try current.merging(incoming)
        XCTAssertEqual(merged.swedishWordForms, [second])
        XCTAssertEqual(merged.sessions[0].fragments, current.sessions[0].fragments)
        XCTAssertEqual(merged.preferences.learningLanguageID, current.preferences.learningLanguageID)
        XCTAssertEqual(try merged.merging(current).swedishWordForms, [second])
    }

    func testHiddenDeletedAndEditedSourcesCannotRestoreCachedForms() throws {
        var archive = archive()
        let available = LearningEngine.project(archive.sessions, languageID: "sv", now: date).words[0]
        let card = try XCTUnwrap(noun().validated(for: available, at: date))
        archive.swedishWordForms = [card]; archive.preferences.hiddenWords = [card.wordID]
        XCTAssertNil(try Archive.decode(archive.encoded()).swedishWordForms)
        archive.preferences.hiddenWords = []; archive.sessions = []; archive.pruneSwedishWordForms()
        XCTAssertNil(archive.swedishWordForms)
        archive.swedishWordForms = [card]
        XCTAssertNil(try Archive.decode(archive.encoded()).swedishWordForms)
        archive = self.archive(); archive.swedishWordForms = [card]
        archive.sessions[0].correctFragment(id: "learner", text: "Jag dricker kaffe.")
        archive.pruneSwedishWordForms()
        XCTAssertNil(archive.swedishWordForms)
    }

    func testMalformedOrDuplicateCachedCardsAreRejected() throws {
        var archive = archive()
        let available = LearningEngine.project(archive.sessions, languageID: "sv", now: date).words[0]
        let card = try XCTUnwrap(noun().validated(for: available, at: date))
        archive.swedishWordForms = [card, card]
        XCTAssertThrowsError(try Archive.decode(archive.encoded()))
        var invalid = card; invalid.forms[0].text = ""
        archive.swedishWordForms = [invalid]
        XCTAssertThrowsError(try Archive.decode(archive.encoded()))
    }

    func testEncodeAndDecodeEnforceUTF8ByteLimit() throws {
        var archive = Archive()
        // Fifteen million characters fit the count limit; UTF-8 plus JSON does not.
        archive.preferences.interests = String(repeating: "ö", count: Archive.maximumEncodedBytes / 2)
        XCTAssertThrowsError(try archive.encoded()) { error in
            guard case ArchiveError.tooLarge = error else { return XCTFail("Expected byte-size rejection, got \(error)") }
        }
        XCTAssertThrowsError(try Archive.decode(Data(repeating: 0x20, count: Archive.maximumEncodedBytes + 1))) { error in
            guard case ArchiveError.tooLarge = error else { return XCTFail("Expected import-size rejection, got \(error)") }
        }
    }
}
