// =============================================================================
// edge_pricing_hostapp.test.mjs  —  P0.4
// =============================================================================
// Extends edge coverage beyond edge_idor.test.mjs:
//   - create-booking-intent server re-pricing: the 5% platform fee AND the
//     child-price fallback (child_price_paisa null -> floor(adult * 0.75)).
//   - submit-host-application: a valid questionnaire submits (200) then a
//     resubmit is refused (409); specific validation rejections return 400.
//   - payment-webhook: a reference (pidx / transaction_uuid) that does not
//     match the initiated payment is rejected (409) for both providers, before
//     any gateway call.
//
// Self-contained: creates its own users + departure, restores every row it
// touches. Requires the local stack + `supabase functions serve` (the runner
// starts serve automatically).
// =============================================================================

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
  try { body = text ? JSON.parse(text) : null; } catch { body = text; }
  return { response, body };
}
const serviceRest = (path, options = {}) =>
  jsonRequest(`${baseUrl}/rest/v1/${path}`, { ...options, headers: { ...serviceHeaders, ...(options.headers ?? {}) } });
const createUser = async (email, password) => {
  const { response, body } = await jsonRequest(`${baseUrl}/auth/v1/admin/users`, {
    method: "POST", headers: serviceHeaders,
    body: JSON.stringify({ email, password, email_confirm: true }),
  });
  assert.equal(response.status, 200, JSON.stringify(body));
  return body.id;
};
const signIn = async (email, password) => {
  const { response, body } = await jsonRequest(`${baseUrl}/auth/v1/token?grant_type=password`, {
    method: "POST", headers: { apikey: anonKey, "Content-Type": "application/json" },
    body: JSON.stringify({ email, password }),
  });
  assert.equal(response.status, 200, JSON.stringify(body));
  return body.access_token;
};
const invoke = (name, token, body) =>
  jsonRequest(`${baseUrl}/functions/v1/${name}`, {
    method: "POST",
    headers: { apikey: anonKey, Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });

test("create-booking-intent re-pricing: 5% fee + child-price fallback", async () => {
  const runId = crypto.randomUUID();
  const password = `Price-${crypto.randomUUID()}aA1!`;
  const email = `price-${runId}@example.test`;
  const departureId = crypto.randomUUID();
  let userId;
  let originalChildPrice;
  let experienceId;

  try {
    userId = await createUser(email, password);
    const token = await signIn(email, password);

    const exp = await serviceRest(
      "experiences?select=id,price_paisa,child_price_paisa&status=eq.published&limit=1",
    );
    assert.equal(exp.response.status, 200, JSON.stringify(exp.body));
    assert.ok(exp.body.length > 0, "a published experience fixture is required");
    experienceId = exp.body[0].id;
    const adultRate = Number(exp.body[0].price_paisa);
    originalChildPrice = exp.body[0].child_price_paisa;

    const start = new Date(Date.now() + 500 * 24 * 60 * 60 * 1000);
    const end = new Date(start.getTime() + 24 * 60 * 60 * 1000);
    const dep = await serviceRest("experience_departures", {
      method: "POST", headers: { Prefer: "return=minimal" },
      body: JSON.stringify({
        id: departureId, experience_id: experienceId,
        start_date: start.toISOString().slice(0, 10), end_date: end.toISOString().slice(0, 10),
        total_spots: 30, spots_left: 30, status: "open",
      }),
    });
    assert.equal(dep.response.status, 201, JSON.stringify(dep.body));

    const base = {
      experience_id: experienceId, departure_id: departureId,
      contact_name: "Price Test", contact_phone: "9800000000", payment_provider: "khalti",
    };

    // --- adults only: fee is exactly round(subtotal * 0.05) -----------------
    const adultsOnly = await invoke("create-booking-intent", token, { ...base, adults: 2, children: 0 });
    assert.equal(adultsOnly.response.status, 200, JSON.stringify(adultsOnly.body));
    const subA = 2 * adultRate;
    assert.equal(adultsOnly.body.subtotal_paisa, subA);
    assert.equal(adultsOnly.body.fees_paisa, Math.round(subA * 0.05), "5% platform fee");
    assert.equal(adultsOnly.body.total_paisa, subA + Math.round(subA * 0.05));

    // --- child-price fallback: child_price_paisa NULL -> floor(adult*0.75) --
    const nulled = await serviceRest(`experiences?id=eq.${experienceId}`, {
      method: "PATCH", headers: { Prefer: "return=minimal" },
      body: JSON.stringify({ child_price_paisa: null }),
    });
    assert.equal(nulled.response.status, 204, JSON.stringify(nulled.body));

    const withChildrenFallback = await invoke("create-booking-intent", token, { ...base, adults: 1, children: 2 });
    assert.equal(withChildrenFallback.response.status, 200, JSON.stringify(withChildrenFallback.body));
    const childFallbackRate = Math.floor(adultRate * 0.75);
    const subFallback = adultRate + 2 * childFallbackRate;
    assert.equal(withChildrenFallback.body.subtotal_paisa, subFallback, "child rate = floor(adult * 0.75)");
    assert.equal(withChildrenFallback.body.fees_paisa, Math.round(subFallback * 0.05));
    assert.equal(withChildrenFallback.body.total_paisa, subFallback + Math.round(subFallback * 0.05));

    // --- explicit child price is used verbatim when present ----------------
    const explicitChild = 111111;
    const setChild = await serviceRest(`experiences?id=eq.${experienceId}`, {
      method: "PATCH", headers: { Prefer: "return=minimal" },
      body: JSON.stringify({ child_price_paisa: explicitChild }),
    });
    assert.equal(setChild.response.status, 204, JSON.stringify(setChild.body));

    const withExplicitChild = await invoke("create-booking-intent", token, { ...base, adults: 1, children: 1 });
    assert.equal(withExplicitChild.response.status, 200, JSON.stringify(withExplicitChild.body));
    assert.equal(withExplicitChild.body.subtotal_paisa, adultRate + explicitChild, "explicit child_price_paisa is not overridden by the fallback");
  } finally {
    if (experienceId) {
      await serviceRest(`experiences?id=eq.${experienceId}`, {
        method: "PATCH", headers: { Prefer: "return=minimal" },
        body: JSON.stringify({ child_price_paisa: originalChildPrice ?? null }),
      });
    }
    await serviceRest(`experience_departures?id=eq.${departureId}`, { method: "DELETE" });
    if (userId) await fetch(`${baseUrl}/auth/v1/admin/users/${userId}`, { method: "DELETE", headers: serviceHeaders });
  }
});

test("submit-host-application: valid submit (200), resubmit refused (409), bad input (400)", async () => {
  const runId = crypto.randomUUID();
  const password = `Host-${crypto.randomUUID()}aA1!`;
  const email = `host-${runId}@example.test`;
  let userId;

  try {
    userId = await createUser(email, password);
    const token = await signIn(email, password);

    const valid = {
      hosting_type: "adventure",
      host_type: "individual",
      full_name: "Edge Test Host",
      email, // individual => must equal the account email
      phone: "9800000001",
      province: "Gandaki",
      district: "Kaski",
      locality: "Pokhara-6",
      min_guests: 1,
      max_guests: 8,
      availability_type: "flexible",
      pricing_model: "custom_quote",
      cancellation_policy: "flexible",
      description: "Automated edge test host application description, well over twenty characters.",
      identity_type: "citizenship",
      identity_number: "12-01-78-01234",
      identity_front_path: `${userId}/id-front.jpg`,
      terms_accepted: true,
    };

    const first = await invoke("submit-host-application", token, { applicationData: valid });
    assert.equal(first.response.status, 200, JSON.stringify(first.body));
    assert.equal(first.body.success, true);

    const resubmit = await invoke("submit-host-application", token, { applicationData: valid });
    assert.equal(resubmit.response.status, 409, JSON.stringify(resubmit.body));

    // reset to 'draft' so the 400 cases below are reached (validation runs
    // before the existing-application check).
    const reset = await serviceRest(`host_applications?user_id=eq.${userId}`, {
      method: "PATCH", headers: { Prefer: "return=minimal" },
      body: JSON.stringify({ status: "draft" }),
    });
    assert.equal(reset.response.status, 204, JSON.stringify(reset.body));

    const noTerms = await invoke("submit-host-application", token, {
      applicationData: { ...valid, terms_accepted: false },
    });
    assert.equal(noTerms.response.status, 400, JSON.stringify(noTerms.body));

    const badIdNumber = await invoke("submit-host-application", token, {
      applicationData: { ...valid, identity_number: "!!" },
    });
    assert.equal(badIdNumber.response.status, 400, JSON.stringify(badIdNumber.body));

    const foreignDocPath = await invoke("submit-host-application", token, {
      applicationData: { ...valid, identity_front_path: "00000000-0000-0000-0000-000000000000/x.jpg" },
    });
    assert.equal(foreignDocPath.response.status, 400, JSON.stringify(foreignDocPath.body));
  } finally {
    if (userId) {
      await serviceRest(`host_applications?user_id=eq.${userId}`, { method: "DELETE" });
      await fetch(`${baseUrl}/auth/v1/admin/users/${userId}`, { method: "DELETE", headers: serviceHeaders });
    }
  }
});

test("payment-webhook: a reference that does not match the initiated payment is rejected (409)", async () => {
  const runId = crypto.randomUUID();
  const password = `Wh-${crypto.randomUUID()}aA1!`;
  const email = `wh-${runId}@example.test`;
  const departureId = crypto.randomUUID();
  let userId;
  let experienceId;

  try {
    userId = await createUser(email, password);
    const token = await signIn(email, password);

    const exp = await serviceRest("experiences?select=id&status=eq.published&limit=1");
    experienceId = exp.body[0].id;
    const start = new Date(Date.now() + 520 * 24 * 60 * 60 * 1000);
    const end = new Date(start.getTime() + 24 * 60 * 60 * 1000);
    await serviceRest("experience_departures", {
      method: "POST", headers: { Prefer: "return=minimal" },
      body: JSON.stringify({
        id: departureId, experience_id: experienceId,
        start_date: start.toISOString().slice(0, 10), end_date: end.toISOString().slice(0, 10),
        total_spots: 10, spots_left: 10, status: "open",
      }),
    });

    // Khalti intent -> webhook with a pidx that was never stored -> 409, no gateway call.
    const khaltiIntent = await invoke("create-booking-intent", token, {
      experience_id: experienceId, departure_id: departureId, adults: 1, children: 0,
      contact_name: "WH", contact_phone: "9800000000", payment_provider: "khalti",
    });
    assert.equal(khaltiIntent.response.status, 200, JSON.stringify(khaltiIntent.body));
    const khaltiMismatch = await invoke("payment-webhook", token, {
      booking_id: khaltiIntent.body.booking_id,
      idempotency_key: khaltiIntent.body.idempotency_key,
      provider: "khalti",
      pidx: "pidx-that-was-never-issued",
    });
    assert.equal(khaltiMismatch.response.status, 409, JSON.stringify(khaltiMismatch.body));

    // eSewa intent -> webhook with an unrelated transaction_uuid -> 409.
    const esewaIntent = await invoke("create-booking-intent", token, {
      experience_id: experienceId, departure_id: departureId, adults: 1, children: 0,
      contact_name: "WH", contact_phone: "9800000000", payment_provider: "esewa",
    });
    assert.equal(esewaIntent.response.status, 200, JSON.stringify(esewaIntent.body));
    const esewaMismatch = await invoke("payment-webhook", token, {
      booking_id: esewaIntent.body.booking_id,
      idempotency_key: esewaIntent.body.idempotency_key,
      provider: "esewa",
      transaction_uuid: crypto.randomUUID(),
    });
    assert.equal(esewaMismatch.response.status, 409, JSON.stringify(esewaMismatch.body));

    // provider that does not match the payment row -> 409 as well.
    const wrongProvider = await invoke("payment-webhook", token, {
      booking_id: khaltiIntent.body.booking_id,
      idempotency_key: khaltiIntent.body.idempotency_key,
      provider: "esewa",
      transaction_uuid: crypto.randomUUID(),
    });
    assert.equal(wrongProvider.response.status, 409, JSON.stringify(wrongProvider.body));
  } finally {
    await serviceRest(`experience_departures?id=eq.${departureId}`, { method: "DELETE" });
    if (userId) await fetch(`${baseUrl}/auth/v1/admin/users/${userId}`, { method: "DELETE", headers: serviceHeaders });
  }
});
