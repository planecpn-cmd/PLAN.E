import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

// Landing marker shared by both clients. The in-app WebView intercepts
// navigation to this URL *before* the request is ever sent (see
// lib/features/booking/payment_webview_screen.dart's onNavigationRequest),
// so this code only ever runs for a real browser hit from the web app.
// Forward it to verify-payment-return, which does the actual server-side
// verification and finalization, then redirects to planenepal.com.
serve((req) => {
  const url = new URL(req.url);
  const target = new URL(`${url.origin}/functions/v1/verify-payment-return${url.search}`);
  return new Response(null, { status: 302, headers: { Location: target.toString() } });
});
