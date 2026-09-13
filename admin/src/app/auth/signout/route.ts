import { NextResponse, type NextRequest } from "next/server";
import { createAnonServerClient } from "@/lib/supabase/server";

export async function POST(request: NextRequest) {
  const supabase = await createAnonServerClient();
  await supabase.auth.signOut();
  return NextResponse.redirect(`${request.nextUrl.origin}/login`, { status: 303 });
}
