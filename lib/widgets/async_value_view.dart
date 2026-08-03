import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/theme.dart';
import 'app_skeleton.dart';
import 'empty_state_view.dart';
import 'error_state_view.dart';

class AsyncValueView<T> extends StatelessWidget {
  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final Widget Function()? loading;
  final Widget Function(Object error, StackTrace? stackTrace)? error;
  final bool Function(T data)? isEmpty;
  final Widget? emptyView;
  final VoidCallback? onRetry;

  const AsyncValueView({
    super.key,
    required this.value,
    required this.data,
    this.loading,
    this.error,
    this.isEmpty,
    this.emptyView,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: (d) {
        if (isEmpty != null && isEmpty!(d)) {
          return emptyView ?? const EmptyStateView(title: 'No data available');
        }
        return data(d);
      },
      loading: () {
        if (loading != null) return loading!();
        return const _DefaultLoadingSkeleton();
      },
      error: (err, stackTrace) {
        if (error != null) return error!(err, stackTrace);
        return ErrorStateView(
          message: err.toString(),
          onRetry: onRetry,
        );
      },
    );
  }
}

class _DefaultLoadingSkeleton extends StatelessWidget {
  const _DefaultLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: AppSpacing.paddingLg16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppSkeleton(height: 24, width: 180),
          SizedBox(height: AppSpacing.md12),
          AppSkeleton(height: 120, width: double.infinity),
          SizedBox(height: AppSpacing.md12),
          AppSkeleton(height: 16, width: 240),
        ],
      ),
    );
  }
}
