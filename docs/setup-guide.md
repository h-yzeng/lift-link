# LiftLink Development Setup Guide

## Prerequisites

Before starting, ensure you have the following installed:

- **Flutter SDK** 3.2.0 or higher
- **Dart SDK** 3.2.0 or higher (included with Flutter)
- **Supabase CLI** (for local development)
- **Git**
- **VS Code** or **Android Studio** (recommended IDEs)

### Installing Prerequisites

#### Flutter
```bash
# Windows (using Chocolatey)
choco install flutter

# Or download from https://flutter.dev/docs/get-started/install/windows
```

#### Supabase CLI
```bash
# Windows (using Scoop)
scoop bucket add supabase https://github.com/supabase/scoop-bucket.git
scoop install supabase

# Or using npm
npm install -g supabase
```

## Initial Setup

### 1. Clone the Repository
```bash
git clone <repository-url>
cd LiftLink
```

### 2. Create Flutter Platform Folders
The Flutter project structure is created manually. Run this to add platform-specific folders:
```bash
cd frontend
flutter create . --platforms=windows,android,ios
```

### 3. Initialize Supabase Locally
```bash
cd ../backend/supabase
supabase init
supabase start
```

This will start a local Supabase instance with:
- PostgreSQL database
- Auth service
- Storage
- Edge Functions (optional)

Note the output - you'll need the API URL and anon key.

### 4. Apply Database Migrations
```bash
cd backend/supabase
supabase db reset
```

This applies all migrations in `backend/supabase/migrations/`.

### 5. Configure Environment

Create a `.env` file in the `frontend/` directory:
```bash
# frontend/.env (DO NOT COMMIT)
SUPABASE_URL=http://localhost:54321
SUPABASE_ANON_KEY=your-local-anon-key-from-supabase-start
```

For production, you'll use your actual Supabase project URL and key.

### 6. Install Flutter Dependencies
```bash
cd frontend
flutter pub get
```

### 7. Generate Code
Run build_runner to generate freezed, json_serializable, riverpod, and drift code:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

For ongoing development, use watch mode:
```bash
flutter pub run build_runner watch --delete-conflicting-outputs
```

## Running the App

### Windows Desktop
```bash
cd frontend
flutter run -d windows
```

### Android Emulator
```bash
flutter run -d <emulator-id>
# List available devices: flutter devices
```

### iOS Simulator (macOS only)
```bash
flutter run -d <simulator-id>
```

### With Environment Variables
```bash
flutter run \
  --dart-define=SUPABASE_URL=http://localhost:54321 \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

## Development Workflow

### 1. Making Database Changes

Create a new migration:
```bash
cd backend/supabase
supabase migration new your_migration_name
```

Edit the generated SQL file, then apply:
```bash
supabase db reset
```

### 2. Updating Drift Schema

After changing Drift table definitions, regenerate:
```bash
cd frontend
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. Adding New Features

Follow the Clean Architecture pattern:
1. Create entity in `domain/entities/`
2. Define repository interface in `domain/repositories/`
3. Implement data models in `data/models/`
4. Create data sources in `data/datasources/`
5. Implement repository in `data/repositories/`
6. Create providers in `presentation/providers/`
7. Build UI in `presentation/pages/` and `presentation/widgets/`

### 4. Running Tests
```bash
# All tests
flutter test

# Specific test file
flutter test test/unit/workout_set_test.dart

# With coverage
flutter test --coverage
```

## Common Commands

| Command | Description |
|---------|-------------|
| `flutter pub get` | Install dependencies |
| `flutter pub run build_runner build` | Generate code |
| `flutter pub run build_runner watch` | Watch mode for code gen |
| `flutter run -d windows` | Run on Windows |
| `flutter test` | Run all tests |
| `supabase start` | Start local Supabase |
| `supabase stop` | Stop local Supabase |
| `supabase db reset` | Reset and apply migrations |
| `supabase migration new <name>` | Create new migration |

## Troubleshooting

### Build Runner Conflicts
If you get conflicts during code generation:
```bash
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### Supabase Connection Issues
1. Ensure Supabase is running: `supabase status`
2. Check URL and key match what's in your config
3. For local dev, use `http://localhost:54321` (not https)

### Flutter Desktop Not Working
Enable desktop support:
```bash
flutter config --enable-windows-desktop
flutter config --enable-macos-desktop
flutter config --enable-linux-desktop
```

### Drift Database Issues
Delete the local database file and restart:
- Windows: `%APPDATA%\liftlink\liftlink.db`
- macOS: `~/Library/Application Support/liftlink/liftlink.db`
- Linux: `~/.local/share/liftlink/liftlink.db`

## VS Code Extensions (Recommended)

- Flutter
- Dart
- Freezed (for syntax highlighting)
- Error Lens
- GitLens

## Project Structure Reference

```
LiftLink/
├── frontend/               # Flutter app
│   ├── lib/
│   │   ├── main.dart
│   │   ├── app.dart
│   │   ├── core/           # Shared infrastructure
│   │   ├── features/       # Feature modules
│   │   └── shared/         # Shared components
│   ├── test/
│   ├── pubspec.yaml
│   └── analysis_options.yaml
│
├── backend/
│   └── supabase/
│       ├── migrations/     # SQL migrations
│       └── config.toml     # Supabase config
│
└── docs/                   # Documentation
    ├── architecture.md
    ├── database-schema.md
    └── setup-guide.md
```
