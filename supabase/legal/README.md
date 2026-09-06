# PLAN E legal documents — delivery pipeline

One mechanism, two clients. Legal text lives **only** in `public.legal_documents`
(Supabase). The Flutter app and the Next.js web app both read the same rows.
Nothing is hardcoded in either client.

## Files

| Path | What |
|---|---|
| `supabase/legal/NN-*.md` | Canonical source docs (templates, with `[PLACEHOLDER]`s) |
| `supabase/legal/placeholders.json` | Fill this before seeding |
| `supabase/migrations/20260905120000_legal_documents_and_acceptances.sql` | The two tables + RLS |
| `supabase/scripts/seed-legal.mjs` | Strips frontmatter, substitutes placeholders, upserts v1.0 rows |

## To publish

1. **Fill `placeholders.json`.** The seed script refuses any document that still
   contains an unresolved `[PLACEHOLDER]` (partial seed — filled docs go live,
   the rest wait). `EFFECTIVE DATE` must be `YYYY-MM-DD`; it also becomes
   `effective_at`.
2. **Apply the migration** to the hosted project.
3. **Seed:**
   ```
   cd supabase/scripts && npm install
   SUPABASE_URL=... SUPABASE_SERVICE_ROLE_KEY=... npm run seed
   ```
   `npm run seed:dry` previews without writing. `npm test` checks the parser.
4. **Regenerate the web types** if the schema changed (currently hand-edited in
   `webapp/src/lib/supabase/database.types.ts`).
5. **Verify anonymous access:**
   ```
   curl -s https://<domain>/legal/privacy-policy | grep -i "Individual Privacy Act"
   ```

## Acceptance model

`legal_acceptances` rows reference a **document version id**, never a slug.
`on delete restrict` on `user_id` — the record survives account deletion
(deletion anonymises the auth user, it does not remove the acceptance).
RLS: users may only INSERT/SELECT their own rows; no UPDATE/DELETE.

- **Sign-up** → `terms-of-service`, `privacy-policy`, `community-guidelines`
  (stashed locally pre-OTP, flushed on first authenticated launch).
- **Checkout** → `booking-terms`, `cancellation-policy` (written against the
  booking, before payment).
- **Risk Acknowledgment** → per booking, high-risk experiences only
  (difficulty ≠ easy, altitude > 3000 m, or climbing/rafting/paragliding/
  canyoning). Full screen, scroll-gated, three ticks.
- **Re-acceptance**: on launch/app-shell mount, `requires_acceptance` docs whose
  current version the user has not accepted → informational banner before the
  effective date, blocking screen on/after it.

## Not done / follow-ups

- No document is seeded yet (placeholders unfilled — see step 1).
- Migration not applied to any environment.
- `ne` locale intentionally unseeded (needs a human translation, not MT).
- Flutter headings use the bold sans scale — no serif font is bundled. Web uses
  Playfair (serif) as specified.
- Contextual links (spec §7) wired in both clients: experience page (near price
  → Cancellation; high-risk → Safety & Risk), checkout service-fee line →
  Payment Policy, booking confirmation → Cancellation + Refund, Settings → Legal
  & Policies, Help & Support → Grievance + Emergency, sign-up, checkout.
  Flutter-only: itinerary + trip chat app bars → Emergency, review submission →
  Community Guidelines, `/emergency` quick-dial screen.
- Still unlinked because the flow itself does not exist yet: **Plans → cancel
  booking** (no cancel action in `plans_screen`) and **Settings → Delete
  Account** (no deletion UI). Add the §7 link when those screens are built.
- The Flutter `limited_package_detail.dart` presentation variant does not carry
  the price-adjacent legal links; add if that path needs parity.
