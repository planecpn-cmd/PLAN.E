#!/usr/bin/env bash

# Configure this machine against a hosted Supabase project: link the project,
# push migrations, optionally deploy Edge Functions, and write env/local.json
# so `flutter run` picks up the client credentials without --dart-define.
#
# The catalog seed is NOT part of the default run. See --with-seed.

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
client_config="$repo_root/env/local.json"
hosted_env="$repo_root/supabase/functions/.env.hosted"

project_ref="${SUPABASE_PROJECT_REF:-}"
do_push=1
do_seed=0
do_functions=0
do_client=1
check_only=0

usage() {
  cat <<'EOF'
Usage: tool/setup_hosted_backend.sh --project-ref <REF> [options]

Options:
  --project-ref <REF>   Hosted project reference (the <ref> in <ref>.supabase.co).
                        Falls back to $SUPABASE_PROJECT_REF.
  --check               Run preflight checks only, change nothing.
  --skip-push           Do not run `supabase db push`.
  --skip-client         Do not write env/local.json.
  --with-functions      Upload secrets from supabase/functions/.env.hosted and
                        deploy all Edge Functions.
  --with-seed           DESTRUCTIVE. Load supabase/seed.sql. This replaces the
                        experience catalog and cascades into dependent booking
                        data. Only for a new or empty project. Requires typing
                        the project ref to confirm.
  -h, --help            Show this message.

Never place SUPABASE_SERVICE_ROLE_KEY, gateway secrets, or database passwords in
env/local.json or in --dart-define; Flutter assets and defines ship inside the
app. Server-only values belong in supabase/functions/.env.hosted, which is
gitignored and uploaded via `supabase secrets set`.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-ref) project_ref="${2:-}"; shift 2 ;;
    --check) check_only=1; shift ;;
    --skip-push) do_push=0; shift ;;
    --skip-client) do_client=0; shift ;;
    --with-functions) do_functions=1; shift ;;
    --with-seed) do_seed=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; echo >&2; usage >&2; exit 1 ;;
  esac
done

# --- Preflight ---------------------------------------------------------------

if ! command -v supabase >/dev/null 2>&1; then
  echo "The Supabase CLI is not installed or not on PATH." >&2
  echo "Install it from https://supabase.com/docs/guides/local-development/cli/getting-started" >&2
  exit 1
fi

if ! supabase projects list >/dev/null 2>&1; then
  echo "The Supabase CLI is not authenticated. Run: supabase login" >&2
  exit 1
fi

if [[ -z "$project_ref" ]]; then
  echo "Missing project reference. Pass --project-ref <REF> or set SUPABASE_PROJECT_REF." >&2
  echo "Find it in the Supabase dashboard under Project Settings > General." >&2
  exit 1
fi

project_url="https://${project_ref}.supabase.co"

echo "Repository:   $repo_root"
echo "Project ref:  $project_ref"
echo "Project URL:  $project_url"
echo

if [[ "$check_only" -eq 1 ]]; then
  echo "Preflight passed: CLI installed, authenticated, project ref supplied."
  echo "Re-run without --check to apply changes."
  exit 0
fi

# --- Link --------------------------------------------------------------------

echo "==> Linking project"
supabase link --project-ref "$project_ref"

# --- Migrations --------------------------------------------------------------

if [[ "$do_push" -eq 1 ]]; then
  echo
  echo "==> Pushing migrations"
  supabase db push --linked
else
  echo
  echo "==> Skipping migrations (--skip-push)"
fi

# --- Catalog seed (destructive, opt-in) --------------------------------------

if [[ "$do_seed" -eq 1 ]]; then
  echo
  echo "############################################################"
  echo "# WARNING: supabase/seed.sql replaces the experience catalog"
  echo "# and cascades into dependent booking and payment data on"
  echo "# project $project_ref."
  echo "#"
  echo "# Only safe on a new or empty project. If this project has"
  echo "# real bookings, answering yes will destroy them."
  echo "############################################################"
  echo
  printf 'Type the project ref (%s) to confirm, anything else to abort: ' "$project_ref"
  read -r seed_confirmation
  if [[ "$seed_confirmation" != "$project_ref" ]]; then
    echo "Seed aborted. Nothing was written." >&2
    exit 1
  fi

  echo "==> Loading catalog seed"
  supabase db query --linked --file supabase/seed.sql

  # Re-run after the seed: the migration runs before the external seed on a
  # first deployment, and its inserts are idempotent.
  echo "==> Regenerating experience departures"
  supabase db query --linked --file supabase/migrations/0018_seed_experience_departures.sql
fi

# --- Edge Functions ----------------------------------------------------------

if [[ "$do_functions" -eq 1 ]]; then
  echo
  if [[ ! -f "$hosted_env" ]]; then
    echo "Missing $hosted_env." >&2
    echo "Copy supabase/functions/.env.example to .env.hosted and fill in the" >&2
    echo "gateway keys plus PUBLIC_SUPABASE_URL=$project_url first." >&2
    exit 1
  fi

  if grep -qE '(replace_me|YOUR_MAC_LAN_IP|<YOUR_)' "$hosted_env"; then
    echo "$hosted_env still contains template placeholders." >&2
    echo "Replace them with real values before deploying." >&2
    exit 1
  fi

  echo "==> Uploading Edge Function secrets"
  supabase secrets set --env-file "$hosted_env"

  echo "==> Deploying Edge Functions"
  supabase functions deploy
fi

# --- Flutter client config ---------------------------------------------------

if [[ "$do_client" -eq 1 ]]; then
  echo
  echo "==> Writing client configuration"

  if [[ -f "$client_config" ]]; then
    printf '%s already exists. Overwrite? [y/N]: ' "$client_config"
    read -r overwrite_confirmation
    if [[ "$overwrite_confirmation" != "y" && "$overwrite_confirmation" != "Y" ]]; then
      echo "Left $client_config unchanged."
      do_client=0
    fi
  fi
fi

if [[ "$do_client" -eq 1 ]]; then
  anon_key=""

  # Best effort: read the publishable key from the CLI so it never has to be
  # pasted by hand. Falls back to a prompt on any parsing or version mismatch.
  if api_keys_json="$(supabase projects api-keys --project-ref "$project_ref" --output json 2>/dev/null)"; then
    if command -v python3 >/dev/null 2>&1; then
      anon_key="$(printf '%s' "$api_keys_json" | python3 -c '
import json, sys
try:
    keys = json.load(sys.stdin)
except Exception:
    sys.exit(0)
if isinstance(keys, dict):
    keys = keys.get("data", keys.get("keys", []))
if not isinstance(keys, list):
    sys.exit(0)
for entry in keys:
    if isinstance(entry, dict) and entry.get("name") in ("anon", "publishable"):
        print(entry.get("api_key") or entry.get("apiKey") or "")
        break
' 2>/dev/null || true)"
    fi
  fi

  if [[ -z "$anon_key" ]]; then
    echo "Could not read the key automatically."
    echo "Copy the anon / publishable key from Project Settings > API Keys."
    printf 'Anon key (input hidden): '
    read -rs anon_key
    echo
  else
    echo "Read the publishable key from the Supabase CLI."
  fi

  if [[ -z "$anon_key" ]]; then
    echo "No anon key supplied; $client_config not written." >&2
    exit 1
  fi

  case "$anon_key" in
    *service_role*)
      echo "That value looks like a service-role key. It bypasses RLS and must" >&2
      echo "never ship in a client app. Use the anon / publishable key." >&2
      exit 1
      ;;
  esac

  umask 077
  cat > "$client_config" <<EOF
{
  "_comment": "WARNING: Never include SUPABASE_SERVICE_ROLE_KEY or any administrative secret in this file. Client app assets are public. DEMO_EMAIL and DEMO_PASSWORD are optional dev-only auto-login values and must not be set for release builds.",
  "SUPABASE_URL": "$project_url",
  "SUPABASE_ANON_KEY": "$anon_key"
}
EOF
  chmod 600 "$client_config"
  echo "Wrote $client_config (mode 600, gitignored)."
fi

# --- Summary -----------------------------------------------------------------

echo
echo "Hosted backend configuration complete for $project_ref."
echo
echo "Run the app with:"
echo "  flutter run -d <DEVICE_ID>"
echo
echo "Or bypass env/local.json entirely:"
echo "  flutter run -d <DEVICE_ID> \\"
echo "    --dart-define=SUPABASE_URL=$project_url \\"
echo "    --dart-define=SUPABASE_ANON_KEY=<ANON_OR_PUBLISHABLE_KEY>"
