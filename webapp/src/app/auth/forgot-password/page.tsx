"use client";

import { useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { supabase } from "@/lib/supabase";
import { TextField } from "@/components/ui/TextField";
import { Button } from "@/components/ui/Button";

export default function ForgotPasswordPage() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError(null);
    const { error } = await supabase.auth.resetPasswordForEmail(email, {
      redirectTo: `${window.location.origin}/auth/set-new-password`,
    });
    setLoading(false);
    if (error) setError(error.message);
    else router.push(`/auth/otp-verify?email=${encodeURIComponent(email)}&purpose=recovery`);
  }

  return (
    <div className="mx-auto max-w-sm px-4 py-16 lg:py-24">
      <h1 className="font-[family-name:var(--font-display)] text-3xl font-bold">Forgot Password</h1>
      <p className="mt-1 text-[var(--color-ink)]/70">Enter your email and we&apos;ll send you a reset code.</p>

      <form onSubmit={submit} className="mt-8 space-y-4">
        <TextField label="Email or Phone" type="email" required value={email} onChange={(e) => setEmail(e.target.value)} />
        {error && <p className="text-sm text-[var(--color-error)]">{error}</p>}
        <Button type="submit" variant="primary" fullWidth isLoading={loading}>
          Send Reset Link
        </Button>
      </form>

      <p className="mt-6 text-center text-sm">
        <Link href="/auth/login" className="font-semibold text-[var(--color-forest)] hover:underline">
          Back to Login
        </Link>
      </p>
    </div>
  );
}
