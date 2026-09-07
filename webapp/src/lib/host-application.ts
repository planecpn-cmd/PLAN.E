export const hostingTypes = {
  adventure: ["Adventure", "Treks, climbing, rafting and outdoor activities"],
  experience: ["Experience", "Wellness, culture, workshops and local activities"],
  stay: ["Stay", "Homestays, retreats and unique places to stay"],
  tour_package: ["Tour / Package", "Multi-day journeys and curated travel packages"],
  community_activity: ["Community Activity", "Social and community-based activities"],
  other: ["Other", "Another meaningful offering"],
} as const;

export const hostTypes = {
  individual: "Individual",
  registered_business: "Registered Business",
  community_group: "Community / Local Group",
  hotel_homestay: "Hotel / Homestay",
  tour_operator: "Tour / Adventure Operator",
  experience_provider: "Experience Provider",
  other: "Other",
} as const;

export type HostDraft = Record<string, unknown> & {
  hosting_type?: keyof typeof hostingTypes;
  host_type?: keyof typeof hostTypes;
  full_name?: string;
  organization_name?: string;
  email?: string;
  phone?: string;
  province?: string;
  district?: string;
  locality?: string;
  min_guests: number;
  max_guests: number;
  availability_type?: string;
  availability_note?: string;
  available_days?: string[];
  start_date?: string;
  end_date?: string;
  pricing_model?: string;
  price_paisa?: number;
  included_items: string[];
  cancellation_policy?: string;
  identity_type?: string;
  identity_number?: string;
  identity_front_path?: string;
  identity_back_path?: string;
  business_document_paths?: string[];
  safety_document_paths?: string[];
  description?: string;
  host_photo_path?: string;
  photo_paths: string[];
  business_logo_path?: string;
  terms_accepted: boolean;
};

export const emptyHostDraft: HostDraft = {
  min_guests: 1,
  max_guests: 8,
  included_items: [],
  photo_paths: [],
  terms_accepted: false,
};

const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const documentNumberPattern = /^[A-Za-z0-9][A-Za-z0-9 ./-]{2,39}$/;

export function isValidHostEmail(value: string) {
  return value.length <= 320 && emailPattern.test(value);
}

export function isValidIdentityDocumentNumber(value: string) {
  return documentNumberPattern.test(value.trim());
}

export function validateHostStep(step: number, draft: HostDraft, accountEmail?: string): string | null {
  if (step === 1 && !draft.hosting_type) return "Choose what you want to host.";
  if (step === 2) {
    if (!draft.host_type) return "Choose your host type.";
    if (!draft.full_name?.trim() || !draft.email?.trim() || !draft.phone?.trim())
      return "Complete your name, email and phone.";
    if (!isValidHostEmail(draft.email.trim())) return "Enter a valid email address.";
    if (draft.host_type === "individual" &&
        draft.email.trim().toLowerCase() !== accountEmail?.toLowerCase())
      return "Use the email registered to your Plan E account.";
    if (draft.host_type !== "individual" && !draft.organization_name?.trim())
      return "Enter your business or organisation name.";
  }
  if (step === 3) {
    if (!draft.province?.trim() || !draft.district?.trim() || !draft.locality?.trim())
      return "Complete your operating location.";
    if (draft.min_guests < 1 || draft.max_guests < draft.min_guests)
      return "Enter a valid maximum guest capacity.";
  }
  if (step === 4) {
    if (!draft.availability_type) return "Choose your availability.";
    if (draft.availability_type === "regular" && !draft.available_days?.length)
      return "Choose at least one available day.";
    if (["specific_dates", "seasonal"].includes(draft.availability_type) &&
        (!draft.start_date || !draft.end_date || draft.end_date < draft.start_date))
      return "Choose a valid availability date range.";
    if (!draft.pricing_model) return "Choose how you normally charge.";
    if (draft.pricing_model !== "custom_quote" && (!draft.price_paisa || draft.price_paisa <= 0))
      return "Enter a valid positive price.";
  }
  if (step === 5 && !draft.cancellation_policy) return "Choose a cancellation policy.";
  if (step === 6) {
    if (!draft.identity_number?.trim() || !isValidIdentityDocumentNumber(draft.identity_number))
      return "Enter a valid document number.";
    if (!draft.identity_type || !draft.identity_front_path)
      return "Upload the required identity document.";
  }
  if (step === 7 && (!draft.description || draft.description.trim().length < 20))
    return "Describe what you want to host in at least 20 characters.";
  if (step === 8) {
    if (!draft.email || !isValidHostEmail(draft.email) ||
        (draft.host_type === "individual" && draft.email.toLowerCase() !== accountEmail?.toLowerCase()))
      return "Review the contact email in step 2.";
    if (!draft.identity_number || !isValidIdentityDocumentNumber(draft.identity_number))
      return "Review the document number in step 6.";
    if (!draft.terms_accepted) return "Accept the host terms before submitting.";
  }
  return null;
}
