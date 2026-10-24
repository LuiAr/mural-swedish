package chat.mural.core

import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonObject
import org.junit.Assert.*
import org.junit.Test

class SwedishWordFormsTest {
    private val date = 1_000_000.0
    private fun word() = WordState("sv|en bok|book", "en bok", "book", "bok", "Jag läser en bok.",
        2, 1, 2, date, date + 86_400)
    private fun nounForms() = listOf(
        SwedishWordForm(SwedishWordFormSlot.indefiniteSingular, "en bok"),
        SwedishWordForm(SwedishWordFormSlot.definiteSingular, "boken"),
        SwedishWordForm(SwedishWordFormSlot.indefinitePlural, "böcker"),
        SwedishWordForm(SwedishWordFormSlot.definitePlural, "böckerna")
    )
    private fun noun(word: WordState = word(), at: Double = date) =
        SwedishWordForms.create(word, at, SwedishWordFormKind.noun, nounForms(), "Bok has the irregular plural böcker.")

    private fun archive(): Archive {
        val session = SessionRecord(languageID = "sv", startedAt = date, endedAt = date + 30)
        session.append(Fragment(id = "forms-learner", speaker = Speaker.user, text = "Jag läser en bok.",
            startMS = 100_000, endMS = 103_000, receivedAt = date))
        val passage = session.passages.single()
        session.assessments += Assessment(passageID = passage.id, revisionKey = passage.revisionKey,
            outcome = Outcome.success, suggestedLevel = 1, nextGoal = "Describe a book", capability = "",
            words = listOf(WordProposal("en bok", "book", "bok", EvidenceKind.independent, .95,
                passage.fragments.map { it.id }, passage.text, "sv")), createdAt = date)
        return Archive(sessions = mutableListOf(session))
    }

    @Test fun nounAndVerbParadigmsKeepDiacriticsAndParticles() {
        val noun = SwedishWordFormsResponse(SwedishWordFormKind.noun, nounForms(), "Irregular plural.").validated(word(), date)
        assertNotNull(noun)
        assertEquals("böcker", noun!!.forms[2].text)
        val verb = word().copy(id = "sv|att känna sig|to feel", lemma = "att känna sig", meaning = "to feel",
            form = "känner sig", example = "Hon känner sig glad.")
        val values = listOf("att känna sig", "känner sig", "kände sig", "känt sig")
        val forms = SwedishWordFormSlot.slots(SwedishWordFormKind.verb).zip(values).map { (slot, text) -> SwedishWordForm(slot, text) }
        val card = SwedishWordFormsResponse(SwedishWordFormKind.verb, forms, "Keep the reflexive pronoun.").validated(verb, date)
        assertNotNull(card)
        assertEquals(values, card!!.forms.map { it.text })
    }

    @Test fun missingIndividualFormsAndExplicitUnavailableAreHonest() {
        val partial = nounForms().map { if (it.slot in listOf(SwedishWordFormSlot.indefinitePlural, SwedishWordFormSlot.definitePlural)) it.copy(text = null) else it }
        assertNotNull(SwedishWordFormsResponse(SwedishWordFormKind.noun, partial, "This sense has no plural.").validated(word(), date))
        val unsupported = word().copy(id = "sv|snabb|fast", lemma = "snabb", meaning = "fast", form = "snabb", example = "Den är snabb.")
        assertNotNull(SwedishWordFormsResponse(SwedishWordFormKind.unavailable, emptyList(), "This is an adjective.").validated(unsupported, date))
        assertNull(SwedishWordFormsResponse(SwedishWordFormKind.unavailable, nounForms(), "Unavailable.").validated(unsupported, date))
        assertNull(SwedishWordFormsResponse(SwedishWordFormKind.noun, nounForms().map { it.copy(text = null) }, "No confident forms.").validated(word(), date))
    }

    @Test fun responseRejectsWrongSlotsDuplicatesEmptyAndOversizedValues() {
        val invalidForms = listOf(nounForms().reversed(), nounForms().dropLast(1),
            listOf(nounForms()[0], nounForms()[0], nounForms()[2], nounForms()[3]),
            nounForms().map { if (it.slot == SwedishWordFormSlot.indefinitePlural) it.copy(text = " ") else it },
            nounForms().map { if (it.slot == SwedishWordFormSlot.indefinitePlural) it.copy(text = "x".repeat(121)) else it })
        invalidForms.forEach { forms ->
            assertNull(SwedishWordFormsResponse(SwedishWordFormKind.noun, forms, "A note.").validated(word(), date))
        }
        assertNull(SwedishWordFormsResponse(SwedishWordFormKind.noun, nounForms(), " ").validated(word(), date))
        assertNull(SwedishWordFormsResponse(SwedishWordFormKind.noun, nounForms(), "x".repeat(601)).validated(word(), date))
        assertFalse(noun().copy(createdAt = Double.NaN).isWellFormed)
        assertFalse(noun().copy(wordID = "nb|en bok|book").isWellFormed)
    }

    @Test fun cachedSenseSurvivesNewPracticeButNotAnotherSenseOrLanguage() {
        val original = word()
        val card = noun(original)
        val later = original.copy(example = "Jag köpte boken.", form = "boken", lastSeen = date + 86_400,
            independentCount = 3)
        assertTrue(card.isValid(later))
        assertFalse(card.isValid(later.copy(id = "sv|en bok|beech", meaning = "beech")))
        assertFalse(card.isValid(later.copy(id = "nb|en bok|book")))
        val island = original.copy(id = "sv|en ö|island", lemma = "en ö", meaning = "island", form = "ö", example = "Jag bor på en ö.")
        val islandForms = SwedishWordFormSlot.slots(SwedishWordFormKind.noun)
            .zip(listOf("en ö", "ön", "öar", "öarna")).map { (slot, text) -> SwedishWordForm(slot, text) }
        val islandCard = SwedishWordForms.create(island, date, SwedishWordFormKind.noun, islandForms, "Regular plural in -ar.")
        val decomposed = java.text.Normalizer.normalize(islandCard.wordID, java.text.Normalizer.Form.NFD)
        assertTrue(islandCard.copy(wordID = decomposed).isValid(island))
    }

    @Test fun legacyAndCachedBackupRoundTripLeaveSpokenEvidenceUntouched() {
        val original = archive()
        val legacy = JsonObject(Json.parseToJsonElement(ArchiveCodec.encode(original)).jsonObject - "swedishWordForms")
        assertNull(ArchiveCodec.decode(legacy.toString()).swedishWordForms)
        val before = LearningEngine.project(original.sessions, "sv", now = date).words.single()
        val fragments = original.sessions.single().fragments.toList()
        val assessments = original.sessions.single().assessments.toList()
        original.swedishWordForms = listOf(noun(before))
        val restored = ArchiveCodec.decode(ArchiveCodec.encode(original))
        assertEquals(original.swedishWordForms, restored.swedishWordForms)
        assertEquals(fragments, restored.sessions.single().fragments)
        assertEquals(assessments, restored.sessions.single().assessments)
        val after = LearningEngine.project(restored.sessions, "sv", now = date).words.single()
        assertEquals(before.bars, after.bars)
        assertEquals(before.independentCount, after.independentCount)
        assertEquals(before.dueAt, after.dueAt, 0.0)
    }

    @Test fun importChoosesNewestValidCardAndKeepsCurrentSourceAndPreferences() {
        val current = archive()
        val projected = LearningEngine.project(current.sessions, "sv", now = date).words.single()
        current.swedishWordForms = listOf(noun(projected))
        val incoming = ArchiveCodec.decode(ArchiveCodec.encode(current))
        val newer = noun(projected, date + 60).copy(note = "A newer explanation.")
        incoming.swedishWordForms = listOf(newer)
        incoming.preferences.learningLanguageID = "sv"
        val result = ArchiveCodec.merge(current, incoming)
        assertEquals(listOf(newer), result.swedishWordForms)
        assertEquals(current.sessions.single().fragments, result.sessions.single().fragments)
        assertEquals(current.sessions.single().assessments, result.sessions.single().assessments)
        assertEquals(current.preferences.learningLanguageID, result.preferences.learningLanguageID)
        assertEquals(listOf(newer), ArchiveCodec.merge(result, current).swedishWordForms)
    }

    @Test fun hidingDeletingOrEditingLastEvidencePrunesCardsAndCannotRestoreWords() {
        val original = archive()
        val projected = LearningEngine.project(original.sessions, "sv", now = date).words.single()
        val card = noun(projected)
        original.swedishWordForms = listOf(card)
        original.preferences.hiddenWords = listOf(projected.id)
        assertNull(ArchiveCodec.decode(ArchiveCodec.encode(original)).swedishWordForms)
        original.preferences.hiddenWords = emptyList()
        original.sessions.single().correctFragment("forms-learner", "Jag läser tidningen.")
        original.pruneSwedishWordForms()
        assertNull(original.swedishWordForms)
        original.swedishWordForms = listOf(card); original.sessions.clear()
        assertNull(ArchiveCodec.decode(ArchiveCodec.encode(original)).swedishWordForms)
        assertNull(ArchiveCodec.merge(Archive(), original).swedishWordForms)
    }

    @Test fun malformedDuplicateAndUnknownSlotBackupsAreRejected() {
        val original = archive()
        val card = noun(LearningEngine.project(original.sessions, "sv", now = date).words.single())
        original.swedishWordForms = listOf(card, card)
        assertThrows(ArchiveError::class.java) { ArchiveCodec.decode(ArchiveCodec.encode(original)) }
        original.swedishWordForms = listOf(card)
        val unknownSlot = ArchiveCodec.encode(original).replace("\"indefinitePlural\"", "\"inventedSlot\"")
        assertThrows(ArchiveError::class.java) { ArchiveCodec.decode(unknownSlot) }
    }

    @Test fun encodedBackupUsesUtf8ByteLimitBeforeItCanBeSaved() {
        val original = Archive()
        // UTF-16 length is below the limit; UTF-8 plus JSON overhead exceeds it.
        original.preferences.interests = "ö".repeat(ArchiveCodec.MAXIMUM_ENCODED_BYTES / 2)
        assertTrue(original.preferences.interests.length < ArchiveCodec.MAXIMUM_ENCODED_BYTES)
        val failure = assertThrows(ArchiveError::class.java) { ArchiveCodec.encode(original) }
        assertEquals(ArchiveError.Kind.TOO_LARGE, failure.kind)
    }
}
