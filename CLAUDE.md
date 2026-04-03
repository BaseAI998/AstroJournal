# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

AstroJournal is an offline-first diary and emotion review tool with astrology theming, built with Flutter. It targets Android, Windows, and Web (iOS is deferred). The UI language is Chinese (Simplified); code and identifiers are in English.

## Build & Development Commands

```bash
flutter pub get                        # Install dependencies
flutter run                            # Run in debug mode (auto-detects device)
flutter run -d windows                 # Run on Windows
flutter run -d chrome                  # Run on Web
flutter build apk                      # Build Android APK
flutter build web                      # Build web version
flutter build windows                  # Build Windows executable
flutter analyze                        # Run linter (uses flutter_lints)
flutter test                           # Run all tests
flutter test test/path_to_test.dart    # Run a single test file
flutter pub run build_runner build     # Code generation (required after changing Drift schemas)
```

## Architecture

### State Management: Riverpod

Three core providers in `lib/providers/`:

- **`databaseProvider`** — singleton `AppDatabase` instance, disposed on teardown
- **`profileProvider`** — `StateNotifierProvider<ProfileNotifier, AsyncValue<Profile?>>` — loads/saves user profile, drives onboarding redirect
- **`journalProvider`** — `StateNotifierProvider<JournalNotifier, AsyncValue<List<JournalEntry>>>` — CRUD for journal entries and comments, sorted newest-first

### Routing: GoRouter

Defined in `lib/core/router/app_router.dart`. Route guard logic: no profile redirects to `/onboarding`; existing profile on `/onboarding` redirects to `/`.

Main layout uses `StatefulShellRoute.indexedStack` with a bottom nav bar (Capture `/` and Chart `/chart`). History (`/history`, `/history/detail/:id`) is presented as a modal route.

### Data Layer

Models (`Profile`, `JournalEntry`, `JournalComment`) and the `AppDatabase` class live in `lib/core/database/database.dart`. Storage is currently JSON file-based with platform-conditional imports:

- `lib/core/database/storage/storage_io.dart` — mobile/desktop (uses `path_provider`)
- `lib/core/database/storage/storage_web.dart` — browser storage
- `lib/core/database/storage/storage.dart` — conditional export hub

Drift (SQLite ORM) is declared as a dependency but not yet active. The `AppDatabase` interface is designed for a seamless migration.

### Feature Organization

Features follow `lib/features/<name>/view/` (or `presentation/`) pattern. Each feature is a self-contained UI module:

- **capture** — full-screen text input, triggers burn shader animation on submit
- **history** — masonry grid of entries (`flutter_staggered_grid_view`), detail page with comments
- **chart** — astrology chart placeholder (static mockup, `fl_chart` ready but not integrated)
- **onboarding** — profile creation form (name, birth date/time, birth city)

### Theme

`lib/core/theme/app_theme.dart` defines a medieval parchment aesthetic — all serif fonts, flat design with no elevation, parchment/goldenrod/sepia color palette.

### Shader

A GLSL fragment shader (`shaders/burn.frag`) powers the paper-burn animation widget at `lib/core/widgets/burn_fade_effect.dart`. It uses simplex noise FBM for a realistic fire edge effect.
