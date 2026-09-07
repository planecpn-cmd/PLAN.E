"use client";
/* eslint-disable @next/next/no-img-element */

import { useEffect, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { useAuth } from "@/lib/AuthProvider";
import { supabase } from "@/lib/supabase";
import type { Json } from "@/lib/supabase/database.types";
import { emptyHostDraft, hostTypes, hostingTypes, validateHostStep, type HostDraft } from "@/lib/host-application";

const availability = { regular: "Available regularly", specific_dates: "Specific dates", seasonal: "Seasonal", flexible: "On request / flexible" };
const pricing = { per_person: "Per person", per_group: "Per group", starting_price: "Starting price", custom_quote: "Custom quote" };
const cancellations = { flexible: "Flexible — adaptable for guests", moderate: "Moderate — balanced commitment", strict: "Strict — firm planning commitment", custom: "Custom — explain your policy" };
const inclusions = ["Guide", "Meals", "Transportation", "Accommodation", "Equipment", "Entry fees / permits", "Pickup / drop-off", "Other"];

export default function HostApplicationPage() {
  const { user, loading: authLoading } = useAuth();
  const router = useRouter();
  const [step, setStep] = useState(1);
  const [draft, setDraft] = useState<HostDraft>(emptyHostDraft);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (authLoading) return;
    if (!user) { router.replace("/auth/required?next=/host/application"); return; }
    supabase.from("host_applications").select("current_step,application_data,status").eq("user_id", user.id).maybeSingle()
      .then(({ data }) => {
        if (data?.application_data && typeof data.application_data === "object")
          setDraft({ ...emptyHostDraft, email: user.email ?? "", ...(data.application_data as unknown as HostDraft) });
        else setDraft({ ...emptyHostDraft, email: user.email ?? "" });
        if (["draft", "action_required", "rejected"].includes(data?.status ?? ""))
          setStep(Math.min(8, Math.max(1, data?.current_step ?? 1)));
        else if (data?.status) router.replace("/host/status");
        setLoading(false);
      });
  }, [authLoading, router, user]);

  function update<K extends keyof HostDraft>(key: K, value: HostDraft[K]) {
    setDraft((current) => ({ ...current, [key]: value }));
  }

  async function upload(field: keyof HostDraft, file?: File, multiple = false) {
    if (!file || !user) return;
    setSaving(true); setError(null);
    const safeName = file.name.replace(/[^A-Za-z0-9._-]/g, "_");
    const path = `${user.id}/${Date.now()}_${safeName}`;
    const { error: uploadError } = await supabase.storage.from("host-documents").upload(path, file);
    if (uploadError) setError("Upload failed. Check the file and try again.");
    else if (multiple) update(field, [...((draft[field] as string[] | undefined) ?? []), path] as HostDraft[typeof field]);
    else update(field, path as HostDraft[typeof field]);
    setSaving(false);
  }

  async function next() {
    const validation = validateHostStep(step, draft, user?.email);
    if (validation) { setError(validation); return; }
    if (!user) return;
    setSaving(true); setError(null);
    if (step === 8) {
      const { error: submitError } = await supabase.functions.invoke("submit-host-application", { body: { applicationData: draft } });
      setSaving(false);
      if (submitError) {
        let message = "Something went wrong while submitting your application. Try again.";
        const response = (submitError as { context?: Response }).context;
        if (response) {
          const payload = await response.clone().json().catch(() => null) as { error?: string } | null;
          if (payload?.error) message = payload.error;
        }
        setError(message);
      }
      else router.push("/host/status");
      return;
    }
    const location = [draft.locality, draft.district, draft.province].filter(Boolean).join(", ");
    const { error: saveError } = await supabase.from("host_applications").upsert({
      user_id: user.id, current_step: step + 1, application_data: draft as unknown as Json,
      title: draft.organization_name ?? draft.hosting_type, description: draft.description,
      location, photos: draft.photo_paths, verification_doc_path: draft.identity_front_path,
    }, { onConflict: "user_id" });
    setSaving(false);
    if (saveError) setError("Something went wrong while saving your application. Try again.");
    else { setStep((value) => value + 1); window.scrollTo({ top: 0, behavior: "smooth" }); }
  }

  if (loading || authLoading) return <div className="mx-auto max-w-3xl px-4 py-20 text-center">Loading your application…</div>;

  return (
    <div className="plan-e-background min-h-screen px-4 py-8 md:py-12">
      <main className={`${step === 8 ? "max-w-4xl" : "max-w-3xl"} mx-auto`}>
        <button onClick={() => step > 1 ? setStep(step - 1) : router.back()} className="min-h-11 font-semibold text-[var(--color-forest)] focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--color-gold)]">← Host Application</button>
        <div className="mt-4" aria-label={`Step ${step} of 8`}>
          <div className="flex justify-between text-sm font-semibold"><span>Step {step} of 8</span><span>{Math.round(step / 8 * 100)}%</span></div>
          <div className="mt-2 h-1.5 overflow-hidden rounded-full bg-[var(--color-sage)]"><div className="h-full bg-[var(--color-forest)]" style={{ width: `${step / 8 * 100}%` }} /></div>
        </div>
        <form className="mt-8" onSubmit={(event) => { event.preventDefault(); void next(); }}>
          <StepContent step={step} draft={draft} update={update} upload={upload} saving={saving} setStep={setStep} />
          {error && <p role="alert" className="mt-5 rounded-[var(--radius-sm)] bg-[var(--color-error-container)] p-3 text-sm font-semibold text-[var(--color-error)]">{error}</p>}
          <div className="sticky bottom-0 mt-8 border-t border-[var(--color-border-subtle)] bg-white/95 py-4 backdrop-blur-sm"><Button type="submit" isLoading={saving} fullWidth>{step === 8 ? "Submit Application" : "Continue"}</Button></div>
        </form>
      </main>
    </div>
  );
}

type Props = { step: number; draft: HostDraft; update: <K extends keyof HostDraft>(key: K, value: HostDraft[K]) => void; upload: (field: keyof HostDraft, file?: File, multiple?: boolean) => Promise<void>; saving: boolean; setStep: (step: number) => void };

function StepContent({ step, draft, update, upload, saving, setStep }: Props) {
  const field = (label: string, key: keyof HostDraft, type = "text", required = false) => <label className="block"><span className="mb-1.5 block text-sm font-semibold">{label}</span><input type={type} required={required} pattern={key === "identity_number" ? "[A-Za-z0-9][A-Za-z0-9 ./-]{2,39}" : undefined} title={key === "identity_number" ? "Use 3–40 letters or numbers; spaces, /, . and - are allowed." : undefined} value={String(draft[key] ?? "")} onChange={(e) => update(key, (type === "number" ? Number(e.target.value) : e.target.value) as never)} className="min-h-12 w-full rounded-[var(--radius-sm)] border border-[var(--color-border)] bg-white px-4 focus:border-[var(--color-forest)] focus:outline-none focus:ring-2 focus:ring-[var(--color-sage)]" />{key === "identity_number" && <span className="mt-1 block text-sm text-[var(--color-ink)]/70">3–40 letters or numbers; spaces, /, . and - are allowed.</span>}{key === "email" && <span className="mt-1 block text-sm text-[var(--color-ink)]/70">Use your account email or, for an organisation, its business email.</span>}</label>;
  const choices = (label: string, key: keyof HostDraft, options: Record<string, string | readonly string[]>) => <fieldset><legend className="sr-only">{label}</legend><div className="grid gap-3 sm:grid-cols-2">{Object.entries(options).map(([value, text]) => { const lines = typeof text === "string" ? [text] : text; return <label key={value} className={`cursor-pointer rounded-[var(--radius-md)] border p-4 transition-colors focus-within:ring-2 focus-within:ring-[var(--color-gold)] ${draft[key] === value ? "border-[var(--color-forest)] bg-[var(--color-sage)]" : "border-[var(--color-border)] bg-white"}`}><input className="sr-only" type="radio" name={String(key)} value={value} checked={draft[key] === value} onChange={() => update(key, value as never)} /><span className="font-semibold text-[var(--color-forest)]">{lines[0]}</span>{lines[1] && <span className="mt-1 block text-sm leading-6">{lines[1]}</span>}</label>; })}</div></fieldset>;
  const uploadField = (label: string, key: keyof HostDraft, multiple = false) => <label className="flex min-h-20 cursor-pointer items-center justify-between rounded-[var(--radius-md)] border border-[var(--color-border)] bg-white p-4 focus-within:ring-2 focus-within:ring-[var(--color-gold)]"><span><strong className="block text-[var(--color-forest)]">{label}</strong><span className="text-sm">{draft[key] ? "Document uploaded — choose to replace" : "Browse JPG, PNG or PDF"}</span></span><input className="sr-only" type="file" accept="image/jpeg,image/png,application/pdf" disabled={saving} onChange={(e) => void upload(key, e.target.files?.[0], multiple)} /></label>;
  const headings = ["", "What would you like to host?", "Tell us about yourself", "Where and how will you host?", "When can guests join?", "What will guests receive?", "Safety & verification", "Show us what you offer", "Review your application"];
  const subtitles = ["", "Choose the type of offering you'd like to bring to Plan E.", "Help us understand who will welcome Plan E travellers.", "Tell us your operating area and comfortable guest capacity.", "Set your usual availability and pricing approach.", "Choose typical inclusions and a cancellation approach.", "We verify hosts to help keep Plan E safe and trustworthy.", "Add clear, authentic photos that help us understand your offering.", "Check your answers before sending them to Plan E."];
  let content: React.ReactNode;
  if (step === 1) content = choices("Hosting type", "hosting_type", hostingTypes);
  else if (step === 2) content = <div className="space-y-4">{choices("Host type", "host_type", hostTypes)}{draft.host_type && <>{field("Full name / representative name", "full_name", "text", true)}{draft.host_type !== "individual" && field("Business / organisation name", "organization_name", "text", true)}{field("Email", "email", "email", true)}{field("Phone", "phone", "tel", true)}</>}</div>;
  else if (step === 3) content = <div className="grid gap-4 sm:grid-cols-2">{field("Province", "province", "text", true)}{field("District / City", "district", "text", true)}<div className="sm:col-span-2">{field("Area / Locality", "locality", "text", true)}</div>{field("Minimum guests", "min_guests", "number", true)}{field("Maximum guests", "max_guests", "number", true)}</div>;
  else if (step === 4) content = <div className="space-y-5">{choices("Availability", "availability_type", availability)}{draft.availability_type === "regular" && <fieldset><legend className="mb-2 font-semibold">Available days</legend><div className="flex flex-wrap gap-2">{["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"].map((day) => <label key={day} className="flex min-h-11 items-center gap-2 rounded-full border border-[var(--color-border)] bg-white px-3"><input type="checkbox" checked={(draft.available_days ?? []).includes(day)} onChange={(e) => update("available_days", e.target.checked ? [...(draft.available_days ?? []), day] : (draft.available_days ?? []).filter((value) => value !== day))} />{day}</label>)}</div></fieldset>}{["specific_dates", "seasonal"].includes(draft.availability_type ?? "") && <div className="grid gap-4 sm:grid-cols-2">{field("Start date", "start_date", "date", true)}{field("End date", "end_date", "date", true)}</div>}{draft.availability_type === "flexible" && field("Availability note", "availability_note")}{choices("Pricing", "pricing_model", pricing)}{draft.pricing_model !== "custom_quote" && <label className="block"><span className="mb-1.5 block text-sm font-semibold">Price (NPR)</span><input type="number" min="1" required value={(draft.price_paisa ?? 0) / 100 || ""} onChange={(e) => update("price_paisa", Math.round(Number(e.target.value) * 100))} className="min-h-12 w-full rounded-[var(--radius-sm)] border border-[var(--color-border)] bg-white px-4 focus:border-[var(--color-forest)] focus:outline-none focus:ring-2 focus:ring-[var(--color-sage)]" /></label>}</div>;
  else if (step === 5) content = <div className="space-y-5"><fieldset><legend className="mb-3 font-semibold">What&apos;s included?</legend><div className="grid gap-2 sm:grid-cols-2">{inclusions.map((item) => <label key={item} className="flex min-h-11 items-center gap-3"><input type="checkbox" checked={draft.included_items.includes(item)} onChange={(e) => update("included_items", e.target.checked ? [...draft.included_items, item] : draft.included_items.filter((value) => value !== item))} />{item}</label>)}</div></fieldset>{choices("Cancellation policy", "cancellation_policy", cancellations)}</div>;
  else if (step === 6) content = <div className="space-y-4">{choices("Identity type", "identity_type", { citizenship: "Citizenship Card", passport: "Passport", driving_licence: "Driving Licence", other: "Other approved ID" })}{field("Document number", "identity_number", "text", true)}{uploadField("Front of identity document", "identity_front_path")}{uploadField("Back of identity document (if applicable)", "identity_back_path")}{draft.host_type !== "individual" && uploadField("Business registration or operating licence", "business_document_paths", true)}{["adventure", "tour_package"].includes(draft.hosting_type ?? "") && uploadField("Guide, safety or tourism certification", "safety_document_paths", true)}</div>;
  else if (step === 7) content = <div className="space-y-4"><label className="block"><span className="mb-1.5 block text-sm font-semibold">Tell us about what you want to host</span><textarea required minLength={20} rows={6} value={draft.description ?? ""} onChange={(e) => update("description", e.target.value)} className="w-full rounded-[var(--radius-sm)] border border-[var(--color-border)] bg-white p-4" /></label>{uploadField("Host / representative photo", "host_photo_path")}{uploadField("Add location or experience photo", "photo_paths", true)}{draft.host_type !== "individual" && uploadField("Business logo (optional)", "business_logo_path")}</div>;
  else content = <div className="space-y-3">{[["Host", `${draft.full_name ?? ""} · ${draft.host_type ? hostTypes[draft.host_type] : ""}`, 2], ["Hosting type", draft.hosting_type ? hostingTypes[draft.hosting_type][0] : "", 1], ["Location", [draft.locality, draft.district, draft.province].filter(Boolean).join(", "), 3], ["Capacity", `${draft.min_guests}–${draft.max_guests} guests`, 3], ["Availability", draft.availability_type ?? "", 4], ["Pricing", draft.pricing_model === "custom_quote" ? "Custom quote" : `NPR ${Math.round((draft.price_paisa ?? 0) / 100)}`, 4], ["Cancellation", draft.cancellation_policy ?? "", 5], ["Document number", draft.identity_number ?? "", 6], ["Verification", draft.identity_front_path ? "Document uploaded" : "Required", 6], ["Photos", `${draft.photo_paths.length} added`, 7]].map(([title, value, edit]) => <Card key={String(title)} className="flex items-center justify-between gap-4"><div><p className="text-xs font-semibold uppercase tracking-wide text-[var(--color-ink)]/60">{title}</p><p className="mt-1">{value}</p></div><button type="button" onClick={() => setStep(Number(edit))} className="font-semibold text-[var(--color-forest)] underline">Edit</button></Card>)}<ReviewUploads draft={draft} /><label className="flex items-start gap-3 py-4"><input className="mt-1" type="checkbox" checked={draft.terms_accepted} onChange={(e) => update("terms_accepted", e.target.checked)} /><span>I agree to Plan E&apos;s <Link href="/legal" className="font-semibold underline">Host Terms, Policies and Terms &amp; Conditions</Link>.</span></label></div>;
  return <><h1 className="font-[family-name:var(--font-display)] text-3xl font-bold text-[var(--color-forest)] md:text-4xl">{headings[step]}</h1><p className="mt-3 text-lg leading-7">{subtitles[step]}</p><div className="mt-7">{content}</div></>;
}

function ReviewUploads({ draft }: { draft: HostDraft }) {
  const files: Array<[string, string]> = [];
  const add = (label: string, value?: string | string[]) => {
    if (typeof value === "string" && value) files.push([label, value]);
    else if (Array.isArray(value)) value.filter(Boolean).forEach((path) => files.push([label, path]));
  };
  add("Identity document — front", draft.identity_front_path);
  add("Identity document — back", draft.identity_back_path);
  add("Business document", draft.business_document_paths);
  add("Safety certificate", draft.safety_document_paths);
  add("Host photo", draft.host_photo_path);
  add("Offering photo", draft.photo_paths);
  add("Business logo", draft.business_logo_path);

  return <section aria-labelledby="review-files"><h2 id="review-files" className="pt-4 text-lg font-bold text-[var(--color-forest)]">Pictures &amp; documents</h2><div className="mt-3 grid gap-3 sm:grid-cols-2">{files.map(([label, path]) => <ReviewFile key={path} label={label} path={path} />)}</div></section>;
}

function ReviewFile({ label, path }: { label: string; path: string }) {
  const [url, setUrl] = useState<string>();
  const isPdf = path.toLowerCase().endsWith(".pdf");
  useEffect(() => {
    let active = true;
    supabase.storage.from("host-documents").createSignedUrl(path, 300).then(({ data }) => {
      if (active) setUrl(data?.signedUrl);
    });
    return () => { active = false; };
  }, [path]);

  return <Card className="overflow-hidden"><p className="text-sm font-bold text-[var(--color-forest)]">{label}</p>{url && !isPdf ? <a href={url} target="_blank" rel="noreferrer" aria-label={`View ${label}`}><img src={url} alt={label} className="mt-3 h-36 w-full rounded-[var(--radius-sm)] object-cover" /></a> : <a href={url} target="_blank" rel="noreferrer" className={`mt-3 flex min-h-24 items-center justify-center rounded-[var(--radius-sm)] bg-[var(--color-sage)] font-semibold ${url ? "" : "pointer-events-none opacity-60"}`}>{url ? "Open PDF" : "Loading preview…"}</a>}</Card>;
}
