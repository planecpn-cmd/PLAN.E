// Host review domain — shared by the API routes and the review screen.
// Mirrors the host_review_decision enum in
// supabase/migrations/20260909120000_host_review_workflow.sql.

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

// decision -> the host_app_status it moves the application to.
export const DECISION_TO_STATUS: Record<Decision, string> = {
  under_review: "under_review",
  approve: "approved",
  reject: "rejected",
  request_changes: "action_required",
};

// A reason is mandatory on anything that is not a plain approval / "start
// review" — matches the plan ("Reason mandatory on anything but approve").
export function reasonRequired(decision: Recommendation | Decision): boolean {
  return decision !== "recommend_approve" && decision !== "approve" && decision !== "under_review";
}

// decision -> notification outcome (null = no host-facing notification)
export function notificationOutcome(
  decision: Decision,
): "approved" | "rejected" | "action_required" | null {
  if (decision === "approve") return "approved";
  if (decision === "reject") return "rejected";
  if (decision === "request_changes") return "action_required";
  return null; // under_review is internal
}
