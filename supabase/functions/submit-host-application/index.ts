import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? supabaseAnonKey;

    const authHeader = req.headers.get("Authorization");
    let userId: string | null = null;

    if (authHeader) {
      const userClient = createClient(supabaseUrl, supabaseAnonKey, {
        global: { headers: { Authorization: authHeader } },
      });
      const { data: { user } } = await userClient.auth.getUser();
      if (user) {
        userId = user.id;
      }
    }

    let body: any = {};
    if (req.method === "POST") {
      body = await req.json().catch(() => ({}));
    }

    if (!userId && body.user_id) {
      userId = body.user_id;
    }

    if (!userId) {
      return new Response(
        JSON.stringify({ success: false, error: "Unauthorized: Missing user authentication" }),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
          status: 401,
        }
      );
    }

    // Extract step fields
    const fullName = body.full_name ?? body.fullName ?? "";
    const phone = body.phone ?? "";
    const district = body.district ?? body.location ?? "";
    const bio = body.bio ?? "";

    const title = body.title ?? body.experience_title ?? body.experienceTitle ?? "";
    const categoryId = body.category_id ?? body.categoryId;
    const durationHours = body.duration_hours ?? body.durationHours ?? 0;
    const maxGroupSize = body.max_group_size ?? body.maxGroupSize ?? 0;
    const pricePaisa = body.price_paisa ?? body.pricePaisa ?? 0;
    const description = body.description ?? "";

    const idType = body.id_type ?? body.idType ?? "";
    const idNumber = body.id_number ?? body.idNumber ?? "";
    const verificationDocPath = body.verification_doc_path ?? body.verificationDocPath ?? "";

    const bankName = body.bank_name ?? body.bankName ?? "";
    const accountName = body.account_name ?? body.accountName ?? "";
    const accountNumber = body.account_number ?? body.accountNumber ?? "";
    const branch = body.branch ?? "";

    // Validate Step 1
    if (!fullName.trim() || !phone.trim() || !district.trim() || !bio.trim()) {
      return new Response(
        JSON.stringify({ success: false, error: "Step 1 incomplete: Full name, phone, district, and bio are required" }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 400 }
      );
    }

    // Validate Step 2
    if (!title.trim() || !description.trim() || Number(pricePaisa) <= 0) {
      return new Response(
        JSON.stringify({ success: false, error: "Step 2 incomplete: Title, description, and valid price are required" }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 400 }
      );
    }

    // Validate Step 3
    if (!idType.trim() || !idNumber.trim() || !verificationDocPath.trim()) {
      return new Response(
        JSON.stringify({ success: false, error: "Step 3 incomplete: ID type, ID number, and verification document upload are required" }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 400 }
      );
    }

    // Validate Step 4
    if (!bankName.trim() || !accountName.trim() || !accountNumber.trim()) {
      return new Response(
        JSON.stringify({ success: false, error: "Step 4 incomplete: Bank name, account name, and account number are required" }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 400 }
      );
    }

    // Use admin client with service role key to bypass client RLS/trigger status restrictions
    const adminClient = createClient(supabaseUrl, supabaseServiceKey);

    const now = new Date().toISOString();
    const appRecord = {
      user_id: userId,
      status: "submitted",
      current_step: 4,
      category_id: categoryId || null,
      title: title.trim(),
      description: description.trim(),
      location: district.trim(),
      verification_doc_path: verificationDocPath.trim(),
      submitted_at: now,
      updated_at: now,
    };

    const { data: appData, error: appError } = await adminClient
      .from("host_applications")
      .upsert(appRecord, { onConflict: "user_id" })
      .select()
      .single();

    if (appError) {
      throw appError;
    }

    // Update profile role to host_applicant
    await adminClient
      .from("profiles")
      .update({ role: "host_applicant", updated_at: now })
      .eq("id", userId);

    return new Response(
      JSON.stringify({
        success: true,
        message: "Host application submitted successfully",
        application: appData,
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      }
    );
  } catch (err: any) {
    return new Response(
      JSON.stringify({ success: false, error: err.message ?? "Host application submission failed" }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 500,
      }
    );
  }
});
