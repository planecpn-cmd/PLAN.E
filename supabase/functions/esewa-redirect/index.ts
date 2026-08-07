import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// eSewa ePay v2. Falls back to the publicly documented sandbox merchant
// (EPAYTEST) when no live ESEWA_MERCHANT_CODE / ESEWA_SECRET_KEY secret is set.
const ESEWA_FORM_URL = "https://rc-epay.esewa.com.np/api/epay/main/v2/form";

function htmlEscape(value: string): string {
  return value.replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]!));
}

serve(async (req) => {
  try {
    const url = new URL(req.url);
    const bookingId = url.searchParams.get("booking_id");

    if (!bookingId) {
      return new Response("Missing booking_id", { status: 400 });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const publicSupabaseUrl = Deno.env.get("PUBLIC_SUPABASE_URL") ?? supabaseUrl;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? Deno.env.get("SUPABASE_ANON_KEY") ?? "";
    const supabaseClient = createClient(supabaseUrl, supabaseServiceKey);

    const { data: payment, error: paymentError } = await supabaseClient
      .from("payments")
      .select("*")
      .eq("booking_id", bookingId)
      .order("created_at", { ascending: false })
      .limit(1)
      .maybeSingle();

    if (paymentError || !payment) {
      return new Response("Payment record not found", { status: 404 });
    }

    if (payment.status === "paid") {
      return new Response("Booking is already paid", { status: 400 });
    }

    const productCode = Deno.env.get("ESEWA_MERCHANT_CODE") ?? "EPAYTEST";
    const secretKey = Deno.env.get("ESEWA_SECRET_KEY") ?? "8gBm/:&EnhH.1/q";
    const transactionUuid = `${bookingId}-${Date.now()}`;
    const totalAmount = (payment.amount_paisa / 100).toFixed(2);

    // Persist the transaction_uuid so verify-payment can look this attempt up later.
    await supabaseClient
      .from("payments")
      .update({
        provider: "esewa",
        raw_response: { ...payment.raw_response, transaction_uuid: transactionUuid },
        updated_at: new Date().toISOString(),
      })
      .eq("id", payment.id);

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

    const returnBase = `${publicSupabaseUrl}/functions/v1/payment-return?provider=esewa&booking_id=${bookingId}&transaction_uuid=${transactionUuid}`;

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
  } catch (err: any) {
    return new Response(`eSewa redirect failed: ${err.message ?? "unknown error"}`, { status: 500 });
  }
});
