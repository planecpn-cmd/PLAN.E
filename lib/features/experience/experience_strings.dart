abstract class ExperienceStrings {
  static const String overviewTitle = 'Overview';
  static const String pricingTitle = 'Pricing Details';
  static const String perPersonUnit = '/ person';
  static const String perChildUnit = '/ child (under 12)';
  static const String taxesIncluded = 'Includes all local taxes, guide fees & permits.';
  static const String whatsIncludedTitle = 'What\'s Included';
  static const String whatsBringTitle = 'What to Bring';
  static const String meetingPointTitle = 'Meeting Point & Location';
  static const String viewOnMap = 'View on Full Map';
  static const String participantsTitle = 'Group & Age Requirements';
  static const String minAgeLabel = 'Minimum Age';
  static const String groupSizeLabel = 'Group Size';
  static const String suitabilityNote = 'Suitable for solo travelers, couples & small groups.';
  static const String thingsToKnowTitle = 'Things to Know & Policies';
  static const String cancellationPolicy = 'Free cancellation up to 48 hours before start date.';
  static const String reviewsTitle = 'Guest Reviews';
  static const String noReviewsYet = 'No reviews yet. Be the first to join and review!';
  static const String hostedByTitle = 'Organized by';
  static const String verifiedGuide = 'Verified Local Host & Guide';
  static const String responseRateText = '100% response rate • Responds within 1 hr';
  static const String contactHost = 'Contact Host';
  static const String joinButtonLabel = 'Join Experience';
  static const String readMore = 'Read more';
  static const String showLess = 'Show less';
  static const String spotsLeftWarningPrefix = 'Only ';
  static const String spotsLeftWarningSuffix = ' spots left for ';
  static const String spotsAvailablePrefix = 'Available for ';
  static const String spotsAvailableSuffix = ' spots left';
  static const String instantConfirmation = 'Instant Confirmation • Scheduled Departures';
  static const String durationLabel = 'Duration';
  static const String difficultyLabel = 'Difficulty';
  static const String altitudeLabel = 'Max Altitude';
  static const String linkCopied = 'Link copied to clipboard';
  static const String loginRequiredToSave = 'Please log in to save this experience';
  static const String savedToWishlist = 'Added to Saved Experiences';
  static const String removedFromWishlist = 'Removed from Saved Experiences';

  // Default fallbacks when database fields are empty
  static const List<String> defaultIncluded = [
    'Professional English/Nepali speaking licensed guide',
    'Local transport & transfers as specified',
    'Necessary permits & conservation entry fees',
    'Emergency first aid kit & safety equipment',
  ];

  static const List<String> defaultBringList = [
    'Comfortable footwear / trekking shoes',
    'Weather-appropriate clothing layers & rain jacket',
    'Personal reusable water bottle (1.5L min)',
    'Sun protection (hat, sunglasses, sunscreen)',
    'Valid government photo ID',
  ];

  static const List<String> defaultThingsToKnow = [
    'Trek difficulty is moderate; reasonable fitness required.',
    'Weather in mountain areas can change rapidly.',
    'Respect local customs, culture, and nature.',
    'Travel insurance covering high-altitude rescue is recommended.',
  ];
}
