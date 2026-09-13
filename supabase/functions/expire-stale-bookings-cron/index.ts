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

// Server-to-server scheduled job, same shape as complete-trips-cron: a
// dedicated X-Cron-Secret (not the service-role key) so a leaked cron secret
// can't be used for anything else, and vice versa. Wiring the actual
// scheduler (pg_cron / GitHub Actions cron / Cloudflare cron) that POSTs here
// on an interval is ops, same as complete-trips-cron today.
serve(async (req: Request) => {
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "method_not_allowed" }), {
      status: 405,
      headers: jsonHeaders,
    });
  }

  const expectedSecret = Deno.env.get("EXPIRE_STALE_BOOKINGS_CRON_SECRET") ?? "";
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
    const { data: expiredCount, error } = await supabase.rpc("expire_stale_pending_bookings");
    if (error) throw error;

    return new Response(JSON.stringify({
      success: true,
      message: `Expired ${expiredCount} stale pending booking(s)`,
      expired_count: expiredCount,
    }), { status: 200, headers: jsonHeaders });
  } catch (err: unknown) {
    console.error(
      "Expire stale bookings cron failed",
      err instanceof Error ? err.message : "unknown error",
    );
    return new Response(
      JSON.stringify({ success: false, error: "Failed to expire stale bookings" }),
      { status: 500, headers: jsonHeaders },
    );
  }
});
