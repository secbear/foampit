# Gate 2A Packet D Composition Review

Status: **Reviewed — exact machine snapshot accepted after cold
reconstruction, adversarial semantic review, and prototype-evidence sign-off**

Date: 2026-07-24

Packet D reviews every supported route by which configuration can be authored,
combined, translated, transported, lowered, extended, cached, or corrupted.
Its conclusion is not that all paths are safe by convention. Its conclusion is
that every path/invariant pair has one closed effect classification, one exact
first-sound phase and rejection deadline, one authority, and one validator
chain.

The normative machine records are:

- [`PACKET-D-COMPOSITION-PATHS.json`](./PACKET-D-COMPOSITION-PATHS.json) —
  the reviewed 54-path universe and frontend evidence mappings;
- [`PACKET-D-CASE-CONTRACTS.json`](./PACKET-D-CASE-CONTRACTS.json) — the
  independently pinned 140-invariant order, per-path classification vectors,
  boundary contracts, ownership exclusions, identity rules, and obligations;
- [`PACKET-D-COMPOSITION-COVERAGE.json`](./PACKET-D-COMPOSITION-COVERAGE.json)
  — the generated complete cross-product; and
- [`validate-composition-coverage.jq`](./validate-composition-coverage.jq) and
  [`test-composition-coverage.sh`](./test-composition-coverage.sh) — the
  expansion, exact-universe, phase, authority, ownership, digest, and
  mutation-resistance checks.

Explanatory text is not allowed to override their closed control fields.

The machine files retain their embedded `candidate` label because Task 8 is a
read-mostly decision gate: review accepts the exact bytes pinned below rather
than mutating the evidence after sign-off. `Reviewed` is the decision recorded
here, not a claim that production Gate 4B is closed.

## Reviewed universe

| Coordinate | Reviewed count |
|---|---:|
| Composition paths | 54 |
| Registered invariants | 140 |
| Exact path × invariant cells | 7,560 |
| Generated identical-contract rule groups | 634 |
| Historical registry path aliases mapped | 68 |
| Frontend/path evidence mappings | 74 |
| Invalid witnesses with nearby valid controls | 50 |
| Initial Packet C target profiles preserved | 4 |
| Serialized built-member/load invariants replayed | 89 |
| Serialized C0–D0 resolved-stage invariants replayed | 30 |
| Native-surface paths | 19 |

The reviewed path/category partition is:

| Category | Count | Paths |
|---|---:|---|
| Authoring | 18 | 8 resource-qualified Artifact paths, 5 Operator Configuration paths, 5 Managed-Service Definition paths |
| Frontend boundary | 2 | renderer output and renderer-to-wire adaptation |
| Artifact native | 6 | namespaced extension, typed/direct Nix values, guest/target native, unsafe opaque extension |
| Lifecycle native | 6 | create, operator, service, live, Exec, and adapter native inputs |
| Provider native | 7 | prebuilt/OCI transfer, cache, provider adapter/operation/construction |
| Downstream boundary | 11 | raw/migrated wire, lowering, manifests, provider results, and five distinct driver trust states |
| Caller | 4 | direct API, framework, CLI, and managed service |

Adding a path, invariant, target profile, frontend mapping, extension form,
provider mode, cache route, migration route, or direct-driver route reopens
Packet D and changes a validator-owned absolute universe.

## Effect decision

The 7,560 cells have this exact partition:

| Effect | Cells | Meaning |
|---|---:|---|
| `may-contribute` | 145 | May add data only within the path's owned, closed schema |
| `may-narrow` | 32 | May reduce a declared bound or authority |
| `may-select` | 54 | May choose only among explicitly declared alternatives/defaults |
| `boundary-input` | 828 | Entire input is untrusted and fully revalidated through semantic completeness |
| `no-authority:foreign-owner` | 2,440 | Path cannot author the other resource owner |
| `no-authority:immutable-artifact-fact` | 2,751 | Later/caller/provider path cannot rewrite immutable Artifact or identity facts |
| `no-authority:same-owner-stage-or-fact-class` | 1,268 | Same owner does not imply authority over builder/member/conformance/observed or other later-stage facts |
| `no-authority:hard-contract-nonwidening` | 42 | Path is relevant to the hard/common rule but cannot weaken, replace, or mint it |

There is no `not-applicable`, warning-only, best-effort, fallback, or
backend-default result.

The independent case catalog stores one 140-code classification vector for
each path. It is a total partition, not a generated owner heuristic. SHA-256
pins add review friction; they are not semantic proof. The validator therefore
also owns exact projections for all 54 complete path contracts, 74 normative
frontend mappings, 68 aliases, and every field of all 28 contract templates.
Coordinated catalog, path, and regenerated-coverage mutations must fail those
independent semantic anchors even when digest checks are neutralized.

## Validator chains

The product phase model is a graph. `F0` and `S0` are ingress nodes; live and
Exec are repeatable sibling branches. Packet D does not impose one false total
order.

| Path family | Required chain |
|---|---|
| Artifact authoring/composition | `P1 -> A0/A1/W0`; defensive W0 replay precedes N0 construction |
| Operator Configuration authoring/composition | `P1 -> OC0/O0`; closed source completion and final Operator validation, with no Artifact phase |
| Managed-Service Definition authoring/composition | `P1 -> MS0/S0`; closed source completion and final Definition validation, with no Artifact phase |
| Serialized frontend/adaptation/raw wire | strict bounded W0 decode/adaptation → the same complete A1 semantic implementation replayed at W0 → semantic identity → N0 typed-handle continuation when present |
| Schema migration | exact old-schema validation → deterministic migration → complete current-schema/A1 replay → canonical identity; no downgrade or fallback |
| Native handle/direct Nix input | W0 validates only serializable identity/reference shape; N0 binds source closure, registry namespace/version/digest, export, interface, system, member, effect projection, and construction identity |
| Guest/target native | A1 scope and common-contract check → W0 identity → N0 Packet C contract/effect rederivation → N1 independent member/manifest verification |
| Target lowering | validated Artifact → N0 all Packet C field/profile/native contracts → N1 build → N1 independent member verifier → C0 manifest load; later owner facts continue to their own phase |
| Built manifest/member | N1 result remains untrusted → C0 closed manifest/protocol/profile/content/evidence verification → creation resolution |
| Provider construction/cache result | N0 pinned request/default suppression → N1 provider result → product-owned identity/equivalence/evidence verification → C0 load |
| Provider transfer/cache hit | Ends at H0 or D0 content/descriptor verification, then hands off to `built-artifact-load` as a separate C0 path; there is no H0→C0 phase edge |
| Resolved driver handoff | `C0 -> O0 -> H0 -> D0`; only private product stages proceed |
| Serialized resolved reentry | `RW0 -> C0 -> O0 -> H0 -> D0`; replay the exact 89 built-load and 30 resolved-stage arrays before constructing fresh private stages |
| Generated runtime configuration | D0 product output and validation; exact total schema and backend-default suppression |
| Direct driver invocation / raw runtime configuration | D0 rejection-only; neither path has an admitted value |
| Framework/CLI/managed service | F0/S0 translation only → the same typed Core Sandbox API at C0, L0, E0, or T0 |

A boundary can inspect an input before an invariant is semantically complete
without claiming to decide that invariant. For example, W0 validates the shape
of a typed native handle, but `NAT-003` remains open until N0 resolves and
compares the complete native identity. Each cell therefore records its own
terminal contract; rules group only cells with identical effects, phases,
authority, chain, exclusions, and obligations.

Framework and CLI use the same typed Create/live/Exec translation. Teardown
state transitions, cleanup, retry, and idempotency remain delegated to Packet
E rather than claimed by Packet D.

The five driver trust-state vectors remain distinct:
`resolved-driver-handoff` has 15 contribute, 7 narrow, and 118 no-authority
cells; `serialized-resolved-reentry` has 107 boundary-input and 33
no-authority cells; `generated-runtime-configuration` has 2 boundary-input and
138 no-authority cells; and both `direct-driver-invocation` and
`raw-runtime-config-input` are 140 no-authority cells. Generated backend
configuration is output from D0, not a direct/raw input form.

The six machine-owned handoffs all resume at the C0 `manifest-load` boundary
of `built-artifact-load`: `prebuilt-member-transfer` and
`oci-descriptor-transfer` hand off after H0; `provider-cache-hit` after D0;
and `provider-side-construction`, `provider-build-cache`, and
`corrupted-provider-build-result` after N1. Every record is
`separate-path-handoff`.

The target applicability projection is also closed: `portable` maps to no
runtime profiles; `all-packet-c-profiles` and `remote-provider` map to all
four Packet C profiles; explicit profile lists map exactly; and the
OCI-plus-remote form maps only to OCI. Consequently native guest modules
project to the two microVM profiles and OCI descriptor transfer only to
`oci-linux-v1`.

For structural `no-authority` cells, the authority is exactly the phase and
component named by `rejectedForeignOwnerAt`. Hard-contract non-widening cells
instead preserve the invariant registry's semantic timing and authority.

## Strongest mechanisms

- A strongest frontend/Nix priority may select only a declared replaceable
  default. It has no authority over hard policy; safe narrowing uses the
  declared refinement path.
- Frontend-native open values, force/update/amend operations, FFI/external
  readers, alternate exports, and unpinned imports have no product authority.
  A source language may represent or render them, but adaptation/W0 rejects
  the resulting invalid candidate.
- Target-native content may contribute only a registered target-local payload,
  complete native identity, and total Packet C effect projection. It cannot
  author portable/common policy, operator state, support claims, conformance
  claims, secrets, provider objects, or runtime-profile selection.
- Unsafe opaque extensions have no conforming result. An extension without a
  total product-derived effect projection is rejected or explicitly typed as
  non-conforming.
- Providers, caches, manifests, adapters, and callers preserve identity only.
  None can mint Artifact, member, support, semantic, or conformance identity.

## Executed research evidence

The disposable research suite proves the original mechanism and the next
product-owned boundary, not merely a parser error:

| Witness group | Passing cases |
|---|---:|
| Strengthened Nix | 31 |
| Nix Operator/Service resource composition | 14 cases / 172 internal assertions |
| CUE | 16 |
| Nickel | 19 |
| Pkl | 18 |
| Dhall research control | 12 |
| Native handle/construction identity | 10 |
| Frontend adaptation | 18 |
| Strict W0 decoding/canonical validation | 27 |
| Resolved reentry/private stages | 13 cases / 18 diagnostic / 8 identity / 44 projection / 6 stale-semantic probes |
| Migration, manifest, and downstream driver boundaries | 40 |

Each serious foreign frontend has a source-valid rendered-invalid candidate
that passes its renderer and the total shape adapter before W0 rejects the
invalid Artifact semantic. Dhall remains a research control, not an initial
product commitment.

These are research witnesses. Production enforcement hooks, conformance tests,
attestations, private validated stage types, and concrete module paths remain
honestly `planned` for Gate 4B.

## Findings corrected during review

The review rejected four false proofs before accepting the matrix:

1. Owner-only classification incorrectly allowed ordinary authoring to
   contribute builder/provider facts.
2. One effect per path incorrectly granted strongest overrides and
   target-native extensions authority over protected invariants.
3. One phase contract per path tried to finish native identity at W0 and
   delayed a target-native contradiction beyond its N0 deadline.
4. Structural no-authority cells named an A1 rejecting boundary while calling
   W0 authoritative.

The final catalog uses per-invariant classification plus per-cell terminal
contracts. Focused mutations pin these regressions, normal/corrupted forms
share the same applicability contract, and all structural exclusions name the
actual rejecting authority.

Prototype review also corrected native identity that previously did not affect
the derivation, adapter omissions that previously became `null`, missing
exact-bound decoder controls, unbound manifest member/evidence digests, and a
token-only retained-source witness.

Final sign-off then found and corrected additional false-green oracles:

1. coordinated owner, rejecting-boundary, applicability, alias, frontend, and
   template rewrites could pass relationships that compared two mutable
   sources to each other;
2. typed Create/live/Exec parity covered framework and CLI adapters but omitted
   direct Core API requests;
3. the resolved-runtime expected configuration was copied from generator
   output, so a valid-shaped generator defect could redefine its own oracle;
4. prototype totals were printed but not all enforced, seven diagnostic probes
   lacked a value they could prove was not disclosed, and authenticated
   reentry did not mutate every documented stale identity.

The repaired validator independently anchors every normative path and template
field and executes 11 coordinated-regeneration regressions in addition to the
earlier mutation corpus. The repaired runtime harness uses separately authored
complete expectations for all four profiles, enforces every reported total,
requires 18 distinct leak markers, and revalidates stale Artifact, member,
Create, policy, profile, and retained-source identities.

## Delegations and limits

Packet D's exact machine-owned delegated taxonomy is:

- Packet E: `operation-transition`, `retry`, `cancellation`, and `cleanup`;
- Packet F: `disclosure`, `redaction`, and `evidence-visibility`.

Timeout, rollback, partial failure, reservation, mutation, restore, orphan
cleanup, teardown, and operation idempotency are Packet E work within those
four categories. Secret-safe diagnostics/logs/provenance, evidence retention,
claimed-versus-measured presentation, and side-channel claim boundaries are
Packet F work within its three categories. These explanatory examples do not
expand the closed taxonomy.

Those delegations do not delegate composition safety. A Packet E/F path cannot
reinterpret or widen the Artifact, skip the Core API, trust a manifest/provider
claim, or mint identity.

Packet D completion therefore does **not** close Gate 2A. Packets E and F remain
required, and Gate 4B must continue to fail while hooks, executable
conformance tests, and implementation evidence remain planned.

## Review evidence

- Path registry SHA-256:
  `488bf76167461b52766dd9fa8a9b1756d084f1ebc08c795315fd2baf2fbab6e0`
- Case-contract catalog SHA-256:
  `955c3dd8c03927be6876c58b2c3c67210f1fc0710ecf5f5ea2a4a2c59bc3f5b0`
- Invariant registry SHA-256:
  `8901d7f384a8fea6b5c8bec82271b4456b4052b988ba74ff1947adda5a768ee2`
  (reviewed as `d798c8fd82ddfe590cc252ce01829a1e4440489b2bd3ca3542c655fcee3284c2`;
  amended by the 2026-07-31 coherence repair, which added the
  `frontend-evaluation` and `artifact-final-validation` trust boundaries to the
  `CMP-009`, `CMP-010`, and `CMP-011` wire-corruption test coverage and added
  `VAL-011` as a valid witness of `SVC-001` and `SVC-002`. No classification,
  path, phase, owner, or effect changed, so the reviewed verdicts below stand.)
- Generated coverage SHA-256:
  `16b156ef2d39c10f55f5aedb5abc025385b865e7d92f9a8ccbb2dd4bf635e532`
- Validator SHA-256:
  `7f9777d36527c8aa0ef571cecc435c4254d8072abca7cd962912d2dec780a31a`
- Focused harness SHA-256:
  `fefac4fb2b7bddc263417e39c04793e1afbab157daf71b510c35fc61c21c936e`
- Focused Packet D validator: 89 cases passed.
- Exact expansion: 54 × 140 = 7,560 unique cells.
- Exact grouping: 634 complete-contract rules.
- Exact effect partition: 145 `may-contribute`, 32 `may-narrow`, 54
  `may-select`, 828 `boundary-input`, and 6,501 `no-authority`.
- All 6,459 structural no-authority cells align authority with their named
  rejecting boundary.
- All 42 hard-contract cells preserve registry timing and authority.
- Generator drift, JSON parsing, exact semantic projections, and digest pins
  pass.
- The integrated inventory and prototype suites are green. Resolved reentry
  enforces 13 cases, 18 marker-bearing diagnostic probes, 8 prepared-identity
  mutations, 44 generated-projection leaves, and 6 stale-semantic
  revalidations; downstream enforces 40 cases; Operator/Service composition
  enforces 14 cases and 172 internal assertions.
- Cold reconstruction independently recovered 54 paths, 140 invariants, 7,560
  cells, 634 groups, the 23-phase/32-edge acyclic graph, five driver states,
  exact 89+30 replay arrays, six handoffs, the E/F taxonomy, and the ten-key
  native identity tuple.
- Adversarial semantic review and two crossed re-reviews rejected coordinated
  owner, phase, template, applicability, alias, frontend, replay, direct/raw,
  diagnostic-disclosure, and generated-configuration mutations without
  relying on digest pins.
- Prototype-evidence review confirmed the real Nix module mechanisms, private
  Rust stages and compile barriers, total four-profile generation, exact
  counters, and the deliberate separation between disposable evidence and
  production closure.
- All three final reviewer verdicts are clean. Gate 2A remains open only for
  Packets E and F, and enforcement closure intentionally remains at Gate 4B
  because all 140 production hooks and 560 production tests are still
  `planned`.
