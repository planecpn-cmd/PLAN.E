import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/legal_document.dart';
import '../../providers/app_providers.dart';
import '../../theme/theme.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/empty_state_view.dart';

/// `/legal` — lists every published legal document.
class LegalIndexScreen extends ConsumerWidget {
  const LegalIndexScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(legalDocumentsProvider);

    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        backgroundColor: AppColors.ivory,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/profile'),
        ),
        title: Text(
          'Legal & Policies',
          style: AppTypography.headingMedium.copyWith(color: AppColors.ink),
        ),
      ),
      body: AsyncValueView<List<LegalDocument>>(
        value: async,
        onRetry: () => ref.invalidate(legalDocumentsProvider),
        isEmpty: (docs) => docs.isEmpty,
        emptyView: const EmptyStateView(
          icon: Icons.description_outlined,
          title: 'Nothing published yet',
          description: 'Legal documents will appear here once published.',
        ),
        data: (docs) => ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm8),
          itemCount: docs.length,
          separatorBuilder: (_, __) =>
              const Divider(height: 1, color: AppColors.borderSubtle),
          itemBuilder: (context, i) {
            final doc = docs[i];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg16,
                vertical: AppSpacing.xs4,
              ),
              title: Text(
                doc.title,
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Version ${doc.version}',
                style: AppTypography.caption.copyWith(
                  color: AppColors.disabledText,
                ),
              ),
              trailing: const Icon(
                Icons.chevron_right,
                color: AppColors.disabledText,
              ),
              onTap: () => context.push('/legal/${doc.slug}'),
            );
          },
        ),
      ),
    );
  }
}
