import Image from "next/image";
import { getHomepageData, isSectionEnabled } from "@/lib/data/homepage";
import { SearchBar } from "@/components/SearchBar";

export const revalidate = 300;

export default async function HomePage() {
  await getHomepageData();

  return (
    <div>
      {isSectionEnabled("hero") && (
        <section className="relative h-[300px] overflow-hidden lg:h-[340px]">
          <Image
            src="/brand/home-hero.webp"
            alt="Travellers hiking a mountain trail in Nepal"
            fill
            priority
            sizes="100vw"
            className="object-cover object-left"
          />
          <div
            className="absolute inset-0"
            style={{
              background:
                "linear-gradient(to bottom, rgba(0,0,0,0.55) 0%, rgba(0,0,0,0.15) 22%, rgba(0,22,15,0.72) 78%, var(--color-ivory) 100%)",
            }}
          />

          <div className="absolute inset-x-0 bottom-0 px-4 pb-6 lg:px-6 lg:pb-8">
            <div className="mx-auto max-w-6xl">
              <h1 className="max-w-xl font-[family-name:var(--font-display)] text-2xl font-bold leading-[1.05] text-white [text-shadow:0_2px_12px_rgba(0,0,0,0.6)] lg:text-4xl">
                Find your kind of Nepal.
              </h1>
              <p className="mt-2 max-w-lg text-sm text-white/90 [text-shadow:0_1px_8px_rgba(0,0,0,0.5)] lg:text-base">
                Adventure, culture, people, wellness and experiences worth remembering - all across Nepal.
              </p>
              <div className="mt-4 max-w-lg">
                <SearchBar />
              </div>
            </div>
          </div>
        </section>
      )}

      {isSectionEnabled("brand_proposition") && (
        <section className="mx-auto max-w-3xl px-4 py-14 text-center lg:px-6 lg:py-20">
          <p className="font-[family-name:var(--font-display)] text-2xl font-bold leading-tight text-[var(--color-ink)] lg:text-3xl">
            Nepal isn&apos;t one kind of experience.
          </p>
          <p className="mt-2 font-[family-name:var(--font-display)] text-2xl font-bold leading-tight text-[var(--color-forest)] lg:text-3xl">
            Neither are you.
          </p>
        </section>
      )}
    </div>
  );
}
