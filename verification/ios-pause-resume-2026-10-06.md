# Personal-key Pause and Resume — October 6, 2026

Added a separate Pause action to iOS Talk for personal-key calls. Pause cancels automatic helper work, sends the existing graceful `session.close`, drains final usage, and releases the transport/audio session. Confirmed closure shows “Paused — voice billing stopped.” A five-second finalization timeout disconnects and explicitly marks final voice usage unconfirmed.

The native sheet offers Resume conversation and New conversation. Dismissal leaves the conversation paused; the orange play control reopens the sheet. Resume waits until sheet dismissal finishes, then opens a new Live session with the existing recent-text history and continuation greeting. A failed reconnect retains the checkpoint and supports retry. Muting continues to leave the call connected.

A small local UserDefaults checkpoint points to the existing archive record. Reconnection preserves one logical conversation ID, theme/topic, translations, learning evidence and full transcript; new provider timestamps and fragment IDs are rebased to prevent overlap or replacement. Per-connection voice receipts and estimates accumulate while excluding paused time. Session duration limits use connected time. Reset, New conversation and provider/language changes clear the checkpoint; missing/deleted records cannot resume.

No new archive fields, provider recordings, API credentials, server endpoints, runtime grants or migrations were introduced. Personal-key Live connections go directly to OpenAI, so no server deployment is needed. Resumption sends the existing bounded recent context (40 messages / 6 KB), plus the current theme and instructions; very old details may therefore be omitted even though the full transcript remains locally saved.

## Verification

- Fetched origin/main; branch HEAD and origin/main both `a21c072`. Preserved pre-existing uncommitted work and personal signing configuration.
- All 208 core tests passed, including six new pause checkpoint, transcript rebasing and multiple-connection cost tests.
- Eight targeted offline UI checks passed across the focused runs: pause/resume and transcript/cost preservation beyond the normal 15-second reset; persisted checkpoint restoration with failed reconnect/retry; unconfirmed finalization; largest accessibility Pause/Resume; hosted/idle visibility; largest accessibility cost sheet; existing hosted funding continuation; Mandarin source text/pinyin transcript regression.
- A fast reconnect failure initially conflicted with sheet dismissal. Starting after dismissal fixed it; the failure/retry test then passed. Its generic alert uses the existing default OK button.
- Simulator build and signed generic iPhone Debug build succeeded. Strict codesign verification passed. Bundle identifier remains `louisar.mural.swedish`.
- Active and paused screenshots were visually reviewed: [active](ios-pause-active-2026-10-06.png), [paused sheet](ios-pause-sheet-2026-10-06.png).
- git diff --check passed. Existing LiveTransport asynchronous-alternative warning remains.

## Delivery and limits

Installed the signed update on the connected iPhone 17 Pro after confirming that no Mural process was running. The existing bundle identity and app data were preserved. Device launch succeeded and a subsequent process check confirmed Mural remained running. No call was started.

No paid provider calls, purchase, merge or release publication was performed. Live speech, actual provider finalization and cold-launch recovery with a real phone conversation were not exercised. Offline simulator fixtures drive the normal pause/close/resume state paths without microphone access, keys or network requests. The new manual Pause action is personal-key only; hosted funding continuation remains as before.

API behavior: https://developers.openai.com/api/docs/guides/live-conversations#close-idle-sessions-and-resume
