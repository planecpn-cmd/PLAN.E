import type { Metadata } from "next";
import { Playfair_Display, Inter } from "next/font/google";
import "./globals.css";
import { AuthProvider } from "@/lib/AuthProvider";
import { CookieConsent } from "@/components/cookie/CookieConsent";

const playfair = Playfair_Display({
  variable: "--font-playfair",
  subsets: ["latin"],
  weight: ["600", "700"],
});

const inter = Inter({
  variable: "--font-inter",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  metadataBase: new URL("https://planenepal.com"),
  title: {
    default: "PLAN E — Discover experiences across Nepal",
    template: "%s",
  },
  description: "Book treks, homestays, and cultural experiences across Nepal.",
  alternates: { canonical: "/" },
};

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html
      lang="en"
      className={`${playfair.variable} ${inter.variable} h-full antialiased`}
    >
      <body
        className="min-h-full flex flex-col plan-e-background text-[var(--color-ink)]"
        suppressHydrationWarning
      >
        <AuthProvider>{children}</AuthProvider>
        <CookieConsent />
      </body>
    </html>
  );
}
