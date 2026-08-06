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
- ⏸️ **Cloud Storage** (profile *and* catch photo upload) — **not provisioned**. As of
  Google's Oct 2024 policy change, a new Storage bucket requires the project to be on
  the **Blaze** (pay-as-you-go) plan, even to stay within the free quota. We're
  deliberately staying on Spark for now, so `ProfileScreen`'s upload button is stubbed
  to a "coming soon" snackbar, and `CatchCaptureScreen` uses the photo transiently
  (sent to Fishial.AI for species ID) without saving it anywhere — `catches` docs have
  no `photoUrl`. To turn it back on: upgrade to Blaze, create the default bucket, run
  `firebase deploy --only storage`, then wire photo persistence back into both screens.
- ❌ **Google Maps API keys** — still placeholders (see step 1 below).
- ❌ **Android SHA-1 for Google Sign-In** — the Android OAuth client Firebase
  auto-created is not guaranteed to match your dev machine's debug keystore. Google
  Sign-In on Android will fail until you register your real SHA-1 (see step 2).
- ❌ **Fishial.AI API credentials** — still placeholders in `lib/config.dart` (see
  step 3). The catch-capture flow's AI species ID will fail until these are set.
- ✅ **Colorado fishing-area map data** — baked from CPW's live Fishing Atlas into
  `assets/data/colorado_fishing_areas.geojson` (see step 4 to regenerate).
- ⚠️ **`firestore.rules` needs redeploying** — new `catches`/`leaderboard` collection
  rules were added locally; run `firebase deploy --only firestore:rules` to push them
  (see step 6).

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

## 3. Fishial.AI API credentials (fish species identification)

The camera button's catch-capture flow calls the [Fishial.AI](https://fishial.ai)
recognition API to identify a fish's species from a photo. Sign up for a developer
account at [portal.fishial.ai](https://portal.fishial.ai) and set your real
`client_id`/`client_secret` in `lib/config.dart` (`fishialClientId`/
`fishialClientSecret`) — this repo ships with placeholders and cannot include a
working credential, same as the Maps keys above.

**Heads up:** `FishIdService` (`lib/services/fish_id_service.dart`) was built by
empirically probing Fishial's live API (their docs site was unreachable from the
environment this was built in) — the recognition endpoint's `q`-signed-image
requirement is confirmed against the real API, but the token/upload-slot request
shapes are reconstructed from Fishial's general public documentation and **should be
double-checked against your actual portal.fishial.ai dashboard/docs** before relying
on this in production. If a field or endpoint name is off, `FishIdService` is the only
file that needs to change — `CatchCaptureScreen` already has a manual-entry fallback
for whenever AI identification fails.

## 4. Colorado fishing-area map data

`assets/data/colorado_fishing_areas.geojson` is a **baked snapshot**, not fetched live
at runtime — the map reads it from the app bundle. It's pulled from Colorado Parks &
Wildlife's real, public Fishing Atlas ArcGIS service (1,735 named rivers/lakes/ponds,
19 Gold Medal streams, 3 Gold Medal lakes, boat ramps, and accessible-fishing-area
points — no API key required).

To regenerate it (e.g. CPW updates their data each season):

```bash
python3 tool/fetch_fishing_data.py
```

If CPW's service ever moves/breaks, `tool/fetch_fishing_data.py`'s docstring has the
fallback plan (an OpenStreetMap Overpass query for Colorado waterway/lake geometry).

## 5. iOS: build tooling

iOS builds require Xcode/CocoaPods on macOS — this repo can't build or run the iOS
target on Linux. After cloning on a Mac:

```bash
cd ios && pod install   # only if a Podfile is present; recent Flutter defaults to Swift Package Manager
```

## 6. Deploy the updated Firestore rules

Catch logging and the leaderboard need the `catches`/`leaderboard` rules added to
`firestore.rules`:

```bash
firebase deploy --only firestore:rules
```

## 7. Turning Storage back on (whenever you're ready for Blaze)

1. Upgrade the project to Blaze in the Firebase console.
2. Create the default Storage bucket (console prompts for this automatically once
   on Blaze, or `firebase deploy` will create it as part of the next step).
3. `firebase deploy --only storage` to push `storage.rules`.
4. Restore the upload flow in `ProfileScreen` (currently replaced with a
   "coming soon" snackbar) to call `StorageService.uploadProfileImage` again, and add
   a `photoUrl` upload to `CatchCaptureScreen`/`CatchService.logCatch` the same way.

## 8. Verify

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Sign up with an email, sign in with Google — you should land on the **Map** tab
first, with Colorado fishing waters/Gold Medal streams already labeled (Maps API keys
still required for the map to render at all). Tap the center camera button, take/pick
a photo, confirm a species (AI suggestion or manual entry — needs step 3 for real AI
results) and a length, and check that: a new pin appears on the map, the coin pill in
the app bar goes up, and the **Leaderboard** tab reflects the new point total. That
exercises Auth, Firestore, Maps, and the catch-logging flow — everything currently
live except persisted photos (see step 7).

## Notes / follow-ups intentionally left out of the MVP

- `firestore.rules` allows create-only (no edit/delete) on chat messages, map pins,
  and catches; add a `createdBy` field + ownership check if you want editable pins.
- No local notification UI for foreground push — `PushService` just logs; wire up
  `flutter_local_notifications` if you want a foreground banner.
- No app icons/splash branding yet beyond the launch screen — the scaffold ships
  Flutter's default app icon.
- Release signing (`android/key.properties`, Xcode signing team) isn't configured.
- Leaderboard points = fish length (inches) x a species rarity multiplier — see
  `lib/utils/points_calculator.dart` and the curated tier list in
  `lib/data/species_rarity.dart`. It's a hand-maintained MVP list of Colorado
  gamefish; unrecognized/free-typed species default to the common tier, so
  scoring never breaks, but the list is worth expanding as real species show up.
