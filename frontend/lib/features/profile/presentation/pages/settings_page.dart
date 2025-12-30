import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liftlink/features/auth/presentation/providers/auth_providers.dart';
import 'package:liftlink/features/profile/domain/usecases/update_profile.dart';
import 'package:liftlink/features/profile/presentation/providers/profile_providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(
              child: Text('Profile not found'),
            );
          }

          return ListView(
            children: [
              // Unit Preference Section
              _buildSectionHeader('Preferences'),
              SwitchListTile(
                title: const Text('Use Imperial Units'),
                subtitle: Text(
                  profile.usesImperialUnits
                      ? 'Pounds (lbs), Feet, Inches'
                      : 'Kilograms (kg), Centimeters',
                ),
                value: profile.usesImperialUnits,
                onChanged: (value) async {
                  final newUnits = value ? 'imperial' : 'metric';

                  userAsync.when(
                    data: (user) async {
                      if (user != null) {
                        final updateUseCase = ref.read(updateProfileProvider);
                        await updateUseCase(
                          UpdateProfileParams(
                            userId: user.id,
                            preferredUnits: newUnits,
                          ),
                        );
                        // Invalidate profile to refresh
                        ref.invalidate(currentProfileProvider);
                      }
                    },
                    loading: () {},
                    error: (_, __) {},
                  );
                },
              ),
              const Divider(),

              // Profile Section
              _buildSectionHeader('Profile'),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Username'),
                subtitle: Text(profile.username ?? 'Not set'),
                trailing: const Icon(Icons.edit),
                onTap: () {
                  // TODO: Navigate to edit username page
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Edit username - Coming soon'),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.badge),
                title: const Text('Display Name'),
                subtitle: Text(profile.displayName ?? 'Not set'),
                trailing: const Icon(Icons.edit),
                onTap: () {
                  // TODO: Navigate to edit display name page
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Edit display name - Coming soon'),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('Bio'),
                subtitle: Text(profile.bio ?? 'Not set'),
                trailing: const Icon(Icons.edit),
                onTap: () {
                  // TODO: Navigate to edit bio page
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Edit bio - Coming soon'),
                    ),
                  );
                },
              ),
              const Divider(),

              // About Section
              _buildSectionHeader('About'),
              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('App Version'),
                subtitle: Text('1.0.0'),
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () async {
                            final logoutUseCase =
                                await ref.read(logoutUseCaseProvider.future);
                            await logoutUseCase();
                            if (context.mounted) {
                              Navigator.pop(context);
                              Navigator.pop(context); // Go back to home
                            }
                          },
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading settings: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(currentProfileProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }
}
