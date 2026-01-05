import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:liftlink/features/auth/presentation/providers/auth_providers.dart';

part 'theme_provider.g.dart';

const _themeModeKey = 'theme_mode';

/// Provider for the current theme mode.
@Riverpod(keepAlive: true)
class ThemeModeNotifier extends _$ThemeModeNotifier {
  @override
  FutureOr<ThemeMode> build() async {
    try {
      final prefs = await ref.watch(sharedPreferencesProvider.future);
      final themeModeString = prefs.getString(_themeModeKey);

      if (themeModeString != null) {
        return _stringToThemeMode(themeModeString);
      }
      return ThemeMode.system;
    } catch (e) {
      return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    // Update state optimistically
    state = AsyncValue.data(mode);

    try {
      final prefs = await ref.read(sharedPreferencesProvider.future);
      await prefs.setString(_themeModeKey, _themeModeToString(mode));
    } catch (e) {
      // If save fails, reload from preferences
      ref.invalidateSelf();
    }
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'system';
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
    }
  }

  ThemeMode _stringToThemeMode(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}

/// Extension to get theme mode display name.
extension ThemeModeExtension on ThemeMode {
  String get displayName {
    switch (this) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  IconData get icon {
    switch (this) {
      case ThemeMode.system:
        return Icons.settings_suggest;
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
    }
  }
}
