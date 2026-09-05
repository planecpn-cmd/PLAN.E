"use client";

import { supabase } from "@/lib/supabase";
import { Button } from "@/components/ui/Button";
import { GoogleMark } from "@/components/ui/GoogleMark";

export function GoogleSignInButton() {
  async function withGoogle() {
    await supabase.auth.signInWithOAuth({
      provider: "google",
      options: { redirectTo: `${window.location.origin}/` },
    });
  }

  return (
    <Button variant="secondary" fullWidth onClick={withGoogle}>
      <GoogleMark size={18} />
      Continue with Google
    </Button>
  );
}
