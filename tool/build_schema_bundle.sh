#!/usr/bin/env bash

# Regenerate the schema bundles from supabase/migrations/.
#
#   supabase/full_schema_bundle.sql    every migration, for a fresh local Docker
#                                      stack
#   supabase/hosted_schema_bundle.sql  same, for pasting into the hosted
#                                      dashboard SQL Editor when the CLI is
#                                      unavailable
#
# Neither bundle contains the experience catalog. 0018 is excluded from both
# because it inserts departures for experiences that only exist after
# supabase/seed.sql has been loaded; run it separately, after the catalog.
#
# Migration files are either the original 4-digit sequence (0001-0022) or a
# 14-digit UTC timestamp (YYYYMMDDHHMMSS...). A plain lexicographic sort puts
# every 4-digit file first, in numeric order, because they're all zero-padded
# to the same width and start with "0" -- which sorts before "2", the first
# digit of every timestamp (all from 2026). Timestamp files then sort in
# chronological order because the format is fixed-width and zero-padded.
# Verified against the actual migrations/ directory, not assumed.

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
migrations_dir="$repo_root/supabase/migrations"
generated_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

emit_bundle() {
  local out_file="$1"
  local header="$2"
  local usage="$3"
  shift 3
  local migrations=("$@")

  {
    printf -- '-- PLAN E: %s\n' "$header"
    printf -- '-- Generated %s by tool/build_schema_bundle.sh. Do not edit by hand.\n' "$generated_at"
    printf -- '-- Source of truth is supabase/migrations/; regenerate after changing it.\n'
    printf -- '-- Contains schema, RLS, grants, and the taxonomy reference rows from\n'
    printf -- '-- 0004 (interests, regions, categories). It does NOT contain the\n'
    printf -- '-- experience catalog, which lives in supabase/seed.sql.\n'
    printf -- '--\n'
    printf -- '-- APPLY ONLY TO AN EMPTY DATABASE. Tables use bare CREATE TABLE and the\n'
    printf -- '-- 0004 inserts have no ON CONFLICT clause, so running this against a\n'
    printf -- '-- database that already has the schema aborts on a duplicate object or\n'
    printf -- '-- duplicate slug. That failure is safe -- it rolls back rather than\n'
    printf -- '-- corrupting data -- but it means this is not a repair or upgrade tool.\n'
    printf -- '--\n'
    printf -- '%s\n' "$usage"

    local name
    for name in "${migrations[@]}"; do
      printf -- '\n-- ===== %s =====\n' "$name"
      cat "$migrations_dir/$name"
    done
  } > "$out_file"

  printf '%s (%s lines)\n' "$out_file" "$(wc -l < "$out_file" | tr -d ' ')"
}

mapfile -t all_migrations < <(cd "$migrations_dir" && ls -1 *.sql | sort)
mapfile -t schema_migrations < <(printf '%s\n' "${all_migrations[@]}" | grep -v '^0018_seed_experience_departures\.sql$')

if [[ ${#schema_migrations[@]} -eq 0 ]]; then
  echo "No migrations found in $migrations_dir" >&2
  exit 1
fi

# A break-glass tool that silently emits a partial schema is worse than one
# that errors -- fail loudly if the count doesn't match what's on disk minus
# the one deliberate exclusion above, instead of quietly shipping a subset.
expected_count=$(( ${#all_migrations[@]} - 1 ))
if [[ ${#schema_migrations[@]} -ne $expected_count ]]; then
  echo "Migration count mismatch: found ${#all_migrations[@]} files in $migrations_dir," >&2
  echo "expected to bundle $expected_count after excluding 0018. Got ${#schema_migrations[@]}." >&2
  echo "Refusing to emit a possibly-incomplete bundle." >&2
  exit 1
fi

emit_bundle \
  "$repo_root/supabase/full_schema_bundle.sql" \
  "full schema bundle for local Docker Supabase" \
  "-- Run once against a fresh local Supabase (docker) instance:
--   supabase db reset   (applies migrations automatically), OR
--   psql \"\$DATABASE_URL\" -f supabase/full_schema_bundle.sql" \
  "${schema_migrations[@]}"

emit_bundle \
  "$repo_root/supabase/hosted_schema_bundle.sql" \
  "schema bundle for a hosted project (dashboard SQL Editor)" \
  "-- For setting up a hosted project without the CLI: open the project in the
-- Supabase dashboard, go to SQL Editor, paste this whole file, and run it.
-- Includes 0019_service_role_grants.sql, which Edge Functions require.
--
-- Prefer \`tool/setup_hosted_backend.sh --project-ref <REF>\` when a terminal is
-- available; it keeps the CLI migration history in sync. After applying this
-- bundle by hand, reconcile that history with:
--   supabase migration repair --status applied <version>" \
  "${schema_migrations[@]}"

echo
echo "Applying a bundle by hand leaves the CLI migration history empty, so a"
echo "later \`supabase db push\` will try to re-apply every migration. Reconcile"
echo "with: supabase migration repair --status applied <version>"
