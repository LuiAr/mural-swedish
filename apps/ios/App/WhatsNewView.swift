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
    private var current: AppReleaseNote? {
        release ?? AppReleaseNotes.current(version: InstalledAppVersion.version, build: InstalledAppVersion.build)
    }
    private var history: [AppReleaseNote] { AppReleaseNotes.history(beforeBuild: InstalledAppVersion.build) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                VStack(alignment: .leading, spacing: 14) {
                    Image(systemName: "sparkles")
                        .font(.system(.largeTitle, design: .rounded, weight: .medium))
                        .foregroundStyle(MuralColor.ink).padding(18)
                        .background(MuralColor.peach, in: RoundedRectangle(cornerRadius: 22))
                        .accessibilityHidden(true)
                    if let release {
                        Text("Version \(release.version) · Build \(release.build)")
                            .font(.subheadline).foregroundStyle(MuralColor.secondary)
                            .accessibilityIdentifier("whats-new-release-build")
                    } else {
                        Text("Mural \(InstalledAppVersion.version) · \(InstalledAppVersion.buildLabel)")
                            .font(.subheadline).foregroundStyle(MuralColor.secondary)
                            .accessibilityIdentifier("whats-new-installed-build")
                    }
                    Text(current?.name ?? "Your Mural updates")
                        .font(.system(.largeTitle, design: .rounded, weight: .semibold))
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityValue(current.map { "Version \($0.version) · Build \($0.build)" } ?? "")
                        .accessibilityIdentifier("whats-new-current-title")
                    if let current {
                        Text(current.date).font(.caption).foregroundStyle(MuralColor.secondary)
                    }
                }

                if let current {
                    highlights(current)
                } else {
                    Text("Notes for this build aren’t available yet. You can still read earlier updates below.")
                        .foregroundStyle(MuralColor.secondary).fixedSize(horizontal: false, vertical: true)
                }

                if release == nil && !history.isEmpty {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("Previous updates")
                            .font(.system(.title2, design: .rounded, weight: .semibold))
                            .accessibilityAddTraits(.isHeader)
                        ForEach(history) { release in
                            NavigationLink {
                                WhatsNewView(release: release)
                            } label: {
                                HStack(spacing: 16) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(release.name).font(.headline)
                                            .fixedSize(horizontal: false, vertical: true)
                                        Text("Version \(release.version) · Build \(release.build) · \(release.date)")
                                            .font(.caption).foregroundStyle(MuralColor.secondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }.frame(maxWidth: .infinity, alignment: .leading)
                                    Image(systemName: "chevron.right").font(.caption.weight(.semibold))
                                        .foregroundStyle(MuralColor.secondary).accessibilityHidden(true)
                                }
                                .padding(22).frame(maxWidth: .infinity, alignment: .leading)
                                .background(.white.opacity(0.65), in: RoundedRectangle(cornerRadius: 24))
                                .contentShape(RoundedRectangle(cornerRadius: 24))
                            }.buttonStyle(.plain).accessibilityIdentifier("whats-new-history-\(release.build)")
                        }
                    }
                }

                Text("Available offline. Come back whenever you’d like a reminder.")
                    .font(.footnote).foregroundStyle(MuralColor.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("whats-new-footer")
            }
            .padding(26).frame(maxWidth: 620, alignment: .leading).frame(maxWidth: .infinity)
        }
        .accessibilityIdentifier("whats-new-scroll")
        .background(MuralColor.cream).foregroundStyle(MuralColor.ink)
        .navigationTitle(release.map { "Build \($0.build)" } ?? "What’s New").navigationBarTitleDisplayMode(.inline)
    }

    private func highlights(_ release: AppReleaseNote) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            ForEach(release.highlights) { highlight in
                HStack(alignment: .top, spacing: 16) {
                    Image(systemName: highlight.symbol).font(.title3).foregroundStyle(MuralColor.ink)
                        .frame(width: 28).padding(.top, 2).accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 8) {
                        Text(highlight.title).font(.headline).fixedSize(horizontal: false, vertical: true)
                        Text(highlight.detail).font(.subheadline).foregroundStyle(MuralColor.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("whats-new-feature-\(release.build)-" + highlight.id)
            }
        }
        .padding(22).frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.65), in: RoundedRectangle(cornerRadius: 24))
    }
}
