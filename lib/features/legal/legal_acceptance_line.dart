import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/theme.dart';

/// The one-line acceptance statement shown at sign-up and checkout. One
/// combined sentence with tappable document names — not a row of checkboxes.
/// The actual acceptance rows are written by the calling flow.
class LegalAcceptanceLine extends StatefulWidget {
  /// `(displayName, slug)` pairs to render as tappable links, in order.
  final List<(String, String)> documents;

  /// Sentence with `{0}`, `{1}`… placeholders for each document link.
  final String template;

  const LegalAcceptanceLine({
    super.key,
    required this.documents,
    required this.template,
  });

  /// "By creating an account you agree to our Terms of Service, Privacy Policy
  /// and Community Guidelines."
  const LegalAcceptanceLine.signUp({Key? key})
      : this(
          key: key,
          documents: const [
            ('Terms of Service', 'terms-of-service'),
            ('Privacy Policy', 'privacy-policy'),
            ('Community Guidelines', 'community-guidelines'),
          ],
          template:
              'By creating an account you agree to our {0}, {1} and {2}.',
        );

  /// "By booking you accept the Booking Terms and the Cancellation Policy for
  /// this experience."
  const LegalAcceptanceLine.checkout({Key? key})
      : this(
          key: key,
          documents: const [
            ('Booking Terms', 'booking-terms'),
            ('Cancellation Policy', 'cancellation-policy'),
          ],
          template:
              'By booking you accept the {0} and the {1} for this experience.',
        );

  @override
  State<LegalAcceptanceLine> createState() => _LegalAcceptanceLineState();
}

class _LegalAcceptanceLineState extends State<LegalAcceptanceLine> {
  final _recognizers = <TapGestureRecognizer>[];

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bodyStyle = AppTypography.caption.copyWith(color: AppColors.ink);
    final linkStyle = bodyStyle.copyWith(
      color: AppColors.gold,
      fontWeight: FontWeight.w700,
      decoration: TextDecoration.underline,
    );

    // Split the template on {n} tokens and interleave the link spans.
    final spans = <InlineSpan>[];
    final parts = widget.template.split(RegExp(r'\{(\d+)\}'));
    final tokens = RegExp(r'\{(\d+)\}')
        .allMatches(widget.template)
        .map((m) => int.parse(m.group(1)!))
        .toList();

    for (var i = 0; i < parts.length; i++) {
      if (parts[i].isNotEmpty) spans.add(TextSpan(text: parts[i]));
      if (i < tokens.length) {
        final idx = tokens[i];
        final (name, slug) = widget.documents[idx];
        final recognizer = TapGestureRecognizer()
          ..onTap = () => context.push('/legal/$slug');
        _recognizers.add(recognizer);
        spans.add(TextSpan(text: name, style: linkStyle, recognizer: recognizer));
      }
    }

    return Text.rich(TextSpan(style: bodyStyle, children: spans));
  }
}
