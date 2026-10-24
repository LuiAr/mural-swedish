# iPhone What’s New — 24 October 2026

Implemented on `codex/whats-new-build10`, based on refreshed main `2c7a11cc667014c12a267a85250ca93f4c9c0822`. This update remains separate from main pending PR review.

## Delivered behavior

Settings → What’s New shows the actual installed `Bundle.main` version/build and the matching release name and date. Version 1.0 build 10 is **Updates at a glance**. Its Previous updates menu opens build 9, **More ways to practise**, with the four recent study-tool highlights. Native navigation, system symbols, Mural’s existing colors and scalable text keep the screen consistent with Settings. There is no automatic pop-up over Talk.

Notes are bundled, offline, read-only app metadata. Opening the screen makes no API request and changes no owner setting, key, learning record or archive schema. No backend deployment or Android archive change is needed. The Core shipping-build test now requires an exact release entry and matching project/generator build metadata for future deliveries. AGENTS.md retains this workflow.

## Verification

- All 248 Swift Core tests passed, including exact current-build matching, future/unknown build handling, history ordering/identity and project/generator/release-note consistency.
- All 89 Python tooling tests, generated Android content and cross-platform contract checks passed.
- All 10 selected offline native UI checks passed with zero failures or skips: the two new normal/accessibility update-screen checks, the existing Settings notices check and all seven study-tool checks. CI retains the seven study checks and adds both update-screen checks.
- Normal and largest accessibility screenshots were exported and visually inspected. Historical build-9 notes retain their own version/build rather than borrowing build 10’s installed label.
- Xcode 27.1 signed iPhone Release build 10 passed strict deep signature verification and actual bundle/team/entitlement/feature-setting checks. The personal bundle remains `louisar.mural.swedish`; managed accounts, Apple/Google sign-in and purchases stay disabled, with an empty managed API URL.
- A transient CoreDevice connection reset occurred before installation. A read-only handshake recovered the connection. Installation then succeeded over the existing version 1.0 build 9. Physical device readback confirmed version 1.0 build 10.
- The original checkout’s 27 local/private files remained unchanged, and the worktree’s private signing copy remains byte-identical and ignored. No uninstall, reset, key change, physical app launch, voice call, live provider request or purchase occurred. The new menu’s physical interaction was not tested because the app was left closed.

Evidence: `/private/tmp/mural-build10-core.log`, `/private/tmp/mural-build10-python.log`, `/private/tmp/mural-build10-ui.xcresult`, `/private/tmp/mural-build10-screenshots`, `/private/tmp/mural-build10-device.log`, `/private/tmp/mural-build10-device/Build/Products/Release-iphoneos/Mural.app`, `/private/tmp/mural-build10-install.json` and `/private/tmp/mural-build10-installed-after.json`.

[Feature/release workflow guide](../docs/whats-new.md). The PR records the current commit and remote-check status separately from these completed local checks and device receipts.
