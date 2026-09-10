// Shared helpers for the Playwright gates. Reads Supabase with the ANON key
// only: the gates judge what the public site can back up, which is exactly
// what the anon role can see.
import { readFileSync, existsSync } from "node:fs";
import path from "node:path";

function env(name: string): string {
  if (process.env[name]) return process.env[name]!;
  const file = path.join(__dirname, "..", ".env.local");
  if (existsSync(file)) {
    for (const line of readFileSync(file, "utf8").split(/\r?\n/)) {
      const i = line.indexOf("=");
      if (i > 0 && line.slice(0, i).trim() === name) return line.slice(i + 1).trim();
    }
  }
  throw new Error(`${name} is required (env or webapp/.env.local)`);
}

const url = () => env("NEXT_PUBLIC_SUPABASE_URL");
const key = () => env("NEXT_PUBLIC_SUPABASE_ANON_KEY");

/** GET /rest/v1/<path> as anon. Returns null body on 401/403 (not readable). */
export async function anon<T>(p: string): Promise<{ status: number; rows: T[] | null; count: number | null }> {
  const res = await fetch(`${url()}/rest/v1/${p}`, {
    headers: { apikey: key(), Authorization: `Bearer ${key()}`, Prefer: "count=exact" },
  });
  const range = res.headers.get("content-range");
  const count = range && range.includes("/") && range.split("/")[1] !== "*" ? Number(range.split("/")[1]) : null;
  if (res.status === 401 || res.status === 403) return { status: res.status, rows: null, count: 0 };
  if (!res.ok) throw new Error(`anon GET ${p} -> ${res.status} ${await res.text()}`);
  return { status: res.status, rows: (await res.json()) as T[], count };
}

/** Rows the anon role can read in a table; 0 when the table is not readable. */
export async function readableCount(table: string): Promise<number> {
  const r = await anon<unknown>(`${table}?select=*&limit=1`);
  return r.count ?? r.rows?.length ?? 0;
}

/** Departures are Nepal-local calendar dates. */
export function nepalDate(offsetDays = 0): string {
  const d = new Date(Date.now() + offsetDays * 86_400_000);
  return new Intl.DateTimeFormat("en-CA", { timeZone: "Asia/Kathmandu" }).format(d);
}

export type Exp = { id: string; slug: string };
export type Dep = { experience_id: string; start_date: string; spots_left: number; status: string };

export async function publishedExperiences(): Promise<Exp[]> {
  return (await anon<Exp>("experiences?select=id,slug&status=eq.published&order=slug")).rows ?? [];
}

export async function openDepartures(): Promise<Dep[]> {
  return (await anon<Dep>("experience_departures?select=experience_id,start_date,spots_left,status&status=eq.open")).rows ?? [];
}

/** Every route in the current IA, with dynamic slugs resolved from live data. */
export async function iaRoutes(): Promise<string[]> {
  const exps = await publishedExperiences();
  return [
    "/",
    "/explore",
    "/search",
    "/map",
    "/host",
    "/legal",
    "/auth/login",
    "/collection/recommended",
    ...(exps[0] ? [`/experience/${exps[0].slug}`] : []),
  ];
}
