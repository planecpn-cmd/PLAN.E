// Ported from BrandManifesto (source design: centered statement, generous
// vertical rhythm). Copy is N4's already-approved brand_proposition text,
// unchanged - this section restyles it in the new design language, it does
// not introduce new claims.
export function BrandManifesto() {
  return (
    <section className="marketing bg-[var(--m-canvas)] px-4 py-20 text-center sm:py-28 lg:px-6">
      <div className="mx-auto max-w-2xl">
        <p className="font-m-serif text-3xl italic leading-tight text-[var(--m-ink)] sm:text-4xl">
          Nepal isn&apos;t one kind of experience.
        </p>
        <p className="mt-3 font-m-display text-2xl font-bold leading-tight text-[var(--m-forest)] sm:text-3xl">
          Neither are you.
        </p>
      </div>
    </section>
  );
}
