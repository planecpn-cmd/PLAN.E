import { describe, expect, it } from "vitest";
import {
  DECISION_TO_STATUS,
  isDecision,
  isRecommendation,
  notificationOutcome,
  reasonRequired,
} from "./host-review";

describe("host-review domain", () => {
  it("maps decisions to the right host_app_status", () => {
    expect(DECISION_TO_STATUS.approve).toBe("approved");
    expect(DECISION_TO_STATUS.reject).toBe("rejected");
    expect(DECISION_TO_STATUS.request_changes).toBe("action_required");
    expect(DECISION_TO_STATUS.under_review).toBe("under_review");
  });

  it("requires a reason for everything but plain approve / start-review", () => {
    expect(reasonRequired("approve")).toBe(false);
    expect(reasonRequired("recommend_approve")).toBe(false);
    expect(reasonRequired("under_review")).toBe(false);
    expect(reasonRequired("reject")).toBe(true);
    expect(reasonRequired("request_changes")).toBe(true);
    expect(reasonRequired("recommend_reject")).toBe(true);
    expect(reasonRequired("recommend_changes")).toBe(true);
  });

  it("only terminal-ish decisions produce a host-facing notification", () => {
    expect(notificationOutcome("approve")).toBe("approved");
    expect(notificationOutcome("reject")).toBe("rejected");
    expect(notificationOutcome("request_changes")).toBe("action_required");
    expect(notificationOutcome("under_review")).toBeNull();
  });

  it("keeps the recommend / decide vocabularies separate", () => {
    expect(isRecommendation("recommend_approve")).toBe(true);
    expect(isRecommendation("approve")).toBe(false);
    expect(isDecision("approve")).toBe(true);
    expect(isDecision("recommend_approve")).toBe(false);
  });
});
