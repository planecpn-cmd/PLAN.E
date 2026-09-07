import Image from "next/image";
import Link from "next/link";
import { Icon, type IconName } from "@/components/ui/Icon";
import { createClient } from "@/lib/supabase/server";

const categories: { label: string; icon: IconName }[] = [
  { label: "Adventure", icon: "terrain" },
  { label: "Stay", icon: "home" },
  { label: "Experience", icon: "lightbulb" },
  { label: "Tours", icon: "route" },
  { label: "Community", icon: "people" },
];

const benefits: { title: string; description: string; icon: IconName }[] = [
  {
    title: "Reach travellers",
    description: "Get discovered by people looking for meaningful experiences.",
    icon: "compass",
  },
  {
    title: "Manage bookings",
    description: "Keep requests and availability organised.",
    icon: "calendar",
  },
  {
    title: "Grow with Plan E",
    description: "Build trust through quality experiences and reviews.",
    icon: "star",
  },
];

const steps = [
  ["01", "Apply", "Tell us about yourself and what you want to host."],
  ["02", "Get verified", "Plan E reviews your host application."],
  ["03", "Start hosting", "Create listings after your host profile is approved."],
] as const;

async function getCta() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { label: "Start Host Application", href: "/host/application" };

  const [{ data: application }, { data: profile }] = await Promise.all([
    supabase.from("host_applications").select("status,current_step").eq("user_id", user.id).maybeSingle(),
    supabase.from("profiles").select("role").eq("id", user.id).maybeSingle(),
  ]);
  if (profile?.role === "host" || application?.status === "approved") {
    return { label: "Go to Host Dashboard", href: "/host/dashboard" };
  }
  if (["submitted", "under_review", "verification"].includes(application?.status ?? "")) {
    return { label: "View Application Status", href: "/host/status" };
  }
  if (application) return { label: "Continue Application", href: "/host/application" };
  return { label: "Start Host Application", href: "/host/application" };
}

export default async function BecomeHostPage() {
  const cta = await getCta();

  return (
    <div className="bg-[var(--color-ivory)]">
      <section className="mx-auto grid max-w-[1280px] lg:min-h-[620px] lg:grid-cols-[0.88fr_1.12fr] lg:items-stretch">
        <div className="order-2 flex items-center px-4 py-10 sm:px-8 lg:order-1 lg:px-12 lg:py-16 xl:px-20">
          <div className="max-w-xl">
            <p className="text-xs font-bold uppercase tracking-[0.2em] text-[var(--color-gold)]">Become a Host</p>
            <h1 className="mt-4 font-[family-name:var(--font-display)] text-4xl font-bold leading-[1.08] text-[var(--color-forest)] sm:text-5xl xl:text-6xl">
              Share what you know.<br />Host with Plan E.
            </h1>
            <p className="mt-5 max-w-lg text-base leading-7 text-[var(--color-ink)]/80 sm:text-lg sm:leading-8">
              Turn your knowledge, place or passion into an experience travellers can discover.
            </p>
            <Link
              href={cta.href}
              className="mt-7 inline-flex min-h-12 items-center justify-center gap-2 rounded-[var(--radius-pill)] bg-[var(--color-forest)] px-6 py-3 text-[15px] font-semibold text-white transition-colors hover:bg-[var(--color-deep)] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--color-gold)]"
            >
              {cta.label}<span aria-hidden="true">→</span>
            </Link>
          </div>
        </div>
        <div className="relative order-1 h-[46svh] min-h-[340px] overflow-hidden lg:order-2 lg:h-auto lg:min-h-[620px] lg:rounded-bl-[var(--radius-lg)]">
          <Image
            src="/brand/host-potter.webp"
            alt="A Nepalese pottery host shaping a clay vessel"
            fill
            priority
            sizes="(min-width: 1024px) 56vw, 100vw"
            className="object-cover object-[center_28%]"
          />
          <div className="absolute inset-0 bg-gradient-to-t from-[rgba(1,37,28,0.45)] via-transparent to-transparent lg:hidden" aria-hidden="true" />
        </div>
      </section>

      <div className="mx-auto max-w-6xl px-4 py-12 sm:px-6 lg:py-20">
        <section aria-labelledby="host-categories">
          <h2 id="host-categories" className="font-[family-name:var(--font-display)] text-2xl font-bold text-[var(--color-forest)] sm:text-3xl">What can you host?</h2>
          <ul className="mt-5 flex flex-wrap gap-2.5">
            {categories.map((category) => (
              <li key={category.label} className="flex min-h-11 items-center gap-2 rounded-[var(--radius-pill)] bg-[var(--color-sage)] px-4 font-semibold text-[var(--color-forest)]">
                <Icon name={category.icon} size={18} />{category.label}
              </li>
            ))}
          </ul>
        </section>

        <section className="mt-14 lg:mt-20" aria-labelledby="host-benefits">
          <h2 id="host-benefits" className="font-[family-name:var(--font-display)] text-2xl font-bold text-[var(--color-forest)] sm:text-3xl">Why host with Plan E?</h2>
          <div className="mt-7 grid gap-7 md:grid-cols-3 md:gap-10">
            {benefits.map((benefit) => (
              <div key={benefit.title} className="flex gap-4 md:block">
                <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-[var(--radius-sm)] bg-[var(--color-sage)] text-[var(--color-forest)] md:mb-4">
                  <Icon name={benefit.icon} size={22} />
                </div>
                <div>
                  <h3 className="font-bold text-[var(--color-forest)]">{benefit.title}</h3>
                  <p className="mt-1 max-w-sm text-sm leading-6 text-[var(--color-ink)]/75">{benefit.description}</p>
                </div>
              </div>
            ))}
          </div>
        </section>

        <section className="mt-14 lg:mt-20" aria-labelledby="host-process">
          <h2 id="host-process" className="font-[family-name:var(--font-display)] text-2xl font-bold text-[var(--color-forest)] sm:text-3xl">How it works</h2>
          <ol className="mt-7 grid gap-7 md:grid-cols-3 md:gap-0">
            {steps.map(([number, title, description], index) => (
              <li key={number} className="relative flex gap-4 md:block md:pr-10">
                {index < steps.length - 1 && <div className="absolute left-8 right-0 top-4 hidden h-px bg-[var(--color-border)] md:block" aria-hidden="true" />}
                <span className="relative z-10 flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-[var(--color-ivory)] text-xs font-extrabold tracking-wide text-[var(--color-gold)] ring-1 ring-[var(--color-border)]">{number}</span>
                <div className="md:mt-4">
                  <h3 className="font-bold text-[var(--color-forest)]">{title}</h3>
                  <p className="mt-1 max-w-xs text-sm leading-6 text-[var(--color-ink)]/75">{description}</p>
                </div>
              </li>
            ))}
          </ol>
        </section>

        <div className="mt-14 flex items-center gap-3 rounded-[var(--radius-md)] bg-[var(--color-sage)] px-4 py-4 font-semibold text-[var(--color-forest)] lg:mt-20 lg:w-fit lg:px-5">
          <Icon name="shield" size={22} />
          <p>Hosts are verified by Plan E before publishing.</p>
        </div>
      </div>
    </div>
  );
}
