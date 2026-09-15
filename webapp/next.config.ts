import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  images: {
    remotePatterns: [
      { protocol: "https", hostname: "images.unsplash.com" },
      { protocol: "https", hostname: "**.supabase.co" },
    ],
  },
  // route/split: plans, saved, profile and booking moved under /app/*.
  // Permanent redirects cover bookmarks, and the payment gateway's return
  // URL (supabase/functions/verify-payment-return builds
  // `${WEB_ORIGIN}/booking/confirmation/${id}` server-side) - not edited
  // here, that's a payment-flow change and out of scope for this node.
  async redirects() {
    return [
      { source: "/plans/:path*", destination: "/app/plans/:path*", permanent: true },
      { source: "/saved/:path*", destination: "/app/saved/:path*", permanent: true },
      { source: "/profile/:path*", destination: "/app/profile/:path*", permanent: true },
      { source: "/booking/:path*", destination: "/app/booking/:path*", permanent: true },
    ];
  },
};

export default nextConfig;
