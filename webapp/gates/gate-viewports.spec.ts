// G8: no horizontal overflow at 360 / 390 / 768 / 1280 on any IA route.
import { test, expect } from "@playwright/test";
import { iaRoutes } from "./lib";

const WIDTHS = [360, 390, 768, 1280];

test("gate-viewports: no horizontal overflow on IA routes", async ({ page }) => {
  const failures: string[] = [];
  const routes = await iaRoutes();
  for (const width of WIDTHS) {
    await page.setViewportSize({ width, height: 900 });
    for (const route of routes) {
      await page.goto(route, { waitUntil: "load" });
      const { scroll, client } = await page.evaluate(() => ({
        scroll: document.documentElement.scrollWidth,
        client: document.documentElement.clientWidth,
      }));
      if (scroll > client) failures.push(`${width}px ${route}: scrollWidth ${scroll} > ${client}`);
    }
  }
  expect(failures, failures.join("\n")).toEqual([]);
});
