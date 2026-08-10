# ileny mobile

Flutter client for the ileny HR platform. Android-first; see `plan.txt` for scope.

## Running locally

The app defaults to the deployed API (`https://api.ileny.app/api/v1`) so a plain
build can never accidentally ship pointed at a workstation. Override it for
local work:

```
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8090/api/v1
```

`10.0.2.2` is the Android emulator's alias for the host's localhost; a physical
device needs the host's LAN IP. Cleartext HTTP is permitted only in debug
builds, so release builds must use an `https` URL.

## Release builds

### One-time setup

1. Generate the upload keystore and keep a durable backup of the `.jks`:

   ```
   keytool -genkey -v -keystore %USERPROFILE%\ileny-upload.jks \
     -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. Copy `android/key.properties.example` to `android/key.properties` and fill
   it in. Both the keystore and that file are gitignored.

Without `key.properties` the release build still compiles, but falls back to the
debug key and prints a loud warning — Google Play rejects such artifacts.

### Building

```
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`. Play requires an
AAB; APKs are rejected. The bundle carries every ABI, so its size on disk is
far larger than what any single device downloads.

Bump `version:` in `pubspec.yaml` before each upload — the `+N` build number
becomes `versionCode` and must strictly increase.

## Firebase

Push notifications run through the `ileny-app` Firebase project. Two files must
stay in step, and both are committed:

- `android/app/google-services.json` — read by the Google Services Gradle plugin
- `lib/firebase_options.dart` — read by `Firebase.initializeApp`

Regenerate both with `flutterfire configure --project=ileny-app`. The API key in
them is not a secret (it ships in every APK) but should be restricted by package
name and SHA-1 in the Google Cloud console.

Delivery also needs service-account credentials on the backend; without them the
backend's `FirebaseConfig` stays a no-op.

## Legal documents

The terms and privacy policy are **not** in this repo. They are static pages in
the marketing front end (`front-end/marketing/src/app/{terms,privacy}/page.tsx`),
because legal text must be changeable without a deploy — see the reasoning on
`LegalController` in the API. Bundling a copy here would put it behind a Play
release.

The app links out to `ileny.app/terms` and `ileny.app/privacy` from the sign-in
footer and the profile screen, via `lib/features/legal/legal_documents.dart`.
Play also requires the privacy URL on the store listing; it is the same page.

Nothing is recorded on acceptance here. Versions are validated only at web
signup, against `GET /api/v1/legal/versions` — employees never register in the
app, so the mobile client only ever displays.
