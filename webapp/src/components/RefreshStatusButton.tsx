"use client";

import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/Button";

export function RefreshStatusButton() {
  const router = useRouter();
  return (
    <Button variant="secondary" fullWidth className="mt-4" onClick={() => router.refresh()}>
      I&apos;ve completed payment — refresh status
    </Button>
  );
}
