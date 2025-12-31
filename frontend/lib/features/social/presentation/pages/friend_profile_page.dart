import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liftlink/features/profile/domain/entities/profile.dart';
import 'package:liftlink/features/profile/presentation/providers/profile_providers.dart';
import 'package:liftlink/features/workout/presentation/pages/workout_detail_page.dart';
import 'package:liftlink/features/workout/presentation/providers/workout_providers.dart';
import 'package:liftlink/features/workout/presentation/widgets/workout_summary_card.dart';

/// Page displaying a friend's profile and their recent workouts
class FriendProfilePage extends ConsumerWidget {
  final String friendId;
  final String? nickname;

  const FriendProfilePage({
    required this.friendId,
    this.nickname,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(getProfileProvider);
    final theme = Theme.of(context);

    return FutureBuilder<Profile?>(
      future: profileAsync(friendId).then(
        (result) => result.fold((_) => null, (profile) => profile),
      ),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final displayName = nickname ?? profile?.displayNameOrUsername ?? 'User';

        return Scaffold(
          appBar: AppBar(
            title: Text(displayName),
          ),
          body: Column(
            children: [
              // Profile header
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: theme.colorScheme.primary,
                      backgroundImage: profile?.hasAvatar == true
                          ? NetworkImage(profile!.avatarUrl!)
                          : null,
                      child: profile?.hasAvatar == true
                          ? null
                          : Text(
                              profile?.initials ?? '?',
                              style: const TextStyle(
                                fontSize: 36,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      displayName,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (profile?.hasUsername == true && nickname != null)
                      Text(
                        '@${profile!.username}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    if (profile?.hasBio == true) ...[
                      const SizedBox(height: 8),
                      Text(
                        profile!.bio!,
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
              const Divider(height: 1),

              // Recent workouts section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.fitness_center,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Recent Workouts',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Workouts list
              Expanded(
                child: _FriendWorkoutsList(friendId: friendId),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FriendWorkoutsList extends ConsumerWidget {
  final String friendId;

  const _FriendWorkoutsList({required this.friendId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final useImperialUnits = profileAsync.valueOrNull?.usesImperialUnits ?? true;

    // Get friend's workout history
    final workoutsAsync = ref.watch(
      userWorkoutHistoryProvider(
        friendId,
        limit: 50,
      ),
    );

    return workoutsAsync.when(
      data: (friendWorkouts) {

        if (friendWorkouts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.fitness_center,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'No workouts yet',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(userWorkoutHistoryProvider);
          },
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: friendWorkouts.length,
            itemBuilder: (context, index) {
              final workout = friendWorkouts[index];
              return WorkoutSummaryCard(
                workout: workout,
                useImperialUnits: useImperialUnits,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => WorkoutDetailPage(workout: workout),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading workouts'),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref.invalidate(userWorkoutHistoryProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
