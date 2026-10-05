import XCTest
@testable import MuralCore

final class SwedishTests: XCTestCase {
    private func record(_ text: String, lemma: String, form: String, meaning: String,
                        day: Int = 0, languageID: String = "sv", supported: Bool = false) -> SessionRecord {
        let date = Date(timeIntervalSince1970: 1_780_000_000 + Double(day) * 86400)
        var session = SessionRecord(languageID: languageID, themeID: "coffee")
        session.startedAt = date
        session.append(Fragment(speaker: .user, text: text, startMS: 100_000, endMS: 103_000,
                                receivedAt: date, meaningVisible: supported))
        let passage = session.passages[0]
        session.assessments = [Assessment(passageID: passage.id, revisionKey: passage.revisionKey,
            outcome: .success, suggestedLevel: 2, nextGoal: "Berätta om en bok.", capability: "Describes a book",
            words: [WordProposal(lemma: lemma, meaning: meaning, form: form, kind: .independent,
                confidence: 0.95, sourceIDs: passage.fragments.map(\.id), quote: text, language: languageID)],
            createdAt: date)]
        session.endedAt = date.addingTimeInterval(104)
        return session
    }

    func testSwedishFlowsUseSwedishWithSeparateEnglishSupport() throws {
        let language = try XCTUnwrap(LanguageRegistry.module(for: "sv"))
        let learner = LearningEngine.project([], languageID: "sv")
        let prompts = [
            TeachingPolicy.voice(language: language, learner: learner, theme: language.themes[0], interests: "", meaningLanguage: "English"),
            TeachingPolicy.assessment(language: language), TeachingPolicy.greeting(language: language),
            TeachingPolicy.help(language: language), TeachingPolicy.redirect(language: language),
            TeachingPolicy.translation(language: language, meaningLanguage: "English"),
            TeachingPolicy.delegation(language: language), TeachingPolicy.typedReply(language: language),
            TeachingPolicy.lookup(language: language, meaningLanguage: "English"), TeachingPolicy.currentTopic(language: language)
        ]
        for prompt in prompts {
            XCTAssertTrue(prompt.contains("Swedish"))
            XCTAssertFalse(prompt.contains("Norwegian"))
            XCTAssertFalse(prompt.contains("Bokmål"))
        }
        XCTAssertTrue(prompts[0].contains("Speak ONLY Swedish."))
        XCTAssertTrue(prompts[0].contains("Meaning subtitles in English are a separate application feature."))
        XCTAssertTrue(prompts[0].contains("Tala bara svenska"))
        XCTAssertTrue(prompts[0].contains("French, English or mixed learner replies as support"))
        XCTAssertTrue(prompts[1].contains("Use language sv for target-language evidence"))
        XCTAssertTrue(prompts[1].contains("pitch-accent errors from a transcript alone"))
        XCTAssertTrue(prompts[5].contains("into English"))
        XCTAssertTrue(prompts[8].contains("Use English, 2–3 short sentences."))
        XCTAssertEqual(language.locale, "sv-SE")
        XCTAssertEqual(language.nativeName, "Svenska")
        XCTAssertEqual(language.greeting, "Hej!")
        XCTAssertEqual(MeaningLanguages.greeting(in: "Swedish"), "Hej!")
        XCTAssertTrue(language.themes.allSatisfy { !$0.situation.contains("Norway") && !$0.situation.contains("Norwegian") })
    }

    func testCaptionsPreserveSwedishLettersCompoundsAndOriginalUnicode() {
        for (text, words) in [
            ("  Åsa går över ån.\n", ["Åsa", "går", "över", "ån"]),
            ("Sjuksköterskan väntar vid tågstationen!", ["Sjuksköterskan", "väntar", "vid", "tågstationen"]),
            ("Jag tycker om blåbär. ☕️", ["Jag", "tycker", "om", "blåbär"]),
            ("Åsa läser.".decomposedStringWithCanonicalMapping, ["Åsa", "läser"].map { $0.decomposedStringWithCanonicalMapping })
        ] {
            let segments = CaptionWords.segments(text, languageID: "sv")
            XCTAssertEqual(segments.map(\.text).joined(), text)
            XCTAssertEqual(segments.compactMap(\.lookup), words)
        }
    }

    func testInflectedNounsShareALemmaAndParticleVerbsStayDistinctAfterExport() throws {
        let sessions = [
            record("Jag läser en bok.", lemma: "en bok", form: "bok", meaning: "book"),
            record("Jag läser böcker.", lemma: "en bok", form: "böcker", meaning: "book", day: 2),
            record("Jag tycker om böcker.", lemma: "att tycka om", form: "tycker om", meaning: "like", day: 2),
            record("Jag tycker att boken är bra.", lemma: "att tycka", form: "tycker", meaning: "think", day: 2)
        ]
        var archive = Archive()
        archive.sessions = sessions
        let restored = try Archive.decode(archive.encoded())
        let words = LearningEngine.project(restored.sessions, languageID: "sv", now: sessions[1].startedAt).words
        XCTAssertEqual(Set(words.map(\.id)), ["sv|en bok|book", "sv|att tycka om|like", "sv|att tycka|think"])
        XCTAssertEqual(words.first { $0.lemma == "en bok" }?.independentCount, 2)
        XCTAssertEqual(restored.sessions.map { $0.passages[0].text }, sessions.map { $0.passages[0].text })
    }

    func testSupportLanguageWordsCannotEnterSwedishVocabulary() throws {
        let session = record("Jag läser en bok.", lemma: "en bok", form: "bok", meaning: "book")
        for languageID in ["en", "fr", "nb", "mixed", "uncertain", "sv-SE"] {
            var assessment = session.assessments[0]
            assessment.words[0].language = languageID
            XCTAssertTrue(try XCTUnwrap(LearningEngine.validate(assessment, session: session)).words.isEmpty, languageID)
        }
    }

    func testVisibleEnglishMeaningDoesNotCountAsIndependentSwedishRecall() {
        let sessions = [
            record("Jag läser en bok.", lemma: "en bok", form: "bok", meaning: "book", supported: true),
            record("Jag läser böcker.", lemma: "en bok", form: "böcker", meaning: "book", day: 2)
        ]
        let word = LearningEngine.project(sessions, languageID: "sv", now: sessions[1].startedAt).words.first
        XCTAssertEqual(word?.independentCount, 1)
        XCTAssertEqual(LearningEngine.validate(sessions[0].assessments[0], session: sessions[0])?.words.first?.kind, .assisted)
    }

    func testSwedishArchiveSelectionAndHiddenWordsStaySeparateFromNorwegian() throws {
        var archive = Archive()
        archive.preferences.learningLanguageID = "sv"
        archive.preferences.meaningLanguage = "English"
        archive.preferences.hiddenWords = ["sv|en radio|radio"]
        archive.sessions = [
            record("Jag har en radio.", lemma: "en radio", form: "radio", meaning: "radio"),
            record("Jeg har en radio.", lemma: "en radio", form: "radio", meaning: "radio", languageID: "nb")
        ]
        let restored = try Archive.decode(archive.encoded())
        XCTAssertEqual(restored.preferences.learningLanguageID, "sv")
        XCTAssertEqual(restored.preferences.meaningLanguage, "English")
        XCTAssertTrue(LearningEngine.project(restored.sessions, languageID: "sv", hiddenWords: restored.preferences.hiddenWords).words.isEmpty)
        XCTAssertEqual(LearningEngine.project(restored.sessions, languageID: "nb", hiddenWords: restored.preferences.hiddenWords).words.first?.id, "nb|en radio|radio")
        XCTAssertEqual(LanguageRegistry.defaultID, "nb")
    }

    func testSpeechDetectionAcceptsSwedishLocalesWithoutAcceptingOtherLanguages() {
        for detected in ["sv", "sv-SE", "sv_FI", "SV-se"] {
            XCTAssertFalse(TeachingPolicy.shouldRedirectSpeech(language: .swedish, detectedLanguageID: detected, confidence: 0.99))
        }
        for detected in ["nb", "da", "en", "fr"] {
            XCTAssertTrue(TeachingPolicy.shouldRedirectSpeech(language: .swedish, detectedLanguageID: detected, confidence: 0.99))
        }
        XCTAssertFalse(TeachingPolicy.shouldRedirectSpeech(language: .swedish, detectedLanguageID: "nb", confidence: 0.7))
    }
}
