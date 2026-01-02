import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing exercise search history and suggestions
class SearchHistoryService {
  final SharedPreferences _prefs;
  final List<String> _recentSearches = [];
  final int _maxHistorySize = 20;

  static const String _historyKey = 'search_history';

  SearchHistoryService(this._prefs) {
    _loadHistory();
  }

  /// Load search history from persistent storage
  Future<void> _loadHistory() async {
    try {
      final historyJson = _prefs.getString(_historyKey);
      if (historyJson != null) {
        final decoded = jsonDecode(historyJson) as List<dynamic>;
        _recentSearches.clear();
        _recentSearches.addAll(decoded.cast<String>());
      }
    } catch (e) {
      // If loading fails, start with empty history
      _recentSearches.clear();
    }
  }

  /// Save search history to persistent storage
  Future<void> _saveHistory() async {
    try {
      final historyJson = jsonEncode(_recentSearches);
      await _prefs.setString(_historyKey, historyJson);
    } catch (e) {
      // Silently fail - search history is a nice-to-have feature
    }
  }

  /// Add a search query to the history
  Future<void> addSearch(String query) async {
    if (query.trim().isEmpty) return;

    final trimmedQuery = query.trim().toLowerCase();

    // Remove existing occurrence to avoid duplicates
    _recentSearches.remove(trimmedQuery);

    // Add to the front
    _recentSearches.insert(0, trimmedQuery);

    // Limit history size
    if (_recentSearches.length > _maxHistorySize) {
      _recentSearches.removeRange(_maxHistorySize, _recentSearches.length);
    }

    await _saveHistory();
  }

  /// Get recent searches
  List<String> getRecentSearches({int limit = 10}) {
    return _recentSearches.take(limit).toList();
  }

  /// Get search suggestions based on a query
  List<String> getSuggestions(String query, {int limit = 5}) {
    if (query.trim().isEmpty) {
      return getRecentSearches(limit: limit);
    }

    final trimmedQuery = query.trim().toLowerCase();

    // Filter searches that start with the query
    final suggestions = _recentSearches
        .where((search) => search.startsWith(trimmedQuery))
        .take(limit)
        .toList();

    return suggestions;
  }

  /// Remove a search from history
  Future<void> removeSearch(String query) async {
    _recentSearches.remove(query.trim().toLowerCase());
    await _saveHistory();
  }

  /// Clear all search history
  Future<void> clearHistory() async {
    _recentSearches.clear();
    await _saveHistory();
  }

  /// Get the total number of searches in history
  int get historySize => _recentSearches.length;

  /// Check if history is empty
  bool get isEmpty => _recentSearches.isEmpty;
}
