import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:liftlink/core/error/failures.dart';

/// Extension methods for handling Either&lt;Failure, T&gt; results with UI feedback.
extension ResultExtensions<T> on Either<Failure, T> {
  /// Shows appropriate snackbar based on result and returns the success value or null.
  T? showResultSnackBar(
    BuildContext context, {
    String? successMessage,
    String? failurePrefix,
    Duration duration = const Duration(seconds: 3),
  }) {
    return fold(
      (failure) {
        if (context.mounted) {
          final message = failurePrefix != null
              ? '$failurePrefix: ${failure.userMessage}'
              : failure.userMessage;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: duration,
            ),
          );
        }
        return null;
      },
      (success) {
        if (successMessage != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(successMessage), duration: duration),
          );
        }
        return success;
      },
    );
  }

  /// Handles the result with callbacks, showing error snackbar on failure.
  void handleResult(
    BuildContext context, {
    required void Function(T value) onSuccess,
    void Function(Failure failure)? onFailure,
    String? failurePrefix,
  }) {
    fold((failure) {
      if (context.mounted) {
        final message = failurePrefix != null
            ? '$failurePrefix: ${failure.userMessage}'
            : failure.userMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      onFailure?.call(failure);
    }, onSuccess);
  }
}

/// Extension for showing simple snackbars.
extension SnackBarExtension on BuildContext {
  void showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(SnackBar(content: Text(message)));
  }

  void showErrorSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(this).colorScheme.error,
      ),
    );
  }

  void showInfoSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(this).colorScheme.primary,
      ),
    );
  }
}
