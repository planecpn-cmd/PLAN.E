import { ExperienceCardSkeleton } from "@/components/ui/Skeleton";

export default function Loading() {
  return (
    <div className="mx-auto max-w-6xl px-4 py-6 lg:px-6 lg:py-10">
      <div className="grid gap-8 lg:grid-cols-[280px_1fr]">
        <div className="hidden lg:block" />
        <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-3">
          {Array.from({ length: 6 }).map((_, i) => (
            <ExperienceCardSkeleton key={i} />
          ))}
        </div>
      </div>
    </div>
  );
}
