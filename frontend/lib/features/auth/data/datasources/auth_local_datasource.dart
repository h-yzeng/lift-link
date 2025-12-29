import 'package:shared_preferences/shared_preferences.dart';
import 'package:liftlink/core/error/exceptions.dart';

/// Local data source for caching authentication state
abstract class AuthLocalDataSource {
  /// Get cached user ID
  Future<String?> getCachedUserId();

  /// Cache user ID
  Future<void> cacheUserId(String userId);

  /// Clear cached user data
  Future<void> clearCache();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SharedPreferences sharedPreferences;

  static const String _cachedUserIdKey = 'CACHED_USER_ID';

  AuthLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<String?> getCachedUserId() async {
    try {
      return sharedPreferences.getString(_cachedUserIdKey);
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> cacheUserId(String userId) async {
    try {
      await sharedPreferences.setString(_cachedUserIdKey, userId);
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await sharedPreferences.remove(_cachedUserIdKey);
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }
}
