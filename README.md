# Delib.io — Android (Flutter)

Cross-platform Flutter app for **Delib.io**, a multi-AI deliberation platform. Users ask one question; five top AI models (Claude, ChatGPT, Grok, Llama, Gemini) deliberate in parallel; the app delivers a single synthesized verdict.

Currently shipping on **Google Play** (Internal Testing live, Production in review).

## Stack

- **Framework:** Flutter (Dart)
- **Min SDK:** Android 7.0 (API 24)
- **Target SDK:** Android 16 (API 36)
- **Package:** `io.delib.app`
- **App name:** Delib.io

## Quick start

Prereqs: Flutter 3.x, Android Studio, JDK 17.

```bash
git clone https://github.com/mcnancarrow/delib-flutter.git
cd delib-flutter
flutter pub get
flutter run
```

App talks to the production backend at `https://www.delib.io`.

## Architecture

```
lib/
├── main.dart                  App entrypoint + theme bootstrap
├── screens/
│   ├── splash_screen.dart     Splash with token check
│   ├── login_screen.dart      Sign in
│   ├── signup_screen.dart     Account creation
│   ├── home_screen.dart       Main deliberation UI + mode selector
│   ├── account_screen.dart    Profile, sign out
│   └── result_screen.dart     Voice cards + verdict
├── services/
│   └── api_service.dart       All backend calls (HTTP + flutter_secure_storage)
└── theme/
    └── app_theme.dart         Brand palette + text styles

android/
├── app/
│   ├── build.gradle.kts       Signing config + version
│   └── src/main/
│       ├── AndroidManifest.xml
│       ├── kotlin/io/delib/app/MainActivity.kt
│       └── res/               App icons, launcher
├── key.properties             Local only — not committed
└── keystore/
    └── delib-release.jks      Local only — not committed
```

## Release signing

The release keystore lives at `android/app/keystore/delib-release.jks` (gitignored). Credentials in `android/key.properties` (also gitignored).

If you lose the keystore, you'll need to request an **Upload Key Reset** from Google Play Console — takes 1–2 business days.

## Building a release AAB

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`.

Verify signing before uploading:

```bash
keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab | grep SHA1
```

Should match the registered upload key fingerprint in Google Play Console:
`CC:A0:61:CF:56:6A:C7:84:8C:45:DE:1B:ED:41:7F:FC:7D:F7:AE:19`

## Versioning

Edit `android/app/build.gradle.kts`:

```kotlin
versionCode = 4
versionName = "1.0.3"
```

Google Play requires `versionCode` to increase with every upload.

## Important notes

- **R8 minification is disabled** (`isMinifyEnabled = false`, `isShrinkResources = false`) — when previously enabled it stripped Flutter runtime classes and caused startup crashes. Can be re-enabled later with proper ProGuard rules.
- **`MainActivity.kt` must be at `kotlin/io/delib/app/MainActivity.kt`** to match `applicationId = "io.delib.app"`. A mismatch causes `ClassNotFoundException` on launch.

## Backend dependency

This app requires the backend at https://www.delib.io to be running. The backend source lives in [mcnancarrow/boardrm-ai](https://github.com/mcnancarrow/boardrm-ai).

## Release history

See [GitHub Releases](https://github.com/mcnancarrow/delib-flutter/releases) for full version notes. Recent:

- **v1.0.3 build 4** — Fixed startup crash (MainActivity package mismatch), corrected app name display, configured release signing
