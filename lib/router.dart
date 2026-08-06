import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'core/onboarding_preferences.dart';
import 'theme/tokens.dart';
import 'features/onboarding/splash_screen.dart';
import 'features/onboarding/onboarding_slide_screen.dart';
import 'features/onboarding/interests_screen.dart';

import 'features/auth/sign_up_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/forgot_password_screen.dart';
import 'features/auth/reset_result_screen.dart';
import 'features/auth/auth_required_sheet.dart';

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

import 'features/trips/trips_screen.dart';
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

import 'features/host/become_host_screen.dart';
import 'features/host/host_step_1_screen.dart';
import 'features/host/host_step_2_screen.dart';
import 'features/host/host_step_3_screen.dart';
import 'features/host/host_step_4_screen.dart';
import 'features/host/application_submitted_screen.dart';

import 'features/dev/routes_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>();

final GoRouter router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  redirect: (context, state) {
    final path = state.uri.path;
    final isOnboardingRoute =
        path == '/' || path.startsWith('/onboarding/') || path == '/interests';
    if (OnboardingPreferences.isCompleted && isOnboardingRoute) {
      return '/home';
    }
    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
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
                          label: '',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.explore_outlined),
                          activeIcon: Icon(Icons.explore),
                          label: '',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.event_note_outlined),
                          activeIcon: Icon(Icons.event_note),
                          label: '',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.card_travel_outlined),
                          activeIcon: Icon(Icons.card_travel),
                          label: '',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.person_outline),
                          activeIcon: Icon(Icons.person),
                          label: '',
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
          builder: (context, state) => const ExploreScreen(),
        ),
        GoRoute(
          path: '/search',
          builder: (context, state) => SearchResultsScreen(
            initialQuery: state.uri.queryParameters['query'],
            initialCategoryId: state.uri.queryParameters['category_id'],
            initialRegionId: state.uri.queryParameters['region_id'],
            initialDifficulty: state.uri.queryParameters['difficulty'],
            initialSortBy: state.uri.queryParameters['sort_by'],
          ),
        ),
        GoRoute(
          path: '/plans',
          builder: (context, state) => const PlansScreen(),
        ),
        GoRoute(
          path: '/trips',
          builder: (context, state) => const TripsScreen(),
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
    GoRoute(path: '/saved', builder: (context, state) => const SavedScreen()),
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
      path: '/review/:bookingId',
      builder: (context, state) =>
          LeaveReviewScreen(bookingId: state.pathParameters['bookingId'] ?? ''),
    ),
    GoRoute(
      path: '/review/submitted',
      builder: (context, state) => const ReviewSubmittedScreen(),
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
      path: '/host',
      builder: (context, state) => const BecomeHostScreen(),
    ),
    GoRoute(
      path: '/host/step-1',
      builder: (context, state) => const HostStep1Screen(),
    ),
    GoRoute(
      path: '/host/step-2',
      builder: (context, state) => const HostStep2Screen(),
    ),
    GoRoute(
      path: '/host/step-3',
      builder: (context, state) => const HostStep3Screen(),
    ),
    GoRoute(
      path: '/host/step-4',
      builder: (context, state) => const HostStep4Screen(),
    ),
    GoRoute(
      path: '/host/submitted',
      builder: (context, state) => const ApplicationSubmittedScreen(),
    ),
  ],
);

int _calculateSelectedIndex(String location) {
  if (location.startsWith('/explore') || location.startsWith('/search')) {
    return 1;
  }
  if (location.startsWith('/plans')) return 2;
  if (location.startsWith('/trips')) return 3;
  if (location.startsWith('/profile')) return 4;
  return 0;
}

class _DoubleBackToExit extends StatefulWidget {
  final Widget child;

  const _DoubleBackToExit({required this.child});

  @override
  State<_DoubleBackToExit> createState() => _DoubleBackToExitState();
}

class _DoubleBackToExitState extends State<_DoubleBackToExit> {
  DateTime? _lastBackPress;

  Future<void> _onPopInvoked(bool didPop, Object? result) async {
    if (didPop) return;
    final now = DateTime.now();
    if (_lastBackPress != null &&
        now.difference(_lastBackPress!) < const Duration(seconds: 2)) {
      await SystemNavigator.pop();
      return;
    }

    _lastBackPress = now;
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Press back again to exit'),
          duration: Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _onPopInvoked,
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
      context.go('/trips');
      break;
    case 4:
      context.go('/profile');
      break;
  }
}
