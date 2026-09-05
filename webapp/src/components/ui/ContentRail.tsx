import type { ReactNode } from "react";

export function ContentRail({ children }: { children: ReactNode }) {
  return (
    <div className="mt-4 flex gap-4 overflow-x-auto pb-2 lg:grid lg:grid-cols-4 lg:gap-5 lg:overflow-visible">
      {children}
    </div>
  );
}
