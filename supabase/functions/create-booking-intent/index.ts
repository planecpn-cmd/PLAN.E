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
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? Deno.env.get("SUPABASE_ANON_KEY") ?? "";
    const supabaseClient = createClient(supabaseUrl, supabaseServiceKey);

    const authHeader = req.headers.get("Authorization");
    let userId: string | null = null;
    if (authHeader) {
      const token = authHeader.replace("Bearer ", "");
      const { data: { user } } = await supabaseClient.auth.getUser(token);
      if (user) {
        userId = user.id;
      }
    }

    const body = await req.json().catch(() => ({}));
    const {
      experience_id,
      departure_id,
      adults = 1,
      children = 0,
      contact_name,
      contact_phone,
      payment_provider = "khalti",
      user_id,
    } = body;

    const finalUserId = userId || user_id || "00000000-0000-0000-0000-000000000000";

    if (!experience_id || !departure_id || !contact_name || !contact_phone) {
      return new Response(
        JSON.stringify({ error: "Missing required fields: experience_id, departure_id, contact_name, contact_phone" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const numAdults = Math.max(1, Number(adults));
    const numChildren = Math.max(0, Number(children));
    const totalGuests = numAdults + numChildren;

    // 1. Validate Experience & Price
    const { data: experience, error: expError } = await supabaseClient
      .from("experiences")
      .select("*")
      .eq("id", experience_id)
      .single();

    if (expError || !experience) {
      return new Response(
        JSON.stringify({ error: "Experience not found" }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 2. Validate Departure & Spots Left
    const { data: departure, error: depError } = await supabaseClient
      .from("experience_departures")
      .select("*")
      .eq("id", departure_id)
      .eq("experience_id", experience_id)
      .single();

    if (depError || !departure) {
      return new Response(
        JSON.stringify({ error: "Departure date not found or invalid" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (departure.spots_left < totalGuests) {
      return new Response(
        JSON.stringify({
          error: `Not enough spots available. Requested: ${totalGuests}, Available: ${departure.spots_left}`,
        }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 3. Server Re-Pricing Logic (in paisa)
    const adultRatePaisa = Number(departure.price_override_paisa ?? experience.price_paisa);
    const childRatePaisa = Number(
      experience.child_price_paisa ?? Math.floor(adultRatePaisa * 0.75)
    );

    const subtotalPaisa = (numAdults * adultRatePaisa) + (numChildren * childRatePaisa);
    const addonsPaisa = 0;
    const feesPaisa = Math.round(subtotalPaisa * 0.05); // 5% platform fee
    const totalPaisa = subtotalPaisa + addonsPaisa + feesPaisa;

    // 4. Expiration Timestamp (15 minutes from now)
    const now = new Date();
    const quoteExpiresAt = new Date(now.getTime() + 15 * 60 * 1000).toISOString();

    // 5. Unique Idempotency Key & Ref
    const idempotencyKey = `intent_${crypto.randomUUID()}`;
    const bookingRef = `PLE-${Math.floor(100000 + Math.random() * 900000)}`;

    // 6. Insert Booking Record (status: pending)
    const { data: booking, error: bookingError } = await supabaseClient
      .from("bookings")
      .insert({
        booking_ref: bookingRef,
        user_id: finalUserId,
        experience_id,
        departure_id,
        adults: numAdults,
        children: numChildren,
        contact_name,
        contact_phone,
        subtotal_paisa: subtotalPaisa,
        addons_paisa: addonsPaisa,
        fees_paisa: feesPaisa,
        total_paisa: totalPaisa,
        status: "pending",
        quote_expires_at: quoteExpiresAt,
        is_draft: false,
      })
      .select("*, experiences(*), experience_departures(*)")
      .single();

    if (bookingError || !booking) {
      return new Response(
        JSON.stringify({ error: `Failed to create booking: ${bookingError?.message}` }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 7. Insert Payment Record (status: initiated) using service role client
    const { error: paymentError } = await supabaseClient
      .from("payments")
      .insert({
        booking_id: booking.id,
        provider: payment_provider === "esewa" ? "esewa" : "khalti",
        idempotency_key: idempotencyKey,
        amount_paisa: totalPaisa,
        status: "initiated",
        raw_response: {
          quote_expires_at: quoteExpiresAt,
          adults: numAdults,
          children: numChildren,
          created_at: now.toISOString(),
        },
      });

    if (paymentError) {
      return new Response(
        JSON.stringify({ error: `Failed to create payment intent: ${paymentError.message}` }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({
        success: true,
        booking_id: booking.id,
        booking_ref: booking.booking_ref,
        idempotency_key: idempotencyKey,
        quote_expires_at: quoteExpiresAt,
        subtotal_paisa: subtotalPaisa,
        fees_paisa: feesPaisa,
        total_paisa: totalPaisa,
        provider: payment_provider === "esewa" ? "esewa" : "khalti",
        payment_intent: {
          idempotency_key: idempotencyKey,
          booking_id: booking.id,
          amount_paisa: totalPaisa,
          provider: payment_provider === "esewa" ? "esewa" : "khalti",
          expires_at: quoteExpiresAt,
        },
        booking,
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err: any) {
    return new Response(
      JSON.stringify({ error: err.message ?? "Failed to create booking intent" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
