# Mural agent instructions

## Start from current main

At the start of each Mural coding task, fetch `origin/main` and base new branch work on that revision. Before opening a PR or marking one ready for review, fetch `origin/main` again, integrate any new commits into the working branch, resolve conflicts, and run the affected checks. Check once more for a newer `main` before merging. Preserve uncommitted and untracked work when updating a checkout; use an isolated worktree when that work would be at risk.

## Keep Talk minimal

William reaffirmed on September 28, 2026 that Talk should retain its original minimal layout. Put funding-boundary explanations and Continue/New conversation choices together in one native sheet, not inline on the home screen. Dismissal must preserve the conversation; the microphone can reopen the pending choice. Use the existing orange primary action and native platform patterns. Avoid additional splash/logo stages before Android's animated Talk orb.

## Ship UI and server changes together

When changing Mural's UI or native apps, check whether the experience depends on server changes: API contracts, error responses, prompts, capabilities, configuration, migrations or runtime permissions.

William requested on September 16, 2026 that required server deployment be part of delivering an authorized app/UI release. Deploy the matching tested server changes before reporting that release work is complete. A merged backend PR or published APK does not establish that production has the required behavior. If deployment is unnecessary, say why; if blocked, report the exact remaining step.

- Inspect the actual production revision and deployment wrapper. Preserve private configuration, enabled features, credentials and retained data. The backend README includes historical activation instructions; confirm current production settings before using them.
- Test the affected server behavior and app/server compatibility. Highlight every new UI/UX change before proposing or performing a merge.
- Before deployment, check active calls, retain the previous image and configuration, and take the existing encrypted backup. Apply only required migrations and runtime grants. Avoid interrupting active conversations.
- Deploy in a compatible order. Do not enable a client feature before its required server behavior is available.
- Verify the deployed source/image, public health and database readiness, affected endpoint contracts, and sanitized logs. Use non-billable checks unless a live provider call or purchase is separately authorized.
- Record the deployed revision, verification results, rollback location and any remaining limits. Distinguish local tests, live verification, merging and deployment in the handover.

Use the user's current instructions to resolve release scope and deferred work. Do not ask again for deployment approval already provided for that scope. This workflow does not authorize unrelated feature activation, pricing changes or destructive data operations.

## iOS pinyin interaction

Keep the optional reading in `PinyinHelp` non-selectable. On iOS 27, enabling text selection there intercepts taps on the sibling Show/Hide pinyin button. Verify changes with `testMandarinOnboardingWithOptionalPinyin` and `testMandarinTranscriptRetainsSourceTextAndPinyinAfterReset`; preserve the source text and word links.

## Personal-key voice cost estimate

The iOS Talk cost pill applies only to personal-key GPT-Live calls. `VoiceCostMeter` uses monotonic time between cumulative provider receipts, freezes on disconnect, and credits the 15-second WebRTC creation charge toward running duration. Keep it explicitly voice-only: helper tokens and search charges are separate, and the OpenAI dashboard is authoritative. The US$0.05/minute rate was checked against OpenAI documentation on October 6, 2026; recheck it if changing the model or pricing. Hosted minutes must not show this personal-key estimate. This local feature needs no server deployment or archive schema change. Verify with offline `--preview --preview-key --active-conversation` fixtures; do not make billable calls just to test the UI. The owner explicitly requires simulator checks to stay offline: never start live voice calls in the simulator. Installing a build on the phone does not authorize starting a conversation or other billable API checks.

`OpenAIBalanceLink` opens `https://platform.openai.com/settings/organization/billing/overview` in the system browser. Offer it in the existing Talk footer before personal-key calls, Settings → Advanced and the call-cost sheet. It does not read or estimate account credits, require an admin key, or access billing with the app's API key. Keep the destination shared and the normal browser sign-in flow intact; no server deployment is needed.

## Personal-key Pause and Resume

iOS personal-key calls use the main orange call control for Pause while active and Play while paused; do not add a second Pause action in the footer. Active personal-key calls also offer a separate Mute/Unmute button in the existing Talk footer. Mute silences the microphone without closing the connection, so voice billing continues; keep the main Pause control available while muted. Hosted calls retain their existing main-control mute behavior. Pause uses `session.close` and waits for `session.closed` before showing confirmed stopped billing. A timeout disconnects and labels final usage unconfirmed. Cancel automatic translation, feedback and delegation work on pause, and do not dispatch new automatic helpers while paused.

`PersonalConversationPause` persists only a local archive pointer, estimated voice duration and closure confirmation in UserDefaults. Restore only a matching, ended `Paused` record in the selected language. Preserve one logical session ID, theme/topic, source transcript, translations and evidence across reconnects. Rebase each new provider transcript timeline after the prior fragments, and accumulate per-connection voice receipts without charging the pause interval. Session limits count connected time. Keep failed reconnects resumable; connection generations prevent old helper results joining a resumed call. Reset, provider/language changes and New conversation clear the checkpoint.

Keep Resume/New conversation choices in the native sheet. Dismissing it preserves the pause; the orange microphone/play control reopens it. Begin reconnection after sheet dismissal completes so a quick connection error can present correctly. This feature does not alter hosted funding continuation, server contracts or the archive schema and needs no server deployment. Use simulator-only `--preview-paused`, `--preview-resume-failure` and `--preview-pause-timeout` fixtures for offline verification. Preview/checkpoint keys are isolated from owner data.

## Adaptive iOS Talk captions

Size Talk against the actual wrapped source, meaning and optional pinyin with `ViewThatFits`. Reduce the orb before scrolling; keep the call controls anchored on ordinary portrait screens. Very long source and meaning use one shared scroll area with natural text heights, rather than two equal-height scroll areas. Accessibility sizes and short windows use whole-page scrolling without nested vertical scroll views. Talk owns the pinyin expansion binding so fitting a different layout preserves Show/Hide state. Keep source word links, meaning toggling and pinyin interaction intact. Verify with offline `--preview-long-caption` and `--preview-overflow-caption` fixtures, including accessibility text and Mandarin.

## Upstream review integration

The upstream review branch retains adaptive caption sizing and uses upstream `FollowingPassage`/`CaptionFollowing` only for the shared overflow viewport. Touching it pauses automatic following for that passage across streaming revisions, meaning visibility and tab changes; a new passage starts following again. Accessibility and short windows keep whole-page scrolling. The two following UI checks use `conversation-passage-scroll`. Keep simulator-only preview setup behind `targetEnvironment(simulator)` so signed device builds compile.

Flashcard paging finishes asynchronously after its animation. UI checks must wait for the pager’s accessibility value before asserting the selected page; keep upstream SwiftUI paging and vertical long-meaning scrolling intact. Upstream guest/account deletion and hosted Dutch/Russian support require matching backend behavior before a hosted release; an isolated personal-key review branch is not a production deployment.

The Checks, Contracts and Android GitHub workflows support manual `workflow_dispatch` on a review branch. Use this to verify an isolated merge when pull-request events do not start CI; do not change main or production to run validation.
