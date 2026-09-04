import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { hashPaymentRedirectToken } from "../_shared/payment_redirect_token.ts";

// eSewa ePay v2. Falls back to the publicly documented sandbox merchant
// (EPAYTEST) when no live ESEWA_MERCHANT_CODE / ESEWA_SECRET_KEY secret is set.
const ESEWA_FORM_URL = "https://rc-epay.esewa.com.np/api/epay/main/v2/form";

function htmlEscape(value: string): string {
  return value.replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]!));
}

serve(async (req) => {
  try {
    if (req.method !== "GET") {
      return new Response("Method not allowed", { status: 405 });
    }

    const url = new URL(req.url);
    const token = url.searchParams.get("token");

    if (!token || !/^[A-Za-z0-9_-]{43}$/.test(token)) {
      return new Response("Payment link is invalid or expired", { status: 404 });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const publicSupabaseUrl = Deno.env.get("PUBLIC_SUPABASE_URL") ?? supabaseUrl;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!supabaseUrl || !publicSupabaseUrl || !supabaseServiceKey) {
      throw new Error("Payment redirect is not configured");
    }
    const supabaseClient = createClient(supabaseUrl, supabaseServiceKey);

    const tokenHash = await hashPaymentRedirectToken(token);
    const { data: consumedToken, error: tokenError } = await supabaseClient
      .rpc("consume_payment_redirect_token", { p_token_hash: tokenHash })
      .maybeSingle();

    if (tokenError) {
      console.error("Payment redirect token lookup failed", tokenError.message);
      return new Response("Payment link could not be opened", { status: 500 });
    }
    if (!consumedToken) {
      return new Response("Payment link is invalid or expired", { status: 404 });
    }

    const { data: booking, error: bookingError } = await supabaseClient
      .from("bookings")
      .select("id,total_paisa,status,quote_expires_at")
      .eq("id", consumedToken.booking_id)
      .maybeSingle();

    const { data: payment, error: paymentError } = await supabaseClient
      .from("payments")
      .select("id,booking_id,provider,amount_paisa,status,raw_response")
      .eq("id", consumedToken.payment_id)
      .eq("booking_id", consumedToken.booking_id)
      .maybeSingle();

    if (bookingError || paymentError) {
      console.error(
        "Payment redirect binding lookup failed",
        bookingError?.message ?? paymentError?.message,
      );
      return new Response("Payment link could not be opened", { status: 500 });
    }
    if (
      !booking || !payment ||
      booking.status !== "pending" ||
      !booking.quote_expires_at || Date.parse(booking.quote_expires_at) <= Date.now() ||
      payment.provider !== "esewa" ||
      !["initiated", "failed"].includes(payment.status) ||
      Number(payment.amount_paisa) !== Number(booking.total_paisa)
    ) {
      return new Response("Payment link is invalid or expired", { status: 404 });
    }

    const productCode = Deno.env.get("ESEWA_MERCHANT_CODE") ?? "EPAYTEST";
    const secretKey = Deno.env.get("ESEWA_SECRET_KEY") ?? "8gBm/:&EnhH.1/q";
    const transactionUuid = crypto.randomUUID();
    const totalAmount = (payment.amount_paisa / 100).toFixed(2);

    // Persist the transaction_uuid so verify-payment can look this attempt up later.
    const { error: paymentUpdateError } = await supabaseClient
      .from("payments")
      .update({
        provider: "esewa",
        status: "initiated",
        raw_response: { ...payment.raw_response, transaction_uuid: transactionUuid },
        updated_at: new Date().toISOString(),
      })
      .eq("id", payment.id)
      .eq("booking_id", booking.id);

    if (paymentUpdateError) {
      console.error("Failed to bind eSewa transaction", paymentUpdateError.message);
      return new Response("Payment link could not be opened", { status: 500 });
    }

    const signedFieldNames = "total_amount,transaction_uuid,product_code";
    const message = `total_amount=${totalAmount},transaction_uuid=${transactionUuid},product_code=${productCode}`;

    const keyData = new TextEncoder().encode(secretKey);
    const msgData = new TextEncoder().encode(message);
    const cryptoKey = await crypto.subtle.importKey(
      "raw",
      keyData,
      { name: "HMAC", hash: "SHA-256" },
      false,
      ["sign"]
    );
    const signatureBuffer = await crypto.subtle.sign("HMAC", cryptoKey, msgData);
    const signature = btoa(String.fromCharCode(...new Uint8Array(signatureBuffer)));

    const returnBase = `${publicSupabaseUrl}/functions/v1/payment-return?provider=esewa&transaction_uuid=${transactionUuid}`;

    const fields: Record<string, string> = {
      amount: totalAmount,
      tax_amount: "0",
      total_amount: totalAmount,
      transaction_uuid: transactionUuid,
      product_code: productCode,
      product_service_charge: "0",
      product_delivery_charge: "0",
      success_url: `${returnBase}&status=success`,
      failure_url: `${returnBase}&status=failed`,
      signed_field_names: signedFieldNames,
      signature,
    };

    const inputs = Object.entries(fields)
      .map(([name, value]) => `<input type="hidden" name="${htmlEscape(name)}" value="${htmlEscape(value)}" />`)
      .join("\n");

    const html = `<!doctype html>
<html><body onload="document.forms[0].submit()">
<form action="${ESEWA_FORM_URL}" method="POST">
${inputs}
</form>
<p>Redirecting to eSewa...</p>
</body></html>`;

    return new Response(html, { status: 200, headers: { "Content-Type": "text/html" } });
  } catch (err: unknown) {
    console.error("eSewa redirect failed", err instanceof Error ? err.message : "unknown error");
    return new Response("Payment link could not be opened", { status: 500 });
  }
});
