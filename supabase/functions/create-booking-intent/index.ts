import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import {
  AuthenticationError,
  requireAuthenticatedUser,
} from "../_shared/auth.ts";
import {
  isPaymentProviderEnabled,
  type PaymentProvider,
} from "../_shared/payment_provider.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const MAX_RATE_PAISA = 10_000_000_000;
const MAX_TOTAL_PAISA = 210_000_000_000;

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({ error: "Method not allowed" }),
      { status: 405, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }

  try {
    const { user, adminClient: supabaseClient } = await requireAuthenticatedUser(req);

    const body = await req.json().catch(() => null);
    if (!body || typeof body !== "object") {
      return new Response(
        JSON.stringify({ error: "Invalid request body" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }
    const {
      experience_id,
      departure_id,
      adults = 1,
      children = 0,
      contact_name,
      contact_phone,
      payment_provider = "khalti",
    } = body;

    if (
      typeof experience_id !== "string" ||
      typeof departure_id !== "string" ||
      typeof contact_name !== "string" ||
      typeof contact_phone !== "string"
    ) {
      return new Response(
        JSON.stringify({ error: "Missing required fields: experience_id, departure_id, contact_name, contact_phone" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const numAdults = Number(adults);
    const numChildren = Number(children);
    const totalGuests = numAdults + numChildren;
    const normalizedName = contact_name.trim().replace(/\s+/g, " ");
    const normalizedPhone = contact_phone.trim();
    if (
      !Number.isInteger(numAdults) || numAdults < 1 || numAdults > 20 ||
      !Number.isInteger(numChildren) || numChildren < 0 || numChildren > 20 ||
      totalGuests > 20 ||
      normalizedName.length < 2 || normalizedName.length > 120 ||
      normalizedPhone.length < 7 || normalizedPhone.length > 24 ||
      !["khalti", "esewa"].includes(payment_provider)
    ) {
      return new Response(
        JSON.stringify({ error: "Invalid booking details" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const normalizedProvider = payment_provider as PaymentProvider;
    if (!(await isPaymentProviderEnabled(supabaseClient, normalizedProvider))) {
      return new Response(
        JSON.stringify({ error: "Payment provider is currently unavailable" }),
        { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // 1. Validate Experience & Price
    const { data: experience, error: expError } = await supabaseClient
      .from("experiences")
      .select("id,price_paisa,child_price_paisa")
      .eq("id", experience_id)
      .eq("status", "published")
      .maybeSingle();

    if (expError || !experience) {
      console.error("Experience lookup failed", {
        experience_id,
        error: expError?.message ?? "No matching row",
      });
      return new Response(
        JSON.stringify({ error: "Experience not found" }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 2. Validate Departure & Spots Left
    const { data: departure, error: depError } = await supabaseClient
      .from("experience_departures")
      .select("id,spots_left,price_override_paisa,start_date")
      .eq("id", departure_id)
      .eq("experience_id", experience_id)
      .eq("status", "open")
      .maybeSingle();

    if (depError || !departure) {
      console.error("Departure lookup failed", {
        experience_id,
        departure_id,
        error: depError?.message ?? "No matching row",
      });
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

    if (
      !Number.isSafeInteger(adultRatePaisa) || adultRatePaisa < 0 ||
      adultRatePaisa > MAX_RATE_PAISA ||
      !Number.isSafeInteger(childRatePaisa) || childRatePaisa < 0 ||
      childRatePaisa > MAX_RATE_PAISA
    ) {
      console.error("Invalid server-owned experience price", { experience_id });
      return new Response(
        JSON.stringify({ error: "Experience price is unavailable" }),
        { status: 409, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const subtotalPaisa = (numAdults * adultRatePaisa) + (numChildren * childRatePaisa);
    const addonsPaisa = 0;
    const feesPaisa = Math.round(subtotalPaisa * 0.05); // 5% platform fee
    const totalPaisa = subtotalPaisa + addonsPaisa + feesPaisa;

    if (
      ![subtotalPaisa, addonsPaisa, feesPaisa, totalPaisa].every(Number.isSafeInteger) ||
      subtotalPaisa < 0 || addonsPaisa < 0 || feesPaisa < 0 ||
      totalPaisa < 1 || totalPaisa > MAX_TOTAL_PAISA
    ) {
      console.error("Invalid server-calculated booking total", { experience_id });
      return new Response(
        JSON.stringify({ error: "Booking total is unavailable" }),
        { status: 409, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

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
        user_id: user.id,
        experience_id,
        departure_id,
        adults: numAdults,
        children: numChildren,
        contact_name: normalizedName,
        contact_phone: normalizedPhone,
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
      console.error("Booking insert failed", bookingError?.message ?? "No row returned");
      return new Response(
        JSON.stringify({ error: "Failed to create booking" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 7. Insert Payment Record (status: initiated) using service role client
    const { error: paymentError } = await supabaseClient
      .from("payments")
      .insert({
        booking_id: booking.id,
        provider: normalizedProvider,
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
      console.error("Payment intent insert failed", paymentError.message);
      return new Response(
        JSON.stringify({ error: "Failed to create payment intent" }),
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
        provider: normalizedProvider,
        payment_intent: {
          idempotency_key: idempotencyKey,
          booking_id: booking.id,
          amount_paisa: totalPaisa,
          provider: normalizedProvider,
          expires_at: quoteExpiresAt,
        },
        booking,
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err: unknown) {
    if (err instanceof AuthenticationError) {
      return new Response(
        JSON.stringify({ error: err.message }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }
    return new Response(
      JSON.stringify({ error: err instanceof Error ? err.message : "Failed to create booking intent" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
