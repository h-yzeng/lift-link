import 'package:freezed_annotation/freezed_annotation.dart';

part 'merge_strategy.freezed.dart';

/// Strategy for resolving sync conflicts
enum MergeStrategy {
  /// Use local version (client wins)
  useLocal,

  /// Use remote version (server wins)
  useRemote,

  /// Merge field-by-field (newest field wins)
  fieldLevel,

  /// Last write wins based on timestamp (current default)
  lastWriteWins,

  /// Manual resolution required (show UI)
  manual,
}

/// Conflict resolution result
@freezed
class MergeResult<T> with _$MergeResult<T> {
  const factory MergeResult.resolved(T mergedEntity) = _Resolved;
  const factory MergeResult.needsManualResolution({
    required T localVersion,
    required T remoteVersion,
    required List<String> conflictingFields,
  }) = _NeedsManualResolution;
}
