"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { supabase } from "@/lib/supabase";
import { useAuth } from "@/lib/AuthProvider";
import { Icon } from "@/components/ui/Icon";

export function BookmarkButton({ experienceId }: { experienceId: string }) {
  const { user } = useAuth();
  const router = useRouter();
  // Raw fetched value; rendering derives `saved` below so signed-out is never
  // a setState call, just a computed false.
  const [fetchedSaved, setFetchedSaved] = useState(false);
  const saved = user ? fetchedSaved : false;

  useEffect(() => {
    if (!user) return;
    supabase
      .from("saved_experiences")
      .select("experience_id")
      .eq("user_id", user.id)
      .eq("experience_id", experienceId)
      .maybeSingle()
      .then(({ data }) => setFetchedSaved(!!data));
  }, [user, experienceId]);

  async function toggle() {
    if (!user) {
      router.push(`/auth/required?reason=${encodeURIComponent("save this experience")}`);
      return;
    }
    if (saved) {
      await supabase
        .from("saved_experiences")
        .delete()
        .eq("user_id", user.id)
        .eq("experience_id", experienceId);
      setFetchedSaved(false);
    } else {
      await supabase.from("saved_experiences").insert({ user_id: user.id, experience_id: experienceId });
      setFetchedSaved(true);
    }
  }

  return (
    <button
      type="button"
      onClick={toggle}
      aria-label={saved ? "Remove from saved" : "Save experience"}
      aria-pressed={saved}
      className="flex h-10 w-10 items-center justify-center rounded-full bg-white/90 text-[var(--color-forest)] shadow-sm hover:bg-white focus-visible:outline focus-visible:outline-2 focus-visible:outline-[var(--color-gold)]"
    >
      <Icon name="heart" filled={saved} className={saved ? "text-[var(--color-error)]" : ""} />
    </button>
  );
}
