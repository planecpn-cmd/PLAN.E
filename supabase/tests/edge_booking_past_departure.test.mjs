// create-booking-intent must refuse a departure whose start_date is in the past,
// even when that departure is still status='open'. Self-contained: creates its
// own user + two departures and removes them. Needs the local stack with
// `supabase functions serve` running.
//   node --test supabase/tests/edge_booking_past_departure.test.mjs

import assert from "node:assert/strict";
import test from "node:test";

const baseUrl = process.env.SUPABASE_URL ?? "http://127.0.0.1:54341";
const anonKey = process.env.SUPABASE_ANON_KEY;
const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
if (!anonKey || !serviceKey) {
  throw new Error("SUPABASE_ANON_KEY and SUPABASE_SERVICE_ROLE_KEY are required");
}

const serviceHeaders = { apikey: serviceKey, Authorization: `Bearer ${serviceKey}`, "Content-Type": "application/json" };

async function jsonRequest(url, options = {}) {
  const response = await fetch(url, options);
  const text = await response.text();
  let body = null;
  try { body = text ? JSON.parse(text) : null; } catch { body = text; }
  return { response, body };
}
const serviceRest = (path, options = {}) =>
  jsonRequest(`${baseUrl}/rest/v1/${path}`, { ...options, headers: { ...serviceHeaders, ...(options.headers ?? {}) } });
const day = (offsetDays) => new Date(Date.now() + offsetDays * 86400000).toISOString().slice(0, 10);

test("create-booking-intent rejects a past-dated open departure (400) and accepts a future one", async () => {
  const runId = crypto.randomUUID();
  const email = `pastdep-${runId}@example.test`;
  const password = `Past-${runId}aA1!`;
  const pastId = crypto.randomUUID();
  const futureId = crypto.randomUUID();
  let userId;

  try {
    const created = await jsonRequest(`${baseUrl}/auth/v1/admin/users`, {
      method: "POST", headers: serviceHeaders, body: JSON.stringify({ email, password, email_confirm: true }),
    });
    assert.equal(created.response.status, 200, JSON.stringify(created.body));
    userId = created.body.id;
    const signIn = await jsonRequest(`${baseUrl}/auth/v1/token?grant_type=password`, {
      method: "POST", headers: { apikey: anonKey, "Content-Type": "application/json" }, body: JSON.stringify({ email, password }),
    });
    assert.equal(signIn.response.status, 200, JSON.stringify(signIn.body));
    const token = signIn.body.access_token;

    const exp = await serviceRest("experiences?select=id&status=eq.published&limit=1");
    assert.ok(exp.body?.length > 0, "a published experience fixture is required");
    const experienceId = exp.body[0].id;

    const insert = await serviceRest("experience_departures", {
      method: "POST", headers: { Prefer: "return=minimal" },
      body: JSON.stringify([
        { id: pastId, experience_id: experienceId, start_date: day(-400), end_date: day(-399), total_spots: 10, spots_left: 10, status: "open" },
        { id: futureId, experience_id: experienceId, start_date: day(540), end_date: day(541), total_spots: 10, spots_left: 10, status: "open" },
      ]),
    });
    assert.equal(insert.response.status, 201, JSON.stringify(insert.body));

    const book = (departure_id) => jsonRequest(`${baseUrl}/functions/v1/create-booking-intent`, {
      method: "POST",
      headers: { apikey: anonKey, Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
      body: JSON.stringify({
        experience_id: experienceId, departure_id, adults: 1, children: 0,
        contact_name: "Past Test", contact_phone: "9800000000", payment_provider: "khalti",
      }),
    });

    const past = await book(pastId);
    assert.equal(past.response.status, 400, JSON.stringify(past.body));
    assert.match(past.body.error, /already passed/);

    const noBooking = await serviceRest(`bookings?select=id&departure_id=eq.${pastId}`);
    assert.deepEqual(noBooking.body, [], "no booking row may be created for a past departure");

    const future = await book(futureId);
    assert.equal(future.response.status, 200, JSON.stringify(future.body));
  } finally {
    // User first: deleting the user cascades its bookings, which would
    // otherwise block the departure delete.
    if (userId) await fetch(`${baseUrl}/auth/v1/admin/users/${userId}`, { method: "DELETE", headers: serviceHeaders });
    await serviceRest(`experience_departures?id=in.(${pastId},${futureId})`, { method: "DELETE" });
  }
});
