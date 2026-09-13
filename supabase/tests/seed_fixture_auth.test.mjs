import assert from "node:assert/strict";
import test from "node:test";

const baseUrl = process.env.SUPABASE_URL ?? "http://127.0.0.1:54341";
const anonKey = process.env.SUPABASE_ANON_KEY;
const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!anonKey || !serviceKey) {
  throw new Error("SUPABASE_ANON_KEY and SUPABASE_SERVICE_ROLE_KEY are required");
}

const serviceHeaders = {
  apikey: serviceKey,
  Authorization: `Bearer ${serviceKey}`,
  "Content-Type": "application/json",
};

async function jsonRequest(url, options = {}) {
  const response = await fetch(url, options);
  const text = await response.text();
  let body = null;
  try {
    body = text ? JSON.parse(text) : null;
  } catch {
    body = text;
  }
  return { response, body };
}

// seed_test.sql's fixtures are inserted directly into auth.users by raw SQL
// (not through GoTrue's own signup path), so nothing guarantees GoTrue can
// actually authenticate them. That gap was real: confirmation_token /
// recovery_token / email_change_token_new / email_change were left NULL
// (no column default, unlike GoTrue's other token columns), and GoTrue's
// admin API 500s scanning NULL into a non-nullable Go string the moment
// anything touches the row through the Auth API -- undetectable by the SQL
// suite (which authenticates by fabricating request.jwt.claims directly,
// never through GoTrue) and by the rest of the edge suite (which creates its
// own throwaway users via the admin API rather than reusing seed fixtures).
// It surfaced only when a human tried to set a real password on the seed
// admin fixture to click through the panel. Assert the whole real path here:
// admin API can update the row, and the resulting credentials actually sign in.
const ADMIN_USER_ID = "11111111-1111-4111-8111-000000000004";
const ADMIN_EMAIL = "admin@planetest.local";

test("a seed_test.sql fixture can have a real password set via the admin API and then sign in", async () => {
  const password = `Seed-auth-${crypto.randomUUID()}`;

  const setPassword = await jsonRequest(
    `${baseUrl}/auth/v1/admin/users/${ADMIN_USER_ID}`,
    { method: "PUT", headers: serviceHeaders, body: JSON.stringify({ password }) },
  );
  assert.equal(
    setPassword.response.status,
    200,
    `admin API failed to update the seed fixture (this is exactly the "converting NULL to string" ` +
      `failure mode if any auth.users token column lacks a value): ${JSON.stringify(setPassword.body)}`,
  );

  const signIn = await jsonRequest(
    `${baseUrl}/auth/v1/token?grant_type=password`,
    {
      method: "POST",
      headers: { apikey: anonKey, "Content-Type": "application/json" },
      body: JSON.stringify({ email: ADMIN_EMAIL, password }),
    },
  );
  assert.equal(signIn.response.status, 200, JSON.stringify(signIn.body));
  assert.ok(signIn.body.access_token, "sign-in did not return an access token");

  const whoami = await jsonRequest(`${baseUrl}/auth/v1/user`, {
    headers: { apikey: anonKey, Authorization: `Bearer ${signIn.body.access_token}` },
  });
  assert.equal(whoami.response.status, 200);
  assert.equal(whoami.body.email, ADMIN_EMAIL);
});
