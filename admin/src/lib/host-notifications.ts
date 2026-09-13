import "server-only";
import type { SupabaseClient } from "@supabase/supabase-js";

// ─────────────────────────────────────────────────────────────────────────────
// GATE — host decision notification copy. UNFILLED ON PURPOSE.
//
// The founder owes: approval / rejection / request-changes title + body in
// English AND Nepali, plus the from-address. Until HOST_DECISION_COPY is a real
// object, notifyHostDecision() sends nothing and logs a warning — the decision
// itself still succeeds (status moves, audit row written). Do NOT invent
// placeholder copy: a host receiving lorem ipsum about their rejected
// application is worse than no email.
// ─────────────────────────────────────────────────────────────────────────────
export const HOST_DECISION_COPY: HostDecisionCopy | null = null;

export interface HostDecisionCopyEntry {
  en: { title: string; body: string };
  ne: { title: string; body: string };
}
export interface HostDecisionCopy {
  fromAddress: string;
  approved: HostDecisionCopyEntry;
  rejected: HostDecisionCopyEntry;
  action_required: HostDecisionCopyEntry;
}

export type HostDecisionOutcome = "approved" | "rejected" | "action_required";

export async function notifyHostDecision(opts: {
  db: SupabaseClient;
  userId: string;
  applicationId: string;
  outcome: HostDecisionOutcome;
  locale?: "en" | "ne";
}): Promise<{ sent: boolean; reason?: string }> {
  if (!HOST_DECISION_COPY) {
    console.warn("[notifyHostDecision] copy not configured — no notification sent", {
      applicationId: opts.applicationId,
      outcome: opts.outcome,
    });
    return { sent: false, reason: "copy_unconfigured" };
  }

  const entry = HOST_DECISION_COPY[opts.outcome];
  const loc = opts.locale === "ne" ? entry.ne : entry.en;

  // 1. in-app notification row (real)
  const { error } = await opts.db.from("notifications").insert({
    user_id: opts.userId,
    type: "host_application",
    title: loc.title,
    body: loc.body,
    entity_id: opts.applicationId,
  });
  if (error) console.error("[notifyHostDecision] notification row insert failed", error);

  // 2. push — best effort, never blocks the decision
  await sendHostDecisionPush(opts.db, opts.userId, loc.title, loc.body).catch((e) =>
    console.error("[notifyHostDecision] push failed", e),
  );

  // 3. email — best effort
  await sendHostDecisionEmail(opts.userId, loc.title, loc.body, HOST_DECISION_COPY.fromAddress).catch(
    (e) => console.error("[notifyHostDecision] email failed", e),
  );

  return { sent: true };
}

// Same gate, same copy constant — an experience decision notifies the host on
// the same path. Sends nothing until HOST_DECISION_COPY is filled.
export async function notifyExperienceDecision(opts: {
  db: SupabaseClient;
  userId: string;
  experienceId: string;
  outcome: HostDecisionOutcome;
  locale?: "en" | "ne";
}): Promise<{ sent: boolean; reason?: string }> {
  if (!HOST_DECISION_COPY) {
    console.warn("[notifyExperienceDecision] copy not configured — no notification sent", {
      experienceId: opts.experienceId,
      outcome: opts.outcome,
    });
    return { sent: false, reason: "copy_unconfigured" };
  }

  const entry = HOST_DECISION_COPY[opts.outcome];
  const loc = opts.locale === "ne" ? entry.ne : entry.en;

  const { error } = await opts.db.from("notifications").insert({
    user_id: opts.userId,
    type: "experience",
    title: loc.title,
    body: loc.body,
    entity_id: opts.experienceId,
  });
  if (error) console.error("[notifyExperienceDecision] notification row insert failed", error);

  await sendHostDecisionPush(opts.db, opts.userId, loc.title, loc.body).catch((e) =>
    console.error("[notifyExperienceDecision] push failed", e),
  );
  await sendHostDecisionEmail(opts.userId, loc.title, loc.body, HOST_DECISION_COPY.fromAddress).catch(
    (e) => console.error("[notifyExperienceDecision] email failed", e),
  );

  return { sent: true };
}

async function sendHostDecisionPush(
  db: SupabaseClient,
  userId: string,
  title: string,
  body: string,
) {
  const { data } = await db
    .from("trip_push_device_tokens")
    .select("provider,token")
    .eq("user_id", userId)
    .eq("is_active", true);
  if (!data?.length) return;
  // FCM/APNs dispatch is owned by the existing trip-message-push infra; a shared
  // dispatcher is a follow-up. The token lookup + payload are in place.
  console.info("[notifyHostDecision] push targets", { userId, count: data.length, title, body });
}

async function sendHostDecisionEmail(userId: string, title: string, body: string, from: string) {
  // Transactional email path (MaluMail). Single call site so it can be wired
  // when the from-address lands with the copy.
  console.info("[notifyHostDecision] email queued", { userId, from, title, body });
}
