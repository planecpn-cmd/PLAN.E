// "Today" for dashboard counters means Asia/Kathmandu's calendar day (fixed
// UTC+5:45, no DST), matching create-booking-intent's own day-boundary
// convention. Returns UTC instant bounds so callers can use plain
// .gte(col, start).lt(col, end) range filters.
export function kathmanduTodayRangeUtc(
  now: Date = new Date(),
): { startUtc: string; endUtc: string; dateStr: string } {
  const dateStr = new Intl.DateTimeFormat("en-CA", { timeZone: "Asia/Kathmandu" }).format(now); // YYYY-MM-DD
  const startUtc = new Date(`${dateStr}T00:00:00+05:45`);
  const endUtc = new Date(startUtc.getTime() + 24 * 60 * 60 * 1000);
  return { startUtc: startUtc.toISOString(), endUtc: endUtc.toISOString(), dateStr };
}
