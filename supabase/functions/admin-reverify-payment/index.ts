import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// Admin "re-verify a stuck payment" — the single highest-value control in the
// ops console. Server-to-server: the admin worker calls this with a shared
// secret and a payment_id. It re-asks the gateway (read-only status lookup) and,
// if the gateway says the payment completed, runs finalize_verified_payment —
// the same idempotent finalizer the webhook / web-return paths use. It never
// moves money.

const jsonHeaders = { "Content-Type": "application/json" };

function secretsMatch(actual: string, expected: string): boolean {
  const a = new TextEncoder().encode(actual);
  const b = new TextEncoder().encode(expected);
  let mismatch = a.length ^ b.length;
  for (let i = 0; i < Math.max(a.length, b.length); i++) mismatch |= (a[i] ?? 0) ^ (b[i] ?? 0);
  return mismatch === 0;
}

serve(async (req: Request) => {
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "method_not_allowed" }), { status: 405, headers: jsonHeaders });
  }

  const expected = Deno.env.get("ADMIN_REVERIFY_SECRET") ?? "";
  const supplied = req.headers.get("X-Admin-Secret") ?? "";
  if (!expected || !secretsMatch(supplied, expected)) {
    return new Response(JSON.stringify({ error: "unauthorized" }), { status: 401, headers: jsonHeaders });
  }

  try {
    const body = (await req.json().catch(() => null)) as { payment_id?: string } | null;
    const paymentId = body?.payment_id;
    if (!paymentId) {
      return new Response(JSON.stringify({ error: "payment_id required" }), { status: 400, headers: jsonHeaders });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    if (!supabaseUrl || !serviceKey) throw new Error("Supabase service role not configured");
    const supabase = createClient(supabaseUrl, serviceKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    const { data: payment } = await supabase.from("payments").select("*").eq("id", paymentId).maybeSingle();
    if (!payment) {
      return new Response(JSON.stringify({ error: "not_found" }), { status: 404, headers: jsonHeaders });
    }

    const bookingId = payment.booking_id as string;
    const { data: booking } = await supabase.from("bookings").select("*").eq("id", bookingId).maybeSingle();
    if (!booking) {
      return new Response(JSON.stringify({ error: "not_found" }), { status: 404, headers: jsonHeaders });
    }

    if (payment.status === "paid" && booking.status === "confirmed") {
      return new Response(
        JSON.stringify({ outcome: "already_finalized", bookingStatus: booking.status }),
        { status: 200, headers: jsonHeaders },
      );
    }

    const provider = payment.provider as "khalti" | "esewa";
    const raw = (payment.raw_response ?? {}) as Record<string, unknown>;
    let success = false;
    let txRef = "";
    let gatewayResponse: Record<string, unknown> = {};

    if (provider === "khalti") {
      const secret = Deno.env.get("KHALTI_SECRET_KEY");
      const base = (Deno.env.get("KHALTI_API_BASE_URL") ?? "https://dev.khalti.com/api/v2").replace(/\/$/, "");
      const pidx = (payment.provider_ref as string | null) ?? (raw.pidx as string | undefined) ?? "";
      if (!secret || !pidx) {
        return new Response(JSON.stringify({ error: "gateway_unconfigured" }), { status: 503, headers: jsonHeaders });
      }
      const res = await fetch(`${base}/epayment/lookup/`, {
        method: "POST",
        headers: { Authorization: `Key ${secret}`, "Content-Type": "application/json" },
        body: JSON.stringify({ pidx }),
      });
      gatewayResponse = await res.json();
      success =
        res.ok &&
        gatewayResponse.status === "Completed" &&
        Number(gatewayResponse.total_amount) === Number(payment.amount_paisa);
      txRef = (gatewayResponse.transaction_id as string) || pidx;
    } else {
      const productCode = Deno.env.get("ESEWA_MERCHANT_CODE") ?? "EPAYTEST";
      const totalAmount = (Number(payment.amount_paisa) / 100).toFixed(2);
      const txUuid = (raw.transaction_uuid as string | undefined) ?? (payment.provider_ref as string | null) ?? "";
      if (!txUuid) {
        return new Response(JSON.stringify({ error: "gateway_unconfigured" }), { status: 503, headers: jsonHeaders });
      }
      const url = new URL("https://rc.esewa.com.np/api/epay/transaction/status/");
      url.searchParams.set("product_code", productCode);
      url.searchParams.set("total_amount", totalAmount);
      url.searchParams.set("transaction_uuid", txUuid);
      const res = await fetch(url.toString());
      gatewayResponse = await res.json();
      success =
        res.ok &&
        gatewayResponse.status === "COMPLETE" &&
        gatewayResponse.transaction_uuid === txUuid &&
        Math.round(Number(gatewayResponse.total_amount) * 100) === Number(payment.amount_paisa);
      txRef = (gatewayResponse.ref_id as string) || txUuid;
    }

    if (!success) {
      return new Response(
        JSON.stringify({ outcome: "gateway_not_completed", gateway: gatewayResponse }),
        { status: 200, headers: jsonHeaders },
      );
    }

    const { data: finalized, error } = await supabase
      .rpc("finalize_verified_payment", {
        p_booking_id: bookingId,
        p_payment_id: paymentId,
        p_provider: provider,
        p_provider_ref: txRef,
        p_gateway_response: gatewayResponse,
      })
      .single();

    if (error || !finalized) {
      return new Response(
        JSON.stringify({ outcome: "finalize_failed", error: error?.message ?? "no result" }),
        { status: 500, headers: jsonHeaders },
      );
    }

    return new Response(
      JSON.stringify({
        outcome: "finalized",
        bookingStatus: (finalized as Record<string, unknown>).result_booking_status,
        alreadyProcessed: (finalized as Record<string, unknown>).already_processed,
      }),
      { status: 200, headers: jsonHeaders },
    );
  } catch (err) {
    console.error("admin-reverify-payment failed", err instanceof Error ? err.message : "unknown");
    return new Response(JSON.stringify({ error: "internal" }), { status: 500, headers: jsonHeaders });
  }
});
