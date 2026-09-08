import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // The admin panel renders no third-party images.
  images: { remotePatterns: [{ protocol: "https", hostname: "**.supabase.co" }] },
};

export default nextConfig;
