import { NextResponse, type NextRequest } from "next/server";
import { createAnonServerClient } from "@/lib/supabase/server";

// OAuth (Google) redirect lands here with ?code=...; exchange it for a session
// cookie, then continue to `next` (default "/").
export async function GET(request: NextRequest) {
  const { searchParams, origin } = request.nextUrl;
  const code = searchParams.get("code");
  const next = searchParams.get("next") || "/";

  if (code) {
    const supabase = await createAnonServerClient();
    const { error } = await supabase.auth.exchangeCodeForSession(code);
    if (!error) return NextResponse.redirect(`${origin}${next}`);
  }
  return NextResponse.redirect(`${origin}/login?error=oauth`);
}
