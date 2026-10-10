import Foundation

/// Local checkpoint only. Text, themes, translations and learning evidence stay
/// in the existing archive; no provider recording or credential is stored here.
public struct PersonalConversationPause: Codable, Sendable {
    public let sessionID: UUID
    public let estimatedVoiceSeconds: Double
    public let closureConfirmed: Bool

    public init(sessionID: UUID, estimatedVoiceSeconds: Double, closureConfirmed: Bool) {
        self.sessionID = sessionID
        self.estimatedVoiceSeconds = estimatedVoiceSeconds
        self.closureConfirmed = closureConfirmed
    }

    public func recover(from sessions: [SessionRecord], languageID: String) -> SessionRecord? {
        guard estimatedVoiceSeconds.isFinite, estimatedVoiceSeconds >= 0 else { return nil }
        return sessions.first {
            $0.id == sessionID && $0.languageID == languageID && $0.endedAt != nil && $0.endReason == "Paused"
        }
    }

    /// Each new Live connection starts its transcript clock at zero. Leave a
    /// presentation gap so its first delta cannot merge into an earlier passage.
    public static func transcriptOffset(for session: SessionRecord) -> Int {
        min(session.fragments.map(\.endMS).max() ?? 0, Int.max - 3_000) + 3_000
    }

    public static func fragment(_ fragment: Fragment, offset: Int, connectionID: UUID) -> Fragment? {
        let (start, startOverflow) = fragment.startMS.addingReportingOverflow(offset)
        let (end, endOverflow) = fragment.endMS.addingReportingOverflow(offset)
        guard offset >= 0, fragment.startMS >= 0, fragment.endMS >= fragment.startMS,
              !startOverflow, !endOverflow else { return nil }
        var result = fragment
        result.startMS = start; result.endMS = end
        if offset > 0 { result.id = "\(connectionID.uuidString):\(fragment.id)" }
        return result
    }
}
