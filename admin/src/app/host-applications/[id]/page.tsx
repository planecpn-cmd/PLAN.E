import Link from "next/link";
import { notFound } from "next/navigation";
import { requireScope } from "@/lib/session";
import { createAnonServerClient } from "@/lib/supabase/server";
import { AdminShell } from "@/components/AdminShell";
import { ReviewPanel } from "@/components/ReviewPanel";

// hosts:review to open. The decision controls inside ReviewPanel switch on
// whether the session also holds hosts:decide.
export default async function HostApplicationDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const session = await requireScope("hosts:review");
  const { id } = await params;
  const supabase = await createAnonServerClient();

  const { data: app } = await supabase.from("host_applications").select("*").eq("id", id).maybeSingle();
  if (!app) notFound();

  const { data: documents } = await supabase
    .from("host_documents")
    .select("id,kind,verified_at,rejection_reason,storage_path")
    .eq("application_id", id)
    .order("kind");

  const { data: reviews } = await supabase
    .from("host_application_reviews")
    .select("id,reviewer_id,from_status,to_status,decision,note,reason_code,created_at")
    .eq("application_id", id)
    .order("created_at", { ascending: false });

  const d = (app.application_data ?? {}) as Record<string, unknown>;
  const fields: [string, unknown][] = [
    ["Full name", d.full_name],
    ["Hosting type", d.hosting_type],
    ["Host type", d.host_type],
    ["Organisation", d.organization_name],
    ["Email", d.email],
    ["Phone", d.phone],
    ["Province / district / locality", [d.province, d.district, d.locality].filter(Boolean).join(" / ")],
    ["Capacity", [d.min_guests, d.max_guests].filter((x) => x != null).join(" – ")],
    ["Availability", d.availability_type],
    ["Pricing model", d.pricing_model],
    ["Cancellation policy", d.cancellation_policy],
    ["Identity type", d.identity_type],
    ["Identity number", d.identity_number],
    ["Description", d.description],
    ["Terms accepted", d.terms_accepted ? "yes" : "no"],
  ];

  return (
    <AdminShell scopes={session.scopes} email={session.email}>
      <Link href="/host-applications" className="text-sm text-[var(--color-ink)]/60 hover:underline">
        ← Queue
      </Link>
      <h1 className="mt-2 text-xl font-bold text-[var(--color-forest)]">
        {(d.full_name as string) || app.title || "Host application"}
      </h1>
      <p className="mt-1 text-sm text-[var(--color-ink)]/60">
        Status:{" "}
        <span className="font-medium">{String(app.status).replace("_", " ")}</span>
        {app.submitted_at && <> · submitted {new Date(app.submitted_at).toLocaleDateString()}</>}
      </p>

      <section className="mt-6">
        <h2 className="text-sm font-semibold uppercase text-[var(--color-ink)]/50">Application</h2>
        <dl className="mt-2 divide-y divide-[var(--color-border-subtle)] rounded-lg border border-[var(--color-border-subtle)] bg-white text-sm">
          {fields.map(([label, value]) => (
            <div key={label} className="grid grid-cols-3 gap-3 px-4 py-2">
              <dt className="text-[var(--color-ink)]/50">{label}</dt>
              <dd className="col-span-2 whitespace-pre-wrap">{value ? String(value) : "—"}</dd>
            </div>
          ))}
        </dl>
      </section>

      <ReviewPanel
        applicationId={id}
        canDecide={session.scopes.includes("hosts:decide")}
        documents={(documents ?? []).map((x) => ({
          id: x.id,
          kind: x.kind,
          verifiedAt: x.verified_at,
          rejectionReason: x.rejection_reason,
        }))}
        reviews={(reviews ?? []).map((r) => ({
          id: r.id,
          reviewerId: r.reviewer_id,
          decision: r.decision,
          note: r.note,
          fromStatus: r.from_status,
          toStatus: r.to_status,
          createdAt: r.created_at,
        }))}
      />
    </AdminShell>
  );
}
