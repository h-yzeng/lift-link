import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liftlink/features/auth/presentation/providers/auth_providers.dart';
import 'package:liftlink/features/profile/domain/usecases/update_profile.dart';
import 'package:liftlink/features/profile/presentation/providers/profile_providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  Future<void> _editUsername(BuildContext context, WidgetRef ref, String? currentUsername, String userId) async {
    final controller = TextEditingController(text: currentUsername);

    final username = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Username'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 30,
          decoration: const InputDecoration(
            labelText: 'Username',
            hintText: 'Enter your username',
            prefixText: '@',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (username == null || !context.mounted) return;

    final updateUseCase = ref.read(updateProfileProvider);
    final result = await updateUseCase(
      UpdateProfileParams(
        userId: userId,
        username: username.isEmpty ? null : username,
      ),
    );

    if (!context.mounted) return;

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message ?? 'Failed to update username'),
            backgroundColor: Colors.red,
          ),
        );
      },
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Username updated'),
          ),
        );
        ref.invalidate(currentProfileProvider);
      },
    );
  }

  Future<void> _editDisplayName(BuildContext context, WidgetRef ref, String? currentDisplayName, String userId) async {
    final controller = TextEditingController(text: currentDisplayName);

    final displayName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Display Name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 50,
          decoration: const InputDecoration(
            labelText: 'Display Name',
            hintText: 'Enter your display name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (displayName == null || !context.mounted) return;

    final updateUseCase = ref.read(updateProfileProvider);
    final result = await updateUseCase(
      UpdateProfileParams(
        userId: userId,
        displayName: displayName.isEmpty ? null : displayName,
      ),
    );

    if (!context.mounted) return;

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message ?? 'Failed to update display name'),
            backgroundColor: Colors.red,
          ),
        );
      },
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Display name updated'),
          ),
        );
        ref.invalidate(currentProfileProvider);
      },
    );
  }

  Future<void> _changePassword(BuildContext context, WidgetRef ref) async {
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: newPasswordController,
              autofocus: true,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                hintText: 'Enter new password',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                hintText: 'Confirm new password',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (newPasswordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Passwords do not match'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.of(context).pop(true);
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );

    if (result != true || !context.mounted) return;

    final updatePasswordUseCase = await ref.read(updatePasswordUseCaseProvider.future);
    final updateResult = await updatePasswordUseCase(newPasswordController.text);

    if (!context.mounted) return;

    updateResult.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message ?? 'Failed to change password'),
            backgroundColor: Colors.red,
          ),
        );
      },
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password changed successfully'),
          ),
        );
      },
    );
  }

  Future<void> _editBio(BuildContext context, WidgetRef ref, String? currentBio, String userId) async {
    final controller = TextEditingController(text: currentBio);

    final bio = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Bio'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 200,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Bio',
            hintText: 'Tell us about yourself',
            alignLabelWithHint: true,
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (bio == null || !context.mounted) return;

    final updateUseCase = ref.read(updateProfileProvider);
    final result = await updateUseCase(
      UpdateProfileParams(
        userId: userId,
        bio: bio.isEmpty ? null : bio,
      ),
    );

    if (!context.mounted) return;

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message ?? 'Failed to update bio'),
            backgroundColor: Colors.red,
          ),
        );
      },
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bio updated'),
          ),
        );
        ref.invalidate(currentProfileProvider);
      },
    );
  }

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
                  userAsync.whenData((user) {
                    if (user != null) {
                      _editUsername(context, ref, profile.username, user.id);
                    }
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.badge),
                title: const Text('Display Name'),
                subtitle: Text(profile.displayName ?? 'Not set'),
                trailing: const Icon(Icons.edit),
                onTap: () {
                  userAsync.whenData((user) {
                    if (user != null) {
                      _editDisplayName(context, ref, profile.displayName, user.id);
                    }
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('Bio'),
                subtitle: Text(profile.bio ?? 'Not set'),
                trailing: const Icon(Icons.edit),
                onTap: () {
                  userAsync.whenData((user) {
                    if (user != null) {
                      _editBio(context, ref, profile.bio, user.id);
                    }
                  });
                },
              ),
              const Divider(),

              // Security Section
              _buildSectionHeader('Security'),
              ListTile(
                leading: const Icon(Icons.lock),
                title: const Text('Change Password'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _changePassword(context, ref),
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
