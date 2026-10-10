# iOS personal-key call cost — October 6, 2026

Added a compact, tappable `Voice ≈ US$…` pill beneath Talk’s call status. Its native sheet explains the US$0.05/minute GPT-Live 1 rate, silence/mute billing, the 15-second connection credit, separate helper/search charges and the authoritative OpenAI dashboard. Hosted calls and idle personal-key screens do not show this estimate.

`VoiceCostMeter` uses monotonic uptime and cumulative provider receipts. Creation’s 15 seconds are credited toward elapsed duration rather than added. Final receipts replace estimates; local disconnect freezes an unconfirmed estimate. Conversation reset/provider changes clear the meter. No archive fields, API contracts, credentials or server configuration changed.

Sources checked on October 6, 2026:
- https://developers.openai.com/api/docs/models/gpt-live-1
- https://developers.openai.com/api/docs/guides/voice-latency-cost

Offline preview: [Talk with cost indicator](ios-call-cost-preview-2026-10-06.jpg).

## Local verification

- `origin/main` fetched at task start; branch HEAD and origin/main were `a21c072`. Preserved existing uncommitted work and personal signing configuration.
- Simulator build succeeded (iPhone 17 Pro, iOS 27).
- Signed generic iPhone Debug build succeeded. Strict code-signature verification passed. Bundle identifier remains `louisar.mural.swedish`.
- All 202 Swift core tests passed, including five new billing/lifecycle tests.
- Four targeted offline UI checks passed: mute still advances the estimate, pricing sheet dismissal preserves the call, ended calls freeze the amount, hosted/idle visibility, and largest accessibility text. The first ended-call test run used an incorrect transcript accessibility label; corrected to the existing `Conversation transcript` label and rerun successfully.
- `git diff --check` passed.
- Existing LiveTransport asynchronous-alternative warning remains.

The estimate is voice-only in USD, uses a documented rate constant, and is not an invoice or spending cap. It does not estimate cached helper tokens, long-context pricing, search charges or taxes. No live provider calls, purchases, merge or release publication were performed. No server deployment is needed because personal-key voice connects directly to OpenAI and this feature calculates/display costs locally.

## iPhone installation

The signed update is ready in `.build/DeviceDerivedData/Build/Products/Debug-iphoneos/Mural.app`. The later [Pause and Resume update](ios-pause-resume-2026-10-06.md), including this cost indicator, was installed on the connected iPhone after confirming Mural was not running.
