# PLAN.E

## Run on Android with this Mac as the backend

The Android project has one application ID: `com.plane.plan_e`. There are no
product flavors, so a normal run always installs or updates the same app:

```sh
flutter run --dart-define-from-file=env/local.json -d <DEVICE_ID>
```

To let physical devices on the same Wi-Fi use the Supabase stack running on
this Mac, run the LAN setup whenever the Mac's Wi-Fi address changes:

```sh
./tool/configure_lan_backend.sh
```

The script updates the ignored client and edge-function environment files,
restarts local Supabase so payment callbacks use the LAN address, and verifies
the REST endpoint. Then run with `--dart-define-from-file=env/local.json`; no flavor or ADB
reverse is required. Keep the Mac awake, Docker Desktop and Supabase running, and allow
incoming connections to port `54341` in the macOS firewall.

The app reads Supabase configuration at build time. For the hosted backend,
keep the matching project URL and current public/publishable key in the ignored
`env/local.json`, then use the command above. Rebuild after changing either value.
Do not commit this local configuration.

For an explicit override, the app also supports:

```sh
flutter run -d <DEVICE_ID> \
  --dart-define=SUPABASE_URL=https://example.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<anon-key>
```

Never put a Supabase service-role key in a Flutter build. The local LAN setup
is for development only and should not contain production customer data.

For deploying the same schema, catalog, and Edge Functions to a shared hosted
Supabase project, follow [docs/SUPABASE_HOSTED_SETUP.md](docs/SUPABASE_HOSTED_SETUP.md).
