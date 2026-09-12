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

const fnUrl = `${baseUrl}/functions/v1/expire-stale-bookings-cron`;

// Same auth shape as complete-trips-cron (supabase/tests/edge_idor.test.mjs):
// a request without the cron secret, or the wrong one, is refused before the
// handler does anything to a booking.
test("expire-stale-bookings-cron rejects requests without the correct X-Cron-Secret", async () => {
  const noHeader = await jsonRequest(fnUrl, { method: "POST", headers: { apikey: anonKey } });
  assert.equal(noHeader.response.status, 401);

  const serviceRoleWithoutSecret = await jsonRequest(fnUrl, { method: "POST", headers: serviceHeaders });
  assert.equal(serviceRoleWithoutSecret.response.status, 401);

  const wrongSecret = await jsonRequest(fnUrl, {
    method: "POST",
    headers: { apikey: anonKey, "X-Cron-Secret": "wrong-secret" },
  });
  assert.equal(wrongSecret.response.status, 401);
});

test("expire-stale-bookings-cron rejects non-POST methods", async () => {
  const got = await jsonRequest(fnUrl, {
    method: "GET",
    headers: { apikey: anonKey, "X-Cron-Secret": "wrong-secret" },
  });
  assert.equal(got.response.status, 405);
});
