// PL-01 Splash Screen
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/onboarding_preferences.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/tokens.dart';

// ---------------------------------------------------------------------------
// SplashScreen
// Pure launch animation — shown every cold start, no interaction.
// Total duration: ~2 800 ms + a 350 ms hold on the final frame, then
// auth-aware navigation. Same hero photo as the welcome screen (bundled
// asset, not fetched) so the two screens read as one continuous identity.
//   - Session exists  →  /home
//   - No session      →  /welcome
//
// Animation phases (normalized 0.0–1.0 over 2 800 ms):
//   Phase 1  0.000–0.230  N·E·P·A·L letters stagger-fade in (wide tracking)
//   Phase 2  0.230–0.640  letters slide to final PL[▲]NE positions; A crossfades → mountain
//   Phase 3  0.640–1.000  PlanELogo holds; tagline fades in; footer fades in
// Slower and more eased than the original 2 000 ms version — that one
// compressed the NEPAL → PLAN E morph into ~640 ms, too quick to read as a
// deliberate transition rather than a flicker.
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
  late final List<Animation<double>> _letterFades;

  // ── Phase 2: position morph ──────────────────────────────────────────────
  // Normalized x-offsets: source (spread) → target (wordmark) positions.
  //
  // Source order:  N  E  P  A  L   (NEPAL, widely spaced)
  // Target order:  P  L  [▲] N  E  (PL[mountain]NE, compact)
  late final List<Animation<double>> _xMorphs; // 0.0 = source, 1.0 = target

  // ── Phase 2: A → mountain crossfade ──────────────────────────────────────
  late final Animation<double> _letterAFade; // letter 'A' fades OUT
  late final Animation<double> _iconFade;    // mountain icon fades IN

  // ── Phase 3: settle ───────────────────────────────────────────────────────
  // No wordmark fade/swap here anymore — see _LetterRow doc comment for why.
  late final Animation<double> _taglineFade;
  late final Animation<double> _footerFade;
  // Nepal flag, beside the wordmark — starts right where the letter-morph
  // (phase 2) ends, so it reads as the next beat once the jumbling settles,
  // not a simultaneous distraction from it.
  late final Animation<double> _flagFade;

  static const int _letterCount = 5;

  static const Duration _totalDuration = Duration(milliseconds: 2800);
  // Brief pause on the settled logo before handing off — an abrupt cut the
  // instant the fade-in finishes reads as rushed, not premium.
  static const Duration _holdDuration = Duration(milliseconds: 350);

  bool _navigationFired = false;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(vsync: this, duration: _totalDuration);

    // ── Phase 1: staggered letter fades (0.000 → 0.230) ─────────────────
    _letterFades = List.generate(_letterCount, (i) {
      final start = i * 0.038;
      final end = (start + 0.075).clamp(0.0, 0.230);
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _ctrl,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ),
      );
    });

    // ── Phase 2: morph position (0.230 → 0.640) — the visible NEPAL → PLAN E
    // transition; given ~1 150 ms (vs. 640 ms originally) so the slide reads
    // as a deliberate transformation, not a jump-cut.
    _xMorphs = List.generate(_letterCount, (_) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _ctrl,
          curve: const Interval(0.230, 0.640, curve: Curves.easeInOutCubic),
        ),
      );
    });

    // A fades out over the first half of the morph
    _letterAFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.230, 0.430, curve: Curves.easeInCubic),
      ),
    );

    // Mountain icon fades in as the letters settle
    _iconFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.440, 0.640, curve: Curves.easeOutCubic),
      ),
    );

    // ── Phase 3: settle (0.640 → 1.000) ──────────────────────────────────
    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.740, 0.860, curve: Curves.easeOutCubic),
      ),
    );

    _footerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.840, 0.980, curve: Curves.easeOutCubic),
      ),
    );

    _flagFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.640, 0.780, curve: Curves.easeOutCubic),
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
      Future.delayed(_holdDuration, _navigate);
    }
  }

  void _navigate() {
    if (_navigationFired || !mounted) return;
    _navigationFired = true;
    final session = Supabase.instance.client.auth.currentSession;
    // Supabase.initialize() is awaited in main() before runApp(), so this
    // synchronous read is safe — no race condition possible.
    // Guest users never hold a Supabase session — only OnboardingPreferences
    // marks them as done — so session-only was routing them to /welcome
    // (i.e. login) on every replay instead of /home.
    if (session != null || OnboardingPreferences.isCompleted) {
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
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Same bundled hero photo as the welcome screen — one continuous
          // visual identity across launch → welcome, not a plain color
          // screen that then cuts to a photo.
          Image.asset('assets/images/welcome_hero.jpg', fit: BoxFit.cover),
          // Strong, uniform wash — unlike the welcome screen's zoned
          // gradient, splash text can land anywhere over the photo, so it
          // needs guaranteed contrast everywhere, not just in one region.
          Container(color: Colors.white.withValues(alpha: 0.72)),
          SafeArea(
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (context, _) {
                final phase = _ctrl.value;
                final inPhase3 = phase >= 0.640;

                return Stack(
                  children: [
                    // The animated letters stay mounted for the whole
                    // animation — never swapped for a separate "real" logo
                    // widget. A swap between two independently-styled
                    // widgets is exactly what caused the visible jump this
                    // replaces: hand-tuned pixel positions can never
                    // perfectly match a different widget's own layout.
                    // Interval curves hold their end value past their
                    // range, so this keeps rendering the settled "PL[▲]NE"
                    // shape through phase 3 with no further code needed.
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _LetterRow(
                            ctrl: _ctrl,
                            letterFades: _letterFades,
                            xMorphs: _xMorphs,
                            letterAFade: _letterAFade,
                            iconFade: _iconFade,
                            flagFade: _flagFade,
                          ),
                          // Always present, not conditionally added at
                          // phase 3 — this whole group sits inside Center,
                          // so appending a new sibling below the wordmark
                          // once phase 3 starts would change the Column's
                          // total height and force Center to shift the
                          // wordmark upward to re-center the taller group.
                          // That shift was the glitch. Reserving the space
                          // from the start and only animating its opacity
                          // (already 0 before 0.740 — Interval clamps)
                          // keeps the Column's height constant throughout,
                          // so the wordmark never moves once it's landed.
                          const SizedBox(height: 14),
                          // Tagline — sourced from ARB: "Plan Your Experience".
                          // Cursive, not the wordmark's serif — a deliberate
                          // handwritten accent under the formal logotype.
                          Opacity(
                            opacity: _taglineFade.value,
                            child: Text(
                              l10n.tagline,
                              style: TextStyle(
                                fontFamily: 'DancingScript',
                                fontWeight: FontWeight.w600,
                                fontSize: 26,
                                letterSpacing: 0.2,
                                color: AppColors.forest.withValues(alpha: 0.85),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Footer — sourced from ARB: "powered by CodePeak Nepal"
                    if (inPhase3)
                      Positioned(
                        bottom: 24,
                        left: 0,
                        right: 0,
                        child: Opacity(
                          opacity: _footerFade.value * 0.45,
                          child: Text(
                            l10n.splashFooter,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              letterSpacing: 0.3,
                              color: AppColors.forest,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _LetterRow — the wordmark for the whole animation, not just phases 1 & 2.
// ---------------------------------------------------------------------------
//
// Source word: N(0) E(1) P(2) A(3) L(4) — wide letter-spacing
// Target word: P(2) L(4) [▲](3) N(0) E(1) — compact wordmark spacing
//
// Font metrics (size, letterSpacing) match PlanELogo's own formula
// (letterSpacing = fontSize * .16) by construction, since this widget
// stands in for it for the entire animation rather than being replaced by
// a real PlanELogo instance partway through.
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
    required this.flagFade,
  });

  final AnimationController ctrl;
  final List<Animation<double>> letterFades;
  final List<Animation<double>> xMorphs;
  final Animation<double> letterAFade;
  final Animation<double> iconFade;
  final Animation<double> flagFade;

  // Source x-positions (fractional, center of each letter slot) — 5 slots
  // evenly spaced and symmetric around 0.5, not left-shifted.
  static const List<double> _sourceX = [0.17, 0.335, 0.5, 0.665, 0.83];

  // Target x-positions for the settled wordmark — centered on 0.5, spaced
  // wider than the source to fit PlanELogo's letterSpacing (fontSize * .16,
  // considerably wider than phase 1's tight NEPAL tracking).
  static const List<double> _targetSlotX = [0.315, 0.39, 0.49, 0.59, 0.665];

  // Map each source slot (N E P A L) to a target slot index (P L ▲ N E)
  //   N → target slot 3,  E → 4,  P → 0,  A → 2,  L → 1
  static const List<int> _slotMap = [3, 4, 0, 2, 1];

  // Labels for each source slot
  static const List<String> _labels = ['N', 'E', 'P', 'A', 'L'];

  static const double _fontSize = 42.0;

  TextStyle get _letterStyle => const TextStyle(
        fontFamily: 'serif',
        fontSize: _fontSize,
        fontWeight: FontWeight.w700,
        letterSpacing: _fontSize * 0.16,
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
            children: [
              ...List.generate(5, (i) {
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
              // Nepal flag — sits just right of the settled 'E', same
              // cap-height as the wordmark letters. Anchored off the same
              // morph math as source-index 1 ('E') so it tracks alongside
              // it instead of being pinned to a hardcoded position.
              Builder(builder: (context) {
                const int eSourceIndex = 1;
                final eSrcX = _sourceX[eSourceIndex] * w;
                final eTgtX = _targetSlotX[_slotMap[eSourceIndex]] * w;
                final eCurrentX = eSrcX + (eTgtX - eSrcX) * xMorphs[eSourceIndex].value;
                return Positioned(
                  left: eCurrentX + _fontSize * 0.5,
                  top: _fontSize * 0.35,
                  child: Opacity(
                    opacity: flagFade.value,
                    child: const Text(
                      // Emoji glyphs fill much more of their em-box than a
                      // serif capital does at the same fontSize — 0.62x is
                      // what actually matches the letters' visible size.
                      '🇳🇵',
                      style: TextStyle(fontSize: _fontSize * 0.62),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
      ),
    );
  }
}
