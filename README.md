<div align="center">

# LiftLink

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)
![Postgres](https://img.shields.io/badge/postgres-%23316192.svg?style=for-the-badge&logo=postgresql&logoColor=white)
![SQLite](https://img.shields.io/badge/sqlite-%2307405e.svg?style=for-the-badge&logo=sqlite&logoColor=white)

![Windows](https://img.shields.io/badge/Windows-0078D6?style=for-the-badge&logo=windows&logoColor=white)
![Web](https://img.shields.io/badge/Web-4285F4?style=for-the-badge&logo=google-chrome&logoColor=white)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![iOS](https://img.shields.io/badge/iOS-000000?style=for-the-badge&logo=ios&logoColor=white)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

A cross-platform fitness tracking app with offline-first architecture built with Flutter and Supabase.

## About

LiftLink is a fitness tracking application featuring an offline-first architecture where the local Drift/SQLite database is the source of truth, with background sync to Supabase for cloud backup and social features.

**Key Features:**

- Workout tracking with automatic 1RM calculation
- Offline-first with cloud sync
- Social features (friends, activity feed)
- Progress analytics and charts
- Cross-platform (Windows, Web, Android, iOS)

## Tech Stack

- **Frontend**: Flutter 3.38+ / Dart 3.2+
- **State Management**: Riverpod (code generation)
- **Local Database**: Drift (SQLite wrapper)
- **Backend**: Supabase (PostgreSQL + Auth + Realtime)
- **Architecture**: Clean Architecture (3-layer)
- **Data Classes**: Freezed + json_serializable
- **Error Handling**: Dartz (`Either<Failure, Result>`)

For detailed architecture and development guidelines, see [.claude/CLAUDE.md](.claude/CLAUDE.md).

## Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) 3.2.0+
- [Dart SDK](https://dart.dev/get-dart) 3.2.0+
- [Supabase CLI](https://supabase.com/docs/guides/cli)
- [Docker Desktop](https://www.docker.com/products/docker-desktop) (for local Supabase)

### Installation

1. Clone the repository

   ```bash
   git clone https://github.com/yourusername/LiftLink.git
   cd LiftLink
   ```

2. Set up Flutter project

   ```bash
   cd frontend
   flutter create . --platforms=windows,android,ios
   flutter pub get
   ```

3. Start local Supabase

   ```bash
   cd ../backend/supabase
   supabase start
   supabase db reset
   ```

4. Generate code

   ```bash
   cd ../../frontend
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

5. Run the app

   ```bash
   flutter run -d windows  # or chrome, edge, android, ios
   ```

### Building for Production

```bash
# Windows Desktop
flutter build windows --release

# Web (PWA)
flutter build web --release

# Android
flutter build apk --release

# iOS
flutter build ios --release
```

### Configuration

Set Supabase credentials via environment variables:

```bash
flutter run \
  --dart-define=SUPABASE_URL=http://localhost:54321 \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

For production, replace with your Supabase Cloud URL and key.

## Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage
```

## Contributing

Contributions are welcome! This project follows Clean Architecture principles and Flutter best practices.

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

See [.claude/CLAUDE.md](.claude/CLAUDE.md) for detailed development guidelines and workflows.

## License

This project is licensed under the MIT License.

## Author

**Henry Zeng**

- GitHub: [@h-yzeng](https://github.com/h-yzeng)
- Email: <thyzeng@gmail.com>
