import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liftlink/shared/widgets/empty_state.dart';
import 'package:liftlink/shared/widgets/error_state.dart';

/// A widget that handles AsyncValue states with consistent loading, error, and empty states.
class AsyncValueBuilder<T> extends StatelessWidget {
  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final VoidCallback? onRetry;
  final Widget? loadingWidget;
  final Widget Function(Object error)? errorBuilder;
  final bool Function(T data)? isEmpty;
  final Widget Function()? emptyBuilder;

  const AsyncValueBuilder({
    super.key,
    required this.value,
    required this.builder,
    this.onRetry,
    this.loadingWidget,
    this.errorBuilder,
    this.isEmpty,
    this.emptyBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: (data) {
        if (isEmpty?.call(data) ?? false) {
          return emptyBuilder?.call() ??
              const EmptyState(
                icon: Icons.inbox,
                title: 'Nothing here yet',
              );
        }
        return builder(data);
      },
      loading: () =>
          loadingWidget ??
          const Center(child: CircularProgressIndicator()),
      error: (error, stack) =>
          errorBuilder?.call(error) ??
          ErrorState(
            message: error.toString(),
            onRetry: onRetry,
          ),
    );
  }
}

/// A widget that handles AsyncValue for lists with consistent states.
class AsyncListBuilder<T> extends StatelessWidget {
  final AsyncValue<List<T>> value;
  final Widget Function(List<T> data) builder;
  final VoidCallback? onRetry;
  final Widget? loadingWidget;
  final Widget Function(Object error)? errorBuilder;
  final Widget? emptyWidget;
  final IconData emptyIcon;
  final String emptyTitle;
  final String? emptySubtitle;
  final String? emptyActionLabel;
  final VoidCallback? emptyAction;

  const AsyncListBuilder({
    super.key,
    required this.value,
    required this.builder,
    this.onRetry,
    this.loadingWidget,
    this.errorBuilder,
    this.emptyWidget,
    this.emptyIcon = Icons.inbox,
    this.emptyTitle = 'Nothing here yet',
    this.emptySubtitle,
    this.emptyActionLabel,
    this.emptyAction,
  });

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: (data) {
        if (data.isEmpty) {
          return emptyWidget ??
              EmptyState(
                icon: emptyIcon,
                title: emptyTitle,
                subtitle: emptySubtitle,
                actionLabel: emptyActionLabel,
                onAction: emptyAction,
              );
        }
        return builder(data);
      },
      loading: () =>
          loadingWidget ??
          const Center(child: CircularProgressIndicator()),
      error: (error, stack) =>
          errorBuilder?.call(error) ??
          ErrorState(
            message: error.toString(),
            onRetry: onRetry,
          ),
    );
  }
}
