import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import {
  AuthenticationError,
  requireAuthenticatedUser,
} from "../_shared/auth.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });

const normalizedText = (value: unknown, maxLength: number) =>
  typeof value === "string" ? value.trim().replace(/\s+/g, " ").slice(0, maxLength) : "";

const questionnaireCategorySlugs: Record<string, string> = {
  adventure: "trekking",
  experience: "culture",
  stay: "homestay",
  tour_package: "travel-package",
  community_activity: "community-event",
  other: "group-activity",
};

const legacyCategorySlugs: Record<string, string> = {
  "Trekking & Hiking": "trekking",
  "Homestay & Village Stay": "homestay",
  "Culinary & Cooking": "food-experience",
  "Cultural & Heritage": "culture",
  "Handicrafts & Pottery": "craft-workshop",
  "Wildlife & Nature": "wildlife",
};

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ success: false, error: "Method not allowed" }, 405);

  try {
    const { user, adminClient: admin } = await requireAuthenticatedUser(req);

    const body = await req.json().catch(() => null);
    if (!body || typeof body !== "object") {
      return json({ success: false, error: "Invalid request body" }, 400);
    }

    const questionnaire = body.applicationData ?? body.application_data;
    const isQuestionnaire = questionnaire && typeof questionnaire === "object";
    const source = isQuestionnaire ? questionnaire : body;
    const fullName = normalizedText(source.full_name ?? body.fullName ?? body.full_name, 120);
    const phone = normalizedText(source.phone, 24);
    const district = normalizedText(source.district ?? source.location, 100);
    const bio = normalizedText(source.bio ?? source.description, 1000);
    const title = normalizedText(
      source.title ?? source.organization_name ?? body.experienceTitle ?? `${fullName} — ${source.hosting_type ?? "Host"}`,
      160,
    );
    const category = normalizedText(source.hosting_type ?? body.category ?? body.categoryId, 80);
    const description = normalizedText(source.description, 4000);
    const idType = normalizedText(source.identity_type ?? body.idType ?? body.id_type, 80);
    const idNumber = normalizedText(source.identity_number ?? body.idNumber ?? body.id_number, 120);
    const email = normalizedText(source.email, 320).toLowerCase();
    const verificationDocPath = normalizedText(
      source.identity_front_path ?? body.verificationDocPath ?? body.verification_doc_path,
      500,
    );
    const bankName = normalizedText(body.bankName ?? body.bank_name, 120);
    const accountName = normalizedText(body.accountName ?? body.account_name, 120);
    const accountNumber = normalizedText(body.accountNumber ?? body.account_number, 80);
    const branch = normalizedText(body.branch, 120);
    const durationHours = Number(body.durationHours ?? body.duration_hours);
    const maxGroupSize = Number(body.maxGroupSize ?? body.max_group_size);
    const pricePaisa = Number(body.pricePaisa ?? body.price_paisa);

    if (isQuestionnaire) {
      const minGuests = Number(source.min_guests);
      const maxGuests = Number(source.max_guests);
      const price = Number(source.price_paisa ?? 0);
      const accountEmail = user.email?.trim().toLowerCase() ?? "";
      const validEmail = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email) &&
        (email === accountEmail || source.host_type !== "individual");
      const validDocumentNumber = /^[A-Za-z0-9][A-Za-z0-9 ./-]{2,39}$/.test(idNumber);
      const required = source.hosting_type && source.host_type && fullName.length >= 2 &&
        phone && source.province && district && source.locality && source.availability_type &&
        source.pricing_model && source.cancellation_policy && description.length >= 20 &&
        validEmail && idType && validDocumentNumber && verificationDocPath.startsWith(`${user.id}/`) &&
        source.terms_accepted === true;
      const validCapacity = Number.isInteger(minGuests) && Number.isInteger(maxGuests) &&
        minGuests >= 1 && maxGuests >= minGuests && maxGuests <= 100;
      const validPrice = source.pricing_model === "custom_quote" ||
        (Number.isSafeInteger(price) && price > 0);
      const validAvailability = source.availability_type === "regular"
        ? Array.isArray(source.available_days) && source.available_days.length > 0
        : ["specific_dates", "seasonal"].includes(source.availability_type)
        ? /^\d{4}-\d{2}-\d{2}$/.test(source.start_date ?? "") &&
          /^\d{4}-\d{2}-\d{2}$/.test(source.end_date ?? "") && source.end_date >= source.start_date
        : source.availability_type === "flexible";
      if (!validEmail) {
        return json({ success: false, error: "Use your account email or a valid business email" }, 400);
      }
      if (!validDocumentNumber) {
        return json({ success: false, error: "Enter a valid identity document number" }, 400);
      }
      if (!required || !validCapacity || !validPrice || !validAvailability) {
        return json({ success: false, error: "Complete all required host application details" }, 400);
      }
    } else if (fullName.length < 2 || !phone || !district || bio.length < 20) {
      return json({ success: false, error: "Complete valid personal and hosting details" }, 400);
    }
    if (!isQuestionnaire && (
      title.length < 3 || description.length < 20 ||
      !Number.isInteger(durationHours) || durationHours < 1 || durationHours > 720 ||
      !Number.isInteger(maxGroupSize) || maxGroupSize < 1 || maxGroupSize > 50 ||
      !Number.isSafeInteger(pricePaisa) || pricePaisa < 0 || pricePaisa > 100_000_000_00
    )) {
      return json({ success: false, error: "Complete valid experience details" }, 400);
    }
    if (!isQuestionnaire && (!idType || !idNumber || !verificationDocPath.startsWith(`${user.id}/`))) {
      return json({ success: false, error: "A valid verification document is required" }, 400);
    }
    if (!isQuestionnaire && (!bankName || !accountName || !accountNumber || !branch)) {
      return json({ success: false, error: "Complete valid payout details" }, 400);
    }

    const { data: existing, error: existingError } = await admin
      .from("host_applications")
      .select("id,status")
      .eq("user_id", user.id)
      .maybeSingle();
    if (existingError) throw existingError;
    if (existing && !["draft", "action_required", "rejected"].includes(existing.status)) {
      return json({ success: false, error: "This host application has already been submitted" }, 409);
    }

    let categoryId: string | null = null;
    if (category) {
      const categorySlug = isQuestionnaire
        ? questionnaireCategorySlugs[category]
        : legacyCategorySlugs[category] ?? category.toLowerCase().replace(/[\s_]+/g, "-");
      if (!categorySlug) {
        return json({ success: false, error: "Choose a valid hosting category" }, 400);
      }
      const { data: categoryRow, error: categoryError } = await admin
        .from("categories")
        .select("id")
        .eq("slug", categorySlug)
        .limit(1)
        .maybeSingle();
      if (categoryError) throw categoryError;
      if (!categoryRow) {
        return json({ success: false, error: "Choose a valid hosting category" }, 400);
      }
      categoryId = categoryRow?.id ?? null;
    }

    const now = new Date().toISOString();
    const application = {
      user_id: user.id,
      status: "submitted",
      current_step: isQuestionnaire ? 8 : 4,
      category_id: categoryId,
      title,
      description,
      location: district,
      verification_doc_path: verificationDocPath,
      photos: isQuestionnaire ? (Array.isArray(source.photo_paths) ? source.photo_paths : []) : undefined,
      application_data: isQuestionnaire ? source : undefined,
      submitted_at: now,
      reviewed_at: null,
      reviewer_note: null,
      updated_at: now,
    };

    const { data: saved, error: saveError } = await admin
      .from("host_applications")
      .upsert(application, { onConflict: "user_id" })
      .select()
      .single();
    if (saveError) throw saveError;

    // This role is informational. Host authorization still requires the
    // approved + active host_accounts row created only during trusted review.
    const { error: profileError } = await admin
      .from("profiles")
      .update({
        full_name: fullName,
        phone,
        bio,
        location: district,
        role: "host_applicant",
        updated_at: now,
      })
      .eq("id", user.id);
    if (profileError) throw profileError;

    // Bank account and raw identity number are intentionally validated but
    // not stored until a dedicated encrypted/PCI-safe backend exists.
    return json({
      success: true,
      message: "Host application submitted for review",
      application: saved,
    });
  } catch (error) {
    if (error instanceof AuthenticationError) {
      return json({ success: false, error: error.message }, 401);
    }
    console.error(
      "Host application submission failed",
      error instanceof Error ? error.message : "unknown error",
    );
    return json({ success: false, error: "Host application submission failed" }, 500);
  }
});
