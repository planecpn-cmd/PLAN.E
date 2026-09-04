import assert from "node:assert/strict";
import { createHmac } from "node:crypto";
import test from "node:test";

const baseUrl = process.env.SUPABASE_URL ?? "http://127.0.0.1:54341";
const anonKey = process.env.SUPABASE_ANON_KEY;
const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
const jwtSecret = process.env.SUPABASE_JWT_SECRET;
const includePaymentRedirect = process.env.PLAN_E_TEST_PAYMENT_REDIRECT === "true";

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

async function createUser(email, password) {
  const { response, body } = await jsonRequest(`${baseUrl}/auth/v1/admin/users`, {
    method: "POST",
    headers: serviceHeaders,
    body: JSON.stringify({ email, password, email_confirm: true }),
  });
  assert.equal(response.status, 200, JSON.stringify(body));
  return body.id;
}

async function signIn(email, password) {
  const { response, body } = await jsonRequest(
    `${baseUrl}/auth/v1/token?grant_type=password`,
    {
      method: "POST",
      headers: { apikey: anonKey, "Content-Type": "application/json" },
      body: JSON.stringify({ email, password }),
    },
  );
  assert.equal(response.status, 200, JSON.stringify(body));
  return body.access_token;
}

async function invoke(name, token, body) {
  return jsonRequest(`${baseUrl}/functions/v1/${name}`, {
    method: "POST",
    headers: {
      apikey: anonKey,
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
  });
}

const encodeJwtPart = (value) =>
  Buffer.from(JSON.stringify(value)).toString("base64url");

function tamperJwt(token, claims) {
  const [header, payload, signature] = token.split(".");
  return `${header}.${encodeJwtPart({
    ...JSON.parse(Buffer.from(payload, "base64url").toString()),
    ...claims,
  })}.${signature}`;
}

function signLegacyJwt(payload) {
  assert.ok(jwtSecret, "SUPABASE_JWT_SECRET is required for the expired-token test");
  const signingInput = `${encodeJwtPart({ alg: "HS256", typ: "JWT" })}.${encodeJwtPart(payload)}`;
  const signature = createHmac("sha256", jwtSecret).update(signingInput).digest("base64url");
  return `${signingInput}.${signature}`;
}

async function serviceRest(path, options = {}) {
  return jsonRequest(`${baseUrl}/rest/v1/${path}`, {
    ...options,
    headers: { ...serviceHeaders, ...options.headers },
  });
}

async function userRest(path, token, options = {}) {
  return jsonRequest(`${baseUrl}/rest/v1/${path}`, {
    ...options,
    headers: {
      apikey: anonKey,
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
      ...options.headers,
    },
  });
}

test("payment Edge Functions reject cross-account booking IDs", async (t) => {
  const runId = crypto.randomUUID();
  const password = `IDOR-${crypto.randomUUID()}aA1!`;
  const emailA = `idor-a-${runId}@example.test`;
  const emailB = `idor-b-${runId}@example.test`;
  const departureId = crypto.randomUUID();
  let userA;
  let userB;
  let previousEsewaFlagRows;
  let previousAiFlagRows;
  const paymentRateLimitBookingIds = [];

  try {
    userA = await createUser(emailA, password);
    userB = await createUser(emailB, password);
    const tokenA = await signIn(emailA, password);
    const tokenB = await signIn(emailB, password);

    const cronAsOrdinaryUser = await jsonRequest(
      `${baseUrl}/functions/v1/complete-trips-cron`,
      { method: "POST", headers: { apikey: anonKey, Authorization: `Bearer ${tokenA}` } },
    );
    assert.equal(cronAsOrdinaryUser.response.status, 401);
    const cronAsServiceRoleWithoutSecret = await jsonRequest(
      `${baseUrl}/functions/v1/complete-trips-cron`,
      { method: "POST", headers: serviceHeaders },
    );
    assert.equal(cronAsServiceRoleWithoutSecret.response.status, 401);
    const cronWrongSecret = await jsonRequest(
      `${baseUrl}/functions/v1/complete-trips-cron`,
      { method: "POST", headers: { "X-Cron-Secret": "wrong-secret" } },
    );
    assert.equal(cronWrongSecret.response.status, 401);
    const cronGet = await jsonRequest(`${baseUrl}/functions/v1/complete-trips-cron`, {
      method: "GET",
      headers: { "X-Cron-Secret": "local-complete-trips-test-secret" },
    });
    assert.equal(cronGet.response.status, 405);

    const protectedRequest = { booking_id: crypto.randomUUID(), provider: "khalti" };
    const tokenPayload = JSON.parse(
      Buffer.from(tokenA.split(".")[1], "base64url").toString(),
    );
    const rejectedTokens = [
      "not-a-jwt",
      `${encodeJwtPart({ alg: "none", typ: "JWT" })}.${encodeJwtPart({
        ...tokenPayload,
        sub: userB,
        role: "service_role",
      })}.`,
      tamperJwt(tokenA, { sub: userB }),
      tamperJwt(tokenA, { role: "service_role", user_role: "admin" }),
      signLegacyJwt({
        ...tokenPayload,
        iat: Math.floor(Date.now() / 1000) - 7200,
        exp: Math.floor(Date.now() / 1000) - 3600,
      }),
    ];
    for (const rejectedToken of rejectedTokens) {
      const rejected = await invoke("initiate-payment", rejectedToken, protectedRequest);
      assert.equal(rejected.response.status, 401, JSON.stringify(rejected.body));
    }

    const authenticatedHostSubmission = await invoke(
      "submit-host-application",
      tokenA,
      {},
    );
    assert.equal(authenticatedHostSubmission.response.status, 400);

    const oversizedAiPrompt = await invoke("generate-itinerary", tokenA, {
      prompt: "x".repeat(1501),
    });
    assert.equal(oversizedAiPrompt.response.status, 400);
    const nestedAiPrompt = await invoke("generate-itinerary", tokenA, {
      prompt: { text: "not a string" },
    });
    assert.equal(nestedAiPrompt.response.status, 400);

    const previousAiFlag = await serviceRest(
      "feature_flags?select=*&key=eq.ai_itinerary",
    );
    assert.equal(previousAiFlag.response.status, 200);
    previousAiFlagRows = previousAiFlag.body;
    const disabledAi = await serviceRest("feature_flags", {
      method: "POST",
      headers: { Prefer: "resolution=merge-duplicates,return=minimal" },
      body: JSON.stringify({ key: "ai_itinerary", enabled: false }),
    });
    assert.ok([200, 201].includes(disabledAi.response.status));
    const disabledAiRequest = await invoke("generate-itinerary", tokenA, {
      prompt: "Plan a food and culture experience in Nepal",
    });
    assert.equal(disabledAiRequest.response.status, 503);
    const aiQuotaAfterDisabledRequest = await serviceRest(
      `ai_rate_limits?select=rate_key&rate_key=eq.itinerary:user:${userA}:hour`,
    );
    assert.deepEqual(aiQuotaAfterDisabledRequest.body, []);
    if (previousAiFlagRows.length > 0) {
      await serviceRest("feature_flags?key=eq.ai_itinerary", {
        method: "PATCH",
        body: JSON.stringify(previousAiFlagRows[0]),
      });
    } else {
      await serviceRest("feature_flags?key=eq.ai_itinerary", { method: "DELETE" });
    }
    previousAiFlagRows = undefined;

    const experiences = await serviceRest(
      "experiences?select=id,price_paisa,child_price_paisa&status=eq.published&limit=1",
    );
    assert.equal(experiences.response.status, 200, JSON.stringify(experiences.body));
    assert.ok(experiences.body.length > 0, "A published experience fixture is required");
    const experienceId = experiences.body[0].id;
    const start = new Date(Date.now() + 400 * 24 * 60 * 60 * 1000);
    const end = new Date(start.getTime() + 24 * 60 * 60 * 1000);

    const departure = await serviceRest("experience_departures", {
      method: "POST",
      headers: { Prefer: "return=minimal" },
      body: JSON.stringify({
        id: departureId,
        experience_id: experienceId,
        start_date: start.toISOString().slice(0, 10),
        end_date: end.toISOString().slice(0, 10),
        total_spots: 20,
        spots_left: 20,
        status: "open",
      }),
    });
    assert.equal(departure.response.status, 201, JSON.stringify(departure.body));

    const bookingBody = {
      experience_id: experienceId,
      departure_id: departureId,
      adults: 1,
      children: 0,
      contact_name: "IDOR Test User",
      contact_phone: "9800000000",
      payment_provider: "khalti",
    };
    const intentB = await invoke("create-booking-intent", tokenB, bookingBody);
    assert.equal(intentB.response.status, 200, JSON.stringify(intentB.body));

    const injectedIntentA = await invoke("create-booking-intent", tokenA, {
      ...bookingBody,
      user_id: userB,
      subtotal_paisa: 1,
      addons_paisa: 0,
      fees_paisa: 0,
      total_paisa: 1,
      amount_paisa: 1,
      status: "confirmed",
    });
    assert.equal(injectedIntentA.response.status, 200, JSON.stringify(injectedIntentA.body));
    assert.equal(injectedIntentA.body.booking.user_id, userA);
    const adultRate = Number(experiences.body[0].price_paisa);
    const expectedTotal = adultRate + Math.round(adultRate * 0.05);
    assert.equal(injectedIntentA.body.subtotal_paisa, adultRate);
    assert.equal(injectedIntentA.body.total_paisa, expectedTotal);
    assert.equal(injectedIntentA.body.booking.status, "pending");

    const forgedBooking = await userRest("bookings", tokenA, {
      method: "POST",
      headers: { Prefer: "return=minimal" },
      body: JSON.stringify({
        booking_ref: `FORGED-${runId}`,
        user_id: userA,
        experience_id: experienceId,
        departure_id: departureId,
        adults: 1,
        children: 0,
        contact_name: "Forged Price",
        contact_phone: "9800000000",
        subtotal_paisa: 1,
        addons_paisa: 0,
        fees_paisa: 0,
        total_paisa: 1,
        status: "pending",
      }),
    });
    assert.ok(
      [401, 403].includes(forgedBooking.response.status),
      `direct client booking insert returned ${forgedBooking.response.status}`,
    );

    const freeRate = await serviceRest(
      `experience_departures?id=eq.${departureId}`,
      {
        method: "PATCH",
        headers: { Prefer: "return=minimal" },
        body: JSON.stringify({ price_override_paisa: 0 }),
      },
    );
    assert.equal(freeRate.response.status, 204, JSON.stringify(freeRate.body));
    const invalidServerTotal = await invoke("create-booking-intent", tokenA, bookingBody);
    assert.equal(invalidServerTotal.response.status, 409);
    const restoredRate = await serviceRest(
      `experience_departures?id=eq.${departureId}`,
      {
        method: "PATCH",
        headers: { Prefer: "return=minimal" },
        body: JSON.stringify({ price_override_paisa: null }),
      },
    );
    assert.equal(restoredRate.response.status, 204, JSON.stringify(restoredRate.body));

    const previousEsewaFlag = await serviceRest(
      "feature_flags?select=*&key=eq.payment_esewa",
    );
    assert.equal(previousEsewaFlag.response.status, 200);
    previousEsewaFlagRows = previousEsewaFlag.body;
    const disabledEsewa = await serviceRest("feature_flags", {
      method: "POST",
      headers: { Prefer: "resolution=merge-duplicates,return=minimal" },
      body: JSON.stringify({ key: "payment_esewa", enabled: false }),
    });
    assert.ok([200, 201].includes(disabledEsewa.response.status));

    const disabledProviderIntent = await invoke("create-booking-intent", tokenA, {
      ...bookingBody,
      payment_provider: "esewa",
    });
    assert.equal(disabledProviderIntent.response.status, 403);
    if (previousEsewaFlagRows.length > 0) {
      await serviceRest("feature_flags?key=eq.payment_esewa", {
        method: "PATCH",
        body: JSON.stringify(previousEsewaFlagRows[0]),
      });
    } else {
      await serviceRest("feature_flags?key=eq.payment_esewa", { method: "DELETE" });
    }
    previousEsewaFlagRows = undefined;

    const enabledEsewaIntent = await invoke("create-booking-intent", tokenA, {
      ...bookingBody,
      payment_provider: "esewa",
    });
    assert.equal(enabledEsewaIntent.response.status, 200);
    previousEsewaFlagRows = previousEsewaFlag.body;
    await serviceRest("feature_flags?key=eq.payment_esewa", {
      method: "PATCH",
      body: JSON.stringify({ enabled: false }),
    });
    const disabledProviderInitiation = await invoke("initiate-payment", tokenA, {
      booking_id: enabledEsewaIntent.body.booking_id,
      provider: "esewa",
    });
    assert.equal(disabledProviderInitiation.response.status, 403);
    await serviceRest("feature_flags?key=eq.payment_esewa", {
      method: "PATCH",
      body: JSON.stringify(previousEsewaFlagRows[0]),
    });
    previousEsewaFlagRows = undefined;

    const throttledIntent = await invoke("create-booking-intent", tokenA, {
      ...bookingBody,
      payment_provider: "esewa",
    });
    assert.equal(throttledIntent.response.status, 200, JSON.stringify(throttledIntent.body));
    paymentRateLimitBookingIds.push(throttledIntent.body.booking_id);
    for (let attempt = 0; attempt < 3; attempt += 1) {
      const initiation = await invoke("initiate-payment", tokenA, {
        booking_id: throttledIntent.body.booking_id,
        provider: "esewa",
      });
      assert.equal(initiation.response.status, 200, JSON.stringify(initiation.body));
    }
    const throttledInitiation = await invoke("initiate-payment", tokenA, {
      booking_id: throttledIntent.body.booking_id,
      provider: "esewa",
    });
    assert.equal(throttledInitiation.response.status, 429, JSON.stringify(throttledInitiation.body));
    assert.equal(throttledInitiation.response.headers.get("retry-after"), "900");

    const foreignInitiation = await invoke("initiate-payment", tokenA, {
      booking_id: intentB.body.booking_id,
      provider: "khalti",
    });
    const nonexistentInitiation = await invoke("initiate-payment", tokenA, {
      booking_id: crypto.randomUUID(),
      provider: "khalti",
    });
    assert.equal(foreignInitiation.response.status, 404);
    assert.equal(nonexistentInitiation.response.status, 404);
    assert.deepEqual(foreignInitiation.body, nonexistentInitiation.body);

    const foreignVerification = await invoke("payment-webhook", tokenA, {
      booking_id: intentB.body.booking_id,
      idempotency_key: intentB.body.idempotency_key,
      provider: "khalti",
      pidx: "attacker-controlled-reference",
    });
    assert.equal(foreignVerification.response.status, 404);

    const paymentAfterAttack = await serviceRest(
      `payments?select=status,provider_ref&booking_id=eq.${intentB.body.booking_id}`,
    );
    assert.deepEqual(paymentAfterAttack.body, [{ status: "initiated", provider_ref: null }]);

    const unauthenticated = await jsonRequest(`${baseUrl}/functions/v1/initiate-payment`, {
      method: "POST",
      headers: { apikey: anonKey, "Content-Type": "application/json" },
      body: JSON.stringify({ booking_id: intentB.body.booking_id, provider: "khalti" }),
    });
    assert.equal(unauthenticated.response.status, 401);

    await t.test(
      "eSewa redirect token is single-use and rejects expiry",
      { skip: !includePaymentRedirect },
      async () => {
        const intent = await invoke("create-booking-intent", tokenA, {
          ...bookingBody,
          payment_provider: "esewa",
        });
        assert.equal(intent.response.status, 200, JSON.stringify(intent.body));
        paymentRateLimitBookingIds.push(intent.body.booking_id);

        const initiated = await invoke("initiate-payment", tokenA, {
          booking_id: intent.body.booking_id,
          provider: "esewa",
        });
        assert.equal(initiated.response.status, 200, JSON.stringify(initiated.body));
        const tokenUrl = new URL(initiated.body.payment_url);
        const localTokenUrl = `${baseUrl}${tokenUrl.pathname}${tokenUrl.search}`;
        assert.equal(
          (await fetch(
            `${baseUrl}/functions/v1/esewa-redirect?booking_id=${intent.body.booking_id}`,
          )).status,
          404,
        );
        assert.equal((await fetch(localTokenUrl)).status, 200);

        const initiatedPayment = await serviceRest(
          `payments?select=raw_response&booking_id=eq.${intent.body.booking_id}`,
        );
        const transactionUuid = initiatedPayment.body[0].raw_response.transaction_uuid;
        const exhaustedVerificationQuota = await serviceRest("ai_rate_limits", {
          method: "POST",
          headers: { Prefer: "resolution=merge-duplicates,return=minimal" },
          body: JSON.stringify({
            rate_key: `payment:verify:booking:${intent.body.booking_id}`,
            request_count: 10,
            window_start: new Date().toISOString(),
          }),
        });
        assert.ok([200, 201].includes(exhaustedVerificationQuota.response.status));
        const throttledVerification = await invoke("payment-webhook", tokenA, {
          booking_id: intent.body.booking_id,
          idempotency_key: intent.body.idempotency_key,
          provider: "esewa",
          transaction_uuid: transactionUuid,
        });
        assert.equal(throttledVerification.response.status, 429);
        assert.equal(throttledVerification.response.headers.get("retry-after"), "900");

        const mismatchedReference = await invoke("payment-webhook", tokenA, {
          booking_id: intent.body.booking_id,
          idempotency_key: intent.body.idempotency_key,
          provider: "esewa",
          transaction_uuid: crypto.randomUUID(),
        });
        assert.equal(mismatchedReference.response.status, 409);
        assert.equal((await fetch(localTokenUrl)).status, 404);

        const replacement = await invoke("initiate-payment", tokenA, {
          booking_id: intent.body.booking_id,
          provider: "esewa",
        });
        assert.equal(replacement.response.status, 200, JSON.stringify(replacement.body));
        const replacementUrl = new URL(replacement.body.payment_url);
        const paymentId = (
          await serviceRest(`payments?select=id&booking_id=eq.${intent.body.booking_id}`)
        ).body[0].id;
        const expired = new Date(Date.now() - 60_000);
        const created = new Date(expired.getTime() - 60_000);
        const expiryUpdate = await serviceRest(
          `payment_redirect_tokens?payment_id=eq.${paymentId}`,
          {
            method: "PATCH",
            headers: { Prefer: "return=minimal" },
            body: JSON.stringify({
              created_at: created.toISOString(),
              expires_at: expired.toISOString(),
            }),
          },
        );
        assert.equal(expiryUpdate.response.status, 204, JSON.stringify(expiryUpdate.body));
        assert.equal(
          (await fetch(`${baseUrl}${replacementUrl.pathname}${replacementUrl.search}`)).status,
          404,
        );
      },
    );
  } finally {
    if (previousAiFlagRows) {
      if (previousAiFlagRows.length > 0) {
        await serviceRest("feature_flags?key=eq.ai_itinerary", {
          method: "PATCH",
          body: JSON.stringify(previousAiFlagRows[0]),
        });
      } else {
        await serviceRest("feature_flags?key=eq.ai_itinerary", { method: "DELETE" });
      }
    }
    if (previousEsewaFlagRows) {
      if (previousEsewaFlagRows.length > 0) {
        await serviceRest("feature_flags?key=eq.payment_esewa", {
          method: "PATCH",
          body: JSON.stringify(previousEsewaFlagRows[0]),
        });
      } else {
        await serviceRest("feature_flags?key=eq.payment_esewa", { method: "DELETE" });
      }
    }
    if (userA) {
      await serviceRest(`ai_rate_limits?rate_key=eq.payment:initiate:user:${userA}`, {
        method: "DELETE",
      });
      await serviceRest(`ai_rate_limits?rate_key=eq.payment:verify:user:${userA}`, {
        method: "DELETE",
      });
    }
    for (const bookingId of paymentRateLimitBookingIds) {
      await serviceRest(`ai_rate_limits?rate_key=eq.payment:initiate:booking:${bookingId}`, {
        method: "DELETE",
      });
      await serviceRest(`ai_rate_limits?rate_key=eq.payment:verify:booking:${bookingId}`, {
        method: "DELETE",
      });
    }
    if (userA) {
      await fetch(`${baseUrl}/auth/v1/admin/users/${userA}`, {
        method: "DELETE",
        headers: serviceHeaders,
      });
    }
    if (userB) {
      await fetch(`${baseUrl}/auth/v1/admin/users/${userB}`, {
        method: "DELETE",
        headers: serviceHeaders,
      });
    }
    await serviceRest(`experience_departures?id=eq.${departureId}`, { method: "DELETE" });
  }
});
