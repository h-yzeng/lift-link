/// Cache manager for storing and retrieving query results with TTL (Time To Live).
///
/// This class provides a simple in-memory caching mechanism to reduce redundant
/// database queries and improve application performance.
///
/// Example usage:
/// ```dart
/// final cacheManager = CacheManager();
///
/// // Store data with 5 minute TTL
/// cacheManager.set('user_workouts', workouts, Duration(minutes: 5));
///
/// // Retrieve cached data
/// final cachedWorkouts = cacheManager.get<List<Workout>>('user_workouts');
/// ```
class CacheManager {
  final Map<String, _CacheEntry> _cache = {};

  /// Retrieves cached data for the given [key].
  ///
  /// Returns null if:
  /// - Key doesn't exist in cache
  /// - Cached data has expired
  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;

    if (entry.isExpired) {
      _cache.remove(key);
      return null;
    }

    return entry.data as T?;
  }

  /// Stores [data] in cache with the given [key] and [ttl].
  ///
  /// If [ttl] is null, data will be cached indefinitely.
  void set<T>(String key, T data, [Duration? ttl]) {
    final expiry = ttl != null ? DateTime.now().add(ttl) : null;
    _cache[key] = _CacheEntry(data: data, expiry: expiry);
  }

  /// Removes cached data for the given [key].
  void invalidate(String key) {
    _cache.remove(key);
  }

  /// Removes all cached data matching the [pattern].
  ///
  /// Example:
  /// ```dart
  /// // Invalidate all workout-related caches
  /// cacheManager.invalidatePattern('workout_');
  /// ```
  void invalidatePattern(String pattern) {
    _cache.removeWhere((key, _) => key.contains(pattern));
  }

  /// Clears all cached data.
  void clear() {
    _cache.clear();
  }

  /// Returns the number of cached entries.
  int get size => _cache.length;

  /// Removes all expired entries from the cache.
  void cleanExpired() {
    _cache.removeWhere((_, entry) => entry.isExpired);
  }
}

/// Internal cache entry with optional expiry time.
class _CacheEntry {
  final Object? data;
  final DateTime? expiry;

  _CacheEntry({required this.data, this.expiry});

  bool get isExpired {
    if (expiry == null) return false;
    return DateTime.now().isAfter(expiry!);
  }
}
