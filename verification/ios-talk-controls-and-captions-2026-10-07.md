# iOS Talk controls and adaptive captions — October 7, 2026

The owner requested that the main mute control become Pause, and that long live transcripts get more space without disrupting Talk's minimal layout.

## Result

- In personal-key calls, the main orange button now displays a pause symbol and closes/saves the call using the existing Pause implementation. The paused control displays Play and opens the existing Resume/New conversation sheet. The separate footer Pause action is removed. The stable `start-conversation` accessibility identifier is retained; its label reflects Start, Pause or Resume.
- The source text, meaning, optional pinyin and learner transcript use their natural wrapped heights. `ViewThatFits` selects an orb size that leaves enough room for the actual content. It replaces the previous character-count heuristic and two equally sized scroll boxes.
- When content exceeds the available space even with a small orb, one scroll area holds both source and meaning. Ordinary portrait call controls stay anchored. Accessibility text sizes and short windows scroll the whole page without nested vertical scroll views.
- The learner's text is no longer limited to one line or its last 160 characters. Word links, subtitle toggling and optional pinyin remain available. Talk owns the pinyin expansion binding so changing the fitted layout does not reset the user's Show/Hide choice.
- The cost sheet now describes the primary Pause action. Existing personal-key billing, checkpoint and resume behavior is retained. Hosted calls retain their existing mute and funding-continuation behavior.

No server deployment is needed: this changes local SwiftUI layout and routes the existing personal-key call control to the existing close/resume behavior. There are no API, prompt, capability, archive or database contract changes.

## Verification

Simulator compilation and the signed generic iPhone Debug build succeeded. Strict deep signature verification succeeded using the system trust store; sandboxed verification could not access that trust store.

The initial four native UI checks passed: long source and meaning fully visible with a smaller orb, long source/meaning scrolling through the final line while controls stay fixed, Pause/Resume with retained transcript and frozen cost across the normal reset delay, and stable controls across greeting/conversation/meaning-error states.

Initial result bundle: `/Users/louisar/Library/Developer/XcodeBuildMCP/workspaces/mural-swedish-8e3a08c2d814/result-bundles/test_sim_2026-10-07T05-38-35-790Z_pid28695_0f733972.xcresult`.

Twelve additional native UI checks passed with no failures or skips: long captions at the largest accessibility text size, full wrapped learner transcript, pinyin Show/Hide persistence through layout changes, original Mandarin onboarding and retained-transcript pinyin, largest-text Pause/Resume, persisted pause recovery and failed reconnect retry, cost accumulation and cost-sheet dismissal, unconfirmed-close handling, hosted/idle estimate visibility, greeting/Meaning toggling and hosted funding continuation. **Sixteen targeted UI checks passed in total.**

Additional result bundle: `/Users/louisar/Library/Developer/XcodeBuildMCP/workspaces/mural-swedish-8e3a08c2d814/result-bundles/test_sim_2026-10-07T05-43-43-310Z_pid28695_c4c3a359.xcresult`.

All checks use offline preview fixtures and cached translations; no paid provider calls or purchases were made. This task changes no production Core behavior, so the previously passing core suite was not rerun. Real speech/audio and live-provider pause behavior were not exercised in this task.

Reviewed native screenshots:

- [Long source and meaning with primary Pause](ios-talk-long-caption-2026-10-07.png)
- [Scrolled through the final translation](ios-talk-overflow-caption-2026-10-07.png)

These screenshots are retained locally; the repository's existing `verification/*.png` ignore rule excludes them from Git.

Signed build log: `/tmp/mural-talk-layout-device-build.log`. Built app: `/Users/louisar/Documents/DevSwift/mural-swedish/.build/DeviceDerivedData/Build/Products/Debug-iphoneos/Mural.app`.

## Delivery

The existing uncommitted work was preserved. `origin/main` was fetched at task start; `HEAD` and `origin/main` remained at `a21c072` with no divergence. No branch reset, commit, PR, merge or server deployment was performed.

Immediately before installation, the paired iPhone was reachable and Mural was not running. The tested update installed successfully over the existing `louisar.mural.swedish` app using the existing signing identity. Installation URL: `/private/var/containers/Bundle/Application/AAB6DDBE-1085-4184-AB75-2B6C6D8754AA/Mural.app/`; CoreDevice database sequence number: `4188`. No uninstall, credential inspection or learning-data reset was performed.

The normal launch attempt was denied because the iPhone was locked (`FBSOpenApplicationErrorDomain` code 7, `Locked`). Installation is verified; opening the updated app on the physical phone remains pending unlock. No call was started. The owner can unlock the phone and open Mural normally.
