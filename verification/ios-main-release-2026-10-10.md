# Personal iPhone delivery — October 10, 2026

PR [#2](https://github.com/LuiAr/mural-swedish/pull/2) was merged into main as `57bbaf9b0cc0d9d6cc5a3bea30d014381e1b94c0`. The signed iPhone app was rebuilt from that merged revision and installed on the owner's connected iPhone 17 Pro. Device readback confirms Mural 1.0, build **5**, bundle identifier `louisar.mural.swedish`, replacing build 4.

The update includes the upstream review integration and the restored separate Mute/Unmute control alongside Pause. Existing [upstream verification](upstream-review-2026-10-10.md) and [four Mute regression checks](ios-mute-control-2026-10-10.md) cover the unchanged app behavior. The final preparation only increments the build number in both the Xcode project and generator and documents the owner's offline-only testing requirement.

## Verification and scope

- Generic signed iPhone build from merged main passed; strict deep code-signature verification passed. Build log: `/tmp/mural-main-iphone-build-5.log`.
- Installation succeeded; `devicectl device info apps` read back build 5. Receipts: `/tmp/mural-main-iphone-install-5.json`, `/tmp/mural-delivery-installed-after.json`, and `/tmp/mural-main-iphone-build-5-receipt.json`.
- The existing bundle identifier and personal signing configuration were retained. No uninstall, credential edit, data reset or migration was performed. The original dirty checkout remains untouched.
- Hosted accounts, Google/Apple sign-in and purchases are disabled in the installed personal-key build; its managed API URL is empty. This delivery needs no backend deployment. Hosted production compatibility remains outside this personal-build delivery; enabling those upstream hosted features would require the matching backend.
- The app was installed without launching it. No live voice call, billable API test or purchase was started. Physical microphone/speaker behavior and the new UI on the phone remain for the owner to try.

The pre-upstream source snapshot `8c548f2` remains available for recovery. This delivery record changes documentation only; the installed app source is the merged main revision above.
