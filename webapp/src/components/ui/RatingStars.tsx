export function RatingStars({
  rating,
  reviewCount,
  size = 16,
}: {
  rating: number;
  reviewCount?: number;
  size?: number;
}) {
  return (
    <span className="inline-flex items-center gap-1 text-sm" aria-label={`Rated ${rating.toFixed(1)} out of 5`}>
      <svg width={size} height={size} viewBox="0 0 20 20" fill="var(--color-gold)" aria-hidden="true">
        <path d="M10 1.5l2.6 5.4 5.9.8-4.3 4.1 1 5.9L10 14.9l-5.2 2.8 1-5.9L1.5 7.7l5.9-.8z" />
      </svg>
      <span className="font-medium text-[var(--color-ink)]">{rating.toFixed(1)}</span>
      {typeof reviewCount === "number" && (
        <span className="text-[var(--color-ink)]/70">({reviewCount})</span>
      )}
    </span>
  );
}
