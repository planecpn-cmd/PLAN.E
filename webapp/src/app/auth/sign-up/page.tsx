"use client";

import { useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { supabase } from "@/lib/supabase";
import { TextField } from "@/components/ui/TextField";
import { Button } from "@/components/ui/Button";
import { GoogleMark } from "@/components/ui/GoogleMark";
import { OrDivider } from "@/components/OrDivider";
import { AuthSplitLayout } from "@/components/AuthSplitLayout";
import { AcceptanceLine } from "@/components/legal/AcceptanceLine";
import { stashSignupAcceptance } from "@/lib/legal-acceptance";

export default function SignUpPage() {
  const router = useRouter();
  const [fullName, setFullName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    if (password !== confirmPassword) {
      setError("Passwords do not match.");
      return;
    }
    setLoading(true);
    setError(null);
    // No session yet (email OTP first) — stash the three sign-up acceptances
    // with this timestamp; LegalAcceptanceManager flushes them after sign-in.
    stashSignupAcceptance();
    const { data, error } = await supabase.auth.signUp({
      email,
      password,
      options: { data: { full_name: fullName } },
    });
    setLoading(false);
    if (error) {
      setError(error.message);
      return;
    }
    if (!data.session) {
      router.push(`/auth/otp-verify?email=${encodeURIComponent(email)}`);
    } else {
      router.push("/");
    }
  }

  async function withGoogle() {
    await supabase.auth.signInWithOAuth({
      provider: "google",
      options: { redirectTo: `${window.location.origin}/` },
    });
  }

  return (
    <AuthSplitLayout>
      <div className="w-full max-w-sm px-4 py-16 lg:py-24">
        <h1 className="font-[family-name:var(--font-display)] text-3xl font-bold">Create Your Account</h1>
        <p className="mt-1 text-[var(--color-ink)]/70">Join PLAN E to save, book, and plan trips across Nepal.</p>

        <form onSubmit={submit} className="mt-8 space-y-4">
          <TextField label="Full Name" icon="user" required value={fullName} onChange={(e) => setFullName(e.target.value)} />
          <TextField
            label="Email Address"
            type="email"
            required
            value={email}
            onChange={(e) => setEmail(e.target.value)}
          />
          <TextField
            label="Password"
            type="password"
            required
            minLength={6}
            value={password}
            onChange={(e) => setPassword(e.target.value)}
          />
          <TextField
            label="Confirm Password"
            type="password"
            required
            value={confirmPassword}
            onChange={(e) => setConfirmPassword(e.target.value)}
          />
          {error && <p className="text-sm text-[var(--color-error)]">{error}</p>}
          <AcceptanceLine context="signUp" />
          <Button type="submit" variant="primary" fullWidth isLoading={loading}>
            Create Account
          </Button>
        </form>

        <OrDivider />

        <Button variant="secondary" fullWidth onClick={withGoogle}>
          <GoogleMark size={18} />
          Continue with Google
        </Button>

        <p className="mt-6 text-center text-sm text-[var(--color-ink)]/70">
          Already have an account?{" "}
          <Link href="/auth/login" className="font-semibold text-[var(--color-forest)] hover:underline">
            Login
          </Link>
        </p>
      </div>
    </AuthSplitLayout>
  );
}
