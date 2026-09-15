#!/usr/bin/env node
// Run after `opennextjs-cloudflare build`, before deploy, in `npm run deploy`.
// Catches exactly the bug this guards against: NEXT_PUBLIC_SUPABASE_URL/ANON_KEY
// inlined from admin/.env.local's local-dev defaults instead of the hosted
// project, which shipped a Worker whose browser client pointed at
// 127.0.0.1:54341 with the well-known local demo anon key -- a page that
// still rendered fine, because the login form doesn't care which backend
// it's wired to until you actually use it.
//
// Absence of local strings is not proof of correct config (a build could
// fail before inlining anything and still "pass" that check), so this also
// asserts the real hosted project ref is positively present.

import { readdirSync, readFileSync, statSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const adminRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");

// Scan ONLY what `wrangler deploy` actually uploads (wrangler.jsonc's `main`
// and `assets.directory`) -- .open-next also contains build intermediates
// (next-env.mjs for local preview, raw pre-bundle server-functions/, etc.)
// that never reach production and would otherwise be scanned for nothing.
const wranglerText = readFileSync(path.join(adminRoot, "wrangler.jsonc"), "utf8");
const mainMatch = wranglerText.match(/"main"\s*:\s*"([^"]+)"/);
const assetsDirMatch = wranglerText.match(/"directory"\s*:\s*"([^"]+)"/);
if (!mainMatch || !assetsDirMatch) {
  console.error('check-deploy-bundle: could not find "main" and/or assets "directory" in wrangler.jsonc.');
  process.exit(1);
}
const deployedPaths = [path.join(adminRoot, mainMatch[1]), path.join(adminRoot, assetsDirMatch[1])];

// "127.0.0.1" and "localhost" alone are NOT safe needles: @supabase/supabase-js
// ships its own hardcoded trusted-host allowlist (*.supabase.co, *.supabase.in,
// localhost, 127.0.0.1, [::1]) inside every build regardless of project config
// -- confirmed by testing this exact check against a known-correct, already
// hosted-verified build, which failed on that string alone. The fused local
// API address and the demo key are specific to actual misconfiguration.
const forbidden = [
  { needle: "127.0.0.1:54341", label: "local Supabase API address" },
  { needle: ":54341", label: "local Supabase API port" },
  {
    needle: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1v",
    label: "well-known local demo anon/service key",
  },
];

const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
if (!url) {
  console.error("check-deploy-bundle: NEXT_PUBLIC_SUPABASE_URL is not set -- run require-prod-env first.");
  process.exit(1);
}
const projectRefMatch = url.match(/^https:\/\/([a-z0-9]+)\.supabase\.co\/?$/);
if (!projectRefMatch) {
  console.error(`check-deploy-bundle: NEXT_PUBLIC_SUPABASE_URL "${url}" doesn't look like a hosted Supabase URL.`);
  process.exit(1);
}
const projectRef = projectRefMatch[1];

function* walk(entryPath) {
  const stat = statSync(entryPath);
  if (stat.isFile()) {
    yield entryPath;
    return;
  }
  for (const entry of readdirSync(entryPath)) yield* walk(path.join(entryPath, entry));
}

const violations = [];
let refFound = false;

for (const root of deployedPaths) {
  for (const file of walk(root)) {
    // Binary/asset noise this doesn't need to scan; keep it to text-ish build output.
    if (!/\.(js|mjs|cjs|json|html|txt)$/.test(file)) continue;
    const text = readFileSync(file, "utf8");
    const relPath = path.relative(adminRoot, file);

    for (const { needle, label } of forbidden) {
      if (text.includes(needle)) violations.push(`${relPath}: contains ${label} ("${needle}")`);
    }
    if (text.includes(projectRef)) refFound = true;
  }
}

if (violations.length > 0) {
  console.error("check-deploy-bundle: the built bundle contains local-stack values. Refusing to deploy.\n");
  console.error(violations.slice(0, 20).join("\n"));
  if (violations.length > 20) console.error(`... and ${violations.length - 20} more`);
  process.exit(1);
}

if (!refFound) {
  console.error(
    `check-deploy-bundle: the hosted project ref "${projectRef}" was not found anywhere in the built ` +
      "bundle. Absence of local strings isn't proof the build picked up the right config -- refusing to deploy.",
  );
  process.exit(1);
}

console.log(`check-deploy-bundle: clean. No local-stack values found; hosted ref "${projectRef}" confirmed present.`);
