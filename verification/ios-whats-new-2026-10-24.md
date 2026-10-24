# iPhone What’s New — 24 October 2026

Implemented on `codex/whats-new-build10`, based on refreshed main `2c7a11cc667014c12a267a85250ca93f4c9c0822`. This update remains separate from main pending PR review.

## Initial build 10 delivery

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

## Build 11 — illustrated update page

The owner supplied two Flighty screenshots and asked to see that layout with Mural content, including existing features. Build 11, **Make every word stick**, uses a full-screen page with the app icon and actual installed version/build, an oversized headline, an honest summary that identifies the tools as already available, large rounded illustrations, captions below, and a floating native glass close button pinned while scrolling. Historical builds use the same layout and close back to the parent. Settings remains the permanent entry point; no automatic pop-up was added.

Four native SwiftUI illustrations use fixed word-listening, daily-recall, conversation-recap and Swedish-form examples. They contain no active controls, playback, owner records or provider requests, and are hidden from accessibility. The images use Mural’s own icon and brand colors. The source catalog adds a summary per release, preserving builds 10 and 9. The generator and Xcode project both identify build 11. No server deployment is required because this update only changes local UI and bundled release metadata.

The first large-text check found that an off-panel decorative ring enlarged the forms group’s accessibility frame to the right of the screen. Drawing that ring within its Canvas bounds fixed the issue; the original viewport-bound assertion remains. A subsequent screenshot review caught a compressed recap illustration headline; its explicit illustration layout now preserves both lines above the cropped phone mockup.

Build 11 verification:

- All 248 Swift Core tests and 89 Python tooling tests passed, along with generated-content and cross-platform contract checks.
- All three affected offline native UI checks passed on the final source with zero failures or skips: normal update-screen navigation, largest accessibility text and existing Settings notices. The update checks retain version/build identity, historical-build identity, forms visibility and viewport bounds; they now also assert a pinned, reachable close button and dismissal back through Settings to Talk. All seven study checks remain configured in native CI; they were not rerun locally for this presentation-only revision. Their earlier build-10 run is recorded above.
- The final header, scrolled feature previews, history and largest-text captures were exported. Normal and large-text layouts were visually reviewed. The recap phone is deliberately cropped within its image panel; the two-line illustration headline remains visible.
- The signed Xcode 27.1 iPhone Release build passed strict deep signature verification, actual entitlement checks, owner bundle/team checks and the disabled hosted/sign-in/purchase configuration checks. No hosted capability was enabled.
- The phone initially reset a read-only CoreDevice handshake; retrying recovered the connection. Installation succeeded over the existing app. Physical readback confirmed **Mural 1.0 build 11**, replacing build 10 under the same personal bundle. The app was left closed; physical interaction with the new page remains untested.
- All 27 original local/private files remain unchanged. The isolated Local.xcconfig remains byte-identical to the owner’s copy and ignored. No uninstall, reset, key change, live provider call, purchase or physical app launch occurred.
- Refreshed origin/main remains `2c7a11cc667014c12a267a85250ca93f4c9c0822`. The redesign updates draft PR #6; main has not been changed. Remote CI for the new commit is distinct from these local results.

Build-11 evidence: `/private/tmp/mural-build11-core.log`, `/private/tmp/mural-build11-python.log`, `/private/tmp/mural-build11-ui-delivery.xcresult`, `/private/tmp/mural-build11-screenshots-delivery`, `/private/tmp/mural-build11-device-final.log`, `/private/tmp/mural-build11-device-final/Build/Products/Release-iphoneos/Mural.app`, `/private/tmp/mural-build11-install.json` and `/private/tmp/mural-build11-installed-after.json`. The two primary simulator captures are also copied into this chat’s visualization folder for review.
