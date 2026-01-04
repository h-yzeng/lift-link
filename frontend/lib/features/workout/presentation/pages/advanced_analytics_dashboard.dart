import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:liftlink/features/workout/domain/entities/workout_session.dart';
import 'package:liftlink/features/workout/presentation/providers/workout_providers.dart';
import 'package:intl/intl.dart';

/// Advanced analytics dashboard with comprehensive workout metrics.
///
/// Displays detailed analytics including:
/// - Training volume trends
/// - Exercise distribution
/// - Personal records timeline
/// - Recovery patterns
/// - Performance insights
class AdvancedAnalyticsDashboard extends ConsumerStatefulWidget {
  const AdvancedAnalyticsDashboard({super.key});

  @override
  ConsumerState<AdvancedAnalyticsDashboard> createState() =>
      _AdvancedAnalyticsDashboardState();
}

class _AdvancedAnalyticsDashboardState
    extends ConsumerState<AdvancedAnalyticsDashboard> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final workoutsAsync = ref.watch(
      workoutHistoryProvider(
        limit: 100,
        startDate: _startDate,
        endDate: _endDate,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () => _selectDateRange(context),
            tooltip: 'Select Date Range',
          ),
        ],
      ),
      body: workoutsAsync.when(
        data: (workouts) {
          if (workouts.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.analytics_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No workout data for selected period',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final analytics = _calculateAnalytics(workouts);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Summary cards
              _buildSummaryCards(analytics),
              const SizedBox(height: 24),

              // Volume trend chart
              _buildVolumeChart(workouts),
              const SizedBox(height: 24),

              // Exercise distribution pie chart
              _buildExerciseDistribution(workouts),
              const SizedBox(height: 24),

              // Workout frequency heatmap
              _buildFrequencyHeatmap(workouts),
              const SizedBox(height: 24),

              // Performance metrics
              _buildPerformanceMetrics(analytics),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('Error: ${error.toString()}'),
        ),
      ),
    );
  }

  /// Opens date range picker dialog.
  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  /// Builds summary metric cards.
  Widget _buildSummaryCards(WorkoutAnalytics analytics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.fitness_center,
                title: 'Total Workouts',
                value: analytics.totalWorkouts.toString(),
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                icon: Icons.schedule,
                title: 'Avg Duration',
                value: '${analytics.avgDuration.round()} min',
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.trending_up,
                title: 'Total Volume',
                value: analytics.totalVolume.toStringAsFixed(0),
                subtitle: 'lbs/kg',
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                icon: Icons.show_chart,
                title: 'Total Sets',
                value: analytics.totalSets.toString(),
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Builds volume trend line chart.
  Widget _buildVolumeChart(List<WorkoutSession> workouts) {
    final sortedWorkouts = workouts.reversed.toList();
    final spots = <FlSpot>[];

    for (var i = 0; i < sortedWorkouts.length; i++) {
      final workout = sortedWorkouts[i];
      double volume = 0;

      for (final exercise in workout.exercises) {
        for (final set in exercise.sets) {
          final weight = set.weight ?? 0;
          final reps = set.reps ?? 0;
          volume += weight * reps;
        }
      }

      spots.add(FlSpot(i.toDouble(), volume));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Volume Trend',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds exercise distribution pie chart.
  Widget _buildExerciseDistribution(List<WorkoutSession> workouts) {
    final exerciseCounts = <String, int>{};

    for (final workout in workouts) {
      for (final exercise in workout.exercises) {
        exerciseCounts[exercise.exerciseName] =
            (exerciseCounts[exercise.exerciseName] ?? 0) + 1;
      }
    }

    final topExercises = exerciseCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top5 = topExercises.take(5).toList();
    final total = top5.fold<int>(0, (sum, entry) => sum + entry.value);

    final sections = top5.asMap().entries.map((entry) {
      final index = entry.key;
      final exercise = entry.value;
      final percentage = (exercise.value / total * 100);

      final colors = [
        Colors.blue,
        Colors.green,
        Colors.orange,
        Colors.purple,
        Colors.red,
      ];

      return PieChartSectionData(
        value: exercise.value.toDouble(),
        title: '${percentage.toStringAsFixed(1)}%',
        color: colors[index % colors.length],
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Exercises',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // Pie chart
                SizedBox(
                  width: 200,
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sections: sections,
                      centerSpaceRadius: 40,
                      sectionsSpace: 2,
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                // Legend
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: top5.asMap().entries.map((entry) {
                      final index = entry.key;
                      final exercise = entry.value;
                      final colors = [
                        Colors.blue,
                        Colors.green,
                        Colors.orange,
                        Colors.purple,
                        Colors.red,
                      ];

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: colors[index % colors.length],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                exercise.key,
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${exercise.value}x',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Builds workout frequency heatmap.
  Widget _buildFrequencyHeatmap(List<WorkoutSession> workouts) {
    final workoutDays = <DateTime>{};
    for (final workout in workouts) {
      if (workout.completedAt != null) {
        final date = DateTime(
          workout.completedAt!.year,
          workout.completedAt!.month,
          workout.completedAt!.day,
        );
        workoutDays.add(date);
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Workout Frequency',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'Training days: ${workoutDays.length}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Avg frequency: ${(workoutDays.length / ((_endDate.difference(_startDate).inDays + 1) / 7)).toStringAsFixed(1)} days/week',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  /// Builds performance metrics section.
  Widget _buildPerformanceMetrics(WorkoutAnalytics analytics) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Insights',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildMetricRow(
              'Longest Workout',
              '${analytics.longestWorkout} min',
              Icons.timer,
            ),
            const Divider(),
            _buildMetricRow(
              'Most Exercises in One Session',
              analytics.maxExercisesPerWorkout.toString(),
              Icons.fitness_center,
            ),
            const Divider(),
            _buildMetricRow(
              'Average Volume per Workout',
              analytics.avgVolumePerWorkout.toStringAsFixed(0),
              Icons.trending_up,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Calculates comprehensive analytics from workouts.
  WorkoutAnalytics _calculateAnalytics(List<WorkoutSession> workouts) {
    int totalWorkouts = workouts.length;
    double totalVolume = 0;
    int totalSets = 0;
    double totalDuration = 0;
    int longestWorkout = 0;
    int maxExercisesPerWorkout = 0;

    for (final workout in workouts) {
      // Duration
      if (workout.durationMinutes != null) {
        totalDuration += workout.durationMinutes!;
        if (workout.durationMinutes! > longestWorkout) {
          longestWorkout = workout.durationMinutes!;
        }
      }

      // Exercises
      if (workout.exercises.length > maxExercisesPerWorkout) {
        maxExercisesPerWorkout = workout.exercises.length;
      }

      // Volume and sets
      for (final exercise in workout.exercises) {
        for (final set in exercise.sets) {
          totalSets++;
          final weight = set.weight ?? 0;
          final reps = set.reps ?? 0;
          totalVolume += weight * reps;
        }
      }
    }

    return WorkoutAnalytics(
      totalWorkouts: totalWorkouts,
      totalVolume: totalVolume,
      totalSets: totalSets,
      avgDuration: totalWorkouts > 0 ? totalDuration / totalWorkouts : 0,
      longestWorkout: longestWorkout,
      maxExercisesPerWorkout: maxExercisesPerWorkout,
      avgVolumePerWorkout: totalWorkouts > 0 ? totalVolume / totalWorkouts : 0,
    );
  }
}

/// Analytics data model.
class WorkoutAnalytics {
  final int totalWorkouts;
  final double totalVolume;
  final int totalSets;
  final double avgDuration;
  final int longestWorkout;
  final int maxExercisesPerWorkout;
  final double avgVolumePerWorkout;

  const WorkoutAnalytics({
    required this.totalWorkouts,
    required this.totalVolume,
    required this.totalSets,
    required this.avgDuration,
    required this.longestWorkout,
    required this.maxExercisesPerWorkout,
    required this.avgVolumePerWorkout,
  });
}

/// Metric card widget for summary statistics.
class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String? subtitle;
  final Color color;

  const _MetricCard({
    required this.icon,
    required this.title,
    required this.value,
    this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
              ),
          ],
        ),
      ),
    );
  }
}
