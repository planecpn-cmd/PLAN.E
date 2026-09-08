import { describe, expect, it, vi } from "vitest";
import { makeWithAdmin, type WithAdminDeps } from "./with-admin";

// GATE 3 suite. The five cases PHASE_1_COMMAND names, plus a couple of
// boundary checks that matter for a security wrapper.

const ACTOR = { userId: "11111111-1111-4111-8111-000000000004", email: "admin@planetest.local" };

function deps(over: Partial<WithAdminDeps> = {}): { d: WithAdminDeps; audits: Record<string, unknown>[] } {
  const audits: Record<string, unknown>[] = [];
  const d: WithAdminDeps = {
    getActor: async () => ACTOR,
    loadStaff: async () => ({ status: "active", scopes: ["content:manage"] }),
    writeAudit: async (row) => {
      audits.push(row);
    },
    db: () => ({ __marker: "service-role" }),
    ...over,
  };
  return { d, audits };
}

const req = (headers: Record<string, string> = {}) =>
  new Request("https://admin.planenepal.com/api/x", { method: "POST", headers });

const ok = () => new Response("ok", { status: 200 });

describe("withAdmin", () => {
  it("no session -> 401, handler never runs, no audit", async () => {
    const { d, audits } = deps({ getActor: async () => null });
    const handler = vi.fn(async () => ok());
    const res = await makeWithAdmin(d)("content:manage", handler, { mutating: true })(req());
    expect(res.status).toBe(401);
    expect(handler).not.toHaveBeenCalled();
    expect(audits).toHaveLength(0);
  });

  it("suspended staff -> 403, handler never runs", async () => {
    const { d } = deps({ loadStaff: async () => ({ status: "suspended", scopes: ["content:manage"] }) });
    const handler = vi.fn(async () => ok());
    const res = await makeWithAdmin(d)("content:manage", handler)(req());
    expect(res.status).toBe(403);
    expect(handler).not.toHaveBeenCalled();
  });

  it("no staff row -> 403", async () => {
    const { d } = deps({ loadStaff: async () => null });
    const res = await makeWithAdmin(d)("content:manage", async () => ok())(req());
    expect(res.status).toBe(403);
  });

  it("wrong scope -> 403, handler never runs", async () => {
    const { d } = deps({ loadStaff: async () => ({ status: "active", scopes: ["bookings:read"] }) });
    const handler = vi.fn(async () => ok());
    const res = await makeWithAdmin(d)("content:manage", handler)(req());
    expect(res.status).toBe(403);
    expect(handler).not.toHaveBeenCalled();
  });

  it("correct scope -> handler runs, gets a service-role db + actor, mutating audit row written", async () => {
    const { d, audits } = deps();
    let seen: { db: unknown; actorUserId: string; requestId: string } | null = null;
    const res = await makeWithAdmin(d)(
      "content:manage",
      async (ctx) => {
        ctx.audit({ action: "feature_flag.toggle", entityType: "feature_flags", entityId: "ai_itinerary", after: { enabled: false }, reason: "kill switch" });
        seen = { db: ctx.db, actorUserId: ctx.actorUserId, requestId: ctx.requestId };
        return Response.json({ ok: true });
      },
      { mutating: true },
    )(req({ "cf-connecting-ip": "203.0.113.7", "user-agent": "vitest" }));

    expect(res.status).toBe(200);
    expect(seen!.db).toEqual({ __marker: "service-role" });
    expect(seen!.actorUserId).toBe(ACTOR.userId);
    expect(seen!.requestId).toMatch(/^[0-9a-f-]{36}$/);

    expect(audits).toHaveLength(1);
    expect(audits[0]).toMatchObject({
      actor_user_id: ACTOR.userId,
      actor_email_snapshot: ACTOR.email,
      scope_used: "content:manage",
      action: "feature_flag.toggle",
      entity_type: "feature_flags",
      entity_id: "ai_itinerary",
      reason: "kill switch",
      ip: "203.0.113.7",
      user_agent: "vitest",
    });
    expect(audits[0].after).toMatchObject({ enabled: false, _outcome: "ok" });
    expect(audits[0].request_id).toBe(seen!.requestId);
  });

  it("handler throws -> the audit row is STILL written (outcome error) and the throw propagates", async () => {
    const { d, audits } = deps();
    await expect(
      makeWithAdmin(d)(
        "content:manage",
        async (ctx) => {
          ctx.audit({ action: "feature_flag.toggle", entityType: "feature_flags", entityId: "x" });
          throw new Error("boom");
        },
        { mutating: true },
      )(req()),
    ).rejects.toThrow("boom");

    expect(audits).toHaveLength(1);
    expect(audits[0]).toMatchObject({ action: "feature_flag.toggle", scope_used: "content:manage" });
    expect(audits[0].after).toMatchObject({ _outcome: "error" });
  });

  it("non-mutating handler writes no audit row", async () => {
    const { d, audits } = deps();
    const res = await makeWithAdmin(d)("content:manage", async () => Response.json({ rows: [] }))(req());
    expect(res.status).toBe(200);
    expect(audits).toHaveLength(0);
  });

  it("a handler that returns >= 400 still audits, with outcome error", async () => {
    const { d, audits } = deps();
    await makeWithAdmin(d)(
      "content:manage",
      async (ctx) => {
        ctx.audit({ action: "feature_flag.toggle" });
        return new Response("bad", { status: 422 });
      },
      { mutating: true },
    )(req());
    expect(audits).toHaveLength(1);
    expect(audits[0].after).toMatchObject({ _outcome: "error" });
  });

  it("the service-role db is not built until session + scope pass", async () => {
    const dbSpy = vi.fn(() => ({ __marker: "service-role" }));
    const { d } = deps({ db: dbSpy, getActor: async () => null });
    await makeWithAdmin(d)("content:manage", async () => ok())(req());
    expect(dbSpy).not.toHaveBeenCalled();
  });
});
