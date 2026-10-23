package chat.mural.core

import kotlinx.serialization.Serializable

/** Generated study material is separate from transcript and proficiency evidence. */
@Serializable enum class ConversationRecapStatus { correction, noCorrection }

@Serializable data class ConversationRecap(
    val sessionID: String, val languageID: String, val sourceRevisions: List<String>, val createdAt: Double,
    val status: ConversationRecapStatus, val passageID: String, val quote: String,
    val suggestedSentence: String, val explanation: String
) {
    fun isValid(session: SessionRecord): Boolean {
        if (!session.id.equals(sessionID, ignoreCase = true) || session.languageID != languageID || session.endedAt == null ||
            session.passages.none { it.speaker == Speaker.user && it.text.isNotBlank() } ||
            !createdAt.isFinite() || createdAt !in -63114076800.0..63113904000.0 ||
            sourceRevisions != revisions(session) || sourceRevisions.size > 10_000 ||
            sourceRevisions.sumOf { it.toByteArray(Charsets.UTF_8).size } > 500_000 ||
            explanation.isBlank() || explanation.length > 800) return false
        return when (status) {
            ConversationRecapStatus.noCorrection -> passageID.isEmpty() && quote.isEmpty() && suggestedSentence.isEmpty()
            ConversationRecapStatus.correction -> {
                val passage = session.passages.firstOrNull { it.id == passageID && it.speaker == Speaker.user }
                quote.isNotBlank() && quote.length <= 1000 && suggestedSentence.isNotBlank() &&
                    suggestedSentence.length <= 1000 && suggestedSentence.canonical() != quote.canonical() &&
                    passage?.text?.canonical()?.contains(quote.canonical()) == true
            }
        }
    }
    companion object {
        fun revisions(session: SessionRecord): List<String> = session.passages.map { "${it.speaker.name}::${it.revisionKey}" }
    }
}

@Serializable data class ConversationRecapResponse(
    val status: ConversationRecapStatus, val passageID: String, val quote: String,
    val suggestedSentence: String, val explanation: String
) {
    fun validated(session: SessionRecord, at: Double = nowSeconds()): ConversationRecap? =
        ConversationRecap(session.id, session.languageID, ConversationRecap.revisions(session), at,
            status, passageID, quote, suggestedSentence, explanation).takeIf { it.isValid(session) }
}
