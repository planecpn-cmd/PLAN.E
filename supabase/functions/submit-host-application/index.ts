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

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ success: false, error: "Method not allowed" }, 405);

  try {
    const { user, adminClient: admin } = await requireAuthenticatedUser(req);

    const body = await req.json().catch(() => null);
    if (!body || typeof body !== "object") {
      return json({ success: false, error: "Invalid request body" }, 400);
    }

    const fullName = normalizedText(body.fullName ?? body.full_name, 120);
    const phone = normalizedText(body.phone, 24);
    const district = normalizedText(body.district ?? body.location, 100);
    const bio = normalizedText(body.bio, 1000);
    const title = normalizedText(body.title ?? body.experienceTitle, 160);
    const category = normalizedText(body.category ?? body.categoryId, 80);
    const description = normalizedText(body.description, 4000);
    const idType = normalizedText(body.idType ?? body.id_type, 80);
    const idNumber = normalizedText(body.idNumber ?? body.id_number, 120);
    const verificationDocPath = normalizedText(
      body.verificationDocPath ?? body.verification_doc_path,
      500,
    );
    const bankName = normalizedText(body.bankName ?? body.bank_name, 120);
    const accountName = normalizedText(body.accountName ?? body.account_name, 120);
    const accountNumber = normalizedText(body.accountNumber ?? body.account_number, 80);
    const branch = normalizedText(body.branch, 120);
    const durationHours = Number(body.durationHours ?? body.duration_hours);
    const maxGroupSize = Number(body.maxGroupSize ?? body.max_group_size);
    const pricePaisa = Number(body.pricePaisa ?? body.price_paisa);

    if (fullName.length < 2 || !phone || !district || bio.length < 20) {
      return json({ success: false, error: "Complete valid personal and hosting details" }, 400);
    }
    if (
      title.length < 3 || description.length < 20 ||
      !Number.isInteger(durationHours) || durationHours < 1 || durationHours > 720 ||
      !Number.isInteger(maxGroupSize) || maxGroupSize < 1 || maxGroupSize > 50 ||
      !Number.isSafeInteger(pricePaisa) || pricePaisa < 0 || pricePaisa > 100_000_000_00
    ) {
      return json({ success: false, error: "Complete valid experience details" }, 400);
    }
    if (!idType || !idNumber || !verificationDocPath.startsWith(`${user.id}/`)) {
      return json({ success: false, error: "A valid verification document is required" }, 400);
    }
    if (!bankName || !accountName || !accountNumber || !branch) {
      return json({ success: false, error: "Complete valid payout details" }, 400);
    }

    const { data: existing, error: existingError } = await admin
      .from("host_applications")
      .select("id,status")
      .eq("user_id", user.id)
      .maybeSingle();
    if (existingError) throw existingError;
    if (existing && !["draft", "rejected"].includes(existing.status)) {
      return json({ success: false, error: "This host application has already been submitted" }, 409);
    }

    let categoryId: string | null = null;
    if (category) {
      const { data: categoryRow } = await admin
        .from("categories")
        .select("id")
        .ilike("name", category)
        .limit(1)
        .maybeSingle();
      categoryId = categoryRow?.id ?? null;
    }

    const now = new Date().toISOString();
    const application = {
      user_id: user.id,
      status: "submitted",
      current_step: 4,
      category_id: categoryId,
      title,
      description,
      location: district,
      verification_doc_path: verificationDocPath,
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
