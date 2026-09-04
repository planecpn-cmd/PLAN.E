import { createClient, type SupabaseClient, type User } from "https://esm.sh/@supabase/supabase-js@2";

export class AuthenticationError extends Error {}

type AuthenticatedContext = {
  user: User;
  userClient: SupabaseClient;
  adminClient: SupabaseClient;
};

export async function requireAuthenticatedUser(req: Request): Promise<AuthenticatedContext> {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ") || authHeader.length <= "Bearer ".length) {
    throw new AuthenticationError("Authentication required");
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !supabaseAnonKey || !serviceRoleKey) {
    throw new Error("Supabase authentication is not configured");
  }

  const userClient = createClient(supabaseUrl, supabaseAnonKey, {
    global: { headers: { Authorization: authHeader } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data: { user }, error } = await userClient.auth.getUser();
  if (error || !user) {
    throw new AuthenticationError("Invalid or expired session");
  }

  const adminClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  return { user, userClient, adminClient };
}
