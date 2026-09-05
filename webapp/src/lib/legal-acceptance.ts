"use client";

import { supabase } from "@/lib/supabase";
import { SIGN_UP_ACCEPTANCE_SLUGS, type LegalDocument } from "@/lib/legal";

const PENDING_KEY = "plan_e_pending_signup_acceptance";

/** Stashed at sign-up (before the email OTP), flushed once a session exists. */
export function stashSignupAcceptance(): void {
  try {
    localStorage.setItem(
      PENDING_KEY,
      JSON.stringify({ slugs: SIGN_UP_ACCEPTANCE_SLUGS, at: new Date().toISOString() }),
    );
  } catch {
    /* private mode / storage disabled — acceptance line still shown, re-prompt covers it */
  }
}

/** Writes any stashed sign-up acceptances now that the user is signed in. */
export async function flushPendingAcceptances(): Promise<void> {
  let raw: string | null = null;
  try {
    raw = localStorage.getItem(PENDING_KEY);
  } catch {
    return;
  }
  if (!raw) return;
  try {
    const { slugs, at } = JSON.parse(raw) as { slugs: string[]; at?: string };
    await recordAcceptances(slugs, { acceptedAt: at });
    localStorage.removeItem(PENDING_KEY);
  } catch {
    /* leave the marker; the next sign-in retries */
  }
}

/**
 * Writes one `legal_acceptances` row per slug, against each slug's CURRENT
 * document version. Requires an authenticated session (RLS enforces
 * `user_id = auth.uid()`).
 *
 * Idempotent: `upsert` + `ignoreDuplicates` so a retry or a double-submit does
 * not error on the unique constraint.
 */
export async function recordAcceptances(
  slugs: string[],
  opts: { bookingId?: string; acceptedAt?: string } = {},
): Promise<void> {
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) throw new Error("Not signed in");

  const { data: docs, error: docErr } = await supabase
    .from("legal_documents")
    .select("id, slug")
    .eq("is_current", true)
    .eq("locale", "en")
    .in("slug", slugs);
  if (docErr) throw docErr;

  const bySlug = new Map((docs ?? []).map((d) => [d.slug, d.id]));
  const rows = slugs
    .map((slug) => bySlug.get(slug))
    .filter((id): id is string => Boolean(id))
    .map((document_id) => ({
      user_id: user.id,
      document_id,
      booking_id: opts.bookingId ?? null,
      client: "web" as const,
      ...(opts.acceptedAt ? { accepted_at: opts.acceptedAt } : {}),
    }));

  if (rows.length === 0) return;

  const { error } = await supabase
    .from("legal_acceptances")
    .upsert(rows, {
      onConflict: "user_id,document_id,booking_id",
      ignoreDuplicates: true,
    });
  if (error) throw error;
}

/** Current `requires_acceptance` docs this user has not accepted at their
 * current version. Empty on any failure (fail open). */
export async function outstandingReacceptances(): Promise<LegalDocument[]> {
  try {
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) return [];

    const [{ data: docs }, { data: accepted }] = await Promise.all([
      supabase
        .from("legal_documents")
        .select("*")
        .eq("is_current", true)
        .eq("locale", "en")
        .eq("requires_acceptance", true),
      supabase.from("legal_acceptances").select("document_id").eq("user_id", user.id),
    ]);

    const acceptedIds = new Set((accepted ?? []).map((a) => a.document_id));
    return ((docs as LegalDocument[] | null) ?? []).filter(
      (d) => !acceptedIds.has(d.id),
    );
  } catch {
    return [];
  }
}
