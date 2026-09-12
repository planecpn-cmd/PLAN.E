import { describe, expect, it, vi } from "vitest";
import {
  HOST_DECISION_COPY,
  notifyExperienceDecision,
  notifyHostDecision,
} from "./host-notifications";

// The copy constant is UNFILLED (GATE). Until the founder supplies English +
// Nepali copy + a from-address, the notification path must send nothing and say
// why — never ship placeholder text.

describe("notifyHostDecision", () => {
  it("HOST_DECISION_COPY is still unfilled (the gate)", () => {
    expect(HOST_DECISION_COPY).toBeNull();
  });

  it("sends nothing and touches no table while the copy is unconfigured", async () => {
    const from = vi.fn();
    const db = { from } as unknown as Parameters<typeof notifyHostDecision>[0]["db"];

    const result = await notifyHostDecision({
      db,
      userId: "u1",
      applicationId: "app1",
      outcome: "approved",
    });

    expect(result).toEqual({ sent: false, reason: "copy_unconfigured" });
    expect(from).not.toHaveBeenCalled();
  });

  it("notifyExperienceDecision is gated on the same unfilled copy", async () => {
    const from = vi.fn();
    const db = { from } as unknown as Parameters<typeof notifyExperienceDecision>[0]["db"];

    const result = await notifyExperienceDecision({
      db,
      userId: "u1",
      experienceId: "exp1",
      outcome: "approved",
    });

    expect(result).toEqual({ sent: false, reason: "copy_unconfigured" });
    expect(from).not.toHaveBeenCalled();
  });
});
