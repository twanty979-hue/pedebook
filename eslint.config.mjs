import { defineConfig, globalIgnores } from "eslint/config";
import nextVitals from "eslint-config-next/core-web-vitals";
import nextTs from "eslint-config-next/typescript";

const eslintConfig = defineConfig([
  ...nextVitals,
  ...nextTs,
  // File-specific overrides for pre-existing legacy code issues.
  // Standard rules are enforced globally on all new SEO work.
  {
    files: ["app/api/pdf-proxy/route.ts"],
    rules: {
      "@typescript-eslint/no-explicit-any": "off", // Legacy: backend handles untyped external payloads
    }
  },
  {
    files: ["app/catalog/*/page.tsx"],
    rules: {
      "@typescript-eslint/no-explicit-any": "off", // Legacy: route parameters and Firebase integration typed as any
      "react-hooks/purity": "off", // Legacy: uses external functions/side-effects directly in page body
    }
  },
  {
    files: ["app/components/EbookViewer.tsx"],
    rules: {
      "@typescript-eslint/no-explicit-any": "off", // Legacy: heavily relies on PDFJS legacy types/untyped interfaces
      "react-hooks/set-state-in-effect": "off", // Legacy: synchronizes pages and dimensions state in effects
      "@typescript-eslint/ban-ts-comment": "off", // Legacy: legacy PDFJS workaround requires ts-ignore
    }
  },
  {
    files: ["app/dashboard/page.tsx"],
    rules: {
      "react-hooks/set-state-in-effect": "off", // Legacy: updates user and books lists from authentication listener effects
      "@next/next/no-html-link-for-pages": "off", // Legacy: contains logout <a> links
    }
  },
  {
    files: ["app/login/page.tsx"],
    rules: {
      "@typescript-eslint/no-explicit-any": "off", // Legacy: Firebase auth error handling uses generic error objects
      "@next/next/no-html-link-for-pages": "off", // Legacy: contains redirect links to dashboard/pages
    }
  },
  // Override default ignores of eslint-config-next.
  globalIgnores([
    // Default ignores of eslint-config-next:
    ".next/**",
    "out/**",
    "build/**",
    "next-env.d.ts",
    "public/pdf.worker.min.mjs",
  ]),
]);

export default eslintConfig;
