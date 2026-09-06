// Seed / re-seed the 13 legal documents into public.legal_documents as
// version 1.0, locale 'en', is_current = true.
//
//   SUPABASE_URL=... SUPABASE_SERVICE_ROLE_KEY=... node supabase/scripts/seed-legal.mjs [--dry]
//
// Idempotent: safe to run repeatedly. For each seeded slug it clears any other
// current version, then upserts the 1.0 row.
//
// PARTIAL SEED (per project decision): a document is seeded only when every
// [PLACEHOLDER] it contains has a non-empty value in legal/placeholders.json.
// Any document with an unresolved placeholder is skipped with a warning and
// listed at the end. Nothing invented here - fill placeholders.json.

import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
// @supabase/supabase-js is imported dynamically inside main() so the pure
// parsing helpers (and their test) run without the dependency installed.

const here = dirname(fileURLToPath(import.meta.url));
const legalDir = join(here, '..', 'legal');
const DRY = process.argv.includes('--dry');
const IS_MAIN = process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1];

// filename stem -> { slug, requiresAcceptance }
const DOCS = [
  ['01-terms-of-service',       'terms-of-service',        true],
  ['02-privacy-policy',         'privacy-policy',          true],
  ['03-booking-terms',          'booking-terms',           true],
  ['04-cancellation-policy',    'cancellation-policy',     true],
  ['05-refund-policy',          'refund-policy',           false],
  ['06-payment-policy',         'payment-policy',          false],
  ['07-grievance-policy',       'grievance-policy',        false],
  ['08-account-deletion-policy','account-deletion-policy', false],
  ['09-community-guidelines',   'community-guidelines',    true],
  ['10-safety-and-risk-policy', 'safety-and-risk-policy',  false],
  ['11-assumption-of-risk',     'risk-acknowledgment',     true],
  ['12-emergency-policy',       'emergency-policy',        false],
  ['13-cookie-policy',          'cookie-policy',           false],
];

const VERSION = '1.0';
const LOCALE = 'en';

// A leftover template slot: '[' + uppercase letter + anything-but-']'. Matches
// [EFFECTIVE DATE], [X], [PAYOUT TIMING - CONFIRM: e.g. ...]. Does NOT match the
// '[ ]' / '[x]' markdown checkboxes used in the emergency + risk-ack docs.
export const UNRESOLVED = /\[[A-Z][^\]\n]*\]/;

function loadPlaceholders() {
  const raw = JSON.parse(readFileSync(join(legalDir, 'placeholders.json'), 'utf8'));
  const map = {};
  for (const [k, v] of Object.entries(raw)) {
    if (k.startsWith('_')) continue;
    if (typeof v === 'string' && v.trim() !== '') map[k] = v;
  }
  return map;
}

export function applyPlaceholders(text, map) {
  let out = text;
  for (const [k, v] of Object.entries(map)) {
    out = out.split(`[${k}]`).join(v);
  }
  return out;
}

// Drop the frontmatter: the '# Title' line, the '**Plan E** ... Effective ...'
// block that follows it (up to the next blank line), and a leading '---' rule.
// Returns { title, body }.
export function splitFrontmatter(text) {
  const lines = text.replace(/\r\n/g, '\n').split('\n');
  let i = 0;
  while (i < lines.length && lines[i].trim() === '') i++;

  let title = '';
  if (lines[i]?.startsWith('# ')) {
    title = lines[i].slice(2).trim();
    i++;
  }
  while (i < lines.length && lines[i].trim() === '') i++;

  if (lines[i]?.startsWith('**Plan E**')) {
    while (i < lines.length && lines[i].trim() !== '') i++; // eat the block
  }
  while (i < lines.length && lines[i].trim() === '') i++;
  if (lines[i]?.trim() === '---') {
    i++;
    while (i < lines.length && lines[i].trim() === '') i++;
  }
  return { title, body: lines.slice(i).join('\n').trim() + '\n' };
}

async function main() {
  const placeholders = loadPlaceholders();
  const effectiveRaw = placeholders['EFFECTIVE DATE'];
  const effectiveAt = effectiveRaw ? new Date(effectiveRaw) : null;
  const effectiveOk = effectiveAt && !Number.isNaN(effectiveAt.getTime());

  const toSeed = [];
  const skipped = [];

  for (const [stem, slug, requiresAcceptance] of DOCS) {
    const rawFile = readFileSync(join(legalDir, `${stem}.md`), 'utf8');
    const filled = applyPlaceholders(rawFile, placeholders);
    const { title, body } = splitFrontmatter(filled);

    const leftover = filled.match(UNRESOLVED);
    if (leftover || !effectiveOk) {
      skipped.push({
        slug,
        reason: leftover ? `unresolved ${leftover[0]}` : 'EFFECTIVE DATE missing/invalid',
      });
      continue;
    }
    toSeed.push({
      slug,
      version: VERSION,
      locale: LOCALE,
      title,
      body_md: body,
      effective_at: effectiveAt.toISOString(),
      requires_acceptance: requiresAcceptance,
      is_current: true,
    });
  }

  console.log(`\nseed-legal: ${toSeed.length} to seed, ${skipped.length} skipped${DRY ? ' (dry run)' : ''}`);
  for (const s of skipped) console.warn(`  skip  ${s.slug.padEnd(24)} ${s.reason}`);
  for (const d of toSeed) console.log(`  seed  ${d.slug.padEnd(24)} "${d.title}"`);

  if (DRY || toSeed.length === 0) return;

  const url = process.env.SUPABASE_URL;
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!url || !key) {
    console.error('\nSUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are required to write.');
    process.exit(1);
  }
  const { createClient } = await import('@supabase/supabase-js');
  const db = createClient(url, key, { auth: { persistSession: false } });

  for (const d of toSeed) {
    // Clear any other current version of this slug so the one-current partial
    // unique index does not trip on the upsert below.
    const cleared = await db
      .from('legal_documents')
      .update({ is_current: false })
      .eq('slug', d.slug)
      .eq('locale', d.locale)
      .neq('version', d.version)
      .eq('is_current', true);
    if (cleared.error) throw cleared.error;

    const up = await db
      .from('legal_documents')
      .upsert(d, { onConflict: 'slug,version,locale' });
    if (up.error) throw up.error;
    console.log(`  wrote ${d.slug}`);
  }
  console.log('\ndone.');
}

if (IS_MAIN) {
  main().catch((e) => {
    console.error(e);
    process.exit(1);
  });
}
