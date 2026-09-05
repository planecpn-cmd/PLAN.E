import Image from "next/image";
import Link from "next/link";
import type { Metadata } from "next";
import { Logo } from "@/components/ui/Logo";
import { Button } from "@/components/ui/Button";
import { GoogleSignInButton } from "@/components/GoogleSignInButton";
import { OrDivider } from "@/components/OrDivider";
import { Icon } from "@/components/ui/Icon";

export const metadata: Metadata = { title: "Welcome — PLAN E" };

// Matches lib/features/onboarding/welcome_screen.dart. Apple sign-in is
// dropped — it's gated iOS-only in the app (isApplePlatform).
export default function WelcomePage() {
  return (
    <div className="lg:flex lg:min-h-screen">
      <div className="relative flex min-h-[62vh] flex-col justify-between overflow-hidden p-5 lg:min-h-screen lg:w-1/2 lg:p-10">
        <Image src="/brand/welcome-hero.jpg" alt="" fill priority sizes="(max-width: 1024px) 100vw, 50vw" className="-z-10 object-cover" />
        <div className="absolute inset-0 -z-10 bg-gradient-to-t from-black/75 via-black/20 to-black/45" />

        <div>
          <Logo size={22} color="#ffffff" />
          <p className="mt-1 text-[11px] font-semibold uppercase tracking-[0.2em] text-white/80">
            Plan Your Experience
          </p>
        </div>

        <div className="max-w-md">
          <h1 className="font-[family-name:var(--font-display)] text-3xl font-bold text-white lg:text-5xl">
            Experience Nepal 🇳🇵
          </h1>
          <span className="mt-3 block h-0.5 w-14 bg-[var(--color-gold)]" />
          <p className="mt-3 text-sm text-white/85 lg:text-base">
            Curated journeys, authentic experiences and memories that last a lifetime.
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
            <GoogleSignInButton />
            <OrDivider label="or continue with email" />
            <Link href="/auth/sign-up">
              <Button variant="secondary" fullWidth>
                Continue with Email
              </Button>
            </Link>
            <Link href="/" className="block text-center">
              <Button variant="text" fullWidth>
                Continue as Guest
              </Button>
            </Link>
          </div>

          <div className="mt-8 grid grid-cols-3 gap-3 text-center">
            <TrustBadge icon="user" title="Secure & Safe" subtitle="Your data is protected" />
            <TrustBadge icon="people" title="Local Experts" subtitle="Curated by locals" />
            <TrustBadge icon="bell" title="24/7 Support" subtitle="We're here anytime" />
          </div>
        </div>
      </div>
    </div>
  );
}

function TrustBadge({ icon, title, subtitle }: { icon: Parameters<typeof Icon>[0]["name"]; title: string; subtitle: string }) {
  return (
    <div>
      <div className="mx-auto flex h-9 w-9 items-center justify-center rounded-full bg-[var(--color-sage)] text-[var(--color-forest)]">
        <Icon name={icon} size={18} />
      </div>
      <p className="mt-1.5 text-xs font-bold">{title}</p>
      <p className="text-[10px] text-[var(--color-ink)]/60">{subtitle}</p>
    </div>
  );
}
