import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_version.dart';
import '../core/current_platform.dart';
import '../core/native_intents.dart';
import '../providers/app_providers.dart';
import '../theme/theme.dart';
import 'app_button.dart';

/// Wraps the whole routed app (see MaterialApp.router's `builder` in
/// main.dart). Reads `app_versions` for the current platform and, in order
/// of severity:
///
///   1. maintenance_mode          → full-screen block, no way past it
///   2. version < min_supported   → full-screen block ("force update")
///   3. version < latest          → dismissible nudge banner, app still usable
///   4. otherwise (or no gate configured for this platform, e.g. web)
///                                 → renders [child] untouched
///
/// Fail-open throughout: a missing gate, a flag that fails to parse, or a
/// platform with no `app_versions` row all fall through to case 4.
class VersionGate extends ConsumerWidget {
  final Widget child;

  const VersionGate({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gate = ref.watch(appVersionGateProvider(currentPlatformKey));
    final action = decideVersionGateAction(gate, AppVersionInfo.version);

    switch (action) {
      case VersionGateAction.maintenance:
        return _BlockingScreen(
          icon: Icons.build_circle_outlined,
          title: 'Under Maintenance',
          message: gate!.maintenanceMessage ??
              'PLAN E is undergoing scheduled maintenance. Please check back shortly.',
        );
      case VersionGateAction.forceUpdate:
        return _BlockingScreen(
          icon: Icons.system_update_outlined,
          title: 'Update Required',
          message:
              'This version of PLAN E is no longer supported. Please update to '
              'version ${gate!.latestVersion} or later to continue.',
          showUpdateButton: true,
        );
      case VersionGateAction.softUpdate:
        return _SoftUpdateBanner(latestVersion: gate!.latestVersion, child: child);
      case VersionGateAction.none:
        return child;
    }
  }
}

class _BlockingScreen extends ConsumerWidget {
  final IconData icon;
  final String title;
  final String message;
  final bool showUpdateButton;

  const _BlockingScreen({
    required this.icon,
    required this.title,
    required this.message,
    this.showUpdateButton = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppSpacing.paddingXxl24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: AppSpacing.paddingXl20,
                  decoration: const BoxDecoration(
                    color: AppColors.sage,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 48.0, color: AppColors.forest),
                ),
                const SizedBox(height: AppSpacing.xl20),
                Text(
                  title,
                  style: AppTypography.headingLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm8),
                Text(
                  message,
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.ink),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xxl24),
                // Android only — the App Store needs a numeric app id we
                // don't have configured yet, not just the bundle id. Skipped
                // for iOS; add once that id is on hand.
                if (showUpdateButton && currentPlatformKey == 'android') ...[
                  AppButton(
                    label: 'Update Now',
                    icon: Icons.open_in_new,
                    isFullWidth: true,
                    onPressed: () =>
                        NativeIntents.openPlayStore(AppVersionInfo.packageName),
                  ),
                  const SizedBox(height: AppSpacing.md12),
                ],
                AppButton.secondary(
                  label: 'Check Again',
                  icon: Icons.refresh,
                  isFullWidth: true,
                  onPressed: () =>
                      ref.read(remoteConfigProvider.notifier).refresh(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SoftUpdateBanner extends StatefulWidget {
  final String latestVersion;
  final Widget child;

  const _SoftUpdateBanner({required this.latestVersion, required this.child});

  @override
  State<_SoftUpdateBanner> createState() => _SoftUpdateBannerState();
}

class _SoftUpdateBannerState extends State<_SoftUpdateBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return widget.child;

    return Column(
      children: [
        SafeArea(
          bottom: false,
          child: Material(
            color: AppColors.sage,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg16,
                vertical: AppSpacing.sm8,
              ),
              child: Row(
                children: [
                  const Icon(Icons.new_releases_outlined, size: 18, color: AppColors.forest),
                  const SizedBox(width: AppSpacing.sm8),
                  Expanded(
                    child: Text(
                      'Version ${widget.latestVersion} is available.',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.forest,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (currentPlatformKey == 'android')
                    TextButton(
                      onPressed: () =>
                          NativeIntents.openPlayStore(AppVersionInfo.packageName),
                      child: Text(
                        'Update',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.forest,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: AppColors.forest),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                    tooltip: 'Dismiss',
                    onPressed: () => setState(() => _dismissed = true),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(child: widget.child),
      ],
    );
  }
}
