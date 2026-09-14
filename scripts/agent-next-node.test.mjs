// node --test scripts/agent-next-node.test.mjs
import assert from "node:assert/strict";
import test from "node:test";
import { readFileSync } from "node:fs";
import { nextNode, setStatus } from "./agent-next-node.mjs";

const real = () => JSON.parse(readFileSync(new URL("../agent/graph-state.json", import.meta.url), "utf8"));

test("closed H1 means nothing runs (N2 stays blocked)", () => {
  assert.equal(nextNode(real()), null);
});

test("approving H1 releases N2 first, then F1 when N2 has an open PR", () => {
  const s = real();
  s.gates.H1.approved = true;
  assert.equal(nextNode(s), "N2");
  assert.equal(nextNode(s, ["N2"]), "F1");
});

test("sections wait for N2 to pass; human-only F2 is never picked", () => {
  const s = real();
  s.gates.H1.approved = true;
  s.gates.H2.approved = true;
  setStatus(s, "N2", "pass");
  setStatus(s, "F1", "pass");
  assert.equal(nextNode(s), "N3");
  for (const id of ["N3", "N4", "N5", "N6", "N7", "N8", "N9"]) setStatus(s, id, "pass");
  assert.equal(nextNode(s), "N10");
  assert.equal(nextNode(s, ["N10"]), null, "F2 is human_only, N11 needs G-FINAL");
});

test("a blocked dependency stops dependents", () => {
  const s = real();
  s.gates.H1.approved = true;
  setStatus(s, "N2", "blocked");
  assert.equal(nextNode(s, ["F1"]), null);
});

test("setStatus rejects unknown status and node", () => {
  assert.throws(() => setStatus(real(), "N2", "done"));
  assert.throws(() => setStatus(real(), "N99", "pass"));
});
