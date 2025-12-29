import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile.freezed.dart';
part 'profile.g.dart';

/// Represents a user's profile information.
@freezed
class Profile with _$Profile {
  const Profile._(); // Required for custom getters

  const factory Profile({
    required String id,
    String? username,
    String? displayName,
    String? avatarUrl,
    String? bio,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Profile;

  factory Profile.fromJson(Map<String, dynamic> json) =>
      _$ProfileFromJson(json);

  /// Returns the display name or falls back to username or "User"
  String get displayNameOrUsername =>
      displayName ?? username ?? 'User';

  /// Whether the user has set a username
  bool get hasUsername => username != null && username!.isNotEmpty;

  /// Whether the user has set a custom display name
  bool get hasCustomDisplayName =>
      displayName != null && displayName!.isNotEmpty;

  /// Whether the user has completed profile setup
  bool get hasCompletedProfile => hasUsername;

  /// Whether the user has set an avatar
  bool get hasAvatar => avatarUrl != null && avatarUrl!.isNotEmpty;

  /// Whether the user has set a bio
  bool get hasBio => bio != null && bio!.isNotEmpty;

  /// Returns initials for avatar placeholder (max 2 characters)
  String get initials {
    final name = displayName ?? username ?? 'User';
    if (name.isEmpty) return '?';

    final words = name.trim().split(RegExp(r'\s+'));
    if (words.length == 1) {
      return words[0].substring(0, words[0].length.clamp(0, 2)).toUpperCase();
    }
    return (words[0][0] + words[1][0]).toUpperCase();
  }
}
