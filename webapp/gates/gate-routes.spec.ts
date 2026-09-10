// G2: every route in the IA returns 200 and renders non-empty main content.
import { test, expect } from "@playwright/test";
import { iaRoutes } from "./lib";

test("gate-routes: every IA route returns 200 with non-empty main content", async ({ page }) => {
  const failures: string[] = [];
  for (const route of await iaRoutes()) {
    const res = await page.goto(route, { waitUntil: "domcontentloaded" });
    const status = res?.status() ?? 0;
    // Pages without a <main> landmark (auth) fall back to <body>.
    const region = (await page.locator("main").count()) > 0 ? page.locator("main").first() : page.locator("body");
    const text = (await region.innerText()).trim();
    if (status !== 200) failures.push(`${route}: HTTP ${status}`);
    else if (text.length < 20) failures.push(`${route}: main content empty (${text.length} chars)`);
    else if (/could not be found/i.test(text)) failures.push(`${route}: renders not-found`);
  }
  expect(failures, failures.join("\n")).toEqual([]);
});
