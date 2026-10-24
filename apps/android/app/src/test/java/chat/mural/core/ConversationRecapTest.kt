package chat.mural.core

import org.junit.Assert.*
import org.junit.Test

class ConversationRecapTest {
    private val date = 1_000_000.0
    private val quote = "Jag läser en bok igår."
    private fun session(): SessionRecord {
        val session = SessionRecord(languageID = "sv", startedAt = date, endedAt = date + 30)
        session.append(Fragment(id = "learner", speaker = Speaker.user, text = quote,
            startMS = 100_000, endMS = 103_000, receivedAt = date))
        session.append(Fragment(id = "teacher", speaker = Speaker.assistant, text = "Du läste en bok igår.",
            startMS = 104_000, endMS = 106_000, receivedAt = date))
        val passage = session.passages.first()
        session.assessments += Assessment(passageID = passage.id, revisionKey = passage.revisionKey,
            outcome = Outcome.partial, suggestedLevel = 1, nextGoal = "Talk about yesterday", capability = "",
            words = listOf(WordProposal("en bok", "book", "bok", EvidenceKind.assisted, .95,
                listOf("learner"), quote, "sv")), createdAt = date)
        return session
    }
    private fun response() = ConversationRecapResponse(ConversationRecapStatus.correction, "learner", quote,
        "Jag läste en bok igår.", "Use the past tense läste with igår, yesterday.")

    @Test fun correctionRequiresExactCurrentLearnerQuote() {
        val session = session()
        assertTrue(response().validated(session, date)!!.isValid(session))
        assertNull(response().copy(quote = "jag läser en bok igår.").validated(session, date))
        assertNull(response().copy(quote = "A sentence never spoken.").validated(session, date))
        assertNull(response().copy(passageID = "teacher", quote = "Du läste en bok igår.").validated(session, date))
        assertNull(response().copy(suggestedSentence = quote).validated(session, date))
    }

    @Test fun editsExtensionsAndResumptionInvalidateCachedRecap() {
        var session = session()
        val recap = response().validated(session, date)!!
        session.recap = recap
        session.correctFragment("learner", "Jag läste en bok igår.")
        assertNull(session.recap); assertFalse(recap.isValid(session)); assertTrue(session.assessments.isEmpty())
        session = session(); session.recap = response().validated(session, date)
        session.append(Fragment(id = "later", speaker = Speaker.assistant, text = "Berätta mer.",
            startMS = 110_000, endMS = 111_000, receivedAt = date))
        assertNull(session.recap)
        session = session(); session.recap = response().validated(session, date)
        session.endedAt = null; session.invalidateChangedAssessments(); assertNull(session.recap)
    }

    @Test fun explicitNoCorrectionNeedsEndedLearnerSpeech() {
        val response = ConversationRecapResponse(ConversationRecapStatus.noCorrection, "", "", "", "No clear correction found.")
        val session = session()
        assertEquals(ConversationRecapStatus.noCorrection, response.validated(session, date)!!.status)
        session.endedAt = null; assertNull(response.validated(session, date))
        session.endedAt = date; session.fragments.clear(); assertNull(response.validated(session, date))
        assertNull(response.copy(quote = quote).validated(session(), date))
    }

    @Test fun languageSessionRevisionAndBoundsAreChecked() {
        val session = session()
        val recap = response().validated(session, date)!!
        assertFalse(recap.copy(sessionID = java.util.UUID.randomUUID().toString()).isValid(session))
        assertFalse(recap.copy(languageID = "nb").isValid(session))
        assertFalse(recap.copy(sourceRevisions = listOf("learner:99")).isValid(session))
        assertNull(response().copy(explanation = "x".repeat(801)).validated(session, date))
        assertNull(response().copy(suggestedSentence = "x".repeat(1001)).validated(session, date))
    }

    @Test fun legacyRoundTripImportAndLearningRemainIndependent() {
        val original = Archive(sessions = mutableListOf(session()))
        assertNull(ArchiveCodec.decode(ArchiveCodec.encode(original)).sessions.single().recap)
        val before = LearningEngine.project(original.sessions, "sv", now = date).words
        original.sessions.single().recap = response().validated(original.sessions.single(), date)
        val restored = ArchiveCodec.decode(ArchiveCodec.encode(original))
        assertEquals(original.sessions.single().recap, restored.sessions.single().recap)
        assertEquals(original.sessions.single().fragments, restored.sessions.single().fragments)
        assertEquals(original.sessions.single().assessments, restored.sessions.single().assessments)
        val after = LearningEngine.project(restored.sessions, "sv", now = date).words
        assertEquals(before.map { it.id }, after.map { it.id })
        assertEquals(before.map { it.bars }, after.map { it.bars })
        assertEquals(before.map { it.independentCount }, after.map { it.independentCount })
        assertEquals(original.sessions.single().recap, ArchiveCodec.merge(Archive(), restored).sessions.single().recap)
        original.sessions.single().recap = original.sessions.single().recap!!.copy(quote = "Invented source.")
        assertThrows(ArchiveError::class.java) { ArchiveCodec.decode(ArchiveCodec.encode(original)) }
    }

    @Test fun sameSessionImportMergesOnlyNewerMatchingRecap() {
        val current = Archive(sessions = mutableListOf(session()))
        current.sessions.single().inputTokens = 40
        val incoming = ArchiveCodec.decode(ArchiveCodec.encode(current))
        incoming.sessions.single().recap = response().validated(incoming.sessions.single(), date)
        incoming.sessions.single().inputTokens = 100
        incoming.sessions.single().assessments.clear()
        incoming.preferences.learningLanguageID = "sv"
        val filled = ArchiveCodec.merge(current, incoming)
        assertEquals(incoming.sessions.single().recap, filled.sessions.single().recap)
        assertEquals(40, filled.sessions.single().inputTokens)
        assertEquals(current.sessions.single().assessments, filled.sessions.single().assessments)
        assertEquals(current.preferences.learningLanguageID, filled.preferences.learningLanguageID)
        val newer = ArchiveCodec.decode(ArchiveCodec.encode(incoming))
        newer.sessions.single().recap = newer.sessions.single().recap!!.copy(createdAt = date + 1)
        assertEquals(newer.sessions.single().recap, ArchiveCodec.merge(filled, newer).sessions.single().recap)
        assertEquals(newer.sessions.single().recap, ArchiveCodec.merge(ArchiveCodec.merge(filled, newer), incoming).sessions.single().recap)
        current.sessions.single().correctFragment("learner", "Jag läste en bok igår.")
        assertNull(ArchiveCodec.merge(current, incoming).sessions.single().recap)
        assertEquals(current.sessions.single().fragments, ArchiveCodec.merge(current, incoming).sessions.single().fragments)
    }
}
