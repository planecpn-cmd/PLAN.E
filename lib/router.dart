import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'core/onboarding_preferences.dart';
import 'theme/tokens.dart';
import 'features/onboarding/splash_screen.dart';
import 'features/onboarding/welcome_screen.dart';
import 'features/onboarding/onboarding_slide_screen.dart';
import 'features/onboarding/interests_screen.dart';

import 'features/auth/sign_up_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/forgot_password_screen.dart';
import 'features/auth/reset_result_screen.dart';
import 'features/auth/auth_required_sheet.dart';
import 'features/auth/otp_verification_screen.dart';
import 'features/auth/set_new_password_screen.dart';

import 'features/home/home_screen.dart';
import 'features/explore/explore_screen.dart';
import 'features/explore/map_screen.dart';
import 'features/search/search_results_screen.dart';
import 'features/search/collection_screen.dart';
import 'features/search/filter_sheet.dart';
import 'features/experience/experience_detail_screen.dart';
import 'features/booking/booking_screen.dart';
import 'features/booking/confirmation_screen.dart';
import 'features/saved/saved_screen.dart';
import 'features/plans/plans_screen.dart';
import 'features/plans/itinerary_screen.dart';
import 'features/plans/trip_chat_screen.dart';
import 'features/plans/gear_checklist_screen.dart';
import 'features/plans/budget_tracker_screen.dart';

import 'features/trips/leave_review_screen.dart';
import 'features/trips/review_submitted_screen.dart';

import 'features/profile/profile_screen.dart';
import 'features/profile/edit_profile_screen.dart';
import 'features/profile/payment_methods_screen.dart';
import 'features/profile/notifications_screen.dart';
import 'features/profile/language_region_screen.dart';
import 'features/profile/help_support_screen.dart';
import 'features/profile/more_settings_screen.dart';
import 'features/profile/my_reviews_screen.dart';
import 'features/profile/moderation_queue_screen.dart';

import 'features/host/become_host_screen.dart';
import 'features/host/host_step_1_screen.dart';
import 'features/host/host_step_2_screen.dart';
import 'features/host/host_step_3_screen.dart';
import 'features/host/host_step_4_screen.dart';
import 'features/host/application_submitted_screen.dart';
import 'features/host/host_dashboard_screen.dart';
import 'features/host/presentation/host_experiences_screen.dart';
import 'features/host/presentation/host_experience_detail_screen.dart';
import 'features/host/presentation/create_host_experience_screen.dart';
import 'features/host/presentation/host_bookings_screen.dart';
import 'features/host/presentation/host_booking_detail_screen.dart';
import 'features/host/presentation/host_messages_screen.dart';
import 'features/host/presentation/host_profile_screen.dart';
import 'features/host/presentation/host_experience_preview_screen.dart';
import 'features/host/presentation/host_experience_submitted_screen.dart';
import 'features/host/presentation/host_listing_preview_screen.dart';
import 'features/host/presentation/host_availability_screen.dart';
import 'features/host/presentation/host_conversation_screen.dart';
import 'features/host/presentation/host_guest_list_screen.dart';
import 'features/host/presentation/host_traveler_detail_screen.dart';
import 'features/host/presentation/widgets/host_mode_access_gate.dart';
import 'features/host/presentation/widgets/host_application_auth_gate.dart';
import 'features/host/presentation/host_business_screen.dart';
import 'features/host/presentation/edit_host_profile_screen.dart';
import 'features/host/presentation/host_departure_detail_screen.dart';
import 'features/host/domain/host_mode_models.dart';

import 'features/dev/routes_screen.dart';
import 'features/notifications/notification_feed_screen.dart';
import 'features/ai_itinerary/ai_itinerary_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>();

final GoRouter router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  redirect: (context, state) {
    final path = state.uri.path;
    // '/' (splash) is deliberately NOT in this list. It used to be, which
    // meant any navigation back to '/' after onboarding was complete (e.g.
    // main.dart's replay-splash-on-resume) got silently redirected straight
    // to /home before SplashScreen ever mounted — the splash would only
    // ever play pre-login, never after, since login/guest both complete
    // onboarding. Splash already has its own logic (in _navigate()) to send
    // a returning, already-onboarded user to /home after the animation, so
    // it doesn't need this redirect to do that job for it.
    final isOnboardingRoute =
        path.startsWith('/onboarding/') || path == '/interests';
    if (OnboardingPreferences.isCompleted && isOnboardingRoute) {
      return '/home';
    }
    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(
      path: '/admin/message-moderation',
      builder: (context, state) => const ModerationQueueScreen(),
    ),
    GoRoute(
      path: '/welcome',
      builder: (context, state) => const WelcomeScreen(),
    ),
    if (kDebugMode)
      GoRoute(
        path: '/dev/routes',
        builder: (context, state) => const DevRoutesScreen(),
      ),
    GoRoute(
      path: '/onboarding/1',
      builder: (context, state) => const OnboardingSlideScreen(step: 1),
    ),
    GoRoute(
      path: '/onboarding/2',
      builder: (context, state) => const OnboardingSlideScreen(step: 2),
    ),
    GoRoute(
      path: '/onboarding/3',
      builder: (context, state) => const OnboardingSlideScreen(step: 3),
    ),
    GoRoute(
      path: '/interests',
      builder: (context, state) => const InterestsScreen(),
    ),
    GoRoute(
      path: '/auth/sign-up',
      builder: (context, state) => const SignUpScreen(),
    ),
    GoRoute(
      path: '/auth/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/auth/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/auth/reset-result',
      builder: (context, state) => const ResetResultScreen(),
    ),
    GoRoute(
      path: '/auth/otp-verify',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return OtpVerificationScreen(
          email: extra?['email'] as String? ?? '',
          isRecovery: extra?['purpose'] == 'recovery',
        );
      },
    ),
    GoRoute(
      path: '/auth/set-new-password',
      builder: (context, state) => const SetNewPasswordScreen(),
    ),
    GoRoute(
      path: '/auth/required',
      builder: (context, state) => const AuthRequiredSheet(),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return _DoubleBackToExit(
          child: Scaffold(
            extendBody: true,
            body: child,
            bottomNavigationBar: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Container(
                  height: 58,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: AppColors.borderSubtle,
                      width: 1.0,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x18000000),
                        blurRadius: 16,
                        spreadRadius: 0,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BottomNavigationBar(
                      currentIndex: _calculateSelectedIndex(state.uri.path),
                      onTap: (index) => _onItemTapped(index, context),
                      elevation: 0,
                      backgroundColor: AppColors.white,
                      selectedItemColor: AppColors.forest,
                      unselectedItemColor: AppColors.ink.withValues(
                        alpha: 0.45,
                      ),
                      type: BottomNavigationBarType.fixed,
                      showSelectedLabels: false,
                      showUnselectedLabels: false,
                      iconSize: 26,
                      items: const [
                        BottomNavigationBarItem(
                          icon: Icon(Icons.home_outlined),
                          activeIcon: Icon(Icons.home),
                          label: 'Home',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.explore_outlined),
                          activeIcon: Icon(Icons.explore),
                          label: 'Explore',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.event_note_outlined),
                          activeIcon: Icon(Icons.event_note),
                          label: 'Plans',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.bookmark_outline),
                          activeIcon: Icon(Icons.bookmark),
                          label: 'Saved',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.person_outline),
                          activeIcon: Icon(Icons.person),
                          label: 'Profile',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      routes: [
        GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/explore',
          builder: (context, state) =>
              ExploreScreen(initialQuery: state.uri.queryParameters['query']),
        ),
        GoRoute(
          path: '/search',
          builder: (context, state) => SearchResultsScreen(
            initialQuery: state.uri.queryParameters['query'],
            initialCategoryId: state.uri.queryParameters['category_id'],
            initialFamilySlug: state.uri.queryParameters['family'],
            initialRegionId: state.uri.queryParameters['region_id'],
            initialDifficulty: state.uri.queryParameters['difficulty'],
            initialMaxDurationHours: int.tryParse(
              state.uri.queryParameters['max_duration_hours'] ?? '',
            ),
            initialSortBy: state.uri.queryParameters['sort_by'],
          ),
        ),
        GoRoute(
          path: '/plans',
          builder: (context, state) => PlansScreen(
            initialTab: planTabFromQuery(state.uri.queryParameters['tab']),
          ),
        ),
        GoRoute(
          path: '/trips',
          redirect: (context, state) => '/plans?tab=past',
        ),
        GoRoute(
          path: '/saved',
          builder: (context, state) => const SavedScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/collection/:slug',
      builder: (context, state) =>
          CollectionScreen(slug: state.pathParameters['slug'] ?? ''),
    ),
    GoRoute(path: '/filter', builder: (context, state) => const FilterSheet()),
    GoRoute(
      path: '/experience/:id',
      builder: (context, state) =>
          ExperienceDetailScreen(id: state.pathParameters['id'] ?? ''),
    ),
    GoRoute(path: '/map', builder: (context, state) => const MapScreen()),
    GoRoute(
      path: '/booking/:id',
      builder: (context, state) =>
          BookingScreen(experienceId: state.pathParameters['id'] ?? ''),
    ),
    GoRoute(
      path: '/booking/confirmation/:bookingId',
      builder: (context, state) => ConfirmationScreen(
        bookingId: state.pathParameters['bookingId'] ?? '',
      ),
    ),
    GoRoute(
      path: '/itinerary/:bookingId',
      builder: (context, state) =>
          ItineraryScreen(bookingId: state.pathParameters['bookingId'] ?? ''),
    ),
    GoRoute(
      path: '/chat/:bookingId',
      builder: (context, state) =>
          TripChatScreen(bookingId: state.pathParameters['bookingId'] ?? ''),
    ),
    GoRoute(
      path: '/gear/:bookingId',
      builder: (context, state) => GearChecklistScreen(
        bookingId: state.pathParameters['bookingId'] ?? '',
      ),
    ),
    GoRoute(
      path: '/budget/:bookingId',
      builder: (context, state) => BudgetTrackerScreen(
        bookingId: state.pathParameters['bookingId'] ?? '',
      ),
    ),
    GoRoute(
      path: '/review/submitted',
      builder: (context, state) => const ReviewSubmittedScreen(),
    ),
    GoRoute(
      path: '/review/:bookingId',
      builder: (context, state) =>
          LeaveReviewScreen(bookingId: state.pathParameters['bookingId'] ?? ''),
    ),
    GoRoute(
      path: '/profile/edit',
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: '/profile/payment-methods',
      builder: (context, state) => const PaymentMethodsScreen(),
    ),
    GoRoute(
      path: '/profile/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/profile/language',
      builder: (context, state) => const LanguageRegionScreen(),
    ),
    GoRoute(
      path: '/profile/help',
      builder: (context, state) => const HelpSupportScreen(),
    ),
    GoRoute(
      path: '/profile/settings',
      builder: (context, state) => const MoreSettingsScreen(),
    ),
    GoRoute(
      path: '/profile/my-reviews',
      builder: (context, state) => const MyReviewsScreen(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationFeedScreen(),
    ),
    GoRoute(
      path: '/ai-planner',
      builder: (context, state) => const AiItineraryScreen(),
    ),
    GoRoute(
      path: '/host',
      builder: (context, state) =>
          const HostApplicationAuthGate(child: BecomeHostScreen()),
    ),
    GoRoute(
      path: '/host/dashboard',
      builder: (context, state) =>
          const HostModeAccessGate(child: HostDashboardScreen()),
    ),
    GoRoute(
      path: '/host/experiences',
      builder: (context, state) => HostModeAccessGate(
        child: HostExperiencesScreen(
          initialFilter: _hostExperienceStatus(
            state.uri.queryParameters['status'],
          ),
          hasInitialFilter: state.uri.queryParameters.containsKey('status'),
        ),
      ),
    ),
    GoRoute(
      path: '/host/experiences/create',
      builder: (context, state) =>
          _hostModePage(const CreateHostExperienceScreen()),
    ),
    GoRoute(
      path: '/host/experiences/create/preview',
      builder: (context, state) =>
          _hostModePage(const HostExperiencePreviewScreen()),
    ),
    GoRoute(
      path: '/host/experiences/submitted',
      builder: (context, state) =>
          _hostModePage(const HostExperienceSubmittedScreen()),
    ),
    GoRoute(
      path: '/host/experiences/:id/preview',
      builder: (context, state) => _hostModePage(
        HostListingPreviewScreen(id: state.pathParameters['id'] ?? ''),
      ),
    ),
    GoRoute(
      path: '/host/experiences/:id/edit',
      builder: (context, state) => _hostModePage(
        CreateHostExperienceScreen(experienceId: state.pathParameters['id']),
      ),
    ),
    GoRoute(
      path: '/host/experiences/:id/availability',
      builder: (context, state) => _hostModePage(
        HostAvailabilityScreen(id: state.pathParameters['id'] ?? ''),
      ),
    ),
    GoRoute(
      path: '/host/experiences/:id',
      builder: (context, state) => _hostModePage(
        HostExperienceDetailScreen(id: state.pathParameters['id'] ?? ''),
      ),
    ),
    GoRoute(
      path: '/host/bookings',
      builder: (context, state) => HostModeAccessGate(
        child: HostBookingsScreen(
          initialFilter: _hostBookingStatus(
            state.uri.queryParameters['status'],
          ),
          hasInitialFilter: state.uri.queryParameters.containsKey('status'),
          experienceId: state.uri.queryParameters['experience'],
        ),
      ),
    ),
    GoRoute(
      path: '/host/bookings/:id',
      builder: (context, state) => _hostModePage(
        HostBookingDetailScreen(id: state.pathParameters['id'] ?? ''),
      ),
    ),
    GoRoute(
      path: '/host/messages',
      builder: (context, state) => HostModeAccessGate(
        child: HostMessagesScreen(
          initialQuery: state.uri.queryParameters['q'] ?? '',
        ),
      ),
    ),
    GoRoute(
      path: '/host/messages/:id',
      builder: (context, state) => _hostModePage(
        HostConversationScreen(id: state.pathParameters['id'] ?? ''),
      ),
    ),
    GoRoute(
      path: '/host/departures/:experienceId',
      builder: (context, state) => _hostModePage(
        HostDepartureDetailScreen(
          experienceId: state.pathParameters['experienceId'] ?? '',
        ),
      ),
    ),
    GoRoute(
      path: '/host/departures/:experienceId/guests',
      builder: (context, state) => _hostModePage(
        HostGuestListScreen(
          experienceId: state.pathParameters['experienceId'] ?? '',
        ),
      ),
    ),
    GoRoute(
      path: '/host/bookings/:bookingId/travelers/:travelerId',
      builder: (context, state) => _hostModePage(
        HostTravelerDetailScreen(
          bookingId: state.pathParameters['bookingId'] ?? '',
          travelerId: state.pathParameters['travelerId'] ?? '',
        ),
      ),
    ),
    GoRoute(
      path: '/host/profile',
      builder: (context, state) =>
          const HostModeAccessGate(child: HostProfileScreen()),
    ),
    GoRoute(
      path: '/host/profile/public',
      builder: (context, state) => _hostModePage(
        const HostBusinessScreen(page: HostBusinessPage.publicProfile),
      ),
    ),
    GoRoute(
      path: '/host/profile/edit',
      builder: (context, state) => _hostModePage(const EditHostProfileScreen()),
    ),
    GoRoute(
      path: '/host/profile/verification',
      builder: (context, state) => _hostModePage(
        const HostBusinessScreen(page: HostBusinessPage.verification),
      ),
    ),
    GoRoute(
      path: '/host/profile/earnings',
      builder: (context, state) => _hostModePage(
        const HostBusinessScreen(page: HostBusinessPage.earnings),
      ),
    ),
    GoRoute(
      path: '/host/profile/reviews',
      builder: (context, state) => _hostModePage(
        const HostBusinessScreen(page: HostBusinessPage.reviews),
      ),
    ),
    GoRoute(
      path: '/host/profile/history',
      builder: (context, state) => _hostModePage(
        const HostBusinessScreen(page: HostBusinessPage.history),
      ),
    ),
    GoRoute(
      path: '/host/profile/notifications',
      builder: (context, state) => _hostModePage(
        const HostBusinessScreen(page: HostBusinessPage.notifications),
      ),
    ),
    GoRoute(
      path: '/host/profile/help',
      builder: (context, state) =>
          _hostModePage(const HostBusinessScreen(page: HostBusinessPage.help)),
    ),
    GoRoute(
      path: '/host/profile/guidelines',
      builder: (context, state) => _hostModePage(
        const HostBusinessScreen(page: HostBusinessPage.guidelines),
      ),
    ),
    GoRoute(
      path: '/host/profile/terms',
      builder: (context, state) =>
          _hostModePage(const HostBusinessScreen(page: HostBusinessPage.terms)),
    ),
    GoRoute(
      path: '/host/step-1',
      builder: (context, state) =>
          const HostApplicationAuthGate(child: HostStep1Screen()),
    ),
    GoRoute(
      path: '/host/step-2',
      builder: (context, state) =>
          const HostApplicationAuthGate(child: HostStep2Screen()),
    ),
    GoRoute(
      path: '/host/step-3',
      builder: (context, state) =>
          const HostApplicationAuthGate(child: HostStep3Screen()),
    ),
    GoRoute(
      path: '/host/step-4',
      builder: (context, state) =>
          const HostApplicationAuthGate(child: HostStep4Screen()),
    ),
    GoRoute(
      path: '/host/submitted',
      builder: (context, state) =>
          const HostApplicationAuthGate(child: ApplicationSubmittedScreen()),
    ),
  ],
);

int _calculateSelectedIndex(String location) {
  if (location.startsWith('/explore') || location.startsWith('/search')) {
    return 1;
  }
  if (location.startsWith('/plans')) return 2;
  if (location.startsWith('/trips')) return 2;
  if (location.startsWith('/saved')) return 3;
  if (location.startsWith('/profile')) return 4;
  return 0;
}

HostExperienceStatus? _hostExperienceStatus(String? value) => switch (value) {
  'active' => HostExperienceStatus.active,
  'draft' => HostExperienceStatus.draft,
  'pendingReview' => HostExperienceStatus.pendingReview,
  'paused' => HostExperienceStatus.paused,
  _ => null,
};

HostBookingStatus? _hostBookingStatus(String? value) => switch (value) {
  'requested' => HostBookingStatus.requested,
  'confirmed' => HostBookingStatus.confirmed,
  'completed' => HostBookingStatus.completed,
  'cancelled' => HostBookingStatus.cancelled,
  _ => null,
};

Widget _hostModePage(Widget child) => HostModeAccessGate(child: child);

/// Double-back-to-exit for the bottom-nav tabs.
///
/// Uses BackButtonListener rather than PopScope. PopScope only works when it
/// can register with an enclosing ModalRoute; placing it in MaterialApp's
/// `builder` puts it *above* the router's Navigator where there is no route
/// to attach to, so it silently never fires and back closed the app outright.
/// BackButtonListener hooks the root back-button dispatcher directly, so it
/// runs regardless of which navigator owns the current route.
///
/// Returning true consumes the press; false lets it fall through to normal
/// back-navigation. Only the tab roots reach here with nothing to pop, so a
/// pushed detail screen still pops normally on the first press.
class _DoubleBackToExit extends StatefulWidget {
  final Widget child;

  const _DoubleBackToExit({required this.child});

  @override
  State<_DoubleBackToExit> createState() => _DoubleBackToExitState();
}

class _DoubleBackToExitState extends State<_DoubleBackToExit> {
  DateTime? _lastBackPress;

  Future<bool> _onBackPressed() async {
    // Something to go back to (a pushed screen above the shell) — let the
    // normal pop happen instead of treating this as an exit attempt.
    if (router.canPop()) return false;

    final now = DateTime.now();
    if (_lastBackPress != null &&
        now.difference(_lastBackPress!) < const Duration(seconds: 2)) {
      await SystemNavigator.pop();
      return true;
    }

    _lastBackPress = now;
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Press back again to exit'),
            duration: Duration(seconds: 2),
          ),
        );
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return BackButtonListener(
      onBackButtonPressed: _onBackPressed,
      child: widget.child,
    );
  }
}

void _onItemTapped(int index, BuildContext context) {
  switch (index) {
    case 0:
      context.go('/home');
      break;
    case 1:
      context.go('/explore');
      break;
    case 2:
      context.go('/plans');
      break;
    case 3:
      context.go('/saved');
      break;
    case 4:
      context.go('/profile');
      break;
  }
}
