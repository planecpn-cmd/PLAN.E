import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import {
  AuthenticationError,
  requireAuthenticatedUser,
} from "../_shared/auth.ts";
import {
  createPaymentRedirectToken,
  hashPaymentRedirectToken,
} from "../_shared/payment_redirect_token.ts";
import {
  isPaymentProviderEnabled,
  type PaymentProvider,
} from "../_shared/payment_provider.ts";
import { consumeRateLimits } from "../_shared/rate_limit.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

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
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const publicSupabaseUrl = Deno.env.get("PUBLIC_SUPABASE_URL") ?? supabaseUrl;

    const body = await req.json().catch(() => null);
    if (!body || typeof body !== "object") {
      return new Response(
        JSON.stringify({ error: "Invalid request body" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }
    const { booking_id, provider = "khalti" } = body;

    if (typeof booking_id !== "string" || !["khalti", "esewa"].includes(provider)) {
      return new Response(
        JSON.stringify({ error: "Valid booking_id and provider are required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const { data: booking, error: bookingError } = await supabaseClient
      .from("bookings")
      .select("id,booking_ref,user_id,contact_name,contact_phone,total_paisa,status,quote_expires_at,experiences(title)")
      .eq("id", booking_id)
      .eq("user_id", user.id)
      .maybeSingle();

    if (bookingError) {
      console.error("Owned booking lookup failed", bookingError.message);
      return new Response(
        JSON.stringify({ error: "Failed to load booking" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }
    if (!booking) {
      return new Response(
        JSON.stringify({ error: "Booking or payment not found" }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (booking.status !== "pending") {
      return new Response(
        JSON.stringify({ error: "Booking is not awaiting payment" }),
        { status: 409, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }
    if (!booking.quote_expires_at || Date.parse(booking.quote_expires_at) <= Date.now()) {
      return new Response(
        JSON.stringify({ error: "Booking quote has expired" }),
        { status: 409, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const normalizedProvider = provider as PaymentProvider;
    if (!(await isPaymentProviderEnabled(supabaseClient, normalizedProvider))) {
      return new Response(
        JSON.stringify({ error: "Payment provider is currently unavailable" }),
        { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const { data: payment, error: paymentError } = await supabaseClient
      .from("payments")
      .select("id,booking_id,provider,amount_paisa,status,raw_response")
      .eq("booking_id", booking_id)
      .maybeSingle();

    if (paymentError) {
      console.error("Owned payment lookup failed", paymentError.message);
      return new Response(
        JSON.stringify({ error: "Failed to load payment" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }
    if (!payment) {
      return new Response(
        JSON.stringify({ error: "Booking or payment not found" }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (payment.status === "paid") {
      return new Response(
        JSON.stringify({ error: "Booking is already paid" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }
    const bookingTotalPaisa = Number(booking.total_paisa);
    const paymentAmountPaisa = Number(payment.amount_paisa);
    if (
      payment.provider !== normalizedProvider ||
      !Number.isSafeInteger(bookingTotalPaisa) || bookingTotalPaisa < 1 ||
      bookingTotalPaisa > MAX_TOTAL_PAISA ||
      !Number.isSafeInteger(paymentAmountPaisa) ||
      paymentAmountPaisa !== bookingTotalPaisa
    ) {
      return new Response(
        JSON.stringify({ error: "Payment details do not match the booking intent" }),
        { status: 409, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }
    if (!["initiated", "failed"].includes(payment.status)) {
      return new Response(
        JSON.stringify({ error: "Payment cannot be initiated" }),
        { status: 409, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const retryAfter = await consumeRateLimits(supabaseClient, [
      { key: `payment:initiate:user:${user.id}`, limit: 20, minutes: 15 },
      { key: `payment:initiate:booking:${booking.id}`, limit: 3, minutes: 15 },
    ]);
    if (retryAfter != null) {
      return new Response(
        JSON.stringify({ error: "Payment initiation limit reached. Try again later." }),
        {
          status: 429,
          headers: {
            ...corsHeaders,
            "Content-Type": "application/json",
            "Retry-After": String(retryAfter),
          },
        },
      );
    }

    const returnUrl = `${publicSupabaseUrl}/functions/v1/payment-return`;

    if (normalizedProvider === "khalti") {
      const khaltiSecret = Deno.env.get("KHALTI_SECRET_KEY");
      const khaltiApiBaseUrl = (
        Deno.env.get("KHALTI_API_BASE_URL") ?? "https://dev.khalti.com/api/v2"
      ).replace(/\/$/, "");
      if (!khaltiSecret) {
        return new Response(
          JSON.stringify({ error: "Khalti is not configured on the server" }),
          { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      const khaltiRes = await fetch(`${khaltiApiBaseUrl}/epayment/initiate/`, {
        method: "POST",
        headers: {
          Authorization: `Key ${khaltiSecret}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          return_url: `${returnUrl}?provider=khalti&booking_id=${booking_id}`,
          website_url: returnUrl,
          amount: paymentAmountPaisa,
          purchase_order_id: booking.booking_ref,
          purchase_order_name: booking.experiences?.title ?? "PLAN E Booking",
          customer_info: {
            name: booking.contact_name,
            phone: booking.contact_phone,
          },
        }),
      });

      const khaltiData = await khaltiRes.json();

      if (!khaltiRes.ok || !khaltiData.pidx) {
        return new Response(
          JSON.stringify({ error: khaltiData.detail || "Failed to initiate Khalti payment" }),
          { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      const { error: paymentUpdateError } = await supabaseClient
        .from("payments")
        .update({
          provider: "khalti",
          status: "initiated",
          raw_response: { ...payment.raw_response, pidx: khaltiData.pidx },
          updated_at: new Date().toISOString(),
        })
        .eq("id", payment.id)
        .eq("booking_id", booking.id);

      if (paymentUpdateError) {
        console.error("Failed to bind Khalti payment reference", paymentUpdateError.message);
        return new Response(
          JSON.stringify({ error: "Failed to save payment attempt" }),
          { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
        );
      }

      return new Response(
        JSON.stringify({ success: true, payment_url: khaltiData.payment_url, pidx: khaltiData.pidx }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // The browser redirect cannot carry the app JWT, so authorize it with a
    // short-lived one-time capability instead of exposing a booking ID.
    const redirectToken = createPaymentRedirectToken();
    const tokenHash = await hashPaymentRedirectToken(redirectToken);
    const tokenCreatedAt = new Date();
    const quoteExpiresAt = Date.parse(booking.quote_expires_at);
    if (quoteExpiresAt <= tokenCreatedAt.getTime()) {
      return new Response(
        JSON.stringify({ error: "Booking quote has expired" }),
        { status: 409, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }
    const tokenExpiresAt = new Date(
      Math.min(
        tokenCreatedAt.getTime() + 10 * 60 * 1000,
        quoteExpiresAt,
      ),
    ).toISOString();
    const { error: tokenError } = await supabaseClient
      .from("payment_redirect_tokens")
      .upsert({
        token_hash: tokenHash,
        payment_id: payment.id,
        booking_id: booking.id,
        expires_at: tokenExpiresAt,
        consumed_at: null,
        created_at: tokenCreatedAt.toISOString(),
      }, { onConflict: "payment_id" });

    if (tokenError) {
      console.error("Failed to create eSewa redirect token", tokenError.message);
      return new Response(
        JSON.stringify({ error: "Failed to prepare payment redirect" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const esewaUrl = `${publicSupabaseUrl}/functions/v1/esewa-redirect?token=${encodeURIComponent(redirectToken)}`;
    return new Response(
      JSON.stringify({ success: true, payment_url: esewaUrl }),
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
      JSON.stringify({ error: err instanceof Error ? err.message : "Failed to initiate payment" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
