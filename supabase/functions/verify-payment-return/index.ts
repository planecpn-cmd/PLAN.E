import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// Browser-redirect landing point for the web app's checkout flow. Unlike
// payment-webhook (called by the authenticated mobile app after its WebView
// intercepts the gateway redirect), this endpoint is reached by a plain,
// unauthenticated browser navigation — Khalti/eSewa redirect the user's own
// browser here via payment-return, which forwards to this function with the
// same query string. There is no user session to check, so every lookup is
// scoped by booking_id/payment identity instead of an owning user, and the
// gateway is always re-verified server-side with our secret — the same rule
// payment-webhook follows: never trust a client-supplied "paid" status.
//
// Mirrors the verification and finalization logic in payment-webhook so both
// the mobile and web checkout paths finalize a booking identically.

const WEB_ORIGIN = "https://planenepal.com";

function redirectToConfirmation(bookingId: string | null, status: string): Response {
  const url = bookingId
    ? `${WEB_ORIGIN}/booking/confirmation/${bookingId}?payment=${encodeURIComponent(status)}`
    : `${WEB_ORIGIN}/?payment=${encodeURIComponent(status)}`;
  return new Response(null, { status: 302, headers: { Location: url } });
}

serve(async (req) => {
  if (req.method !== "GET") {
    return new Response("Method not allowed", { status: 405 });
  }

  const url = new URL(req.url);
  const provider = url.searchParams.get("provider");
  const bookingIdParam = url.searchParams.get("booking_id");
  const pidx = url.searchParams.get("pidx");
  const transactionUuid = url.searchParams.get("transaction_uuid");
  const gatewayStatus = url.searchParams.get("status");

  if (provider !== "khalti" && provider !== "esewa") {
    return redirectToConfirmation(bookingIdParam, "invalid");
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!supabaseUrl || !serviceRoleKey) {
      throw new Error("Supabase service role is not configured");
    }
    const supabaseClient = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    // eSewa's failure_url carries status=failed with no reliable transaction_uuid
    // guarantee — bail out to the confirmation page without touching payment rows.
    if (provider === "esewa" && gatewayStatus === "failed") {
      const { data: paymentByTx } = transactionUuid
        ? await supabaseClient
            .from("payments")
            .select("booking_id")
            .eq("raw_response->>transaction_uuid", transactionUuid)
            .maybeSingle()
        : { data: null };
      return redirectToConfirmation(paymentByTx?.booking_id ?? bookingIdParam, "failed");
    }

    let bookingId = bookingIdParam;
    let payment: Record<string, unknown> | null = null;

    if (provider === "khalti") {
      if (!bookingId || !pidx) return redirectToConfirmation(bookingId, "invalid");
      const { data } = await supabaseClient
        .from("payments")
        .select("*")
        .eq("booking_id", bookingId)
        .eq("provider", "khalti")
        .maybeSingle();
      payment = data;
    } else {
      if (!transactionUuid) return redirectToConfirmation(bookingId, "invalid");
      const { data } = await supabaseClient
        .from("payments")
        .select("*")
        .eq("provider", "esewa")
        .eq("raw_response->>transaction_uuid", transactionUuid)
        .maybeSingle();
      payment = data;
      bookingId = (data?.booking_id as string | undefined) ?? bookingId;
    }

    if (!payment) return redirectToConfirmation(bookingId, "not_found");

    const { data: booking } = await supabaseClient
      .from("bookings")
      .select("*")
      .eq("id", payment.booking_id as string)
      .maybeSingle();

    if (!booking) return redirectToConfirmation(bookingId, "not_found");

    // Already finalized (user refreshed, or double redirect) — nothing to do.
    if (payment.status === "paid") {
      return redirectToConfirmation(bookingId, booking.status === "confirmed" ? "confirmed" : "inconsistent");
    }
    if (booking.status !== "pending" || !["initiated", "failed"].includes(payment.status as string)) {
      return redirectToConfirmation(bookingId, "unavailable");
    }
    if (!booking.quote_expires_at || Date.parse(booking.quote_expires_at as string) <= Date.now()) {
      return redirectToConfirmation(bookingId, "expired");
    }

    let isPaymentSuccess = false;
    let txRef = "";
    let gatewayResponse: Record<string, unknown> = {};

    if (provider === "khalti") {
      const khaltiSecret = Deno.env.get("KHALTI_SECRET_KEY");
      const khaltiApiBaseUrl = (Deno.env.get("KHALTI_API_BASE_URL") ?? "https://dev.khalti.com/api/v2").replace(/\/$/, "");
      if (!khaltiSecret) return redirectToConfirmation(bookingId, "unavailable");

      const lookupRes = await fetch(`${khaltiApiBaseUrl}/epayment/lookup/`, {
        method: "POST",
        headers: { Authorization: `Key ${khaltiSecret}`, "Content-Type": "application/json" },
        body: JSON.stringify({ pidx }),
      });
      const lookupData = await lookupRes.json();
      gatewayResponse = lookupData;
      isPaymentSuccess =
        lookupRes.ok &&
        lookupData.status === "Completed" &&
        Number(lookupData.total_amount) === Number(payment.amount_paisa);
      txRef = lookupData.transaction_id || pidx || "";
    } else {
      const productCode = Deno.env.get("ESEWA_MERCHANT_CODE") ?? "EPAYTEST";
      const totalAmount = (Number(payment.amount_paisa) / 100).toFixed(2);
      const statusUrl = new URL("https://rc.esewa.com.np/api/epay/transaction/status/");
      statusUrl.searchParams.set("product_code", productCode);
      statusUrl.searchParams.set("total_amount", totalAmount);
      statusUrl.searchParams.set("transaction_uuid", transactionUuid!);

      const statusRes = await fetch(statusUrl.toString());
      const statusData = await statusRes.json();
      gatewayResponse = statusData;
      isPaymentSuccess =
        statusRes.ok &&
        statusData.status === "COMPLETE" &&
        statusData.transaction_uuid === transactionUuid &&
        Math.round(Number(statusData.total_amount) * 100) === Number(payment.amount_paisa);
      txRef = statusData.ref_id || transactionUuid || "";
    }

    if (!isPaymentSuccess) {
      await supabaseClient
        .from("payments")
        .update({
          status: "failed",
          raw_response: { ...(payment.raw_response as Record<string, unknown>), ...gatewayResponse },
          updated_at: new Date().toISOString(),
        })
        .eq("id", payment.id as string)
        .eq("booking_id", bookingId as string)
        .in("status", ["initiated", "failed"]);
      return redirectToConfirmation(bookingId, "failed");
    }

    const { data: finalized, error: finalizationError } = await supabaseClient
      .rpc("finalize_verified_payment", {
        p_booking_id: bookingId,
        p_payment_id: payment.id,
        p_provider: provider,
        p_provider_ref: txRef,
        p_gateway_response: gatewayResponse,
      })
      .single();

    if (finalizationError || !finalized) {
      console.error("Web payment finalization failed", finalizationError?.message ?? "No result returned");
      return redirectToConfirmation(bookingId, "unavailable");
    }

    return redirectToConfirmation(bookingId, "confirmed");
  } catch (err: unknown) {
    console.error("verify-payment-return failed", err instanceof Error ? err.message : "unknown error");
    return redirectToConfirmation(bookingIdParam, "error");
  }
});
