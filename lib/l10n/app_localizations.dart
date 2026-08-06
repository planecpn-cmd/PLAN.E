import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ne.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ne'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'PLAN E'**
  String get appTitle;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Plan Your Experience'**
  String get tagline;

  /// No description provided for @splashFooter.
  ///
  /// In en, this message translates to:
  /// **'powered by CodePeak Nepal'**
  String get splashFooter;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @exploreAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Explore as Guest'**
  String get exploreAsGuest;

  /// No description provided for @selectInterests.
  ///
  /// In en, this message translates to:
  /// **'Select Interests'**
  String get selectInterests;

  /// No description provided for @selectMin3.
  ///
  /// In en, this message translates to:
  /// **'Select at least 3 interests to personalize your experience'**
  String get selectMin3;

  /// No description provided for @continueText.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;

  /// No description provided for @comingSoonTitle.
  ///
  /// In en, this message translates to:
  /// **'Feature Coming Soon'**
  String get comingSoonTitle;

  /// No description provided for @comingSoonDesc.
  ///
  /// In en, this message translates to:
  /// **'This feature is planned for Stage B development. Stay tuned for future updates!'**
  String get comingSoonDesc;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @explore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get explore;

  /// No description provided for @plans.
  ///
  /// In en, this message translates to:
  /// **'Plans'**
  String get plans;

  /// No description provided for @trips.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get trips;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @recommendedForYou.
  ///
  /// In en, this message translates to:
  /// **'Recommended For You'**
  String get recommendedForYou;

  /// No description provided for @trendingNow.
  ///
  /// In en, this message translates to:
  /// **'Trending Now'**
  String get trendingNow;

  /// No description provided for @authenticHomestays.
  ///
  /// In en, this message translates to:
  /// **'Authentic Homestays'**
  String get authenticHomestays;

  /// No description provided for @communityLedTours.
  ///
  /// In en, this message translates to:
  /// **'Community-Led Tours'**
  String get communityLedTours;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by keyword, location, trek...'**
  String get searchHint;

  /// No description provided for @searchResults.
  ///
  /// In en, this message translates to:
  /// **'Search Results'**
  String get searchResults;

  /// No description provided for @recentSearches.
  ///
  /// In en, this message translates to:
  /// **'Recent Searches'**
  String get recentSearches;

  /// No description provided for @clearAllFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear All Filters'**
  String get clearAllFilters;

  /// No description provided for @resetFilters.
  ///
  /// In en, this message translates to:
  /// **'Reset Search'**
  String get resetFilters;

  /// No description provided for @filterAndSort.
  ///
  /// In en, this message translates to:
  /// **'Filter & Sort'**
  String get filterAndSort;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort By'**
  String get sortBy;

  /// No description provided for @difficultyLevel.
  ///
  /// In en, this message translates to:
  /// **'Difficulty Level'**
  String get difficultyLevel;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @regions.
  ///
  /// In en, this message translates to:
  /// **'Regions'**
  String get regions;

  /// No description provided for @applyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get applyFilters;

  /// No description provided for @resetAll.
  ///
  /// In en, this message translates to:
  /// **'Reset All'**
  String get resetAll;

  /// No description provided for @noExperiencesFound.
  ///
  /// In en, this message translates to:
  /// **'No Experiences Found'**
  String get noExperiencesFound;

  /// No description provided for @savedExperiences.
  ///
  /// In en, this message translates to:
  /// **'Saved Experiences'**
  String get savedExperiences;

  /// No description provided for @noSavedExperiences.
  ///
  /// In en, this message translates to:
  /// **'No Saved Experiences Yet'**
  String get noSavedExperiences;

  /// No description provided for @noSavedExperiencesSub.
  ///
  /// In en, this message translates to:
  /// **'Tap the heart icon on any experience to save it for later.'**
  String get noSavedExperiencesSub;

  /// No description provided for @bookingForm.
  ///
  /// In en, this message translates to:
  /// **'Booking Form'**
  String get bookingForm;

  /// No description provided for @selectDepartureDate.
  ///
  /// In en, this message translates to:
  /// **'Select Departure Date'**
  String get selectDepartureDate;

  /// No description provided for @contactDetails.
  ///
  /// In en, this message translates to:
  /// **'Contact Details'**
  String get contactDetails;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @adults.
  ///
  /// In en, this message translates to:
  /// **'Adults'**
  String get adults;

  /// No description provided for @children.
  ///
  /// In en, this message translates to:
  /// **'Children'**
  String get children;

  /// No description provided for @subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @serviceFee.
  ///
  /// In en, this message translates to:
  /// **'Service & Tech Fee (5%)'**
  String get serviceFee;

  /// No description provided for @proceedToPayment.
  ///
  /// In en, this message translates to:
  /// **'Proceed to Payment'**
  String get proceedToPayment;

  /// No description provided for @paymentsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Payments Coming Soon'**
  String get paymentsComingSoon;

  /// No description provided for @bookingConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Booking Confirmation'**
  String get bookingConfirmation;

  /// No description provided for @bookingRef.
  ///
  /// In en, this message translates to:
  /// **'Booking Ref'**
  String get bookingRef;

  /// No description provided for @myPlans.
  ///
  /// In en, this message translates to:
  /// **'My Plans'**
  String get myPlans;

  /// No description provided for @myTrips.
  ///
  /// In en, this message translates to:
  /// **'My Trips'**
  String get myTrips;

  /// No description provided for @upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcoming;

  /// No description provided for @drafts.
  ///
  /// In en, this message translates to:
  /// **'Drafts'**
  String get drafts;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @noUpcomingPlans.
  ///
  /// In en, this message translates to:
  /// **'No Upcoming Plans'**
  String get noUpcomingPlans;

  /// No description provided for @noDraftPlans.
  ///
  /// In en, this message translates to:
  /// **'No Draft Plans'**
  String get noDraftPlans;

  /// No description provided for @noCompletedTrips.
  ///
  /// In en, this message translates to:
  /// **'No Completed Trips'**
  String get noCompletedTrips;

  /// No description provided for @noCancelledTrips.
  ///
  /// In en, this message translates to:
  /// **'No Cancelled Trips'**
  String get noCancelledTrips;

  /// No description provided for @becomeAHost.
  ///
  /// In en, this message translates to:
  /// **'Become a Host'**
  String get becomeAHost;

  /// No description provided for @hostApplication.
  ///
  /// In en, this message translates to:
  /// **'Host Application'**
  String get hostApplication;

  /// No description provided for @step1Personal.
  ///
  /// In en, this message translates to:
  /// **'Step 1: Personal Info'**
  String get step1Personal;

  /// No description provided for @step2Details.
  ///
  /// In en, this message translates to:
  /// **'Step 2: Experience Details'**
  String get step2Details;

  /// No description provided for @step3Id.
  ///
  /// In en, this message translates to:
  /// **'Step 3: Verification'**
  String get step3Id;

  /// No description provided for @step4Bank.
  ///
  /// In en, this message translates to:
  /// **'Step 4: Banking Info'**
  String get step4Bank;

  /// No description provided for @submitApplication.
  ///
  /// In en, this message translates to:
  /// **'Submit Application'**
  String get submitApplication;

  /// No description provided for @applicationSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Application Submitted'**
  String get applicationSubmitted;

  /// No description provided for @underReview.
  ///
  /// In en, this message translates to:
  /// **'Under Review'**
  String get underReview;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get forgotPassword;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Login'**
  String get alreadyHaveAccount;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign Up'**
  String get dontHaveAccount;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @paymentMethods.
  ///
  /// In en, this message translates to:
  /// **'Payment Methods'**
  String get paymentMethods;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @languageAndRegion.
  ///
  /// In en, this message translates to:
  /// **'Language & Region'**
  String get languageAndRegion;

  /// No description provided for @helpAndSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpAndSupport;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @myReviews.
  ///
  /// In en, this message translates to:
  /// **'My Reviews'**
  String get myReviews;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @authRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Authentication Required'**
  String get authRequiredTitle;

  /// No description provided for @authRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Please sign in or create an account to perform this action.'**
  String get authRequiredMessage;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @itinerary.
  ///
  /// In en, this message translates to:
  /// **'Itinerary'**
  String get itinerary;

  /// No description provided for @included.
  ///
  /// In en, this message translates to:
  /// **'What is Included'**
  String get included;

  /// No description provided for @bringList.
  ///
  /// In en, this message translates to:
  /// **'What to Bring'**
  String get bringList;

  /// No description provided for @meetingPoint.
  ///
  /// In en, this message translates to:
  /// **'Meeting Point'**
  String get meetingPoint;

  /// No description provided for @reviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviews;

  /// No description provided for @organizer.
  ///
  /// In en, this message translates to:
  /// **'Organizer'**
  String get organizer;

  /// No description provided for @joinExperience.
  ///
  /// In en, this message translates to:
  /// **'Join Experience'**
  String get joinExperience;

  /// No description provided for @spotsLeft.
  ///
  /// In en, this message translates to:
  /// **'spots left'**
  String get spotsLeft;

  /// No description provided for @perPerson.
  ///
  /// In en, this message translates to:
  /// **'per person'**
  String get perPerson;

  /// No description provided for @viewGuide.
  ///
  /// In en, this message translates to:
  /// **'View Guide'**
  String get viewGuide;

  /// No description provided for @leaveReview.
  ///
  /// In en, this message translates to:
  /// **'Leave Review'**
  String get leaveReview;

  /// No description provided for @reviewSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Review Submitted'**
  String get reviewSubmitted;

  /// No description provided for @accountCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Account created successfully!'**
  String get accountCreatedSuccess;

  /// No description provided for @loggedInSuccess.
  ///
  /// In en, this message translates to:
  /// **'Logged in successfully!'**
  String get loggedInSuccess;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Log in to manage your bookings and saved Nepal itineraries.'**
  String get loginSubtitle;

  /// No description provided for @emailOrPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Email or Phone Number'**
  String get emailOrPhoneLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @resetLinkSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset instructions sent!'**
  String get resetLinkSent;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email or phone to receive a password reset link.'**
  String get forgotPasswordSubtitle;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get sendResetLink;

  /// No description provided for @resetResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Password Reset Email Sent'**
  String get resetResultTitle;

  /// No description provided for @resetResultSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Please check your inbox and follow the instructions to reset your password.'**
  String get resetResultSubtitle;

  /// No description provided for @signInToContinue.
  ///
  /// In en, this message translates to:
  /// **'Sign In to Continue'**
  String get signInToContinue;

  /// No description provided for @signUpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join PLAN E to book authentic experiences across Nepal.'**
  String get signUpSubtitle;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPasswordLabel;

  /// No description provided for @onboardingSlide1Title.
  ///
  /// In en, this message translates to:
  /// **'Discover Local Culture'**
  String get onboardingSlide1Title;

  /// No description provided for @onboardingSlide1Desc.
  ///
  /// In en, this message translates to:
  /// **'Authentic Nepal experiences hosted by passionate locals'**
  String get onboardingSlide1Desc;

  /// No description provided for @onboardingSlide2Title.
  ///
  /// In en, this message translates to:
  /// **'Trek Off the Beaten Path'**
  String get onboardingSlide2Title;

  /// No description provided for @onboardingSlide2Desc.
  ///
  /// In en, this message translates to:
  /// **'Explore hidden trails, sacred mountain valleys, and ancient villages'**
  String get onboardingSlide2Desc;

  /// No description provided for @onboardingSlide3Title.
  ///
  /// In en, this message translates to:
  /// **'Support Local Communities'**
  String get onboardingSlide3Title;

  /// No description provided for @onboardingSlide3Desc.
  ///
  /// In en, this message translates to:
  /// **'Every booking directly empowers rural families and artisans'**
  String get onboardingSlide3Desc;

  /// No description provided for @skipText.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skipText;

  /// No description provided for @nextText.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextText;

  /// No description provided for @homeHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Discover Authentic Nepal'**
  String get homeHeroTitle;

  /// No description provided for @homeHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Connect with local hosts, homestays & mountain guides'**
  String get homeHeroSubtitle;

  /// No description provided for @railRecommendedSub.
  ///
  /// In en, this message translates to:
  /// **'Handpicked experiences based on popular journeys'**
  String get railRecommendedSub;

  /// No description provided for @railTrendingSub.
  ///
  /// In en, this message translates to:
  /// **'Most booked trips this season in Nepal'**
  String get railTrendingSub;

  /// No description provided for @railHomestaysSub.
  ///
  /// In en, this message translates to:
  /// **'Immerse in local village hospitality'**
  String get railHomestaysSub;

  /// No description provided for @railCommunitySub.
  ///
  /// In en, this message translates to:
  /// **'Direct impact travel supporting local communities'**
  String get railCommunitySub;

  /// No description provided for @regionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'From Annapurna circuits to Everest highlands'**
  String get regionsSubtitle;

  /// No description provided for @categoriesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find journeys tailored to your adventure style'**
  String get categoriesSubtitle;

  /// No description provided for @addressCopied.
  ///
  /// In en, this message translates to:
  /// **'Meeting point address copied to clipboard'**
  String get addressCopied;

  /// No description provided for @noSearchResultsSub.
  ///
  /// In en, this message translates to:
  /// **'No results match your search or filter settings.'**
  String get noSearchResultsSub;

  /// No description provided for @allLevels.
  ///
  /// In en, this message translates to:
  /// **'All Levels'**
  String get allLevels;

  /// No description provided for @collectionRecommendedTitle.
  ///
  /// In en, this message translates to:
  /// **'Recommended for You'**
  String get collectionRecommendedTitle;

  /// No description provided for @collectionTrendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Trending Experiences'**
  String get collectionTrendingTitle;

  /// No description provided for @collectionHomestaysTitle.
  ///
  /// In en, this message translates to:
  /// **'Local Homestays'**
  String get collectionHomestaysTitle;

  /// No description provided for @collectionCommunityTitle.
  ///
  /// In en, this message translates to:
  /// **'Community-Led Tours'**
  String get collectionCommunityTitle;

  /// No description provided for @collectionDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Experience Collection'**
  String get collectionDefaultTitle;

  /// No description provided for @collectionRecommendedSub.
  ///
  /// In en, this message translates to:
  /// **'Handpicked journeys customized for travelers in Nepal'**
  String get collectionRecommendedSub;

  /// No description provided for @collectionTrendingSub.
  ///
  /// In en, this message translates to:
  /// **'Most booked and highest rated experiences this month'**
  String get collectionTrendingSub;

  /// No description provided for @collectionHomestaysSub.
  ///
  /// In en, this message translates to:
  /// **'Authentic village homestays and community warm welcomes'**
  String get collectionHomestaysSub;

  /// No description provided for @collectionCommunitySub.
  ///
  /// In en, this message translates to:
  /// **'Sustainable tours directly benefiting local Nepalese guides'**
  String get collectionCommunitySub;

  /// No description provided for @collectionDefaultSub.
  ///
  /// In en, this message translates to:
  /// **'Explore our curated list of authentic experiences'**
  String get collectionDefaultSub;

  /// No description provided for @returnHome.
  ///
  /// In en, this message translates to:
  /// **'Return Home'**
  String get returnHome;

  /// No description provided for @exploreAll.
  ///
  /// In en, this message translates to:
  /// **'Explore All'**
  String get exploreAll;

  /// No description provided for @sortHighestRated.
  ///
  /// In en, this message translates to:
  /// **'Highest Rated'**
  String get sortHighestRated;

  /// No description provided for @sortMostPopular.
  ///
  /// In en, this message translates to:
  /// **'Most Popular'**
  String get sortMostPopular;

  /// No description provided for @diffEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get diffEasy;

  /// No description provided for @diffModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get diffModerate;

  /// No description provided for @diffChallenging.
  ///
  /// In en, this message translates to:
  /// **'Challenging'**
  String get diffChallenging;

  /// No description provided for @diffStrenuous.
  ///
  /// In en, this message translates to:
  /// **'Strenuous'**
  String get diffStrenuous;

  /// No description provided for @noCategoriesLoaded.
  ///
  /// In en, this message translates to:
  /// **'No categories loaded'**
  String get noCategoriesLoaded;

  /// No description provided for @noRegionsLoaded.
  ///
  /// In en, this message translates to:
  /// **'No regions loaded'**
  String get noRegionsLoaded;

  /// No description provided for @experienceNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Experience Not Found'**
  String get experienceNotFoundTitle;

  /// No description provided for @experienceNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'The requested experience could not be loaded.'**
  String get experienceNotFoundMessage;

  /// No description provided for @contactHostComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Host contact option coming soon'**
  String get contactHostComingSoon;

  /// No description provided for @essentialGearHeading.
  ///
  /// In en, this message translates to:
  /// **'Essential Gear & Packing List'**
  String get essentialGearHeading;

  /// No description provided for @adultsLabel.
  ///
  /// In en, this message translates to:
  /// **'Adults (18+ yrs)'**
  String get adultsLabel;

  /// No description provided for @childrenLabel.
  ///
  /// In en, this message translates to:
  /// **'Children (0-17 yrs)'**
  String get childrenLabel;

  /// No description provided for @primaryContactInfo.
  ///
  /// In en, this message translates to:
  /// **'Primary Contact Info'**
  String get primaryContactInfo;

  /// No description provided for @fullNameHintExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. Ram Bahadur Shrestha'**
  String get fullNameHintExample;

  /// No description provided for @nepaliPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Nepali Phone Number'**
  String get nepaliPhoneLabel;

  /// No description provided for @nepaliPhoneHintExample.
  ///
  /// In en, this message translates to:
  /// **'98XXXXXXXX or +97798XXXXXXXX'**
  String get nepaliPhoneHintExample;

  /// No description provided for @valEnterFullName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your full name'**
  String get valEnterFullName;

  /// No description provided for @valEnterPhone.
  ///
  /// In en, this message translates to:
  /// **'Please enter mobile number'**
  String get valEnterPhone;

  /// No description provided for @valValidNepaliPhone.
  ///
  /// In en, this message translates to:
  /// **'Must be valid 10-digit Nepali mobile number (98XXXXXXXX)'**
  String get valValidNepaliPhone;

  /// No description provided for @specialNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Special Requirements / Notes (Optional)'**
  String get specialNotesLabel;

  /// No description provided for @specialNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Dietary preferences, pickup requests...'**
  String get specialNotesHint;

  /// No description provided for @proceedToPay.
  ///
  /// In en, this message translates to:
  /// **'Proceed to Pay'**
  String get proceedToPay;

  /// No description provided for @confirmDraftReservation.
  ///
  /// In en, this message translates to:
  /// **'Confirm Draft Reservation'**
  String get confirmDraftReservation;

  /// No description provided for @paymentsComingSoonDesc.
  ///
  /// In en, this message translates to:
  /// **'Online payment gateway integration (Khalti & eSewa) lands in Phase 7. You can place a draft reservation now.'**
  String get paymentsComingSoonDesc;

  /// No description provided for @bookingNotFound.
  ///
  /// In en, this message translates to:
  /// **'Booking record not found.'**
  String get bookingNotFound;

  /// No description provided for @returnToHome.
  ///
  /// In en, this message translates to:
  /// **'Return to Home'**
  String get returnToHome;

  /// No description provided for @viewTripItinerary.
  ///
  /// In en, this message translates to:
  /// **'View Trip Itinerary'**
  String get viewTripItinerary;

  /// No description provided for @backToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get backToHome;

  /// No description provided for @removedFromSaved.
  ///
  /// In en, this message translates to:
  /// **'Removed from saved experiences'**
  String get removedFromSaved;

  /// No description provided for @noUpcomingPlansSub.
  ///
  /// In en, this message translates to:
  /// **'Your confirmed trips and upcoming adventures will appear here.'**
  String get noUpcomingPlansSub;

  /// No description provided for @noDraftPlansSub.
  ///
  /// In en, this message translates to:
  /// **'Any incomplete bookings or saved drafts will appear here.'**
  String get noDraftPlansSub;

  /// No description provided for @draftDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Draft deleted successfully'**
  String get draftDeletedSuccess;

  /// No description provided for @noCompletedTripsSub.
  ///
  /// In en, this message translates to:
  /// **'Trips you complete will be listed here with memories & review options.'**
  String get noCompletedTripsSub;

  /// No description provided for @noCancelledTripsSub.
  ///
  /// In en, this message translates to:
  /// **'Any cancelled trip reservations will be shown here.'**
  String get noCancelledTripsSub;

  /// No description provided for @bookAgain.
  ///
  /// In en, this message translates to:
  /// **'Book Again'**
  String get bookAgain;

  /// No description provided for @tripChat.
  ///
  /// In en, this message translates to:
  /// **'Trip Chat'**
  String get tripChat;

  /// No description provided for @gearList.
  ///
  /// In en, this message translates to:
  /// **'Gear List'**
  String get gearList;

  /// No description provided for @budget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get budget;

  /// No description provided for @itineraryNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Itinerary Guide Not Available'**
  String get itineraryNotAvailable;

  /// No description provided for @itineraryNotAvailableMessage.
  ///
  /// In en, this message translates to:
  /// **'Experience data could not be loaded.'**
  String get itineraryNotAvailableMessage;

  /// No description provided for @deleteDraftTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Trip Draft'**
  String get deleteDraftTitle;

  /// No description provided for @deleteDraftConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this trip draft? This action cannot be undone.'**
  String get deleteDraftConfirm;

  /// No description provided for @rateYourExperience.
  ///
  /// In en, this message translates to:
  /// **'Rate Your Experience'**
  String get rateYourExperience;

  /// No description provided for @submitReview.
  ///
  /// In en, this message translates to:
  /// **'Submit Review'**
  String get submitReview;

  /// No description provided for @reviewSubmittedTitle.
  ///
  /// In en, this message translates to:
  /// **'Thank You for Your Review!'**
  String get reviewSubmittedTitle;

  /// No description provided for @accountSettings.
  ///
  /// In en, this message translates to:
  /// **'Account Settings'**
  String get accountSettings;

  /// No description provided for @subEditProfile.
  ///
  /// In en, this message translates to:
  /// **'Name, phone, bio & photo'**
  String get subEditProfile;

  /// No description provided for @subPaymentMethods.
  ///
  /// In en, this message translates to:
  /// **'Khalti, eSewa & cards'**
  String get subPaymentMethods;

  /// No description provided for @subNotifications.
  ///
  /// In en, this message translates to:
  /// **'Trip alerts & recommendations'**
  String get subNotifications;

  /// No description provided for @subLanguageRegion.
  ///
  /// In en, this message translates to:
  /// **'English (NPR - Rs)'**
  String get subLanguageRegion;

  /// No description provided for @subMyReviews.
  ///
  /// In en, this message translates to:
  /// **'Past ratings & feedback'**
  String get subMyReviews;

  /// No description provided for @subHelpSupport.
  ///
  /// In en, this message translates to:
  /// **'FAQs, contact & policies'**
  String get subHelpSupport;

  /// No description provided for @subSettings.
  ///
  /// In en, this message translates to:
  /// **'Cache, privacy & app info'**
  String get subSettings;

  /// No description provided for @becomeLocalHostTitle.
  ///
  /// In en, this message translates to:
  /// **'Become a Local Host'**
  String get becomeLocalHostTitle;

  /// No description provided for @becomeLocalHostSub.
  ///
  /// In en, this message translates to:
  /// **'Share your culture, home, or guiding skills with global travelers'**
  String get becomeLocalHostSub;

  /// No description provided for @startHostAppBtn.
  ///
  /// In en, this message translates to:
  /// **'Start Host Application'**
  String get startHostAppBtn;

  /// No description provided for @hostUnderReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Host Application Under Review'**
  String get hostUnderReviewTitle;

  /// No description provided for @hostVerifiedTitle.
  ///
  /// In en, this message translates to:
  /// **'Verified PLAN E Host'**
  String get hostVerifiedTitle;

  /// No description provided for @profileUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdatedSuccess;

  /// No description provided for @bioLabel.
  ///
  /// In en, this message translates to:
  /// **'Bio / About You'**
  String get bioLabel;

  /// No description provided for @addressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address / Location'**
  String get addressLabel;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @savedPaymentGateways.
  ///
  /// In en, this message translates to:
  /// **'Saved Payment Gateways'**
  String get savedPaymentGateways;

  /// No description provided for @paymentMethodsPageSub.
  ///
  /// In en, this message translates to:
  /// **'Manage your digital wallets and cash options for booking experiences in Nepal.'**
  String get paymentMethodsPageSub;

  /// No description provided for @paymentGatewayModeActive.
  ///
  /// In en, this message translates to:
  /// **'Payment gateway integration mode active'**
  String get paymentGatewayModeActive;

  /// No description provided for @defaultTag.
  ///
  /// In en, this message translates to:
  /// **'DEFAULT'**
  String get defaultTag;

  /// No description provided for @khaltiWalletTitle.
  ///
  /// In en, this message translates to:
  /// **'Khalti Wallet'**
  String get khaltiWalletTitle;

  /// No description provided for @khaltiWalletSub.
  ///
  /// In en, this message translates to:
  /// **'Primary payment gateway (+977 9800000000)'**
  String get khaltiWalletSub;

  /// No description provided for @esewaWalletTitle.
  ///
  /// In en, this message translates to:
  /// **'eSewa Mobile Wallet'**
  String get esewaWalletTitle;

  /// No description provided for @esewaWalletSub.
  ///
  /// In en, this message translates to:
  /// **'Instant online payout & booking'**
  String get esewaWalletSub;

  /// No description provided for @cashOnArrivalTitle.
  ///
  /// In en, this message translates to:
  /// **'Cash on Arrival'**
  String get cashOnArrivalTitle;

  /// No description provided for @cashOnArrivalSub.
  ///
  /// In en, this message translates to:
  /// **'Pay directly to local host at check-in'**
  String get cashOnArrivalSub;

  /// No description provided for @addPaymentGatewayBtn.
  ///
  /// In en, this message translates to:
  /// **'Add Payment Gateway'**
  String get addPaymentGatewayBtn;

  /// No description provided for @notificationPreferencesTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification Preferences'**
  String get notificationPreferencesTitle;

  /// No description provided for @notificationPreferencesSub.
  ///
  /// In en, this message translates to:
  /// **'Configure how you want to be notified about trips, host messages, and special offers.'**
  String get notificationPreferencesSub;

  /// No description provided for @notifTripStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip Status & Reminders'**
  String get notifTripStatusTitle;

  /// No description provided for @notifTripStatusSub.
  ///
  /// In en, this message translates to:
  /// **'Real-time departure alerts, guide details, and schedule updates'**
  String get notifTripStatusSub;

  /// No description provided for @notifHostMessagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Host Messages'**
  String get notifHostMessagesTitle;

  /// No description provided for @notifHostMessagesSub.
  ///
  /// In en, this message translates to:
  /// **'Instant chat messages and instructions from local hosts'**
  String get notifHostMessagesSub;

  /// No description provided for @notifWeatherAlertsTitle.
  ///
  /// In en, this message translates to:
  /// **'Mountain Weather Alerts'**
  String get notifWeatherAlertsTitle;

  /// No description provided for @notifWeatherAlertsSub.
  ///
  /// In en, this message translates to:
  /// **'Crucial trail weather and safety warnings for booked treks'**
  String get notifWeatherAlertsSub;

  /// No description provided for @notifPromoOffersTitle.
  ///
  /// In en, this message translates to:
  /// **'Promotional Offers'**
  String get notifPromoOffersTitle;

  /// No description provided for @notifPromoOffersSub.
  ///
  /// In en, this message translates to:
  /// **'Seasonal discounts on homestays and featured treks'**
  String get notifPromoOffersSub;

  /// No description provided for @notifSoundEnabledTitle.
  ///
  /// In en, this message translates to:
  /// **'Sound Effects'**
  String get notifSoundEnabledTitle;

  /// No description provided for @notifSoundEnabledSub.
  ///
  /// In en, this message translates to:
  /// **'Play sound for incoming push notifications'**
  String get notifSoundEnabledSub;

  /// No description provided for @toastTripUpdatesSaved.
  ///
  /// In en, this message translates to:
  /// **'Trip updates preference saved'**
  String get toastTripUpdatesSaved;

  /// No description provided for @toastHostMessagesSaved.
  ///
  /// In en, this message translates to:
  /// **'Host messages preference saved'**
  String get toastHostMessagesSaved;

  /// No description provided for @toastWeatherAlertsSaved.
  ///
  /// In en, this message translates to:
  /// **'Weather alerts preference saved'**
  String get toastWeatherAlertsSaved;

  /// No description provided for @toastPromoOffersSaved.
  ///
  /// In en, this message translates to:
  /// **'Promotional offers preference saved'**
  String get toastPromoOffersSaved;

  /// No description provided for @toastSoundSaved.
  ///
  /// In en, this message translates to:
  /// **'Sound preference saved'**
  String get toastSoundSaved;

  /// No description provided for @appLanguage.
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get appLanguage;

  /// No description provided for @currencyDisplay.
  ///
  /// In en, this message translates to:
  /// **'Currency Display'**
  String get currencyDisplay;

  /// No description provided for @toastLanguageUpdated.
  ///
  /// In en, this message translates to:
  /// **'Language preference updated'**
  String get toastLanguageUpdated;

  /// No description provided for @toastCurrencyUpdated.
  ///
  /// In en, this message translates to:
  /// **'Currency preference updated'**
  String get toastCurrencyUpdated;

  /// No description provided for @needHelpTitle.
  ///
  /// In en, this message translates to:
  /// **'Need help with your booking?'**
  String get needHelpTitle;

  /// No description provided for @needHelpSub.
  ///
  /// In en, this message translates to:
  /// **'Our local support team in Kathmandu is available 24/7 to assist with your journey.'**
  String get needHelpSub;

  /// No description provided for @callUs.
  ///
  /// In en, this message translates to:
  /// **'Call Us'**
  String get callUs;

  /// No description provided for @liveChat.
  ///
  /// In en, this message translates to:
  /// **'Live Chat'**
  String get liveChat;

  /// No description provided for @faqHeading.
  ///
  /// In en, this message translates to:
  /// **'Frequently Asked Questions'**
  String get faqHeading;

  /// No description provided for @emailSupport.
  ///
  /// In en, this message translates to:
  /// **'Email Support'**
  String get emailSupport;

  /// No description provided for @sendAnEmail.
  ///
  /// In en, this message translates to:
  /// **'Send an Email'**
  String get sendAnEmail;

  /// No description provided for @moreSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'More Settings'**
  String get moreSettingsTitle;

  /// No description provided for @appPreferencesHeader.
  ///
  /// In en, this message translates to:
  /// **'App Preferences'**
  String get appPreferencesHeader;

  /// No description provided for @darkThemeTitle.
  ///
  /// In en, this message translates to:
  /// **'Dark Theme'**
  String get darkThemeTitle;

  /// No description provided for @darkThemeSub.
  ///
  /// In en, this message translates to:
  /// **'Enable dark theme for nighttime reading'**
  String get darkThemeSub;

  /// No description provided for @offlineMapsTitle.
  ///
  /// In en, this message translates to:
  /// **'Offline Trail Maps'**
  String get offlineMapsTitle;

  /// No description provided for @offlineMapsSub.
  ///
  /// In en, this message translates to:
  /// **'Download maps for offline navigation during treks'**
  String get offlineMapsSub;

  /// No description provided for @clearCacheTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear Cache'**
  String get clearCacheTitle;

  /// No description provided for @clearCacheSub.
  ///
  /// In en, this message translates to:
  /// **'Remove cached images and temporary travel data'**
  String get clearCacheSub;

  /// No description provided for @toastThemeUpdated.
  ///
  /// In en, this message translates to:
  /// **'Theme preference updated'**
  String get toastThemeUpdated;

  /// No description provided for @toastOfflineMapsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Offline maps setting updated'**
  String get toastOfflineMapsUpdated;

  /// No description provided for @toastCacheCleared.
  ///
  /// In en, this message translates to:
  /// **'Cache cleared successfully'**
  String get toastCacheCleared;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @openSourceLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open Source Licenses'**
  String get openSourceLicenses;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logOut;

  /// No description provided for @logoutConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out of PLAN E?'**
  String get logoutConfirmation;

  /// No description provided for @noReviewsYetSub.
  ///
  /// In en, this message translates to:
  /// **'You have not submitted any experience reviews yet.'**
  String get noReviewsYetSub;

  /// No description provided for @review1Title.
  ///
  /// In en, this message translates to:
  /// **'Panauti Authentic Newari Homestay & Cooking Class'**
  String get review1Title;

  /// No description provided for @review1Location.
  ///
  /// In en, this message translates to:
  /// **'Panauti, Kavre'**
  String get review1Location;

  /// No description provided for @review1Comment.
  ///
  /// In en, this message translates to:
  /// **'Unforgettable hospitality from Sunita and her family! The Yomari making experience was the highlight of our Nepal trip.'**
  String get review1Comment;

  /// No description provided for @review2Title.
  ///
  /// In en, this message translates to:
  /// **'Patan Heritage Alley & Pottery Workshop'**
  String get review2Title;

  /// No description provided for @review2Location.
  ///
  /// In en, this message translates to:
  /// **'Patan, Lalitpur'**
  String get review2Location;

  /// No description provided for @review2Comment.
  ///
  /// In en, this message translates to:
  /// **'Master potter Dil Bahadur taught us traditional clay techniques. Great cultural insight away from tourist crowds.'**
  String get review2Comment;

  /// No description provided for @becomeHostHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Become a Local Host'**
  String get becomeHostHeaderTitle;

  /// No description provided for @becomeHostHeaderSub.
  ///
  /// In en, this message translates to:
  /// **'Share your culture, home, or guiding skills with global travelers'**
  String get becomeHostHeaderSub;

  /// No description provided for @exploreExperiences.
  ///
  /// In en, this message translates to:
  /// **'Explore Experiences'**
  String get exploreExperiences;

  /// No description provided for @easy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get easy;

  /// No description provided for @moderate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get moderate;

  /// No description provided for @challenging.
  ///
  /// In en, this message translates to:
  /// **'Challenging'**
  String get challenging;

  /// No description provided for @strenuous.
  ///
  /// In en, this message translates to:
  /// **'Strenuous'**
  String get strenuous;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @region.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get region;

  /// No description provided for @resetSearch.
  ///
  /// In en, this message translates to:
  /// **'Reset Search'**
  String get resetSearch;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ne'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ne':
      return AppLocalizationsNe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
