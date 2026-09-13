import { createServerClient } from "@supabase/ssr";
import { cookies } from "next/headers";

// Anon, session-bound client. Used ONLY to identify the caller (getUser).
// Every business read/write goes through the service-role client inside
// withAdmin — never this one.
export async function createAnonServerClient() {
  const cookieStore = await cookies();
  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll();
        },
        setAll(cookiesToSet) {
          try {
            cookiesToSet.forEach(({ name, value, options }) =>
              cookieStore.set(name, value, options),
            );
          } catch {
            // Server Component with no writable request context — the proxy
            // refreshes the session cookie instead.
          }
        },
      },
    },
  );
}
