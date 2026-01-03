import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:liftlink/core/error/failures.dart';
import 'package:liftlink/features/profile/domain/entities/profile.dart';
import 'package:liftlink/features/social/presentation/providers/friendship_providers.dart';

part 'paginated_friends_provider.freezed.dart';
part 'paginated_friends_provider.g.dart';

@freezed
class PaginatedFriendsState with _$PaginatedFriendsState {
  const factory PaginatedFriendsState({
    @Default([]) List<Profile> friends,
    @Default(false) bool isLoading,
    @Default(true) bool hasMore,
    Failure? error,
  }) = _PaginatedFriendsState;
}

@riverpod
class PaginatedFriends extends _$PaginatedFriends {
  static const int _pageSize = 20;

  @override
  PaginatedFriendsState build(String userId) {
    // Load first page on initialization
    Future.microtask(() => loadFirstPage());
    return const PaginatedFriendsState();
  }

  Future<void> loadFirstPage() async {
    state = const PaginatedFriendsState(isLoading: true);
    await _loadPage(offset: 0, isRefresh: true);
  }

  Future<void> loadNextPage() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);
    await _loadPage(offset: state.friends.length);
  }

  Future<void> refresh() async {
    await loadFirstPage();
  }

  Future<void> _loadPage({
    required int offset,
    bool isRefresh = false,
  }) async {
    try {
      final repository = ref.read(friendshipRepositoryProvider);
      final result = await repository.getFriendsPaginated(
        userId: userId,
        limit: _pageSize,
        offset: offset,
      );

      result.fold(
        (failure) {
          state = state.copyWith(
            isLoading: false,
            error: failure,
          );
        },
        (newFriends) {
          state = state.copyWith(
            friends: isRefresh ? newFriends : [...state.friends, ...newFriends],
            isLoading: false,
            hasMore: newFriends.length == _pageSize,
            error: null,
          );
        },
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: Failure(message: e.toString()),
      );
    }
  }
}
