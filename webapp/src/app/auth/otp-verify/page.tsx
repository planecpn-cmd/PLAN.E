"use client";

import { Suspense, useEffect, useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { supabase } from "@/lib/supabase";
import { TextField } from "@/components/ui/TextField";
import { Button } from "@/components/ui/Button";

function OtpVerifyForm() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const email = searchParams.get("email") ?? "";
  const isRecovery = searchParams.get("purpose") === "recovery";

  const [code, setCode] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [cooldown, setCooldown] = useState(30);

  useEffect(() => {
    if (cooldown <= 0) return;
    const t = setTimeout(() => setCooldown((c) => c - 1), 1000);
    return () => clearTimeout(t);
  }, [cooldown]);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError(null);
    const { error } = await supabase.auth.verifyOtp({
      email,
      token: code,
      type: isRecovery ? "recovery" : "email",
    });
    setLoading(false);
    if (error) {
      setError(error.message);
      return;
    }
    router.push(isRecovery ? "/auth/set-new-password" : "/");
  }

  async function resend() {
    setCooldown(30);
    if (isRecovery) {
      await supabase.auth.resetPasswordForEmail(email);
    } else {
      await supabase.auth.resend({ type: "signup", email });
    }
  }

  return (
    <div className="mx-auto max-w-sm px-4 py-16 lg:py-24">
      <h1 className="font-[family-name:var(--font-display)] text-3xl font-bold">
        {isRecovery ? "Reset Your Password" : "Verify Your Email"}
      </h1>
      <p className="mt-1 text-[var(--color-ink)]/70">
        Enter the 6-digit code we sent to {email || "your email"}.
      </p>

      <form onSubmit={submit} className="mt-8 space-y-4">
        <TextField
          label="Verification Code"
          inputMode="numeric"
          maxLength={6}
          required
          value={code}
          onChange={(e) => setCode(e.target.value)}
        />
        <div className="text-right text-sm">
          {cooldown > 0 ? (
            <span className="text-[var(--color-ink)]/70">Resend code in {cooldown}s</span>
          ) : (
            <button type="button" onClick={resend} className="font-medium text-[var(--color-forest)] hover:underline">
              Resend code
            </button>
          )}
        </div>
        {error && <p className="text-sm text-[var(--color-error)]">{error}</p>}
        <Button type="submit" variant="primary" fullWidth isLoading={loading}>
          Verify
        </Button>
      </form>
    </div>
  );
}

export default function OtpVerifyPage() {
  return (
    <Suspense>
      <OtpVerifyForm />
    </Suspense>
  );
}
