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

    const body = await req.json().catch(() => ({}));
    const { booking_id, provider = "khalti" } = body;

    if (!booking_id) {
      return new Response(
        JSON.stringify({ error: "booking_id is required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const { data: booking, error: bookingError } = await supabaseClient
      .from("bookings")
      .select("*, experiences(title)")
      .eq("id", booking_id)
      .single();

    if (bookingError || !booking) {
      return new Response(
        JSON.stringify({ error: "Booking not found" }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const { data: payment, error: paymentError } = await supabaseClient
      .from("payments")
      .select("*")
      .eq("booking_id", booking_id)
      .order("created_at", { ascending: false })
      .limit(1)
      .maybeSingle();

    if (paymentError || !payment) {
      return new Response(
        JSON.stringify({ error: "Payment record not found for booking" }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (payment.status === "paid") {
      return new Response(
        JSON.stringify({ error: "Booking is already paid" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const returnUrl = `${supabaseUrl}/functions/v1/payment-return`;
    const normalizedProvider = provider === "esewa" ? "esewa" : "khalti";

    if (normalizedProvider === "khalti") {
      const khaltiSecret = Deno.env.get("KHALTI_SECRET_KEY");
      if (!khaltiSecret) {
        return new Response(
          JSON.stringify({ error: "Khalti is not configured on the server" }),
          { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      const khaltiRes = await fetch("https://khalti.com/api/v2/epayment/initiate/", {
        method: "POST",
        headers: {
          Authorization: `Key ${khaltiSecret}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          return_url: `${returnUrl}?provider=khalti&booking_id=${booking_id}`,
          website_url: returnUrl,
          amount: payment.amount_paisa,
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

      await supabaseClient
        .from("payments")
        .update({
          provider: "khalti",
          raw_response: { ...payment.raw_response, pidx: khaltiData.pidx },
          updated_at: new Date().toISOString(),
        })
        .eq("id", payment.id);

      return new Response(
        JSON.stringify({ success: true, payment_url: khaltiData.payment_url, pidx: khaltiData.pidx }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // eSewa: hand off to esewa-redirect, which builds + serves the signed auto-submit form.
    const esewaUrl = `${supabaseUrl}/functions/v1/esewa-redirect?booking_id=${booking_id}`;
    return new Response(
      JSON.stringify({ success: true, payment_url: esewaUrl }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err: any) {
    return new Response(
      JSON.stringify({ error: err.message ?? "Failed to initiate payment" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
