import 'package:flutter/material.dart';

/// Renders the complete application against a slightly larger logical
/// viewport, then fits it back into the device viewport.
///
/// This keeps typography, spacing, controls, routes, dialogs, sheets, and
/// overlays at the same proportions while reducing their rendered size.
class ScaledAppViewport extends StatelessWidget {
  static const double scale = 0.95;

  final Widget child;

  const ScaledAppViewport({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportSize = Size(
          constraints.maxWidth / scale,
          constraints.maxHeight / scale,
        );
        final scaledMediaQuery = mediaQuery.copyWith(
          size: viewportSize,
          padding: _unscale(mediaQuery.padding),
          viewPadding: _unscale(mediaQuery.viewPadding),
          viewInsets: _unscale(mediaQuery.viewInsets),
          systemGestureInsets: _unscale(mediaQuery.systemGestureInsets),
        );

        return FittedBox(
          fit: BoxFit.fill,
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: viewportSize.width,
            height: viewportSize.height,
            child: MediaQuery(data: scaledMediaQuery, child: child),
          ),
        );
      },
    );
  }

  EdgeInsets _unscale(EdgeInsets insets) => EdgeInsets.fromLTRB(
    insets.left / scale,
    insets.top / scale,
    insets.right / scale,
    insets.bottom / scale,
  );
}
