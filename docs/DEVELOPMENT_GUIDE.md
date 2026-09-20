# 🛠️ Development & Performance Guide

This guide provides instructions for setting up, building, testing, and maintaining **Convolens**.

---

## 💻 Local Environment Setup

### Tools Required
- **Flutter SDK**: `^3.24.0` (Dart `^3.12.2`)
- **Android Studio** / **VS Code** with Flutter and Dart plugins
- **Platform Toolchains**: Android SDK for Android builds, Xcode for iOS builds, CMake/Visual Studio for Desktop builds.

---

## ⚙️ Code Generation (`build_runner`)

Convolens uses `drift_dev` to generate typed database code (`app_database.g.dart`).

Whenever you modify any table file in `lib/core/database/tables/` or query in `app_database.dart`:

```bash
# One-shot build
dart run build_runner build --delete-conflicting-outputs

# Watch mode (automatically re-generates on save during dev)
dart run build_runner watch --delete-conflicting-outputs
```

---

## 🧪 Testing Guidelines

### Unit & Widget Testing
Tests are located under the `test/` directory.

- **Run all unit & widget tests**:
  ```bash
  flutter test
  ```

- **Run specific test file**:
  ```bash
  flutter test test/timeline_wave_test.dart
  ```

### Static Analysis & Lints
Always ensure the codebase passes static analysis cleanly before submitting commits:

```bash
# Analyze full workspace
dart analyze lib test

# Apply mechanical dart fixes
dart fix --apply

# Format all Dart files
dart format lib test
```

---

## 🚀 Performance Guidelines

To maintain smooth 60/120 FPS rendering on mobile devices:

1. **Avoid Multi-Level Outer StreamBuilders**:
   - Wrap `StreamBuilder`s at the smallest possible widget scope.
   - Do not wrap entire `CustomScrollView`s or `Stack`s in streams if only list items depend on them.

2. **Liquid Glass Surface Quality**:
   - Use `GlassQuality.standard` for scrollable list elements.
   - Limit active premium glass surfaces to 1-2 elements maximum per screen.
   - In production builds, ensure `enablePerformanceMonitor` is set to `false`.

3. **Repaint Boundaries**:
   - Heavy custom paint elements (`_LiquidWavePainter`, `RelationshipWebPainter`) must be wrapped in `RepaintBoundary`.
   - Set `isComplex: true` and `willChange: true` on `CustomPaint` widgets when repaints occur frequently.

4. **Gesture Recognizer Isolation**:
   - Edge gesture overlays must use `IgnorePointer` over canvas paint areas and employ `onHorizontalDrag*` recognizers to avoid hijacking vertical scroll gestures.

---

## 📦 Building for Production

### Android Release APK/Bundle
```bash
flutter build apk --release
flutter build appbundle --release
```

### iOS Release Build
```bash
flutter build ipa --release
```
