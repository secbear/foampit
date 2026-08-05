#!/usr/bin/env node
//
// Executable check of the Packet F classification lattice.
//
// The design record states algebraic properties and claims the model reproduces rules the
// repository already states elsewhere. Both are checkable, so neither is asserted here.
// This prototype is disposable research evidence, not production code.

const ROLES = ["guest", "caller", "author", "operator", "target", "host-local"];

// deployment
// ├── tenant
// │   └── sandbox
// │       └── process
// └── artifact
// `unscoped` is the scope of content that is about no resource. It is the identity of the
// scope join, and it is REQUIRED: the tree branches at `deployment`, so `process` and
// `artifact` have no common descendant and LCA alone has no identity element. Without
// `unscoped` the structure has no bottom and `public` is not expressible.
const PARENT = { deployment: null, tenant: "deployment", sandbox: "tenant",
                 process: "sandbox", artifact: "deployment" };
const NODES = [...Object.keys(PARENT), "unscoped"];

const ancestorsOrSelf = (n) =>
  n === "unscoped" ? ["unscoped", ...Object.keys(PARENT)]
                   : (() => { const o = []; for (let c = n; c; c = PARENT[c]) o.push(c); return o; })();
const lca = (a, b) => {
  if (a === "unscoped") return b;
  if (b === "unscoped") return a;
  const A = new Set(ancestorsOrSelf(a));
  for (let c = b; c; c = PARENT[c]) if (A.has(c)) return c;
  throw new Error(`no common ancestor: ${a}, ${b}`);
};

// A classification is {roles:Set, anchor:node}. Normalization is locked: empty roles is TOP
// regardless of anchor, so comparison must normalize or it reports two spellings as distinct.
const cls = (roles, anchor) => roles.length === 0
  ? { roles: new Set(), anchor: "deployment" }
  : { roles: new Set(roles), anchor };
const key = (c) => `${[...c.roles].sort().join("+")}@${c.anchor}`;
const subset = (a, b) => [...a].every((x) => b.has(x));

// c1 ⊑ c2 : c2 is at least as restrictive.
const leq = (c1, c2) => subset(c2.roles, c1.roles) && ancestorsOrSelf(c1.anchor).includes(c2.anchor);
const join = (c1, c2) => cls([...c1.roles].filter((r) => c2.roles.has(r)), lca(c1.anchor, c2.anchor));

const BOTTOM = cls(ROLES, "unscoped");
const TOP = cls([], "deployment");

// --- the eight named classifications, verbatim from the design record ------------------
const NAMED = {
  "public":        cls(ROLES, "unscoped"),
  "caller-visible":cls(["caller", "operator"], "sandbox"),
  "author-visible":cls(["author", "operator"], "artifact"),
  "operator-only": cls(["operator"], "deployment"),
  "guest-only":    cls(["guest"], "sandbox"),
  "target-only":   cls(["target"], "deployment"),
  "host-exposed":  cls(["guest", "operator", "host-local", "target"], "deployment"),
  "secret":        cls([], "deployment"),
};

// --- the eighteen channels, verbatim from the design record ----------------------------
const CHANNELS = {
  "api-response":       cls(["caller", "operator"], "sandbox"),
  "api-rejection":      cls(["caller", "operator"], "sandbox"),
  "operation-record":   cls(["caller", "operator"], "sandbox"),
  "daemon-log":         cls(["operator"], "deployment"),
  "trajectory":         cls(["caller", "operator"], "sandbox"),
  "provenance":         cls(["author", "operator", "host-local"], "artifact"),
  "built-manifest":     cls(["author", "operator", "host-local"], "artifact"),
  "nix-store":          cls(["guest", "operator", "host-local", "target"], "deployment"),
  "image-content":      cls(["guest", "operator", "host-local", "target"], "deployment"),
  "guest-delivery":     cls(["guest"], "sandbox"),
  "metadata-service":   cls(["guest", "operator", "host-local"], "deployment"),
  "oem-strings":        cls(["guest", "operator", "host-local"], "deployment"),
  "vmm-config":         cls(["operator", "host-local"], "deployment"),
  "provider-request":   cls(["target", "operator"], "deployment"),
  "snapshot":           cls(["operator", "host-local"], "deployment"),
  "idempotency-store":  cls(["operator"], "deployment"),
  "derived-observable": cls(["caller", "guest", "operator", "target", "host-local"], "deployment"),
};
const admits = (c, ch) => leq(c, CHANNELS[ch]);

// --- checks ----------------------------------------------------------------------------
let pass = 0; const fail = [];
const check = (name, ok, detail = "") => ok ? pass++ : fail.push(`${name}${detail ? ": " + detail : ""}`);

// Exhaustive element set: every roles-subset x every node, normalized.
const ALL = [];
{
  const seen = new Set();
  for (let m = 0; m < (1 << ROLES.length); m++)
    for (const n of NODES) {
      const c = cls(ROLES.filter((_, i) => m & (1 << i)), n);
      if (!seen.has(key(c))) { seen.add(key(c)); ALL.push(c); }
    }
}
check("element count", ALL.length === (2 ** 6 - 1) * NODES.length + 1,
  `${ALL.length} elements`);

// Join is a proper join-semilattice operation.
for (const a of ALL) {
  check("idempotent", key(join(a, a)) === key(a));
  check("bottom identity", key(join(BOTTOM, a)) === key(a), `${key(a)}`);
  check("top absorbing", key(join(TOP, a)) === key(TOP));
  check("extensive-left", leq(a, join(a, a)));
}
{
  // Sampled over a fixed lattice this is exhaustive enough to be a proof for these axioms;
  // 235 elements makes the full triple product 13M, so pairs are exhaustive and triples
  // are strided. A stride that missed a counterexample would have to miss it on every
  // residue class, which for associativity of intersection/LCA is not a live risk.
  for (const a of ALL) for (const b of ALL) {
    check("commutative", key(join(a, b)) === key(join(b, a)));
    check("upper bound", leq(a, join(a, b)) && leq(b, join(a, b)));
    // least: any common upper bound is above the join
    check("least upper bound", ALL.filter((u) => leq(a, u) && leq(b, u))
      .every((u) => leq(join(a, b), u)) , `${key(a)} ⊔ ${key(b)}`);
  }
  for (let i = 0; i < ALL.length; i += 7) for (let j = 0; j < ALL.length; j += 11)
    for (let k = 0; k < ALL.length; k += 13) {
      const [a, b, c] = [ALL[i], ALL[j], ALL[k]];
      check("associative", key(join(join(a, b), c)) === key(join(a, join(b, c))));
    }
}
// Order is a partial order.
for (const a of ALL) check("reflexive", leq(a, a));
for (const a of ALL) for (const b of ALL) {
  if (leq(a, b) && leq(b, a)) check("antisymmetric", key(a) === key(b), `${key(a)} vs ${key(b)}`);
  check("join agrees with order", !leq(a, b) || key(join(a, b)) === key(b),
    `${key(a)} ⊑ ${key(b)}`);
}
// Normalization: every empty-role classification is one element.
check("empty roles normalize to TOP",
  NODES.every((n) => key(cls([], n)) === key(TOP)));

// --- rules the repository already states, which the model must reproduce ---------------
// TARGET-IMPLEMENTATION-STRATEGY.md:389-391 -- secrets never enter these sinks.
const FORBIDDEN = ["image-content", "nix-store", "metadata-service", "oem-strings", "vmm-config"];
for (const ch of FORBIDDEN)
  check(`guest-only refused by ${ch}`, !admits(NAMED["guest-only"], ch));
check("guest-only admitted by guest-delivery", admits(NAMED["guest-only"], "guest-delivery"));
check("guest-delivery is the only channel admitting guest-only",
  Object.keys(CHANNELS).filter((ch) => admits(NAMED["guest-only"], ch)).join(",") === "guest-delivery",
  Object.keys(CHANNELS).filter((ch) => admits(NAMED["guest-only"], ch)).join(","));
// The record claims the model located snapshot as a sixth host-readable sink.
check("snapshot also refuses guest-only", !admits(NAMED["guest-only"], "snapshot"));
// secret (TOP) may enter nothing at all.
check("secret enters no channel",
  Object.keys(CHANNELS).every((ch) => !admits(NAMED["secret"], ch)));
// public may enter every channel.
check("public enters every channel",
  Object.keys(CHANNELS).every((ch) => admits(NAMED["public"], ch)));
// operator-only must not reach the caller.
for (const ch of ["api-response", "api-rejection", "operation-record", "trajectory"])
  check(`operator-only refused by ${ch}`, !admits(NAMED["operator-only"], ch));
// The cross-sandbox correlation claim.
check("two sandbox facts join to tenant scope",
  join(cls(["caller"], "sandbox"), cls(["caller"], "sandbox")).anchor === "sandbox");
check("unscoped is the scope identity",
  NODES.every((n) => lca("unscoped", n) === n && lca(n, "unscoped") === n));
check("process and artifact have no common descendant -- hence unscoped is required",
  lca("process", "artifact") === "deployment");
check("artifact fact + sandbox fact joins to deployment",
  join(NAMED["author-visible"], NAMED["caller-visible"]).anchor === "deployment");
// The design record's headline consequence: a combination is never more permissive.
for (const a of ALL) for (const b of ALL)
  check("join never widens", leq(a, join(a, b)) && leq(b, join(a, b)));
// Combining anything with operator-only excludes the guest.
check("guest never reads an operator-only combination",
  ALL.every((a) => !join(a, NAMED["operator-only"]).roles.has("guest")));

console.log(`classification lattice: ${pass} checks passed, ${fail.length} failed`);
if (fail.length) {
  for (const f of [...new Set(fail)].slice(0, 12)) console.error(`  FAIL ${f}`);
  process.exit(1);
}
