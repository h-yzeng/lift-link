import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

/// Base class for creating mock providers in tests
class MockProviderContainer {
  /// Create override for async provider returning loading state
  static Override asyncLoading<T>(ProviderListenable<AsyncValue<T>> provider) {
    return provider.overrideWith((ref) => const AsyncValue.loading());
  }

  /// Create override for async provider returning data
  static Override asyncData<T>(
    ProviderListenable<AsyncValue<T>> provider,
    T data,
  ) {
    return provider.overrideWith((ref) => AsyncValue.data(data));
  }

  /// Create override for async provider returning error
  static Override asyncError<T>(
    ProviderListenable<AsyncValue<T>> provider,
    Object error, [
    StackTrace? stackTrace,
  ]) {
    return provider.overrideWith(
      (ref) => AsyncValue.error(error, stackTrace ?? StackTrace.current),
    );
  }
}

/// Example mock classes for common interfaces
class MockCallback extends Mock {
  void call();
}

class MockCallbackWithParam<T> extends Mock {
  void call(T param);
}
