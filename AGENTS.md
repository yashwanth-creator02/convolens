# Convolens

Android-first Flutter app that turns the device call log into an analyzable, visualizable communication record: call history with a draggable timeline wave, relationship analytics (heatmaps, web graph, hour clock), contact enrichment from device contacts, per-contact tags and social links, and a personal vCard profile with QR sharing. Local-only: all data lives in a Drift SQLite database on the device.

## Stack

| Layer | Choice |
| --- | --- |
| Framework | Flutter (Dart SDK `^3.12.2`, app version in `pubspec.yaml`) |
| State | No state-management package. `StatefulWidget` + `ValueNotifier` + `StreamBuilder` over Drift watch queries |
| Database | `drift` + `sqlite3_flutter_libs`, generated code in `lib/core/database/app_database.g.dart` |
| Device APIs | `flutter_contacts`, `permission_handler`, `record`, `just_audio`, `image_picker`, `file_picker` |
| UI | `liquid_glass_widgets`, custom `CustomPainter`s, fragment shader `shaders/cosmo_nebula.frag` |
| Tests | `flutter_test` only. No integration tests, no mocking package |

## Commands

| Task | Command |
| --- | --- |
| Install | `flutter pub get` |
| Run (device) | `flutter run` |
| Build APK | `flutter build apk --release` |
| Test all | `flutter test` |
| Test one file | `flutter test test/features/history/timeline_wave_index_test.dart` |
| Analyze | `dart analyze lib test` |
| Format | `dart format lib test` |
| Mechanical fixes | `dart fix --apply` |
| DB codegen (after any table/edit in `lib/core/database/`) | `dart run build_runner build --delete-conflicting-outputs` |
| DB codegen watch | `dart run build_runner watch --delete-conflicting-outputs` |

`app_database.g.dart` is generated and committed. Never hand-edit it; regenerate instead.

## Architecture

Feature-first layered architecture, described at length in `docs/ARCHITECTURE.md` (data flow), `docs/DATABASE_SCHEMA.md` (tables), `docs/FEATURES.md` (behaviour), `docs/DEVELOPMENT_GUIDE.md` (setup and perf rules).

```
lib/main.dart                     entry point
lib/app/app.dart                  MaterialApp, theme wiring
lib/app/main_shell.dart           bottom-tab shell, _FadeIndexedStack keeps tab state alive
lib/core/database/                AppDatabase (Drift), tables/, models/, migrations (schema v15)
lib/core/{native,notifications,services,theme,toast,logger,utils,widgets}
lib/features/<feature>/           models/ repository/ screens/ widgets/ utils/ tabs/
lib/shared/                       cross-feature widgets, utils, cosmo widgets
```

Flow: screen -> `features/*/repository` -> `AppDatabase` watch stream -> `StreamBuilder`. Screens never query Drift directly. Repositories also own precomputed view structures (`buildHistoryItems`, `buildYearIndex`, `buildMonthIndex`).

Features present: `history` (call list, timeline wave, filters, call details), `analytics` (heatmap, relationship web, hour clock), `contacts` (list, detail, tags, socials, add flows), `settings` (preferences, theme, developer tools), `profile` (vCard + QR), `onboarding`.

## Conventions

- Group code by feature, not by kind. New screens go in `lib/features/<feature>/screens/`, widgets only that feature uses stay in its `widgets/`.
- Paths use `package:convolens/...` imports.
- `const` constructors everywhere possible; `super.key` in widget constructors.
- Dispose every `StreamSubscription`, `AnimationController`, `ValueNotifier`, and `Timer` in `dispose()`.
- Keep `StreamBuilder`s at the lowest possible subtree; never wrap a whole `CustomScrollView` in one.
- Custom painters get `RepaintBoundary` and `isComplex: true` when they repaint often.
- Glass surfaces: `GlassQuality.standard` in scrolling lists, at most 1-2 premium surfaces per screen, `enablePerformanceMonitor` false in production.
- Zero emojis in code, comments, commits, and UI copy. No raw hex/rgb colour literals; colours come from `lib/core/theme`.
- No `print`; use `lib/core/logger`.
- Commit messages: Conventional-Commits style, branch per change, never commit to `main` directly.

### Sensitive areas

- `lib/features/history/widgets/timeline_wave_navigator.dart` owns a hand-rolled horizontal drag recognizer. It is intentionally isolated from the vertical list gesture arena; changes need `test/timeline_wave_test.dart` and `test/features/history/timeline_wave_index_test.dart` green, plus a manual drag check on a device.
- Migration code in `lib/core/database/app_database.dart` is versioned and must keep existing `onUpgrade` steps intact. Never reorder or renumber a shipped step.
- Device permissions flow through `lib/core/native`; requesting permissions elsewhere duplicates prompts.

## Capability catalog

Installed MCP servers, skills and plugins are catalogued in `~/.config/opencode/skills/repo-initializer/references/catalog.md`. Regenerate it with `python ~/.config/opencode/skills/repo-initializer/scripts/build_catalog.py`.

This repo enables only the subset listed in `.opencode/opencode.jsonc`: MCP servers `dart`, `context7`, `graphify`, plus the Dart/Flutter skill set, `accessibility`, `populate`, `discernment-nudge`, and the skills contributed by always-on plugins. Plugins are not restricted and stay enabled globally.

A denied skill or MCP server is removed from the registry, not merely hidden: it cannot be loaded on demand later. If a task needs a capability that is not enabled here, read the catalog, tell the user what enabling it would add and why, and wait for approval before changing any configuration. To widen the profile, re-run:

```bash
python ~/.config/opencode/skills/repo-initializer/scripts/make_policy.py \
  --skills <ids> --mcp <servers> --write .opencode/opencode.jsonc
```

## Verification before finishing

1. `dart analyze lib test` - no new issues.
2. `flutter test` - all green.
3. `dart run build_runner build --delete-conflicting-outputs` if anything under `lib/core/database/` changed.
4. Manual run on the connected device for gesture, scroll, and animation changes; hot reload through the `dart` MCP server, hot restart when state or `main()` changed.
