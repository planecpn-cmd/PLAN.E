"use client";

import { Suspense } from "react";
import Image from "next/image";
import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { Logo } from "@/components/ui/Logo";
import { Button } from "@/components/ui/Button";
import { GoogleMark } from "@/components/ui/GoogleMark";
import { OrDivider } from "@/components/OrDivider";
import { Icon } from "@/components/ui/Icon";
import { supabase } from "@/lib/supabase";

// Mirrors welcome_screen.dart visually — auth_required_sheet.dart reuses the
// same hero-photo + floating-card template with dynamic reason copy.
function AuthRequiredContent() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const reason = searchParams.get("reason") ?? "continue";

  async function withGoogle() {
    await supabase.auth.signInWithOAuth({
      provider: "google",
      options: { redirectTo: `${window.location.origin}/` },
    });
  }

  return (
    <div className="lg:flex lg:min-h-screen">
      <div className="relative flex min-h-[52vh] flex-col justify-between overflow-hidden p-5 lg:min-h-screen lg:w-1/2 lg:p-10">
        <Image src="/brand/welcome-hero.jpg" alt="" fill priority sizes="(max-width: 1024px) 100vw, 50vw" className="-z-10 object-cover" />
        <div className="absolute inset-0 -z-10 bg-gradient-to-t from-black/75 via-black/20 to-black/45" />

        <div className="flex items-center justify-between">
          <button onClick={() => router.back()} aria-label="Back" className="flex h-10 w-10 items-center justify-center rounded-full bg-white/15 text-white">
            <Icon name="chevronLeft" size={20} />
          </button>
          <Logo size={20} color="#ffffff" />
        </div>

        <div className="max-w-md">
          <h1 className="font-[family-name:var(--font-display)] text-3xl font-bold text-white lg:text-5xl">
            Sign In
            <br />
            Required
          </h1>
          <span className="mt-3 block h-0.5 w-14 bg-[var(--color-gold)]" />
          <p className="mt-3 text-sm text-white/85 lg:text-base">
            Create a free account or log in to {reason}.
          </p>
        </div>
      </div>

      <div className="flex flex-1 items-center justify-center px-4 py-6 lg:w-1/2 lg:py-10">
        <div className="-mt-10 w-full max-w-sm rounded-[var(--radius-lg)] bg-white p-6 shadow-[0_-8px_32px_rgba(1,37,28,0.12)] lg:mt-0 lg:shadow-none">
          <div className="space-y-3">
            <Link href="/auth/sign-up">
              <Button variant="primary" fullWidth>
                <Icon name="user" size={18} />
                Continue with Phone
              </Button>
            </Link>
            <Button variant="secondary" fullWidth onClick={withGoogle}>
              <GoogleMark size={18} />
              Continue with Google
            </Button>
            <OrDivider label="or continue with email" />
            <Link href="/auth/sign-up">
              <Button variant="secondary" fullWidth>
                Continue with Email
              </Button>
            </Link>
            <Button variant="text" fullWidth onClick={() => router.back()}>
              Not Now
            </Button>
          </div>
        </div>
      </div>
    </div>
  );
}

export default function AuthRequiredPage() {
  return (
    <Suspense>
      <AuthRequiredContent />
    </Suspense>
  );
}
