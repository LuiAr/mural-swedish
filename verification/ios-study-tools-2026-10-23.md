# Personal study tools — 23 October 2026

Review: [PR #5](https://github.com/LuiAr/mural-swedish/pull/5), branch `codex/swedish-practice-tools-2026-10-23`, based on refreshed fork main `2ff10a8`.

The four requested changes were implemented in order: normal/slow word and saved-example listening, a daily active-recall queue, source-grounded conversation recaps with typed retry, and Swedish noun/verb reference cards. Their interfaces live in Words and conversation history. Talk retains its existing layout.

The delivery candidate is Mural 1.0, build 8, aligned in the Xcode project and generator. No phone installation or App Store/TestFlight upload was performed from this Linux workspace. The owner's existing bundle identifier, team, Keychain and private signing configuration must be reused on the Mac for signed installation; do not uninstall or reset the existing app.

## Validation

- 71 portable Swift tests passed: 47 existing learning/language/theme tests and 24 tests for review, recap and word forms. The harness uses unchanged production Foundation sources; Apple-only purchase/account modules are excluded on Linux.
- The full native Swift Core suite passed all 244 tests on 24 October. The local Kotlin study-model harness passed all 23 tests using the production serialization plugin.
- All 89 Python tooling tests, generated Android content and cross-platform checks passed.
- Swift frontend parsing passed for App and UI-test sources. This checks syntax; the native build provides Apple-framework type checking.
- Kotlin Core/archive counterparts and tests preserve the new optional study fields in Android backups. Android unit/build/lint/emulator validation runs through the existing PR workflow.
- Android CI passed unit tests, lint, debug/release builds and all 94 emulator tests on candidate `aff2ecf` ([run](https://github.com/LuiAr/mural-swedish/actions/runs/40073329135)).
- The PR's native Checks job builds the iPhone Simulator app, runs the study screens with offline fixtures, exports screenshots and builds an unsigned iPhone Release app. Exact run results are recorded in the PR description and GitHub Checks; an intermediate compiled simulator build does not establish a final device installation.

The study interfaces use temporary preview storage and fixed responses. No live provider calls, purchases, raw-key inspection or owner-data reset were used for verification. Installed voice availability, physical speaker/headphone routing, signed installation and installed-version readback still require the owner's Mac and iPhone.

## Data and release scope

Review grades, generated recaps and word-form cards stay separate from transcript learning evidence and spoken-recall bars. Optional archive fields preserve older schema-2 backups; imports merge newer matching study material while retaining current source/evidence. Transcript revisions invalidate recaps. Hidden or unsupported words lose their reference cards. Encoding rejects archives above the same 30 MB limit used on import, before new data replaces the stored payload.

Listening uses installed iPhone voices. Recap/form generation is explicit and uses the app's existing personal key and AI-processing permission. Cached material works offline. These features add no hosted API contracts, migrations, accounts or purchase activation, so no server deployment is required.

See the [study tool guide](../docs/study-tools.md) for navigation, playback behavior, review intervals and generated-content limits.
