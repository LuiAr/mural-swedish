/// Personal-key GPT-Live voice estimate. Supply monotonic uptime, never wall time.
/// Provider usage is cumulative and replaces the local timing baseline.
public struct VoiceCostMeter: Sendable {
    // https://developers.openai.com/api/docs/models/gpt-live-1 (2026-10-06).
    public static let usdPerMinute = 0.05
    public static let initializationSeconds = 15.0
    private var initialized = false
    private var sampleSeconds = 0.0
    private var sampleTime: Double?
    private var frozenSeconds: Double?

    public init() {}

    public mutating func created() { initialized = true }

    public mutating func started(now: Double) {
        guard now.isFinite, sampleTime == nil, frozenSeconds == nil else { return }
        initialized = true
        sampleTime = now
    }

    public mutating func update(seconds: Double, now: Double, final: Bool = false) {
        guard seconds.isFinite, seconds >= 0, now.isFinite else { return }
        // A final receipt may correct a local estimate, including after disconnect.
        guard final || frozenSeconds == nil else { return }
        initialized = true
        sampleSeconds = seconds
        sampleTime = now
        if final { frozenSeconds = seconds }
    }

    public func estimatedSeconds(now: Double) -> Double? {
        guard initialized else { return nil }
        if let frozenSeconds { return frozenSeconds }
        let elapsed = sampleTime.map { max(0, now - $0) } ?? 0
        // Creation's 15 seconds are credited against running duration, not added.
        return max(Self.initializationSeconds, sampleSeconds + elapsed)
    }

    public func estimatedUSD(now: Double) -> Double? {
        estimatedSeconds(now: now).map { $0 * Self.usdPerMinute / 60 }
    }

    public mutating func finish(now: Double) {
        guard frozenSeconds == nil else { return }
        frozenSeconds = estimatedSeconds(now: now)
    }
}
