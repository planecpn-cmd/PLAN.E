// src/i18n/index.ts
// Phase S4 English string catalog (ne land in Phase 11)

export const en = {
  common: {
    appName: 'PLAN E',
    tagline: 'Discover & Plan Authentic Nepal Adventures',
    loading: 'Loading...',
    tryAgain: 'Try Again',
    goBack: 'Go Back',
    continue: 'Continue',
    next: 'Next',
    submit: 'Submit',
    cancel: 'Cancel',
    save: 'Save',
    search: 'Search',
    filter: 'Filter & Sort',
    comingSoonTitle: 'Coming Soon',
    comingSoonBody: 'This feature will be available in Stage B. Stay tuned!',
  },
  onboarding: {
    slide1Title: 'Discover Authentic Nepal',
    slide1Subtitle: 'Uncover handpicked treks, homestays, and local cultural experiences.',
    slide2Title: 'Plan & Track Adventures',
    slide2Subtitle: 'Interactive itineraries, gear checklists, and budget tracking built for mountain trails.',
    slide3Title: 'Connect with Local Hosts',
    slide3Subtitle: 'Support local Sherpa guides, indigenous homestays, and eco-organizers directly.',
    interestsTitle: 'What experiences do you love?',
    interestsSubtitle: 'Pick at least 3 to personalize your Nepal recommendation feed.',
  },
  home: {
    recommendedRail: 'Recommended for You',
    trendingRail: 'Trending Treks & Adventures',
    homestaysRail: 'Homestays Near You',
    communityRail: 'Community & Volunteering',
  },
  experience: {
    fromPrice: 'From',
    perPerson: 'per person',
    joinCTA: 'Join Experience',
    spotsLeft: 'spots left',
    overview: 'Trip Overview',
    whatsIncluded: 'What is Included',
    whatToBring: 'What to Bring',
    meetingPoint: 'Meeting Point',
    thingsToKnow: 'Things to Know',
    reviews: 'Traveler Reviews',
    organizer: 'Local Organizer',
  },
  booking: {
    title: 'Book Experience',
    selectDate: 'Select Departure Date',
    selectGuests: 'Select Participants',
    adults: 'Adults',
    children: 'Children',
    addons: 'Optional Add-ons',
    contactDetails: 'Contact Details',
    fullName: 'Full Name',
    phone: 'Nepali Phone (+977)',
    priceBreakdown: 'Price Breakdown',
    subtotal: 'Subtotal',
    proceedToPayment: 'Proceed to Payment',
    paymentsComingSoonTitle: 'Payments Coming Soon in Stage B',
    paymentsComingSoonBody: 'Transactions will be enabled in Phase 7 with Khalti & eSewa integration.',
  },
  host: {
    landingTitle: 'Become a PLAN E Host',
    landingSubtitle: 'Share your local Nepal adventures with travelers worldwide.',
    startApplication: 'Start Host Application',
    step1Title: 'Personal Details & Contact',
    step2Title: 'Identity Verification & Documents',
    step3Title: 'Pricing & Availability',
    step4Title: 'Review & Submit Application',
    submittedTitle: 'Application Submitted',
    submittedSubtitle: 'Your application is under review by the PLAN E team.',
  },
};

export function t(key: string): string {
  const keys = key.split('.');
  let current: any = en;
  for (const k of keys) {
    if (current && current[k] !== undefined) {
      current = current[k];
    } else {
      return key;
    }
  }
  return typeof current === 'string' ? current : key;
}
