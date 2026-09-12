import "server-only";
import type { Scope } from "./scopes";

// `DB` is the service-role client type. with-admin.ts stays dependency-free, so
// it is `unknown` here; with-admin.server.ts binds it to a real SupabaseClient.

// ─────────────────────────────────────────────────────────────────────────────
// withAdmin — the single security boundary for the whole panel.
//
// For every admin data access, in order, every time:
//   1. verify the Supabase session JWT server-side          -> no session: 401
//   2. load the staff_members row                           -> none / suspended: 403
//   3. check the required scope is present                  -> missing: 403
//   4. build AdminContext (service-role db reachable ONLY here)
//   5. run the handler
//   6. for a mutating handler, write an admin_audit_log row — even if the
//      handler threw.
//
// This file is dependency-free so it is unit-testable without Next or Supabase.
// The real wiring (session + service-role client + audit insert) lives in
// with-admin.server.ts.
// ─────────────────────────────────────────────────────────────────────────────

export interface AdminActor {
  userId: string;
  email: string | null;
}

export interface StaffRecord {
  status: "active" | "suspended";
  scopes: string[];
}

export interface AdminAuditEntry {
  action: string;
  entityType?: string | null;
  entityId?: string | null;
  before?: unknown;
  after?: unknown;
  reason?: string | null;
}

export interface AdminContext<DB = unknown> {
  actorUserId: string;
  actorEmail: string | null;
  scopes: string[];
  requestId: string;
  ip: string | null;
  userAgent: string | null;
  /** service-role client — bypasses RLS; reachable only via this context */
  db: DB;
  /** record the audit payload for this request; withAdmin flushes it */
  audit(entry: AdminAuditEntry): void;
}

export interface WithAdminOptions {
  /** when true, an admin_audit_log row is always written (including on throw) */
  mutating?: boolean;
  /** fallback action label if the handler does not call ctx.audit() */
  action?: string;
}

export type AdminHandler<DB = unknown> = (ctx: AdminContext<DB>) => Promise<Response>;

/** Injectable dependencies — real wiring in with-admin.server.ts; tests pass fakes. */
export interface WithAdminDeps<DB = unknown> {
  getActor(req: Request): Promise<AdminActor | null>;
  loadStaff(userId: string): Promise<StaffRecord | null>;
  writeAudit(row: Record<string, unknown>): Promise<void>;
  db(): DB;
}

function json(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json" },
  });
}

export function makeWithAdmin<DB = unknown>(deps: WithAdminDeps<DB>) {
  return function withAdmin(
    scope: Scope,
    handler: AdminHandler<DB>,
    opts: WithAdminOptions = {},
  ) {
    return async function route(req: Request): Promise<Response> {
      const requestId = crypto.randomUUID();
      const ip =
        req.headers.get("cf-connecting-ip") ??
        req.headers.get("x-forwarded-for") ??
        null;
      const userAgent = req.headers.get("user-agent") ?? null;

      // 1. session
      const actor = await deps.getActor(req);
      if (!actor) {
        console.warn("[withAdmin] 401", {
          scope, action: opts.action, requestId, outcome: "no_session",
        });
        return json(401, { error: "authentication required" });
      }

      // 2. staff record
      const staff = await deps.loadStaff(actor.userId);
      if (!staff || staff.status === "suspended") {
        console.warn("[withAdmin] 403", {
          actorUserId: actor.userId, scope, action: opts.action, requestId,
          outcome: staff ? "suspended" : "not_staff",
        });
        return json(403, { error: "not authorized" });
      }

      // 3. scope
      if (!staff.scopes.includes(scope)) {
        console.warn("[withAdmin] 403", {
          actorUserId: actor.userId, scope, action: opts.action, requestId,
          outcome: "missing_scope", have: staff.scopes,
        });
        return json(403, { error: "not authorized" });
      }

      // 4. context. `audit()` mutates a captured cell; a plain `let` here gets
      // narrowed to `null` by control-flow analysis (it can't see the closure
      // write), so keep the payload on an object and read it back through an
      // explicitly typed local in the finally / catch blocks.
      const audited: { payload: AdminAuditEntry | null } = { payload: null };
      const ctx: AdminContext<DB> = {
        actorUserId: actor.userId,
        actorEmail: actor.email,
        scopes: staff.scopes,
        requestId,
        ip,
        userAgent,
        db: deps.db(),
        audit(entry) {
          audited.payload = entry;
        },
      };

      // 5. run + 6. audit
      let outcome: "ok" | "error" = "ok";
      try {
        const response = await handler(ctx);
        if (response.status >= 400) outcome = "error";
        return response;
      } catch (err) {
        outcome = "error";
        const p: AdminAuditEntry | null = audited.payload;
        console.error("[withAdmin] handler threw", {
          actorUserId: actor.userId, scope,
          action: p?.action ?? opts.action, requestId, err,
        });
        throw err;
      } finally {
        if (opts.mutating) {
          const p: AdminAuditEntry | null = audited.payload;
          const baseAfter =
            p?.after && typeof p.after === "object"
              ? (p.after as Record<string, unknown>)
              : {};
          try {
            await deps.writeAudit({
              actor_user_id: actor.userId,
              actor_email_snapshot: actor.email,
              scope_used: scope,
              action: p?.action ?? opts.action ?? "unknown",
              entity_type: p?.entityType ?? null,
              entity_id: p?.entityId ?? null,
              before: p?.before ?? null,
              after: { ...baseAfter, _outcome: outcome },
              reason: p?.reason ?? null,
              ip,
              user_agent: userAgent,
              request_id: requestId,
            });
          } catch (auditErr) {
            console.error("[withAdmin] AUDIT WRITE FAILED", { requestId, auditErr });
          }
        }
      }
    };
  };
}
