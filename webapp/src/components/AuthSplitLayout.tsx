import Image from "next/image";
import { Logo } from "@/components/ui/Logo";
import type { ReactNode } from "react";

// Desktop-only photo/form split for the simple auth screens (login, sign-up,
// forgot-password, etc). Mobile keeps the plain centered-form layout those
// pages already had — only the wide viewport gets the photo pane, so the
// form never floats alone on a bare textured background at desktop width.
export function AuthSplitLayout({ children }: { children: ReactNode }) {
  return (
    <div className="lg:flex lg:min-h-screen">
      <div className="relative hidden lg:block lg:w-1/2">
        <Image src="/brand/welcome-hero.jpg" alt="" fill priority sizes="50vw" className="object-cover" />
        <div className="absolute inset-0 bg-gradient-to-t from-black/70 via-black/10 to-black/40" />
        <div className="absolute left-8 top-8">
          <Logo size={24} color="#ffffff" />
        </div>
      </div>
      <div className="flex flex-1 items-center justify-center lg:w-1/2">{children}</div>
    </div>
  );
}
