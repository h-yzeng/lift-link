import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:liftlink/core/utils/unit_conversion.dart';
import 'package:liftlink/features/profile/presentation/providers/profile_providers.dart';
import 'package:liftlink/features/workout/presentation/providers/workout_providers.dart';
import 'package:intl/intl.dart';

/// Page displaying progress analytics with various charts.
class ProgressChartsPage extends ConsumerStatefulWidget {
  const ProgressChartsPage({super.key});

  @override
  ConsumerState<ProgressChartsPage> createState() => _ProgressChartsPageState();
}

class _ProgressChartsPageState extends ConsumerState<ProgressChartsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress Analytics'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Volume', icon: Icon(Icons.trending_up)),
            Tab(text: '1RM', icon: Icon(Icons.show_chart)),
            Tab(text: 'Frequency', icon: Icon(Icons.calendar_today)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _VolumeChartTab(),
          _OneRMChartTab(),
          _FrequencyChartTab(),
        ],
      ),
    );
  }
}

/// Tab showing total volume over time.
class _VolumeChartTab extends ConsumerWidget {
  const _VolumeChartTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutsAsync = ref.watch(workoutHistoryProvider(limit: 30));
    final profileAsync = ref.watch(currentProfileProvider);

    return workoutsAsync.when(
      data: (workouts) {
        if (workouts.isEmpty) {
          return const Center(child: Text('No workout data available'));
        }

        // Prepare chart data - most recent workouts first, reverse for chronological
        final sortedWorkouts = workouts.reversed.toList();
        final spots = <FlSpot>[];

        for (var i = 0; i < sortedWorkouts.length; i++) {
          final workout = sortedWorkouts[i];
          spots.add(FlSpot(i.toDouble(), workout.totalVolume));
        }

        return profileAsync.when(
          data: (profile) {
            final useImperial = profile?.usesImperialUnits ?? true;

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Volume Over Time',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Last ${sortedWorkouts.length} workouts',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: true,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Colors.grey.withValues(alpha: 0.2),
                              strokeWidth: 1,
                            );
                          },
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 60,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  UnitConversion.formatWeight(
                                    value,
                                    useImperial,
                                  ),
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index < 0 ||
                                    index >= sortedWorkouts.length) {
                                  return const Text('');
                                }
                                final workout = sortedWorkouts[index];
                                final date = DateFormat(
                                  'M/d',
                                ).format(workout.startedAt);
                                return Text(
                                  date,
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: true),
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            color: Theme.of(context).colorScheme.primary,
                            barWidth: 3,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.1),
                            ),
                          ),
                        ],
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipItems: (touchedSpots) {
                              return touchedSpots.map((spot) {
                                final index = spot.x.toInt();
                                if (index < 0 ||
                                    index >= sortedWorkouts.length) {
                                  return null;
                                }
                                final workout = sortedWorkouts[index];
                                return LineTooltipItem(
                                  '${workout.title}\n${UnitConversion.formatWeight(spot.y, useImperial)}',
                                  const TextStyle(color: Colors.white),
                                );
                              }).toList();
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const Center(child: Text('Error loading profile')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }
}

/// Tab showing 1RM progression for selected exercise.
class _OneRMChartTab extends ConsumerStatefulWidget {
  const _OneRMChartTab();

  @override
  ConsumerState<_OneRMChartTab> createState() => _OneRMChartTabState();
}

class _OneRMChartTabState extends ConsumerState<_OneRMChartTab> {
  String? _selectedExerciseId;

  @override
  Widget build(BuildContext context) {
    final workoutsAsync = ref.watch(workoutHistoryProvider(limit: 100));
    final profileAsync = ref.watch(currentProfileProvider);

    return workoutsAsync.when(
      data: (workouts) {
        if (workouts.isEmpty) {
          return const Center(child: Text('No workout data available'));
        }

        // Get all unique exercises from workouts
        final exerciseMap = <String, String>{};
        for (final workout in workouts) {
          for (final exercise in workout.exercises) {
            exerciseMap[exercise.exerciseId] = exercise.exerciseName;
          }
        }

        if (exerciseMap.isEmpty) {
          return const Center(child: Text('No exercises found in workouts'));
        }

        // Set default selected exercise if none selected
        _selectedExerciseId ??= exerciseMap.keys.first;

        // Filter workouts that contain the selected exercise
        final exerciseWorkouts = workouts.where((workout) {
          return workout.exercises.any(
            (e) => e.exerciseId == _selectedExerciseId,
          );
        }).toList();

        // Sort chronologically
        exerciseWorkouts.sort((a, b) => a.startedAt.compareTo(b.startedAt));

        // Build chart data
        final spots = <FlSpot>[];
        for (var i = 0; i < exerciseWorkouts.length; i++) {
          final workout = exerciseWorkouts[i];
          final exercise = workout.exercises.firstWhere(
            (e) => e.exerciseId == _selectedExerciseId,
          );

          final maxOneRM = exercise.maxOneRM;
          if (maxOneRM != null) {
            spots.add(FlSpot(i.toDouble(), maxOneRM));
          }
        }

        if (spots.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('No 1RM data for selected exercise'),
                const SizedBox(height: 16),
                _buildExerciseDropdown(exerciseMap),
              ],
            ),
          );
        }

        return profileAsync.when(
          data: (profile) {
            final useImperial = profile?.usesImperialUnits ?? true;

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '1RM Progression',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildExerciseDropdown(exerciseMap),
                  const SizedBox(height: 24),
                  Expanded(
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: true,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Colors.grey.withValues(alpha: 0.2),
                              strokeWidth: 1,
                            );
                          },
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 60,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  UnitConversion.formatWeight(
                                    value,
                                    useImperial,
                                  ),
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index < 0 ||
                                    index >= exerciseWorkouts.length) {
                                  return const Text('');
                                }
                                final workout = exerciseWorkouts[index];
                                final date = DateFormat(
                                  'M/d',
                                ).format(workout.startedAt);
                                return Text(
                                  date,
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: true),
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            color: Colors.green,
                            barWidth: 3,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.green.withValues(alpha: 0.1),
                            ),
                          ),
                        ],
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipItems: (touchedSpots) {
                              return touchedSpots.map((spot) {
                                final index = spot.x.toInt();
                                if (index < 0 ||
                                    index >= exerciseWorkouts.length) {
                                  return null;
                                }
                                final workout = exerciseWorkouts[index];
                                return LineTooltipItem(
                                  '${DateFormat('MMM d').format(workout.startedAt)}\n${UnitConversion.formatWeight(spot.y, useImperial)}',
                                  const TextStyle(color: Colors.white),
                                );
                              }).toList();
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const Center(child: Text('Error loading profile')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildExerciseDropdown(Map<String, String> exerciseMap) {
    final entries = exerciseMap.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    return DropdownButtonFormField<String>(
      initialValue: _selectedExerciseId,
      decoration: const InputDecoration(
        labelText: 'Select Exercise',
        border: OutlineInputBorder(),
      ),
      items: entries.map((entry) {
        return DropdownMenuItem(value: entry.key, child: Text(entry.value));
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedExerciseId = value;
        });
      },
    );
  }
}

/// Tab showing workout frequency over time.
class _FrequencyChartTab extends ConsumerWidget {
  const _FrequencyChartTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutsAsync = ref.watch(workoutHistoryProvider(limit: 90));

    return workoutsAsync.when(
      data: (workouts) {
        if (workouts.isEmpty) {
          return const Center(child: Text('No workout data available'));
        }

        // Group workouts by week
        final weeklyData = <DateTime, int>{};
        for (final workout in workouts) {
          if (!workout.isCompleted) continue;

          // Get the start of the week (Monday)
          final completedDate = workout.completedAt!;
          final weekday = completedDate.weekday;
          final startOfWeek = completedDate.subtract(
            Duration(days: weekday - 1),
          );
          final weekKey = DateTime(
            startOfWeek.year,
            startOfWeek.month,
            startOfWeek.day,
          );

          weeklyData[weekKey] = (weeklyData[weekKey] ?? 0) + 1;
        }

        // Sort weeks chronologically
        final sortedWeeks = weeklyData.keys.toList()
          ..sort((a, b) => a.compareTo(b));

        if (sortedWeeks.isEmpty) {
          return const Center(child: Text('No completed workouts found'));
        }

        // Build bar chart data
        final barGroups = <BarChartGroupData>[];
        for (var i = 0; i < sortedWeeks.length; i++) {
          final week = sortedWeeks[i];
          final count = weeklyData[week]!;

          barGroups.add(
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: count.toDouble(),
                  color: Theme.of(context).colorScheme.primary,
                  width: 16,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Workout Frequency',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Workouts per week over time',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: BarChart(
                  BarChartData(
                    barGroups: barGroups,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.grey.withValues(alpha: 0.2),
                          strokeWidth: 1,
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toInt().toString(),
                              style: const TextStyle(fontSize: 12),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= sortedWeeks.length) {
                              return const Text('');
                            }
                            final week = sortedWeeks[index];
                            final date = DateFormat('M/d').format(week);
                            return Text(
                              date,
                              style: const TextStyle(fontSize: 10),
                            );
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: true),
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final week = sortedWeeks[group.x];
                          final count = rod.toY.toInt();
                          return BarTooltipItem(
                            'Week of ${DateFormat('MMM d').format(week)}\n$count workout${count == 1 ? '' : 's'}',
                            const TextStyle(color: Colors.white),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }
}
