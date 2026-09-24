# Hearth — Upgrade & Bug-Fix Plan

**This document is the single source of truth for what Hearth is, what it is becoming, why every major decision was made, and exactly what work remains.** It is written so that a fresh Claude session — with zero memory of any prior conversation, given only this repo's zip file, this document, and `progress.md` — can understand the entire project and correctly execute any single task without anyone re-explaining anything.

If you are that fresh session: read this whole document once before touching code, then check `progress.md` to see what's already done, then re-read only the specific phase/task section you've been assigned before doing the work.

---

## 0. How to read this document

- **Section 1** — what Hearth is today, for someone who has never seen it.
- **Section 2** — the original codebase as it was found, before any of this upgrade work began (architecture, stack, git history).
- **Section 3** — the Northstar vision and every hard constraint that shapes this upgrade. These are non-negotiable unless the project owner explicitly changes them in this file.
- **Section 4** — the target architecture in detail (Firestore schema, auth, notifications, vault, invites).
- **Section 5** — key engineering decisions, explained in plain language with rationale, including a few things deliberately *not* being done and why.
- **Section 6** — the complete inventory of bugs and issues found during the original audit, each with severity, root cause, and fix approach.
- **Section 7** — the session protocol: how any AI session should operate given the project's actual workflow.
- **Section 8** — the phased build plan itself: every phase, task, and subtask, each labeled for who does it.

### Label legend (used throughout Sections 6 and 8)

| Label | Meaning |
|---|---|
| 🤖 **AI Agent** | A Claude session can fully complete this by reading/writing/editing code in the repo. The standard verification loop (person runs `flutter analyze` / `flutter test` / `flutter pub get` and reviews the diff) applies automatically and is not repeated for every single item. |
| 🧑 **Human Required** | Needs the project owner to do something no AI agent can do on their behalf — create an account, click through a web console, generate or store a secret, physically test on a real device, or make a decision involving money. The specific action is always spelled out. |
| 🤝 **Mixed** | The AI agent does most of the work, but a distinct, callable-out human action is embedded partway through (not just "then verify"). |

### The standard verification loop (implied for every 🤖 task, not restated each time)

1. AI agent makes the code change and reports back exactly what changed and what to run.
2. Person runs `flutter pub get` (if dependencies changed), `flutter analyze`, and the relevant `flutter test` command(s).
3. Person reviews the diff, commits it to git with a clear message, and marks the task/subtask as done in `progress.md`.
4. If anything fails, that goes back to a fresh Claude session as a new, small, well-described task — not silently patched by guessing.

---

## 1. What Hearth is

Hearth is a Flutter mobile app — a "household operating system" covering everything a group of roommates or a family needs to coordinate:

- **Auth** — account creation, sign in, password reset, onboarding.
- **Household** — create a household, invite/join members, assign roles (admin / member / observer).
- **Chores** — assign chores with fair rotation, track completion streaks, and a fairness score showing whether workload is being shared evenly.
- **Finance** — log shared expenses, split them (equally, by percentage, fixed amounts, or with exemptions), track running balances between household members, recurring bills.
- **Grocery** — a shared shopping list and a pantry tracker with barcode scanning (via the free Open Food Facts database) and expiry tracking.
- **Documents** — a "vault" for important documents (passports, warranties, IDs, insurance) with expiry tracking and a PIN/biometric lock.
- **Maintenance** — track home assets (appliances, systems), maintenance tasks with recurrence, and a vendor directory with ratings.
- **Calendar** — a shared calendar aggregating upcoming items from every other feature (bills due, chores due, documents expiring, maintenance due).

It was originally built as a demo project for job-hunting purposes. It is well-architected (feature-based Clean Architecture, 27 test files, genuinely solid patterns in several places) but has a number of real bugs, and — most importantly — it is **100% local and single-device**, with no way for two different phones to actually share the same household data. This upgrade turns it into a real, working multi-device app while fixing every bug found in a full audit.

---

## 2. The original codebase, as found

This section documents the state of the repository *before* this upgrade began, established through a full manual audit (the Flutter/Dart toolchain could not be executed in the auditing environment due to sandbox network restrictions — this was a careful static read of every relevant file, git history, and configuration, not a compiler-verified pass).

### 2.1 Tech stack (original)

- Flutter, Dart SDK constraint `^3.11.1`.
- **Riverpod 2.6.1** for state management.
- **go_router 14.8.1** for navigation (a `StatefulShellRoute` with bottom-nav tabs per feature).
- **Drift 2.28.2** (SQLite) — a single local `AppDatabase` spanning every feature, migrations handled up to schema version 6.
- `local_auth` (biometric prompts, used for the vault), `camera` / `image_picker` / `file_picker` (document scanning and photo attachment), `flutter_pdfview` (viewing PDFs), `mobile_scanner` (barcode scanning for groceries), `flutter_local_notifications` (in-app alerts), `crypto` (hand-rolled PBKDF2 password hashing), `share_plus` (sharing invite text), `hugeicons` (icon set).
- Android and iOS platform folders only — no web/desktop targets.

### 2.2 Architecture (original, and preserved going forward)

Feature-based Clean Architecture. Each feature folder (`lib/features/<name>/`) has:
- `domain/` — entities and use cases; pure Dart, no knowledge of Drift, Firestore, or any specific data source. This is exactly why the backend migration is tractable: the domain layer (fairness scoring, expense splitting, balance netting, expiry-status calculation) does not need to change at all when the data layer underneath it is swapped from Drift to Firestore.
- `data/` — repositories implementing the domain's repository interfaces, talking to the actual data source (previously Drift; going forward, Firestore).
- `presentation/` — Riverpod notifiers (state + business orchestration) and widgets/screens.

### 2.3 Git history (original)

Eight commits total, six of them "Phase 1" through "Phase 6," each adding one feature module in sequence (foundation/auth/household → finance → chores → documents → grocery → maintenance/calendar/vendors), followed by a README update and a gitignore/Android config update. The commits were made within a single day for the six feature phases, consistent with this being a demo built in a concentrated sprint.

### 2.4 What was already done well (preserve these patterns)

- **Password hashing** (`password_hasher.dart`): a correct, from-scratch PBKDF2-HMAC-SHA256 implementation, 100,000 iterations, proper per-user random salt, constant-time comparison. Genuinely solid — better than a lot of production code. This utility is being **repurposed** (see Section 4.4) rather than thrown away, even though Firebase Auth takes over the main login.
- **Expense split engine** (`split_engine.dart`) and **balance engine** (`balance_engine.dart`): correct integer-cent math throughout (no floating point money), correct largest-remainder apportionment for percentage splits, correct pairwise debt netting between household members.
- **Shared expiry-status utility** (`core/utils/expiry_status.dart`): correctly normalizes dates to midnight before differencing, avoiding the classic off-by-one bug that comes from comparing timestamps with time-of-day still attached.
- **`HearthButton`** (`core/widgets/hearth_button.dart`): correctly disables its own tap handler when `isLoading` is true, preventing double-submission — a pattern other new buttons should keep using.
- **Vault auto-lock on backgrounding**: the app correctly force-locks the document vault the instant it's backgrounded (in `app.dart`'s lifecycle listener), not just relying on the inactivity timer — a genuinely good proactive security habit already in place.
- A comprehensive existing test suite: 27 test files, with coverage across nearly every feature including edge cases (fairness score capping, split rounding, migration behavior).

This is a strong foundation. The bugs documented in Section 6 are real, but they sit inside genuinely well-organized bones — this upgrade is a renovation, not a rebuild.

---

## 3. The Northstar vision and every hard constraint

Everything in this section came from an extensive requirements conversation with the project owner, one topic at a time, before any implementation work began. These are not assumptions — each one was explicitly confirmed. Treat every constraint in this section as binding unless the project owner updates this file directly.

### 3.1 Purpose of the upgrade

Hearth is becoming **both** a genuinely usable real app (the owner intends to actually use it with a real household) **and** a stronger portfolio piece to show future employers. This means: favor solid, well-reasoned engineering judgment over impressive-looking complexity — a good interviewer respects pragmatism more than needless sophistication — while also making sure the app is actually reliable for day-to-day real use, since real people will depend on it.

### 3.2 The core architectural change: local-only → real backend

The original app's "household invite" system only ever created a second row in the *same device's* local SQLite database — there was never a way for two different phones to actually share data. The QR code shown during invites was **entirely decorative** (a hardcoded grid pattern, encoding no real data whatsoever — verified by reading the widget's source directly). This upgrade replaces the entire local-only data layer with a real backend so that multiple real phones can genuinely share one household's data.

**Backend choice: Firebase** (Cloud Firestore for data, Firebase Authentication for login). Chosen specifically because it gives real-time sync essentially for free with Firestore, and because Firebase Cloud Messaging offered a path toward fixing the notification system — though see 3.4 below for how the cost constraint changed that specific piece.

### 3.3 The hard, zero-cost constraint — read this before adding any dependency or Firebase feature

**No feature may ever require a credit card, a paid plan, or any billing account.** This was stated explicitly and firmly: *"Choose the option that doesn't require any kind of integration of money or cards. If the implementation of any feature requires money, then drop that feature."* This has real, specific consequences that must not be silently reversed by a future session:

- **Firebase stays on the free Spark plan, permanently.** No Cloud Functions (they require the paid Blaze plan). No Firebase Cloud Storage (as of February 2026, Google requires a linked billing account — the paid Blaze plan — for Cloud Storage regardless of actual usage volume; this is not optional even for zero real cost).
- Firestore, Firebase Authentication (standard email/password), and Firebase Cloud Messaging *delivery* are all free at personal-household scale with no card required — the core sync goal is fully achievable at $0.
- **Consequence for the Document Vault:** actual document *files* can never be uploaded to Firebase Cloud Storage. Files always stay on the local device that added them — there is no cross-device file sync, ever, under this architecture. (See 3.5 for the per-document metadata nuance, which *is* still possible for free via Firestore.)
- **Consequence for notifications:** there is no server-side component that can wake up and push a notification while the app is fully closed (that would need Cloud Functions). Instead, notifications are fixed using the phone's own OS-level scheduled notifications (see Section 4.4) — genuinely proactive, but computed and scheduled locally rather than triggered from a server.
- **Consequence for distribution:** official app store listings (Apple App Store, Google Play Store) also cost money (Apple Developer Program ~$99/year, Google Play Console $25 one-time) and were explicitly declined — see 3.6.
- If any future task in this plan turns out to secretly require a paid tier of anything, **stop and flag it rather than proceeding** — do not silently enable billing to make something work.

### 3.4 Notifications: proactive, but free

Cloud Functions were explicitly declined (money). Instead, the actual root bug found in the original notification system (see Section 6, Finding N1) is fixed directly: replace immediate `.show()` calls with `zonedSchedule()` from `flutter_local_notifications`, which asks the phone's own OS (AlarmManager on Android, `UNUserNotificationCenter` on iOS) to fire a notification at a specific future time — even if the app is completely closed — with **zero server component and zero cost**. The honest trade-off, which the owner accepted: if data changes remotely (a roommate resolves something on their phone) while this device hasn't reopened the app to resync and reschedule, a locally-scheduled reminder could be briefly stale until the next app open. This is a large improvement over the original behavior (which only fired while a relevant screen happened to be open) at no cost at all.

### 3.5 Document Vault: the final, confirmed design

Per-document choice, confirmed in two parts:
1. **File storage location is not a per-document choice anymore** (it was originally going to be, but the free-tier constraint in 3.3 removed the "cloud" option entirely) — every document's actual file bytes always stay local to the device that added them.
2. **Metadata visibility remains a genuine per-document choice**, and this *is* free (it only touches Firestore, not Cloud Storage): for each document, the person who added it chooses whether its metadata (title, type, expiry date) is visible to the rest of the household — so shared expiry awareness and reminders still work for everyone even though only one device holds the actual file — or whether the document is **fully private**, invisible to everyone else, existing only on the device that added it.

This means the Documents feature needs a per-document visibility field with (at least) two real states: `sharedMetadata` (household can see title/expiry; only this device has the file) and `private` (invisible to the household entirely, local-only in every sense). See Section 4.3 for the exact schema.

### 3.6 Distribution and platforms

- **No official app store submissions** — no Apple Developer Program, no Google Play Console listing, as part of this work. Distribution is direct/sideload install only.
- **Android is the real, day-to-day platform.** Android sideloading is free and permanent (a signed APK, once built, keeps working indefinitely with no reinstall needed).
- **iOS keeps building and running** (for portfolio demos and the owner's own occasional use), with the explicit, accepted understanding that without paying Apple's $99/year Developer Program fee, a free-account install expires and needs reinstalling via Xcode roughly every 7 days. This is fine for occasional/demo use, not for daily household reliance — so iOS is not the priority for polish, edge-case handling, or urgent bug-fix ordering. Android bugs and Android testing take priority whenever a choice must be made.

### 3.7 Household invites

Now that a real backend exists, the invite mechanism becomes genuinely meaningful across devices for the first time. The previously-decorative QR code becomes a **real, scannable QR code** (the app already depends on `mobile_scanner` for grocery barcode scanning, which can be reused for scanning invite QR codes; a QR *generation* package needs to be added — see Section 4.6 and Section 8).

### 3.8 Execution workflow — this shapes how every task in Section 8 must be written

The project owner is **not** using Claude Code. Each work session is a fresh Claude.ai chat conversation (potentially on different accounts), with **no** live git access and **no** memory of any other session. The actual loop is:

1. The owner uploads a fresh zip of the current GitHub repo state, plus the current `plan.md` and `progress.md`, to a new Claude chat.
2. That session reads `.claude/CLAUDE.md`, `progress.md`, and its assigned task from this document, then makes the code changes.
3. The session reports back exactly what changed and the exact commands to run.
4. The owner personally runs `flutter pub get` / `flutter analyze` / `flutter test`, reviews the diff, commits and pushes to GitHub themselves, and updates `progress.md`.
5. The next task starts the same way, with a fresh zip re-upload reflecting the latest committed state.

**Consequence: every task description in Section 8 must be fully self-contained** — exact file paths, exact current behavior being changed, and a clear definition of done — because the session executing it has no other context than this document, `progress.md`, and the code itself. Tasks that depend on a previous task must say so explicitly and must not be attempted out of order.

`.claude/CLAUDE.md` is included in the repo for two reasons: it gives every fresh session (regardless of whether it's this manual chat workflow or, later, actual Claude Code) fast orientation without re-reading this entire document; and if the project owner or anyone else (an interviewer exploring the GitHub repo) ever does open it in real Claude Code, it will be picked up completely automatically, at zero extra effort, since that auto-load behavior is a genuine (if unused by the current workflow) Claude Code feature.

---

## 4. Target architecture, in detail

### 4.1 Firestore schema

Firestore collections are nested under each household, so Security Rules can be written once per household and automatically cover everything inside it. Top level:

```
/users/{userId}
    displayName, email, avatarColorSeed, createdAt, activeHouseholdId

/households/{householdId}
    name, currencyCode, inviteCode, createdAt, createdByUserId

/households/{householdId}/members/{userId}
    role ("admin" | "member" | "observer"), displayName (cached), joinedAt

/households/{householdId}/chores/{choreId}
    title, assigneeUserId, rotationOrder[], frequency, nextDueAt,
    estimatedMinutes, currentStreak, isActive

/households/{householdId}/choreCompletions/{completionId}
    choreId, completedByUserId, completedAt, minutesLogged, photoLocalPath (nullable — see 4.1.1)

/households/{householdId}/expenses/{expenseId}
    description, amountCents, paidByUserId, splitRule (equal | percentage | fixed | exemption + its params),
    allocations[] {userId, amountCents}, expenseDate, isRecurringTemplate, nextDueAt, recurrenceRule

/households/{householdId}/settlements/{settlementId}
    fromUserId, toUserId, amountCents, settledAt

/households/{householdId}/groceryItems/{itemId}
    name, section, isChecked, addedByUserId, createdAt

/households/{householdId}/pantryItems/{itemId}
    name, barcodeUpc (nullable), quantity, expiryDate (nullable), lowStockThreshold

/households/{householdId}/assets/{assetId}
    name, category, purchaseDate, warrantyExpiryDate (nullable)

/households/{householdId}/maintenanceTasks/{taskId}
    title, assetId (nullable), dueDate, recurrence, vendorId (nullable), isActive

/households/{householdId}/vendors/{vendorId}
    name, category, phone, notes, ratings[] {userId, stars, comment, ratedAt}

/households/{householdId}/documents/{documentId}
    title, documentType, expiryDate (nullable), addedByUserId, createdAt,
    visibility ("sharedMetadata" | "adminOnly"), fileLocation ("local"),
    ownerDeviceHint (informational only — the actual file never leaves ownerDeviceHint's device)

/users/{userId}/privateDocuments/{documentId}
    same shape as above, but scoped entirely to this user, never under any household path —
    used when a document's visibility is "private" per Section 3.5
```

**Why nested subcollections instead of flat top-level collections with a `householdId` field:** Firestore Security Rules can check "is this caller a member of this household" once, at the household path level, and that check automatically protects every subcollection underneath it. A flat structure would require repeating (and risking drift in) the same membership check in a separate rule for every single collection. Nesting is the standard, more secure, more maintainable pattern for exactly this kind of app.

**4.1.1 — `photoLocalPath` on chore completions:** the original app let a chore completion attach a photo. Since photo files also can't go to paid Cloud Storage, a chore-completion photo behaves the same way as vault documents: the file stays local to the device that took it, and only a local file path (meaningless on any other device) is recorded. This is a real, accepted limitation of the free-tier constraint — flagged explicitly rather than silently dropped, so a future session doesn't "fix" it by re-introducing Cloud Storage.

### 4.2 Security rules — the approach (not the full rules file itself, which is written as part of Phase 1)

Since there are no Cloud Functions, **Firestore Security Rules are the only enforcement layer** — anything they don't check, a malicious or buggy client could get away with. The core pattern:

```
function isHouseholdMember(householdId) {
  return exists(/databases/$(database)/documents/households/$(householdId)/members/$(request.auth.uid));
}
function isHouseholdAdmin(householdId) {
  return get(/databases/$(database)/documents/households/$(householdId)/members/$(request.auth.uid)).data.role == "admin";
}
```

Every subcollection's rule reads roughly as "allow read/write if `isHouseholdMember(householdId)`," with admin-only operations (deleting the household, changing another member's role) additionally requiring `isHouseholdAdmin(householdId)`. Documents with `visibility == "adminOnly"` additionally require the reader to be an admin for read access — **this is the fix for Finding S3 in Section 6**: unlike the original app (which stored an "Admins Only" flag but never checked it anywhere), Firestore Security Rules make this a real, server-enforced restriction, not a decorative label, because the rule is evaluated by Firestore itself before any data is returned — a client can't bypass it by simply not checking the flag in its own code.

### 4.3 Notification redesign

Replace every `_plugin.show(...)` call in `notification_service.dart` with `_plugin.zonedSchedule(...)`, using the `timezone` package (already a transitive dependency of `flutter_local_notifications`) to compute the correct local fire time. Concretely:

- Each feature's bootstrap logic (chores, documents, grocery/pantry, maintenance) computes, from the current Firestore-synced data, the **set of future dates that should have a reminder** (e.g., a document's critical-threshold date and its warning-threshold date), and calls `zonedSchedule` once per date with a **stable, deterministic notification ID** derived from the item's ID and the specific milestone (so re-running this logic reschedules the *same* notification rather than creating duplicates).
- Before rescheduling, **cancel only the notification IDs belonging to items that actually changed or no longer qualify** — this is the fix for Finding N2 (the original bug where completing one item re-fired notifications for every other unrelated item). Do not call a blanket cancel-all-and-reschedule-everything on every data change.
- Add the Android 13+ runtime permission request (`AndroidFlutterLocalNotificationsPlugin.requestNotificationsPermission()`) on first app launch after sign-in, and add `<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>` to `AndroidManifest.xml` — this is the fix for Finding N1, which without this permission silently fails to show *any* notification on Android 13+.
- Unify all day-count thresholds (currently hardcoded separately per feature: 60/7 for documents, 2/6 for pantry, 60/7 for warranty) to actually call the shared `ExpiryStatus.urgencyForDate()` utility (parameterized per domain, since different thresholds for milk versus a passport are legitimately correct — see Finding N3) so the notification trigger and the UI's colored urgency badge always agree.

### 4.4 Authentication design

- **Firebase Authentication, email + password**, matching the existing UX most directly and avoiding OAuth complexity for a personal project. Firebase Auth itself owns the actual credential hashing and storage server-side; the app never sees or stores the raw password again.
- The existing hand-rolled PBKDF2 utility (`password_hasher.dart`) is **not deleted** — it's repurposed to fix a completely different bug: the Document Vault's PIN is currently hashed with plain, unsalted, single-round SHA-256 (Finding S1), far weaker than the effort already proven correct elsewhere in this same codebase. The vault PIN's hashing is switched to use the existing PBKDF2 utility instead. Since PBKDF2 at 100,000 iterations is comparatively expensive for something now used more frequently (every vault unlock, not just sign-in), wrap the hashing call in Flutter's `compute()` so it runs on a background isolate and doesn't jank the UI thread — this also retroactively fixes a smaller original issue (Finding S1b) where the same PBKDF2 call was never isolated even for login.
- Add a simple attempt counter with escalating lockout (e.g., a short delay after 5 wrong PIN attempts, longer after 10) to the vault PIN check — the original app had no brute-force protection at all (Finding S2).
- **New, optional, low-risk addition:** since `local_auth` (biometric) is already a dependency and the vault already has a working biometric-unlock pattern, extend the same pattern to the main app: after the first real Firebase Auth sign-in, offer a biometric "quick unlock" so the person doesn't have to retype their password every time they reopen the app, while Firebase Auth still owns the actual cross-device identity. This reuses code that already exists and works, rather than introducing anything new — see Section 8, Phase 2 for exact scope.
- **Centralize the auth route guard.** The original app had no `redirect:` logic in `go_router` at all — every screen that needed to enforce "must be signed in" did so with its own imperative `context.go(...)` call, which is exactly how the original password-reset bug (Finding B2) went unnoticed. Firebase Auth exposes an `authStateChanges()` stream; wire this into `go_router`'s `refreshListenable` and a single `redirect:` callback, so the app can no longer accidentally leave a protected screen reachable after sign-out or a session change.

### 4.5 QR code implementation

Add `qr_flutter` (a small, well-established, pure-Dart QR generation package with no cost or account requirement) to render a real QR code encoding the household's invite code (and household ID) as a URI-style payload. The existing `mobile_scanner` dependency (already used for grocery barcodes) is reused to scan it — `mobile_scanner` reads QR codes natively alongside barcodes, no new scanning dependency needed. Scanning resolves to the same "join household" flow that already exists for typed invite codes, now genuinely meaningful across two different phones because both are reading from and writing to the same Firestore household document.

### 4.6 What gets removed entirely

- **Drift and all its generated code, tables, and migration logic** — fully removed once every feature's repository has been migrated to Firestore (Section 8 tracks this feature-by-feature; Drift itself is only deleted once every feature is off it, in the final cleanup phase, so the app keeps compiling throughout).
- The custom `session_provider.dart` (a hand-rolled UUID-token "session" concept) — replaced by Firebase Auth's own built-in session persistence.
- The fake `QrPlaceholder` widget — replaced per 4.5.

---

## 5. Key engineering decisions and rationale

These are decisions made using engineering judgment rather than product preference — each is explained here so anyone (including a future session, or the project owner reviewing this document) understands *why*, not just *what*.

### 5.1 Removing Drift entirely, rather than keeping it as an offline cache alongside Firestore

**Decision:** fully replace Drift/SQLite with Firestore for all shared data, relying on Firestore's own built-in offline persistence (it caches reads locally and queues writes automatically when offline, syncing on reconnect) rather than hand-building a second, custom sync layer on top of Drift.

**Why:** maintaining two databases that must stay reconciled with each other is a genuinely hard, bug-prone distributed-systems problem (conflict resolution, partial-sync states, drift between "what Drift thinks" and "what Firestore thinks"). Firestore's SDK already solves the "works offline, syncs when back online" problem well, for free, without any of that custom complexity. This is simpler, more reliable, and far less code to maintain — the standard, well-trodden path for this kind of app, not a shortcut.

### 5.2 Not upgrading Riverpod (2.x → 3.x) or go_router (14.x → 17.x/18.x) as part of this project

**Decision:** stay on the current major versions of both for the duration of this upgrade. Treat a future move to Riverpod 3 and go_router 17/18 as a separate, optional, later project.

**Why:** the backend migration already touches nearly every file in the app (every repository swaps from Drift to Firestore, every notifier's error handling needs review). Bundling a *second* wide, breaking-change migration (Riverpod's 2→3 API changes) into the same window would make it very difficult to tell whether any bug that surfaces during testing came from the backend change or the state-management change — especially since verification here depends entirely on the project owner manually running `flutter analyze`/`flutter test` themselves, with no AI agent able to compile-check its own work in real time. One large, well-isolated change at a time is the responsible call. Both packages remain fully supported and secure at their current versions; there is no urgency forcing this now.

### 5.3 Not migrating to Flutter's new `material_ui` / `cupertino_ui` packages

**Decision:** keep the classic `package:flutter/material.dart` imports throughout the app for this upgrade.

**Why:** Flutter is in the middle of decoupling Material and Cupertino out of the core SDK into standalone packages, with formal deprecation of the old bundled imports expected in the November 2026 stable release — imminent, but not yet in effect, and even after deprecation the old imports keep working (deprecated is not removed). The new packages only reached version 1.0/1.1 in August 2026, meaning the official migration tooling is a matter of weeks old at the time of this writing. Given the app's hard "no visual changes" constraint and the fact that no AI agent in this workflow can visually verify a change across every screen before the project owner sees it, a wide mechanical migration right now is unnecessary risk for no functional benefit today. Revisit this in 6–12 months once the new packages and their migration tooling have matured further.

### 5.4 Testing strategy after removing Drift

The original test suite used an in-memory Drift database for repository-level tests. Once Drift is gone, those tests need real replacements, not deletion:

- **`fake_cloud_firestore`** (a lightweight, pure-Dart in-memory fake of `FirebaseFirestore`, widely used in the Flutter ecosystem, zero network/emulator required) replaces the in-memory Drift database for fast repository unit tests — this most closely matches the original test style and keeps the test suite fast.
- The **Firebase Local Emulator Suite** (a genuinely free, offline, local developer tool — entirely separate from and unrelated to the paid Blaze plan) is set up for integration-style testing where it matters (e.g., actually exercising Security Rules, which `fake_cloud_firestore` does not enforce). This runs entirely on the project owner's own machine.
- **Pure domain-layer tests** (the split engine, balance engine, fairness score, expiry status, recurrence-date-math tests) need little to no change — they test plain Dart logic that never touched Drift in the first place. This is a direct, practical payoff of the Clean Architecture separation already present in the original codebase.
- The three `app_database_migration_test.dart` files (documents, grocery, maintenance) test Drift schema migrations specifically. Once Drift is removed, these tests are **deleted, not rewritten** — they test something that will no longer exist.

### 5.5 Existing local demo data

**Decision:** the upgrade starts with a clean slate in Firestore. Whatever test/demo data currently exists in the local SQLite database is not migrated.

**Why:** it's the project owner's own test data from building the original demo, not real production data anyone depends on, and there is no reasonable way to "migrate" locally-invented single-device demo data into a genuinely multi-user authenticated system in a way that would carry real value. (If this assumption is wrong, the project owner should say so — it's flagged here specifically so it isn't silently assumed without being visible.)

### 5.6 Android build fix approach

**Decision:** make the release-signing config in `android/app/build.gradle.kts` conditional on `key.properties` actually existing, falling back to the Flutter template's default debug signing when it doesn't — rather than requiring the project owner to generate a release keystore immediately.

**Why:** the current file unconditionally tries to read `key.properties`, which is correctly git-ignored and simply does not exist in a fresh clone, so `flutter run` fails immediately for *any* Android build, even plain debug ones — this was verified directly (the file is absent, has never been committed, and is correctly listed in `.gitignore`). Making the read conditional immediately unblocks all development and debug-signed direct-install builds. Generating a real keystore for longer-term, stable release signing (so a distributed APK can be updated later without every device needing to uninstall/reinstall) is flagged separately in Section 8 as a distinct, human-required, one-time task — it doesn't need to block getting the app running again.

### 5.7 iOS deployment target

**Decision:** bump `IPHONEOS_DEPLOYMENT_TARGET` from 13.0 to 15.0 across the Xcode project and Podfile.

**Why:** the current stable Flutter release (3.47, August 2026) raised its own minimum supported iOS version to 15 — building this project on current Flutter tooling with the old 13.0 target is likely to fail or warn. Since iOS is the secondary platform (Section 3.6) and any real device someone would sideload this onto in 2026 comfortably supports iOS 15+, there is no real-world device-support cost to this change.

---

## 6. Complete bug and issue inventory

Every item below was found and verified during a full manual audit of the original codebase (git history, every feature's domain/data/presentation layers, Android/iOS configuration, and dependency versions cross-checked against the current, real Flutter/Firebase ecosystem as of September 2026). Each is labeled with severity, exact evidence, the fix approach, and who does the work. IDs are referenced from the phase plan in Section 8 so each task can point back here instead of re-explaining the bug.

### Build & tooling

**[T1] Android cannot build at all, for anyone, on a fresh clone — 🔴 Critical**
`android/app/build.gradle.kts` unconditionally opens `key.properties` to load release-signing credentials. That file is correctly git-ignored and has never existed in the repo (confirmed: absent from disk, absent from all git history, correctly listed in `.gitignore`). Every Android build — including plain debug `flutter run` — fails immediately with a file-not-found error. This is almost certainly why the README links to an Appetize.io browser preview instead of inviting people to just clone and run it.
**Fix:** make the `key.properties` read conditional on the file existing, falling back to Flutter's default debug signing otherwise (full rationale in Section 5.6). 🤖 AI Agent. *A separate, one-time task (Phase 12) to generate a real local release keystore for stable, updatable direct-install builds is 🧑 Human Required — it's a local secret only the project owner should generate and hold, never something an AI session creates or sees.*

**[T2] iOS deployment target below current Flutter's minimum — 🟠 High**
`IPHONEOS_DEPLOYMENT_TARGET` is set to 13.0 across the Xcode project and Podfile; current stable Flutter (3.47) requires iOS 15 minimum. **Fix:** bump to 15.0 (Section 5.7). 🤖 AI Agent.

### Security

**[S1] Document Vault PIN uses weak, unsalted, single-round SHA-256 — 🔴 Critical**
`vault_lock_provider.dart` hashes the vault PIN with plain `sha256.convert(utf8.encode(pin))` — no salt, one round. This is trivially brute-forceable offline (a 4-digit PIN has only 10,000 possibilities; unsalted single-round SHA-256 computes all of them in microseconds) if the stored hash were ever extracted. The same codebase already has a correct, properly-salted, 100,000-iteration PBKDF2 implementation used for the main account password (`password_hasher.dart`) — this is an inconsistency, not a technology gap. **Fix:** switch the vault PIN to use the existing PBKDF2 utility (Section 4.4). 🤖 AI Agent.

**[S1b] PBKDF2 hashing runs on the UI thread — 🟡 Medium**
100,000 HMAC-SHA256 iterations in pure Dart, not wrapped in `compute()` — plausible, noticeable UI jank, worse once S1's fix makes this run on every vault unlock rather than just sign-in. **Fix:** wrap in `compute()` to run on a background isolate. 🤖 AI Agent.

**[S2] No brute-force protection on the vault PIN — 🔴 Critical**
`validatePin()` has no attempt counter, no delay, no lockout — unlimited rapid guesses are possible. **Fix:** add an escalating lockout after repeated failures (Section 4.4). 🤖 AI Agent.

**[S3] "Admins Only" document visibility is completely unenforced — 🟠 High**
Every document-fetching method in the data layer (`watchDocumentsInFolder`, `watchAllDocuments`, `searchDocuments`, `getDocumentsWithExpiryBefore`) takes only a `householdId` — none filter by the viewer's role. The `visibility` field is written and displayed but never checked anywhere before returning data. Any household member, regardless of role, can open any document regardless of this setting — verified by reading every query in the data layer. **Fix:** Firestore Security Rules make this a real, server-enforced restriction (Section 4.2) rather than a client-side check that could be skipped. 🤖 AI Agent (rules) — 🧑 Human Required to actually *deploy* the rules via the Firebase console or CLI (an AI session can write the rules file, but cannot click "publish" in the Firebase console on the owner's behalf).

**[S4] The "Document Vault" never actually encrypted files at rest — 🟠 High (architectural, resolved by design)**
The PIN/biometric lock only gated in-app navigation; the underlying files were always ordinary, unencrypted files in normal app storage — verified: no encryption package exists in the original `pubspec.yaml`, and `save_document_usecase.dart` does a plain `sourceFile.copy(destinationPath)`. This is addressed by the confirmed design in Section 3.5/4.1: files never leave the device at all now, and real device-level protections (app sandboxing, device lock) are the actual security boundary — this is now honestly represented rather than implied to be something it isn't. No separate fix task beyond the document-metadata migration itself.

### Notifications

**[N1] Notifications silently never fire on Android 13+ — 🔴 Critical**
The `POST_NOTIFICATIONS` runtime permission (required since Android 13, released 2022, and the overwhelming majority of active Android phones by 2026) is declared nowhere in `AndroidManifest.xml` and requested nowhere in the code — confirmed by direct manifest inspection and a full-codebase search for any permission-request call. Every notification feature is fully coded but inert on modern Android. **Fix:** Section 4.3. 🤖 AI Agent.

**[N2] Completing one item re-fires notifications for every other unrelated item — 🟠 High**
Every feature's data-mutation flow invalidates a single "bootstrap" Riverpod provider that re-scans and re-`.show()`s *every* currently-qualifying notification in that feature, not just the one that changed — confirmed by tracing every `ref.invalidate(...BootstrapProvider)` call site back to its trigger (completing a chore, checking a grocery item, editing a document, completing a maintenance task all trigger this). **Fix:** Section 4.3 — cancel/reschedule only what actually changed. 🤖 AI Agent.

**[N3] Notification thresholds don't match the UI's own urgency badges — 🟡 Medium**
Each feature hardcodes its own day-count thresholds for when to alert (e.g., documents at 60/7 days), independently of the shared `ExpiryStatus` utility that drives the UI's colored urgency badges (which defaults to 14/60) — so a document can show "critical" (red) in the UI for several days before any notification fires. **Fix:** Section 4.3 — route both through the same parameterized utility. 🤖 AI Agent.

**[N4] "Scheduled" notifications were never actually scheduled — 🟠 High**
Despite the method names (`scheduleDocumentExpiryAlerts`, etc.), every call site uses `.show()` (immediate display), never `zonedSchedule()` — confirmed by a full-codebase search finding zero uses of `zonedSchedule` or the `timezone` package. Alerts only ever appeared at the moment a relevant screen happened to load. **Fix:** Section 4.3, this is the core notification redesign. 🤖 AI Agent.

### Data-correctness bugs

**[B1] Recurring monthly dates drift permanently — three independent, buggy implementations — 🔴 Critical**
Finance (`local_finance_repository.dart`) and Chores (`complete_chore_usecase.dart`) each hand-roll an identical `_addMonths` helper that clamps the day-of-month correctly *per step*, but chains off the **previous generated date** rather than the original anchor date. Verified empirically (reproduced the exact chaining logic outside Dart to confirm): a bill or chore anchored on the 31st becomes due on the 28th the first time it crosses February — and stays on the 28th forever afterward, even in 31-day months, because each subsequent computation starts from the already-shrunk value. Maintenance (`complete_task_usecase.dart`) has a *third*, different, and actually worse implementation: it uses the raw `DateTime(year, month, day)` constructor with no clamping at all, so a day that doesn't exist in the target month silently **overflows into a completely different month** (e.g., a task anchored Jan 31 computes its "monthly" next date as March 3, skipping February's due date entirely). **Fix:** one new, correct, shared utility (e.g. `lib/core/utils/recurrence.dart`) that always computes forward from the *original* anchor day, used by all three features; delete all three existing implementations. 🤖 AI Agent.

**[B2] Password reset fails silently — 🟠 High**
`reset_password_screen.dart` calls `resetPassword()` and then unconditionally navigates to sign-in, regardless of success or failure — unlike `sign_in_screen.dart` and `sign_up_screen.dart`, which correctly use a `ref.listenManual` pattern to show error/success messages via SnackBar. `forgot_password_screen.dart` has the same gap (no listener at all, so a failed "no account with that email" error is never shown). Confirmed by comparing all four auth screens directly — two have the listener pattern, two don't. Net effect: a failed password reset silently behaves like a success from the user's point of view. **Fix:** as part of the Firebase Auth migration (Section 4.4), rebuild these screens with the same message-listening pattern already used correctly elsewhere, and make navigation conditional on actual success. 🤖 AI Agent.

**[B3] Calendar hardcodes USD regardless of the household's real currency — 🟡 Medium**
`calendar_repository_impl.dart` calls `AppFormatters.currencyFromCents(..., currencyCode: 'USD')` — a literal hardcoded string — while every other Finance screen correctly threads the household's actual `currencyCode` through (confirmed by comparing against `finance_module.dart`, `expense_detail_screen.dart`, and `balance_settlement_sheet.dart`, which all do this correctly). **Fix:** pass the real household currency code through in the Firestore-backed rewrite of the calendar aggregator. 🤖 AI Agent.

**[B4] Missing `mounted` checks after image-picker awaits — three occurrences — 🟡 Medium**
`complete_chore_sheet.dart`, `complete_task_sheet.dart`, and `add_edit_asset_sheet.dart` each call `setState()` immediately after `await _imagePicker.pickImage(...)` with no `mounted` guard — will throw if the sheet is dismissed while the OS photo picker is open. Two sibling files (`add_document_sheet.dart`, `camera_scan_screen.dart`) handle this correctly, confirming it's an inconsistency rather than a deliberate pattern. **Fix:** add the missing `if (!mounted) return;` guard in all three. 🤖 AI Agent.

**[B5] Household QR invite was entirely decorative — 🟡 Medium (now being fixed as a feature, see 3.7/4.5)**
`QrPlaceholder` renders a hardcoded grid pattern with no relationship to any real household or invite code whatsoever — confirmed by reading the widget's source, which contains a fixed set of "filled" cell indices unrelated to any data. Addressed by Section 4.5.

**[B6] Duplicate expiry-urgency logic — 🟢 Low (code quality)**
`PantryItemEntity` (grocery) reimplements the same midnight-normalized date-difference algorithm as the shared `ExpiryStatus` utility, with its own parallel `PantryExpiryUrgency` enum, instead of calling `ExpiryStatus.urgencyForDate()` with pantry-appropriate thresholds (which the utility already supports as parameters). The different threshold *values* are correct and intentional (milk needs a much shorter horizon than a passport) — it's the duplicated *implementation* that's the issue. **Fix:** consolidate onto the one shared utility, parameterized per domain. 🤖 AI Agent.

**[B7] Dead code: unused legacy recurrence-string format — 🟢 Low**
`complete_task_usecase.dart` parses a `custom:(\d+)` pattern that the UI (`add_edit_task_sheet.dart`) never actually produces (it only ever writes `every_N_days`) — harmless leftover from an earlier naming convention. **Fix:** remove the dead branch. 🤖 AI Agent.

**[B8] A few screens may not wire `isLoading` into `HearthButton` consistently — 🟢 Low (verify, don't assume)**
The shared `HearthButton` component itself is correctly built (disables its own tap handler when `isLoading` is true — verified by reading its source). A codebase-wide heuristic scan flagged `chore_detail_screen.dart`, `settings_screen.dart`, and `asset_detail_screen.dart` as possibly not wiring a loading state into their primary action buttons, though this needs a direct check per screen rather than being asserted as confirmed. **Fix:** spot-check these three during their respective feature's migration phase and wire `isLoading` if missing. 🤖 AI Agent.

### Architecture & robustness

**[A1] No centralized authentication route guard — 🟠 High**
The original `go_router` configuration has no `redirect:` logic at all — every screen that needed to enforce "must be signed in" did so with its own imperative `context.go(...)` call scattered across the codebase, confirmed by reading `app_router.dart` (no redirect callback present) and tracing how sign-out and splash-screen gating are each handled independently, ad hoc, per call site. This fragility is exactly how **B2** (the password-reset screen's missing error check) went unnoticed — there was no structural safety net catching an inconsistent screen. **Fix:** Section 4.4 — wire Firebase Auth's `authStateChanges()` into `go_router`'s `refreshListenable` with one `redirect:` callback covering every protected route. 🤖 AI Agent.

### Polish

**[P1] Stale in-app and README copy — 🟢 Low**
The Settings screen and README still describe the app as delivering only "Phase 1" (auth, design system, household setup) despite six phases now being built. The README also contains a broken sentence pointing to an absolute path on the original developer's own machine (`/Users/mizu/Downloads/...`), meaningless to anyone else. **Fix:** update both. 🤖 AI Agent.

**[P2] Open Food Facts API calls have no User-Agent header — 🟢 Low**
Open Food Facts' own guidelines recommend a descriptive User-Agent identifying the calling app, to avoid being rate-limited. **Fix:** add one. 🤖 AI Agent.

**[P3] No `errorBuilder` for unmatched routes — 🟢 Low**
An unmatched deep link or route currently falls through to go_router's default, unstyled error screen. **Fix:** add a themed not-found screen. 🤖 AI Agent.

**[P4] Quick-add document shortcut bypasses the vault lock for adding (not viewing) — 🟢 Low, likely acceptable**
A "quick add document" shortcut reachable from the home shell's persistent navigation isn't wrapped in the vault lock overlay the way `folder_screen.dart`, `document_detail_screen.dart`, `vault_dashboard_screen.dart`, and `expiry_timeline_screen.dart` all are — so a new document can be *added* without unlocking the vault first, though *viewing* any document (including the newly added one) still correctly requires unlocking. Flagged for awareness rather than as a required fix, since this may be intentional (similar to how some note-taking apps allow creating locked content without unlocking first) — confirm intent before changing.

---

## 7. Session protocol for any AI agent picking up work here

This restates and slightly expands `.claude/CLAUDE.md` for completeness, since this document must stand alone.

1. **Read this entire document once** if this is your first time seeing it in this session. If you were only given a specific phase to work on, still skim Sections 1–7 for context before jumping to Section 8 — the bug IDs and architectural decisions referenced there assume you've read the earlier sections.
2. **Read `progress.md`** to see the true current state — which phases/tasks are done, in progress, or blocked. `progress.md` overrides any assumption you might otherwise make from this document about what's "already done," since this document describes the plan, not a live status.
3. **Do only the task(s) you were explicitly asked to do.** If you notice an unrelated bug while working, do not fix it inline — note it clearly in your handback so it can become its own tracked task (this keeps each change small and independently reviewable, per the project owner's explicit request for small, reviewable stages).
4. **Never touch visual styling** (colors, spacing, typography, layout) while doing a backend or bug-fix task, even incidentally. If a fix seems to require a visual change, stop and flag it instead of proceeding.
5. **Never introduce anything that requires payment, a credit card, or a billing account** — re-read Section 3.3 if a task seems to be heading that direction, and flag it instead of proceeding.
6. **Report back explicitly**, every time: what changed (files and a short summary), exactly which commands the project owner should run to verify it, and anything that deviated from this plan or needs a decision.
7. **Update `progress.md` yourself** before ending your turn — mark the task's status, note the date, and leave verification as "pending" (only the project owner can mark something verified, since only they can actually run the app/tests).

---

## 8. Phased build plan

Phases are ordered to respect real dependencies (you cannot migrate a feature's repository to Firestore before Firestore itself is configured; you cannot delete Drift before every feature has stopped using it). Within a phase, tasks are listed in a sensible order but most are independently reviewable. Every task assumes the standard verification loop from Section 0 unless otherwise noted.

### Phase 0 — Environment & Foundation Setup

**0.1 — Fix the Android build-breaking bug [T1]** 🤖 AI Agent
Make `android/app/build.gradle.kts`'s `key.properties` loading conditional on the file's existence; fall back to Flutter's default debug signing config when absent (Section 5.6).

**0.2 — Bump iOS deployment target [T2]** 🤖 AI Agent
Update `IPHONEOS_DEPLOYMENT_TARGET` to 15.0 in `ios/Podfile` and all three build configurations in `ios/Runner.xcodeproj/project.pbxproj` (Section 5.7).

**0.3 — Create the Firebase project** 🧑 Human Required
Go to the Firebase console (console.firebase.google.com), create a new project (e.g. "hearth-app"), and enable: Authentication (Email/Password sign-in method), Cloud Firestore (start in production mode, not test mode — the real rules from Phase 1 will govern access), and nothing else (specifically do **not** enable Cloud Storage or upgrade to Blaze — Section 3.3). A future AI session can write out the exact click-by-click steps as a companion checklist if useful, but the account creation and console clicks themselves cannot be done by an AI agent.

**0.4 — Install the FlutterFire CLI and connect the app** 🧑 Human Required (with 🤖-generated files)
Install the Firebase CLI and FlutterFire CLI locally, sign in, and run `flutterfire configure` against the project from 0.3 — this generates `lib/firebase_options.dart` and registers the Android/iOS app IDs. An AI session can prepare the `pubspec.yaml` additions (`firebase_core`, `firebase_auth`, `cloud_firestore`) ahead of this so `flutterfire configure` has less to do, but the CLI login and the generated `firebase_options.dart` depend on the human's real Firebase account and cannot be produced by an AI session in the abstract.

**0.5 — Set up local Firestore testing infrastructure** 🤖 AI Agent
Add `fake_cloud_firestore` as a dev dependency; add the Firebase Local Emulator Suite configuration (`firebase.json`, emulator ports) so `flutter test` can run against a fake/local Firestore rather than a real project (Section 5.4). Document the exact emulator-start command in this repo's own README.

**0.6 — Land the planning documents** 🤖 AI Agent (this task is being completed right now)
Commit `.claude/CLAUDE.md`, `.claude/settings.json`, `plan.md`, and `progress.md` to the repo root / `.claude/` folder as applicable.

### Phase 1 — Firestore Schema & Security Rules

**1.1 — Write `firestore.rules`** 🤖 AI Agent
Implement the full rules described in Section 4.2, covering every collection in Section 4.1, including the admin-only document-visibility enforcement (fixes **S3**).

**1.2 — Write Firestore composite indexes config (`firestore.indexes.json`)** 🤖 AI Agent
Any compound queries (e.g., documents filtered by household + sorted by expiry date) need explicit indexes declared ahead of time — write this file so `firebase deploy --only firestore:indexes` works cleanly the first time.

**1.3 — Deploy rules and indexes to the real project** 🧑 Human Required
Run `firebase deploy --only firestore:rules,firestore:indexes` (or paste the rules into the console's Rules tab) against the project from 0.3.

**1.4 — Establish the repository test pattern** 🤖 AI Agent
Write one complete example (e.g., the household repository) showing the `fake_cloud_firestore` test pattern other features' migrations will follow, so later phases can copy a proven pattern rather than inventing their own each time.

### Phase 2 — Authentication Migration

**2.1 — Replace local auth with Firebase Authentication** 🤖 AI Agent
Rewrite `local_auth_repository.dart` (or its replacement) to call Firebase Auth's `createUserWithEmailAndPassword` / `signInWithEmailAndPassword` / `sendPasswordResetEmail`-equivalent flow instead of the local PBKDF2 + Drift `users` table. Note: Firebase's own password reset flow sends a real email, which is a meaningful UX improvement over the original's "no verification at all" reset — but confirm this fits before assuming it (the original design deliberately skipped email verification since it had no way to send one; Firebase makes real email verification possible for the first time).

**2.2 — Rebuild the four auth screens with correct, consistent error handling [B2]** 🤖 AI Agent
Sign-in, sign-up, forgot-password, and reset-password all use the same `ref.listenManual` message-listening pattern already correct in the original sign-in/sign-up screens; forgot-password and reset-password gain it for the first time, and reset-password's navigation becomes conditional on actual success (fixes **B2**).

**2.3 — Centralize the auth route guard [A1]** 🤖 AI Agent
Wire Firebase Auth's `authStateChanges()` into `go_router`'s `refreshListenable` and a single `redirect:` callback covering every protected route, replacing the original's scattered imperative navigation checks.

**2.4 — Remove `session_provider.dart`** 🤖 AI Agent
No longer needed once Firebase Auth owns session persistence.

**2.5 — Add biometric quick-unlock (new feature)** 🤖 AI Agent
After a real Firebase sign-in, offer to enable biometric quick-unlock for subsequent app opens, reusing the existing vault biometric pattern (Section 4.4).

**2.6 — Fix vault PIN hashing and add lockout [S1, S1b, S2]** 🤖 AI Agent
Switch the vault PIN hash to the existing PBKDF2 utility wrapped in `compute()`, and add an escalating attempt lockout (Section 4.4).

**2.7 — Update auth tests** 🤖 AI Agent
Rewrite repository-level auth tests against a fake Firebase Auth (e.g. `firebase_auth_mocks`); update/expand the four screens' widget tests to cover the newly-consistent error-handling paths.

### Phase 3 — Household Migration

**3.1 — Rewrite the household repository for Firestore** 🤖 AI Agent
Replace `local_household_repository.dart`'s Drift-backed implementation with one reading/writing `/households/{id}` and `/households/{id}/members/{userId}` (Section 4.1). Creating a household writes the household doc plus a `members` doc for the creator with role `admin`.

**3.2 — Real invite codes and a real, scannable QR code [B5]** 🤖 AI Agent
Generate a genuinely unique invite code stored on the household doc; add `qr_flutter` to render it as a real QR code; wire `mobile_scanner` (already a dependency) to scan and resolve it to the join flow (Section 4.5). Joining now writes a `members` subcollection doc under the *scanned* household — the actual fix that makes cross-device joining real for the first time.

**3.3 — Update household tests** 🤖 AI Agent
Rewrite `local_household_repository_test.dart` against `fake_cloud_firestore`, following the pattern from 1.4. Add a test specifically proving two different simulated users can join the same household doc (the thing that was structurally impossible before).

### Phase 4 — Chores Migration

**4.1 — Rewrite the chore repository for Firestore** 🤖 AI Agent
Replace `local_chore_repository.dart` with one reading/writing `/households/{id}/chores/{choreId}` and `/households/{id}/choreCompletions/{completionId}` (Section 4.1). Domain-layer logic (`calculate_fairness_score_usecase.dart`, `complete_chore_usecase.dart`'s completion/streak logic) should need little to no change — only the repository's data source changes (Section 2.2/5.1).

**4.2 — Build the shared recurrence utility [B1, part 1 of 3]** 🤖 AI Agent
Create `lib/core/utils/recurrence.dart` with a correctly anchor-preserving "add N months" function (Section 6, Finding B1) and a test file proving the specific regression case (a date anchored on the 31st, advanced repeatedly across a February, must eventually return to the 31st in a 31-day month rather than staying stuck at 28). Update chores' monthly-frequency logic to use it, deleting the old `_addMonths` from `complete_chore_usecase.dart`.

**4.3 — Fix the missing `mounted` guard [B4, part 1 of 3]** 🤖 AI Agent
Add `if (!mounted) return;` after the image-picker await in `complete_chore_sheet.dart`, matching the correct pattern already used in `add_document_sheet.dart`.

**4.4 — Update chores tests** 🤖 AI Agent
Rewrite repository tests against `fake_cloud_firestore`; the existing `rotation_engine_test.dart` and `fairness_score_test.dart` (pure domain-logic tests) should need little to no change (Section 5.4).

### Phase 5 — Finance Migration

**5.1 — Rewrite the finance repository for Firestore** 🤖 AI Agent
Replace `local_finance_repository.dart` with one reading/writing `/households/{id}/expenses/{expenseId}` and `/households/{id}/settlements/{settlementId}` (Section 4.1). `split_engine.dart` and `balance_engine.dart` (pure domain logic) need no changes (Section 5.1).

**5.2 — Apply the shared recurrence utility to recurring bills [B1, part 2 of 3]** 🤖 AI Agent
Replace `reconcileRecurringBillsOnLaunch`'s local `_addMonths` with the utility from 4.2; keep the existing `while (!nextDue.isAfter(now))` catch-up loop (this part was already well-designed), just feed it the corrected date function.

**5.3 — Update finance tests** 🤖 AI Agent
Rewrite repository tests against `fake_cloud_firestore`; existing `split_engine_test.dart`/balance-engine tests need little to no change.

### Phase 6 — Grocery Migration

**6.1 — Rewrite the grocery repository for Firestore** 🤖 AI Agent
Replace `local_grocery_repository.dart` with one reading/writing `/households/{id}/groceryItems/{itemId}` and `/households/{id}/pantryItems/{itemId}` (Section 4.1).

**6.2 — Consolidate expiry-urgency logic [B6]** 🤖 AI Agent
Remove `PantryExpiryUrgency` and `PantryItemEntity`'s hand-rolled date math; call the shared `ExpiryStatus.urgencyForDate()` utility with pantry-appropriate thresholds instead (Section 6, Finding B6).

**6.3 — Add a User-Agent header to Open Food Facts calls [P2]** 🤖 AI Agent
A small addition to `open_food_facts_service.dart`'s HTTP calls.

**6.4 — Update grocery tests** 🤖 AI Agent
Rewrite repository tests against `fake_cloud_firestore`; delete `app_database_migration_test.dart` for grocery (tests Drift-specific migration behavior that no longer applies — Section 5.4).

### Phase 7 — Maintenance Migration

**7.1 — Rewrite the maintenance repository for Firestore** 🤖 AI Agent
Replace the asset/task/vendor repositories with ones reading/writing `/households/{id}/assets/{assetId}`, `/households/{id}/maintenanceTasks/{taskId}`, and `/households/{id}/vendors/{vendorId}` (Section 4.1).

**7.2 — Apply the shared recurrence utility, fixing the worse overflow bug [B1, part 3 of 3]** 🤖 AI Agent
Replace `complete_task_usecase.dart`'s raw, unclamped `DateTime(year, month + n, day)` recurrence math with the shared utility from 4.2 — this is the more severe of the two recurrence bugs (it overflows into a different month entirely, not just drifts within the right one).

**7.3 — Fix the two remaining missing `mounted` guards [B4, parts 2–3 of 3]** 🤖 AI Agent
Add the guard to `complete_task_sheet.dart` and `add_edit_asset_sheet.dart`.

**7.4 — Remove the dead recurrence-string parsing branch [B7]** 🤖 AI Agent
Delete the unused `custom:(\d+)` regex branch from the maintenance task's recurrence parsing.

**7.5 — Update maintenance tests** 🤖 AI Agent
Rewrite repository tests against `fake_cloud_firestore`; delete `app_database_migration_test.dart` for maintenance.

### Phase 8 — Documents / Vault Migration

**8.1 — Rewrite the document repository: metadata to Firestore, files stay local** 🤖 AI Agent
Household-visible metadata goes to `/households/{id}/documents/{documentId}`; private documents go to `/users/{userId}/privateDocuments/{documentId}` (Section 4.1). The actual file continues to be written to local device storage exactly as before (`sourceFile.copy(destinationPath)` stays, since local storage was never the bug — only the "vault" framing implying more than that was, see Finding S4).

**8.2 — Build the per-document visibility choice UI** 🤖 AI Agent
When adding or editing a document, let the person choose "visible to household" vs. "private," per Section 3.5. Update `add_document_sheet.dart` and `document_detail_screen.dart` accordingly.

**8.3 — Confirm "Admins Only" is now actually enforced [S3]** 🤖 AI Agent
This is largely already fixed by Phase 1's security rules; this task is to update the client code's document-fetching calls to match the new rule-protected paths and confirm (via a `fake_cloud_firestore` test simulating a non-admin read attempt) that access is genuinely denied, not just hidden by the UI.

**8.4 — Update documents tests** 🤖 AI Agent
Rewrite repository tests against `fake_cloud_firestore`, including a test proving a non-admin cannot read an admin-only document (via the Firebase Local Emulator Suite, since `fake_cloud_firestore` does not itself enforce security rules — Section 5.4). Delete `app_database_migration_test.dart` for documents.

### Phase 9 — Notifications Overhaul

**9.1 — Add the Android 13+ notification permission [N1]** 🤖 AI Agent
Add `<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>` to `AndroidManifest.xml` and call the runtime permission request on first launch after sign-in.

**9.2 — Replace immediate `.show()` with real scheduled `zonedSchedule()` calls [N4]** 🤖 AI Agent
Rework `notification_service.dart` so every alert is scheduled ahead of time for its actual target date/time using the `timezone` package, with deterministic per-milestone notification IDs (Section 4.3). This is the core notification redesign and the largest single task in this phase.

**9.3 — Fix the notification re-spam bug with targeted cancel/reschedule [N2]** 🤖 AI Agent
Change each feature's bootstrap-invalidation flow to cancel and reschedule only the specific notification IDs belonging to items that actually changed, not everything currently qualifying.

**9.4 — Unify alert thresholds with the shared `ExpiryStatus` utility [N3]** 🤖 AI Agent
Replace every feature's hardcoded day-count thresholds with calls to the shared, parameterized utility (also touches 6.2's grocery consolidation — coordinate if these land in different sessions, since both change the same utility's call sites).

**9.5 — Update notification-related tests** 🤖 AI Agent
Add tests proving a notification is actually scheduled for the correct future date/time (not just that a `.show()` call happened), and that completing one item does not cancel/reschedule unrelated notification IDs.

### Phase 10 — Calendar Migration

**10.1 — Rewrite calendar aggregation for Firestore** 🤖 AI Agent
Replace `calendar_repository_impl.dart`'s Drift-table watchers with Firestore listeners across the relevant collections (expenses, chores, documents, maintenance tasks — Section 4.1). Preserve the existing deep-link route strings exactly (these were verified correct against the actual registered routes during the original audit — don't "fix" something that already works).

**10.2 — Fix the hardcoded USD currency [B3]** 🤖 AI Agent
Pass the household's real `currencyCode` through instead of the literal `'USD'`.

**10.3 — Update calendar tests** 🤖 AI Agent
Rewrite `calendar_repository_impl_test.dart` against `fake_cloud_firestore`.

### Phase 11 — Cross-Cutting Cleanup

**11.1 — Remove Drift entirely** 🤖 AI Agent
Only once Phases 3–10 are all confirmed complete in `progress.md`: delete the Drift dependency from `pubspec.yaml`, delete `app_database.dart` and all table definition files, delete all remaining `.g.dart`/generated Drift artifacts references. This is deliberately last so the app keeps compiling and remains testable throughout every prior phase.

**11.2 — Fix stale README and in-app copy [P1]** 🤖 AI Agent
Update the Settings screen's "Phase 1" description and the README to reflect the full, current feature set; remove the broken absolute local-machine path.

**11.3 — Add a themed `errorBuilder` for unmatched routes [P3]** 🤖 AI Agent

**11.4 — Resolve the quick-add-document vault bypass [P4]** 🤖 AI Agent, pending a one-line confirmation from the project owner on intent (mentioned here so it isn't silently decided either way)

**11.5 — Spot-check and fix `HearthButton` `isLoading` wiring [B8]** 🤖 AI Agent
Check `chore_detail_screen.dart`, `settings_screen.dart`, and `asset_detail_screen.dart` specifically; wire `isLoading` from the relevant notifier's state wherever it's missing on a primary async action button.

**11.6 — Full regression test pass** 🤝 Mixed
AI agent ensures the full test suite is coherent (no leftover references to deleted Drift code, no skipped tests). Project owner runs `flutter analyze` and `flutter test` clean, end to end, on the fully migrated app.

### Phase 12 — Distribution Readiness

**12.1 — Generate a real local release keystore** 🧑 Human Required
For stable, updatable direct-install Android builds (so the app can be updated later without every device uninstalling/reinstalling), generate a real keystore locally (`keytool -genkey ...`) and create the local, git-ignored `key.properties` file pointing to it. This is a secret — it must never be committed or handled by an AI session.

**12.2 — Build and verify a signed release APK on a real Android device** 🧑 Human Required
Run `flutter build apk --release`, install it directly on real Android phone(s), and confirm the full app works end-to-end with the real Firebase backend, including with a second real device to confirm genuine multi-device sync (the actual point of this entire upgrade).

**12.3 — Verify the iOS build** 🧑 Human Required
Needs a Mac with Xcode. Build and run on a real iPhone or simulator; confirm no regressions, accepting the known 7-day free-account reinstall limitation (Section 3.6).

**12.4 — Final full regression pass across both platforms** 🧑 Human Required
A manual walkthrough of every feature on both platforms before considering the upgrade complete.

---

*End of plan.md. See `progress.md` for live status of every item above.*
