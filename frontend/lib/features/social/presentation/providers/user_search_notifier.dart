import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:liftlink/core/error/failures.dart';
import 'package:liftlink/features/social/presentation/providers/user_search_state.dart';
import 'package:liftlink/features/profile/domain/entities/profile.dart';
import 'package:liftlink/features/profile/presentation/providers/profile_providers.dart';

part 'user_search_notifier.g.dart';

/// StateNotifier for managing user search state
@riverpod
class UserSearchNotifier extends _$UserSearchNotifier {
  @override
  UserSearchState build() {
    return const UserSearchState();
  }

  /// Perform search with the given query
  Future<void> search(String query) async {
    // Clear results if query is empty
    if (query.trim().isEmpty) {
      state = const UserSearchState();
      return;
    }

    // Update state to show loading
    state = state.copyWith(
      isSearching: true,
      errorMessage: null,
      query: query,
    );

    try {
      final searchUsers = ref.read(searchUsersProvider);
      final result = await searchUsers(query: query);

      result.fold(
        (failure) {
          state = state.copyWith(
            isSearching: false,
            errorMessage: failure.userMessage,
            searchResults: const [],
          );
        },
        (profiles) {
          state = state.copyWith(
            isSearching: false,
            searchResults: profiles,
            errorMessage: null,
          );
        },
      );
    } catch (e) {
      state = state.copyWith(
        isSearching: false,
        errorMessage: 'An error occurred while searching',
        searchResults: const [],
      );
    }
  }

  /// Clear search results and reset state
  void clear() {
    state = const UserSearchState();
  }
}
