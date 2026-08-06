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
    const {
      idempotency_key,
      booking_id,
      provider = "khalti",
      provider_ref,
      status = "paid",
      raw_response = {},
      participants = [],
    } = body;

    if (!idempotency_key && !booking_id) {
      return new Response(
        JSON.stringify({ error: "Either idempotency_key or booking_id is required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 1. Fetch Payment Record
    let paymentQuery = supabaseClient.from("payments").select("*");
    if (idempotency_key) {
      paymentQuery = paymentQuery.eq("idempotency_key", idempotency_key);
    } else if (booking_id) {
      paymentQuery = paymentQuery.eq("booking_id", booking_id);
    }

    const { data: payment, error: paymentFetchError } = await paymentQuery.maybeSingle();

    if (paymentFetchError || !payment) {
      return new Response(
        JSON.stringify({ error: "Payment record not found" }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 2. Idempotency Check: If already paid, return early success
    if (payment.status === "paid") {
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

    // 3. Fetch Booking Record
    const { data: booking, error: bookingFetchError } = await supabaseClient
      .from("bookings")
      .select("*")
      .eq("id", payment.booking_id)
      .single();

    if (bookingFetchError || !booking) {
      return new Response(
        JSON.stringify({ error: "Associated booking not found" }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const isPaymentSuccess = status === "paid" || status === "success" || status === "COMPLETED";

    if (!isPaymentSuccess) {
      // Mark payment as failed
      await supabaseClient
        .from("payments")
        .update({
          status: "failed",
          raw_response: raw_response,
          updated_at: new Date().toISOString(),
        })
        .eq("id", payment.id);

      return new Response(
        JSON.stringify({ error: "Payment verification failed or status is not paid" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const txRef = provider_ref || `TXN-${idempotency_key || booking.id}`;

    // 4. Update Payments -> 'paid'
    const { error: updatePaymentError } = await supabaseClient
      .from("payments")
      .update({
        status: "paid",
        provider: provider === "esewa" ? "esewa" : "khalti",
        provider_ref: txRef,
        raw_response: raw_response,
        paid_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      })
      .eq("id", payment.id);

    if (updatePaymentError) {
      return new Response(
        JSON.stringify({ error: `Failed to update payment status: ${updatePaymentError.message}` }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 5. Update Bookings -> 'confirmed' (service_role bypasses RLS status change trigger)
    const { error: updateBookingError } = await supabaseClient
      .from("bookings")
      .update({
        status: "confirmed",
        updated_at: new Date().toISOString(),
      })
      .eq("id", booking.id);

    if (updateBookingError) {
      return new Response(
        JSON.stringify({ error: `Failed to confirm booking: ${updateBookingError.message}` }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 6. Decrement spots_left in experience_departures
    const totalGuests = (booking.adults || 1) + (booking.children || 0);
    const { data: departure } = await supabaseClient
      .from("experience_departures")
      .select("spots_left")
      .eq("id", booking.departure_id)
      .single();

    if (departure) {
      const newSpots = Math.max(0, departure.spots_left - totalGuests);
      await supabaseClient
        .from("experience_departures")
        .update({ spots_left: newSpots })
        .eq("id", booking.departure_id);
    }

    // 7. Insert Participants into booking_participants
    const participantRows = [
      {
        booking_id: booking.id,
        full_name: booking.contact_name,
        is_lead: true,
      },
    ];

    if (Array.isArray(participants) && participants.length > 0) {
      for (const p of participants) {
        if (p.full_name && p.full_name !== booking.contact_name) {
          participantRows.push({
            booking_id: booking.id,
            full_name: p.full_name,
            is_lead: false,
          });
        }
      }
    }

    await supabaseClient.from("booking_participants").insert(participantRows);

    // 8. Seed Gear Checklist in gear_checklist_items
    const { data: experience } = await supabaseClient
      .from("experiences")
      .select("bring_list")
      .eq("id", booking.experience_id)
      .single();

    let gearList: string[] = experience?.bring_list || [];
    if (!gearList || gearList.length === 0) {
      gearList = [
        "Trekking Boots",
        "Water Bottle (1.5L)",
        "Warm Layered Clothing",
        "Rain Jacket / Poncho",
        "Personal First Aid Kit",
        "Headlamp with extra batteries",
      ];
    }

    const gearRows = gearList.map((label: string, index: number) => ({
      booking_id: booking.id,
      label,
      is_checked: false,
      is_custom: false,
      sort_order: index,
    }));

    await supabaseClient.from("gear_checklist_items").insert(gearRows);

    return new Response(
      JSON.stringify({
        success: true,
        booking_id: booking.id,
        booking_ref: booking.booking_ref,
        status: "confirmed",
        payment_status: "paid",
        message: "Payment verified and booking confirmed successfully",
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err: any) {
    return new Response(
      JSON.stringify({ error: err.message ?? "Payment webhook processing failed" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
