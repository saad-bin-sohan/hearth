# Hearth — Progress Tracker

**This file is the single source of truth for what has actually been done.** `plan.md` describes the plan; this file describes reality. If the two ever disagree, believe this file. Every task ID below matches `plan.md` exactly — look up the ID there for full detail, rationale, and the exact fix approach before starting or resuming any task.

## How to use this file

- **Status values:** `Not Started` · `In Progress` · `Done — verification pending` · `Verified` · `Blocked`
- An AI agent session may move a task to `Done — verification pending` after making the change and reporting the verification commands. **Only the project owner may mark a task `Verified`** — that means they personally ran the relevant `flutter` commands and confirmed it works.
- If a task is `Blocked`, the Notes column says on what — don't attempt it until that's resolved.
- Update the row(s) for whatever you worked on before ending your session, including a one-line note if anything deviated from `plan.md`. Add a dated note rather than deleting history — this file should show the project's actual trail, not just its current state.
- The **Overall Status** table at the top is a quick-glance summary — update its counts whenever a phase's task statuses change.

---

## Overall status

| Phase | Tasks | Not Started | In Progress | Done (pending) | Verified | Blocked |
|---|---|---|---|---|---|---|
| 0 — Environment & Foundation | 6 | 5 | 0 | 1 | 0 | 0 |
| 1 — Firestore Schema & Rules | 4 | 4 | 0 | 0 | 0 | 0 |
| 2 — Authentication | 7 | 7 | 0 | 0 | 0 | 0 |
| 3 — Household | 3 | 3 | 0 | 0 | 0 | 0 |
| 4 — Chores | 4 | 4 | 0 | 0 | 0 | 0 |
| 5 — Finance | 3 | 3 | 0 | 0 | 0 | 0 |
| 6 — Grocery | 4 | 4 | 0 | 0 | 0 | 0 |
| 7 — Maintenance | 5 | 5 | 0 | 0 | 0 | 0 |
| 8 — Documents / Vault | 4 | 4 | 0 | 0 | 0 | 0 |
| 9 — Notifications | 5 | 5 | 0 | 0 | 0 | 0 |
| 10 — Calendar | 3 | 3 | 0 | 0 | 0 | 0 |
| 11 — Cross-Cutting Cleanup | 6 | 6 | 0 | 0 | 0 | 0 |
| 12 — Distribution Readiness | 4 | 4 | 0 | 0 | 0 | 0 |
| **Total** | **58** | **57** | **0** | **1** | **0** | **0** |

**Only the planning documents themselves exist so far** (task 0.6, this delivery). Everything else in the project is genuinely not started yet — that's expected and correct at this stage.

---

## Phase 0 — Environment & Foundation Setup

| ID | Task | Label | Status | Date | Notes |
|---|---|---|---|---|---|
| 0.1 | Fix Android build-breaking `key.properties` bug | 🤖 | Not Started | | Blocks all Android builds until done — do this first. |
| 0.2 | Bump iOS deployment target to 15.0 | 🤖 | Not Started | | |
| 0.3 | Create the Firebase project | 🧑 | Not Started | | Do **not** enable Cloud Storage or Blaze. |
| 0.4 | Install FlutterFire CLI, run `flutterfire configure` | 🧑 | Not Started | | Depends on 0.3. |
| 0.5 | Set up `fake_cloud_firestore` + Firebase Local Emulator Suite | 🤖 | Not Started | | |
| 0.6 | Land `.claude/CLAUDE.md`, `.claude/settings.json`, `plan.md`, `progress.md` | 🤖 | **Done — verification pending** | 2026-09-24 | Delivered as the first output of this project. Project owner still needs to place these files in the repo and commit them. |

## Phase 1 — Firestore Schema & Security Rules

| ID | Task | Label | Status | Date | Notes |
|---|---|---|---|---|---|
| 1.1 | Write `firestore.rules` | 🤖 | Not Started | | Fixes S3. |
| 1.2 | Write `firestore.indexes.json` | 🤖 | Not Started | | |
| 1.3 | Deploy rules and indexes to the real project | 🧑 | Not Started | | Depends on 0.3, 1.1, 1.2. |
| 1.4 | Establish the `fake_cloud_firestore` repository test pattern | 🤖 | Not Started | | Later phases copy this pattern. |

## Phase 2 — Authentication Migration

| ID | Task | Label | Status | Date | Notes |
|---|---|---|---|---|---|
| 2.1 | Replace local auth with Firebase Authentication | 🤖 | Not Started | | |
| 2.2 | Rebuild the 4 auth screens with consistent error handling | 🤖 | Not Started | | Fixes B2. |
| 2.3 | Centralize the auth route guard via `go_router` `redirect` | 🤖 | Not Started | | Fixes A1. |
| 2.4 | Remove `session_provider.dart` | 🤖 | Not Started | | |
| 2.5 | Add biometric quick-unlock | 🤖 | Not Started | | New feature, not a bug fix. |
| 2.6 | Fix vault PIN hashing + add lockout | 🤖 | Not Started | | Fixes S1, S1b, S2. |
| 2.7 | Update auth tests | 🤖 | Not Started | | |

## Phase 3 — Household Migration

| ID | Task | Label | Status | Date | Notes |
|---|---|---|---|---|---|
| 3.1 | Rewrite household repository for Firestore | 🤖 | Not Started | | |
| 3.2 | Real invite codes + real scannable QR code | 🤖 | Not Started | | Fixes B5. Adds `qr_flutter` dependency. |
| 3.3 | Update household tests | 🤖 | Not Started | | Include a real cross-device-join test. |

## Phase 4 — Chores Migration

| ID | Task | Label | Status | Date | Notes |
|---|---|---|---|---|---|
| 4.1 | Rewrite chore repository for Firestore | 🤖 | Not Started | | |
| 4.2 | Build shared recurrence utility (`lib/core/utils/recurrence.dart`) | 🤖 | Not Started | | Fixes B1 (1 of 3). Also used by Phases 5 and 7. |
| 4.3 | Fix missing `mounted` guard in `complete_chore_sheet.dart` | 🤖 | Not Started | | Fixes B4 (1 of 3). |
| 4.4 | Update chores tests | 🤖 | Not Started | | |

## Phase 5 — Finance Migration

| ID | Task | Label | Status | Date | Notes |
|---|---|---|---|---|---|
| 5.1 | Rewrite finance repository for Firestore | 🤖 | Not Started | | |
| 5.2 | Apply shared recurrence utility to recurring bills | 🤖 | Not Started | | Fixes B1 (2 of 3). Depends on 4.2. |
| 5.3 | Update finance tests | 🤖 | Not Started | | |

## Phase 6 — Grocery Migration

| ID | Task | Label | Status | Date | Notes |
|---|---|---|---|---|---|
| 6.1 | Rewrite grocery repository for Firestore | 🤖 | Not Started | | |
| 6.2 | Consolidate expiry-urgency logic onto shared `ExpiryStatus` | 🤖 | Not Started | | Fixes B6. Coordinate with 9.4 (same utility). |
| 6.3 | Add User-Agent header to Open Food Facts calls | 🤖 | Not Started | | Fixes P2. |
| 6.4 | Update grocery tests | 🤖 | Not Started | | Delete Drift migration test. |

## Phase 7 — Maintenance Migration

| ID | Task | Label | Status | Date | Notes |
|---|---|---|---|---|---|
| 7.1 | Rewrite maintenance repository for Firestore | 🤖 | Not Started | | |
| 7.2 | Apply shared recurrence utility, fix overflow bug | 🤖 | Not Started | | Fixes B1 (3 of 3). Depends on 4.2. |
| 7.3 | Fix 2 remaining missing `mounted` guards | 🤖 | Not Started | | Fixes B4 (2–3 of 3). |
| 7.4 | Remove dead recurrence-string parsing branch | 🤖 | Not Started | | Fixes B7. |
| 7.5 | Update maintenance tests | 🤖 | Not Started | | Delete Drift migration test. |

## Phase 8 — Documents / Vault Migration

| ID | Task | Label | Status | Date | Notes |
|---|---|---|---|---|---|
| 8.1 | Rewrite document repository — metadata to Firestore, files stay local | 🤖 | Not Started | | |
| 8.2 | Build per-document visibility choice UI | 🤖 | Not Started | | |
| 8.3 | Confirm "Admins Only" is genuinely enforced | 🤖 | Not Started | | Fixes S3 (client side; rule already written in 1.1). |
| 8.4 | Update documents tests | 🤖 | Not Started | | Include a non-admin-denied-read test via the emulator. Delete Drift migration test. |

## Phase 9 — Notifications Overhaul

| ID | Task | Label | Status | Date | Notes |
|---|---|---|---|---|---|
| 9.1 | Add Android 13+ `POST_NOTIFICATIONS` permission | 🤖 | Not Started | | Fixes N1. |
| 9.2 | Replace `.show()` with real `zonedSchedule()` calls | 🤖 | Not Started | | Fixes N4. Largest task in this phase. |
| 9.3 | Fix notification re-spam with targeted cancel/reschedule | 🤖 | Not Started | | Fixes N2. |
| 9.4 | Unify alert thresholds with shared `ExpiryStatus` | 🤖 | Not Started | | Fixes N3. Coordinate with 6.2. |
| 9.5 | Update notification tests | 🤖 | Not Started | | |

## Phase 10 — Calendar Migration

| ID | Task | Label | Status | Date | Notes |
|---|---|---|---|---|---|
| 10.1 | Rewrite calendar aggregation for Firestore | 🤖 | Not Started | | Preserve existing deep-link routes exactly — verified correct already. |
| 10.2 | Fix hardcoded USD currency | 🤖 | Not Started | | Fixes B3. |
| 10.3 | Update calendar tests | 🤖 | Not Started | | |

## Phase 11 — Cross-Cutting Cleanup

| ID | Task | Label | Status | Date | Notes |
|---|---|---|---|---|---|
| 11.1 | Remove Drift entirely | 🤖 | Not Started | | **Do not start until Phases 3–10 all show Verified.** |
| 11.2 | Fix stale README / in-app copy | 🤖 | Not Started | | Fixes P1. |
| 11.3 | Add themed `errorBuilder` for unmatched routes | 🤖 | Not Started | | Fixes P3. |
| 11.4 | Resolve quick-add-document vault bypass | 🤖 | Not Started | | Fixes P4. Needs a 1-line intent confirmation from project owner first. |
| 11.5 | Spot-check `HearthButton` `isLoading` wiring | 🤖 | Not Started | | Fixes B8. Check the 3 named screens specifically. |
| 11.6 | Full regression test pass | 🤝 | Not Started | | |

## Phase 12 — Distribution Readiness

| ID | Task | Label | Status | Date | Notes |
|---|---|---|---|---|---|
| 12.1 | Generate a real local release keystore | 🧑 | Not Started | | Never commit this or hand it to an AI session. |
| 12.2 | Build and verify signed release APK on real Android device(s) | 🧑 | Not Started | | This is the real test of the whole project's point: 2 real devices, same household, syncing. |
| 12.3 | Verify iOS build | 🧑 | Not Started | | Needs a Mac + Xcode. Accept the 7-day reinstall limitation. |
| 12.4 | Final full regression pass, both platforms | 🧑 | Not Started | | |

---

## Open questions / decisions still needed from the project owner

- **11.4**: does the quick-add-document shortcut bypassing the vault lock for *adding* (not viewing) reflect intended behavior, or should it also require unlocking first?

## Deviations from `plan.md` (log any here as they happen — don't edit plan.md itself without also noting why here)

*(none yet)*
