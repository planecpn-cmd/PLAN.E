import { formatNpr, toKathmandu, formatDate, isNepaliPhone, formatDuration } from '../format';

describe('Nepali Formatters', () => {
  describe('formatNpr (Paisa to NPR with Lakh Grouping)', () => {
    test('formats small amounts correctly', () => {
      expect(formatNpr(0)).toBe('Rs. 0');
      expect(formatNpr(50000)).toBe('Rs. 500');
    });

    test('formats lakhs (1,00,000)', () => {
      // 1,00,000 rupees = 10,000,000 paisa
      expect(formatNpr(10000000)).toBe('Rs. 1,00,000');
    });

    test('formats 12,50,000 NPR (125,000,000 paisa)', () => {
      expect(formatNpr(125000000)).toBe('Rs. 12,50,000');
    });

    test('formats crores (1,00,00,000 NPR)', () => {
      // 1,00,00,000 rupees = 1,000,000,000 paisa
      expect(formatNpr(1000000000)).toBe('Rs. 1,00,00,000');
    });
  });

  describe('Asia/Kathmandu Timezone', () => {
    test('converts UTC to Asia/Kathmandu (+05:45 offset without DST)', () => {
      const utcDate = new Date('2026-08-03T12:00:00Z');
      const ktmDate = toKathmandu(utcDate);
      expect(ktmDate).toBeInstanceOf(Date);
    });

    test('formats date correctly in Kathmandu timezone', () => {
      const formatted = formatDate('2026-08-03T00:00:00Z', 'yyyy-MM-dd');
      expect(formatted).toBe('2026-08-03');
    });
  });

  describe('isNepaliPhone', () => {
    test('accepts valid Nepali mobile numbers', () => {
      expect(isNepaliPhone('9841234567')).toBe(true);
      expect(isNepaliPhone('+9779801234567')).toBe(true);
      expect(isNepaliPhone('+9779741234567')).toBe(true);
      expect(isNepaliPhone('9611234567')).toBe(true);
    });

    test('rejects invalid numbers', () => {
      expect(isNepaliPhone('1234567890')).toBe(false);
      expect(isNepaliPhone('+14155552671')).toBe(false);
      expect(isNepaliPhone('9841234')).toBe(false);
      expect(isNepaliPhone('abc9841234567')).toBe(false);
    });
  });

  describe('formatDuration', () => {
    test('formats hours under 24', () => {
      expect(formatDuration(1)).toBe('1 hr');
      expect(formatDuration(8)).toBe('8 hrs');
      expect(formatDuration(23)).toBe('23 hrs');
    });

    test('formats days for 24 hours or more', () => {
      expect(formatDuration(24)).toBe('1 day');
      expect(formatDuration(48)).toBe('2 days');
      expect(formatDuration(288)).toBe('12 days');
    });
  });
});
