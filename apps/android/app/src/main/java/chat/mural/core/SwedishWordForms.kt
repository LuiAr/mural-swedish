package chat.mural.core

import kotlinx.serialization.Serializable

@Serializable enum class SwedishWordFormKind { noun, verb, unavailable }
@Serializable enum class SwedishWordFormSlot {
    indefiniteSingular, definiteSingular, indefinitePlural, definitePlural, infinitive, present, past, supine;
    companion object {
        fun slots(kind: SwedishWordFormKind): List<SwedishWordFormSlot> = when (kind) {
            SwedishWordFormKind.noun -> listOf(indefiniteSingular, definiteSingular, indefinitePlural, definitePlural)
            SwedishWordFormKind.verb -> listOf(infinitive, present, past, supine)
            SwedishWordFormKind.unavailable -> emptyList()
        }
    }
}
@Serializable data class SwedishWordForm(val slot: SwedishWordFormSlot, val text: String? = null)

/** Reference material never creates vocabulary or changes spoken evidence. */
@Serializable data class SwedishWordForms(
    val wordID: String, val lemma: String, val meaning: String,
    val sourceExample: String, val sourceForm: String, val sourceLastSeen: Double, val createdAt: Double,
    val kind: SwedishWordFormKind, val forms: List<SwedishWordForm>, val note: String
) {
    val isWellFormed: Boolean get() {
        fun validDate(date: Double) = date.isFinite() && date in -63114076800.0..63113904000.0
        return wordID.startsWith("sv|") && wordID.length <= 500 && lemma.isNotBlank() && lemma.length < 100 &&
            meaning.isNotBlank() && meaning.length < 180 && sourceExample.isNotEmpty() && sourceExample.length <= 50_000 &&
            sourceForm.isNotEmpty() && sourceForm.length <= 1000 && validDate(sourceLastSeen) && validDate(createdAt) &&
            note.isNotBlank() && note.length <= 600 && forms.map { it.slot } == SwedishWordFormSlot.slots(kind) &&
            forms.all { form -> form.text?.let { it.isNotBlank() && it.length <= 120 } != false } &&
            (kind == SwedishWordFormKind.unavailable || forms.any { it.text != null })
    }
    fun isValid(word: WordState): Boolean = isWellFormed && word.id.canonical() == wordID.canonical() &&
        word.lemma.canonical() == lemma.canonical() && word.meaning.canonical() == meaning.canonical()
    companion object {
        fun create(word: WordState, at: Double, kind: SwedishWordFormKind, forms: List<SwedishWordForm>, note: String) =
            SwedishWordForms(word.id, word.lemma, word.meaning, word.example, word.form, word.lastSeen, at, kind, forms, note)
    }
}

@Serializable data class SwedishWordFormsResponse(val kind: SwedishWordFormKind, val forms: List<SwedishWordForm>, val note: String) {
    fun validated(word: WordState, at: Double = nowSeconds()): SwedishWordForms? =
        SwedishWordForms.create(word, at, kind, forms, note).takeIf { it.isValid(word) }
}
