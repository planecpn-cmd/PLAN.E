export type RateLimit = {
  key: string;
  limit: number;
  minutes: number;
};

export async function consumeRateLimits(
  supabaseClient: any,
  quotas: RateLimit[],
): Promise<number | null> {
  for (const quota of quotas) {
    const { data: allowed, error } = await supabaseClient.rpc(
      "check_ai_rate_limit",
      {
        p_key: quota.key,
        p_limit: quota.limit,
        p_window_minutes: quota.minutes,
      },
    );
    if (error) throw new Error(`Rate limit check failed: ${error.message}`);
    if (!allowed) return quota.minutes * 60;
  }
  return null;
}
