import { TopNav, BottomNav } from "@/components/Nav";
import { Footer } from "@/components/Footer";
import { LegalAcceptanceManager } from "@/components/legal/LegalAcceptanceManager";

export default function MainLayout({ children }: { children: React.ReactNode }) {
  return (
    <>
      <TopNav />
      <main className="flex-1 pb-24 lg:pb-0">{children}</main>
      <BottomNav />
      <Footer />
      <LegalAcceptanceManager />
    </>
  );
}
