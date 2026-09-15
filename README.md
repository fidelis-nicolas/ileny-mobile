# ileny mobile

Flutter client for the ileny HR platform. Android shipped first; see `plan.txt`
for scope and the iOS section below for what that target still needs.

## Running locally

The app defaults to the deployed API (`https://api.ileny.app/api/v1`) so a plain
build can never accidentally ship pointed at a workstation. Override it for
local work:

```
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8090/api/v1
```

`10.0.2.2` is the Android emulator's alias for the host's localhost; a physical
device needs the host's LAN IP. On the iOS simulator, which shares the Mac's
network stack, use `http://localhost:8090/api/v1` instead. Cleartext HTTP is
permitted only in debug builds, so release builds must use an `https` URL.

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

Push notifications run through the `ileny-app` Firebase project, which has one
app registered per platform:

| | App ID | Config read from |
|---|---|---|
| Android | `1:753285259194:android:63891387bd0fb0e0894783` | `android/app/google-services.json` + `lib/firebase_options.dart` |
| iOS | `1:753285259194:ios:222d7e27eeb43715894783` | `ios/Runner/GoogleService-Info.plist` |

All three files are committed. Android needs two of them because the Gradle
plugin and `Firebase.initializeApp` read different ones, and they must stay in
step; iOS needs only the plist, because the Firebase iOS SDK configures itself
from the bundle. Regenerate any of them with `flutterfire configure
--project=ileny-app`. The API keys are not secrets — they ship inside every
build — but should be restricted by bundle ID and SHA-1 in the Google Cloud
console.

The iOS plist is in the Runner target's **Resources** build phase, not just the
folder. The SDK loads it from the app bundle, so a file that is merely present
on disk configures nothing.

### What still has to be true for a push to arrive

Client registration is only one end of it. In order:

1. **The backend can send.** `app.firebase.enabled` defaults to `false` and
   `FirebaseConfig` returns a null bean without it, which makes
   `PushNotificationService` a silent no-op — so `FCM_ENABLED=true` and
   `FCM_CREDENTIALS_PATH` must both be set in the deployed environment. This is
   worth checking before blaming a client: if it is off, no push has ever been
   delivered on **either** platform, and nothing in the app or the logs would
   say so.
2. **FCM can reach the platform.** Android works off the project alone. iOS
   additionally needs an APNs key — see below.
3. **The device registered a token.** `PushNotificationService.start` does this
   on sign-in and drops it on sign-out.

## Tester builds (Firebase App Distribution)

Play submission is blocked until the upload keystore exists, but testers can
get builds now through App Distribution, which has no signing requirement of
its own — it serves the APK straight to enrolled devices.

Distribute an **APK**, not the AAB: App Distribution only accepts a bundle for
projects linked to Play, and this one is not linked yet.

```
flutter build apk --release
firebase login          # once per machine, opens a browser
firebase appdistribution:distribute \
  build/app/outputs/flutter-apk/app-release.apk \
  --app 1:753285259194:android:63891387bd0fb0e0894783 \
  --groups testers \
  --release-notes-file distribution-notes.txt
```

`.firebaserc` pins the project to `ileny-app`, so `--project` is not needed.
The `--app` value is the `mobilesdk_app_id` from `android/app/google-services.json`;
create the `testers` group under App Distribution → Testers & Groups first, or
swap `--groups` for `--testers a@example.com,b@example.com`.

Until `android/key.properties` exists these builds are **debug-signed**. That is
fine for App Distribution, but two consequences follow: such a build can never be
promoted to Play, and the day the real upload key lands the signature changes, so
testers must uninstall before installing the next one — Android refuses an update
signed by a different key.

## iOS

The iOS target builds from the same Dart source and needs no code changes — but
it can only be built on a Mac, so everything below has been prepared on the
project side and none of it has been compiled. Treat the first `flutter build`
as the real verification.

### First build on a Mac

```
flutter pub get
cd ios && pod install && cd ..
flutter run                       # simulator: no signing needed
```

`pod install` needs CocoaPods (`sudo gem install cocoapods`, or `brew install
cocoapods`). `ios/Podfile` is committed rather than left for Flutter to
generate, because the generated one pins the template's platform floor and the
Firebase pods will not build below iOS 15.

To run on a physical device, open `ios/Runner.xcworkspace` once and set the team
under Runner → Signing & Capabilities. That writes `DEVELOPMENT_TEAM` into the
project file; without it `flutter build ipa` fails before it compiles anything.

### What is already set

- **Bundle ID** `app.ileny.mobile`, the same string as the Android
  `applicationId`. Like Play, App Store Connect fixes this at first upload.
- **Deployment target** iOS 15.0, in the Xcode project and the Podfile. Set by
  firebase_core 4.12, which pulls the Firebase iOS SDK 12.x; every other plugin
  here would have been happy with 13.0.
- **Permission strings** for camera, location and photo library in
  `ios/Runner/Info.plist`. iOS terminates the app rather than showing a prompt
  when one is missing, so the photo library entry matters even though only the
  discipline-case picker reaches it.
- **Entitlements** in `ios/Runner/{DebugProfile,Release}.entitlements`:
  - *Keychain Sharing*, which flutter_secure_storage needs on iOS — without it
    the session token appears to save and does not, so the user is signed out on
    every cold start.
  - *`aps-environment`*, `development` in DebugProfile and `production` in
    Release. The two APNs environments issue different device tokens and neither
    accepts the other's, which is the usual explanation for a push that works
    from Xcode but not from TestFlight, or the reverse.
- **App icon and launch screen**, generated from `assets/icons/ileny_favicon.svg`
  by `node store/ios/generate-ios-icons.js`. The launch screen follows the system
  appearance, as the Android one does.
- `ITSAppUsesNonExemptEncryption` is answered `false` in `Info.plist`, so
  TestFlight stops asking on every upload. The app's only cryptography is HTTPS
  through the OS, which is exempt.

### What iOS still needs

1. **An Apple Developer Program membership** ($99/yr) for TestFlight, the App
   Store, and push. This is now a hard requirement rather than a distribution
   one: the entitlements ask for `aps-environment`, and a free personal team
   cannot sign that — Xcode fails the build with "Push Notifications is not
   available" rather than dropping the capability. If you need to run on a
   device before the membership exists, delete the `aps-environment` key from
   `ios/Runner/DebugProfile.entitlements` and put it back afterwards.
2. **An APNs authentication key**, which is the one remaining piece of iOS
   push. Everything on this side is done: the Firebase iOS app exists,
   `GoogleService-Info.plist` is committed and in the Resources build phase, and
   `aps-environment` is set in both entitlements files. But FCM delivers to iOS
   *through* Apple, and it cannot until it holds a key:

   1. In the Apple Developer portal → Keys, create a key with **Apple Push
      Notifications service (APNs)** enabled. Download the `.p8` **once** — Apple
      will not serve it again — and note the Key ID and your Team ID.
   2. Firebase console → Project settings → Cloud Messaging → the **ileny iOS**
      app → Upload the `.p8` with that Key ID and Team ID.

   Both steps need the paid membership above; the portal has no Keys section
   without it.

   Until then the app runs normally and registers no usable token. Nothing
   crashes: `main` catches a failed init, `start()` catches a failed
   registration, and the unread badge falls back to `NotificationsState`'s
   polling — the same degraded mode an Android build with no Firebase runs in.
3. **A decision on iPad.** The project still declares the template's universal
   device family, so the App Store will expect iPad screenshots and judge the
   layout on one. Nothing here was designed for that width. Setting
   `TARGETED_DEVICE_FAMILY` to `1` makes it an iPhone app; leaving it means
   testing on an iPad before submitting.

### TestFlight

```
flutter build ipa --release
```

Output: `build/ios/ipa/*.ipa`, uploaded with Transporter or
`xcrun altool`. `version:` in `pubspec.yaml` drives both fields —
`1.0.0` becomes `CFBundleShortVersionString` and `+4` becomes
`CFBundleVersion`, which must increase with every upload, as `versionCode` does
for Play. The two stores share the counter, so an iOS upload consumes a build
number that Android then cannot reuse.

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
