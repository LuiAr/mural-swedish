import Foundation

public enum SwedishWordFormKind: String, Codable, Sendable { case noun, verb, unavailable }

/// Labels are stable archive values, not arbitrary text returned by the model.
public enum SwedishWordFormSlot: String, Codable, CaseIterable, Sendable {
    case indefiniteSingular, definiteSingular, indefinitePlural, definitePlural
    case infinitive, present, past, supine
    public var title: String {
        switch self {
        case .indefiniteSingular: "Indefinite singular"
        case .definiteSingular: "Definite singular"
        case .indefinitePlural: "Indefinite plural"
        case .definitePlural: "Definite plural"
        case .infinitive: "Infinitive"
        case .present: "Present"
        case .past: "Past"
        case .supine: "Supine"
        }
    }
    public static func slots(for kind: SwedishWordFormKind) -> [Self] {
        switch kind {
        case .noun: [.indefiniteSingular, .definiteSingular, .indefinitePlural, .definitePlural]
        case .verb: [.infinitive, .present, .past, .supine]
        case .unavailable: []
        }
    }
}

public struct SwedishWordForm: Codable, Equatable, Identifiable, Sendable {
    public var slot: SwedishWordFormSlot
    /// Nil means this particular form is unavailable or not applicable.
    public var text: String?
    public var id: SwedishWordFormSlot { slot }
    public init(slot: SwedishWordFormSlot, text: String?) { self.slot = slot; self.text = text }
}

/// Generated forms retain their glossary sense and original request context.
/// Fresh practice of that same sense can reuse the reference card. The card
/// never creates vocabulary or changes spoken-recall evidence.
public struct SwedishWordForms: Codable, Equatable, Sendable {
    public var wordID: String
    public var lemma: String
    public var meaning: String
    public var sourceExample: String
    public var sourceForm: String
    public var sourceLastSeen: Date
    public var createdAt: Date
    public var kind: SwedishWordFormKind
    public var forms: [SwedishWordForm]
    public var note: String

    public init(word: WordState, createdAt: Date = .now, kind: SwedishWordFormKind, forms: [SwedishWordForm], note: String) {
        wordID = word.id; lemma = word.lemma; meaning = word.meaning
        sourceExample = word.example; sourceForm = word.form; sourceLastSeen = word.lastSeen
        self.createdAt = createdAt; self.kind = kind; self.forms = forms; self.note = note
    }

    public var isWellFormed: Bool {
        func dateIsValid(_ date: Date) -> Bool {
            date.timeIntervalSinceReferenceDate.isFinite && date >= .distantPast && date <= .distantFuture
        }
        guard wordID.hasPrefix("sv|"), wordID.count <= 500,
              !lemma.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, lemma.count < 100,
              !meaning.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, meaning.count < 180,
              !sourceExample.isEmpty, sourceExample.count <= 50_000,
              !sourceForm.isEmpty, sourceForm.count <= 1000,
              dateIsValid(sourceLastSeen), dateIsValid(createdAt),
              !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, note.count <= 600,
              forms.map(\.slot) == SwedishWordFormSlot.slots(for: kind),
              forms.allSatisfy({ form in
                  form.text.map { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && $0.count <= 120 } ?? true
              }) else { return false }
        return kind == .unavailable || forms.contains { $0.text != nil }
    }

    public func isValid(for word: WordState) -> Bool {
        isWellFormed && word.id == wordID && word.lemma == lemma && word.meaning == meaning
    }
}

public struct SwedishWordFormsResponse: Codable, Sendable {
    public var kind: SwedishWordFormKind
    public var forms: [SwedishWordForm]
    public var note: String
    public init(kind: SwedishWordFormKind, forms: [SwedishWordForm], note: String) {
        self.kind = kind; self.forms = forms; self.note = note
    }
    public func validated(for word: WordState, at date: Date = .now) -> SwedishWordForms? {
        let card = SwedishWordForms(word: word, createdAt: date, kind: kind, forms: forms, note: note)
        return card.isValid(for: word) ? card : nil
    }
}
