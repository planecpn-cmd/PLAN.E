import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

type Delivery = {
  id: string;
  recipient_id: string;
  target_route: string;
};

type PushToken = {
  id: string;
  provider: "fcm" | "apns";
  token: string;
};

type SendResult = {
  ok: boolean;
  invalidToken?: boolean;
  errorCode?: string;
};

const jsonHeaders = { "Content-Type": "application/json" };
const uuidPattern =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

let cachedFcmAccessToken: { value: string; expiresAt: number } | null = null;
let cachedApnsJwt: { value: string; expiresAt: number } | null = null;

function base64Url(value: Uint8Array | string): string {
  const bytes = typeof value === "string" ? new TextEncoder().encode(value) : value;
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replaceAll("+", "-").replaceAll("/", "_").replace(/=+$/, "");
}

function pemBytes(pem: string): Uint8Array {
  const body = pem.replace(/-----[^-]+-----/g, "").replace(/\s/g, "");
  const binary = atob(body);
  return Uint8Array.from(binary, (character) => character.charCodeAt(0));
}

function secretsMatch(actual: string, expected: string): boolean {
  const actualBytes = new TextEncoder().encode(actual);
  const expectedBytes = new TextEncoder().encode(expected);
  let mismatch = actualBytes.length ^ expectedBytes.length;
  const length = Math.max(actualBytes.length, expectedBytes.length);
  for (let index = 0; index < length; index += 1) {
    mismatch |= (actualBytes[index] ?? 0) ^ (expectedBytes[index] ?? 0);
  }
  return mismatch === 0;
}

async function getFcmAccessToken(): Promise<{ token: string; projectId: string }> {
  const rawCredentials = Deno.env.get("FCM_SERVICE_ACCOUNT_JSON");
  if (!rawCredentials) throw new Error("fcm_not_configured");

  const credentials = JSON.parse(rawCredentials) as {
    project_id: string;
    client_email: string;
    private_key: string;
  };
  if (!credentials.project_id || !credentials.client_email || !credentials.private_key) {
    throw new Error("fcm_credentials_invalid");
  }

  const now = Math.floor(Date.now() / 1000);
  if (cachedFcmAccessToken && cachedFcmAccessToken.expiresAt > now + 60) {
    return { token: cachedFcmAccessToken.value, projectId: credentials.project_id };
  }

  const header = base64Url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const claim = base64Url(JSON.stringify({
    iss: credentials.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  }));
  const signingInput = `${header}.${claim}`;
  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemBytes(credentials.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(signingInput),
  );
  const assertion = `${signingInput}.${base64Url(new Uint8Array(signature))}`;

  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });
  const payload = await response.json().catch(() => ({})) as {
    access_token?: string;
    expires_in?: number;
  };
  if (!response.ok || !payload.access_token) throw new Error("fcm_auth_failed");

  cachedFcmAccessToken = {
    value: payload.access_token,
    expiresAt: now + Math.min(payload.expires_in ?? 3600, 3600),
  };
  return { token: payload.access_token, projectId: credentials.project_id };
}

async function sendFcm(
  deviceToken: string,
  title: string,
  route: string,
): Promise<SendResult> {
  try {
    const auth = await getFcmAccessToken();
    const response = await fetch(
      `https://fcm.googleapis.com/v1/projects/${encodeURIComponent(auth.projectId)}/messages:send`,
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${auth.token}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          message: {
            token: deviceToken,
            notification: { title, body: "Open PLAN E to view it." },
            data: { type: "trip_message", route },
            android: { notification: { tag: "trip-message" } },
            apns: { payload: { aps: { "thread-id": "trip-message" } } },
          },
        }),
      },
    );
    if (response.ok) return { ok: true };

    const payload = await response.json().catch(() => ({})) as {
      error?: { status?: string; details?: Array<{ errorCode?: string }> };
    };
    const providerCode = payload.error?.details?.[0]?.errorCode ?? payload.error?.status;
    const invalidToken = response.status === 404 || providerCode === "UNREGISTERED";
    return {
      ok: false,
      invalidToken,
      errorCode: invalidToken ? "fcm_unregistered" : `fcm_${response.status}`,
    };
  } catch (error) {
    const code = error instanceof Error && error.message.startsWith("fcm_")
      ? error.message
      : "fcm_send_failed";
    return { ok: false, errorCode: code };
  }
}

async function getApnsJwt(): Promise<string> {
  const teamId = Deno.env.get("APNS_TEAM_ID");
  const keyId = Deno.env.get("APNS_KEY_ID");
  const privateKey = Deno.env.get("APNS_PRIVATE_KEY");
  if (!teamId || !keyId || !privateKey) throw new Error("apns_not_configured");

  const now = Math.floor(Date.now() / 1000);
  if (cachedApnsJwt && cachedApnsJwt.expiresAt > now + 60) {
    return cachedApnsJwt.value;
  }

  const header = base64Url(JSON.stringify({ alg: "ES256", kid: keyId }));
  const claim = base64Url(JSON.stringify({ iss: teamId, iat: now }));
  const signingInput = `${header}.${claim}`;
  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemBytes(privateKey),
    { name: "ECDSA", namedCurve: "P-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    { name: "ECDSA", hash: "SHA-256" },
    key,
    new TextEncoder().encode(signingInput),
  );
  const jwt = `${signingInput}.${base64Url(new Uint8Array(signature))}`;
  cachedApnsJwt = { value: jwt, expiresAt: now + 3000 };
  return jwt;
}

async function sendApns(
  deviceToken: string,
  title: string,
  route: string,
): Promise<SendResult> {
  const bundleId = Deno.env.get("APNS_BUNDLE_ID");
  if (!bundleId) return { ok: false, errorCode: "apns_not_configured" };

  try {
    const jwt = await getApnsJwt();
    const host = Deno.env.get("APNS_USE_SANDBOX") === "true"
      ? "api.sandbox.push.apple.com"
      : "api.push.apple.com";
    const response = await fetch(`https://${host}/3/device/${deviceToken}`, {
      method: "POST",
      headers: {
        authorization: `bearer ${jwt}`,
        "apns-topic": bundleId,
        "apns-push-type": "alert",
        "apns-priority": "10",
      },
      body: JSON.stringify({
        aps: {
          alert: { title, body: "Open PLAN E to view it." },
          sound: "default",
          "thread-id": "trip-message",
        },
        type: "trip_message",
        route,
      }),
    });
    if (response.ok) return { ok: true };
    return {
      ok: false,
      invalidToken: response.status === 410,
      errorCode: response.status === 410 ? "apns_unregistered" : `apns_${response.status}`,
    };
  } catch (error) {
    const code = error instanceof Error && error.message.startsWith("apns_")
      ? error.message
      : "apns_send_failed";
    return { ok: false, errorCode: code };
  }
}

serve(async (request) => {
  if (request.method !== "POST") {
    return new Response(JSON.stringify({ error: "method_not_allowed" }), {
      status: 405,
      headers: jsonHeaders,
    });
  }

  const expectedSecret = Deno.env.get("TRIP_MESSAGE_PUSH_WEBHOOK_SECRET") ?? "";
  const suppliedSecret = request.headers.get("X-Trip-Push-Secret") ?? "";
  if (!expectedSecret || !secretsMatch(suppliedSecret, expectedSecret)) {
    return new Response(JSON.stringify({ error: "unauthorized" }), {
      status: 401,
      headers: jsonHeaders,
    });
  }

  const body = await request.json().catch(() => ({})) as {
    message_id?: string;
    record?: { message_id?: string; id?: string };
  };
  const messageId = body.message_id ?? body.record?.message_id ?? body.record?.id ?? "";
  if (!uuidPattern.test(messageId)) {
    return new Response(JSON.stringify({ error: "invalid_message_id" }), {
      status: 400,
      headers: jsonHeaders,
    });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  if (!supabaseUrl || !serviceRoleKey) {
    return new Response(JSON.stringify({ error: "server_not_configured" }), {
      status: 500,
      headers: jsonHeaders,
    });
  }
  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const { data: claimed, error: claimError } = await supabase.rpc(
    "claim_trip_push_deliveries",
    { p_message_id: messageId },
  );
  if (claimError) {
    return new Response(JSON.stringify({ error: "claim_failed" }), {
      status: 500,
      headers: jsonHeaders,
    });
  }
  const deliveries = (claimed ?? []) as Delivery[];
  if (deliveries.length === 0) {
    return new Response(JSON.stringify({ processed: 0 }), { headers: jsonHeaders });
  }

  const { data: message, error: messageError } = await supabase
    .from("trip_messages")
    .select("id,sender_id")
    .eq("id", messageId)
    .maybeSingle();
  if (messageError || !message) {
    await supabase.from("trip_push_deliveries").update({
      status: "failed",
      error_code: "message_not_found",
      updated_at: new Date().toISOString(),
    }).in("id", deliveries.map((delivery) => delivery.id));
    return new Response(JSON.stringify({ error: "message_not_found" }), {
      status: 404,
      headers: jsonHeaders,
    });
  }

  const { data: senderProfile } = await supabase
    .from("profiles")
    .select("full_name")
    .eq("id", message.sender_id)
    .maybeSingle();
  const senderName = String(senderProfile?.full_name ?? "a trip participant")
    .replace(/[\r\n]+/g, " ")
    .trim()
    .slice(0, 80);
  const title = `New message from ${senderName || "a trip participant"}`;

  let sent = 0;
  let failed = 0;
  let skipped = 0;

  for (const delivery of deliveries) {
    const { data: tokenRows, error: tokenError } = await supabase
      .from("trip_push_device_tokens")
      .select("id,provider,token")
      .eq("user_id", delivery.recipient_id)
      .eq("is_active", true);
    const tokens = (tokenRows ?? []) as PushToken[];

    if (tokenError || tokens.length === 0) {
      skipped += 1;
      await supabase.from("trip_push_deliveries").update({
        status: tokenError ? "failed" : "skipped_no_token",
        error_code: tokenError ? "token_lookup_failed" : null,
        updated_at: new Date().toISOString(),
      }).eq("id", delivery.id);
      continue;
    }

    let anySent = false;
    let lastError = "provider_send_failed";
    for (const token of tokens) {
      const result = token.provider === "apns"
        ? await sendApns(token.token, title, delivery.target_route)
        : await sendFcm(token.token, title, delivery.target_route);
      if (result.ok) anySent = true;
      if (result.errorCode) lastError = result.errorCode;
      if (result.invalidToken) {
        await supabase.from("trip_push_device_tokens").update({
          is_active: false,
          updated_at: new Date().toISOString(),
        }).eq("id", token.id);
      }
    }

    if (anySent) {
      sent += 1;
      await supabase.from("trip_push_deliveries").update({
        status: "sent",
        error_code: null,
        sent_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      }).eq("id", delivery.id);
    } else {
      failed += 1;
      await supabase.from("trip_push_deliveries").update({
        status: "failed",
        error_code: lastError.slice(0, 80),
        updated_at: new Date().toISOString(),
      }).eq("id", delivery.id);
    }
  }

  return new Response(JSON.stringify({ processed: deliveries.length, sent, failed, skipped }), {
    headers: jsonHeaders,
  });
});
