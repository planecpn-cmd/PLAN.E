// Experience review domain — shared by the API routes and the review screen.
// Mirrors the experience_review_decision enum in
// supabase/migrations/20260910120000_experience_review_workflow.sql, and the
// P2 host-application review shape.

export const RECOMMENDATIONS = [
  "recommend_approve",
  "recommend_reject",
  "recommend_changes",
] as const;

export const DECISIONS = [
  "under_review",
  "approve",
  "reject",
  "request_changes",
] as const;

export type Recommendation = (typeof RECOMMENDATIONS)[number];
export type Decision = (typeof DECISIONS)[number];

export function isRecommendation(v: string): v is Recommendation {
  return (RECOMMENDATIONS as readonly string[]).includes(v);
}
export function isDecision(v: string): v is Decision {
  return (DECISIONS as readonly string[]).includes(v);
}

// decision -> the experience_status the listing moves to.
//   approve           -> published
//   reject            -> draft  (host edits, resubmits)
//   request_changes   -> draft  (same status; the review row records the intent)
//   under_review      -> pending_review (unchanged; just stamps a reviewer)
export const DECISION_TO_STATUS: Record<Decision, string> = {
  under_review: "pending_review",
  approve: "published",
  reject: "draft",
  request_changes: "draft",
};

// A reason is mandatory on anything that is not a plain approval / "start
// review" — matches P2 ("Reason mandatory on anything but approve").
export function reasonRequired(decision: Recommendation | Decision): boolean {
  return (
    decision !== "recommend_approve" &&
    decision !== "approve" &&
    decision !== "under_review"
  );
}

// decision -> host-facing notification outcome (null = internal, no notification)
export function notificationOutcome(
  decision: Decision,
): "approved" | "rejected" | "action_required" | null {
  if (decision === "approve") return "approved";
  if (decision === "reject") return "rejected";
  if (decision === "request_changes") return "action_required";
  return null;
}

export const DIFFICULTIES = [
  "easy",
  "moderate",
  "challenging",
  "strenuous",
] as const;
export type Difficulty = (typeof DIFFICULTIES)[number];
export function isDifficulty(v: string): v is Difficulty {
  return (DIFFICULTIES as readonly string[]).includes(v);
}

// A private experience-photos path (host_id/key/file) vs an already-public URL.
export function isPrivatePhotoPath(value: string): boolean {
  return value.length > 0 && !/^https?:\/\//i.test(value);
}

// copy-on-approve: map each private path to its promoted public URL, order
// preserved; anything already public passes through untouched.
export function promotedGallery(
  source: string[],
  publicUrlFor: (path: string) => string,
): string[] {
  return source.map((p) => (isPrivatePhotoPath(p) ? publicUrlFor(p) : p));
}
