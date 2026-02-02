# Class Activity Manager

A Flutter desktop application for managing professional training modules, learning outcomes, and classroom activities in the Catalan education system (Formació Professional).

## Features

- **Dashboard**: View today's active classes and track overall RA (Resultat d'Aprenentatge) progress
- **Calendar**: Interactive academic calendar with holidays, weekends, and vacation period indicators
- **Modules Management**: Create, edit, and organize professional training modules (Mòduls)
- **Daily Notes**: Record session notes linked to specific RAs and dates with Markdown support
- **Groups**: Manage student groups/classes with color-coding
- **RA Configuration**: Configure learning outcomes and evaluation criteria
- **Curriculum Import**: Import official Catalan curriculum data from YAML files
- **Offline-First**: Local Isar database with optional MongoDB Atlas cloud synchronization
- **Multi-Platform**: Runs on Linux, macOS, and Windows desktops

## Tech Stack

- **Framework**: Flutter (Desktop)
- **Language**: Dart (SDK ^3.10.4)
- **State Management**: Riverpod
- **Routing**: GoRouter
- **Local Database**: Isar
- **Cloud Database**: MongoDB (optional)
- **UI**: Material 3 with Atkinson Hyperlegible font

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) ^3.10.4
- [Docker](https://www.docker.com/) (optional, for local MongoDB)

## Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd class_activity_manager
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate Isar schemas**
   ```bash
   dart run build_runner build
   ```

4. **Configure environment** (optional, for MongoDB sync)

   Create `lib/.env`:
   ```env
   MONGO_URI=mongodb://user:password@localhost:27017/class_activity_manager
   ```

5. **Run the application**
   ```bash
   flutter run -d linux    # or macos, windows
   ```

## Development Commands

```bash
# Install dependencies
flutter pub get

# Run code generation (Isar schemas)
dart run build_runner build

# Analyze code
flutter analyze

# Run tests
flutter test

# Run on desktop
flutter run -d linux     # Linux
flutter run -d macos     # macOS
flutter run -d windows   # Windows

# Build release
flutter build linux      # or macos, windows

# Code quality check
./scripts/code-quality.sh
```

## Project Structure

```
lib/
├── main.dart           # Entry point with initialization
├── app.dart            # Main app widget
├── core/               # Theme, utilities, audit logging
├── data/               # Data layer
│   ├── cache/          # Isar schemas for local caching
│   ├── datasources/    # Local (Isar) & Remote (MongoDB) datasources
│   ├── models/         # Curriculum data models
│   ├── repositories/   # Caching repositories
│   └── services/       # Database and sync services
├── models/             # Domain models (Modul, RA, Group, DailyNote, etc.)
├── presentation/       # UI layer
│   ├── pages/          # Main application pages
│   ├── shell/          # App shell and navigation drawer
│   └── widgets/        # Reusable widgets
├── router/             # GoRouter configuration
├── state/              # Riverpod state management
└── l10n/               # Internationalization (Catalan, English)
```

## Architecture

### State Management
- Uses **Riverpod** with `StateNotifierProvider`
- Single provider `appStateProvider` holds all application state
- Immutable `AppState` class with `copyWith()` for updates

### Data Persistence
- **Offline-first** architecture with Isar local database
- Optional **MongoDB Atlas** synchronization with conflict resolution
- Sync queue for reliable data synchronization

### Domain Models
- **Modul**: Professional training module (e.g., MP06)
- **RA** (Resultat d'Aprenentatge): Learning outcome within a module
- **CriteriAvaluacio**: Evaluation criteria for each RA
- **Group**: Student group/class
- **DailyNote**: Session notes linked to RA + date
- **AcademicYear**: Academic year with vacation periods

## MongoDB Setup (Optional)

For local development with MongoDB:

```bash
# Start MongoDB and Mongo Express
docker-compose -f docker/docker-compose.yml up -d

# Access Mongo Express at http://localhost:8081

# Stop services
docker-compose -f docker/docker-compose.yml down
```

For production, see [MongoDB Atlas Guide](docs/mongodb-atlas-dart-guide.md).

## Configuration

### Environment Variables

Create `lib/.env` with your database connection:

```env
# Local development
MONGO_URI=mongodb://cam_user:password@localhost:27017/class_activity_manager

# MongoDB Atlas (use direct connection string, not SRV)
MONGO_URI=mongodb://user:pass@host1:27017,host2:27017/dbname?tls=true&authSource=admin
```

### Curriculum Data

The application can import curriculum data from `assets/curriculum-informatica.yaml`. This file contains official Catalan professional training curriculum definitions.

## Localization

The app supports:
- **Catalan** (primary)
- **English**

Localization files are in `lib/l10n/`.

## License

This project is private and not published to pub.dev.
