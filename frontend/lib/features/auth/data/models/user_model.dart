import 'package:liftlink/features/auth/domain/entities/user.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Extension to convert Supabase User to domain User entity
extension UserModelMapper on supabase.User {
  User toEntity() {
    return User(
      id: id,
      email: email ?? '',
      username: userMetadata?['username'] as String?,
      displayName: userMetadata?['display_name'] as String?,
      avatarUrl: userMetadata?['avatar_url'] as String?,
      emailConfirmedAt: emailConfirmedAt != null
          ? DateTime.tryParse(emailConfirmedAt!)
          : null,
      createdAt: DateTime.parse(createdAt),
      lastSignInAt:
          lastSignInAt != null ? DateTime.tryParse(lastSignInAt!) : null,
    );
  }
}
