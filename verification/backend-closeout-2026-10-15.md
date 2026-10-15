# Hosted closeout source integration — 15 October 2026

PR [#3](https://github.com/LuiAr/mural-swedish/pull/3) merges upstream [Chuloo/mural#168](https://github.com/Chuloo/mural/pull/168), revision `bb45a7b0af230f966970b587047611cac9e0f9cc`, into the fork's current main at `63cd37c99aaf2fc7d096a96f907f5cd477244ec8`. The validated source revision is `9416785e6d687804d744d1a04eac6f8b5a2bed18`; subsequent verification documentation does not change those sources.

The backend retains final voice usage before settlement, replays saved authoritative evidence after failure or restart, and continues receiving final usage after a rejected close command. It adds durable store reconciliation health and monitoring for unresolved teaching requests. The fork's Swedish provider entry is preserved.

## Account-load test cleanup

Upstream's post-merge server suite passed 532 tests and failed one: the ten-thousand-account sign-in test timed out on its bulk cleanup `DELETE`, after its sign-in and account-count assertions had passed. This integration deletes those synthetic fixture accounts in batches of 250. It retains all ten thousand accounts during the assertions and leaves the production database statement timeout unchanged. The corrected test passed in PostgreSQL 17 CI in 6.97 seconds, including its full assertions and cleanup.

## Verification

- Local Python tooling: 89 passed, including 31 payment monitor tests.
- Local generated Android content and cross-platform contracts: passed.
- Local API type-check and build: passed.
- Local API tests without PostgreSQL: 140 passed, 0 failed, 393 skipped. Fake-provider socket tests ran with localhost access after the sandbox blocked their local servers.
- [Checks](https://github.com/LuiAr/mural-swedish/actions/runs/38692130661): 220 Swift core tests and all 533 PostgreSQL 17 server tests passed, with zero server skips. API type-check and build passed in the same workflow. This includes final-usage preservation/replay, runtime grants, reconciliation ordering and the account-load regression.
- [Contracts](https://github.com/LuiAr/mural-swedish/actions/runs/38692133492): passed.
- [Secret scan](https://github.com/LuiAr/mural-swedish/actions/runs/38692136541): passed.

The original dirty checkout's status and changed-file content hashes were verified unchanged. Integration work is isolated at `/Users/louisar/.codex/worktrees/mural-hosted-closeout/mural-swedish` on `codex/upstream-closeout-2026-10-15`.

## Release scope

This is backend source synchronization. Native iOS and Android source, app configuration, signing, dependency versions and the installed app are unchanged. Hosted accounts, sign-in, purchases and managed API access remain disabled in the owner's personal-key configuration. Its voice calls use the personal-key client path, so this source integration needs no server deployment for the current app behavior.

For a separately authorized hosted server release, apply migration `035_closeout_evidence_and_health.sql` and `operations/closeout-evidence-runtime-grants.sql` before replacing the API. Enable monitor `reconciliationHealth` only for migrated targets. Preserve private configuration, monitor state, balances and unresolved holds, and follow AGENTS.md's active-call, encrypted-backup, rollback and deployment verification requirements.

No production deployment, production migration, live provider call, purchase, app installation, device launch or owner-data reset was performed. CI and fake-provider tests do not establish current production behavior or physical-device behavior.
