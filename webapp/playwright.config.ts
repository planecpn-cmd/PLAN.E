import { defineConfig, devices } from "@playwright/test";

// Gates run against a production build (`npm run build` first). Set
// GATE_BASE_URL to point at an already-running server instead.
const baseURL = process.env.GATE_BASE_URL ?? "http://localhost:3000";

export default defineConfig({
  testDir: "./gates",
  timeout: 5 * 60_000,
  retries: 0,
  workers: 1,
  reporter: process.env.CI ? [["list"], ["github"]] : "list",
  use: { baseURL, ...devices["Desktop Chrome"] },
  webServer: process.env.GATE_BASE_URL
    ? undefined
    : { command: "npm run start", url: baseURL, reuseExistingServer: !process.env.CI, timeout: 120_000 },
});
