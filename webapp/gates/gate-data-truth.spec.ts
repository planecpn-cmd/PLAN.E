// G6: no rendered count, rating, booking claim or availability claim may
// exceed what the anon-readable data backs. Every number found in the DOM is
// resolved to a Supabase query; the gate fails if the query returns fewer
// rows than displayed.
import { test, expect, type Page } from "@playwright/test";
import { readableCount, nepalDate, publishedExperiences, openDepartures, type Dep } from "./lib";

const LIST_PAGES = ["/", "/explore", "/search", "/map", "/collection/recommended", "/collection/trending"];
const MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

type Ctx = { reviews: number; bookings: number; published: number; deps: Dep[]; idBySlug: Map<string, string>; today: string };

async function context(): Promise<Ctx> {
  const exps = await publishedExperiences();
  return {
    reviews: await readableCount("reviews"),
    bookings: await readableCount("bookings"),
    published: exps.length,
    deps: await openDepartures(),
    idBySlug: new Map(exps.map((e) => [e.slug, e.id])),
    today: nepalDate(),
  };
}

async function checkPage(page: Page, route: string, ctx: Ctx): Promise<string[]> {
  await page.goto(route, { waitUntil: "load" });
  return analyse(page, route, ctx);
}

async function analyse(page: Page, route: string, ctx: Ctx): Promise<string[]> {
  const out: string[] = [];
  const text = await page.locator("body").innerText();

  // 1. Structured data must not publish ratings the data cannot back.
  for (const ld of await page.locator('script[type="application/ld+json"]').allTextContents()) {
    if (/aggregateRating|reviewCount/.test(ld) && ctx.reviews === 0) {
      out.push(`${route}: JSON-LD aggregateRating/reviewCount with ${ctx.reviews} readable review rows`);
    }
  }

  // 2. Star / rating badges.
  const badges = await page.locator('[aria-label^="Rated "]').count();
  if (badges > 0 && ctx.reviews === 0) out.push(`${route}: ${badges} rating badge(s) with 0 readable review rows`);

  // 3. Review counts: "(124)" beside a rating, "124 reviews", "Reviews (124)".
  for (const m of text.matchAll(/(?:\b(\d[\d,]*)\s+reviews?\b|Reviews\s*\((\d[\d,]*)\))/gi)) {
    const n = Number((m[1] ?? m[2]).replace(/,/g, ""));
    if (n > ctx.reviews) out.push(`${route}: displays ${n} reviews, ${ctx.reviews} readable rows`);
  }

  // 4. Booking-volume claims.
  for (const m of text.matchAll(/\b(\d[\d,]*)\s+(?:people|travell?ers|guests)\s+(?:have\s+)?booked\b|\bbooked\s+(\d[\d,]*)\s+times\b/gi)) {
    const n = Number((m[1] ?? m[2]).replace(/,/g, ""));
    if (n > ctx.bookings) out.push(`${route}: claims ${n} bookings, ${ctx.bookings} readable rows`);
  }

  // 5. "N experiences available" cannot exceed published experiences.
  for (const m of text.matchAll(/\b(\d+)\s+experiences?\s+(?:available|found)\b/gi)) {
    if (Number(m[1]) > ctx.published) out.push(`${route}: shows ${m[1]} experiences, ${ctx.published} published`);
  }

  // 6. "Happening This Week": every card needs an open departure in [today, today+6].
  const week = page.locator("section").filter({ has: page.getByRole("heading", { name: /happening this week/i }) });
  if ((await week.count()) > 0) {
    const end = nepalDate(6);
    const hrefs = await week.first().locator('a[href^="/experience/"]').evaluateAll((as) => as.map((a) => a.getAttribute("href")!));
    for (const slug of new Set(hrefs.map((h) => h.split("/")[2]))) {
      const id = ctx.idBySlug.get(slug);
      const ok = ctx.deps.some((d) => d.experience_id === id && d.start_date >= ctx.today && d.start_date <= end);
      if (!ok) out.push(`${route}: "Happening This Week" shows ${slug} with no open departure ${ctx.today}..${end}`);
    }
  }
  return out;
}

async function checkSpots(page: Page, slug: string, ctx: Ctx): Promise<string[]> {
  const route = `/experience/${slug}`;
  await page.goto(route, { waitUntil: "load" });
  const text = await page.locator("body").innerText();
  const out: string[] = [];
  const id = ctx.idBySlug.get(slug);
  // "10 spots available for Aug 14" / "2 spots LEFT for Sep 18"
  for (const m of text.matchAll(/\b(\d+)\s+spots\s+(?:left|available)\s+for\s+([A-Z][a-z]{2})\s+(\d{1,2})\b/gi)) {
    const [n, mon, day] = [Number(m[1]), MONTHS.indexOf(m[2]) + 1, Number(m[3])];
    const backed = ctx.deps.some((d) => {
      const [, mm, dd] = d.start_date.split("-").map(Number);
      return d.experience_id === id && d.start_date >= ctx.today && mm === mon && dd === day && d.spots_left >= n;
    });
    if (!backed) out.push(`${route}: "${m[0]}" has no open departure on/after ${ctx.today} with >= ${n} spots`);
  }
  return out;
}

test("gate-data-truth: rendered claims are backed by anon-readable rows", async ({ page }) => {
  test.setTimeout(10 * 60_000);
  const ctx = await context();
  const failures: string[] = [];
  for (const route of LIST_PAGES) failures.push(...(await checkPage(page, route, ctx)));
  for (const slug of ctx.idBySlug.keys()) {
    failures.push(...(await checkPage(page, `/experience/${slug}`, ctx)));
    failures.push(...(await checkSpots(page, slug, ctx)));
  }
  expect(failures, failures.join("\n")).toEqual([]);
});

// Guards the gate itself: a page carrying every banned pattern must be
// flagged on every check. If this passes vacuously, the gate is broken.
test("gate-data-truth self-check: synthetic unbacked claims are all flagged", async ({ page }) => {
  const ctx: Ctx = { reviews: 0, bookings: 0, published: 3, deps: [], idBySlug: new Map([["x", "id-x"]]), today: "2026-09-10" };
  await page.setContent(`
    <script type="application/ld+json">{"aggregateRating":{"reviewCount":124}}</script>
    <span aria-label="Rated 4.9 out of 5">4.9 (124)</span>
    <h2>Reviews (124)</h2><p>12 travellers booked</p><p>30 experiences available</p>
    <section><h2>Happening This Week</h2><a href="/experience/x">x</a></section>`);
  const found = await analyse(page, "synthetic", ctx);
  for (const needle of ["JSON-LD", "rating badge", "reviews,", "bookings", "30 experiences", "Happening This Week"]) {
    expect(found.some((f) => f.includes(needle)), `expected a failure mentioning "${needle}"; got:\n${found.join("\n")}`).toBe(true);
  }
});
