import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const ANTHROPIC_MODEL = "claude-sonnet-5";

// Recommendations are constrained to this catalog (id + short fields) so
// the model can only suggest experiences that actually exist and are
// bookable — never a hallucinated trek.
async function fetchCatalogSummary(supabaseClient: any) {
  const { data, error } = await supabaseClient
    .from("experiences")
    .select(
      "id, title, summary, difficulty, duration_hours, price_paisa, regions(name_en), categories(name_en)"
    )
    .eq("status", "published")
    .limit(60);

  if (error) throw new Error(`Catalog fetch failed: ${error.message}`);

  return (data ?? []).map((e: any) => ({
    id: e.id,
    title: e.title,
    summary: e.summary,
    difficulty: e.difficulty,
    duration_days: Math.ceil((e.duration_hours ?? 0) / 24),
    price_npr: Math.round((e.price_paisa ?? 0) / 100),
    region: e.regions?.name_en ?? null,
    category: e.categories?.name_en ?? null,
  }));
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const anthropicKey = Deno.env.get("ANTHROPIC_API_KEY");
    if (!anthropicKey) {
      return new Response(
        JSON.stringify({ error: "AI itinerary generation is not configured yet." }),
        { status: 503, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseServiceKey =
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? Deno.env.get("SUPABASE_ANON_KEY") ?? "";
    const supabaseClient = createClient(supabaseUrl, supabaseServiceKey);

    const body = await req.json().catch(() => ({}));
    const {
      trip_type,       // e.g. "trekking", "wildlife", "culture", "wellness"
      duration_days,    // e.g. 7
      pace,             // e.g. "relaxed", "moderate", "intense"
      budget_npr,       // e.g. 150000 — total budget, optional
      interests,        // free-text, e.g. "photography, local food, monasteries"
      group_type,       // e.g. "solo", "couple", "family", "friends"
    } = body;

    if (!trip_type || !duration_days) {
      return new Response(
        JSON.stringify({ error: "Missing required fields: trip_type, duration_days" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const catalog = await fetchCatalogSummary(supabaseClient);

    const systemPrompt = `You are a Nepal trip-planning assistant for the PLAN E app. Recommend a personalized itinerary built ONLY from the experiences in the provided catalog — never invent a trek, tour, or place that isn't listed. If nothing in the catalog fits well, say so honestly in "notes" rather than forcing a bad match.

Respond with ONLY valid JSON, no prose outside the JSON, matching this shape:
{
  "summary": "one or two sentence overview of the recommended plan",
  "picks": [
    { "experience_id": "<id from catalog>", "reason": "one sentence on why this fits their preferences" }
  ],
  "notes": "optional caveats, e.g. budget doesn't fully cover the picks, or catalog gaps"
}`;

    const userPrompt = `Traveler preferences:
- Trip type: ${trip_type}
- Duration: ${duration_days} days
- Pace: ${pace ?? "not specified"}
- Budget: ${budget_npr ? `NPR ${budget_npr}` : "not specified"}
- Group: ${group_type ?? "not specified"}
- Interests: ${interests ?? "not specified"}

Catalog (JSON array of available experiences):
${JSON.stringify(catalog)}`;

    const aiResponse = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "content-type": "application/json",
        "x-api-key": anthropicKey,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model: ANTHROPIC_MODEL,
        max_tokens: 1024,
        system: systemPrompt,
        messages: [{ role: "user", content: userPrompt }],
      }),
    });

    if (!aiResponse.ok) {
      const errText = await aiResponse.text();
      console.error("Anthropic API error", aiResponse.status, errText);
      return new Response(
        JSON.stringify({ error: "AI itinerary generation failed. Please try again." }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const aiJson = await aiResponse.json();
    const rawText = aiJson.content?.[0]?.text ?? "{}";

    let parsed: { summary?: string; picks?: { experience_id: string; reason: string }[]; notes?: string };
    try {
      parsed = JSON.parse(rawText);
    } catch {
      console.error("Failed to parse model output as JSON", rawText);
      return new Response(
        JSON.stringify({ error: "AI returned an unexpected format. Please try again." }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Resolve picks against the real catalog rows so the client gets full
    // experience data (image, price, rating) to render, not just an id.
    const catalogById = new Map(catalog.map((c: any) => [c.id, c]));
    const resolvedPicks = (parsed.picks ?? [])
      .filter((p) => catalogById.has(p.experience_id))
      .map((p) => ({ ...catalogById.get(p.experience_id), reason: p.reason }));

    return new Response(
      JSON.stringify({
        summary: parsed.summary ?? "",
        notes: parsed.notes ?? null,
        picks: resolvedPicks,
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err: any) {
    console.error("generate-itinerary error", err);
    return new Response(
      JSON.stringify({ error: err.message ?? "Failed to generate itinerary" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
