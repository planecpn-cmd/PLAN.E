"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { supabase } from "@/lib/supabase";
import { useAuth } from "@/lib/AuthProvider";
import { Button } from "@/components/ui/Button";
import { EmptyState } from "@/components/ui/EmptyState";
import { OrnamentDivider } from "@/components/ui/OrnamentDivider";
import { Icon, type IconName } from "@/components/ui/Icon";

type Profile = {
  full_name: string | null;
  avatar_url: string | null;
  location: string | null;
  points: number;
  role: string;
};

const SETTINGS: { label: string; href: string; icon: IconName }[] = [
  { label: "My Plans", href: "/plans", icon: "calendar" },
  { label: "My Reviews", href: "/profile/my-reviews", icon: "star" },
  { label: "Payment Methods", href: "/profile/payment-methods", icon: "bookmark" },
  { label: "Notifications", href: "/profile/notifications", icon: "bell" },
  { label: "Language & Region", href: "/profile/language", icon: "compass" },
  { label: "Help & Support", href: "/profile/help", icon: "user" },
  { label: "Settings", href: "/profile/settings", icon: "menu" },
];

export default function ProfilePage() {
  const { user, loading: authLoading } = useAuth();
  const router = useRouter();
  const [profile, setProfile] = useState<Profile | null>(null);
  const [historyCount, setHistoryCount] = useState(0);
  const [savedCount, setSavedCount] = useState(0);

  useEffect(() => {
    if (authLoading || !user) return;
    supabase.from("profiles").select("full_name, avatar_url, location, points, role").eq("id", user.id).maybeSingle().then(({ data }) => {
      setProfile(data);
    });
    supabase
      .from("bookings")
      .select("id", { count: "exact", head: true })
      .eq("user_id", user.id)
      .eq("status", "completed")
      .then(({ count }) => setHistoryCount(count ?? 0));
    supabase
      .from("saved_experiences")
      .select("experience_id", { count: "exact", head: true })
      .eq("user_id", user.id)
      .then(({ count }) => setSavedCount(count ?? 0));
  }, [user, authLoading]);

  if (authLoading) return null;

  if (!user) {
    return (
      <div className="mx-auto max-w-6xl px-4 py-16 lg:px-6">
        <EmptyState
          title="Log in to view your profile"
          description="Sign in to manage your account, bookings, and saved experiences."
          action={
            <div className="mt-3 flex flex-col items-center gap-2">
              <Link href="/auth/login">
                <Button variant="primary">Log in</Button>
              </Link>
              <Link href="/host" className="text-sm font-semibold text-[var(--color-forest)] hover:underline">
                Continue as Host
              </Link>
            </div>
          }
        />
      </div>
    );
  }

  const initial = (profile?.full_name ?? user.email ?? "?").charAt(0).toUpperCase();

  return (
    <div className="mx-auto max-w-6xl px-4 py-10 lg:px-6 lg:py-14">
      <div className="lg:grid lg:grid-cols-[320px_1fr] lg:gap-10">
        <div>
          <div className="flex flex-col items-center text-center">
            <div className="flex h-24 w-24 items-center justify-center rounded-full border-2 border-[var(--color-forest)] bg-[var(--color-sage)] font-[family-name:var(--font-display)] text-3xl font-bold text-[var(--color-forest)]">
              {initial}
            </div>
            <h1 className="mt-3 font-[family-name:var(--font-display)] text-2xl font-bold">
              {profile?.full_name || "Traveler"}
            </h1>
            {profile?.location && (
              <p className="mt-1 flex items-center gap-1 text-sm text-[var(--color-ink)]/60">
                <Icon name="mapPin" size={14} />
                {profile.location}
              </p>
            )}
            <Link href="/profile/edit" className="mt-3">
              <Button variant="secondary" className="!py-2 !px-5 !text-xs">
                EDIT PROFILE
              </Button>
            </Link>
          </div>

          <OrnamentDivider className="my-6" />

          <div className="grid grid-cols-3 divide-x divide-[var(--color-border-subtle)] rounded-[var(--radius-md)] border border-[var(--color-border)] py-4 text-center">
            <Link href="/plans?tab=past" className="px-2">
              <p className="text-xl font-bold text-[var(--color-forest)]">{historyCount}</p>
              <p className="text-xs text-[var(--color-ink)]/60">History</p>
            </Link>
            <Link href="/saved" className="px-2">
              <p className="text-xl font-bold text-[var(--color-forest)]">{savedCount}</p>
              <p className="text-xs text-[var(--color-ink)]/60">Saved</p>
            </Link>
            <div className="px-2">
              <p className="text-xl font-bold text-[var(--color-forest)]">{profile?.points ?? 0}</p>
              <p className="text-xs text-[var(--color-ink)]/60">Points</p>
            </div>
          </div>
        </div>

        <div className="mt-8 lg:mt-0">
          <div className="overflow-hidden rounded-[var(--radius-md)] border border-[var(--color-border)]">
            {SETTINGS.map((item, i) => (
              <Link
                key={item.href}
                href={item.href}
                className={`flex items-center gap-3 px-4 py-3.5 text-sm hover:bg-[var(--color-sage)]/40 ${
                  i > 0 ? "border-t border-[var(--color-border-subtle)]" : ""
                }`}
              >
                <Icon name={item.icon} size={18} className="text-[var(--color-forest)]" />
                <span className="flex-1 font-medium">{item.label}</span>
                <Icon name="chevronRight" size={16} className="text-[var(--color-ink)]/40" />
              </Link>
            ))}
          </div>

          <Link href="/host" className="mt-4 block">
            <Button variant="secondary" fullWidth className="!bg-[var(--color-sage)] !border-transparent">
              <Icon name="people" size={18} />
              BECOME A LOCAL HOST
            </Button>
          </Link>

          <button
            onClick={async () => {
              await supabase.auth.signOut();
              router.push("/");
            }}
            className="mt-6 w-full text-center text-sm font-semibold text-[var(--color-error)]"
          >
            LOGOUT
          </button>
        </div>
      </div>
    </div>
  );
}
