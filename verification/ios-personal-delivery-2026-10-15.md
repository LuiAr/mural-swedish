# Personal iPhone delivery — 15 October 2026

The owner requested a physical-phone build and installation after each completed Mural update, including backend-only updates. AGENTS.md and the existing weekly upstream-review automation now retain that default. Scheduled reviews remain review/planning only; their later authorized implementation includes a signed build and installation attempt.

This delivery starts from refreshed main `eaeaece81b3f98715abff01a5f91dcac3af76385`, containing the merged upstream closeout update in PR #3. It increments `CURRENT_PROJECT_VERSION` from 6 to 7 in both the Xcode project and its generator. Native app logic and UI are unchanged.

## Build and installation evidence

- Xcode 27 signed Debug build for the connected physical iPhone 17 Pro: passed.
- Strict deep signature verification: passed with macOS trust-store access. The sandboxed verifier initially reported `CSSMERR_TP_NOT_TRUSTED`; the host verification resolved that environment limitation.
- Built bundle: `louisar.mural.swedish`, Mural 1.0, build 7.
- Installation over the existing app: succeeded using `devicectl`, without uninstalling or resetting it.
- Device readback before installation: Mural 1.0, build 6.
- Device readback after installation: Mural 1.0, build 7.
- 89 Python tooling tests, generated Android content and cross-platform contracts: passed.

The app's built Info.plist confirms managed accounts, Google/Apple sign-in and Apple purchases remain disabled, and the managed API URL remains empty. Existing private personal signing settings were reused without publishing them. No app launch, voice call, purchase, credential inspection or owner-data reset was performed. Installation and version readback do not establish physical microphone/speaker or UI behavior.

Build log: `/private/tmp/mural-personal-delivery-20261015-build.log`. Signed app: `/private/tmp/mural-personal-delivery-20261015-derived/Build/Products/Debug-iphoneos/Mural.app`. Installation and device version receipts are `/private/tmp/mural-personal-install-20261015.json`, `/private/tmp/mural-personal-installed-before-20261015.json` and `/private/tmp/mural-personal-installed-after-20261015.json`.

No server deployment is required for this personal-key delivery: its hosted path is disabled, and this release changes build identification and the delivery workflow. The separately applicable hosted migration and deployment requirements remain in AGENTS.md.

The original checkout's unrelated app edits and untracked work are preserved. Its AGENTS.md receives only the new delivery guidance so agents entering that still-dirty checkout also see the owner's instruction.
