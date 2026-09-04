import {
  AuthenticationError,
  requireAuthenticatedUser,
} from "./auth.ts";

Deno.test("rejects a request without a bearer token before privileged access", async () => {
  try {
    await requireAuthenticatedUser(new Request("https://example.test"));
    throw new Error("Expected authentication to fail");
  } catch (error) {
    if (!(error instanceof AuthenticationError)) throw error;
  }
});

Deno.test("rejects a non-bearer authorization header", async () => {
  const request = new Request("https://example.test", {
    headers: { Authorization: "Basic dXNlcjpwYXNz" },
  });

  try {
    await requireAuthenticatedUser(request);
    throw new Error("Expected authentication to fail");
  } catch (error) {
    if (!(error instanceof AuthenticationError)) throw error;
  }
});
