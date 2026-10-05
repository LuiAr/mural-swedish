package chat.mural.core

import org.junit.Assert.*
import org.junit.Test

class SwedishTest {
    private fun record(text: String, lemma: String, form: String, meaning: String, day: Int = 0,
                       languageID: String = "sv", supported: Boolean = false): SessionRecord {
        val date = 810_000_000.0 + day * 86400
        val session = SessionRecord(languageID = languageID, startedAt = date, themeID = "coffee")
        session.append(Fragment(speaker = Speaker.user, text = text, startMS = 100_000, endMS = 103_000,
            receivedAt = date, meaningVisible = supported))
        val passage = session.passages.single()
        session.assessments += Assessment(passageID = passage.id, revisionKey = passage.revisionKey,
            outcome = Outcome.success, suggestedLevel = 2, nextGoal = "Berätta om en bok.",
            capability = "Describes a book", createdAt = date,
            words = listOf(WordProposal(lemma, meaning, form, EvidenceKind.independent, .95,
                passage.fragments.map { it.id }, text, languageID)))
        session.endedAt = date + 104
        return session
    }

    @Test fun swedishConversationHasSeparateEnglishSupport() {
        val language = LanguageRegistry.get("sv")!!
        val voice = TeachingPolicy.voice(language, LearningEngine.project(emptyList(), "sv"), language.themes.first(), "", "English")
        assertTrue(voice.contains("Speak ONLY Swedish."))
        assertTrue(voice.contains("Tala bara svenska"))
        assertTrue(voice.contains("Meaning subtitles in English are a separate application feature."))
        assertTrue(voice.contains("French, English or mixed learner replies as support"))
        assertFalse(voice.contains("Norwegian"))
        assertTrue(TeachingPolicy.translation(language, "English").contains("into English"))
        assertTrue(TeachingPolicy.lookup(language, "English").contains("Use English, 2–3 short sentences."))
        assertTrue(TeachingPolicy.assessment(language).contains("pitch-accent errors from a transcript alone"))
        assertEquals("sv-SE", language.locale)
        assertEquals("Svenska", language.nativeName)
        assertEquals("Hej!", MeaningLanguages.greeting("Swedish"))
    }

    @Test fun captionsPreserveSwedishLettersAndCompounds() {
        for ((text, expected) in listOf(
            "  Åsa går över ån.\n" to listOf("Åsa", "går", "över", "ån"),
            "Sjuksköterskan väntar vid tågstationen!" to listOf("Sjuksköterskan", "väntar", "vid", "tågstationen"),
            "Jag tycker om blåbär. ☕️" to listOf("Jag", "tycker", "om", "blåbär"),
        )) {
            val segments = CaptionWords.segments(text, "sv", null)
            assertEquals(text, segments.joinToString("") { it.text })
            assertEquals(expected, segments.mapNotNull { it.lookup })
        }
    }

    @Test fun nounInflectionsShareALemmaAndParticleVerbsRemainDistinctAfterExport() {
        val sessions = mutableListOf(
            record("Jag läser en bok.", "en bok", "bok", "book"),
            record("Jag läser böcker.", "en bok", "böcker", "book", day = 2),
            record("Jag tycker om böcker.", "att tycka om", "tycker om", "like", day = 2),
            record("Jag tycker att boken är bra.", "att tycka", "tycker", "think", day = 2),
        )
        val restored = ArchiveCodec.decode(ArchiveCodec.encode(Archive(sessions = sessions)))
        val words = LearningEngine.project(restored.sessions, "sv", now = sessions[1].startedAt).words
        assertEquals(setOf("sv|en bok|book", "sv|att tycka om|like", "sv|att tycka|think"), words.map { it.id }.toSet())
        assertEquals(2, words.single { it.lemma == "en bok" }.independentCount)
        assertEquals(sessions.map { it.passages.single().text }, restored.sessions.map { it.passages.single().text })
    }

    @Test fun foreignLanguageEvidenceAndVisibleMeaningsNeverBecomeIndependentSwedishRecall() {
        val supported = record("Jag läser en bok.", "en bok", "bok", "book", supported = true)
        val independent = record("Jag läser böcker.", "en bok", "böcker", "book", day = 2)
        assertEquals(1, LearningEngine.project(listOf(supported, independent), "sv").words.single().independentCount)
        assertEquals(EvidenceKind.assisted, LearningEngine.validate(supported.assessments.single(), supported)!!.words.single().kind)
        for (languageID in listOf("en", "fr", "nb", "mixed", "uncertain", "sv-SE")) {
            val assessment = independent.assessments.single().let { original ->
                original.copy(words = original.words.map { it.copy(language = languageID) })
            }
            assertTrue(LearningEngine.validate(assessment, independent)!!.words.isEmpty())
        }
    }

    @Test fun swedishSelectionAndHiddenWordsStaySeparateFromNorwegianAfterExport() {
        val archive = Archive(sessions = mutableListOf(
            record("Jag har en radio.", "en radio", "radio", "radio"),
            record("Jeg har en radio.", "en radio", "radio", "radio", languageID = "nb"),
        ))
        archive.preferences.learningLanguageID = "sv"
        archive.preferences.meaningLanguage = "English"
        archive.preferences.hiddenWords = mutableListOf("sv|en radio|radio")
        val restored = ArchiveCodec.decode(ArchiveCodec.encode(archive))
        assertEquals("sv", restored.preferences.learningLanguageID)
        assertEquals("English", restored.preferences.meaningLanguage)
        assertTrue(LearningEngine.project(restored.sessions, "sv", restored.preferences.hiddenWords).words.isEmpty())
        assertEquals("nb|en radio|radio", LearningEngine.project(restored.sessions, "nb", restored.preferences.hiddenWords).words.single().id)
        assertEquals("nb", LanguageRegistry.defaultID)
    }

    @Test fun swedishRegionalSpeechLabelsAreAcceptedButOtherLanguagesAreRedirected() {
        val language = LanguageRegistry.get("sv")!!
        for (detected in listOf("sv", "sv-SE", "sv_FI", "SV-se")) {
            assertFalse(TeachingPolicy.shouldRedirectSpeech(language, detected, .99))
        }
        for (detected in listOf("nb", "da", "en", "fr")) {
            assertTrue(TeachingPolicy.shouldRedirectSpeech(language, detected, .99))
        }
        assertFalse(TeachingPolicy.shouldRedirectSpeech(language, "nb", .7))
    }
}
