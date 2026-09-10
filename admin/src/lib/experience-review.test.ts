import { describe, expect, it } from "vitest";
import {
  DECISION_TO_STATUS,
  isDecision,
  isDifficulty,
  isPrivatePhotoPath,
  isRecommendation,
  notificationOutcome,
  promotedGallery,
  reasonRequired,
} from "./experience-review";

describe("experience-review domain", () => {
  it("maps decisions to the right experience_status", () => {
    expect(DECISION_TO_STATUS.approve).toBe("published");
    expect(DECISION_TO_STATUS.reject).toBe("draft");
    expect(DECISION_TO_STATUS.request_changes).toBe("draft");
    expect(DECISION_TO_STATUS.under_review).toBe("pending_review");
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

  it("only terminal-ish decisions notify the host", () => {
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

  it("validates difficulty against the enum", () => {
    expect(isDifficulty("moderate")).toBe(true);
    expect(isDifficulty("extreme")).toBe(false);
  });

  it("distinguishes a private photo path from a promoted public URL", () => {
    expect(isPrivatePhotoPath("host-1/exp-1/a.jpg")).toBe(true);
    expect(isPrivatePhotoPath("https://x.supabase.co/storage/.../a.jpg")).toBe(false);
    expect(isPrivatePhotoPath("")).toBe(false);
  });

  it("promotedGallery maps private paths to public URLs, order preserved", () => {
    const out = promotedGallery(
      ["h/e/a.jpg", "https://cdn/x/b.jpg", "h/e/c.jpg"],
      (p) => `https://pub/${p}`,
    );
    expect(out).toEqual([
      "https://pub/h/e/a.jpg",
      "https://cdn/x/b.jpg",
      "https://pub/h/e/c.jpg",
    ]);
  });
});
