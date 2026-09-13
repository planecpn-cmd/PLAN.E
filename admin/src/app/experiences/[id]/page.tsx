import Link from "next/link";
import { notFound } from "next/navigation";
import { requireAnyScope } from "@/lib/session";
import { createAnonServerClient } from "@/lib/supabase/server";
import { AdminShell } from "@/components/AdminShell";
import { ExperienceReviewPanel } from "@/components/ExperienceReviewPanel";

// content:manage OR content:decide opens the page (a content:decide-only
// account needs to see the listing to decide on it). The panel itself
// still switches which controls render on whether the session holds
// content:decide specifically — recommend vs. decide, not page access.
export default async function ExperienceReviewDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const session = await requireAnyScope(["content:manage", "content:decide"]);
  const { id } = await params;
  const supabase = await createAnonServerClient();

  const { data: exp } = await supabase.from("experiences").select("*").eq("id", id).maybeSingle();
  if (!exp) notFound();

  // A revision inherits its live listing's taxonomy as the panel defaults —
  // the revision row itself carries none.
  let taxonomyFrom = exp;
  if (exp.revision_of) {
    const { data: live } = await supabase
      .from("experiences")
      .select("category_id,region_id,difficulty")
      .eq("id", exp.revision_of)
      .maybeSingle();
    if (live) taxonomyFrom = { ...exp, ...live };
  }

  const [{ data: departures }, { data: itinerary }, { data: reviews }, { data: categories }, { data: regions }] =
    await Promise.all([
      supabase
        .from("experience_departures")
        .select("id,start_date,end_date,total_spots,spots_left,status")
        .eq("experience_id", id)
        .order("start_date"),
      supabase
        .from("itinerary_items")
        .select("day_number,title,description")
        .eq("experience_id", id)
        .order("day_number"),
      supabase
        .from("experience_reviews")
        .select("id,reviewer_id,from_status,to_status,decision,note,reason_code,created_at")
        .eq("experience_id", id)
        .order("created_at", { ascending: false }),
      supabase.from("categories").select("id,name_en").order("name_en"),
      supabase.from("regions").select("id,name_en").order("name_en"),
    ]);

  const gallery: string[] = Array.isArray(exp.gallery) ? exp.gallery : [];
  const fields: [string, unknown][] = [
    ["Title", exp.title],
    ["Summary", exp.summary],
    ["Description", exp.description],
    ["Location", exp.location_name],
    ["Meeting point", exp.meeting_point],
    ["Price (NPR)", exp.price_paisa != null ? Math.round(exp.price_paisa / 100) : null],
    ["Capacity", exp.group_size_max],
    ["Included", (exp.included as string[] | null)?.join(", ")],
    ["Bring", (exp.bring_list as string[] | null)?.join(", ")],
    ["Trip details", (exp.things_to_know as string[] | null)?.join(" · ")],
  ];

  return (
    <AdminShell scopes={session.scopes} email={session.email}>
      <Link href="/experiences" className="text-sm text-[var(--color-ink)]/60 hover:underline">
        ← Queue
      </Link>
      <h1 className="mt-2 text-xl font-bold text-[var(--color-forest)]">
        {exp.title || "Experience"}
      </h1>
      <p className="mt-1 text-sm text-[var(--color-ink)]/60">
        Status: <span className="font-medium">{String(exp.status).replace("_", " ")}</span>
        {exp.updated_at && <> · updated {new Date(exp.updated_at).toLocaleDateString()}</>}
      </p>
      {exp.revision_of && (
        <p className="mt-2 rounded-md bg-[var(--color-sage)] px-3 py-2 text-sm">
          These are <strong>proposed changes</strong> to a live listing. The live version stays
          published and unchanged until you approve — approving swaps this content in atomically.
        </p>
      )}

      <section className="mt-6">
        <h2 className="text-sm font-semibold uppercase text-[var(--color-ink)]/50">Submitted listing</h2>
        <dl className="mt-2 divide-y divide-[var(--color-border-subtle)] rounded-lg border border-[var(--color-border-subtle)] bg-white text-sm">
          {fields.map(([label, value]) => (
            <div key={label} className="grid grid-cols-3 gap-3 px-4 py-2">
              <dt className="text-[var(--color-ink)]/50">{label}</dt>
              <dd className="col-span-2 whitespace-pre-wrap">{value ? String(value) : "—"}</dd>
            </div>
          ))}
        </dl>
      </section>

      {(departures ?? []).length > 0 && (
        <section className="mt-6">
          <h2 className="text-sm font-semibold uppercase text-[var(--color-ink)]/50">Departure</h2>
          <ul className="mt-2 space-y-1 text-sm">
            {(departures ?? []).map((d) => (
              <li key={d.id} className="rounded border border-[var(--color-border-subtle)] bg-white px-3 py-2">
                {d.start_date} → {d.end_date} · {d.total_spots} spots ({d.spots_left} left) · {d.status}
              </li>
            ))}
          </ul>
        </section>
      )}

      {(itinerary ?? []).length > 0 && (
        <section className="mt-6">
          <h2 className="text-sm font-semibold uppercase text-[var(--color-ink)]/50">Itinerary</h2>
          <ol className="mt-2 space-y-1 text-sm">
            {(itinerary ?? []).map((it, i) => (
              <li key={i} className="rounded border border-[var(--color-border-subtle)] bg-white px-3 py-2">
                <span className="font-medium">Day {it.day_number}</span> — {it.title}
              </li>
            ))}
          </ol>
        </section>
      )}

      <ExperienceReviewPanel
        experienceId={id}
        status={exp.status as string}
        canDecide={session.scopes.includes("content:decide")}
        photoPaths={gallery}
        currentCategoryId={(taxonomyFrom.category_id as string | null) ?? ""}
        currentRegionId={(taxonomyFrom.region_id as string | null) ?? ""}
        currentDifficulty={(taxonomyFrom.difficulty as string | null) ?? "moderate"}
        categories={(categories ?? []).map((c) => ({ id: c.id, name: c.name_en }))}
        regions={(regions ?? []).map((r) => ({ id: r.id, name: r.name_en }))}
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
