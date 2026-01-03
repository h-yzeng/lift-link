import 'package:liftlink/core/sync/merge_strategy.dart';
import 'package:liftlink/features/workout/domain/entities/workout_session.dart';
import 'package:liftlink/features/profile/domain/entities/profile.dart';

/// Handles field-level merging of entities during sync conflicts
class EntityMerger {
  /// Merge two workout sessions using the specified strategy
  static MergeResult<WorkoutSession> mergeWorkoutSession(
    WorkoutSession local,
    WorkoutSession remote,
    MergeStrategy strategy,
  ) {
    if (strategy == MergeStrategy.useLocal) {
      return MergeResult.resolved(local);
    }

    if (strategy == MergeStrategy.useRemote) {
      return MergeResult.resolved(remote);
    }

    if (strategy == MergeStrategy.lastWriteWins) {
      final useLocal = local.updatedAt.isAfter(remote.updatedAt);
      return MergeResult.resolved(useLocal ? local : remote);
    }

    // Field-level merge
    final conflictingFields = <String>[];

    // Check each field for conflicts
    final title = _mergeField(
      local.title,
      remote.title,
      local.updatedAt,
      remote.updatedAt,
      'title',
      conflictingFields,
    );

    final notes = _mergeField(
      local.notes,
      remote.notes,
      local.updatedAt,
      remote.updatedAt,
      'notes',
      conflictingFields,
    );

    // If critical fields conflict, require manual resolution
    if (conflictingFields.isNotEmpty && strategy == MergeStrategy.manual) {
      return MergeResult.needsManualResolution(
        localVersion: local,
        remoteVersion: remote,
        conflictingFields: conflictingFields,
      );
    }

    // Merge successful - use field-level merged values
    return MergeResult.resolved(
      local.copyWith(
        title: title,
        notes: notes,
        // Exercises: use local list (more likely to be current during active workout)
        // Use latest updatedAt timestamp
        updatedAt: local.updatedAt.isAfter(remote.updatedAt)
            ? local.updatedAt
            : remote.updatedAt,
      ),
    );
  }

  /// Merge two profiles using the specified strategy
  static MergeResult<Profile> mergeProfile(
    Profile local,
    Profile remote,
    MergeStrategy strategy,
  ) {
    if (strategy == MergeStrategy.useLocal) {
      return MergeResult.resolved(local);
    }

    if (strategy == MergeStrategy.useRemote) {
      return MergeResult.resolved(remote);
    }

    if (strategy == MergeStrategy.lastWriteWins) {
      final useLocal = local.updatedAt.isAfter(remote.updatedAt);
      return MergeResult.resolved(useLocal ? local : remote);
    }

    // Field-level merge for profile
    final conflictingFields = <String>[];

    final displayName = _mergeField(
      local.displayName,
      remote.displayName,
      local.updatedAt,
      remote.updatedAt,
      'displayName',
      conflictingFields,
    );

    final bio = _mergeField(
      local.bio,
      remote.bio,
      local.updatedAt,
      remote.updatedAt,
      'bio',
      conflictingFields,
    );

    final preferredUnits = _mergeField(
      local.preferredUnits,
      remote.preferredUnits,
      local.updatedAt,
      remote.updatedAt,
      'preferredUnits',
      conflictingFields,
    );

    // If critical fields conflict with manual strategy, require resolution
    if (conflictingFields.isNotEmpty && strategy == MergeStrategy.manual) {
      return MergeResult.needsManualResolution(
        localVersion: local,
        remoteVersion: remote,
        conflictingFields: conflictingFields,
      );
    }

    // Merge successful
    return MergeResult.resolved(
      local.copyWith(
        displayName: displayName,
        bio: bio,
        preferredUnits: preferredUnits,
        updatedAt: local.updatedAt.isAfter(remote.updatedAt)
            ? local.updatedAt
            : remote.updatedAt,
      ),
    );
  }

  /// Merge a single field using timestamp-based resolution
  static T _mergeField<T>(
    T localValue,
    T remoteValue,
    DateTime localTime,
    DateTime remoteTime,
    String fieldName,
    List<String> conflictingFields,
  ) {
    // If values are the same, no conflict
    if (localValue == remoteValue) return localValue;

    // If values differ, use the one with newest timestamp
    if (localTime.isAfter(remoteTime)) {
      return localValue;
    } else if (remoteTime.isAfter(localTime)) {
      return remoteValue;
    } else {
      // Same timestamp but different values - true conflict!
      conflictingFields.add(fieldName);
      return localValue; // Fallback to local
    }
  }
}
