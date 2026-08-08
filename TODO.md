# TODO

## Apple sign-in

Entry point exists ("Continue with Apple" button on
[login_screen.dart](lib/features/auth/login_screen.dart),
[sign_up_screen.dart](lib/features/auth/sign_up_screen.dart), and
[welcome_screen.dart](lib/features/onboarding/welcome_screen.dart)), gated
behind `isApplePlatform` (`auth_repository.dart`) so it's hidden on Android —
Apple sign-in only makes sense on iOS/macOS. Wired through
`AuthRepository.signInWithOAuth(OAuthProvider.apple)`, but the provider is
disabled server-side — tapping it currently opens a browser tab showing
`{"error_code":"validation_failed","msg":"Unsupported provider: provider is
not enabled"}`.

To finish:

1. Apple Developer account (paid, $99/year) — needed to create a Services ID.
2. Register a Services ID with the web redirect URI:
   `https://dtebgbrqynxahuzmbtbc.supabase.co/auth/v1/callback`
3. Generate a Sign in with Apple private key, derive the client secret JWT
   from it (Apple secrets are short-lived signed tokens, not a static string
   — Supabase's docs walk through the exact generation step).
4. Fill in `client_id`/`secret` and set `enabled = true` under
   `[auth.external.apple]` in [supabase/config.toml](supabase/config.toml),
   then `supabase config push`.

## AI itinerary planner

"Plan with AI" button on [home_screen.dart](lib/features/home/home_screen.dart)
opens [ai_itinerary_screen.dart](lib/features/ai_itinerary/ai_itinerary_screen.dart),
which calls the [generate-itinerary](supabase/functions/generate-itinerary/index.ts)
Edge Function — deployed, but returns
`{"error":"AI itinerary generation is not configured yet."}` until an
Anthropic API key is set.

To finish:

1. Get an API key from [console.anthropic.com](https://console.anthropic.com) → API Keys.
2. `supabase secrets set ANTHROPIC_API_KEY=<key> --project-ref dtebgbrqynxahuzmbtbc`

The function only recommends experiences that exist in the `experiences`
table — it can't hallucinate a trek that isn't actually bookable.
