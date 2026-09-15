"use client";

import Image from "next/image";
import { motion } from "framer-motion";
import { Compass } from "lucide-react";
import { SearchBar } from "@/components/SearchBar";

// Ported from OrbitalHero (source design): full-bleed photo, dark scrim, gold
// accent badge, kinetic headline entrance. The source's destination-orbit
// selector needed five different real place photos (Everest/Annapurna/
// Mardi/Pokhara/Chitwan) with no verifiable provenance in this repo - not
// ported. This uses the same real, already-approved hero photo the rest of
// the site uses (/brand/home-hero.webp), not a stock substitute.
export function Hero() {
  return (
    <section className="relative flex min-h-[92vh] w-full items-center overflow-hidden bg-[var(--m-forest-dark)]">
      <div className="absolute inset-0 z-0">
        <Image
          src="/brand/home-hero.webp"
          alt="Travellers hiking a mountain trail in Nepal"
          fill
          priority
          sizes="100vw"
          className="object-cover"
        />
        <div className="absolute inset-0 bg-gradient-to-r from-black/85 via-black/50 to-transparent" />
        <div className="absolute inset-x-0 top-0 h-36 bg-gradient-to-b from-black/70 to-transparent" />
        <div className="absolute inset-x-0 bottom-0 h-28 bg-gradient-to-t from-[var(--m-forest-dark)] to-transparent" />
      </div>

      <div className="relative z-10 mx-auto w-full max-w-7xl px-4 pb-16 pt-32 sm:px-6 lg:px-8">
        <div className="max-w-2xl space-y-6 text-left">
          <motion.div
            initial={{ opacity: 0, y: -10 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, delay: 0.2 }}
            className="inline-flex items-center gap-2 rounded-full border border-white/20 bg-white/10 px-3.5 py-1.5 text-xs font-semibold uppercase tracking-wider text-white backdrop-blur-md"
          >
            <span className="h-2 w-2 rounded-full bg-[var(--m-gold)]" />
            <span>Plan Your Experiences · Nepal 🇳🇵</span>
          </motion.div>

          <motion.h1
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.7, delay: 0.35 }}
            className="font-m-display text-4xl font-bold leading-[1.08] tracking-tight text-white drop-shadow-2xl sm:text-5xl lg:text-6xl"
          >
            Find your kind of Nepal.
          </motion.h1>

          <motion.p
            initial={{ opacity: 0, y: 15 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, delay: 0.5 }}
            className="max-w-lg text-base font-light leading-relaxed text-white/90 drop-shadow"
          >
            Adventure, culture, people, wellness and experiences worth remembering - all across Nepal.
          </motion.p>

          <motion.div
            initial={{ opacity: 0, y: 15 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, delay: 0.62 }}
            className="max-w-xl pt-1"
          >
            <SearchBar />
          </motion.div>

          <motion.div
            initial={{ opacity: 0, y: 15 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, delay: 0.72 }}
            className="flex flex-wrap items-center gap-3 pt-1 text-xs font-sans text-white/70"
          >
            <span className="flex items-center gap-1.5">
              <Compass className="h-3.5 w-3.5 text-[var(--m-gold)]" />
              <span>Book directly, pay with Khalti &amp; eSewa</span>
            </span>
          </motion.div>
        </div>
      </div>
    </section>
  );
}
