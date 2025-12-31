import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liftlink/features/auth/presentation/providers/auth_providers.dart';
import 'package:liftlink/features/profile/presentation/pages/settings_page.dart';
import 'package:liftlink/features/profile/presentation/providers/profile_providers.dart';
import 'package:liftlink/features/social/presentation/pages/social_hub_page.dart';
import 'package:liftlink/features/workout/presentation/pages/active_workout_page.dart';
import 'package:liftlink/features/workout/presentation/pages/exercise_list_page.dart';
import 'package:liftlink/features/workout/presentation/pages/muscle_frequency_page.dart';
import 'package:liftlink/features/workout/presentation/pages/personal_records_page.dart';
import 'package:liftlink/features/workout/presentation/pages/progress_charts_page.dart';
import 'package:liftlink/features/workout/presentation/pages/templates_page.dart';
import 'package:liftlink/features/workout/presentation/pages/workout_history_page.dart';
import 'package:liftlink/features/workout/presentation/providers/workout_providers.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  Future<void> _startWorkout(BuildContext context, WidgetRef ref) async {
    final titleController = TextEditingController(text: 'Workout');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start New Workout'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(
            labelText: 'Workout Title',
            hintText: 'e.g., Push Day, Leg Day',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Start'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final user = await ref.read(currentUserProvider.future);
    if (user == null) return;

    final useCase = ref.read(startWorkoutUseCaseProvider);
    final result = await useCase(
      userId: user.id,
      title: titleController.text.isEmpty ? 'Workout' : titleController.text,
    );

    result.fold(
      (failure) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(failure.message ?? 'Failed to start workout')),
          );
        }
      },
      (workout) {
        if (context.mounted) {
          ref.invalidate(activeWorkoutProvider);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ActiveWorkoutPage(workout: workout),
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final activeWorkoutAsync = ref.watch(activeWorkoutProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('LiftLink'),
      ),
      body: SafeArea(
        child: profileAsync.when(
          data: (profile) {
            final greeting = _getGreeting();
            final displayName = profile?.displayNameOrUsername ?? 'there';

            return Column(
              children: [
                // Greeting header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$greeting,',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        displayName,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Main content
                Expanded(
                  child: activeWorkoutAsync.when(
                    data: (activeWorkout) {
                      if (activeWorkout != null) {
                        // Active workout view
                        return SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _ActiveWorkoutCard(
                                workout: activeWorkout,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ActiveWorkoutPage(workout: activeWorkout),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                              _QuickActionsGrid(
                                onStartNewWorkout: () => _startWorkout(context, ref),
                              ),
                            ],
                          ),
                        );
                      }

                      // No active workout view
                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _StartWorkoutHero(
                              onStartWorkout: () => _startWorkout(context, ref),
                            ),
                            const SizedBox(height: 24),
                            _QuickActionsGrid(
                              onStartNewWorkout: () => _startWorkout(context, ref),
                              showStartWorkout: false,
                            ),
                          ],
                        ),
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (_, __) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: FilledButton.icon(
                          onPressed: () => _startWorkout(context, ref),
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Start Workout'),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                onPressed: () => _startWorkout(context, ref),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Workout'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

class _ActiveWorkoutCard extends StatelessWidget {
  final dynamic workout;
  final VoidCallback onTap;

  const _ActiveWorkoutCard({
    required this.workout,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 4,
      color: theme.colorScheme.primaryContainer,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.play_circle,
                      color: theme.colorScheme.onPrimary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WORKOUT IN PROGRESS',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          workout.title as String,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _WorkoutStat(
                    icon: Icons.fitness_center,
                    label: '${workout.exerciseCount}',
                    subtitle: 'Exercises',
                  ),
                  const SizedBox(width: 20),
                  _WorkoutStat(
                    icon: Icons.format_list_numbered,
                    label: '${workout.totalSets}',
                    subtitle: 'Sets',
                  ),
                  const SizedBox(width: 20),
                  _WorkoutStat(
                    icon: Icons.timer,
                    label: workout.formattedDuration as String,
                    subtitle: 'Duration',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onTap,
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('Continue Workout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkoutStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;

  const _WorkoutStat({
    required this.icon,
    required this.label,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            size: 20,
            color: theme.colorScheme.onPrimaryContainer,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _StartWorkoutHero extends StatelessWidget {
  final VoidCallback onStartWorkout;

  const _StartWorkoutHero({
    required this.onStartWorkout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primaryContainer,
              theme.colorScheme.secondaryContainer,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.fitness_center,
                size: 48,
                color: theme.colorScheme.onPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Ready to train?',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start tracking your workout',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onStartWorkout,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Workout'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  final VoidCallback onStartNewWorkout;
  final bool showStartWorkout;

  const _QuickActionsGrid({
    required this.onStartNewWorkout,
    this.showStartWorkout = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.95,
          children: [
            if (showStartWorkout)
              _QuickActionCard(
                icon: Icons.add_circle,
                label: 'New Workout',
                color: Colors.green,
                onTap: onStartNewWorkout,
              ),
            _QuickActionCard(
              icon: Icons.history,
              label: 'History',
              color: Colors.orange,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const WorkoutHistoryPage(),
                  ),
                );
              },
            ),
            _QuickActionCard(
              icon: Icons.emoji_events,
              label: 'PRs',
              color: Colors.amber,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const PersonalRecordsPage(),
                  ),
                );
              },
            ),
            _QuickActionCard(
              icon: Icons.show_chart,
              label: 'Progress',
              color: Colors.purple,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ProgressChartsPage(),
                  ),
                );
              },
            ),
            _QuickActionCard(
              icon: Icons.pie_chart,
              label: 'Muscles',
              color: Colors.teal,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const MuscleFrequencyPage(),
                  ),
                );
              },
            ),
            _QuickActionCard(
              icon: Icons.people,
              label: 'Social',
              color: Colors.indigo,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SocialHubPage(),
                  ),
                );
              },
            ),
            _QuickActionCard(
              icon: Icons.folder_copy,
              label: 'Templates',
              color: Colors.deepOrange,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const TemplatesPage(),
                  ),
                );
              },
            ),
            _QuickActionCard(
              icon: Icons.search,
              label: 'Exercises',
              color: Colors.blue,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ExerciseListPage(),
                  ),
                );
              },
            ),
            _QuickActionCard(
              icon: Icons.settings,
              label: 'Settings',
              color: Colors.grey,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SettingsPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
