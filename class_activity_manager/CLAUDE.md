# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Class Activity Manager is a Flutter desktop application for managing professional training modules, learning outcomes (RAs - Resultats d'Aprenentatge), and classroom activities in the Catalan education system. The app is localized for Catalan.

## Build & Development Commands

```bash
flutter pub get          # Install dependencies
flutter analyze          # Lint code (uses flutter_lints)
flutter test             # Run tests
flutter run -d linux     # Run on Linux desktop
flutter run -d macos     # Run on macOS desktop
flutter run -d windows   # Run on Windows desktop
```

## Architecture

### State Management
- **Riverpod** with `StateNotifierProvider`
- Single provider: `appStateProvider` in `lib/state/app_state.dart`
- All app data lives in the immutable `AppState` class
- State updates via `ref.read(appStateProvider.notifier).methodName()`
- State reads via `ref.watch(appStateProvider)`
- **No persistence layer** - all state is in-memory

### Routing
- **GoRouter** configured in `lib/router/app_router.dart`
- Nested routes with `ShellRoute` wrapper (`AppShell` provides the navigation drawer)
- Navigation via `context.go('/path')` or `context.push('/path')`

### Key Directories
```
lib/
├── core/           # Theme, utilities (single instance guard)
├── data/           # Curriculum data models and services (read-only YAML import)
├── models/         # Domain models (Modul, RA, Group, DailyNote, etc.)
├── presentation/   # Pages and shell (UI layer)
├── router/         # GoRouter configuration
└── state/          # AppState and AppStateNotifier
```

### Domain Models
- **Modul**: Professional training module (e.g., MP06) with code, hours, RAs
- **RA** (Resultat d'Aprenentatge): Learning outcome within a module
- **CriteriAvaluacio**: Evaluation criteria for each RA
- **Group**: Student group/class
- **DailyNote**: Session notes linked to RA + date
- **AcademicYear**: Academic year with vacation periods and holidays

All models use `copyWith()` for immutable updates and UUIDs for IDs.

### Curriculum Import
The app can import modules from `assets/curriculum-informatica.yaml`. The `CurriculumService` loads YAML data and converts `CurriculumUF` (Unitat Formativa) entries to `RA` objects.

## UI Conventions

- **Material 3** with forest green primary (`#1B5E20`)
- Pages extend `ConsumerWidget` or `ConsumerStatefulWidget`
- Forms use `showDialog()` for CRUD operations
- Hardcoded Catalan UI strings (no i18n setup yet)
- Desktop enforces single-instance via file lock

## Dependencies

Key packages: `flutter_riverpod`, `go_router`, `uuid`, `intl`, `yaml`
