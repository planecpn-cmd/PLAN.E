import {
  createPaymentRedirectToken,
  hashPaymentRedirectToken,
} from "./payment_redirect_token.ts";

Deno.test("creates URL-safe 256-bit payment redirect tokens", () => {
  const first = createPaymentRedirectToken();
  const second = createPaymentRedirectToken();

  if (!/^[A-Za-z0-9_-]{43}$/.test(first)) throw new Error("Token is not URL-safe");
  if (first === second) throw new Error("Expected independently generated tokens");
});

Deno.test("hashes payment redirect tokens with SHA-256", async () => {
  const hash = await hashPaymentRedirectToken("test");
  if (hash !== "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08") {
    throw new Error("Unexpected SHA-256 digest");
  }
});
