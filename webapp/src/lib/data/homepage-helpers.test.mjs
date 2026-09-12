// node webapp/src/lib/data/homepage-helpers.test.mjs
import assert from "node:assert/strict";
import test from "node:test";
import { familiesWithPublishedCounts } from "./homepage-helpers.mjs";

const families = [{ id: "f1", slug: "adventure-together" }, { id: "f2", slug: "give-back" }];
const categories = [{ id: "c1", family_id: "f1" }, { id: "c2", family_id: "f2" }];

test("counts published experiences per family and drops families with zero", () => {
  const result = familiesWithPublishedCounts(families, categories, [
    { category_id: "c1" },
    { category_id: "c1" },
  ]);
  assert.deepEqual(result, [{ id: "f1", slug: "adventure-together", publishedCount: 2 }]);
});

test("returns null, not an empty array, when nothing has a published experience", () => {
  const result = familiesWithPublishedCounts(families, categories, []);
  assert.equal(result, null);
});

test("an experience with a null or unmapped category_id is ignored, not counted anywhere", () => {
  const result = familiesWithPublishedCounts(families, categories, [
    { category_id: null },
    { category_id: "does-not-exist" },
  ]);
  assert.equal(result, null);
});

console.log("homepage-helpers.test: all assertions passed");
