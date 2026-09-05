import type { MetadataRoute } from "next";
import { createClient } from "@/lib/supabase/server";
import { LEGAL_DOC_ORDER } from "@/lib/legal";

const BASE_URL = "https://planenepal.com";

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const supabase = await createClient();
  const [{ data: experiences }, { data: categories }] = await Promise.all([
    supabase.from("experiences").select("slug, updated_at").eq("status", "published"),
    supabase.from("categories").select("slug"),
  ]);

  const staticRoutes: MetadataRoute.Sitemap = [
    { url: `${BASE_URL}/`, changeFrequency: "daily", priority: 1 },
    { url: `${BASE_URL}/explore`, changeFrequency: "daily", priority: 0.9 },
    { url: `${BASE_URL}/search`, changeFrequency: "daily", priority: 0.7 },
    { url: `${BASE_URL}/map`, changeFrequency: "weekly", priority: 0.5 },
    { url: `${BASE_URL}/legal`, changeFrequency: "monthly", priority: 0.4 },
    ...LEGAL_DOC_ORDER.map((slug) => ({
      url: `${BASE_URL}/legal/${slug}`,
      changeFrequency: "yearly" as const,
      priority: 0.3,
    })),
  ];

  const experienceRoutes: MetadataRoute.Sitemap = (experiences ?? []).map((e) => ({
    url: `${BASE_URL}/experience/${e.slug}`,
    lastModified: e.updated_at ?? undefined,
    changeFrequency: "weekly",
    priority: 0.8,
  }));

  const collectionRoutes: MetadataRoute.Sitemap = [
    "recommended",
    "trending",
    "homestays",
    ...(categories ?? []).map((c) => c.slug),
  ].map((slug) => ({
    url: `${BASE_URL}/collection/${slug}`,
    changeFrequency: "weekly",
    priority: 0.6,
  }));

  return [...staticRoutes, ...experienceRoutes, ...collectionRoutes];
}
