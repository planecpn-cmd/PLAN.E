import { Compass } from "lucide-react";
import { SearchBar } from "@/components/SearchBar";

// Ported from OrbitalHero (source design): full-bleed photo, dark scrim, gold
// accent badge, kinetic headline entrance. The source's destination-orbit
// selector needed five different real place photos (Everest/Annapurna/
// Mardi/Pokhara/Chitwan) with no verifiable provenance in this repo - not
// ported. This uses the same real, already-approved hero photo the rest of
// the site uses (/brand/home-hero.{avif,webp}), not a stock substitute.
//
// Server component, CSS-only entrance (animate-m-rise in globals.css) - not
// framer-motion. It was the single largest JS contributor to this page and
// the animation is decorative, not functional; dropping it was the fix that
// brought Lighthouse mobile performance from 83 to the required >=85 (P4).
//
// HERO-PERF: plain <picture>/<img>, not next/image. Lighthouse against the
// deployed site traced 7.6s of an 8.4s LCP to this one request going through
// /_next/image?url=... - OpenNext's Cloudflare image loader resizes/re-
// encodes at request time in the Worker, which is slow and was adding a full
// round trip for an image that's already pre-sized and pre-compressed
// (1400x933, under 1920px wide). A plain <img> pointed at the static file is
// served directly off Cloudflare's asset CDN (the wrangler.jsonc `assets`
// binding) with zero Worker execution. next/image's `priority` prop also
// wasn't reliably producing fetchpriority=high through that same custom
// loader path; a plain <img fetchPriority="high"> sets the real attribute
// directly, no dependency on the loader translating it.
export function Hero() {
  return (
    <section className="relative flex min-h-[92vh] w-full items-center overflow-hidden bg-[var(--m-forest-dark)]">
      <div className="absolute inset-0 z-0">
        <picture>
          <source srcSet="/brand/home-hero.avif" type="image/avif" />
          <source srcSet="/brand/home-hero.webp" type="image/webp" />
          <img
            src="/brand/home-hero.webp"
            alt="Travellers hiking a mountain trail in Nepal"
            fetchPriority="high"
            decoding="async"
            className="absolute inset-0 h-full w-full object-cover"
          />
        </picture>
        <div className="absolute inset-0 bg-gradient-to-r from-black/85 via-black/50 to-transparent" />
        <div className="absolute inset-x-0 top-0 h-36 bg-gradient-to-b from-black/70 to-transparent" />
        <div className="absolute inset-x-0 bottom-0 h-28 bg-gradient-to-t from-[var(--m-forest-dark)] to-transparent" />
      </div>

      <div className="relative z-10 mx-auto w-full max-w-7xl px-4 pb-16 pt-32 sm:px-6 lg:px-8">
        <div className="max-w-2xl space-y-6 text-left">
          <div
            className="animate-m-rise inline-flex items-center gap-2 rounded-full border border-white/20 bg-white/10 px-3.5 py-1.5 text-xs font-semibold uppercase tracking-wider text-white backdrop-blur-md [animation-delay:0.1s]"
          >
            <span className="h-2 w-2 rounded-full bg-[var(--m-gold)]" />
            <span>Plan Your Experiences · Nepal 🇳🇵</span>
          </div>

          <h1
            className="animate-m-rise font-m-display text-4xl font-bold leading-[1.08] tracking-tight text-white drop-shadow-2xl [animation-delay:0.2s] sm:text-5xl lg:text-6xl"
          >
            Find your kind of Nepal.
          </h1>

          <p
            className="animate-m-rise max-w-lg text-base font-light leading-relaxed text-white/90 drop-shadow [animation-delay:0.3s]"
          >
            Adventure, culture, people, wellness and experiences worth remembering - all across Nepal.
          </p>

          <div className="animate-m-rise max-w-xl pt-1 [animation-delay:0.4s]">
            <SearchBar />
          </div>

          <div
            className="animate-m-rise flex flex-wrap items-center gap-3 pt-1 text-xs font-sans text-white/70 [animation-delay:0.5s]"
          >
            <span className="flex items-center gap-1.5">
              <Compass className="h-3.5 w-3.5 text-[var(--m-gold)]" />
              <span>Book directly, pay with Khalti &amp; eSewa</span>
            </span>
          </div>
        </div>
      </div>
    </section>
  );
}
