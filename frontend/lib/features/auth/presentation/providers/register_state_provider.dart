import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'register_state_provider.g.dart';

/// Provider for register loading state
@riverpod
class RegisterLoadingState extends _$RegisterLoadingState {
  @override
  bool build() => false;

  void setLoading(bool isLoading) {
    state = isLoading;
  }
}

/// Provider for password visibility state
@riverpod
class RegisterPasswordVisibility extends _$RegisterPasswordVisibility {
  @override
  bool build() => true; // Initially obscured

  void toggle() {
    state = !state;
  }
}

/// Provider for confirm password visibility state
@riverpod
class RegisterConfirmPasswordVisibility
    extends _$RegisterConfirmPasswordVisibility {
  @override
  bool build() => true; // Initially obscured

  void toggle() {
    state = !state;
  }
}
