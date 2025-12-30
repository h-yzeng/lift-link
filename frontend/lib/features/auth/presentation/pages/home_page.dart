import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liftlink/core/error/failures.dart';
import 'package:liftlink/features/auth/presentation/providers/auth_providers.dart';
import 'package:liftlink/features/profile/presentation/pages/settings_page.dart';
import 'package:liftlink/features/workout/presentation/pages/active_workout_page.dart';
import 'package:liftlink/features/workout/presentation/pages/exercise_list_page.dart';
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
            SnackBar(content: Text(failure.userMessage)),
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
    final userAsync = ref.watch(currentUserProvider);
    final activeWorkoutAsync = ref.watch(activeWorkoutProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('LiftLink'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SettingsPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: userAsync.when(
        data: (userData) {
          if (userData == null) {
            return const Center(
              child: Text('Not logged in'),
            );
          }

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: userData.avatarUrl != null
                        ? NetworkImage(userData.avatarUrl!)
                        : null,
                    child: userData.avatarUrl == null
                        ? const Icon(Icons.person, size: 50)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    userData.displayNameOrFallback,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    userData.email,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),

                  // Active workout card
                  activeWorkoutAsync.when(
                    data: (activeWorkout) {
                      if (activeWorkout != null) {
                        return Card(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ActiveWorkoutPage(workout: activeWorkout),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.play_circle,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Active Workout',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onPrimaryContainer,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    activeWorkout.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimaryContainer,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${activeWorkout.exerciseCount} exercises • ${activeWorkout.totalSets} sets • ${activeWorkout.formattedDuration}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimaryContainer,
                                        ),
                                  ),
                                  const SizedBox(height: 12),
                                  FilledButton.icon(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ActiveWorkoutPage(
                                                  workout: activeWorkout,),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.arrow_forward),
                                    label: const Text('Continue Workout'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome to LiftLink!',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Your fitness tracking journey starts here.',
                              ),
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                onPressed: () => _startWorkout(context, ref),
                                icon: const Icon(Icons.play_arrow),
                                label: const Text('Start Workout'),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ExerciseListPage(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.fitness_center),
                                label: const Text('Browse Exercise Library'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    loading: () => const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ),
                    error: (_, __) => Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: FilledButton.icon(
                          onPressed: () => _startWorkout(context, ref),
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Start Workout'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }
}
