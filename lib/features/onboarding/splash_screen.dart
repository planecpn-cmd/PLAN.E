// PL-01 Splash Screen
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/tokens.dart';
import '../../widgets/plan_e_logo.dart';

// ---------------------------------------------------------------------------
// SplashScreen
// Pure launch animation — shown every cold start, no interaction.
// Total duration: ~2 000 ms, then auth-aware navigation.
//   - Session exists  →  /home
//   - No session      →  /welcome
//
// Animation phases (normalized 0.0–1.0 over 2 000 ms):
//   Phase 1  0.000–0.280  N·E·P·A·L letters stagger-fade in (wide tracking)
//   Phase 2  0.280–0.600  letters slide to final PL[▲]NE positions; A crossfades → mountain
//   Phase 3  0.600–1.000  PlanELogo holds; tagline fades in; footer fades in
// ---------------------------------------------------------------------------

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  // ── Phase 1: per-letter fade-in ──────────────────────────────────────────
  // Source word N E P A L → indices 0..4
  // Each letter starts at (i * 0.050) and fully opaque by (start + 0.055)
  late final List<Animation<double>> _letterFades;

  // ── Phase 2: position morph ──────────────────────────────────────────────
  // Normalized x-offsets: source (spread) → target (wordmark) positions.
  // Expressed as fractions of the available row width; resolved at paint time.
  //
  // Source order:  N  E  P  A  L   (NEPAL, widely spaced)
  // Target order:  P  L  [▲] N  E  (PL[mountain]NE, compact)
  //
  // We track each *letter* slot (not position slot), so:
  //   slot 0 = 'N' : source pos 0 → target pos 3
  //   slot 1 = 'E' : source pos 1 → target pos 4
  //   slot 2 = 'P' : source pos 2 → target pos 0
  //   slot 3 = 'A' : source pos 3 → target pos 2  (becomes mountain)
  //   slot 4 = 'L' : source pos 4 → target pos 1

  late final List<Animation<double>> _xMorphs; // 0.0 = source, 1.0 = target

  // ── Phase 2: A → mountain crossfade ──────────────────────────────────────
  late final Animation<double> _letterAFade; // letter 'A' fades OUT
  late final Animation<double> _iconFade;    // mountain icon fades IN

  // ── Phase 3: settle ───────────────────────────────────────────────────────
  late final Animation<double> _wordmarkFade;
  late final Animation<double> _taglineFade;
  late final Animation<double> _footerFade;

  // Resolved layout geometry (set in LayoutBuilder during Phase 1/2)
  static const int _letterCount = 5;

  static const Duration _totalDuration = Duration(milliseconds: 2000);

  bool _navigationFired = false;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(vsync: this, duration: _totalDuration);

    // ── Reduced-motion: skip straight to final frame ──────────────────────
    // Checked here; WidgetsBinding is already initialized at this point.
    // We re-check in didChangeDependencies once context is available.

    // ── Phase 1: staggered letter fades (0.000 → 0.280) ─────────────────
    _letterFades = List.generate(_letterCount, (i) {
      final start = i * 0.050;
      final end = (start + 0.055).clamp(0.0, 0.280);
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _ctrl,
          curve: Interval(start, end, curve: Curves.easeIn),
        ),
      );
    });

    // ── Phase 2: morph position (0.280 → 0.600) ──────────────────────────
    // Each animation drives t from 0 (source pos) to 1 (target pos).
    _xMorphs = List.generate(_letterCount, (_) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _ctrl,
          curve: const Interval(0.280, 0.600, curve: Curves.easeInOut),
        ),
      );
    });

    // A fades out 0.280–0.440
    _letterAFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.280, 0.440, curve: Curves.easeIn),
      ),
    );

    // Mountain icon fades in 0.400–0.600
    _iconFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.400, 0.600, curve: Curves.easeOut),
      ),
    );

    // ── Phase 3: settle (0.600 → 1.000) ──────────────────────────────────
    _wordmarkFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.600, 0.720, curve: Curves.easeOut),
      ),
    );

    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.680, 0.820, curve: Curves.easeOut),
      ),
    );

    _footerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.800, 0.960, curve: Curves.easeOut),
      ),
    );

    _ctrl.addStatusListener(_onAnimationStatus);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reduced-motion: skip animation, show final frame, navigate after short delay.
    if (MediaQuery.of(context).disableAnimations) {
      _ctrl.value = 1.0;
      Future.delayed(const Duration(milliseconds: 400), _navigate);
    } else {
      _ctrl.forward();
    }
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _navigate();
    }
  }

  void _navigate() {
    if (_navigationFired || !mounted) return;
    _navigationFired = true;
    final session = Supabase.instance.client.auth.currentSession;
    // Supabase.initialize() is awaited in main() before runApp(), so this
    // synchronous read is safe — no race condition possible.
    if (session != null) {
      context.go('/home');
    } else {
      context.go('/welcome');
    }
  }

  @override
  void dispose() {
    _ctrl.removeStatusListener(_onAnimationStatus);
    _ctrl.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              // Top: ivory blended 35% toward white — lighter, no hardcoded hex
              Color.lerp(AppColors.ivory, Colors.white, 0.35)!,
              // Bottom: ivory as-is
              AppColors.ivory,
            ],
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) {
              final phase = _ctrl.value;
              // Phase 3 starts at 0.600
              final inPhase3 = phase >= 0.600;

              return Stack(
                children: [
                  // ── Phase 1 & 2: letter animation ─────────────────────
                  if (!inPhase3)
                    Center(
                      child: _LetterRow(
                        ctrl: _ctrl,
                        letterFades: _letterFades,
                        xMorphs: _xMorphs,
                        letterAFade: _letterAFade,
                        iconFade: _iconFade,
                      ),
                    ),

                  // ── Phase 3: final wordmark + tagline + footer ─────────
                  if (inPhase3) ...[
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Wordmark
                          Opacity(
                            opacity: _wordmarkFade.value,
                            child: const PlanELogo(fontSize: 32),
                          ),
                          const SizedBox(height: 12),
                          // Tagline — sourced from ARB: "Plan Your Experience"
                          Opacity(
                            opacity: _taglineFade.value,
                            child: Text(
                              l10n.tagline,
                              style: TextStyle(
                                fontFamily: 'serif',
                                fontSize: 15,
                                letterSpacing: 0.4,
                                color: AppColors.forest
                                    .withValues(alpha: 0.72),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Footer — sourced from ARB: "powered by CodePeak Nepal"
                    Positioned(
                      bottom: 24,
                      left: 0,
                      right: 0,
                      child: Opacity(
                        opacity: _footerFade.value * 0.38,
                        child: Text(
                          l10n.splashFooter,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11,
                            letterSpacing: 0.3,
                            color: AppColors.forest,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _LetterRow — Phase 1 & 2 animation widget
// ---------------------------------------------------------------------------
//
// Source word: N(0) E(1) P(2) A(3) L(4) — wide letter-spacing
// Target word: P(2) L(4) [▲](3) N(0) E(1) — compact, PlanELogo spacing
//
// Each letter is placed absolutely using fractional x-positions resolved
// from the LayoutBuilder width.

class _LetterRow extends StatelessWidget {
  const _LetterRow({
    required this.ctrl,
    required this.letterFades,
    required this.xMorphs,
    required this.letterAFade,
    required this.iconFade,
  });

  final AnimationController ctrl;
  final List<Animation<double>> letterFades;
  final List<Animation<double>> xMorphs;
  final Animation<double> letterAFade;
  final Animation<double> iconFade;

  // Source x-positions (fractional, center of each letter slot)
  // Spread over ~70% of screen width, 5 slots evenly spaced.
  static const List<double> _sourceX = [0.10, 0.25, 0.42, 0.58, 0.75];

  // Target x-positions matching PlanELogo's tight serif tracking.
  // Order matches target word P L [▲] N E (slots 0..4).
  // Absolute target slot positions:
  static const List<double> _targetSlotX = [0.32, 0.38, 0.455, 0.535, 0.61];

  // Map each source slot (N E P A L) to a target slot index (P L ▲ N E)
  //   N → target slot 3,  E → 4,  P → 0,  A → 2,  L → 1
  static const List<int> _slotMap = [3, 4, 0, 2, 1];

  // Labels for each source slot
  static const List<String> _labels = ['N', 'E', 'P', 'A', 'L'];

  static const double _fontSize = 30.0;

  TextStyle get _letterStyle => const TextStyle(
        fontFamily: 'serif',
        fontSize: _fontSize,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
        color: AppColors.forest,
      );

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'NEPAL',
      child: LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;

        return SizedBox(
          width: w,
          height: _fontSize * 1.4,
          child: Stack(
            children: List.generate(5, (i) {
              final srcX = _sourceX[i] * w;
              final tgtX = _targetSlotX[_slotMap[i]] * w;
              final t = xMorphs[i].value;
              final currentX = srcX + (tgtX - srcX) * t;

              // Slot 3 = 'A' → crossfade to mountain icon
              if (i == 3) {
                return Positioned(
                  left: currentX - _fontSize * 0.5,
                  top: 0,
                  child: Opacity(
                    opacity: letterFades[i].value,
                    child: SizedBox(
                      width: _fontSize,
                      height: _fontSize * 1.4,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 'A' fades out
                          Opacity(
                            opacity: letterAFade.value,
                            child: Text('A', style: _letterStyle),
                          ),
                          // Mountain icon fades in
                          Opacity(
                            opacity: iconFade.value,
                            child: const Icon(
                              Icons.landscape_outlined,
                              size: _fontSize * 0.9,
                              color: AppColors.forest,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              // All other letters: fade in, then slide to position
              return Positioned(
                left: currentX - _fontSize * 0.35,
                top: 0,
                child: Opacity(
                  opacity: letterFades[i].value,
                  child: Text(_labels[i], style: _letterStyle),
                ),
              );
            }),
          ),
        );
      },
      ),
    );
  }
}
