# Pantry Chef

Select the ingredients you have on hand and see which dishes you can cook.
All data (ingredients, dishes, selections) is stored on-device via
`shared_preferences`. No backend, no account. The only network use is checking GitHub for
app updates.

## Features

- **Suggest tab** — tap ingredients you have (your selection is remembered);
  dishes you can fully make are ranked first, followed by the closest partial
  matches (fewest missing) showing what's missing.
- **Ingredients tab** — add or delete ingredients; each shows how many dishes use it.
- **Dishes tab** — add, edit (tap a dish), or delete (with Undo) dishes, each with
  its own list of required ingredients. In the editor one field both filters the
  list and adds a brand-new ingredient; leaving with unsaved changes asks first.
- Light and dark theme follow the phone's setting.

## Project layout

```
lib/
  main.dart                    app entry point
  app_state.dart               in-memory state, persistence, matching logic
  models/
    ingredient.dart
    dish.dart
  services/
    storage_service.dart       SharedPreferences load/save
    seed_data.dart             starter ingredients/dishes for first launch
    updater.dart               self-update from the "latest" GitHub release
  util/
    names.dart                 tidying/comparing ingredient and dish names
  screens/
    root_screen.dart           bottom navigation
    suggest_screen.dart
    ingredients_screen.dart
    dishes_screen.dart
    dish_editor_screen.dart
    update_ui.dart             update strip and About & updates sheet
android/                       Android project (signing, app id, native installer hook)
test/                          unit and widget tests
```

## Install

1. On the phone, open this repository's **Releases** page and download `PantryChef.apk` from
   **Latest build**.
2. Open the downloaded file. Android asks once to allow installs from the browser. Allow it.

### Updates

The app updates itself from the same **Latest build** release. When it starts (and when you come
back to it, at most once an hour) it reads the release's `version.json`; if there is a newer build
a strip appears above the tabs. Tap **Details** (or ⓘ on the Suggest tab) to see what changed, then
**Download and install**. Android always asks for that one tap for apps from outside the Play
Store, and the first time it asks to allow installs from Pantry Chef. ⓘ also shows the installed
version and has **Check now**. Nothing is lost: every build is signed with the same key. The
repository is public, so no token is needed.

## Build

GitHub Actions (`.github/workflows/build.yml`) analyzes, runs the tests and builds a signed APK
on every push to `main`, then publishes it as the **latest** release together with
`version.json` (the version and the merged pull request titles since the previous build).
Pull requests are analyzed, tested and built, but not published.

- **Version**: `versionName` comes from `pubspec.yaml`; the build number (Android `versionCode`)
  is the workflow run number, so every build on `main` is newer than the last.
- **Signing**: the key lives in the repository secrets `SIGNING_KEYSTORE_B64` (a base64 PKCS#12
  keystore with the alias `release` and the certificate name `CN=Pantry Chef`) and
  `SIGNING_PASSWORD`. Every build must use the same key, or the phone refuses the update, so a
  build on `main` fails when the secret is missing.

To make the key once:

```
keytool -genkeypair -storetype pkcs12 -keystore release.p12 -alias release \
  -keyalg RSA -keysize 4096 -validity 36500 -dname "CN=Pantry Chef"
base64 -w0 release.p12   # paste into the SIGNING_KEYSTORE_B64 secret
```

## Running it locally

With the Flutter SDK installed:

```
flutter pub get
flutter test
flutter run              # pick a connected device/emulator
```

Local release builds without `SIGNING_KEYSTORE` set are signed with the debug key and can't
update an installed copy from GitHub.
