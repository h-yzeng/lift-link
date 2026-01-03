import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'login_state_provider.g.dart';

/// Provider for login loading state
@riverpod
class LoginLoadingState extends _$LoginLoadingState {
  @override
  bool build() => false;

  void setLoading(bool isLoading) {
    state = isLoading;
  }
}

/// Provider for password visibility state
@riverpod
class LoginPasswordVisibility extends _$LoginPasswordVisibility {
  @override
  bool build() => true; // Initially obscured

  void toggle() {
    state = !state;
  }
}
