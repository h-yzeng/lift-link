import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:liftlink/core/error/failures.dart';
import 'package:liftlink/features/social/domain/entities/friendship.dart';
import 'package:liftlink/features/social/presentation/providers/friendship_providers.dart';

part 'paginated_friends_provider.freezed.dart';
part 'paginated_friends_provider.g.dart';

@freezed
class PaginatedFriendsState with _$PaginatedFriendsState {
  const factory PaginatedFriendsState({
    @Default([]) List<Friendship> friendships,
    @Default(false) bool isLoading,
    @Default(true) bool hasMore,
    String? errorMessage,
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
    await _loadPage(offset: state.friendships.length);
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
            errorMessage: failure.userMessage,
          );
        },
        (newFriendships) {
          state = state.copyWith(
            friendships: isRefresh
                ? newFriendships
                : [...state.friendships, ...newFriendships],
            isLoading: false,
            hasMore: newFriendships.length == _pageSize,
            errorMessage: null,
          );
        },
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
}
