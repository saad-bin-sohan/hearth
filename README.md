# Hearth

Hearth is a Flutter mobile app for shared household coordination. Phase 1 delivers the foundation: the design system, local authentication, household creation and invites, the authenticated shell, and light/dark theme support.

## Setup

1. `flutter pub get`
2. `dart run build_runner build --delete-conflicting-outputs`
3. `flutter analyze`
4. `flutter test`

## Run

- iOS Simulator: `flutter emulators --launch apple_ios_simulator`
- Android Emulator: `flutter emulators --launch Medium_Phone_API_36.1`
- Run the app: `flutter run -d <device-id>`

## Project Notes

- State management uses Riverpod.
- Local data uses Drift SQLite.
- Theme preferences and session state use `shared_preferences`.
- Invite sharing uses `share_plus`.
- Assets are declared manually in [lib/generated/assets.gen.dart](/Users/mizu/Downloads/Ed_Career/git/hearth/lib/generated/assets.gen.dart).
