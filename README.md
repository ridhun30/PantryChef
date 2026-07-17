# Pantry Chef

Select the ingredients you have on hand and see which dishes you can cook.
Fully offline — all data (ingredients, dishes, selections) is stored on-device
via `shared_preferences`. No backend, no account, no network calls.

## Features

- **Suggest tab** — tap ingredients you have; dishes you can fully make are
  ranked first, followed by close partial matches showing what's missing.
- **Ingredients tab** — add or delete ingredients.
- **Dishes tab** — add, edit, or delete dishes, each with its own list of
  required ingredients (you can add a brand-new ingredient inline while
  defining a dish).

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
  screens/
    root_screen.dart           bottom navigation
    suggest_screen.dart
    ingredients_screen.dart
    dishes_screen.dart
    dish_editor_screen.dart
```

## Running it

This repo only contains the Dart source and `pubspec.yaml` — the platform
folders (`android/`, `ios/`, `web/`, etc.) aren't generated yet. On a machine
with the Flutter SDK installed:

```
flutter create .        # generates android/ios/web scaffolding in place
flutter pub get
flutter run              # pick a connected device/emulator, or:
flutter run -d chrome    # quick preview in a browser
```

To build an installable Android APK later: `flutter build apk`.
