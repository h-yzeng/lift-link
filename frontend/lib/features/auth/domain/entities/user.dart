import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
abstract class User with _$User {
  const User._();

  const factory User({
    required String id,
    required String email,
    String? username,
    String? displayName,
    String? avatarUrl,
    DateTime? emailConfirmedAt,
    required DateTime createdAt,
    DateTime? lastSignInAt,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  /// Get display name with fallback to username or email
  String get displayNameOrFallback {
    if (displayName != null && displayName!.isNotEmpty) {
      return displayName!;
    }
    if (username != null && username!.isNotEmpty) {
      return username!;
    }
    return email.split('@').first;
  }

  /// Check if user has completed profile setup
  bool get hasCompletedProfile => username != null && username!.isNotEmpty;

  /// Check if email is verified
  bool get isEmailVerified => emailConfirmedAt != null;
}
