import { describe, expect, test } from "vitest";
import { readFileSync } from "node:fs";
import path from "node:path";

// Scope enforcement itself (401/403/200 for a given required scope) is
// already covered generically by with-admin.test.ts for ANY route using
// withAdmin -- these 4 routes get that for free. What's specific to the
// dashboard and worth its own check: that DashboardClient.tsx's per-section
// scope gate (which decides whether the browser even REQUESTS a domain's
// endpoint) actually matches the scope each route file requires server-side.
// A single-scope moderator "sees only their portion" only holds if these two
// stay in sync -- this fails loudly if either drifts without the other.
const adminSrc = path.resolve(__dirname, "..", "..", "..");

const ROUTES: Record<string, string> = {
  "/api/dashboard/users": "app/api/dashboard/users/route.ts",
  "/api/dashboard/hosts": "app/api/dashboard/hosts/route.ts",
  "/api/dashboard/experiences": "app/api/dashboard/experiences/route.ts",
  "/api/dashboard/bookings": "app/api/dashboard/bookings/route.ts",
};

function scopeRequiredByRoute(relPath: string): string {
  const text = readFileSync(path.join(adminSrc, relPath), "utf8");
  const m = text.match(/withAdmin\(\s*"([a-z]+:[a-z]+)"/);
  if (!m) throw new Error(`could not find withAdmin(...) scope in ${relPath}`);
  return m[1];
}

function scopeGatesInDashboardClient(): Record<string, string> {
  const text = readFileSync(path.join(adminSrc, "components", "DashboardClient.tsx"), "utf8");
  // const hasX = scopes.includes("scope:name");
  const flags = new Map<string, string>();
  for (const m of text.matchAll(/const (has\w+) = scopes\.includes\("([a-z]+:[a-z]+)"\)/g)) {
    flags.set(m[1], m[2]);
  }
  const gates: Record<string, string> = {};
  for (const [endpoint, flagName] of [
    ["/api/dashboard/users", "hasUsers"],
    ["/api/dashboard/hosts", "hasHosts"],
    ["/api/dashboard/experiences", "hasExperiences"],
    ["/api/dashboard/bookings", "hasBookings"],
  ] as const) {
    const scope = flags.get(flagName);
    if (!scope) throw new Error(`DashboardClient.tsx: could not find scope for ${flagName}`);
    gates[endpoint] = scope;
  }
  return gates;
}

describe("dashboard scope gating stays in sync between client and server", () => {
  const clientGates = scopeGatesInDashboardClient();

  for (const [endpoint, routeFile] of Object.entries(ROUTES)) {
    test(`${endpoint}: DashboardClient only fetches this when the route's own required scope is present`, () => {
      expect(clientGates[endpoint]).toBe(scopeRequiredByRoute(routeFile));
    });
  }

  test("every dashboard route requires a distinct scope (a single-scope moderator's fetches are non-overlapping)", () => {
    const scopes = Object.values(clientGates);
    expect(new Set(scopes).size).toBe(scopes.length);
  });
});
