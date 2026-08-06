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
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
    const client = createClient(supabaseUrl, supabaseAnonKey);

    let body: any = {};
    if (req.method === "POST") {
      body = await req.json().catch(() => ({}));
    } else {
      const url = new URL(req.url);
      body = {
        query: url.searchParams.get("query") ?? url.searchParams.get("q") ?? url.searchParams.get("search_query"),
        category_id: url.searchParams.get("category_id") ?? url.searchParams.get("categoryId"),
        region_id: url.searchParams.get("region_id") ?? url.searchParams.get("regionId"),
        difficulty: url.searchParams.get("difficulty"),
        min_price: url.searchParams.get("min_price") ?? url.searchParams.get("min_price_paisa") ?? url.searchParams.get("minPricePaisa"),
        max_price: url.searchParams.get("max_price") ?? url.searchParams.get("max_price_paisa") ?? url.searchParams.get("maxPricePaisa"),
        sort_by: url.searchParams.get("sort_by") ?? url.searchParams.get("sortBy"),
        page: url.searchParams.get("page") ? parseInt(url.searchParams.get("page")!) : 1,
        limit: url.searchParams.get("limit") ? parseInt(url.searchParams.get("limit")!) : 20,
      };
    }

    const query = body.query ?? body.search_query ?? body.q ?? "";
    const category_id = body.category_id ?? body.categoryId;
    const region_id = body.region_id ?? body.regionId;
    const difficulty = body.difficulty;
    const min_price = body.min_price ?? body.min_price_paisa ?? body.minPricePaisa;
    const max_price = body.max_price ?? body.max_price_paisa ?? body.maxPricePaisa;
    const sort_by = body.sort_by ?? body.sortBy ?? "relevance";
    const page = body.page ?? 1;
    const limit = body.limit ?? 20;

    let dbQuery = client
      .from("experiences")
      .select("*", { count: "exact" })
      .eq("status", "published");

    if (category_id && String(category_id).trim() !== "") {
      dbQuery = dbQuery.eq("category_id", String(category_id).trim());
    }
    if (region_id && String(region_id).trim() !== "") {
      dbQuery = dbQuery.eq("region_id", String(region_id).trim());
    }
    if (difficulty && String(difficulty).trim() !== "" && difficulty !== "all") {
      dbQuery = dbQuery.eq("difficulty", String(difficulty).trim());
    }
    if (min_price !== undefined && min_price !== null && min_price !== "") {
      dbQuery = dbQuery.gte("price_paisa", Number(min_price));
    }
    if (max_price !== undefined && max_price !== null && max_price !== "") {
      dbQuery = dbQuery.lte("price_paisa", Number(max_price));
    }

    if (query && String(query).trim() !== "") {
      dbQuery = dbQuery.textSearch("search_tsv", String(query).trim(), {
        config: "english",
        type: "websearch",
      });
    }

    // Sorting
    switch (sort_by) {
      case "price_asc":
        dbQuery = dbQuery.order("price_paisa", { ascending: true });
        break;
      case "price_desc":
        dbQuery = dbQuery.order("price_paisa", { ascending: false });
        break;
      case "rating":
        dbQuery = dbQuery.order("rating_avg", { ascending: false });
        break;
      case "duration":
      case "duration_asc":
        dbQuery = dbQuery.order("duration_hours", { ascending: true });
        break;
      case "duration_desc":
        dbQuery = dbQuery.order("duration_hours", { ascending: false });
        break;
      case "popular":
        dbQuery = dbQuery.order("rating_count", { ascending: false });
        break;
      case "newest":
        dbQuery = dbQuery.order("created_at", { ascending: false });
        break;
      case "relevance":
      default:
        dbQuery = dbQuery.order("rating_avg", { ascending: false });
        break;
    }

    const fromIndex = (page - 1) * limit;
    const toIndex = fromIndex + limit - 1;
    dbQuery = dbQuery.range(fromIndex, toIndex);

    const { data, count, error } = await dbQuery;

    if (error) {
      throw error;
    }

    return new Response(
      JSON.stringify({
        experiences: data ?? [],
        total: count ?? 0,
        page,
        limit,
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      }
    );
  } catch (err: any) {
    return new Response(
      JSON.stringify({ error: err.message ?? "Search failed" }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 500,
      }
    );
  }
});
