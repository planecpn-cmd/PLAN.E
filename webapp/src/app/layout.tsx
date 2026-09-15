import type { Metadata } from "next";
import { Playfair_Display, Inter, Plus_Jakarta_Sans, Cormorant_Garamond, Outfit } from "next/font/google";
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

// M-PORT: marketing homepage only, scoped under .marketing (globals.css).
// Self-hosted via next/font/google - no Google Fonts hotlink.
const mSans = Plus_Jakarta_Sans({
  variable: "--font-m-sans",
  subsets: ["latin"],
  weight: ["400", "500", "600", "700"],
});

const mSerif = Cormorant_Garamond({
  variable: "--font-m-serif",
  subsets: ["latin"],
  weight: ["500", "600", "700"],
  style: ["normal", "italic"],
});

const mDisplay = Outfit({
  variable: "--font-m-display",
  subsets: ["latin"],
  weight: ["500", "600", "700", "800"],
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

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html
      lang="en"
      className={`${playfair.variable} ${inter.variable} ${mSans.variable} ${mSerif.variable} ${mDisplay.variable} h-full antialiased`}
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
