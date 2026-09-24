# Hearth — Claude Project Memory

> **If you are a fresh Claude session (chat or Claude Code) starting work on this repo, read this file first, then immediately read `progress.md` (what's done / what's next) and the relevant section of `plan.md` (the full spec for your assigned task) before writing any code.** Do not skip this — this file is the only memory that survives between sessions.

## What Hearth is

Hearth is a Flutter mobile app (Android-first, iOS-secondary) for household coordination: chores with fair rotation, shared expenses, a shared calendar, a grocery/pantry tracker, a document vault, and home maintenance tracking. It was originally built as a portfolio/job-hunting demo (100% local, offline-only, single-device). It is being upgraded into a real Firebase-backed app that real households can use across multiple phones, while also remaining a strong portfolio piece — see `plan.md` for the full vision, every decision made, and the phased build plan.

## Tech stack

- **Flutter / Dart**, Riverpod for state management, `go_router` for navigation.
- **Target backend: Firebase** — Cloud Firestore (data), Firebase Authentication (login), staying entirely on the free **Spark** plan. No Cloud Functions, no Firebase Cloud Storage, no paid tier of anything, ever — see the hard constraints below.
- Drift/SQLite (the original local-only database) is being **removed entirely** as part of this upgrade, replaced by Firestore. The one exception: raw bytes of documents a user marks "local-only" in the Document Vault stay on local device storage (no database needed for that, just the filesystem).
- Feature-based Clean Architecture: each feature under `lib/features/<name>/` has its own `domain/` (entities, use cases, pure business logic), `data/` (repositories talking to Firestore or local storage), and `presentation/` (Riverpod notifiers + widgets) layers. **Preserve this structure.** The domain layer should stay almost entirely untouched by the backend migration — it doesn't know or care where data comes from, by design.

## Non-negotiable constraints — read this twice

1. **No visual changes.** Colors, layout, spacing, typography, and overall look and feel must stay exactly as they are. Bug fixes and backend changes must be invisible to the eye. Do not "improve" the UI while touching a file for an unrelated reason.
2. **Zero ongoing cost, ever.** No feature may require a credit card, a paid plan, or a billing account of any kind. If something can only be done by upgrading Firebase to Blaze (Cloud Functions, Cloud Storage), it is out of scope — build the free-tier alternative documented in `plan.md` instead, or flag it and stop.
3. **Android is the real, primary platform.** iOS must keep building and running correctly, but is understood to have the free-tier 7-day reinstall limitation and is not the priority for polish or edge-case handling.
4. **No official app store submissions** (no Apple Developer Program, no Google Play Console listing) as part of this work. Distribution is direct/sideload only.
5. **Every fix must actually fix the underlying bug**, not paper over the symptom. If you find a fix in `plan.md` that turns out to be wrong once you're in the code, say so in your handback notes rather than forcing it.

## Standard workflow for every task

You are working from a **zip upload**, not a live git connection — you have no access to git history beyond what's in the zip, and no memory of any other session. Because of this:

1. Read this file, `progress.md`, and your assigned task's full entry in `plan.md`.
2. Do the work for exactly one task (or the specific subtasks requested) — don't jump ahead to unrelated tasks even if you notice them.
3. Report back clearly: what changed, which files, and the **exact commands** the person should run to verify it (e.g. `flutter analyze`, `flutter test test/features/chores/`, `flutter pub get`).
4. Update `progress.md` yourself for the task(s) you completed — mark status, add a one-line note if anything deviated from the plan, and leave a "verified: pending" marker since the person still has to actually run the commands.
5. Do not touch files outside your assigned task's stated scope.

## Key commands (for the person running them locally)

```bash
flutter pub get                    # after any pubspec.yaml change
flutter analyze                    # static analysis — should be clean
flutter test                       # full test suite
flutter test test/features/<name>/ # one feature's tests
flutter run -d <device-id>         # run on a connected device/emulator
```

## Code conventions already established in this codebase (follow them)

- Screens expose a `static const String routePath` where practical; nested routes are registered as relative path segments in each feature's `lib/features/<name>/presentation/routes.dart`.
- Riverpod notifiers live in `<feature>_notifier.dart`; state classes are immutable with `copyWith`.
- Shared, reusable UI lives in `lib/core/widgets/` (e.g. `HearthButton`, which already correctly disables itself via `isLoading` — reuse this pattern, don't rebuild it).
- Shared utilities live in `lib/core/utils/` (e.g. `expiry_status.dart`) — if you find yourself duplicating date/urgency logic, it probably belongs here instead.
- Money is always handled in **integer cents**, never floating point. Keep this everywhere it currently applies (finance) and anywhere new money handling is added.
- Tests mirror the `lib/` structure under `test/`.

## Full detail lives in `plan.md`

This file is intentionally short. Every architectural decision, every bug found in the original audit, the full Firestore schema, and the complete phase-by-phase build plan are in `plan.md`. `progress.md` tracks what's actually been done. Treat those two as the source of truth; treat this file as the map to them.
