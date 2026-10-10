import SwiftUI
import MuralCore

struct OpenAIBalanceLink: View {
    static let destination = URL(string: "https://platform.openai.com/settings/organization/billing/overview")!

    var body: some View {
        Link(destination: Self.destination) {
            Label("Check OpenAI balance", systemImage: "arrow.up.right.square")
                .fixedSize(horizontal: false, vertical: true)
                .frame(minHeight: 44).contentShape(Rectangle())
        }
        .accessibilityHint("Opens your OpenAI billing page in the browser")
        .accessibilityIdentifier("openai-balance")
    }
}

struct CallCostIndicator: View {
    let coordinator: ConversationCoordinator
    @State private var showingDetails = false

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { _ in
            if let cost = coordinator.estimatedVoiceCostUSD {
                Button { showingDetails = true } label: {
                    HStack(spacing: 6) {
                        Text("Voice ≈ \(Self.amount(cost))").monospacedDigit()
                        Image(systemName: "info.circle")
                    }
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(MuralColor.secondary)
                    .padding(.horizontal, 12).padding(.vertical, 7)
                    .background(MuralColor.butter.opacity(0.45), in: Capsule())
                    .frame(minHeight: 44).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Estimated voice cost, \(Self.amount(cost))")
                .accessibilityHint("Shows pricing and what is charged during quiet time")
                .accessibilityIdentifier("call-cost")
            }
        }
        .sheet(isPresented: $showingDetails) { CallCostDetails(coordinator: coordinator) }
    }

    static func amount(_ cost: Double) -> String {
        cost.formatted(.currency(code: "USD").locale(Locale(identifier: "en_US")).precision(.fractionLength(2)))
            .replacingOccurrences(of: "$", with: "US$")
    }
}

private struct CallCostDetails: View {
    let coordinator: ConversationCoordinator
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    TimelineView(.periodic(from: .now, by: 1)) { _ in
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Estimated voice cost").font(.subheadline).foregroundStyle(MuralColor.secondary)
                            Text(CallCostIndicator.amount(coordinator.estimatedVoiceCostUSD ?? 0))
                                .font(.system(.largeTitle, design: .rounded, weight: .semibold)).monospacedDigit()
                        }.accessibilityElement(children: .combine)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("US$0.05 per minute").font(.headline)
                        Text("GPT-Live 1 bills by the second while connected. Speaking, listening and quiet time all cost the same. Tap Pause when taking a break, or end the call.")
                        Text("Opening a connection initially charges 15 seconds. That is credited toward the call’s duration, and is included in this estimate.")
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Voice only").font(.headline)
                        Text("Translations, learning feedback and searches cost extra. This estimate uses elapsed time and reported voice usage. It stops during a pause and includes earlier parts of a resumed conversation. Final charges may differ.")
                        OpenAIBalanceLink()
                        Link("View final usage in OpenAI", destination: URL(string: "https://platform.openai.com/usage")!)
                        Link("OpenAI voice pricing", destination: URL(string: "https://developers.openai.com/api/docs/guides/voice-latency-cost")!)
                            .font(.footnote)
                        Text("Rate checked October 6, 2026. Amounts are in US dollars.")
                            .font(.footnote).foregroundStyle(MuralColor.secondary)
                    }
                }.padding(24)
            }
            .background(MuralColor.cream).foregroundStyle(MuralColor.ink)
            .navigationTitle("Call cost").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
        .tint(MuralColor.ink)
        .presentationDetents(typeSize.isAccessibilitySize ? [.large] : [.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
