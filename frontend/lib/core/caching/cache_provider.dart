import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'cache_manager.dart';

part 'cache_provider.g.dart';

/// Global cache manager provider for application-wide caching.
///
/// This provider maintains a single instance of [CacheManager] throughout
/// the application lifecycle, enabling consistent caching across all features.
///
/// Example usage:
/// ```dart
/// // In a repository or service
/// final cache = ref.read(cacheManagerProvider);
///
/// // Check cache before database query
/// final cachedData = cache.get<List<Workout>>('recent_workouts');
/// if (cachedData != null) return cachedData;
///
/// // Query database and cache result
/// final data = await database.getRecentWorkouts();
/// cache.set('recent_workouts', data, Duration(minutes: 5));
/// ```
@Riverpod(keepAlive: true)
CacheManager cacheManager(CacheManagerRef ref) {
  return CacheManager();
}
