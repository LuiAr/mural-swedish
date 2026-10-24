# What’s New on iPhone

Open **Settings → What’s New** to see the installed version and build, the release name and its highlights. Choose an earlier update to read its notes. The screen is available offline and does not interrupt Talk or appear automatically after installation.

- **1.0 build 11 — Make every word stick:** introduces the illustrated, full-screen update page and showcases four existing study tools.
- **1.0 build 10 — Updates at a glance:** introduces this menu and release history.
- **1.0 build 9 — More ways to practise:** saved-word/example listening, daily recall, conversation recap with typed retry, and cached Swedish noun/verb forms.

Release notes are bundled app metadata. Opening them makes no API request, reads no key and changes no learning record, setting or archive format. No server deployment is needed.

## Future deliveries

1. Add a named, dated entry with a short summary and concise user-facing highlights to `apps/ios/Core/AppReleaseNotes.swift`. Keep previous entries, newest first. Describe what changed and where to find it.
2. Increment the build in `scripts/generate_project.py` and regenerate the Xcode project. Both must match the release entry’s version/build. Keep build numbers increasing across versions.
3. Run the Core suite. `testShippingBuildMustHaveMatchingNotesAndGeneratorMetadata` fails when a delivery build lacks matching notes or the project and generator disagree.
4. Verify native Settings navigation and accessibility text using `testWhatsNewShowsInstalledBuildAndRecentChanges` and `testWhatsNewRemainsReadableAtAccessibilitySizes`. Both use offline preview storage and run in native CI alongside the seven study checks.

The installed metadata always comes from `Bundle.main`. An unknown running build gets an honest unavailable state, never another release’s name. History excludes the current build and future entries. Historical notes show their own version/build rather than borrowing the installed number.

## Design

The owner’s two Flighty screenshots guide the layout: an app icon and build label, a large headline and intro, wide rounded illustrations, bold captions with secondary body text, and a floating native glass close button that stays pinned as the page scrolls. Previous updates use the same full-screen layout; closing them returns to the installed build’s page. Mural retains its own icon, wording and colors.

The illustrations are native SwiftUI compositions with fixed listening, recall, recap and word-form examples. They are decorative, excluded from accessibility, and perform no playback or API work. Feature captions scale with Dynamic Type and the page supports dark appearance and Reduce Transparency. Build 11 deliberately showcases existing tools, as requested, and says so in its summary. It adds no new study behavior.
