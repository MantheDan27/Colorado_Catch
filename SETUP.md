# Setup

This scaffold compiles and passes `flutter analyze`/`flutter test` out of the box, but
every screen talks to Firebase/Google Maps with placeholder credentials. Follow these
steps once to point it at your own project.

## 1. Create a Firebase project

1. Go to the [Firebase console](https://console.firebase.google.com/) → **Add project**.
2. Enable these products for the project:
   - **Authentication** → Sign-in method → enable **Email/Password** and **Google**.
   - **Firestore Database** → create in production mode (rules are already in `firestore.rules`).
   - **Storage** → create a default bucket (rules are already in `storage.rules`).
   - **Cloud Messaging** (push) — no setup needed beyond project creation.
   - **Analytics** — enabled automatically if you turned it on at project creation.

## 2. Generate `firebase_options.dart`

Install the FlutterFire CLI once, then run it from the project root:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Pick your Firebase project and the `android`/`ios` platforms. This overwrites
`lib/firebase_options.dart` with real values and drops:
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

into place automatically.

## 3. iOS: register the Google Sign-In URL scheme

Open `ios/Runner/GoogleService-Info.plist` (just added by the CLI) and copy the
`REVERSED_CLIENT_ID` value into `ios/Runner/Info.plist`, replacing the placeholder
string `REVERSED_CLIENT_ID` under `CFBundleURLTypes`.

Also add `GoogleService-Info.plist` to the Xcode project (Runner target →
**Add Files to "Runner"**) so it's bundled into the app — the CLI usually does this
for you, but double-check in Xcode if `Firebase.initializeApp()` fails at runtime.

## 4. Google Maps API keys

Create two API keys in the [Google Cloud console](https://console.cloud.google.com/apis/credentials)
for the same GCP project Firebase created for you, restricted to:
- **Maps SDK for Android**, restricted by the app's SHA-1 + package name
  (`com.coloradocatch.colorado_catch`).
- **Maps SDK for iOS**, restricted by the bundle ID (`com.coloradocatch.coloradoCatch`).

Then set:
- `android/app/src/main/AndroidManifest.xml` → the `com.google.android.geo.API_KEY`
  `meta-data` value.
- `ios/Runner/AppDelegate.swift` → the `GMSServices.provideAPIKey(...)` argument.

## 5. Android: get a SHA-1 for Google Sign-In

Google Sign-In on Android needs your debug (and later release) SHA-1 registered on the
Firebase Android app:

```bash
cd android && ./gradlew signingReport
```

Copy the SHA-1 under `debug` into **Project settings → Your apps → Android app** in the
Firebase console, then re-download `google-services.json` if it changes.

## 6. iOS: build tooling

iOS builds require Xcode/CocoaPods on macOS — this repo can't build or run the iOS
target on Linux. After cloning on a Mac:

```bash
cd ios && pod install   # only if a Podfile is present; recent Flutter defaults to Swift Package Manager
```

## 7. Verify

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Sign up with an email, sign in with Google, upload a profile photo, drop into the chat
tab, and check the map tab renders. Each of those exercises a different Firebase
product, so it's a good end-to-end smoke test.

## Notes / follow-ups intentionally left out of the MVP

- `firestore.rules` allows create-only (no edit/delete) on chat messages and map pins;
  add a `createdBy` field + ownership check if you want editable pins.
- No local notification UI for foreground push — `PushService` just logs; wire up
  `flutter_local_notifications` if you want a foreground banner.
- No app icons/splash branding yet — the scaffold ships Flutter's default icon.
- Release signing (`android/key.properties`, Xcode signing team) isn't configured.
