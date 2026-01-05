import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:liftlink/features/workout/domain/entities/exercise.dart';
import 'package:liftlink/features/workout/presentation/providers/exercise_providers.dart';
import 'package:liftlink/features/workout/presentation/providers/workout_providers.dart';

/// Page displaying muscle frequency analysis.
class MuscleFrequencyPage extends ConsumerWidget {
  const MuscleFrequencyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutsAsync = ref.watch(workoutHistoryProvider(limit: 100));
    final exercisesAsync = ref.watch(exerciseListProvider());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Muscle Frequency'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(workoutHistoryProvider);
              ref.invalidate(exerciseListProvider);
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: workoutsAsync.when(
        data: (workouts) {
          if (workouts.isEmpty) {
            return const Center(child: Text('No workout data available'));
          }

          return exercisesAsync.when(
            data: (exercises) {
              // Build a map of exercise ID to muscle group
              final exerciseMap = <String, String>{};
              for (final exercise in exercises) {
                exerciseMap[exercise.id] = exercise.muscleGroup;
              }

              // Count muscle group frequencies from workouts
              final muscleGroupCounts = <String, int>{};

              for (final workout in workouts) {
                if (!workout.isCompleted) continue;

                final seenInWorkout = <String>{};
                for (final exercise in workout.exercises) {
                  final muscleGroup =
                      exerciseMap[exercise.exerciseId] ?? 'unknown';

                  // Count each muscle group once per workout
                  if (!seenInWorkout.contains(muscleGroup)) {
                    muscleGroupCounts[muscleGroup] =
                        (muscleGroupCounts[muscleGroup] ?? 0) + 1;
                    seenInWorkout.add(muscleGroup);
                  }
                }
              }

              if (muscleGroupCounts.isEmpty) {
                return const Center(
                  child: Text('No muscle group data available'),
                );
              }

              // Sort by frequency descending
              final sortedEntries = muscleGroupCounts.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));

              final total = sortedEntries.fold<int>(
                0,
                (sum, entry) => sum + entry.value,
              );

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Muscle Group Training Frequency',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Based on last ${workouts.where((w) => w.isCompleted).length} workouts',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 32),

                    // Pie Chart
                    SizedBox(
                      height: 300,
                      child: PieChart(
                        PieChartData(
                          sections: _buildPieSections(
                            sortedEntries,
                            total,
                            context,
                          ),
                          sectionsSpace: 2,
                          centerSpaceRadius: 60,
                          pieTouchData: PieTouchData(
                            touchCallback:
                                (FlTouchEvent event, pieTouchResponse) {},
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // List of muscle groups with counts
                    Card(
                      child: Column(
                        children: sortedEntries.map((entry) {
                          final percentage = ((entry.value / total) * 100)
                              .toStringAsFixed(1);
                          final color = _getMuscleGroupColor(entry.key);

                          return ListTile(
                            leading: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            title: Text(
                              entry.key[0].toUpperCase() +
                                  entry.key.substring(1),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${entry.value} workouts',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                Text(
                                  '$percentage%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Recommendations
                    if (_hasImbalance(sortedEntries))
                      Card(
                        color: Colors.amber[50],
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.lightbulb_outline,
                                    color: Colors.amber[700],
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Recommendation',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber[900],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Consider training underworked muscle groups more frequently for balanced development.',
                                style: TextStyle(color: Colors.amber[900]),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) =>
                Center(child: Text('Error loading exercises: $error')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(workoutHistoryProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(
    List<MapEntry<String, int>> entries,
    int total,
    BuildContext context,
  ) {
    return entries.map((entry) {
      final percentage = (entry.value / total) * 100;
      final color = _getMuscleGroupColor(entry.key);

      return PieChartSectionData(
        value: entry.value.toDouble(),
        title: '${percentage.toStringAsFixed(0)}%',
        color: color,
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Color _getMuscleGroupColor(String muscleGroup) {
    switch (muscleGroup.toLowerCase()) {
      case MuscleGroups.chest:
        return Colors.red;
      case MuscleGroups.back:
        return Colors.blue;
      case MuscleGroups.legs:
        return Colors.green;
      case MuscleGroups.shoulders:
        return Colors.orange;
      case MuscleGroups.arms:
        return Colors.purple;
      case MuscleGroups.core:
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  bool _hasImbalance(List<MapEntry<String, int>> entries) {
    if (entries.length < 2) return false;

    final highest = entries.first.value;
    final lowest = entries.last.value;

    // If highest is more than 3x the lowest, consider it imbalanced
    return highest > lowest * 3;
  }
}
