import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';

/// Non-intrusive offline indicator banner shown when internet is disconnected.
class OfflineBanner extends ConsumerWidget {
  final Widget? child;
  final bool? isOfflineOverride;

  const OfflineBanner({
    super.key,
    this.child,
    this.isOfflineOverride,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isOffline = isOfflineOverride ?? ref.watch(isOfflineProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isOffline)
          Semantics(
            container: true,
            label: 'Offline indicator. You are currently offline, displaying cached data.',
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              color: AppColors.warningContainer,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg16,
                vertical: AppSpacing.sm8,
              ),
              child: SafeArea(
                bottom: false,
                top: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.wifi_off_rounded,
                      size: 18,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: AppSpacing.sm8),
                    Flexible(
                      child: Text(
                        'Offline Mode — Displaying cached travel data',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (child != null) Flexible(child: child!),
      ],
    );
  }
}
