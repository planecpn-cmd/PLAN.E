// Picks the next node agent.yml may run, deterministically, from
// agent/graph-state.json. Prints the node id, or nothing if no node is
// runnable (a human gate is closed, deps are unfinished, or all done).
//
//   node scripts/agent-next-node.mjs [--skip N2,N3]
//     --skip  node ids that already have an open agent PR
//   node scripts/agent-next-node.mjs --set <node> <status>
//     records a contract's status into the state file (used by agent.yml).
// Run from the repo root.
import { readFileSync, writeFileSync } from "node:fs";

export function nextNode(state, skip = []) {
  const byId = new Map(state.nodes.map((n) => [n.id, n]));
  return (
    state.nodes.find(
      (n) =>
        n.status === "pending" &&
        !n.human_only &&
        !skip.includes(n.id) &&
        n.deps.every((d) => byId.get(d)?.status === "pass") &&
        (!n.gate || state.gates[n.gate]?.approved === true),
    )?.id ?? null
  );
}

const STATUSES = ["pass", "blocked", "halted"];

export function setStatus(state, id, status) {
  if (!STATUSES.includes(status)) throw new Error(`bad status ${status}`);
  const node = state.nodes.find((n) => n.id === id);
  if (!node) throw new Error(`unknown node ${id}`);
  node.status = status;
  return state;
}

if (process.argv[1]?.endsWith("agent-next-node.mjs")) {
  const args = process.argv.slice(2);
  const file = "agent/graph-state.json";
  const state = JSON.parse(readFileSync(file, "utf8"));
  if (args[0] === "--set") {
    writeFileSync(file, JSON.stringify(setStatus(state, args[1], args[2]), null, 2) + "\n");
  } else {
    const skip = args[0] === "--skip" ? (args[1] ?? "").split(",").filter(Boolean) : [];
    const id = nextNode(state, skip);
    if (id) process.stdout.write(id);
  }
}
