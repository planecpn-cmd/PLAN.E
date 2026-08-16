import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const GEMINI_MODEL = "gemini-3.1-flash-lite";
const RATE_LIMIT_PER_HOUR = 15;

async function fetchWithRetry(url: string, init: RequestInit, attempts = 3): Promise<Response> {
  let lastResponse: Response | null = null;
  for (let i = 0; i < attempts; i++) {
    const res = await fetch(url, init);
    if (res.status !== 429 && res.status !== 503) return res;
    lastResponse = res;
    if (i < attempts - 1) await new Promise((r) => setTimeout(r, 1000 * (i + 1)));
  }
  return lastResponse!;
}

function parseModelJson(rawText: string): any {
  try {
    return JSON.parse(rawText);
  } catch {
    const match = rawText.match(/\{[\s\S]*\}/);
    if (match) return JSON.parse(match[0]);
    throw new Error("Unparseable model output");
  }
}

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
    const geminiKey = Deno.env.get("GEMINI_API_KEY");
    if (!geminiKey) {
      return new Response(
        JSON.stringify({ error: "AI itinerary generation is not configured yet." }),
        { status: 503, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseServiceKey =
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? Deno.env.get("SUPABASE_ANON_KEY") ?? "";
    const supabaseClient = createClient(supabaseUrl, supabaseServiceKey);

    // Auth gate, hoisted above every other check: this function spends money
    // on a third party per call, so an unauthenticated caller must never
    // reach the Gemini fetch. The anon key alone satisfies Supabase's
    // verify_jwt gateway check, so that check is not enough on its own.
    const authHeader = req.headers.get("Authorization");
    const token = authHeader?.replace("Bearer ", "");
    const {
      data: { user },
    } = token ? await supabaseClient.auth.getUser(token) : { data: { user: null } };
    if (!user) {
      return new Response(JSON.stringify({ error: "Authentication required." }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { data: allowed, error: rateLimitError } = await supabaseClient.rpc(
      "check_ai_rate_limit",
      { p_key: `itinerary:${user.id}`, p_limit: RATE_LIMIT_PER_HOUR, p_window_minutes: 60 }
    );
    if (rateLimitError) throw new Error(`Rate limit check failed: ${rateLimitError.message}`);
    if (!allowed) {
      return new Response(
        JSON.stringify({ error: "You've reached your planning limit for this hour. Try again later." }),
        { status: 429, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const body = await req.json().catch(() => ({}));
    const {
      trip_type,       // e.g. "trekking", "wildlife", "culture", "wellness"
      duration_days,    // e.g. 7
      pace,             // e.g. "relaxed", "moderate", "intense"
      budget_npr,       // e.g. 150000 — total budget, optional
      interests,        // free-text, e.g. "photography, local food, monasteries"
      group_type,       // e.g. "solo", "couple", "family", "friends"
      prompt,           // free-text mode: the whole string, replaces the fields above
      confirmed,        // true on the traveler's follow-up after accepting a suggested substitute
    } = body;
    const isConfirmed = confirmed === true;

    const freeText = typeof prompt === "string" ? prompt.trim() : "";
    if (!freeText && (!trip_type || !duration_days)) {
      return new Response(
        JSON.stringify({ error: "Missing required fields: trip_type, duration_days (or a free-text prompt)" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const catalog = await fetchCatalogSummary(supabaseClient);

    const systemPrompt = `You are a Nepal trip-planning assistant for the PLAN E app. Recommend a personalized DAY-BY-DAY itinerary built ONLY from the experiences in the provided catalog — never invent a trek, tour, or place that isn't listed. The traveler's request may be free-form text instead of structured fields — infer trip type, duration, budget, pace, and group as best you can from it; if duration isn't stated, pick a reasonable default and say so in "notes".

If the traveler names a SPECIFIC place, region, or trek that the catalog has NO reasonable match for, do NOT silently substitute a different region and build an itinerary anyway. Instead reply with the "clarify" shape below: briefly say what's missing, name the closest available alternative from the catalog, and ask if that works — then stop, do not generate picks yet.${isConfirmed ? " The traveler has ALREADY confirmed they're fine with a substitute — always use the \"direct\" shape now, do not ask again, go straight to the best available itinerary." : ""}

Once you do have a good enough catalog match (or the traveler already confirmed), sequence the picks across the trip's days, one "day" number per pick (starting at 1):
- Never reuse the same experience_id twice.
- Vary pacing — don't stack two intense multi-hour activities back to back; follow a demanding day (e.g. a long trek or paragliding) with something lighter, or leave the day open with no pick if nothing else fits well.
- It's fine for the picks list to have fewer entries than there are days — leaving a day unplanned (a free/rest day) is better than forcing a low-quality or repeated match.

Respond with ONLY valid JSON, no prose outside the JSON, in ONE of these two shapes:

Shape "clarify" — only when something specific was requested and the catalog has nothing reasonably close, AND the traveler hasn't already confirmed:
{ "confidence": "clarify", "clarifying_question": "one or two sentences: what's missing, the closest catalog alternative, and asking if that works" }

Shape "direct" — the normal case, and always once confirmed:
{
  "confidence": "direct",
  "summary": "one or two sentence overview of the recommended plan",
  "picks": [
    { "experience_id": "<id from catalog>", "day": 1, "reason": "one sentence on why this fits their preferences" }
  ],
  "notes": "optional caveats, e.g. budget doesn't fully cover the picks, or catalog gaps"
}`;

    const userPrompt = freeText
      ? `Traveler's request (free text): ${freeText}

Catalog (JSON array of available experiences):
${JSON.stringify(catalog)}`
      : `Traveler preferences:
- Trip type: ${trip_type}
- Duration: ${duration_days} days
- Pace: ${pace ?? "not specified"}
- Budget: ${budget_npr ? `NPR ${budget_npr}` : "not specified"}
- Group: ${group_type ?? "not specified"}
- Interests: ${interests ?? "not specified"}

Catalog (JSON array of available experiences):
${JSON.stringify(catalog)}`;

    const aiResponse = await fetchWithRetry(
      `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${geminiKey}`,
      {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({
          systemInstruction: { parts: [{ text: systemPrompt }] },
          contents: [{ role: "user", parts: [{ text: userPrompt }] }],
          generationConfig: {
            temperature: 0.2,
            maxOutputTokens: 1024,
            responseMimeType: "application/json",
            thinkingConfig: { thinkingBudget: 0 },
          },
        }),
      }
    );

    if (!aiResponse.ok) {
      const errText = await aiResponse.text();
      console.error("Gemini API error", aiResponse.status, errText);
      return new Response(
        JSON.stringify({ error: "AI itinerary generation failed. Please try again." }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const aiJson = await aiResponse.json();
    const rawText = aiJson.candidates?.[0]?.content?.parts?.[0]?.text ?? "{}";

    let parsed: {
      confidence?: string;
      clarifying_question?: string;
      summary?: string;
      picks?: { experience_id: string; day?: number; reason: string }[];
      notes?: string;
    };
    try {
      parsed = parseModelJson(rawText);
    } catch {
      console.error("Failed to parse model output as JSON", rawText);
      return new Response(
        JSON.stringify({ error: "AI returned an unexpected format. Please try again." }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // The model asked before substituting a region/trek the catalog doesn't
    // have — surface the question and stop, no picks generated yet.
    if (!isConfirmed && parsed.confidence === "clarify" && parsed.clarifying_question) {
      return new Response(
        JSON.stringify({ confidence: "clarify", clarifying_question: parsed.clarifying_question }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Resolve picks against the real catalog rows so the client gets full
    // experience data (image, price, rating) to render, not just an id.
    // The model is told not to repeat an experience across days, but its
    // output is never trusted as final — dedupe and sort here too.
    const catalogById = new Map(catalog.map((c: any) => [c.id, c]));
    const seenIds = new Set<string>();
    const resolvedPicks = (parsed.picks ?? [])
      .filter((p) => catalogById.has(p.experience_id) && !seenIds.has(p.experience_id) && seenIds.add(p.experience_id))
      .map((p) => ({
        ...catalogById.get(p.experience_id),
        day: Number.isInteger(p.day) && p.day! > 0 ? p.day : null,
        reason: p.reason,
      }))
      .sort((a, b) => (a.day ?? Infinity) - (b.day ?? Infinity));

    return new Response(
      JSON.stringify({
        confidence: "direct",
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
