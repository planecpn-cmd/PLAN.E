import { createBrowserClient } from "@supabase/ssr";

// Browser client — sign-in / sign-out only. No business data is ever queried
// from the browser in the admin panel.
export function createBrowserSupabase() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
  );
}
