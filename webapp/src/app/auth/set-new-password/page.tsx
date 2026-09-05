"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { supabase } from "@/lib/supabase";
import { TextField } from "@/components/ui/TextField";
import { Button } from "@/components/ui/Button";

export default function SetNewPasswordPage() {
  const router = useRouter();
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
    const { error } = await supabase.auth.updateUser({ password });
    setLoading(false);
    if (error) setError(error.message);
    else router.push("/auth/login");
  }

  return (
    <div className="mx-auto max-w-sm px-4 py-16 lg:py-24">
      <h1 className="font-[family-name:var(--font-display)] text-3xl font-bold">Set a New Password</h1>
      <p className="mt-1 text-[var(--color-ink)]/70">Choose a new password for your account.</p>

      <form onSubmit={submit} className="mt-8 space-y-4">
        <TextField
          label="New Password"
          type="password"
          required
          minLength={6}
          value={password}
          onChange={(e) => setPassword(e.target.value)}
        />
        <TextField
          label="Confirm New Password"
          type="password"
          required
          value={confirmPassword}
          onChange={(e) => setConfirmPassword(e.target.value)}
        />
        {error && <p className="text-sm text-[var(--color-error)]">{error}</p>}
        <Button type="submit" variant="primary" fullWidth isLoading={loading}>
          Update Password
        </Button>
      </form>
    </div>
  );
}
