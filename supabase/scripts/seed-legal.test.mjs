// node seed-legal.test.mjs  -  asserts the frontmatter + placeholder logic.
import assert from 'node:assert';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { splitFrontmatter, applyPlaceholders, UNRESOLVED } from './seed-legal.mjs';

const legalDir = join(dirname(fileURLToPath(import.meta.url)), '..', 'legal');
const read = (f) => readFileSync(join(legalDir, f), 'utf8');

// 1. Two-line frontmatter block (title + "operated by" + "Effective/Last updated").
{
  const { title, body } = splitFrontmatter(read('01-terms-of-service.md'));
  assert.equal(title, 'Terms of Service');
  assert.ok(body.startsWith('## 1. Who we are'), `got: ${body.slice(0, 40)}`);
  assert.ok(!body.includes('Last updated:'), 'frontmatter leaked into body');
}

// 2. One-line "**Plan E** · Effective:" block, with a real intro paragraph after
//    it that must be KEPT.
{
  const { title, body } = splitFrontmatter(read('05-refund-policy.md'));
  assert.equal(title, 'Refund Policy');
  assert.ok(body.startsWith('This explains how refunds'), `got: ${body.slice(0, 40)}`);
}

// 3. Risk acknowledgment: intro sentence + blockquote note are content, not
//    frontmatter.
{
  const { title, body } = splitFrontmatter(read('11-assumption-of-risk.md'));
  assert.equal(title, 'Risk Acknowledgment');
  assert.ok(body.startsWith('Shown at booking'), `got: ${body.slice(0, 40)}`);
}

// 4. Unresolved-placeholder detector: real slots caught, md checkboxes are not.
assert.ok(UNRESOLVED.test('foo [EFFECTIVE DATE] bar'));
assert.ok(UNRESOLVED.test('delete after [X] years'));
assert.ok(UNRESOLVED.test('[PAYOUT TIMING — CONFIRM: e.g. within X days]'));
assert.ok(!UNRESOLVED.test('- [ ] Emergency numbers saved'));
assert.ok(!UNRESOLVED.test('- [x] done'));
assert.ok(!'the **Grievance Policy** applies'.match(UNRESOLVED));

// 5. Substitution clears the slot.
{
  const filled = applyPlaceholders('mail [SUPPORT EMAIL] now', { 'SUPPORT EMAIL': 'x@y.z' });
  assert.equal(filled, 'mail x@y.z now');
  assert.ok(!UNRESOLVED.test(filled));
}

// 6. Every shipped doc still has at least one unresolved slot today (proves the
//    partial-seed guard is actually load-bearing, not dead code).
{
  const stems = [
    '01-terms-of-service', '02-privacy-policy', '03-booking-terms',
    '04-cancellation-policy', '05-refund-policy', '06-payment-policy',
    '07-grievance-policy', '08-account-deletion-policy', '09-community-guidelines',
    '10-safety-and-risk-policy', '11-assumption-of-risk', '12-emergency-policy',
    '13-cookie-policy',
  ];
  const withSlots = stems.filter((s) => UNRESOLVED.test(read(`${s}.md`)));
  assert.equal(withSlots.length, stems.length, `some docs have no placeholders: ${stems.filter(s => !withSlots.includes(s))}`);
}

console.log('seed-legal.test: all assertions passed');
