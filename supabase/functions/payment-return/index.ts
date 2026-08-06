import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

// Pure landing marker. The in-app WebView intercepts navigation to this URL
// before it loads and reads the query params itself (pidx, transaction_uuid,
// status) to trigger server-side verification. This page only renders when a
// user opens the payment link outside the app (e.g. external browser).
serve((req) => {
  const url = new URL(req.url);
  const provider = url.searchParams.get("provider") ?? "";
  const status = url.searchParams.get("status") ?? (provider === "khalti" ? "unknown" : "unknown");

  const html = `<!doctype html>
<html><body style="font-family: sans-serif; text-align: center; padding-top: 3rem;">
<h2>Payment received</h2>
<p>Status: ${status}. You can return to the PLAN E app now.</p>
</body></html>`;

  return new Response(html, { status: 200, headers: { "Content-Type": "text/html" } });
});
