import { defineConfig, globalIgnores } from "eslint/config";
import nextVitals from "eslint-config-next/core-web-vitals";
import nextTs from "eslint-config-next/typescript";

// The service-role Supabase client bypasses RLS. It must be reachable from
// exactly one module: src/lib/with-admin.server.ts (the withAdmin wiring). Any
// other file importing it fails lint. This is a convenience tripwire — the
// load-bearing enforcement is src/lib/no-service-role-import.test.ts, which
// cannot be silenced with an inline comment.
const banServiceRole = {
  name: "admin/ban-service-role-import",
  rules: {
    "no-restricted-imports": [
      "error",
      {
        patterns: [
          {
            group: [
              "**/service-role",
              "**/lib/service-role",
              "@/lib/service-role",
            ],
            message:
              "Do not import the service-role client. It is reachable only through withAdmin() in src/lib/with-admin.server.ts.",
          },
        ],
      },
    ],
  },
};

const eslintConfig = defineConfig([
  ...nextVitals,
  ...nextTs,
  banServiceRole,
  {
    // with-admin.server.ts is the one legitimate consumer; service-role.ts
    // defines it.
    files: ["src/lib/with-admin.server.ts", "src/lib/service-role.ts"],
    rules: { "no-restricted-imports": "off" },
  },
  globalIgnores([".next/**", "out/**", "build/**", ".open-next/**", "next-env.d.ts"]),
]);

export default eslintConfig;
