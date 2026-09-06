import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/theme.dart';

/// Renders a legal document body (Markdown) with PLAN E styling, an H2 section
/// index, and working links. Shared by the viewer screen and the Risk
/// Acknowledgment screen.
///
/// ponytail: headings use the app's bold sans scale, not a serif face — no
/// serif font is bundled. Add one to pubspec `fonts:` and set `headingFamily`
/// here if design insists.
class LegalDocumentView extends StatefulWidget {
  final String bodyMd;

  /// Called once the user has scrolled to (or near) the end. Fires at most
  /// once. Used by the Risk Acknowledgment scroll gate.
  final VoidCallback? onScrolledToEnd;

  /// Shows a "Jump to section" button when the body has 3+ H2 headings.
  final bool showSectionIndex;

  /// Leading content above the document body (e.g. version / last-updated).
  final Widget? header;

  const LegalDocumentView({
    super.key,
    required this.bodyMd,
    this.onScrolledToEnd,
    this.showSectionIndex = true,
    this.header,
  });

  @override
  State<LegalDocumentView> createState() => _LegalDocumentViewState();
}

class _LegalDocumentViewState extends State<LegalDocumentView> {
  final _scrollController = ScrollController();
  final _sectionKeys = <String, GlobalKey>{};
  late final List<_Section> _sections;
  bool _endReported = false;

  @override
  void initState() {
    super.initState();
    _sections = _splitSections(widget.bodyMd);
    for (final s in _sections) {
      if (s.title != null) _sectionKeys[s.title!] = GlobalKey();
    }
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_endReported || widget.onScrolledToEnd == null) return;
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    // 48px slack so it fires even if the last line sits under a bottom bar.
    if (pos.pixels >= pos.maxScrollExtent - 48) {
      _endReported = true;
      widget.onScrolledToEnd!();
    }
  }

  /// If the whole document is shorter than the viewport there is nothing to
  /// scroll — treat it as already read.
  void _maybeReportShortDoc() {
    if (_endReported || widget.onScrolledToEnd == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      if (_scrollController.position.maxScrollExtent <= 0) {
        _endReported = true;
        widget.onScrolledToEnd!();
      }
    });
  }

  Future<void> _openLink(String? href) async {
    if (href == null) return;
    final uri = Uri.tryParse(href);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _jumpTo(String title) {
    final key = _sectionKeys[title];
    final ctx = key?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.02,
      );
    }
  }

  void _showSectionSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.ivory,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: AppSpacing.lg16),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg16,
                AppSpacing.sm8,
                AppSpacing.lg16,
                AppSpacing.md12,
              ),
              child: Text('Jump to section', style: AppTypography.headingMedium),
            ),
            for (final s in _sections)
              if (s.title != null)
                ListTile(
                  title: Text(s.title!, style: AppTypography.bodyLarge),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _jumpTo(s.title!);
                  },
                ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _maybeReportShortDoc();
    final styleSheet = _legalStyleSheet(context);
    final h2Count = _sections.where((s) => s.title != null).length;

    return Stack(
      children: [
        ListView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg16,
            AppSpacing.lg16,
            AppSpacing.lg16,
            AppSpacing.huge40,
          ),
          children: [
            if (widget.header != null) ...[
              widget.header!,
              const SizedBox(height: AppSpacing.lg16),
            ],
            for (final s in _sections)
              SizedBox(
                key: s.title != null ? _sectionKeys[s.title!] : null,
                width: double.infinity,
                child: MarkdownBody(
                  data: s.markdown,
                  selectable: true,
                  styleSheet: styleSheet,
                  onTapLink: (text, href, title) => _openLink(href),
                ),
              ),
          ],
        ),
        if (widget.showSectionIndex && h2Count >= 3)
          Positioned(
            right: AppSpacing.lg16,
            bottom: AppSpacing.lg16,
            child: FloatingActionButton.small(
              backgroundColor: AppColors.forest,
              foregroundColor: AppColors.ivory,
              onPressed: _showSectionSheet,
              child: const Icon(Icons.list),
            ),
          ),
      ],
    );
  }
}

class _Section {
  final String? title; // null for the pre-amble before the first H2
  final String markdown;
  _Section(this.title, this.markdown);
}

/// Splits a Markdown body on `## ` (H2) headings so each section can carry a
/// scroll key for the jump-to-section index.
List<_Section> _splitSections(String body) {
  final lines = body.replaceAll('\r\n', '\n').split('\n');
  final sections = <_Section>[];
  final buffer = <String>[];
  String? currentTitle;

  void flush() {
    if (buffer.isEmpty && currentTitle == null) return;
    sections.add(_Section(currentTitle, buffer.join('\n').trim()));
    buffer.clear();
  }

  for (final line in lines) {
    final isH2 = line.startsWith('## ') && !line.startsWith('### ');
    if (isH2) {
      flush();
      currentTitle = line.substring(3).trim();
      buffer.add(line);
    } else {
      buffer.add(line);
    }
  }
  flush();
  return sections.isEmpty ? [_Section(null, body)] : sections;
}

MarkdownStyleSheet _legalStyleSheet(BuildContext context) {
  final base = MarkdownStyleSheet.fromTheme(Theme.of(context));
  return base.copyWith(
    p: AppTypography.bodyLarge.copyWith(color: AppColors.ink, height: 1.6),
    pPadding: const EdgeInsets.only(bottom: AppSpacing.md12),
    h1: AppTypography.headingLarge.copyWith(color: AppColors.deep),
    h1Padding: const EdgeInsets.only(top: AppSpacing.lg16, bottom: AppSpacing.sm8),
    h2: AppTypography.headingMedium.copyWith(color: AppColors.forest),
    h2Padding: const EdgeInsets.only(top: AppSpacing.xxl24, bottom: AppSpacing.sm8),
    h3: AppTypography.bodyLarge.copyWith(
      fontWeight: FontWeight.w700,
      color: AppColors.forest,
    ),
    h3Padding: const EdgeInsets.only(top: AppSpacing.lg16, bottom: AppSpacing.xs4),
    listBullet: AppTypography.bodyLarge.copyWith(color: AppColors.ink, height: 1.6),
    blockquote: AppTypography.bodyMedium.copyWith(color: AppColors.ink),
    blockquotePadding: const EdgeInsets.all(AppSpacing.md12),
    blockquoteDecoration: const BoxDecoration(
      color: AppColors.sage,
      borderRadius: AppRadii.borderSm8,
      border: Border(
        left: BorderSide(color: AppColors.gold, width: 3),
      ),
    ),
    a: AppTypography.bodyLarge.copyWith(
      color: AppColors.gold,
      decoration: TextDecoration.underline,
    ),
    tableHead: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700),
    tableBody: AppTypography.bodyMedium.copyWith(color: AppColors.ink),
    tableBorder: TableBorder.all(color: AppColors.border, width: 1),
    tableHeadAlign: TextAlign.left,
    tableCellsPadding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm8,
      vertical: AppSpacing.xs4,
    ),
    tableColumnWidth: const IntrinsicColumnWidth(),
    horizontalRuleDecoration: const BoxDecoration(
      border: Border(top: BorderSide(color: AppColors.borderSubtle, width: 1)),
    ),
  );
}
