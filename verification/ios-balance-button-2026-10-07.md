# OpenAI balance button — October 7, 2026

Added a shared native `OpenAIBalanceLink` labeled **Check OpenAI balance**. It opens `https://platform.openai.com/settings/organization/billing/overview` in the system browser, preserving OpenAI's normal sign-in flow. It does not fetch account credits or require another API key.

The link appears in the existing Talk footer before personal-key calls, in Settings → Advanced for personal-key access, and in the call-cost sheet. Talk's active-call footer retains Type instead and A little help. No server deployment is required: this is a local browser link with no API, prompt, capability, archive or database changes.

Simulator compilation and signed generic iPhone Debug compilation passed. Strict deep code-signature verification passed. Three existing native UI checks passed: greeting/meaning toggling, fixed Talk controls across call/meaning-error states, and the call-cost sheet at the largest accessibility text size. No new tests were added for this reversible link change.

UI result bundle: `/Users/louisar/Library/Developer/XcodeBuildMCP/workspaces/mural-swedish-8e3a08c2d814/result-bundles/test_sim_2026-10-07T06-42-06-742Z_pid28695_13604952.xcresult`. Signed build log: `/tmp/mural-balance-button-device-build.log`.

The idle personal-key preview was visually inspected, and the native accessibility tree exposed the link with its browser-opening hint. The owner then reported **“It works i tested now”**, confirming the link behavior. [Talk preview](ios-balance-button-2026-10-07.jpg).

Mural was not running on the iPhone immediately before installation. The tested update installed over the existing `louisar.mural.swedish` app using the existing signing identity, preserving data and keys. CoreDevice installation sequence: `4212`; app container: `/private/var/containers/Bundle/Application/8E3A7B49-FE21-448B-BE18-B8684F0ADA9B/Mural.app/`.

The updated app launched normally on the iPhone without verification arguments or starting a call.

No paid provider call, purchase, key inspection, commit, PR, merge or server deployment was performed. Existing uncommitted work was preserved. `origin/main` was fetched at task start and matched `HEAD` at `a21c072`.
