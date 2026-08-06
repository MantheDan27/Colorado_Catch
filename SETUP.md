# Setup

This scaffold compiles and passes `flutter analyze`/`flutter test` out of the box.
Project: **colorado-catch** (Firebase project ID). Status below reflects what's live.

## Status

- ✅ **Firebase project** `colorado-catch` created (Spark/free plan).
- ✅ **Authentication** — Email/Password and Google sign-in both enabled. Works fine
  on Spark; no Blaze required for this one, despite some conflicting info out there.
- ✅ **Firestore** — database created (`nam5`), `firestore.rules` deployed.
- ✅ **Android + iOS apps registered** — `google-services.json` and
  `GoogleService-Info.plist` are in place with real OAuth client IDs.
  `lib/firebase_options.dart` has real values (generated via `flutterfire configure`).
- ✅ **iOS Google Sign-In URL scheme** — `Info.plist`'s `CFBundleURLTypes` has the
  real `REVERSED_CLIENT_ID`.
- ⏸️ **Cloud Storage** (profile photo upload) — **not provisioned**. As of Google's
  Oct 2024 policy change, a new Storage bucket requires the project to be on the
  **Blaze** (pay-as-you-go) plan, even to stay within the free quota. We're
  deliberately staying on Spark for now, so `ProfileScreen`'s upload button is
  stubbed to a "coming soon" snackbar instead of calling `StorageService`. To turn
  it back on: upgrade to Blaze, create the default bucket, run
  `firebase deploy --only storage`, then wire `_uploadImage` back into
  `ProfileScreen` the way `git log` shows it used to work.
- ❌ **Google Maps API keys** — still placeholders (see step 1 below).
- ❌ **Android SHA-1 for Google Sign-In** — the Android OAuth client Firebase
  auto-created is not guaranteed to match your dev machine's debug keystore. Google
  Sign-In on Android will fail until you register your real SHA-1 (see step 2).

## 1. Google Maps API keys

Create two API keys in the [Google Cloud console](https://console.cloud.google.com/apis/credentials)
for the `colorado-catch` project, restricted to:
- **Maps SDK for Android**, restricted by the app's SHA-1 (see step 2) + package name
  (`com.coloradocatch.colorado_catch`).
- **Maps SDK for iOS**, restricted by the bundle ID (`com.coloradocatch.coloradoCatch`).

Then set:
- `android/app/src/main/AndroidManifest.xml` → the `com.google.android.geo.API_KEY`
  `meta-data` value.
- `ios/Runner/AppDelegate.swift` → the `GMSServices.provideAPIKey(...)` argument.

## 2. Android: get a SHA-1 for Google Sign-In

Run this on whichever machine actually builds the Android app (needs Android
Studio/SDK — this doesn't work in a plain Linux CI box without it):

```bash
cd android && ./gradlew signingReport
```

Copy the SHA-1 under `debug`, then either add it in **Firebase console → Project
settings → your Android app → Add fingerprint**, or hand it over and it can be
added via the Firebase Management API directly. Re-download
`android/app/google-services.json` afterward (`firebase apps:sdkconfig ANDROID
<appId> -o android/app/google-services.json`) since it embeds the cert hash.

Do the same again later for your release keystore before shipping to Play.

## 3. iOS: build tooling

iOS builds require Xcode/CocoaPods on macOS — this repo can't build or run the iOS
target on Linux. After cloning on a Mac:

```bash
cd ios && pod install   # only if a Podfile is present; recent Flutter defaults to Swift Package Manager
```

## 4. Turning Storage back on (whenever you're ready for Blaze)

1. Upgrade the project to Blaze in the Firebase console.
2. Create the default Storage bucket (console prompts for this automatically once
   on Blaze, or `firebase deploy` will create it as part of the next step).
3. `firebase deploy --only storage` to push `storage.rules`.
4. Restore the upload flow in `ProfileScreen` (currently replaced with a
   "coming soon" snackbar) to call `StorageService.uploadProfileImage` again.

## 5. Verify

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Sign up with an email, sign in with Google, drop into the chat tab, and check the
map tab renders (once Maps API keys are set). That exercises Auth, Firestore, and
Maps — the three backends currently live.

## Notes / follow-ups intentionally left out of the MVP

- `firestore.rules` allows create-only (no edit/delete) on chat messages and map pins;
  add a `createdBy` field + ownership check if you want editable pins.
- No local notification UI for foreground push — `PushService` just logs; wire up
  `flutter_local_notifications` if you want a foreground banner.
- No app icons/splash branding yet — the scaffold ships Flutter's default icon.
- Release signing (`android/key.properties`, Xcode signing team) isn't configured.
