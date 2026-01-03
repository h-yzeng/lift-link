import 'package:mocktail/mocktail.dart';

/// Helper utilities for creating mock providers in tests.
///
/// Note: These functions are primarily documentation. In practice, use:
/// - `provider.overrideWith((ref) => value)` for most providers
/// - `provider.overrideWithValue(value)` for use case providers
class MockProviderContainer {
  // Note: Due to Riverpod's type system, these generic methods don't work
  // Instead, use the provider's overrideWith method directly in your tests
  // Example: myProvider.overrideWith((ref) => AsyncValue.data(myData))
}

/// Example mock classes for common interfaces
class MockCallback extends Mock {
  void call();
}

class MockCallbackWithParam<T> extends Mock {
  void call(T param);
}
