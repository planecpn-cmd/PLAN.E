#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
network_interface="${1:-en0}"

lan_ip="$(ipconfig getifaddr "$network_interface" 2>/dev/null || true)"
if [[ -z "$lan_ip" ]]; then
  lan_ip="$(ifconfig "$network_interface" 2>/dev/null | awk '/inet / { print $2; exit }')"
fi

if [[ -z "$lan_ip" ]]; then
  echo "Could not find an IPv4 address on $network_interface." >&2
  echo "Pass the active interface explicitly, for example: $0 en1" >&2
  exit 1
fi

public_url="http://${lan_ip}:54341"
client_config="$repo_root/env/local.json"
function_env="$repo_root/supabase/functions/.env"

if [[ ! -f "$client_config" ]]; then
  echo "Missing $client_config. Copy env/local.json.example and add the local anon key first." >&2
  exit 1
fi

if [[ ! -f "$function_env" ]]; then
  echo "Missing $function_env. Copy supabase/functions/.env.example and add gateway keys first." >&2
  exit 1
fi

LAN_PUBLIC_URL="$public_url" perl -0pi -e \
  's#"SUPABASE_URL"\s*:\s*"[^"]*"#"SUPABASE_URL": "$ENV{LAN_PUBLIC_URL}"#' \
  "$client_config"

temp_env="$(mktemp)"
awk -v public_url="$public_url" '
  BEGIN { updated = 0 }
  /^PUBLIC_SUPABASE_URL=/ {
    print "PUBLIC_SUPABASE_URL=" public_url
    updated = 1
    next
  }
  { print }
  END {
    if (!updated) print "PUBLIC_SUPABASE_URL=" public_url
  }
' "$function_env" > "$temp_env"
mv "$temp_env" "$function_env"

cd "$repo_root"
if supabase status >/dev/null 2>&1; then
  supabase stop
fi
supabase start

status_code="$(curl --max-time 5 --silent --output /dev/null --write-out '%{http_code}' "$public_url/rest/v1/")"
if [[ "$status_code" != "200" ]]; then
  echo "Supabase started, but $public_url/rest/v1/ returned HTTP $status_code." >&2
  exit 1
fi

echo
echo "PLAN E LAN backend is ready at $public_url"
echo "Devices must be on the same Wi-Fi as this Mac."
echo "Run the app with: flutter run --dart-define-from-file=env/local.json -d <DEVICE_ID>"
