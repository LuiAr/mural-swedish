# Upstream maintenance and build 12 — 26 October 2026

The owner approved integrating upstream PRs [#171](https://github.com/Chuloo/mural/pull/171) and [#173](https://github.com/Chuloo/mural/pull/173), leaving alert exceptions disabled, validating PostgreSQL behavior, and delivering the next iPhone build. The isolated branch starts from refreshed fork main `011605eb7a385eed1fcf0aa93f19e3d90ad93f50` and merges upstream `607c3bbc28f22cfbc3b109fff28cb4d2f62ace9a`, retaining the fork's history and customizations.

Apple history catch-up now uses consecutive windows of at most seven days with five-minute overlap, preserved pagination dates and failed-page rollback. Checkout readiness still requires a recent verified completion. The monitor supports exact, audited helper-usage exceptions, but no exception entry, approval record, operational configuration or financial adjustment is added here. Both changes retain their upstream regression tests. No schema migration or runtime grant is added.

The first full fork CI run passed 535 of 536 API tests and exposed a timing flaw in the upstream clock-advance test: its frozen JavaScript clock could precede PostgreSQL's default `next_poll_after=now()`. The fixture now explicitly sets an already-due timestamp under the frozen clock. All original page, timestamp and completion assertions remain, and production polling behavior is unchanged. The integration PR records the corrected full-suite result separately.

The iPhone delivery metadata advances from build 11 to 12 in both the Xcode project and generator. Settings → What’s New adds **Keeping things steady**, dated 26 October, clearly describing maintenance rather than a new personal-key study feature. Previous release entries remain. Native app behavior, Talk, Swedish support, study tools, private settings and learning records are unchanged.

## Completed local validation

- 248 Swift Core tests passed, including exact shipping-build/release-note/generator matching.
- 91 Python tooling tests passed, including 33 payment-monitor tests.
- Generated Android content and cross-platform contracts passed.
- Both affected offline native UI checks passed, zero failures/skips: `testWhatsNewShowsInstalledBuildAndRecentChanges` and `testWhatsNewRemainsReadableAtAccessibilitySizes`.
- Normal build-12 release page and the largest-text historical page captures were visually reviewed. Build identity, history navigation, text wrapping and the pinned close control remain intact.
- The existing private Local.xcconfig is byte-identical to the owner's copy and remains ignored. The original checkout's 27-file content manifest is retained for the final preservation check.

Core log: `/private/tmp/mural-upstream12-core.log`. Native UI result: `/private/tmp/mural-upstream12-whats-new.xcresult`. Captures: `/private/tmp/mural-upstream12-ui-captures/`.

The integration PR records the full PostgreSQL 17 API suite and other remote checks separately. Those checks validate this fork's candidate, rather than relying on upstream CI. Signed release compilation, installation and physical version readback are separate delivery evidence and are reported after building from merged main. The pre-delivery physical-phone readback confirmed Mural 1.0 build 11.

## Release scope and safeguards

This is source maintenance for hosted services plus the required iPhone delivery metadata. The owner's personal-key app retains disabled hosted accounts, sign-in and purchases, with an empty managed API URL. No server deployment is needed for that disabled path. Any separately authorized hosted rollout follows AGENTS.md's actual-production, active-call, backup, configuration, rollback and deployed-verification requirements.

No provider call, purchase, live financial operation or production configuration change is part of this integration. The physical app must remain closed after installation, and version/build readback must match the signed artifact. Installation does not establish physical microphone/speaker or release-page behavior.
