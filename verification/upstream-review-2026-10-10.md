# Upstream merge review — October 10, 2026

## Review branch and preservation

Draft PR: https://github.com/LuiAr/mural-swedish/pull/2

Branch: `codex/upstream-review-2026-10-10`, in `/Users/louisar/.codex/worktrees/upstream-review/mural-swedish`.

Fork main was fetched at task start and before the draft PR; it remains `a21c072`. The fork is two commits ahead of the common ancestor and upstream adds seven commits through `Chuloo/mural@7bf1128` (#165). The upstream history is merged, not squash-copied.

The original checkout remains on `claude/personal-signing-config`, with all 26 changed/untracked source and verification files unchanged (hash-checked against the snapshot). `8c548f2` preserves that work on this branch before the upstream merge `4193b54`. Private local signing settings were copied into the ignored worktree-local xcconfig and never committed. No main reset, main merge, phone installation or data migration was performed.

## Visible changes and merge decisions

- Preserve Swedish alongside upstream Dutch and Russian in iOS, Android, meaning choices and the server locale allowlist.
- Retain personal-key voice cost, Pause/Resume, the primary orange Pause control and the OpenAI billing link.
- Keep actual wrapped text sizing, shrinking orb, shared overflow viewport, anchored call controls and whole-page accessibility/short-window scrolling. Upstream gentle caption following replaces the overflow scroll helper, rather than replacing adaptive sizing with two fixed three-line windows. Touch pauses following for the current passage across streaming revisions, meaning toggles and navigation; the next passage resumes it. Pinyin expansion and source word links remain intact.
- Adopt upstream flashcards, AI processing permission controls, full-capsule onboarding taps and purchase/account recovery changes. Flashcard code remains upstream SwiftUI code; UI tests wait for the page animation to finish before checking accessibility values.
- Move debug preview setup out of the large SwiftUI body and guard simulator-only caption preview calls. This fixes the imported signed-device compilation error.
- Add Swedish to both new Android all-language caption fixtures. The initial emulator run passed 92/94 checks and failed only these missing-fixture assertions; the corrected run is recorded below.
- Existing Checks, Contracts and Android workflows can be manually dispatched on a review branch. Automatic PR checks did not start despite enabled workflows; no repository permissions or production settings were changed.

[Reviewed Swedish long-caption preview](ios-upstream-review-2026-10-10.jpg)

## Local verification

- Simulator build and offline Swedish preview launch passed. Signed generic iPhone Debug build and strict deep signature verification passed.
- 220 Swift core tests and 78 Python tooling tests passed; shared platform parity passed.
- 18 distinct targeted native iOS UI checks passed across the recorded runs: captions and following, pinyin, accessibility text, Pause/Resume and recovery, cost details, Swedish/Dutch/Russian onboarding, consent withdrawal and flashcards. Initial flashcard assertions read before the transition completed; the final three flashcard checks pass with asynchronous value expectations.
- API type-check passed. Without local PostgreSQL, 140 API tests passed and 388 skipped; CI subsequently exercised all 528 with PostgreSQL 17 and zero skips.
- No billable provider calls, purchases, real account deletions or owner-data resets were used. Device speech/audio and live provider behavior were not exercised.

Native result bundles are under `/Users/louisar/Library/Developer/XcodeBuildMCP/workspaces/mural-swedish-8e3a08c2d814/result-bundles/`:

- Initial 14/16 successful checks: `test_sim_2026-10-10T09-29-37-367Z_pid85071_4ff75656.xcresult` (tool response timed out; xcodebuild completed and its saved log/result was inspected).
- Additional onboarding/pinyin/following checks: `test_sim_2026-10-10T09-38-02-252Z_pid85071_3f62ed4a.xcresult`.
- Final flashcards: `test_sim_2026-10-10T09-52-52-500Z_pid85071_06447f11.xcresult` — 3 passed, 0 failed/skipped.

Final signed build log: `/tmp/mural-upstream-device-build.log`; device app: `/tmp/mural-upstream-device-derived/Build/Products/Debug-iphoneos/Mural.app`. Simulator app: `/tmp/mural-upstream-derived/Build/Products/Debug-iphonesimulator/Mural.app`.

Existing SDK warnings remain: the StoreKit purchase-error switch, the callback statistics API and an upstream verification-only redundant HTTP response cast. They do not prevent builds.

## GitHub verification

- [Checks](https://github.com/LuiAr/mural-swedish/actions/runs/38042373195): Swift core and all 528 PostgreSQL server tests passed, zero server skips, on `9321fc9` (these production sources are unchanged by later UI-test/fixture fixes).
- [Contracts](https://github.com/LuiAr/mural-swedish/actions/runs/38042375108): tooling, generated content and cross-platform parity passed.
- [Secret scan](https://github.com/LuiAr/mural-swedish/actions/runs/38042439811): redacted history scan passed.
- [Initial Android](https://github.com/LuiAr/mural-swedish/actions/runs/38042376873): unit/lint/build/release checks passed; emulator 92/94 passed, with two missing Swedish-fixture assertions corrected in `c2e5681`.
- [Corrected Android run](https://github.com/LuiAr/mural-swedish/actions/runs/38043102253): in progress at report creation; update before handover.

## Release scope and manual review

This is an isolated review branch, not an app/server release. Main and production are unchanged. Personal-key caption, cost, pause and balance-link features remain local. Upstream hosted guest/account deletion changes (`DELETE /v1/guest/account`, `confirmCreditAccessLoss`, `account_usage_pending`) and Dutch/Russian hosted admission require the matching tested backend before a hosted release. No migrations were added by this upstream range. Production compatibility/deployment verification remains a separate release step; this draft PR does not establish that production has the new contracts.

Open `apps/ios/Mural.xcodeproj` from the isolated worktree to test this branch. The ignored personal signing xcconfig is already present. For a no-cost simulator check, use `--preview --preview-key --active-conversation --preview-language=sv --preview-long-caption`, or replace the final flag with `--preview-overflow-caption`. Use `--preview-caption-following` to exercise streaming following, `--preview-paused` for Resume, and `--preview --screenshot=words` for flashcards. These are offline fixtures; launch normally for actual use. The installed physical-phone app was not replaced.
