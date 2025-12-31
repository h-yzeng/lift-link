import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liftlink/core/theme/theme_provider.dart';
import 'package:liftlink/features/auth/presentation/pages/main_scaffold.dart';
import 'package:liftlink/features/auth/presentation/pages/login_page.dart';
import 'package:liftlink/features/auth/presentation/providers/auth_providers.dart';

class LiftLinkApp extends ConsumerWidget {
  const LiftLinkApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch auth state changes
    final authStateAsync = ref.watch(authStateChangesProvider);
    // Watch theme mode
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'LiftLink',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: themeMode,
      home: authStateAsync.when(
        data: (user) {
          // If user is logged in, show main scaffold with bottom navigation
          // Otherwise, show login page
          return user != null ? const MainScaffold() : const LoginPage();
        },
        loading: () => const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
        error: (error, stack) => Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Invalidate provider to retry
                    ref.invalidate(authStateChangesProvider);
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
