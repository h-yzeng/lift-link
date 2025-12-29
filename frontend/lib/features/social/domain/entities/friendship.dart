import 'package:freezed_annotation/freezed_annotation.dart';

part 'friendship.freezed.dart';
part 'friendship.g.dart';

/// Status of a friendship request
enum FriendshipStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('accepted')
  accepted,
  @JsonValue('rejected')
  rejected,
}

/// Represents a friendship relationship between two users.
@freezed
class Friendship with _$Friendship {
  const Friendship._(); // Required for custom getters

  const factory Friendship({
    required String id,
    required String requesterId,
    required String addresseeId,
    required FriendshipStatus status,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Friendship;

  factory Friendship.fromJson(Map<String, dynamic> json) =>
      _$FriendshipFromJson(json);

  /// Whether this friendship is pending approval
  bool get isPending => status == FriendshipStatus.pending;

  /// Whether this friendship has been accepted
  bool get isAccepted => status == FriendshipStatus.accepted;

  /// Whether this friendship has been rejected
  bool get isRejected => status == FriendshipStatus.rejected;

  /// Returns the ID of the other user in the friendship
  String getOtherUserId(String currentUserId) {
    if (requesterId == currentUserId) return addresseeId;
    return requesterId;
  }

  /// Whether the given user is the one who sent the request
  bool isRequester(String userId) => requesterId == userId;

  /// Whether the given user is the one who received the request
  bool isAddressee(String userId) => addresseeId == userId;

  /// Whether the given user can accept/reject this friendship
  bool canRespond(String userId) =>
      isPending && isAddressee(userId);
}
