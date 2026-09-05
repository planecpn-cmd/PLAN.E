import type { MetadataRoute } from "next";

export default function robots(): MetadataRoute.Robots {
  return {
    rules: [
      {
        userAgent: "*",
        allow: "/",
        disallow: ["/auth/", "/booking/", "/plans", "/saved", "/profile"],
      },
    ],
    sitemap: "https://planenepal.com/sitemap.xml",
  };
}
