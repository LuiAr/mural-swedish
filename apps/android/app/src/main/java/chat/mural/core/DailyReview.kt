package chat.mural.core

import kotlinx.serialization.Serializable

/** Self-reported practice never becomes conversation evidence. */
@Serializable enum class ReviewGrade { remembered, needsPractice }

@Serializable data class WordReview(
    val wordID: String, val languageID: String, val reviewedAt: Double,
    val dueAt: Double, val consecutiveRemembered: Int
) {
    val isValid: Boolean get() = LanguageRegistry.get(languageID) != null && wordID.startsWith("$languageID|") &&
        wordID.length > languageID.length + 1 && wordID.length <= 500 &&
        reviewedAt.isFinite() && dueAt.isFinite() && reviewedAt >= -63114076800.0 && dueAt <= 63113904000.0 &&
        consecutiveRemembered in 0..4 && dueAt - reviewedAt in 86_400.0..1_209_600.0
}

object DailyReview {
    const val MAXIMUM_WORDS = 10
    const val MAXIMUM_SECONDS = 300
    private val intervals = listOf(1, 3, 7, 14)

    fun queue(words: List<WordState>, reviews: List<WordReview>, languageID: String, now: Double = nowSeconds()): List<WordState> {
        val progress = reviews.filter { it.languageID == languageID && it.isValid }.groupBy { it.wordID.canonical() }
            .mapValues { (_, values) -> values.maxBy { it.reviewedAt } }
        fun due(word: WordState) = progress[word.id.canonical()]?.dueAt ?: word.lastSeen
        return FlashcardDeck(words, languageID).words.filter { due(it) <= now }
            .sortedWith(compareBy<WordState> { due(it) }.thenBy { it.id }).take(MAXIMUM_WORDS)
    }

    fun record(wordID: String, languageID: String, grade: ReviewGrade, previous: WordReview?, at: Double = nowSeconds()): WordReview {
        val prior = previous?.takeIf { it.wordID.canonical() == wordID.canonical() && it.languageID == languageID && it.isValid }
        val count = when {
            grade == ReviewGrade.needsPractice -> 0
            prior != null && at < prior.dueAt -> maxOf(1, prior.consecutiveRemembered)
            else -> minOf(4, (prior?.consecutiveRemembered ?: 0) + 1)
        }
        return WordReview(wordID, languageID, at, at + intervals[maxOf(0, count - 1)] * 86_400.0, count)
    }
}
