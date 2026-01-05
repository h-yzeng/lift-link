import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liftlink/core/utils/unit_conversion.dart';
import 'package:liftlink/features/profile/presentation/providers/profile_providers.dart';
import 'package:liftlink/features/workout/domain/entities/personal_record.dart';
import 'package:liftlink/features/workout/presentation/providers/workout_providers.dart';
import 'package:intl/intl.dart';

/// Page displaying all personal records for the user.
class PersonalRecordsPage extends ConsumerWidget {
  const PersonalRecordsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(personalRecordsProvider);
    final profileAsync = ref.watch(currentProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Records'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(personalRecordsProvider),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: recordsAsync.when(
        data: (records) {
          if (records.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.emoji_events_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No Personal Records Yet',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Complete workouts to track your PRs',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            );
          }

          return profileAsync.when(
            data: (profile) {
              final useImperial = profile?.usesImperialUnits ?? true;

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(personalRecordsProvider);
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    final record = records[index];
                    final rank = index + 1;

                    return _PersonalRecordCard(
                      record: record,
                      rank: rank,
                      useImperial: useImperial,
                    );
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) {
              // Default to imperial if profile load fails
              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(personalRecordsProvider);
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    final record = records[index];
                    final rank = index + 1;

                    return _PersonalRecordCard(
                      record: record,
                      rank: rank,
                      useImperial: true,
                    );
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(personalRecordsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PersonalRecordCard extends StatelessWidget {
  final PersonalRecord record;
  final int rank;
  final bool useImperial;

  const _PersonalRecordCard({
    required this.record,
    required this.rank,
    required this.useImperial,
  });

  Color _getRankColor() {
    switch (rank) {
      case 1:
        return Colors.amber; // Gold
      case 2:
        return Colors.grey[400]!; // Silver
      case 3:
        return Colors.brown[300]!; // Bronze
      default:
        return Colors.grey[300]!;
    }
  }

  IconData _getRankIcon() {
    switch (rank) {
      case 1:
      case 2:
      case 3:
        return Icons.emoji_events;
      default:
        return Icons.fitness_center;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Rank badge
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getRankColor(),
                shape: BoxShape.circle,
              ),
              child: Icon(_getRankIcon(), color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),

            // Exercise info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.exerciseName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${record.reps} reps @ ${UnitConversion.formatWeight(record.weight, useImperial)}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateFormat.format(record.achievedAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            // 1RM display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    UnitConversion.formatWeight(record.oneRepMax, useImperial),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '1RM',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
