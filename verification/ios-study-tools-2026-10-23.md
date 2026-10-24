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

## Owner Mac verification — 24 October 2026

The Mac checked out candidate `458c5ff313d26fe1e40c4af44b95e351e8bd3a84` in an isolated worktree based on current `origin/main` (`2ff10a8`). The original dirty checkout, its untracked files and private `Local.xcconfig` were preserved; hashes of all 27 local/private files remained unchanged.

Final results for that exact candidate:

- [Checks run 40076412429](https://github.com/LuiAr/mural-swedish/actions/runs/40076412429): Swift Core and server passed (244 and 533 tests); Simulator and unsigned iPhone Release builds passed. Native UI passed six of seven checks. Swedish forms passed; the flashcard boundary-page assertion exceeded its three-second accessibility wait, although the subsequent diagnostic tree reported the expected `1 of 4` value.
- [Android run 40076412405](https://github.com/LuiAr/mural-swedish/actions/runs/40076412405): unit tests, lint, builds, release validation and all 94 emulator tests passed. Contracts and secret scanning also passed on this candidate.

Local Xcode 27.1 / iOS 27 Simulator checks:

- All 244 Swift Core tests passed with zero failures.
- The unchanged flashcard gesture test passed locally. Its exact-page wait was then increased from three to ten seconds for loaded CI simulators. No page, short-drag, boundary, vertical-scroll, full-deck or word-form assertion was removed or weakened; the slow short drag still ends with a stationary release, and word details still open through the real row-center tap.
- All seven targeted offline UI checks passed together after the timing adjustment, with zero failures or skips. Preview storage and fixed recap/forms/pronunciation responses kept these checks offline. The workflow retains all seven checks.
- The iPhone Release compilation passed with the owner's existing private configuration. The artifact reports `louisar.mural.swedish`, version `1.0`, build `8`. Managed accounts, Apple/Google sign-in and Apple purchases remain disabled, and the managed API URL is empty.

Signed physical delivery completed on 24 October after the owner refreshed the existing Apple Account. The connected iPhone 17 Pro initially reported `louisar.mural.swedish`, version `1.0`, build `7`; the successful in-place installation and device readback confirmed version `1.0`, build `8`. The existing bundle identifier and signing team were retained. Strict deep signature verification passed, and the development profile is valid until 31 October 2026 at 09:47:24 UTC.

The initial build reported `No Accounts`. After account refresh, a signing retry requested Sign in with Apple even though the resolved personal settings disabled it. A byte-identical copy of the existing private configuration in the worktree's ignored `apps/ios/Config/Local.xcconfig`, together with fresh isolated DerivedData, resolved the mismatch. The final build checks confirmed the expected bundle, version, build, team, device provisioning and disabled hosted/sign-in/purchase features before installation. Hashes of all 27 original local/private files remained unchanged, including the original signing configuration. No uninstall, reset, key change, app launch, live provider request or purchase occurred.

The installed app was built from tested code revision `d6e18b86e9a7106294d9267224e24abff9d38577`. All [native/server Checks](https://github.com/LuiAr/mural-swedish/actions/runs/40078890433), [Android checks](https://github.com/LuiAr/mural-swedish/actions/runs/40078890428), [contracts](https://github.com/LuiAr/mural-swedish/actions/runs/40078890400) and [secret scanning](https://github.com/LuiAr/mural-swedish/actions/runs/40078890461) completed successfully on that revision: 244 Swift Core tests, 533 server tests, all seven offline native UI checks, Simulator and unsigned iPhone Release builds, Android unit/lint/build/release checks and all 94 emulator tests. The later delivery-record update changes documentation only.

Local evidence: `/private/tmp/mural-build8-swift.log`, `/private/tmp/mural-build8-seven-ui.xcresult`, `/private/tmp/mural-build8-device-fresh-signed.log`, `/private/tmp/mural-build8-device-fresh/Build/Products/Release-iphoneos/Mural.app` (signed), `/private/tmp/mural-build8-install.json` and `/private/tmp/mural-build8-installed-after.json`. Earlier failed signing and unsigned compile logs are retained separately.

PR #5 remains a draft and main remains unchanged. No server deployment is required for the personal-key study paths. Physical voice availability and speaker/headphone routing remain unverified.
