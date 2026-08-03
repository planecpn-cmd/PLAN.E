import { toZonedTime, format as formatZoned } from 'date-fns-tz';

const KATHMANDU_TZ = 'Asia/Kathmandu';

/**
 * Formats integer paisa into Nepali Rupees with Nepali lakh grouping (e.g. Rs. 12,50,000)
 * Rs 1 = 100 paisa
 */
export function formatNpr(paisa: number): string {
  if (paisa < 0) return `Rs. 0`;
  const rupees = Math.floor(paisa / 100);
  const numStr = rupees.toString();

  if (numStr.length <= 3) {
    return `Rs. ${numStr}`;
  }

  // Last 3 digits
  const lastThree = numStr.substring(numStr.length - 3);
  const remaining = numStr.substring(0, numStr.length - 3);

  // Group remaining digits by 2s (lakh, crore pattern)
  const grouped = remaining.replace(/\B(?=(\d{2})+(?!\d))/g, ',');

  return `Rs. ${grouped},${lastThree}`;
}

/**
 * Converts a UTC Date/string to Asia/Kathmandu timezone Date object
 */
export function toKathmandu(date: Date | string): Date {
  const d = typeof date === 'string' ? new Date(date) : date;
  return toZonedTime(d, KATHMANDU_TZ);
}

/**
 * Formats a Date in Asia/Kathmandu timezone
 */
export function formatDate(date: Date | string, formatStr: string = 'dd MMM yyyy'): string {
  const kathmanduDate = toKathmandu(date);
  return formatZoned(kathmanduDate, formatStr, { timeZone: KATHMANDU_TZ });
}

/**
 * Validates whether a string is a valid Nepali mobile phone number (+9779XXXXXXXX or 9XXXXXXXX)
 */
export function isNepaliPhone(phone: string): boolean {
  const regex = /^(\+977)?9[678]\d{8}$/;
  return regex.test(phone.trim());
}

/**
 * Formats duration: hours if under 24, days if 24 or more
 */
export function formatDuration(hours: number): string {
  if (hours < 24) {
    return `${hours} ${hours === 1 ? 'hr' : 'hrs'}`;
  }
  const days = Math.floor(hours / 24);
  return `${days} ${days === 1 ? 'day' : 'days'}`;
}
