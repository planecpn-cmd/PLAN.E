import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import {
  AuthenticationError,
  requireAuthenticatedUser,
} from "../_shared/auth.ts";
import { consumeRateLimits } from "../_shared/rate_limit.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const GEMINI_MODEL = "gemini-3.1-flash-lite";

function boundedText(value: unknown, maxLength: number): string | null {
  return typeof value === "string" ? value.slice(0, maxLength) : null;
}

function isOptionalText(value: unknown, maxLength: number): boolean {
  return value == null ||
    (typeof value === "string" && value.trim().length <= maxLength);
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
    title: boundedText(e.title, 160),
    summary: boundedText(e.summary, 400),
    difficulty: boundedText(e.difficulty, 40),
    duration_days: Math.ceil((e.duration_hours ?? 0) / 24),
    price_npr: Math.round((e.price_paisa ?? 0) / 100),
    region: boundedText(e.regions?.name_en, 100),
    category: boundedText(e.categories?.name_en, 100),
  }));
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  try {
    const { user, adminClient: supabaseClient } = await requireAuthenticatedUser(req);

    const body = await req.json().catch(() => null);
    if (!body || typeof body !== "object" || Array.isArray(body)) {
      return new Response(JSON.stringify({ error: "Invalid request body" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }
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
    if (
      !isOptionalText(prompt, 1500) ||
      !isOptionalText(trip_type, 80) ||
      !isOptionalText(pace, 40) ||
      !isOptionalText(interests, 500) ||
      !isOptionalText(group_type, 40) ||
      (duration_days != null &&
        (!Number.isInteger(duration_days) || duration_days < 1 || duration_days > 30)) ||
      (budget_npr != null &&
        (!Number.isSafeInteger(budget_npr) || budget_npr < 0 || budget_npr > 1_000_000_000)) ||
      (confirmed != null && typeof confirmed !== "boolean")
    ) {
      return new Response(JSON.stringify({ error: "Invalid itinerary preferences" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const tripType = typeof trip_type === "string" ? trip_type.trim() : "";
    const tripPace = typeof pace === "string" ? pace.trim() : "";
    const tripInterests = typeof interests === "string" ? interests.trim() : "";
    const groupType = typeof group_type === "string" ? group_type.trim() : "";
    const isConfirmed = confirmed === true;

    const freeText = typeof prompt === "string" ? prompt.trim() : "";
    if (!freeText && (!tripType || duration_days == null)) {
      return new Response(
        JSON.stringify({ error: "Missing required fields: trip_type, duration_days (or a free-text prompt)" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const { data: aiFlag, error: aiFlagError } = await supabaseClient
      .from("feature_flags")
      .select("enabled")
      .eq("key", "ai_itinerary")
      .maybeSingle();
    if (aiFlagError) {
      console.error("AI itinerary flag lookup failed", aiFlagError.message);
    }
    if (aiFlagError || aiFlag?.enabled !== true) {
      return new Response(
        JSON.stringify({ error: "AI itinerary planning is temporarily unavailable." }),
        { status: 503, headers: { ...corsHeaders, "Content-Type": "application/json" } },
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
- Trip type: ${tripType}
- Duration: ${duration_days} days
- Pace: ${tripPace || "not specified"}
- Budget: ${budget_npr != null ? `NPR ${budget_npr}` : "not specified"}
- Group: ${groupType || "not specified"}
- Interests: ${tripInterests || "not specified"}

Catalog (JSON array of available experiences):
${JSON.stringify(catalog)}`;

    const geminiKey = Deno.env.get("GEMINI_API_KEY");
    if (!geminiKey) {
      return new Response(
        JSON.stringify({ error: "AI itinerary generation is not configured yet." }),
        { status: 503, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const quotas = [
      { key: `itinerary:user:${user.id}:hour`, limit: 10, minutes: 60 },
      { key: `itinerary:user:${user.id}:day`, limit: 30, minutes: 1440 },
      { key: "itinerary:global:hour", limit: 100, minutes: 60 },
      { key: "itinerary:global:day", limit: 500, minutes: 1440 },
    ];
    const retryAfter = await consumeRateLimits(supabaseClient, quotas);
    if (retryAfter != null) {
      return new Response(
        JSON.stringify({ error: "AI planning limit reached. Try again later." }),
        {
          status: 429,
          headers: {
            ...corsHeaders,
            "Content-Type": "application/json",
            "Retry-After": String(retryAfter),
          },
        },
      );
    }

    const aiResponse = await fetch(
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
  } catch (err: unknown) {
    if (err instanceof AuthenticationError) {
      return new Response(JSON.stringify({ error: err.message }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }
    console.error(
      "generate-itinerary error",
      err instanceof Error ? err.message : "unknown error",
    );
    return new Response(
      JSON.stringify({ error: "Failed to generate itinerary" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
