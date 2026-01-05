import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:liftlink/core/search/search_history_service.dart';
import 'package:liftlink/features/auth/presentation/providers/auth_providers.dart';

part 'search_history_provider.g.dart';

@riverpod
Future<SearchHistoryService> searchHistoryService(
  Ref ref,
) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return SearchHistoryService(prefs);
}

@riverpod
Future<List<String>> recentSearches(
  Ref ref, {
  int limit = 10,
}) async {
  final service = await ref.watch(searchHistoryServiceProvider.future);
  return service.getRecentSearches(limit: limit);
}

@riverpod
Future<List<String>> searchSuggestions(
  Ref ref, {
  required String query,
  int limit = 5,
}) async {
  final service = await ref.watch(searchHistoryServiceProvider.future);
  return service.getSuggestions(query, limit: limit);
}
