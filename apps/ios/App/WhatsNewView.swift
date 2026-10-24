import SwiftUI
import MuralCore

enum InstalledAppVersion {
    static var version: String { Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown" }
    static var build: String { Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown" }
    static var buildLabel: String { "Build \(build)" }
}

struct WhatsNewView: View {
    private let release: AppReleaseNote?
    init(release: AppReleaseNote? = nil) { self.release = release }
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @ScaledMetric(relativeTo: .largeTitle) private var titleSize: CGFloat = 42
    @State private var previousRelease: AppReleaseNote?

    private var current: AppReleaseNote? {
        release ?? AppReleaseNotes.current(version: InstalledAppVersion.version, build: InstalledAppVersion.build)
    }
    private var history: [AppReleaseNote] { AppReleaseNotes.history(beforeBuild: InstalledAppVersion.build) }
    private func identifier(_ base: String) -> String { release.map { "\(base)-\($0.build)" } ?? base }
    private var buildHeading: String {
        release.map { "Mural \($0.version) · Build \($0.build)" }
            ?? "Mural \(InstalledAppVersion.version) · \(InstalledAppVersion.buildLabel)"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 10) {
                    Image("ReleaseAppIcon").resizable().scaledToFit()
                        .frame(width: 40, height: 40).clipShape(RoundedRectangle(cornerRadius: 10))
                        .accessibilityHidden(true)
                    Text(buildHeading).font(.headline).fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier(release == nil ? "whats-new-installed-build" : "whats-new-release-build")
                }
                .padding(.trailing, 58).padding(.top, 18).padding(.bottom, 34)

                Text(current?.name ?? "Your Mural updates")
                    .font(.system(size: titleSize, weight: .bold))
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityValue(current.map { "Version \($0.version) · Build \($0.build)" } ?? "")
                    .accessibilityIdentifier(identifier("whats-new-current-title"))
                Text(current?.summary ?? "Notes for this build aren’t available yet.")
                    .font(.title3).lineSpacing(2).fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 12)
                if let current {
                    Text(current.date).font(.caption).foregroundStyle(.secondary).padding(.top, 14)
                    VStack(alignment: .leading, spacing: 32) {
                        ForEach(current.highlights) { highlight in
                            VStack(alignment: .leading, spacing: 12) {
                                ReleaseFeatureArtwork(featureID: highlight.id)
                                    .accessibilityHidden(true).allowsHitTesting(false)
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(highlight.title).font(.title3.weight(.bold))
                                        .fixedSize(horizontal: false, vertical: true).accessibilityAddTraits(.isHeader)
                                        .accessibilityIdentifier("whats-new-heading-\(current.build)-" + highlight.id)
                                    Text(highlight.detail).font(.body).foregroundStyle(.secondary).lineSpacing(2)
                                        .fixedSize(horizontal: false, vertical: true)
                                }.padding(.horizontal, 10)
                            }
                            .accessibilityElement(children: .contain)
                            .accessibilityIdentifier("whats-new-feature-\(current.build)-" + highlight.id)
                        }
                    }.padding(.top, 32)
                }

                if release == nil && !history.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Previous updates").font(.title2.bold()).accessibilityAddTraits(.isHeader)
                            .padding(.bottom, 8)
                        ForEach(history) { release in
                            Button { previousRelease = release } label: {
                                HStack(spacing: 16) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(release.name).font(.headline)
                                        Text("Version \(release.version) · Build \(release.build) · \(release.date)")
                                            .font(.caption).foregroundStyle(.secondary)
                                    }.fixedSize(horizontal: false, vertical: true)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    Image(systemName: "chevron.right").font(.caption.weight(.semibold))
                                        .foregroundStyle(.secondary).accessibilityHidden(true)
                                }.padding(.vertical, 16).contentShape(Rectangle())
                            }.buttonStyle(.plain).accessibilityIdentifier("whats-new-history-\(release.build)")
                            Divider()
                        }
                    }.padding(.top, 40)
                }

                Text("Available offline.").font(.footnote).foregroundStyle(.secondary)
                    .padding(.top, 28).padding(.bottom, 40)
                    .accessibilityIdentifier(identifier("whats-new-footer"))
            }
            .padding(.horizontal, 24).frame(maxWidth: 620, alignment: .leading).frame(maxWidth: .infinity)
        }
        .accessibilityIdentifier(identifier("whats-new-scroll"))
        .background(Color(uiColor: .systemBackground).ignoresSafeArea()).foregroundStyle(.primary)
        .overlay(alignment: .topTrailing) {
            Group {
                if reduceTransparency {
                    closeButton.background(Color(uiColor: .systemBackground), in: Circle())
                        .overlay(Circle().strokeBorder(.secondary.opacity(0.2)))
                } else {
                    closeButton.glassEffect(.regular.interactive(), in: .circle)
                }
            }.padding(.trailing, 18).padding(.top, 12)
        }
        .fullScreenCover(item: $previousRelease) { WhatsNewView(release: $0) }
    }

    private var closeButton: some View {
        Button { dismiss() } label: {
            Image(systemName: "xmark").font(.system(size: 22, weight: .regular))
                .foregroundStyle(.primary).frame(width: 48, height: 48).contentShape(Circle())
        }
        .buttonStyle(.plain).accessibilityLabel("Close What’s New")
        .accessibilityIdentifier(identifier("whats-new-close"))
    }
}
