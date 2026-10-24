package chat.mural.core

import org.junit.Assert.*
import org.junit.Test

class DailyReviewTest {
    private val date = 1_000_000.0
    private val day = 86_400.0
    private fun word(id: String = "sv|en bok|book", seen: Double = date) =
        WordState(id, "en bok", "book", "bok", "Jag läser en bok.", 2, 1, 2, seen, date + day)

    private fun archive(): Archive {
        val session = SessionRecord(languageID = "sv", startedAt = date, endedAt = date + 20)
        session.append(Fragment(speaker = Speaker.user, text = "Jag läser en bok.", startMS = 100_000,
            endMS = 103_000, receivedAt = date))
        val passage = session.passages.single()
        session.assessments += Assessment(passageID = passage.id, revisionKey = passage.revisionKey,
            outcome = Outcome.success, suggestedLevel = 1, nextGoal = "Talk about a book", capability = "Describes a book",
            words = listOf(WordProposal("en bok", "book", "bok", EvidenceKind.independent, .95,
                passage.fragments.map { it.id }, "Jag läser en bok.", "sv")), createdAt = date)
        return Archive(sessions = mutableListOf(session))
    }

    @Test fun queueSeparatesLanguagesDeduplicatesAndUsesPracticeSchedule() {
        val book = word()
        val review = DailyReview.record(book.id, "sv", ReviewGrade.remembered, null, date)
        assertEquals(listOf(book.id), DailyReview.queue(listOf(book, word("nb|en bok|book"), book), emptyList(), "sv", date).map { it.id })
        assertTrue(DailyReview.queue(listOf(book), listOf(review), "sv", date).isEmpty())
        assertEquals(listOf(book.id), DailyReview.queue(listOf(book), listOf(review), "sv", review.dueAt).map { it.id })
        assertTrue(DailyReview.queue(listOf(book), emptyList(), "sv", date - 1).isEmpty())
    }

    @Test fun queueIsOldestFirstStableAndLimitedToTen() {
        val words = (0..11).reversed().map { word("sv|word$it|meaning", date + it) }
        assertEquals((0..9).map { "sv|word$it|meaning" }, DailyReview.queue(words, emptyList(), "sv", date + 20).map { it.id })
        assertEquals(listOf("sv|a|a", "sv|b|b"), DailyReview.queue(listOf(word("sv|b|b"), word("sv|a|a")), emptyList(), "sv", date).map { it.id })
    }

    @Test fun importedUnicodeWordIdentityKeepsItsReviewSchedule() {
        val word = word("sv|å|river")
        val decomposed = java.text.Normalizer.normalize(word.id, java.text.Normalizer.Form.NFD)
        val review = DailyReview.record(decomposed, "sv", ReviewGrade.remembered, null, date)
        assertTrue(DailyReview.queue(listOf(word), listOf(review), "sv", date).isEmpty())
    }

    @Test fun rememberedIntervalsNeedPracticeAndEarlyRepeatBehaveAsExpected() {
        var previous: WordReview? = null
        var at = date
        for (expectedDays in listOf(1, 3, 7, 14, 14)) {
            val review = DailyReview.record(word().id, "sv", ReviewGrade.remembered, previous, at)
            assertEquals(expectedDays * day, review.dueAt - at, 0.0)
            assertTrue(review.isValid)
            previous = review; at = review.dueAt
        }
        val reset = DailyReview.record(word().id, "sv", ReviewGrade.needsPractice, previous, at)
        assertEquals(0, reset.consecutiveRemembered)
        assertEquals(day, reset.dueAt - at, 0.0)
        val next = DailyReview.record(word().id, "sv", ReviewGrade.remembered, reset, reset.dueAt)
        assertEquals(1, next.consecutiveRemembered)
        assertEquals(1, DailyReview.record(word().id, "sv", ReviewGrade.remembered, next, reset.dueAt + 1).consecutiveRemembered)
        assertEquals(1, DailyReview.record("sv|ett hus|house", "sv", ReviewGrade.remembered, previous, at).consecutiveRemembered)
    }

    @Test fun legacyAndReviewBackupRoundTripsDoNotChangeSpokenRecallEvidence() {
        val original = archive()
        assertNull(ArchiveCodec.decode(ArchiveCodec.encode(original)).wordReviews)
        val before = LearningEngine.project(original.sessions, "sv", now = date).words.single()
        original.wordReviews = listOf(DailyReview.record(before.id, "sv", ReviewGrade.remembered, null, date))
        val restored = ArchiveCodec.decode(ArchiveCodec.encode(original))
        assertEquals(original.wordReviews, restored.wordReviews)
        val after = LearningEngine.project(restored.sessions, "sv", now = date).words.single()
        assertEquals(before.bars, after.bars)
        assertEquals(before.independentCount, after.independentCount)
        assertEquals(before.dueAt, after.dueAt, 0.0)
        assertEquals(original.sessions.single().assessments, restored.sessions.single().assessments)
    }

    @Test fun importsMergeNewestReviewAndPreserveCurrentPreferences() {
        val current = archive()
        val first = DailyReview.record(word().id, "sv", ReviewGrade.remembered, null, date)
        val second = DailyReview.record(word().id, "sv", ReviewGrade.remembered, first, first.dueAt)
        current.wordReviews = listOf(first)
        val incoming = ArchiveCodec.decode(ArchiveCodec.encode(current))
        incoming.wordReviews = listOf(second); incoming.preferences.learningLanguageID = "sv"
        val merged = ArchiveCodec.merge(current, incoming)
        assertEquals(listOf(second), merged.wordReviews)
        assertEquals(1, merged.sessions.size)
        assertEquals(current.preferences.learningLanguageID, merged.preferences.learningLanguageID)
        assertEquals(listOf(second), ArchiveCodec.merge(merged, current).wordReviews)
        assertEquals(listOf(second), ArchiveCodec.merge(merged, archive()).wordReviews)
    }

    @Test fun hiddenDeletedOrUnsupportedWordReferencesCannotRestoreVocabulary() {
        val archive = archive()
        val review = DailyReview.record(word().id, "sv", ReviewGrade.remembered, null, date)
        archive.wordReviews = listOf(review); archive.preferences.hiddenWords = listOf(review.wordID)
        assertNull(ArchiveCodec.decode(ArchiveCodec.encode(archive)).wordReviews)
        archive.preferences.hiddenWords = emptyList(); archive.sessions.clear(); archive.pruneWordReviews()
        assertNull(archive.wordReviews)
        archive.wordReviews = listOf(review)
        assertNull(ArchiveCodec.decode(ArchiveCodec.encode(archive)).wordReviews)
        assertTrue(DailyReview.queue(emptyList(), listOf(review), "sv", review.dueAt).isEmpty())
    }

    @Test fun malformedAndDuplicateReviewsAreRejected() {
        val archive = archive()
        val good = DailyReview.record(word().id, "sv", ReviewGrade.remembered, null, date)
        for (reviews in listOf(listOf(good, good), listOf(good.copy(languageID = "nb")),
            listOf(good.copy(dueAt = date - 1)), listOf(good.copy(consecutiveRemembered = 5)))) {
            archive.wordReviews = reviews
            assertThrows(ArchiveError::class.java) { ArchiveCodec.decode(ArchiveCodec.encode(archive)) }
        }
    }
}
