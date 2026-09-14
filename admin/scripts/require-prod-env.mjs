#!/usr/bin/env node
// Run before `opennextjs-cloudflare build` in `npm run deploy`. NEXT_PUBLIC_*
// values are inlined into the client bundle at build time -- a wrangler
// secret or wrangler.jsonc var set afterwards has no effect on already-built
// JS. admin/.env.local (git-ignored, local-dev defaults) is loaded by
// Next.js unconditionally and would otherwise win silently. Refusing to
// build without these explicitly set in the environment is what stops that.

const required = ["NEXT_PUBLIC_SUPABASE_URL", "NEXT_PUBLIC_SUPABASE_ANON_KEY"];
const missing = required.filter((name) => !process.env[name]);

if (missing.length > 0) {
  console.error(
    `Refusing to build for deploy: ${missing.join(", ")} not set in the environment.\n` +
      "NEXT_PUBLIC_* is inlined into the client bundle at build time -- .env.local's " +
      "local-dev values would otherwise win silently. Export the production values " +
      "before running `npm run deploy`, e.g.:\n" +
      "  export NEXT_PUBLIC_SUPABASE_URL=https://dtebgbrqynxahuzmbtbc.supabase.co\n" +
      "  export NEXT_PUBLIC_SUPABASE_ANON_KEY=<hosted anon key>",
  );
  process.exit(1);
}

console.log("require-prod-env: NEXT_PUBLIC_SUPABASE_URL and NEXT_PUBLIC_SUPABASE_ANON_KEY are set.");
