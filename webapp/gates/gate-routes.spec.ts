// G2: every IA seed route returns 200 with non-empty main content, AND every
// internal link rendered on those pages does too (one hop, from each seed).
//
// A fixed seed list alone missed three live 404s for a week - /notifications,
// /ai-planner, and /profile/help were each linked from a real page's rendered
// HTML, but none was ever a seed, so nothing ever asked for them. Crawling
// outward from the seeds is what catches a dead link anywhere those pages
// actually point, not just at the handful of URLs this file happens to name.
//
// Anonymous only, same as the rest of this gate suite (see lib.ts): a link
// that only ever renders inside a logged-in view (e.g. the profile page's
// settings menu, or /host/dashboard, which needs an approved host) is not in
// the anonymous DOM at all, so this crawl cannot reach it. That is a real,
// separate gap - flagged in BLOCKED.md / the node report, not silently
// covered up by pretending an anonymous crawl can see a session-gated link.
import { test, expect, type Page } from "@playwright/test";
import { iaRoutes, settle } from "./lib";

async function checkPage(page: Page, route: string): Promise<{ ok: boolean; reason?: string }> {
  const res = await settle(page, route);
  const status = res?.status() ?? 0;
  // Pages without a <main> landmark (auth) fall back to <body>.
  const region = (await page.locator("main").count()) > 0 ? page.locator("main").first() : page.locator("body");
  const text = (await region.innerText()).trim();
  if (status !== 200) return { ok: false, reason: `HTTP ${status}` };
  if (text.length < 20) return { ok: false, reason: `main content empty (${text.length} chars)` };
  if (/could not be found/i.test(text)) return { ok: false, reason: "renders not-found" };
  return { ok: true };
}

const SKIP_EXTENSIONS = /\.(png|jpe?g|webp|gif|svg|ico|css|js|xml|txt|pdf)$/i;

/** Every same-origin href in the current rendered DOM, as a bare path. */
async function discoverHrefs(page: Page): Promise<string[]> {
  const rawHrefs = await page.$$eval("a[href]", (as) => as.map((a) => a.getAttribute("href") ?? ""));
  const origin = new URL(page.url()).origin;
  const paths = new Set<string>();
  for (const href of rawHrefs) {
    if (!href || href.startsWith("#") || href.startsWith("mailto:") || href.startsWith("tel:")) continue;
    let url: URL;
    try {
      url = new URL(href, origin);
    } catch {
      continue;
    }
    if (url.origin !== origin) continue;
    // A distinct page, not a distinct route - query/hash variants of the
    // same path are not checked separately (e.g. every /search?region=...).
    if (SKIP_EXTENSIONS.test(url.pathname)) continue;
    paths.add(url.pathname);
  }
  return [...paths];
}

test("gate-routes: every IA route, and every link on it, returns 200 with non-empty main content", async ({ page }) => {
  const failures: string[] = [];
  const checked = new Set<string>();
  const linkedFrom = new Map<string, Set<string>>();

  for (const seed of await iaRoutes()) {
    const result = await checkPage(page, seed);
    checked.add(seed);
    if (!result.ok) failures.push(`${seed}: ${result.reason}`);

    for (const target of await discoverHrefs(page)) {
      if (!linkedFrom.has(target)) linkedFrom.set(target, new Set());
      linkedFrom.get(target)!.add(seed);
    }
  }

  for (const [target, sources] of linkedFrom) {
    if (checked.has(target)) continue;
    const result = await checkPage(page, target);
    checked.add(target);
    if (!result.ok) failures.push(`${target}: ${result.reason} (linked from ${[...sources].join(", ")})`);
  }

  expect(failures, failures.join("\n")).toEqual([]);
});
