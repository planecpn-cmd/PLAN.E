// RM-21 Settings Screen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/theme.dart';
import '../../widgets/widgets.dart';

class MoreSettingsScreen extends ConsumerStatefulWidget {
  const MoreSettingsScreen({super.key});

  @override
  ConsumerState<MoreSettingsScreen> createState() => _MoreSettingsScreenState();
}

class _MoreSettingsScreenState extends ConsumerState<MoreSettingsScreen> {
  bool _darkMode = false;
  bool _offlineMaps = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        title: Text(
          'More Settings',
          style: AppTypography.headingMedium.copyWith(color: AppColors.ink),
        ),
        backgroundColor: AppColors.ivory,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          constraints: AppTouchTarget.minConstraints,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'App Preferences',
              style: AppTypography.headingMedium.copyWith(fontSize: 18),
            ),
            const SizedBox(height: AppSpacing.md12),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg16,
                      vertical: AppSpacing.md12,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: AppTouchTarget.minSize,
                          height: AppTouchTarget.minSize,
                          alignment: Alignment.center,
                          child: const Icon(Icons.dark_mode_outlined, color: AppColors.forest, size: 22),
                        ),
                        const SizedBox(width: AppSpacing.sm8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dark Theme',
                                style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                'Enable dark theme for nighttime reading',
                                style: AppTypography.caption.copyWith(color: AppColors.disabledText),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _darkMode,
                          activeTrackColor: AppColors.forest,
                          onChanged: (val) {
                            setState(() => _darkMode = val);
                            AppToast.show(context, message: 'Theme preference updated');
                          },
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.borderSubtle),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg16,
                      vertical: AppSpacing.md12,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: AppTouchTarget.minSize,
                          height: AppTouchTarget.minSize,
                          alignment: Alignment.center,
                          child: const Icon(Icons.map_outlined, color: AppColors.forest, size: 22),
                        ),
                        const SizedBox(width: AppSpacing.sm8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Offline Trail Maps',
                                style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                'Pre-cache maps for remote mountain routes',
                                style: AppTypography.caption.copyWith(color: AppColors.disabledText),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _offlineMaps,
                          activeTrackColor: AppColors.forest,
                          onChanged: (val) {
                            setState(() => _offlineMaps = val);
                            AppToast.show(context, message: 'Offline maps setting updated');
                          },
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.borderSubtle),
                  InkWell(
                    onTap: () {
                      AppToast.show(
                        context,
                        message: 'App cache cleared successfully (4.2 MB saved)',
                        variant: AppToastVariant.success,
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg16,
                        vertical: AppSpacing.md12,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: AppTouchTarget.minSize,
                            height: AppTouchTarget.minSize,
                            alignment: Alignment.center,
                            child: const Icon(Icons.cleaning_services_outlined, color: AppColors.forest, size: 22),
                          ),
                          const SizedBox(width: AppSpacing.sm8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Clear Cache',
                                  style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  'Free up storage space (4.2 MB cached)',
                                  style: AppTypography.caption.copyWith(color: AppColors.disabledText),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: AppColors.disabledText),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl24),

            Text(
              'Legal & Info',
              style: AppTypography.headingMedium.copyWith(fontSize: 18),
            ),
            const SizedBox(height: AppSpacing.md12),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _LinkTile(
                    title: 'Terms of Service',
                    icon: Icons.description_outlined,
                    onTap: () => AppStubSheet.show(
                      context,
                      title: 'Terms of Service',
                      featureName: 'Legal & Service Agreements (Stage B)',
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.borderSubtle),
                  _LinkTile(
                    title: 'Privacy Policy',
                    icon: Icons.privacy_tip_outlined,
                    onTap: () => AppStubSheet.show(
                      context,
                      title: 'Privacy Policy',
                      featureName: 'Data Privacy & Security Policies (Stage B)',
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.borderSubtle),
                  _LinkTile(
                    title: 'Open Source Licenses',
                    icon: Icons.code_outlined,
                    onTap: () => showLicensePage(context: context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl24),

            // App Version Details Footer
            Center(
              child: Column(
                children: [
                  Text(
                    'PLAN E Nepal',
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.forest,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs4),
                  Text(
                    'Version 1.0.0 (Build 104)',
                    style: AppTypography.caption.copyWith(color: AppColors.disabledText),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _LinkTile({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg16,
          vertical: AppSpacing.md12,
        ),
        child: Row(
          children: [
            Container(
              width: AppTouchTarget.minSize,
              height: AppTouchTarget.minSize,
              alignment: Alignment.center,
              child: Icon(icon, color: AppColors.forest, size: 22),
            ),
            const SizedBox(width: AppSpacing.sm8),
            Expanded(
              child: Text(
                title,
                style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.disabledText),
          ],
        ),
      ),
    );
  }
}
