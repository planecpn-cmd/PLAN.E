import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const jsonHeaders = { "Content-Type": "application/json" };

function secretsMatch(actual: string, expected: string): boolean {
  const actualBytes = new TextEncoder().encode(actual);
  const expectedBytes = new TextEncoder().encode(expected);
  let mismatch = actualBytes.length ^ expectedBytes.length;
  for (let index = 0; index < Math.max(actualBytes.length, expectedBytes.length); index++) {
    mismatch |= (actualBytes[index] ?? 0) ^ (expectedBytes[index] ?? 0);
  }
  return mismatch === 0;
}

serve(async (req: Request) => {
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "method_not_allowed" }), {
      status: 405,
      headers: jsonHeaders,
    });
  }

  const expectedSecret = Deno.env.get("COMPLETE_TRIPS_CRON_SECRET") ?? "";
  const suppliedSecret = req.headers.get("X-Cron-Secret") ?? "";
  if (!expectedSecret || !secretsMatch(suppliedSecret, expectedSecret)) {
    return new Response(JSON.stringify({ error: "unauthorized" }), {
      status: 401,
      headers: jsonHeaders,
    });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    if (!supabaseUrl || !supabaseServiceKey) {
      throw new Error("Missing Supabase URL or Service Role key");
    }

    const supabase = createClient(supabaseUrl, supabaseServiceKey);
    const nowIso = new Date().toISOString();
    const todayStr = nowIso.split("T")[0];
    const { data: pastBookings, error: fetchError } = await supabase
      .from("bookings")
      .select("id, departure_id, experience_departures!inner(end_date)")
      .eq("status", "confirmed")
      .lte("experience_departures.end_date", todayStr);
    if (fetchError) throw fetchError;

    const updatedIds: string[] = [];
    for (const booking of pastBookings ?? []) {
      const { error } = await supabase
        .from("bookings")
        .update({ status: "completed", completed_at: nowIso, updated_at: nowIso })
        .eq("id", booking.id);
      if (!error) updatedIds.push(booking.id);
    }

    return new Response(JSON.stringify({
      success: true,
      message: `Successfully completed ${updatedIds.length} trip(s)`,
      completed_count: updatedIds.length,
      completed_ids: updatedIds,
    }), { status: 200, headers: jsonHeaders });
  } catch (err: unknown) {
    console.error(
      "Complete trips cron failed",
      err instanceof Error ? err.message : "unknown error",
    );
    return new Response(
      JSON.stringify({ success: false, error: "Failed to complete trips" }),
      { status: 500, headers: jsonHeaders },
    );
  }
});
