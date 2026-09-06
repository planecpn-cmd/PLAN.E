import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/app_providers.dart';
import '../../theme/theme.dart';

/// `/emergency` — the numbers you may need with no data connection.
///
/// The government numbers are compile-time constants: they render and dial
/// whether or not anything has been fetched. The full Emergency Policy is a
/// normal cached legal document.
class EmergencyInfoScreen extends ConsumerWidget {
  const EmergencyInfoScreen({super.key});

  static const _numbers = <({String label, String number, IconData icon})>[
    (label: 'Nepal Police', number: '100', icon: Icons.local_police_outlined),
    (label: 'Ambulance', number: '102', icon: Icons.local_hospital_outlined),
    (label: 'Fire', number: '101', icon: Icons.local_fire_department_outlined),
    (
      label: 'Tourist Police, Kathmandu',
      number: '1144',
      icon: Icons.support_agent_outlined,
    ),
  ];

  Future<void> _dial(BuildContext context, String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open dialer for $number')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final policy = ref.watch(legalDocumentProvider('emergency-policy'));

    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        backgroundColor: AppColors.ivory,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: Text(
          'Emergency',
          style: AppTypography.headingMedium.copyWith(color: AppColors.ink),
        ),
      ),
      body: ListView(
        padding: AppSpacing.paddingLg16,
        children: [
          Text(
            'In immediate danger, get to safety, tell your guide, then call '
            'emergency services. Call the PLAN E line once danger has passed — '
            'we coordinate, we do not rescue.',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.ink),
          ),
          const SizedBox(height: AppSpacing.lg16),
          for (final n in _numbers)
            Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm8),
              color: AppColors.cardBackground,
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadii.borderMd16,
                side: BorderSide(color: AppColors.borderSubtle),
              ),
              child: ListTile(
                leading: Icon(n.icon, color: AppColors.forest),
                title: Text(
                  n.label,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(n.number, style: AppTypography.bodyMedium),
                trailing: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.forest,
                  ),
                  onPressed: () => _dial(context, n.number),
                  icon: const Icon(Icons.call, size: 18),
                  label: const Text('Call'),
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.md12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.menu_book_outlined,
                color: AppColors.forest),
            title: Text(
              'PLAN E Emergency Policy',
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              policy.valueOrNull == null
                  ? 'Full incident and evacuation guidance, including the PLAN E '
                      '24/7 line.'
                  : 'Includes the PLAN E 24/7 emergency line.',
              style: AppTypography.caption.copyWith(
                color: AppColors.disabledText,
              ),
            ),
            trailing: const Icon(Icons.chevron_right,
                color: AppColors.disabledText),
            onTap: () => context.push('/legal/emergency-policy'),
          ),
        ],
      ),
    );
  }
}
