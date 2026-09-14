import assert from "node:assert/strict";
import test from "node:test";
import { readFileSync, readdirSync } from "node:fs";
import { fileURLToPath } from "node:url";
import path from "node:path";

// Static, no DB/network needed: the scope vocabulary lives in three places
// that must agree --
//   1. admin/src/lib/scopes.ts        (ALL_SCOPES, the TypeScript source of truth)
//   2. the staff_members_scopes_known CHECK constraint's LATEST definition
//      (it is dropped and re-created by each migration that adds a scope --
//      the last one in filename order is what's actually live)
//   3. the founder bootstrap migration's v_all_scopes
// A scope added to one and not the others is exactly the class of bug that
// broke the founder bootstrap (v_all_scopes had 2 scopes the CHECK
// constraint didn't allow yet). This asserts the three sets are identical,
// not just that each one parses.

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..", "..");
const migrationsDir = path.join(repoRoot, "supabase", "migrations");

function quotedStringsBetween(text, startIndex) {
  const close = text.indexOf("]", startIndex);
  assert.notEqual(close, -1, "unterminated array literal");
  const slice = text.slice(startIndex, close);
  return [...slice.matchAll(/['"]([a-z]+:[a-z]+)['"]/g)].map((m) => m[1]);
}

test("scopes.ts, the live CHECK constraint, and the founder bootstrap agree on the scope set", () => {
  // 1. admin/src/lib/scopes.ts
  const scopesTs = readFileSync(path.join(repoRoot, "admin", "src", "lib", "scopes.ts"), "utf8");
  const tsAnchor = scopesTs.indexOf("ALL_SCOPES");
  assert.notEqual(tsAnchor, -1, "ALL_SCOPES not found in scopes.ts");
  const tsScopes = quotedStringsBetween(scopesTs, tsAnchor);
  assert.ok(tsScopes.length > 0, "parsed zero scopes out of scopes.ts");

  // 2. the latest staff_members_scopes_known CHECK constraint definition
  const migrationFiles = readdirSync(migrationsDir).filter((f) => f.endsWith(".sql")).sort();
  let latestConstraintFile = null;
  let latestConstraintScopes = null;
  for (const file of migrationFiles) {
    const text = readFileSync(path.join(migrationsDir, file), "utf8");
    const addAnchor = text.indexOf("add constraint staff_members_scopes_known");
    if (addAnchor === -1) continue;
    const arrayAnchor = text.indexOf("array[", addAnchor);
    if (arrayAnchor === -1) continue;
    latestConstraintFile = file;
    latestConstraintScopes = quotedStringsBetween(text, arrayAnchor);
  }
  assert.notEqual(latestConstraintFile, null, "no migration defines staff_members_scopes_known");
  assert.ok(latestConstraintScopes.length > 0, `parsed zero scopes out of ${latestConstraintFile}`);

  // 3. the founder bootstrap's v_all_scopes (found by content, not a fixed
  // filename -- it has already been renumbered once to fix an ordering bug)
  let bootstrapFile = null;
  let bootstrapScopes = null;
  for (const file of migrationFiles) {
    const text = readFileSync(path.join(migrationsDir, file), "utf8");
    const anchor = text.indexOf("v_all_scopes");
    if (anchor === -1) continue;
    const arrayAnchor = text.indexOf("array[", anchor);
    if (arrayAnchor === -1) continue;
    bootstrapFile = file;
    bootstrapScopes = quotedStringsBetween(text, arrayAnchor);
    break;
  }
  assert.notEqual(bootstrapFile, null, "no migration defines v_all_scopes (founder bootstrap missing?)");
  assert.ok(bootstrapScopes.length > 0, `parsed zero scopes out of ${bootstrapFile}`);

  const tsSet = new Set(tsScopes);
  const constraintSet = new Set(latestConstraintScopes);
  const bootstrapSet = new Set(bootstrapScopes);

  const describe = (name, set) => `${name}: [${[...set].sort().join(", ")}]`;

  assert.deepEqual(
    [...tsSet].sort(),
    [...constraintSet].sort(),
    `scopes.ts and the CHECK constraint (${latestConstraintFile}) disagree.\n` +
      `${describe("scopes.ts", tsSet)}\n${describe(latestConstraintFile, constraintSet)}`,
  );
  assert.deepEqual(
    [...tsSet].sort(),
    [...bootstrapSet].sort(),
    `scopes.ts and the founder bootstrap (${bootstrapFile}) disagree.\n` +
      `${describe("scopes.ts", tsSet)}\n${describe(bootstrapFile, bootstrapSet)}`,
  );
});
