"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { Card } from "@/components/ui/Card";
import { Button } from "@/components/ui/Button";
import { useAuth } from "@/lib/AuthProvider";
import { supabase } from "@/lib/supabase";

export default function HostStatusPage() {
  const { user } = useAuth();
  const [status, setStatus] = useState("submitted");
  useEffect(() => { if (user) void supabase.from("host_applications").select("status").eq("user_id", user.id).maybeSingle().then(({ data }) => setStatus(data?.status ?? "submitted")); }, [user]);
  const label = status === "action_required" ? "ACTION REQUIRED" : status.replaceAll("_", " ").toUpperCase();
  return <div className="plan-e-background min-h-[70vh] px-4 py-16"><Card className="mx-auto max-w-xl p-8 text-center md:p-12"><div className="mx-auto flex h-16 w-16 items-center justify-center rounded-full bg-[var(--color-sage)] text-3xl text-[var(--color-forest)]" aria-hidden="true">✓</div><h1 className="mt-6 font-[family-name:var(--font-display)] text-3xl font-bold text-[var(--color-forest)]">Application submitted</h1><p className="mt-3 leading-7">Your host application has been sent to Plan E for review.</p><p className="mx-auto mt-6 w-fit rounded-full bg-[var(--color-sage)] px-4 py-2 text-sm font-bold text-[var(--color-forest)]">{label}</p><p className="mt-5 text-sm">We&apos;ll let you know if we need any additional information.</p><Link href="/profile" className="mt-8 block"><Button fullWidth>Back to My Account</Button></Link></Card></div>;
}
