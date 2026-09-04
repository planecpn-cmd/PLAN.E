import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";

export type PaymentProvider = "khalti" | "esewa";

export async function isPaymentProviderEnabled(
  client: SupabaseClient,
  provider: PaymentProvider,
): Promise<boolean> {
  const { data, error } = await client
    .from("feature_flags")
    .select("enabled")
    .eq("key", `payment_${provider}`)
    .maybeSingle();

  if (error) throw new Error("Failed to load payment provider configuration");
  return data?.enabled === true;
}
