import Foundation

/// Generated study material is deliberately separate from conversation evidence.
public enum ConversationRecapStatus: String, Codable, Sendable { case correction, noCorrection }

public struct ConversationRecap: Codable, Equatable, Sendable {
    public var sessionID: UUID
    public var languageID: String
    public var sourceRevisions: [String]
    public var createdAt: Date
    public var status: ConversationRecapStatus
    public var passageID: String
    public var quote: String
    public var suggestedSentence: String
    public var explanation: String

    public init(sessionID: UUID, languageID: String, sourceRevisions: [String], createdAt: Date = .now,
                status: ConversationRecapStatus, passageID: String, quote: String,
                suggestedSentence: String, explanation: String) {
        self.sessionID = sessionID; self.languageID = languageID; self.sourceRevisions = sourceRevisions
        self.createdAt = createdAt; self.status = status; self.passageID = passageID
        self.quote = quote; self.suggestedSentence = suggestedSentence; self.explanation = explanation
    }

    public static func revisions(in session: SessionRecord) -> [String] {
        session.passages.map { $0.speaker.rawValue + "::" + $0.revisionKey }
    }

    /// Only the current, ended transcript may retain a recap. Corrections are
    /// suggestions about wording, never proof of pronunciation or proficiency.
    public func isValid(for session: SessionRecord) -> Bool {
        guard session.id == sessionID, session.languageID == languageID, session.endedAt != nil,
              session.passages.contains(where: { $0.speaker == .user && !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }),
              createdAt.timeIntervalSinceReferenceDate.isFinite, createdAt >= .distantPast, createdAt <= .distantFuture,
              sourceRevisions == Self.revisions(in: session), sourceRevisions.count <= 10_000,
              sourceRevisions.reduce(0, { $0 + $1.utf8.count }) <= 500_000,
              !explanation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, explanation.count <= 800 else { return false }
        switch status {
        case .noCorrection:
            return passageID.isEmpty && quote.isEmpty && suggestedSentence.isEmpty
        case .correction:
            guard !quote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, quote.count <= 1000,
                  !suggestedSentence.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  suggestedSentence.count <= 1000, suggestedSentence != quote,
                  let passage = session.passages.first(where: { $0.id == passageID && $0.speaker == .user }) else { return false }
            return passage.text.contains(quote)
        }
    }
}

public struct ConversationRecapResponse: Codable, Sendable {
    public var status: ConversationRecapStatus
    public var passageID: String
    public var quote: String
    public var suggestedSentence: String
    public var explanation: String

    public init(status: ConversationRecapStatus, passageID: String, quote: String, suggestedSentence: String, explanation: String) {
        self.status = status; self.passageID = passageID; self.quote = quote
        self.suggestedSentence = suggestedSentence; self.explanation = explanation
    }

    public func validated(for session: SessionRecord, at date: Date = .now) -> ConversationRecap? {
        let recap = ConversationRecap(sessionID: session.id, languageID: session.languageID,
            sourceRevisions: ConversationRecap.revisions(in: session), createdAt: date, status: status,
            passageID: passageID, quote: quote, suggestedSentence: suggestedSentence, explanation: explanation)
        return recap.isValid(for: session) ? recap : nil
    }
}
