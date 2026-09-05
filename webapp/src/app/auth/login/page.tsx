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

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError(null);
    const { error } = await supabase.auth.signInWithPassword({ email, password });
    setLoading(false);
    if (error) setError(error.message);
    else router.push("/");
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
        <h1 className="font-[family-name:var(--font-display)] text-3xl font-bold">Welcome Back</h1>
        <p className="mt-1 text-[var(--color-ink)]/70">Sign in to continue planning your trip.</p>

        <form onSubmit={submit} className="mt-8 space-y-4">
          <TextField
            label="Email or Phone"
            type="text"
            icon="user"
            required
            value={email}
            onChange={(e) => setEmail(e.target.value)}
          />
          <TextField
            label="Password"
            type="password"
            required
            value={password}
            onChange={(e) => setPassword(e.target.value)}
          />
          <div className="text-right">
            <Link href="/auth/forgot-password" className="text-sm font-medium text-[var(--color-forest)] hover:underline">
              Forgot Password?
            </Link>
          </div>
          {error && <p className="text-sm text-[var(--color-error)]">{error}</p>}
          <Button type="submit" variant="primary" fullWidth isLoading={loading}>
            Login
          </Button>
        </form>

        <OrDivider />

        <Button variant="secondary" fullWidth onClick={withGoogle}>
          <GoogleMark size={18} />
          Continue with Google
        </Button>

        <p className="mt-6 text-center text-sm text-[var(--color-ink)]/70">
          Don&apos;t have an account?{" "}
          <Link href="/auth/sign-up" className="font-semibold text-[var(--color-forest)] hover:underline">
            Sign Up
          </Link>
        </p>
      </div>
    </AuthSplitLayout>
  );
}
