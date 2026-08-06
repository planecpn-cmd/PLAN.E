import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? Deno.env.get("SUPABASE_SERVICE_KEY") ?? "";

    if (!supabaseUrl || !supabaseServiceKey) {
      throw new Error("Missing Supabase URL or Service Role key");
    }

    const supabase = createClient(supabaseUrl, supabaseServiceKey);
    const nowIso = new Date().toISOString();
    const todayStr = nowIso.split("T")[0];

    // Fetch confirmed bookings whose departure end_date is in the past (or on/before today)
    const { data: pastBookings, error: fetchError } = await supabase
      .from("bookings")
      .select("id, departure_id, experience_departures!inner(end_date)")
      .eq("status", "confirmed")
      .lte("experience_departures.end_date", todayStr);

    if (fetchError) {
      throw fetchError;
    }

    const updatedIds: string[] = [];

    if (pastBookings && pastBookings.length > 0) {
      for (const booking of pastBookings) {
        const { error: updateError } = await supabase
          .from("bookings")
          .update({
            status: "completed",
            completed_at: nowIso,
            updated_at: nowIso,
          })
          .eq("id", booking.id);

        if (!updateError) {
          updatedIds.push(booking.id);
        }
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: `Successfully completed ${updatedIds.length} trip(s)`,
        completed_count: updatedIds.length,
        completed_ids: updatedIds,
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      }
    );
  } catch (err: any) {
    return new Response(
      JSON.stringify({ success: false, error: err.message ?? "Failed to complete trips" }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 500,
      }
    );
  }
});
