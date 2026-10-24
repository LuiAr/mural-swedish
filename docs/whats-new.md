# What’s New on iPhone

Open **Settings → What’s New** to see the installed version and build, the release name and its highlights. Choose an earlier update to read its notes. The screen is available offline and does not interrupt Talk or appear automatically after installation.

- **1.0 build 10 — Updates at a glance:** introduces this menu and release history.
- **1.0 build 9 — More ways to practise:** saved-word/example listening, daily recall, conversation recap with typed retry, and cached Swedish noun/verb forms.

Release notes are bundled app metadata. Opening them makes no API request, reads no key and changes no learning record, setting or archive format. No server deployment is needed.

## Future deliveries

1. Add a named, dated entry with concise user-facing highlights to `apps/ios/Core/AppReleaseNotes.swift`. Keep previous entries, newest first. Describe what changed and where to find it.
2. Increment the build in `scripts/generate_project.py` and regenerate the Xcode project. Both must match the release entry’s version/build. Keep build numbers increasing across versions.
3. Run the Core suite. `testShippingBuildMustHaveMatchingNotesAndGeneratorMetadata` fails when a delivery build lacks matching notes or the project and generator disagree.
4. Verify native Settings navigation and accessibility text using `testWhatsNewShowsInstalledBuildAndRecentChanges` and `testWhatsNewRemainsReadableAtAccessibilitySizes`. Both use offline preview storage and run in native CI alongside the seven study checks.

The installed metadata always comes from `Bundle.main`. An unknown running build gets an honest unavailable state, never another release’s name. History excludes the current build and future entries. Historical notes show their own version/build rather than borrowing the installed number.

## Design references

The short feature highlights borrow the structure of [Flighty’s published release notes](https://apps.apple.com/gb/app/flighty-live-flight-tracker/id1358823008). The versioned history takes inspiration from [Fantastical’s release notes](https://flexibits.com/fantastical-ios/releasenotes). Mural uses its own copy, system symbols and existing cream/orange styling, with native navigation and scalable text. These references describe published notes, not a replica of either app’s private interface.
