// Pure logic pulled out of homepage.ts so it can be tested with plain
// `node --test`, no TS build step - same pattern as
// supabase/scripts/seed-legal.mjs / .test.mjs in this repo.

/**
 * "Render only families with >=1 published experience" - AUDIT.md (g).
 * Never returns an empty array: an empty result is `null` (rule 1 - no
 * placeholder), so the caller can omit the section outright.
 *
 * @param {{ id: string }[]} families
 * @param {{ id: string, family_id: string | null }[]} categories
 * @param {{ category_id: string | null }[]} publishedExperiences
 * @returns {(object & { publishedCount: number })[] | null}
 */
export function familiesWithPublishedCounts(families, categories, publishedExperiences) {
  const categoryIdToFamilyId = new Map(categories.map((c) => [c.id, c.family_id]));
  const publishedCountByFamily = new Map();
  for (const e of publishedExperiences) {
    const familyId = e.category_id ? categoryIdToFamilyId.get(e.category_id) : null;
    if (!familyId) continue;
    publishedCountByFamily.set(familyId, (publishedCountByFamily.get(familyId) ?? 0) + 1);
  }

  const withCounts = families
    .map((f) => ({ ...f, publishedCount: publishedCountByFamily.get(f.id) ?? 0 }))
    .filter((f) => f.publishedCount > 0);

  return withCounts.length > 0 ? withCounts : null;
}
