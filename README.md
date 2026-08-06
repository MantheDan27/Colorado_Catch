# Colorado Catch

A cross-platform (Android + iOS) Flutter app for finding and tracking fishing spots
around Colorado, built on Firebase.

## MVP features

- **Auth** — email/password and Google Sign-In (`lib/services/auth_service.dart`)
- **User profiles** — Firestore-backed profile doc per user (`lib/screens/profile_screen.dart`)
- **Firestore database** — profiles, chat messages, and map pins (`lib/services/firestore_service.dart`)
- **Image upload** — profile photo upload to Firebase Storage (`lib/services/storage_service.dart`)
- **Push notifications** — FCM token registration + foreground/background handlers (`lib/services/push_service.dart`)
- **Chat** — a global chat room backed by a Firestore-streamed message list (`lib/screens/chat_screen.dart`)
- **Maps** — Google Map showing catch-spot pins pulled from Firestore (`lib/screens/map_screen.dart`)
- **Analytics** — Firebase Analytics events for login/sign-up (`lib/services/analytics_service.dart`)

## Project structure

```
lib/
  main.dart              # Firebase init, FCM background handler, runApp
  app.dart                # MaterialApp, DI (Provider), auth-gated routing
  firebase_options.dart   # Placeholder — regenerate with `flutterfire configure`
  models/                 # Plain data classes (UserProfile)
  services/                # Firebase-facing services (auth, firestore, storage, push, analytics)
  screens/                 # Login, Home (tab shell), Profile, Map, Chat
  widgets/                 # Shared small widgets
```

## Before you can run it

This repo has the Flutter scaffolding (`android/`, `ios/`) and app code, but it points
at placeholder Firebase/Maps credentials. **See [SETUP.md](SETUP.md)** for the one-time
steps to wire it up to a real Firebase project — you need to do that before `flutter run`
will work end to end.

## Quick start (after SETUP.md)

```bash
flutter pub get
flutter analyze
flutter test
flutter run            # pick an Android emulator or iOS simulator
```
