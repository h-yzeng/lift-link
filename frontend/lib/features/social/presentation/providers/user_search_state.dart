import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:liftlink/features/profile/domain/entities/profile.dart';

part 'user_search_state.freezed.dart';

/// State for user search functionality
@freezed
abstract class UserSearchState with _$UserSearchState {
  const factory UserSearchState({
    @Default([]) List<Profile> searchResults,
    @Default(false) bool isSearching,
    String? errorMessage,
    @Default('') String query,
  }) = _UserSearchState;

  const UserSearchState._();

  /// Whether there are search results to display
  bool get hasResults => searchResults.isNotEmpty;

  /// Whether there's an error to display
  bool get hasError => errorMessage != null;
}
