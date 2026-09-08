import { describe, expect, it } from "vitest";
import { readdirSync, readFileSync, statSync } from "node:fs";
import { join, relative } from "node:path";

// Load-bearing enforcement of "only one module imports the service-role client".
// This is a TEST, not an eslint rule, on purpose: an eslint rule is one
// `// eslint-disable-next-line` away from being defeated in the same PR that
// adds the bad import. If this fails, CI fails, and no inline comment helps.

const SRC = join(__dirname, "..");                 // admin/src
const ALLOWED = new Set([
  "lib/with-admin.server.ts",                      // the one legitimate consumer
  "lib/service-role.ts",                           // defines it
]);

// matches:  from "...service-role"  |  import("...service-role")  |  require("...service-role")
// with the path ending at service-role(.ts) optionally preceded by ./ ../ @/lib/ etc.
const SERVICE_ROLE_IMPORT =
  /(?:from|import|require)\s*\(?\s*["'][^"']*service-role(?:\.ts)?["']/;

function walk(dir: string): string[] {
  const out: string[] = [];
  for (const name of readdirSync(dir)) {
    const p = join(dir, name);
    if (statSync(p).isDirectory()) {
      out.push(...walk(p));
    } else if (/\.(ts|tsx|js|jsx|mjs)$/.test(name)) {
      out.push(p);
    }
  }
  return out;
}

describe("service-role client import boundary", () => {
  it("is imported by nothing outside the allow-list", () => {
    const offenders: string[] = [];
    for (const file of walk(SRC)) {
      const rel = relative(SRC, file).replaceAll("\\", "/");
      if (ALLOWED.has(rel)) continue;
      if (rel.endsWith(".test.ts") || rel.endsWith(".test.tsx")) continue;
      if (rel === "test/server-only-stub.ts") continue;

      const src = readFileSync(file, "utf8");
      for (const line of src.split("\n")) {
        if (SERVICE_ROLE_IMPORT.test(line)) {
          offenders.push(`${rel}: ${line.trim()}`);
        }
      }
    }
    expect(offenders, `service-role is reachable only via with-admin.server.ts:\n${offenders.join("\n")}`).toEqual([]);
  });

  it("the allow-list files still exist (guards against a rename silently disabling this test)", () => {
    for (const rel of ALLOWED) {
      expect(() => statSync(join(SRC, rel)), `${rel} missing`).not.toThrow();
    }
  });
});
