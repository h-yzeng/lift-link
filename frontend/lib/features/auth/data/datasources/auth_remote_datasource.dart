import 'package:liftlink/core/error/exceptions.dart';
import 'package:liftlink/features/auth/domain/entities/user.dart';
import 'package:liftlink/features/auth/data/models/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Remote data source for authentication using Supabase
abstract class AuthRemoteDataSource {
  /// Get the currently authenticated user
  Future<User?> getCurrentUser();

  /// Sign in with email and password
  Future<User> loginWithEmail({
    required String email,
    required String password,
  });

  /// Register a new user with email and password
  Future<User> registerWithEmail({
    required String email,
    required String password,
  });

  /// Sign out the current user
  Future<void> logout();

  /// Stream of authentication state changes
  Stream<User?> get authStateChanges;

  /// Reset password
  Future<void> resetPassword({required String email});

  /// Update password
  Future<void> updatePassword({required String newPassword});
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final supabase.SupabaseClient supabaseClient;

  AuthRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<User?> getCurrentUser() async {
    try {
      final supabaseUser = supabaseClient.auth.currentUser;
      return supabaseUser?.toEntity();
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<User> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw const ServerException(message: 'Login failed: No user returned');
      }

      return response.user!.toEntity();
    } on supabase.AuthException catch (e) {
      throw ServerException(message: e.message);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<User> registerWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await supabaseClient.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw const ServerException(
          message: 'Registration failed: No user returned',
        );
      }

      return response.user!.toEntity();
    } on supabase.AuthException catch (e) {
      throw ServerException(message: e.message);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> logout() async {
    try {
      await supabaseClient.auth.signOut();
    } on supabase.AuthException catch (e) {
      throw ServerException(message: e.message);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Stream<User?> get authStateChanges {
    return supabaseClient.auth.onAuthStateChange.map((authState) {
      final supabaseUser = authState.session?.user;
      return supabaseUser?.toEntity();
    });
  }

  @override
  Future<void> resetPassword({required String email}) async {
    try {
      await supabaseClient.auth.resetPasswordForEmail(email);
    } on supabase.AuthException catch (e) {
      throw ServerException(message: e.message);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> updatePassword({required String newPassword}) async {
    try {
      await supabaseClient.auth.updateUser(
        supabase.UserAttributes(password: newPassword),
      );
    } on supabase.AuthException catch (e) {
      throw ServerException(message: e.message);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }
}
