import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import {
  AuthenticationError,
  requireAuthenticatedUser,
} from "../_shared/auth.ts";
import { consumeRateLimits } from "../_shared/rate_limit.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

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
      idempotency_key,
      booking_id,
      provider = "khalti",
      pidx,
      transaction_uuid,
    } = body;

    if (
      typeof idempotency_key !== "string" || !idempotency_key.trim() ||
      typeof booking_id !== "string" || !booking_id.trim()
    ) {
      return new Response(
        JSON.stringify({ error: "booking_id and idempotency_key are required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (!["khalti", "esewa"].includes(provider)) {
      return new Response(
        JSON.stringify({ error: "Invalid payment provider" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }
    const normalizedProvider = provider as "khalti" | "esewa";
    if (normalizedProvider === "khalti" && (typeof pidx !== "string" || !pidx.trim())) {
      return new Response(
        JSON.stringify({ error: "pidx is required to verify a Khalti payment" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }
    if (
      normalizedProvider === "esewa" &&
      (typeof transaction_uuid !== "string" || !transaction_uuid.trim())
    ) {
      return new Response(
        JSON.stringify({ error: "transaction_uuid is required to verify an eSewa payment" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Resolve the caller-owned booking before loading or mutating payment data.
    const { data: booking, error: bookingFetchError } = await supabaseClient
      .from("bookings")
      .select("*")
      .eq("id", booking_id)
      .eq("user_id", user.id)
      .maybeSingle();

    if (bookingFetchError) {
      console.error("Owned booking lookup failed", bookingFetchError.message);
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

    const { data: payment, error: paymentFetchError } = await supabaseClient
      .from("payments")
      .select("*")
      .eq("booking_id", booking.id)
      .eq("idempotency_key", idempotency_key)
      .maybeSingle();

    if (paymentFetchError) {
      console.error("Owned payment lookup failed", paymentFetchError.message);
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

    if (
      payment.provider !== normalizedProvider ||
      Number(payment.amount_paisa) !== Number(booking.total_paisa)
    ) {
      return new Response(
        JSON.stringify({ error: "Payment details do not match the booking intent" }),
        { status: 409, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }
    if (
      normalizedProvider === "khalti" &&
      payment.raw_response?.pidx !== pidx
    ) {
      return new Response(
        JSON.stringify({ error: "Payment reference does not match the initiated payment" }),
        { status: 409, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }
    if (
      normalizedProvider === "esewa" &&
      payment.raw_response?.transaction_uuid !== transaction_uuid
    ) {
      return new Response(
        JSON.stringify({ error: "Payment reference does not match the initiated payment" }),
        { status: 409, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // Idempotency is checked only after the caller owns the booking and payment.
    if (payment.status === "paid") {
      if (booking.status !== "confirmed") {
        return new Response(
          JSON.stringify({ error: "Payment state is inconsistent" }),
          { status: 409, headers: { ...corsHeaders, "Content-Type": "application/json" } },
        );
      }
      return new Response(
        JSON.stringify({
          success: true,
          booking_id: payment.booking_id,
          status: "confirmed",
          payment_status: "paid",
          message: "Payment was already processed and verified",
        }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }
    if (booking.status !== "pending" || !["initiated", "failed"].includes(payment.status)) {
      return new Response(
        JSON.stringify({ error: "Payment cannot be verified for this booking" }),
        { status: 409, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }
    if (!booking.quote_expires_at || Date.parse(booking.quote_expires_at) <= Date.now()) {
      return new Response(
        JSON.stringify({ error: "Booking quote has expired" }),
        { status: 409, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const retryAfter = await consumeRateLimits(supabaseClient, [
      { key: `payment:verify:user:${user.id}`, limit: 20, minutes: 15 },
      { key: `payment:verify:booking:${booking.id}`, limit: 10, minutes: 15 },
    ]);
    if (retryAfter != null) {
      return new Response(
        JSON.stringify({ error: "Payment verification limit reached. Try again later." }),
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

    // 3b. Verify the payment directly with the gateway using our server-side
    // secret. Never trust a client-supplied "paid" status — that lets anyone
    // confirm a free booking by calling this endpoint directly.
    let isPaymentSuccess = false;
    let txRef = "";
    let gatewayResponse: Record<string, unknown> = {};

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

      const lookupRes = await fetch(`${khaltiApiBaseUrl}/epayment/lookup/`, {
        method: "POST",
        headers: {
          Authorization: `Key ${khaltiSecret}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ pidx }),
      });
      const lookupData = await lookupRes.json();
      gatewayResponse = lookupData;

      isPaymentSuccess =
        lookupRes.ok &&
        lookupData.status === "Completed" &&
        Number(lookupData.total_amount) === Number(payment.amount_paisa);
      txRef = lookupData.transaction_id || pidx;
    } else {
      const productCode = Deno.env.get("ESEWA_MERCHANT_CODE") ?? "EPAYTEST";
      const totalAmount = (payment.amount_paisa / 100).toFixed(2);
      const statusUrl = new URL("https://rc.esewa.com.np/api/epay/transaction/status/");
      statusUrl.searchParams.set("product_code", productCode);
      statusUrl.searchParams.set("total_amount", totalAmount);
      statusUrl.searchParams.set("transaction_uuid", transaction_uuid);

      const statusRes = await fetch(statusUrl.toString());
      const statusData = await statusRes.json();
      gatewayResponse = statusData;

      isPaymentSuccess =
        statusRes.ok &&
        statusData.status === "COMPLETE" &&
        statusData.transaction_uuid === transaction_uuid &&
        Math.round(Number(statusData.total_amount) * 100) === Number(payment.amount_paisa);
      txRef = statusData.ref_id || transaction_uuid;
    }

    if (!isPaymentSuccess) {
      // Mark payment as failed
      await supabaseClient
        .from("payments")
        .update({
          status: "failed",
          raw_response: { ...payment.raw_response, ...gatewayResponse },
          updated_at: new Date().toISOString(),
        })
        .eq("id", payment.id)
        .eq("booking_id", booking.id)
        .in("status", ["initiated", "failed"]);

      return new Response(
        JSON.stringify({ error: "Payment verification failed or status is not paid" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const { data: finalized, error: finalizationError } = await supabaseClient
      .rpc("finalize_verified_payment", {
        p_booking_id: booking.id,
        p_payment_id: payment.id,
        p_provider: normalizedProvider,
        p_provider_ref: txRef,
        p_gateway_response: gatewayResponse,
      })
      .single();

    if (finalizationError || !finalized) {
      console.error(
        "Atomic payment finalization failed",
        finalizationError?.message ?? "No result returned",
      );
      return new Response(
        JSON.stringify({ error: "Failed to finalize verified payment" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    return new Response(
      JSON.stringify({
        success: true,
        booking_id: finalized.result_booking_id,
        booking_ref: finalized.result_booking_ref,
        status: finalized.result_booking_status,
        payment_status: finalized.result_payment_status,
        message: "Payment verified and booking confirmed successfully",
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
      JSON.stringify({ error: err instanceof Error ? err.message : "Payment webhook processing failed" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
