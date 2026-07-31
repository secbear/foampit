# Packet E Runtime Lifecycle and Trust Boundary Inventory Walk Implementation Plan

> **For agentic workers:** Steps use checkbox (`- [ ]`) syntax for tracking.
> Execute task-by-task. Do not reorder tasks; the ordering encodes irreversible
> identifier-allocation and digest-pinning constraints.

**Goal:** Close Gate 2A's Packet E scope by converting the four locked Packet E
decision records' registry obligations into an exhaustive machine-readable
operation-contract ledger plus stable registry entries with witnesses, phases,
dispositions, planned hooks, planned tests, and diagnostics, so that the only
remaining Gate 2A packet is F.

**Architecture:** Packet E follows the Packet C/D shape. A hand-authored
operation registry fixes the closed axis vocabularies; a stripped, digest-pinned
case-contract catalog fixes the per-cell control fields; a generator expands one
total, disjoint operations × lifecycle-states matrix; an independent jq
validator recomputes every structural identity; and a bash mutation harness
proves the validator rejects coordinated rewrites. Specification-totality
meta-rules become validator rules over that ledger rather than registry
entries. Semantic invalid states become registry entries in
`invariants.json`, each with one owner and one earliest-sound boundary, and each
widening the Packet D composition matrix from 54 × 140 to 54 × N.

**Tech Stack:** Markdown, JSON, `jq`, `rg` (ripgrep — GNU grep cannot
substitute), Bash, Node.js (ambient PATH; not present in the `test-all.sh` nix
shell), `shasum -a 256`, `comm`, `awk`.

---

## Global Constraints

- This is greenfield design work under `docs/greenfield/`. Existing product
  implementation code is not an input, and no production implementation is
  authorized by this plan.
- The four locked Packet E decision records are the design authority:
  `PACKET-E-OPERATION-IDENTITY-DESIGN.md`,
  `PACKET-E-LIFECYCLE-STATE-DESIGN.md`,
  `PACKET-E-OPERATION-TAXONOMY-DESIGN.md`, and
  `PACKET-E-RESULT-ERROR-CONTRACT-DESIGN.md`. Their locked sections may not be
  weakened, reinterpreted, or silently extended. `DESIGN.md:232-588` mirrors
  them normatively.
- Every new registry entry has exactly one owner and exactly one earliest-sound
  boundary. A listed obligation that spans two owners or two boundaries is
  **partitioned** into separate entries, never compressed into one.
- Production hooks and tests remain `planned`. No entry may be marked `closed`,
  no hook `production`, no test `passing`. `check-enforcement-closure.sh` must
  remain red; turning it green is forbidden by `CONTRIBUTING.md:53-54`.
- Every new invalid witness has a nearby valid witness.
- Generated files are never hand-edited. Change the generator, regenerate,
  and compare with `--check`.
- Registry entries are **appended** to the tail of `.invariants`. Never inserted
  mid-array: Packet D rule-group identifiers are assigned in first-encounter
  order over registry order, and mid-array insertion silently renumbers
  downstream `DCR_*` identifiers and misclassifies every positional
  classification cell.
- Digest re-pinning is a step taken **after** the semantic suite passes, never a
  shortcut to make it pass. Both copies of each pin move together.
- Packet E does not close Gate 4B and does not close Gate 2A by itself; Packet F
  remains required.
- Disposable research evidence must not be relabeled as production closure.
- Do not stage, commit, push, or publish. Preserve unrelated workspace content.

---

## Verified Baseline (2026-07-31, commit `7663ed7`)

| Fact | Value |
|---|---|
| Registry entries | 140, all `scope:"v1"`, all `status:"specified"` |
| Planned hooks / tests | 140 / 560 |
| Corpus cases | 140 `####` invalid + 42 `### VAL-` valid |
| Packet D universe | 54 paths × 140 invariants = 7,560 cells, 634 rule groups |
| `check-inventory.sh` | exit 0, ~2 m 13 s |
| `check-enforcement-closure.sh` | exit 5, 1,481 lines, intentionally red |
| Obligations listed across the four Packet E records | 178 |
| Distinct semantic rules after cross-document dedup | 144 |
| Projected registry entries after partition | 185 (low 145 / high 240) |

---

### Task 1: Record the binding structural rulings

**Files:**

- Create: `docs/greenfield/research/invariants/PACKET-E-OPERATION-CONTRACT-REVIEW.md`
- Modify: `docs/greenfield/research/invariants/INVENTORY-REVIEW.md`

**Interfaces:**

- Consumes: the four Packet E decision records; `INVARIANT-ENFORCEMENT.md`
  protocol; the closed vocabularies in `validate-registry.jq:1-93`.
- Produces: a recorded ruling for each blocking decision, binding on every
  later task.

- [ ] **Step 1: Record the owner ruling**

  The closed owner set is `artifact create operator service live exec framework
  runtime` (`validate-registry.jq:48-58`). In the current registry `runtime`
  denotes the **driver/provider boundary** (`DRV-*`, `WIRE-*` at `D0`/`RW0`) and
  `service` denotes the **Managed-Sandbox Service Definition** (`SVC-*` at
  `MS0`/`S0`). Neither denotes the Core Sandbox API service control plane that
  owns Operation acceptance, authority fencing, retention, reconciliation, and
  terminal immutability — the owner of roughly half of Packet E.

  **RULED (2026-07-31): extend the closed set with a ninth owner value for the
  Core Sandbox API control plane.** `runtime` remains driver/provider-scoped and
  `service` remains the Managed-Sandbox Service Definition. The ruling is
  recorded once and applied uniformly; no entry mixes conventions.

  **Four** machine locations pin the closed 8-owner set and must move in
  lockstep. This plan authorizes editing all four:

  | File | Location | Enforced at |
  |---|---|---|
  | `validate-registry.jq` | `:48-58` (`def owners`) | `:157-159` |
  | `validate-surface-coverage.jq` | `:1-5` (`def owners`) | `:56` |
  | `generate-composition-coverage.mjs` | `:18-27` (`const owners`) | `:94-99` |
  | `validate-composition-coverage.jq` | `:59-60` (`def owners`) | `:2439` |

  The generator assertion at `mjs:94-99` throws *before* any write, so a stale
  enum makes regeneration impossible rather than merely red. Verified end to
  end: one entry carrying an unregistered owner produces `unknown owner: …` from
  `validate-registry.sh`, `every invariant owner must be in the closed Packet D
  owner universe` from the generator, and 54 `unknown invariantOwner` errors
  from the full-scope validator.

  Prose also touches the corpus "Locked Owners" table (corpus lines 42-56) and
  the `INVENTORY-REVIEW.md` owner-distribution table.

  This does **not** force a `PACKET-D-COMPOSITION-PATHS.json` change unless a
  path gains the owner in `reachableOwners`. If no path does, every
  active-effect cell for a Core-owned invariant is mechanically `F` — the
  correct reading for a runtime-service rule on a configuration composition
  path. Determine deliberately whether any path *should* gain the owner and
  record the answer; silence is not a decision. This affects active effects
  only: `B` is not owner-gated (Tasks 4-7 Step 4).

- [ ] **Step 2: Record the phase-graph ruling**

  Three Packet E flows have no representation in the 23-phase vocabulary:

  1. `StartSandbox` on a stopped Sandbox must re-enter `D0`/`R0`, but the graph
     has only `L1 -> T0`.
  2. Retention, tombstone, and post-deletion obligations have no node after
     `T0`.
  3. System-originated reconciliation, adoption, fencing, and quarantine
     Operations have no ingress phase comparable to `F0`/`S0`.

  **RULED (2026-07-31): no phase or edge is added. The graph is a
  validation-order model over a single traversal, not a runtime-history model.**

  Each node names an **information set** — the facts completely available at
  that station. Reachability is a soundness relation over *decidability*, not a
  claim about temporal succession: two phases may both occur after launch and
  remain mutually unreachable (`L0 -> E0`). Repetition, re-entry, and succession
  *between* operations are deliberately unrepresentable. An operation that ends
  and thereby authorizes another **begins a new traversal with its own
  first-sound phase**, linked by a handoff record, never by a phase edge.
  Runtime history is modeled on a different substrate entirely: the
  monotonically increasing runtime epoch over immutable Operation, Process,
  event, and tombstone records.

  A phase may be added only when a genuinely new **information set** enters the
  product — typically a new trust boundary decoding a value no existing phase
  can describe — and never to express that an existing information set was
  reached *again*, *from a different caller*, or *later in time*.

  The ruling is computationally forced, not merely textual. Every candidate
  restart edge creates a cycle **and** makes `reachable(L0;E0)` true, which
  directly contradicts `INVARIANT-ENFORCEMENT.md:332-333`:

  | Candidate edge | Cycle created | `reachable(L0;E0)` |
  |---|---|---|
  | `L1 -> R0` | `{R0,R1,L0,L1}` | **true** |
  | `L1 -> C0` | `{C0,O0,H0,D0,R0,R1,L0,L1}` | **true** |
  | `L1 -> D0` | `{D0,R0,R1,L0,L1}` | **true** |
  | `T0 -> C0` | 11-node cycle | **true** |

  Supporting evidence: the corpus column heading is literally "Complete
  information available"; `INVARIANT-ENFORCEMENT.md:279-280` says the phases
  "form a graph, **not one false global timeline**"; `:328-329` says handoff
  records "do not add phase edges"; and `crossPathHandoffs` in
  `PACKET-D-CASE-CONTRACTS.json` **already** models a backward `D0 -> C0` jump
  with no edge.

  **Hard prohibition (normative, not stylistic).** `firstSoundPhase` may never
  name an ingress or resolution phase that the operation being described does
  not itself traverse. The phase pair is the *filter input* to
  `activeBoundaryChain` (`generate-composition-coverage.mjs:263-270`) and
  `expected_active_chain` (`validate-composition-coverage.jq:1272-1276`), which
  mechanically selects which components the corpus asserts defensively
  revalidate the rule across all 54 paths. Running the real algorithm on a
  `C0 -> R1` Start assignment generates a chain claiming `creation-resolver` and
  `core-api-request-validator` revalidate a Start postcondition — for an
  operation with no `CreateSandbox` input. That is a **false coverage claim,
  generated silently, in the artifact the gates treat as reviewed coverage.**

  Per-gap dispositions are recorded in Task 4 Step 3.

- [ ] **Step 3: Record the Packet E / Packet F disclosure ruling**

  RESULT #10 (permission response leaking resource existence), RESULT #42 (raw
  provider evidence escaping redaction and size bounds), and the bounded
  public-detail rules sit on the Packet E/F seam. Record the split:

  - Packet E owns the **semantic** rule: authorization precedes existence
    disclosure and detailed validation; provider evidence is protected,
    bounded, and never a public union extension.
  - Packet F owns the **disclosure-channel** rule: what may appear in logs,
    diagnostics, trajectories, provenance, and evidence sinks.

  Name each affected obligation explicitly on one side. An obligation named on
  both sides is a defect.

- [ ] **Step 4: Record the ledger-versus-registry ruling**

  Specification-totality meta-rules — "an absent operation-contract cell treated
  as implementation discretion", "a wildcard or default operation outcome", "an
  operation pair with no compatibility entry treated as permitted" — follow
  Packet C/D precedent and become **validator rules over the Packet E ledger**,
  not registry entries. Record the list of obligations resolved this way and the
  validator rule each becomes. This is worth roughly 10-15 entries and fixes
  the projected total.

- [ ] **Step 4b: Record the ledger-axis ruling**

  `PACKET-E-OPERATION-TAXONOMY-DESIGN.md:939-960` requires the ledger to close a
  **16-dimension** Cartesian product, and
  `PACKET-E-RESULT-ERROR-CONTRACT-DESIGN.md:1379-1401` lists **21** required
  dimensions. Task 9 encodes two axes with the remainder factored into ordered
  `valueCases`. That factoring is almost certainly the right engineering choice
  — both Packet C and Packet D pick exactly two axes — but it is a reduction of
  a Locked section, and Global Constraints forbid weakening or silently
  reinterpreting one.

  Critically, these dimension lists sit **outside** the 178 numbered
  obligations, so Task 2's per-obligation disposition record structurally cannot
  reach them. They need their own ruling.

  Record, one line per dimension across both lists, exactly one disposition:
  **ledger axis**, **ordered `valueCase` inside a cell**, **`predicateId`
  condition**, **carried by a registered invariant** (name it), or **explicitly
  delegated to Packet F** (with rationale). A dimension named on two sides, or
  on none, is a defect. This ruling is what makes the factored encoding an
  equivalent representation rather than a silent narrowing, and it binds
  Tasks 9, 10, and 13.

- [ ] **Step 4c: Record the token-spelling ruling**

  Record that Packet E's ledgers namespace the locked `unknown` token as
  `state-unknown` and `outcome-unknown` (see Task 8 Step 2) rather than
  deviating from the `placeholder_strings` definition shared byte-identically by
  five existing validators, and that each vocabulary entry carries a
  `lockedSourceToken` naming its design-record origin.

  Record the alternative considered — making `^UNKNOWN$` case-sensitive in the
  Packet E validator only — and why it was rejected: it would make one
  validator's placeholder rule differ from every sibling, and "delete the
  placeholder rule" must never be the path of least resistance. This ruling
  binds Tasks 8, 9, and 11.

- [ ] **Step 5: Record the valid-witness convention**

  All 140 current entries carry exactly one `VAL-*` valid witness. Record
  whether new entries stay 1:1 (recommended; preserves the convention and avoids
  a retrofit that would edit both the corpus and every `positive-boundary` test
  `case`) or may reuse an existing `VAL-*` where it genuinely covers the nearby
  valid state. Next free identifier is `VAL-043`.

- [ ] **Step 6: Verify the baseline is still green before any edit**

  ```sh
  docs/greenfield/research/invariants/check-inventory.sh
  ```

  Expected: exit 0, ending `Gate 2A remains open for Packets E-F`. Record the
  observed counter lines verbatim; later tasks compare against them.

---

### Task 1A: Repair the phase model and its duplicated copies

The phase model is stated in **five** places. Nothing compares them, and three
have already drifted. Repairing this precedes identifier allocation because
Packet E is about to assign roughly 185 phase pairs against it, and because
Packet E is the first packet to inhabit the post-launch region at all.

**Files:**

- Modify: `docs/greenfield/research/invariants/validate-registry.jq`
- Modify: `docs/greenfield/research/invariants/validate-composition-coverage.jq`
- Modify: `docs/greenfield/research/invariants/test-registry.sh`
- Modify: `docs/greenfield/research/CONFIGURATION-LANGUAGE-CORPUS.md`
- Modify: `docs/greenfield/research/INVARIANT-ENFORCEMENT.md`

- [ ] **Step 1: Collapse the two reachability models into one**

  `phase_paths` (`validate-registry.jq:20-46`) and `phase_edges`
  (`validate-composition-coverage.jq:1147-1171`) disagree on **four** ordered
  pairs out of 529, computed exhaustively — the graph admits 233, the paths 231,
  the enforced intersection 230:

  | Pair | `phase_edges` | `phase_paths` |
  |---|---|---|
  | `P0 -> OC0` | ✅ | ❌ |
  | `P0 -> MS0` | ✅ | ❌ |
  | `P0 -> S0` | ✅ | ❌ |
  | `OC0 -> C0` | ❌ | ✅ |

  `OC0 -> C0` is not a harmless over-approximation — it **contradicts locked
  design text**. `DESIGN.md:117` locks Operator Configuration as
  `P1 -> OC0/O0`, and `phase_edges` gives `"OC0": ["O0"]`, but
  `validate-registry.jq:31-33` routes `["P1","OC0"]` into `launch_phases`, which
  begins at `C0`. One artifact is wrong on the merits.

  Replace `phase_paths` and `phase_reachable` with the `phase_edges` map plus a
  **visited-set-guarded** transitive closure, making the Packet D graph the
  single authority. This eliminates the divergence and one copy at once.

  Verified test-safe: `test-registry.sh:160-245` pins ten phase behaviours
  (`P1->OC0` pass, `P1->MS0` pass, `RW0->RW0` pass, `C0->A1` fail, `L0->L1`
  pass, `E0->E1` pass, `L0->E0` fail, `F0->C0` pass, `S0->L0` pass, `F0->S0`
  fail). **None** touches a divergent pair; all ten behave identically under the
  graph relation. No current registry entry uses any of the four pairs, so the
  behaviour change is latent, not active.

- [ ] **Step 2: Give `descendants` a visited set**

  `validate-composition-coverage.jq:1179-1184` `descendants` is unguarded
  recursion. Verified empirically under jq 1.8.1: on a graph containing
  `L1 -> D0`, `descendants("D0")` terminates with
  `jq: error: cannot allocate memory` (exit 134).

  The consequence is that the acyclicity assertion **can never fire as a
  diagnostic**. In the conjunction at `:1458-1489`, conjunct A pins
  `phase_edges` against a second literal copy of itself in the same file, and
  conjunct B is the acyclicity check. Because jq's `and` short-circuits, a
  one-copy edit is caught cleanly by A; a two-copy edit passes A and then
  exhausts memory inside B — and inside every other `reachable` call site
  (`:1236, :1249, :1261, :1270, :1308, :1316, :2123, :2539, :2549`). B is a true
  statement structurally incapable of diagnosing the failure it names.

  Add the visited set. Then add a mutation case proving a two-copy cycle is
  **reported**, not OOM-killed.

- [ ] **Step 3: Land the editorial phase corrections**

  1. `CONFIGURATION-LANGUAGE-CORPUS.md:66-87` — add the three missing rows
     `OC0`, `MS0`, `RW0`. The table has 20 rows against a 23-phase vocabulary,
     and the corpus assigns those three to invariants **15 times** while its own
     table omits them. This also makes `INVARIANT-ENFORCEMENT.md:279` ("The
     registry uses the product phases from the executable corpus") false as
     written.
  2. `CONFIGURATION-LANGUAGE-CORPUS.md:81` versus
     `INVARIANT-ENFORCEMENT.md:301` — resolve the `R0` label drift. The corpus
     says "Runtime launch", the protocol says "Sandbox launch". Under Packet E's
     locked vocabulary these are **different claims**: the Sandbox aggregate
     persists across epochs, the runtime does not. "Runtime launch" is correct.
  3. `CONFIGURATION-LANGUAGE-CORPUS.md:77` — restate `C0` as "Artifact manifest
     plus the complete resolved creation input for one launch", noting the input
     may be a `CreateSandbox` request, a decoded serialized resolved-reentry
     envelope, or durably recorded creation selections replayed by a `Start` or
     same-Sandbox `Restore`. This documents what `RW0 -> C0` and the
     `serialized-resolved-reentry` template already do.
  4. `INVARIANT-ENFORCEMENT.md:318-333` — insert the Task 1 Step 2 normative
     paragraph and the hard prohibition.

- [ ] **Step 4: Full gate green**

  ```sh
  docs/greenfield/research/invariants/check-inventory.sh
  ```

---

### Task 1B: Build the model-coherence gate

This repository deliberately duplicates definitions across independent oracles
so that no component defines its own correctness. That duplication is correct
and must **not** be collapsed where it is load-bearing. The defect is that
almost none of it is mechanically compared, so copies drift silently — and a
*missing* copy is entirely invisible.

**Files:**

- Create: `docs/greenfield/research/invariants/check-model-coherence.sh`
- Modify: `docs/greenfield/research/invariants/check-inventory.sh`
- Modify: `CONTRIBUTING.md`

- [ ] **Step 1: Write the checker**

  Repo harness conventions: `set -euo pipefail`, `mktemp -d` with an EXIT trap,
  a `compare` helper, a `pass_count`, and a final
  `echo "model coherence: ${pass_count} checks passed"`. Extraction is the hard
  part — jq `def` blocks, `mjs` `const` literals, and markdown tables each need
  their own robust extractor. Normalize to sorted line-oriented text and use
  `comm`/`diff`, never substring matching.

  Checks, each naming its copies and its exact failure message:

  1. phase reachability closure equality across both models (all 529 pairs);
  2. phase universe equality across all five copies — `phase_order`, `phase_edges`,
     the `mjs` edges, the corpus table plus its Packet D addendum, and the
     mermaid node set;
  3. phase label equality between the corpus table and the mermaid;
  4. owner-set equality across the four machine copies (Task 1 Step 1);
  5. owner label agreement across the three prose tables;
  6. `placeholder_strings` byte-identity across every validator that defines it,
     **plus an assertion that every ledger validator defines it** — this is what
     catches the missing copy rather than a diverging one;
  7. digest-pin agreement between each validator's internal def and
     `check-inventory.sh`;
  8. count-literal mutual consistency across the fourteen pinned locations;
  9. orphaned valid corpus witnesses (the missing `comm -13` mirror);
  10. every locked Packet D path is nameable from some `registryPathAliases`
      value;
  11. every active-effect classification cell has a declaring `compositionPath`;
  12. every declared `trustBoundaries` element has covering test evidence.

- [ ] **Step 2: Wire it into the gate**

  Run it **first** in `check-inventory.sh`, before any packet validator: a
  drifted vocabulary makes every downstream result untrustworthy.

- [ ] **Step 3: Record the authoring discipline**

  Add to `CONTRIBUTING.md` a short checklist for adding an invariant, a
  vocabulary value, or a phase, naming every copy that must move in lockstep.
  Preserve the existing note that `check-enforcement-closure.sh` is expected to
  fail, verbatim.

---

### Task 1C: Land the Tier A coherence fixes

The checker from Task 1B fails on **eight** live defects in the already-reviewed
packets. Each is either fixed or explicitly accepted with a recorded rationale;
none may be silenced by weakening its check.

- [ ] **Step 1: A5 — active-effect cells with no declaring composition path**

  **56 (path, invariant) pairs across 29 invariants** are classified `C`/`N`/`S`
  in `PACKET-D-CASE-CONTRACTS.json` while the invariant declares no
  `compositionPaths` entry aliasing to that path.

  This is the most consequential finding, and it is a genuine coverage hole
  rather than a labelling nit: `validate-registry.jq:277` derives per-path
  evidence obligations **only** from `compositionPaths`, so those 56 pairs carry
  no test obligation at inventory *or* at Gate 4B closure. Packet D's reviewed
  matrix asserts an active effect on paths its own registry entries never claim
  to reach.

  Fix by widening the affected invariants' `compositionPaths` (the classification
  is the reviewed judgement; the registry declaration is what lags), or by
  correcting the classification where the active effect was wrong. Record which,
  per pair.

- [ ] **Step 2: A6 — eight locked paths are unnameable**

  `artifact-semantic-refinement`, `operator-configuration-authoring`,
  `operator-configuration-refinement`, `managed-service-definition-authoring`,
  `managed-service-definition-refinement`, `generated-runtime-configuration`,
  `create-native-extension`, and `corrupted-provider-build-result` are locked
  Packet D paths that no `registryPathAliases` value targets. No invariant can
  name them, so no invariant can carry evidence for them.

- [ ] **Step 3: A4 — orphaned valid witness**

  `VAL-011` is defined in the corpus and referenced by no invariant. The
  registry-to-corpus direction is checked; the mirror never was.

- [ ] **Step 4: A7 — owner labels and transposed counts**

  Four label mismatches across the three prose tables (`service`, `exec`,
  `runtime`, `live`). Worse, `INVENTORY-REVIEW.md` counts **by owner** while
  `PACKET-A-RESOURCE-OPERATION-REVIEW.md` counts **by resource**: because
  surface `live.exec` is `resource=live, owner=exec`, Packet A's true owner
  counts are live=12/exec=13 while its rows read 13/12. Both tables are
  internally correct; a cross-reader gets transposed numbers. Add a backticked
  owner-ID column to both and state each table's axis in its caption.

- [ ] **Step 5: A8 — unevidenced trust boundaries**

  `CMP-009 frontend-evaluation`, `CMP-010 artifact-final-validation`, and
  `CMP-011 artifact-final-validation` declare a trust boundary that no test
  lists in `covers`.

- [ ] **Step 6: Full gate green, then checkpoint**

  ```sh
  docs/greenfield/research/invariants/check-model-coherence.sh
  docs/greenfield/research/invariants/check-inventory.sh
  ```

  Both exit 0 before any Packet E identifier is allocated. Re-pin the Packet D
  digests last, and update `PACKET-D-COMPOSITION-REVIEW.md` to record that its
  verdicts were reopened for these repairs and what changed.

---

### Task 2: Partition the obligations and allocate the complete identifier block

**Files:**

- Create: `docs/greenfield/research/invariants/PACKET-E-OBLIGATION-PARTITION.json`
- Modify: `docs/greenfield/research/invariants/PACKET-E-OPERATION-CONTRACT-REVIEW.md`

**Interfaces:**

- Consumes: the 178 listed obligations; the Task 1 rulings.
- Produces: one closed record per obligation with its disposition
  (`registry-entry`, `partitioned`, `duplicate-of`, `ledger-rule`,
  `witness-extension`, `delegated-to-F`), and, for every resulting registry
  entry, its allocated identifier, owner, `firstSoundPhase`,
  `rejectionDeadline`, and disposition.

- [ ] **Step 1: Build the closed obligation record**

  One record per listed obligation, keyed
  `<DOC>-<NUMBER>` (`IDENTITY-01` … `RESULT-51`), carrying the verbatim
  obligation text, its source document and line, and its disposition. Every one
  of the 178 must appear exactly once. A record with disposition
  `duplicate-of` names the surviving record; a record with disposition
  `partitioned` names every resulting identifier and states the owner or
  boundary distinction that forced the split.

  Twenty-four cross-document duplicate groups are already known, including the
  five-way terminal-immutability group (IDENTITY #18, LIFECYCLE #19,
  LIFECYCLE #29, TAXONOMY #49, RESULT #24) and the three-way terminal-`unknown`
  group (IDENTITY #27, LIFECYCLE #26, RESULT #25). Each must be resolved
  explicitly, not silently merged.

- [ ] **Step 2: Allocate the complete identifier block in one pass**

  Identifier allocation is effectively irreversible: an identifier appears in
  the corpus, the registry, `reviewedInvariantIds`, 54 classification vectors,
  and roughly a thousand generated rule selectors. Allocate the whole block
  **after** the partition is complete, never incrementally.

  Every prefix in the registry is currently contiguous `001..N` with no gaps and
  no duplicates. Preserve that. Proposed families, all verified non-colliding
  with the 30 existing prefixes (`IDE` ≠ `IDN`/`IDT`, `PRC`/`PRF` ≠ `PRV`,
  `RET` ≠ `RES`, `OPA` ≠ `OPS`):

  | Prefix | Family | Est. |
  |---|---|---:|
  | `IDE` | Identity and coordinate integrity | 19 |
  | `FEN` | Authority fencing and effect-authority ordering | 10 |
  | `OPA` | Durable acceptance, idempotency, and recovery | 19 |
  | `SBX` | Sandbox runtime-state truth and status projection | 17 |
  | `ADM` | Execution admission and Process launch authority | 8 |
  | `PRC` | Process state, termination, and replay | 14 |
  | `SIG` | Signal and termination dispatch proof | 6 |
  | `PIO` | Process output streams and sequenced Process control | 17 |
  | `PRF` | Outcome proof, terminal immutability, forbidden inference | 15 |
  | `CNC` | Concurrency lanes and operation-pair compatibility | 4 |
  | `ERR` | Public error, recovery, and transport projection | 10 |
  | `SOP` | Snapshot resource contract and class integrity | 12 |
  | `FRK` | Restore, Fork, and derivation semantics | 10 |
  | `RET` | Retention, deletion independence, and tombstones | 5 |
  | `ADP` | Adapter, Session, and desired-state boundary | 7 |
  | `POL` | Runtime policy non-widening and capability rejection | 6 |
  | — | ledger-rule dispositions (no identifier) | ~6 |

  Use `SOP`, not `SNP2`: a numeric-suffixed prefix is legal under
  `^[A-Z][A-Z0-9]*-[0-9]{3}$` but breaks the alphabetic-prefix convention, and
  `SNP` is already taken.

- [ ] **Step 3: Assign owner, phases, and disposition per entry**

  Apply the Task 1 owner ruling. Every `firstSoundPhase` and
  `rejectionDeadline` must be reachable under the single post-Task-1A
  reachability relation. The traps that matter: **`L0 -> E0` and `E0 -> L1`
  both fail** — the live and exec branches never coexist on one path — and
  `T0` is a sink.

  **The partition rule.** Answer these four questions in this order, never any
  other:

  1. **What facts must exist for this rule to be decided without guessing future
     inputs?** Match that fact set to a row of the corpus "Observable Product
     Phases" table. That row **is** `firstSoundPhase`. Do not pick a phase
     because the operation "passes through" it, because a caller reached it
     earlier, or because a sibling invariant uses it.
  2. **Who owns those facts?** That is `owner`.
  3. **What is the last station on *this same traversal* at which refusing is
     still a correct product implementation?** That is `rejectionDeadline`.
  4. **Is the violation committed by a *different operation* than the one whose
     traversal I am describing?** If yes, **stop** — the obligation is not
     yours. File it on the offending operation's traversal, at that operation's
     own first-sound phase, and link the two with a handoff record.

  If two obligations you were about to merge give different answers to (1) **or**
  (2), they are two entries. Same answer to both, one entry.

  **Per-gap dispositions (binding).**

  *Start on a stopped Sandbox* is **two traversals**. The live request:
  stopped-proof and epoch-allocation rules at `L0 -> L0` and `L0 -> L1`;
  prior-epoch fencing at `L1 -> L1`. The launch it authorizes begins a new
  traversal: manifest re-resolution `C0 -> C0` (`create`), operator re-admission
  `O0 -> D0` (`operator`), no-reactivation `R0 -> R1`, and the conformance
  postcondition `R1 -> R1`. Same-Sandbox `RestoreSandbox` takes the identical
  shape. Note `SNP-002` is correctly placed for its admission half, but its
  restore *postcondition* half is genuinely uncarried today and must be added as
  a separate `R1 -> R1` runtime-owned entry — a missing entry, not a missing
  phase.

  **`firstSoundPhase C0, rejectionDeadline R1` for a Start postcondition is
  forbidden** — see the Task 1 Step 2 hard prohibition and its generated false
  chain.

  *Retention and tombstones* split three ways: Delete-traversal proof
  obligations at `T0 -> T0` (`runtime`); Delete-traversal **admission**
  obligations at `L0 -> L0` — filing these at `T0` is a real error and must be
  corrected on sight; and obligations whose subject is a *later, different*
  operation, which go to that operation's own traversal (a caller deleting an
  Operation before retention expiry is `L0 -> L0` on the `DeleteOperation`
  request; a later `Create` reusing an unreleased name is `C0 -> C0`).

  *System-originated Operations* are filed at **exactly the phase their
  caller-originated twin is filed at**. `origin` is an attribution field on the
  request, not an information set, and the locked taxonomy states system work
  "uses the same target, epoch, authority, and proof rules". Reconciliation and
  adoption resolving an `unknown` are `R1 -> R1` `observed-conformance`;
  containment-absence proof is `T0 -> T0`; the authority-epoch fence is
  `D0 -> D0` authoritative with **defensive** hooks at `R0`, `R1`, `L1`, `E1`,
  `T0` — legal because the reachability constraint binds only `authoritative`
  hooks.

  Registering at `R1 -> R1` and `T0 -> T0` works **today** with no Packet D
  template change: the generator and validator always synthesize and append the
  authority step, so the chain is non-empty and contains the authority. The cost
  is a degenerate one-step chain recording no defensive revalidation, which
  Task 10 addresses.

  A remaining decision, on a different axis and not a phase question:
  `PACKET-D-COMPOSITION-PATHS.json` has no `system-origin` path id, and
  `reachableOwners` binds owner to path. Decide whether system-origin Operations
  ride `direct-api` (`reachableOwners: ["create"]` today) or need a 55th path,
  and record the answer.

  Each entry's `disposition` must be justified against the protocol's four
  guarantees. Packet E is dominated by `reject-at-boundary`; use
  `observed-conformance` only where the fact is provable solely after launch,
  and `dynamic-preflight` only where validity depends on current external state
  and must be decided before mutation.

- [ ] **Step 4: Confirm the witness-extension set**

  Several obligations extend an existing entry's witnesses rather than adding a
  new entry — candidates include TAXONOMY #47 against `TGT-003`/`XRS-005`,
  TAXONOMY #46 / RESULT #44 against `TGT-001`/`TGT-004`/`TGT-006`, RESULT #45
  against `LIVE-001`, and IDENTITY #8 / RESULT #13 against `CRT-004`. Confirm
  each by reading the existing entry's `statement`, not its title.

  A witness extension still edits `invariants.json` and therefore still triggers
  the whole digest and count chain. Batch these with the new entries; never as a
  separate change.

- [ ] **Step 5: Dispose of the Dynamic-state row obligations**

  `INVENTORY-REVIEW.md:89` assigns to Packet E: acquisition, reservation,
  rollback, retry, cancellation, mutation, and teardown transitions, and `:93`
  states that no row may remain `partial` or `unwalked` when Gate 2A closes.
  Retry, cancellation, mutation, and teardown are covered by the registered
  families and the Task 9 ledger. Record an explicit disposition for
  **acquisition**, **reservation**, and **rollback**, including the "dynamic
  reservation and time-of-check/time-of-use protocol" that all four locked
  records list as still unlocked. Each is either registered here, becomes a
  Task 9/10 ledger rule, or is named as an explicit deferral with a destination
  packet and rationale. An obligation with no disposition is a defect.

  This matters beyond bookkeeping: Task 13 Step 1 rewrites the
  `INVENTORY-REVIEW.md` span that is currently the obligation's last textual
  home, so an undisposed obligation would be deleted while the same edit claims
  Packets A through E reviewed. Packet F's declared scope does not cover
  reservation or TOCTOU, so silent delegation there is unsupported.

- [ ] **Step 6: Record the final sizing**

  State the resulting counts: registry entries added, corpus invalid cases,
  corpus valid cases, resulting `N`, resulting cell count `54 × N`, resulting
  planned hooks and tests. Also state the **cumulative** registry length and
  cell count after each of the four batches (`140 + |b1|`, `+ |b2|`, `+ |b3|`,
  `+ |b4| = N`). Task 3 pins the batch-1 cumulative pair; Tasks 4-7 Step 4b pin
  the rest. The final `N` is a sizing figure, not a literal to install early.

---

### Task 3: Parameterize the machinery for `N != 140` (red-first)

**Files:**

- Modify: `docs/greenfield/research/invariants/test-registry.sh`
- Modify: `docs/greenfield/research/invariants/check-inventory.sh`
- Modify: `docs/greenfield/research/invariants/generate-composition-coverage.mjs`
- Modify: `docs/greenfield/research/invariants/validate-composition-coverage.jq`
- Modify: `docs/greenfield/research/invariants/test-composition-coverage.sh`

**Interfaces:**

- Consumes: the Task 2 sizing, and batch 1's allocated identifier list.
- Produces: machinery that fails RED against the current 140-entry registry and
  passes once batch 1 lands. Task 3 pins **batch 1's cumulative counts only**
  (`140 + |batch 1|`, and `54 ×` that). The literals are re-pinned once per
  batch in Tasks 4-7 Step 4b; they never move directly to the final `N`.

- [ ] **Step 1: Add the failing registration assertion first**

  Extend `assert_packet_d_correction_registration`
  (`test-registry.sh:386-398`) to assert the presence of the batch's new
  identifiers and the new registry length, **before** the registry is edited.

  Run:

  ```sh
  docs/greenfield/research/invariants/test-registry.sh inventory
  ```

  Expected: RED, caused by the absent identifiers.

  **Warning:** line 396 is a bare `jq -e … >/dev/null`. It fails with **zero
  output**, and `check-inventory.sh` then exits 1 with empty stdout and stderr,
  which reads like a harness crash rather than an assertion failure. The same
  silent-failure shape exists at `check-inventory.sh:126-148` and `:99-112`.

- [ ] **Step 2: Update every hard-coded count literal**

  Fourteen machine locations pin `140` or `7560`. All must move together, and
  all to **this batch's cumulative** count, not to the final `N`:

  | File | Line | Literal |
  |---|---|---|
  | `test-registry.sh` | 396 | `(.invariants \| length == 140)` |
  | `check-inventory.sh` | 131 | registry length `140` |
  | `check-inventory.sh` | 134 | `reviewedInvariantIds` length `140` |
  | `check-inventory.sh` | 139 | `.expectedCellCount == 7560` |
  | `check-inventory.sh` | 140 | selector expansion `== 7560` |
  | `generate-composition-coverage.mjs` | 71-72 | `invariantIds.length === 140` + message |
  | `generate-composition-coverage.mjs` | 526-527 | `expectedCellCount === 7560` + message |
  | `generate-composition-coverage.mjs` | 532 | message naming `7,560` |
  | `test-composition-coverage.sh` | 301 | the `.[0:139]` boundary slice |
  | `validate-composition-coverage.jq` | 1988 | `test("^[FLIH]{140}$")` |
  | `validate-composition-coverage.jq` | 1997 | `test("^[FLIH]{140}$")` |
  | `validate-composition-coverage.jq` | 2000 | message naming 140 |
  | `validate-composition-coverage.jq` | 2359 | `(.invariantIds \| length) == 140` |
  | `validate-composition-coverage.jq` | 2361 | message naming the 140-ID order |
  | `test-composition-coverage.sh` | 677-681, 686, 699 | `140` / `7560` gate and messages |

  The generator literals at `mjs:71` and `:526` must be updated **before**
  regeneration or generation throws before writing anything.

  The generator spells the count `7,560` with a comma in its messages, so
  `grep 7560` will not find `:527` or `:532`. Search both spellings.

- [ ] **Step 3: Move the off-by-one boundary probe**

  Update the slice literal at `test-composition-coverage.sh:301` from `.[0:139]`
  to `.[0:<cumulative N − 1>]`, and rename the case at `:300` from
  `vector-width-139` to match. Renaming alone is not enough: the literal `139`
  is what encodes "one short", and if it is left behind the mutation still fails
  as expected while silently ceasing to probe the boundary. Do not delete the
  mutation.

- [ ] **Step 4: Confirm the machinery is RED for the right reason**

  Run `test-registry.sh inventory` and confirm the failure names the absent
  identifiers or the count mismatch — not a syntax error in the edited jq.

---

### Tasks 4-7: Register the invariants in four owner-grouped batches

Owner determines the classification default across 42-53 of the 54 Packet D
paths, so grouping batches by owner keeps each batch's classification derivation
uniform and locally reviewable.

- **Task 4 — Batch 1:** Core control-plane / `runtime`-owned entries
  (`IDE`, `FEN`, `OPA`, `PRF`, `RET` families).
- **Task 5 — Batch 2:** live-operation entries
  (`SBX`, `SIG`, `SOP`, `FRK`, `CNC` families).
- **Task 6 — Batch 3:** Exec and Process entries
  (`ADM`, `PRC`, `PIO` families).
- **Task 7 — Batch 4:** create / service / framework entries plus witness
  extensions (`ERR`, `ADP`, `POL` families).

**Every batch executes the identical seven-step sequence below.** Each batch
ends fully green; no batch may leave the gate red for the next.

**Files (per batch):**

- Modify: `docs/greenfield/research/CONFIGURATION-LANGUAGE-CORPUS.md`
- Modify: `docs/greenfield/research/invariants/invariants.json`
- Modify: `docs/greenfield/research/invariants/PACKET-D-CASE-CONTRACTS.json`
- Modify: `docs/greenfield/research/invariants/PACKET-D-COMPOSITION-COVERAGE.json` (generated)
- Modify: `docs/greenfield/research/invariants/check-inventory.sh` (count literals **and** digest pins — different lines)
- Modify: `docs/greenfield/research/invariants/validate-composition-coverage.jq` (count literals **and** digest pins — different lines)
- Modify: `docs/greenfield/research/invariants/test-registry.sh`
- Modify: `docs/greenfield/research/invariants/generate-composition-coverage.mjs`
- Modify: `docs/greenfield/research/invariants/test-composition-coverage.sh`

- [ ] **Step 1: Author the corpus cases**

  One `#### \`<ID>\`` heading per new invariant, matching
  `^#### \`([A-Z][A-Z0-9]*-[0-9]{3})\`` exactly — four hashes, one space,
  backticks around the identifier. One `### \`VAL-nnn\`` heading per new valid
  witness — **three** hashes.

  Place invalid cases inside the topically correct existing `###` family or open
  a new `### Packet E …` family. Follow the body convention, in order:
  `- Owner:`, `- First-sound phase:`, `- Rejection deadline:`, `- Invariant:`,
  `- Minimum witness:`, `- Required diagnostic:` (or `- Required result:`).

  The first four bullets appear on all 140 current cases; a minimum-witness
  bullet on 122 and a diagnostic-or-result bullet on 123, with only 99 matching
  the full six-bullet sequence. New cases carry all six. All 140 agree exactly
  with the registry on owner and both phases; preserve that parity.

  Only the headings are machine-checked; the body is convention. Write it
  correctly anyway — it is the human review surface.

- [ ] **Step 2: Append the registry entries**

  Append to the tail of `.invariants`. Each entry carries the same 19 keys in
  the same order as all existing entries. Hard requirements:

  - exactly **one** hook with `role: "authoritative"` — not zero, not two; its
    phase must be reachable from `firstSoundPhase` *and* must reach
    `rejectionDeadline`;
  - required planned tests: `positive-boundary` always, `diagnostic` always,
    `source-rejection` for `unrepresentable`/`reject-at-boundary`,
    `dynamic-preflight` for `dynamic-preflight`, `runtime-probe` for
    `observed-conformance`, and `wire-corruption` whenever `trustBoundaries` is
    non-empty — which is always, since `trustBoundaries` must be non-empty;
  - every `compositionPaths` value must appear in some test's `covers`, and
    every `targets` value in some test's `targets`;
  - `diagnostic.identity` must equal `id` exactly; `diagnostic.relatedPaths`
    must be present even when empty;
  - no string anywhere in the entry may match
    `^(TBD|TODO|FIXME)(:|\b|$)|^UNKNOWN$` case-insensitively.

  Prefer existing `compositionPaths` tokens, but do not treat the vocabulary as
  frozen. It is **derived**, not declared: `validate-composition-coverage.jq`
  requires `registryPathAliases` keys to *equal* the set of tokens the registry
  actually uses, so declaring a token and registering its alias are one decision
  recorded in two places. Many-to-one aliasing is idiomatic — ten tokens name
  `direct-api`.

  Minting a token costs editing `PACKET-D-COMPOSITION-PATHS.json`, the jq alias
  literal, the alias count, and two digest pins. It does **not** reopen Packet D:
  the `reopenPolicy` scopes reopening to a new composition or extension
  *facility*, and the review record's own trigger list does not include aliases.
  An alias adds no facility, path, cell, or rule group — verified by the
  2026-07-31 mint, after which the generated coverage matrix regenerated
  byte-identically.

  Two conventions bind new tokens, both established 2026-07-31:

  - **Identity form.** A newly minted token is always `key == value`. Unqualified
    keys (`imports`, `explicit-override`) are historical records of pre-rename
    registry usage; minting an unqualified token would fabricate a legacy name
    and destroy the map's one self-documenting property.
  - **Canonical declaration.** Where several tokens alias one path, a new
    declaration uses the identity token, never a legacy collapse token. This is
    not cosmetic: `planned_test_covers` matches `.covers` on *any* test kind, so
    a token that is also a `trustBoundaries` value would be discharged for free
    by the `wire-corruption` test and create no real obligation.

- [ ] **Step 3: Validate the registry and corpus (cheap inner loop, ~1 s)**

  ```sh
  cd docs/greenfield/research/invariants
  ./validate-registry.sh inventory invariants.json ../CONFIGURATION-LANGUAGE-CORPUS.md
  ```

  This is the only fast check for Steps 1-2 and catches every schema, enum,
  phase-reachability, hook, test-evidence, diagnostic, placeholder, and
  corpus set-equality error in both directions. Iterate here until green before
  touching anything downstream.

  Note one silent gap: an `invalidWitnesses` element that does **not** match
  `^[A-Z][A-Z0-9]*-[0-9]{3}$` is skipped without checking, so a malformed
  witness name passes. Verify witness names by eye.

- [ ] **Step 4: Widen the Packet D case contracts**

  In `PACKET-D-CASE-CONTRACTS.json`:

  1. append the batch's identifiers to `.reviewedInvariantIds` **in registry
     order**, not sorted;
  2. append one classification character per new invariant to each of the **54**
     strings in `.classificationVectorsByPath`, at the matching index;
  3. recompute `.portableArtifactInvariantIds` — registry-derived as
     `owner == "artifact"` and `firstSoundPhase ∈ {P0,P1,A0,A1,W0}`, **in
     registry order, not sorted**. Packet E should add few or none;
  4. leave `.packetCTargetRealizationInvariantIds` alone unless a Packet C rule
     genuinely applies — note it uses the **opposite** (sorted) convention.

  Classification derivation, which collapses most of the work: all 54 paths
  admit `no-authority`, so for a new invariant with owner `O` on path `P`, if
  `O ∉ P.reachableOwners` an active effect is illegal and the code defaults to
  `F`. Only paths where `O ∈ P.reachableOwners` — `live` 1, `exec` 1,
  `framework` 3, `create` 6, `service` 7, `operator` 9, `runtime` 12,
  `artifact` 27 — require judgement on the **active-effect** codes (`C`/`N`/`S`).

  Separately, **`B` (boundary-input) is not owner-gated.**
  `validate-composition-coverage.jq:367-368` excludes `boundary-input` from
  `active_effect`, and the reachable-owner requirement at `:1933-1940` applies
  only to active effects. **21** paths admit `boundary-input`, not four. Eleven
  have validator-pinned exact `B` sets and are derived, not judged. The
  remaining **six require a deliberate `B`-versus-no-authority ruling for every
  new invariant, regardless of owner**: `generated-runtime-configuration`,
  `provider-native-adapter`, `provider-native-operation`,
  `prebuilt-member-transfer`, `oci-descriptor-transfer`, and
  `provider-cache-hit` — plus the four typed-request caller paths
  (`direct-api`, `framework-adapter`, `cli-adapter`, `managed-service`).

  Precedent proves owner is irrelevant here: `direct-api` has
  `reachableOwners == ["create"]` yet carries `B` for 33 invariants, and
  `provider-native-operation` has `reachableOwners == ["runtime"]` yet carries
  `B` for `LIVE-002`/`LIVE-003`/`LIVE-004` — exactly the family batch 2
  registers. Writing `F` here passes every gate silently **and** discards the
  forced `fullRevalidation == true` that boundary-input cells carry
  (`:2632-2637`). That is a silent semantic loss, not a style choice.

  Use `L` (same-owner-stage-or-fact-class) rather than `F` where the owner
  matches the path but the stage does not. Outside the pinned groups below, the
  `F`/`L`/`I`/`H` distinction is reviewer-enforced, so choose honestly.

  **Pinned constraints that are derived, never judged.** Appending a wrong
  character to any of these fails even when the effect is legal:

  1. `target-lowering` — exact set equality with
     `packetCTargetRealizationInvariantIds` (89).
  2. `serialized-resolved-reentry` — hard `== 107` on both sides.
  3. The three provider-construction paths (`provider-side-construction`,
     `provider-build-cache`, `corrupted-provider-build-result`) — fixed 9-ID
     `B` list **and** required to be **byte-identical whole strings**
     (`:2038-2041`). A single differing character fails with a message naming a
     *boundary set*, which badly misdescribes the actual violation.
  4. `built-artifact-load` and `corrupted-manifest` — required to be
     **byte-identical whole strings** (`:2029-2030`), and registry-derived as
     portable + `IDT-002` + `MAN-001..006` + `TGT-003` + `NAT-002/003` (89).
  5. The eight `operator-configuration-*` and `managed-service-definition-*`
     source paths — exact pinned `C`/`N`/`S` arrays by equality, not subset
     (`:1966-1981`). The four service ones are live for batch 4.
  6. `frontend-output`, `frontend-adaptation`, `raw-wire-input`,
     `schema-migration` — registry-derived as portable + `NAT-002/003` (81).
  7. `direct-driver-invocation` and `raw-runtime-config-input` — every character
     must be `F`/`L`/`I`/`H` (`:1997`), and
     `operator-configuration-native-escape` and
     `managed-service-definition-native-escape` likewise (`:1988`).
  8. `conditionalNativeHandleContract.invariantIds` is pinned to exactly
     `["NAT-002","NAT-003"]` (`:1849`) — no new invariant may ever join it.

  Cheap inner loop, no regeneration:

  ```sh
  cd docs/greenfield/research/invariants
  jq -e --arg validationScope catalog \
    --arg pathsRegistrySha256 "$(shasum -a 256 PACKET-D-COMPOSITION-PATHS.json | awk '{print $1}')" \
    --arg caseContractsSha256 "$(shasum -a 256 PACKET-D-CASE-CONTRACTS.json | awk '{print $1}')" \
    --arg invariantRegistrySha256 "$(shasum -a 256 invariants.json | awk '{print $1}')" \
    --slurpfile paths PACKET-D-COMPOSITION-PATHS.json \
    --slurpfile caseContracts PACKET-D-CASE-CONTRACTS.json \
    --slurpfile registry invariants.json \
    --slurpfile targetRealization PACKET-C-TARGET-REALIZATION.json \
    -f validate-composition-coverage.jq PACKET-D-COMPOSITION-COVERAGE.json
  ```

  All four `--slurpfile` bindings are required even in `catalog` scope: jq
  resolves `$caseContracts` and `$targetRealization` at **compile** time, so
  omitting either yields `jq: 64 compile errors` before any rule is evaluated.
  Catalog scope does not read the coverage document's contents, so a stale
  `PACKET-D-COMPOSITION-COVERAGE.json` is harmless as `.`.

  **Expected mid-batch result: not exit 0.** The validator compares
  `$invariantRegistrySha256` and `$caseContractsSha256` against its pins at
  `:1023-1024` and `:1018-1019`, and those are only re-pinned in Step 6. The
  success criterion for this loop is **"the only remaining lines are the two
  SHA-256 pin errors"** — errors are accumulated and joined, so genuine
  classification errors appear alongside them.

- [ ] **Step 4b: Re-pin the count literals to this batch's cumulative `N`**

  Set every location in the Task 3 Step 2 table to this batch's cumulative
  registry length and `54 ×` that: `test-registry.sh:396`;
  `check-inventory.sh:131`, `:134`, `:139`, `:140`;
  `generate-composition-coverage.mjs:71-72`, `:526-527`, `:532`;
  `validate-composition-coverage.jq:1988`, `:1997`, `:2000`, `:2359`, `:2361`;
  `test-composition-coverage.sh:301`, `:677-681`, `:686`, `:699`. Also update
  the identifier assertion added in Task 3 Step 1 to this batch's identifiers.

  This step **must** precede Step 5: `generate-composition-coverage.mjs:71` and
  `:526` throw before the only `writeFileSync` at `:563`, so a stale literal
  makes regeneration impossible rather than merely red. The `^[FLIH]{N}$`
  literals at `validate-composition-coverage.jq:1988` and `:1997` must also
  precede Step 4's inner loop, or that loop fails on vector width before
  evaluating any classification.

- [ ] **Step 5: Regenerate the coverage matrix**

  ```sh
  node docs/greenfield/research/invariants/generate-composition-coverage.mjs
  node docs/greenfield/research/invariants/generate-composition-coverage.mjs --check
  ```

  Never hand-edit `PACKET-D-COMPOSITION-COVERAGE.json`. The resulting
  `.rules` length is derived, not predictable — read it off with
  `jq '.rules | length'` and use the observed value in prose. One added
  invariant moved 634 to 646 in a controlled experiment.

- [ ] **Step 6: Re-pin the digests — only after the semantic suite passes**

  ```sh
  cd docs/greenfield/research/invariants
  shasum -a 256 invariants.json PACKET-D-CASE-CONTRACTS.json PACKET-D-COMPOSITION-PATHS.json
  ```

  Update both copies of each changed pin: `validate-composition-coverage.jq`
  defs at `:1015-1016`, `:1018-1019`, `:1023-1024`, and the literals at
  `check-inventory.sh:60-62`. Both copies must move together or
  `check-inventory.sh:64-69` aborts **before any validator runs** with
  `Packet D digest pin mismatch`.

  `PACKET-D-COMPOSITION-PATHS.json` only changes if `registryPathAliases`
  gained a key. Packet C's pins are untouched unless
  `PACKET-B-ARTIFACT-FIELDS.json` was edited.

- [ ] **Step 7: Full green gate and recorded counters**

  ```sh
  docs/greenfield/research/invariants/check-inventory.sh
  ```

  Expected: exit 0. Capture the counter lines verbatim — the cell count, effect
  partition (which must sum to `54 × N`), and rule-group count are derived and
  must be read, not predicted.

  Confirm `check-enforcement-closure.sh` is still red and that its error volume
  grew by roughly 10.6 lines per new entry. A shrinking error count means an
  entry was wrongly marked closed.

---

### Task 7A: Extend the Packet D contract templates into the post-launch region

Packet E is the first packet to inhabit the post-launch region, and the region
has no template vocabulary. Verified: `P0`, `R0`, `R1`, `L1`, `E1`, and `T0`
carry **zero** registry phase uses, zero enforcement hooks, zero contract-template
boundary steps across all 28 templates, and zero occurrences in the 7,560-cell
matrix. The deepest launch-side step in any template is `D0`. Independently, all
54 composition paths terminate at or before driver preparation — not one models
launch, conformance, live mutation, process launch, teardown, or retention.

Entries at those phases **validate today** and produce a non-empty chain
containing their authority. But the chain is degenerate: one synthesized step,
recording no defensive revalidation boundary at all. Since the generated chain
is what the gates treat as reviewed coverage, leaving it degenerate would make
Packet E's coverage claim technically true and substantively empty.

**Files:**

- Modify: `docs/greenfield/research/invariants/PACKET-D-CASE-CONTRACTS.json`
- Modify: `docs/greenfield/research/invariants/validate-composition-coverage.jq`
- Modify: `docs/greenfield/research/invariants/test-composition-coverage.sh`

- [ ] **Step 1: Add the post-launch components**

  `R0/runtime-launch-committer`, `R1/post-create-conformance-prober`,
  `L1/live-mutation-committer`, `E1/process-launcher`, and
  `T0/containment-absence-prober`.

- [ ] **Step 2: Add the templates**

  `launch-conformance` (`R0 > R1`), `live-commit` (`L0 > L1`), `teardown`
  (`T0`), and a `launch-replay` variant of `create` whose `C0` step is
  `resolved-reentry-stage-constructor`-shaped rather than `creation-resolver` —
  so a `Start` never claims `creation-resolver` revalidated it.

- [ ] **Step 3: Accept the scoped Packet D reopening**

  This breaks the pinned template literals at
  `validate-composition-coverage.jq:495-660`, `:1797-1820`, `:2090-2185` and the
  `caseContractsSha256` pin, and reopens Packet D. It does **not** touch the
  phase graph; acyclicity is unaffected. Record the reopening and its scope in
  `PACKET-D-COMPOSITION-REVIEW.md` rather than letting the digests move silently.

- [ ] **Step 4: Regenerate, re-pin, and confirm chains are no longer degenerate**

  Verify by generating the chain for a representative `R1 -> R1` and `T0 -> T0`
  entry and confirming each now records a defensive revalidation boundary.

---

### Task 8: Author the Packet E operation registry

**Files:**

- Create: `docs/greenfield/research/invariants/PACKET-E-OPERATION-REGISTRY.json`

**Interfaces:**

- Consumes: the four locked decision records; the registered Packet E
  invariants.
- Produces: the closed axis vocabularies and per-operation contracts consumed by
  the generator and validator.

- [ ] **Step 1: Fix the header block**

  `registryVersion: 1`, `packet: "E"`, `status: "candidate"`, plus a
  `textAuthority` string declaring that only closed structured control fields
  and stable obligation identifiers are normative. Packet D's precedent is
  binding: a packet that has not closed must say `candidate` and must not say
  `reviewed`.

- [ ] **Step 2: Lock the closed axis vocabularies**

  From the decision records, exactly:

  - `callClasses` (6): durable Operation mutation, durable Process mutation,
    observation, atomic Core-record update, existing-handle intent, sequenced
    Process control.
  - `lifecycleStates` — the composite of Sandbox status and execution
    admission: `provisioning/closed`, `running/accepting`, `running/closed`,
    `suspended/closed`, `stopped/closed`, `unknown/closed`. Only `running` may
    be `accepting`.
  - `processStates` (5): `accepted`, `starting`, `running`, `state-unknown`,
    `terminated`.
  - `processTerminationVariants` (9) — four are stated only in the document
    body, not in any numbered list.
  - `operationStates` (7) and `terminalOutcomes` (4): `succeeded`, `failed`,
    `cancelled`, `outcome-unknown`.
  - `requestErrorVariants` — the closed 31-variant union.
  - `recoveryErrorVariants` — the closed 2-variant `RecoveryError` union
    (`PACKET-E-RESULT-ERROR-CONTRACT-DESIGN.md:557-570`). It is **not** a subset
    of `requestErrorVariants`; `:531` states that expired recovery state is not
    a `RequestError`.
  - `modeContract` — a canonical `mode -> phase -> component` table mirroring
    `validate-target-realization.jq:25-63`. **Lock this before authoring any
    case**; the validator recomputes canonical phase and component per mode, and
    changing it later invalidates every obligation identifier.

  **Token-collision rule.** The bare token `unknown` may not appear as a value
  anywhere in a Packet E ledger. Every ledger validator's `placeholder_strings`
  def matches `^UNKNOWN$` **case-insensitively**
  (`validate-registry.jq:104-109` and four byte-identical siblings), so a
  literal `"unknown"` is rejected as placeholder content. Verified: the
  composite `unknown/closed` and prose containing the word both pass — only a
  bare value collides, which is why Packets A-D never hit this.

  The locked semantics are preserved by namespacing: `state-unknown`,
  `outcome-unknown`, and the already-composite `unknown/closed`. This is a
  spelling change to the ledger encoding only; the locked semantics
  (`DESIGN.md:326`, `:365`, `:548`) are unchanged. Each vocabulary entry must
  carry an explicit `lockedSourceToken` field naming the design-record token it
  encodes, so the correspondence is machine-checkable rather than implicit —
  namespacing without that field would trade a validator collision for exactly
  the kind of silent drift this packet exists to eliminate.

  This encoding also has an independent merit: the most-emphasized Packet E
  distinction is that terminal Operation `unknown` and reconcilable Process
  `unknown` must never be conflated (IDENTITY #27, LIFECYCLE #26, RESULT #25).
  Distinct spellings make that distinction structural rather than merely stated.

  Align names with the existing prototype's `OperationContract`
  (`prototypes/packet-e-contract-compiler/src/model.ts:30-41`) for the record
  key set, and `src/definition.ts:1-33` for the closed axis values (`CallClass`
  `:1-5`, `ResultBranch` `:7`, `ResultCarrierKind` `:9-13`, `MatrixCellKind`
  `:15`, `RecoveryCoordinateKind` `:17-23`), rather than inventing parallel
  vocabulary. Note `definition.ts` declares **four** call classes against this
  step's six — reconcile that difference explicitly in the review record; do not
  silently diverge.

- [ ] **Step 3: Author the operation records**

  One record per Core operation with a closed key set: `id`, `callClass`,
  `targetKind`, `owner`, `capabilityGate`, `mutationClass`,
  `resultCarrierKind`, `allowedRequestErrors[]`, `allowedRecoveryErrors[]`,
  `allowedKnownFailures[]`, `allowedAmbiguities[]`, `recoveryCoordinates[]`,
  `refinesPacketASurfaces[]`, `refinesPacketBFields[]`, `invariants[]`,
  `delegatedPackets[]`, `rationale`.

  `allowedRecoveryErrors` is mandatory and easy to lose: `RecoveryError` is one
  of the five locked result branches (`DESIGN.md:499-515`), the design record
  requires a per-method `RecoveryErrorFor<K>` alongside the other three
  (`:615-638`), and `recoveryCoordinates[]` cannot substitute for it — the
  prototype's own validator treats them as independent. `unknown_keys` gates
  reject *extra* keys and are silent on *missing* ones, so nothing downstream
  would catch the omission.

  Coverage is total: the six mandatory driver operations, all reads and
  observations, all Process transport and control commands, and every
  capability-gated operation.

  None of the **fourteen** names rejected at `DESIGN.md:486-491` — plus `shell`
  (`PACKET-E-OPERATION-TAXONOMY-DESIGN.md:662`) — may be an operation `id`. The
  check is scoped to `id` values, not to any string anywhere: `attach`
  legitimately appears in prose (`DESIGN.md:426-428`).

  **Member partition (required ruling).** `OperationContract` at
  `PACKET-E-RESULT-ERROR-CONTRACT-DESIGN.md:1350-1373` fixes 22 members that
  every operation "must declare". Record, one line per member, where each lands:
  this operation record, the Task 9 per-case key set, an existing registry
  invariant family, the Task 10 concurrency ledger, or an explicit Packet F
  delegation. No member may be named on two sides, and none may be unnamed. At
  minimum state the disposition of `originSet`, `orderedAdmissionChecks`,
  `successPredicate`, `requiredEvidence`, `forbiddenInference`,
  `callerRecoveryByOutcome`, `coreResolutionByOutcome`, `idempotencyContract`,
  `retentionContract`, `concurrencyLane`, and `transportProjection`. RESULT #50
  and #51 exist to protect exactly these.

- [ ] **Step 4: Close the inherited delegations**

  `introducedInvariants[]` must reference only identifiers present in
  `invariants.json`, and every one must be referenced by at least one operation
  — the bidirectional pattern from Packet B.

  Additionally, every Packet A surface with `delegatedPacket == "E"` (the 20
  named surfaces, from `artifact.lifetime-maximum` through
  `runtime.cleanup-errors`) must be named by some operation; the 5 Packet B
  fields delegating `"E"` must be resolved; and the 6 Packet C rules carrying
  those delegations must be discharged.

  Record the open **E → A** dependency explicitly: the file, directory, copy,
  transfer, endpoint, and port method families are Packet A-owned and their
  names are not yet closed
  (`PACKET-E-RESULT-ERROR-CONTRACT-DESIGN.md:1552-1561`), while
  `:257-259` and the taxonomy record at `:685-687` require them to participate
  in the concurrency matrix. Carry `delegatedPackets: ["A"]` markers for those
  families so the ledger states the handoff rather than implying a totality it
  cannot yet have.

- [ ] **Step 5: Validate structurally before the generator exists**

  Confirm no placeholder strings, no unsafe softening prose (`best-effort`,
  `fail-open`, `warning-only`, `inherits backend defaults`, `fallback to target
  defaults`, `implicit fallback`, `silently drop|ignore|weaken`), and no
  unknown keys against the declared allow-list.

---

### Task 9: Author the case-contract catalog and the generator

**Files:**

- Create: `docs/greenfield/research/invariants/PACKET-E-CASE-CONTRACTS.json`
- Create: `docs/greenfield/research/invariants/generate-operation-contracts.mjs`
- Create: `docs/greenfield/research/invariants/PACKET-E-OPERATION-CONTRACTS.json` (generated)

- [ ] **Step 1: Author the stripped catalog**

  Mirrors `PACKET-D-CASE-CONTRACTS.json`: `reviewedInvariantIds` in exact
  registry order, `cellKindContract`, `transitionVectorsByOperation` (one total
  string per operation, length `|lifecycleStates|`),
  `outcomePartitionsByCellKind`, `contractTemplates`, and `entries[]` with a
  closed key set asserted by sorted-key equality in the generator.

  The vector here is `|operations| × |lifecycleStates|` — roughly 240 characters
  total, not `54 × N`. Packet E's own matrix is cheap; the expensive vector work
  was Packet D's.

  Include `delegatedConcernResolution`, closing Packet D's
  `delegatedConcernTaxonomy.E == ["operation-transition","retry","cancellation","cleanup"]`
  for all 33 delegating entries.

- [ ] **Step 2: Write the generator**

  Two axes only: operations × lifecycle states. Outcomes, error variants, retry,
  cancellation, and cleanup policies become the ordered `valueCases` list
  *inside* each cell, exactly as Packet C expresses value partitions. Do not
  attempt the 16-dimension flat product implied by the taxonomy document — the
  factoring is authorized and bounded by the Task 1 Step 4b ledger-axis ruling,
  which must already be recorded before this step runs.

  The generator reads only sibling JSON, renders
  `JSON.stringify(doc, null, 2) + "\n"`, supports `--check`, and throws a
  stale-output message on drift. It must build a Map keyed `row × column`,
  throw on overlap naming the prior rule, and require
  `seen.size === rows * cols`, enumerating every missing key.

- [ ] **Step 3: Fix the obligation-identifier grammar**

  Recomputed by the validator, never free text:
  `"<ruleId>/<caseId>/step-<i+1>/<phase>/<mode>"`,
  `"<ruleId>/<caseId>/evidence-<i+1>/<class>"` with `class` matching
  `^[a-z0-9]+(?:-[a-z0-9]+)*$`, and
  `diagnostic.identity == "<ruleId>/<caseId>"`. Reordering steps changes every
  downstream identifier, so step-order edits are never local.

- [ ] **Step 4: Fix the per-case closed key set**

  Each value case carries `id`, `condition` (`all-values`, `field-present`,
  `field-omitted`, `constraint-satisfied` with `predicateId`, or `otherwise` —
  `otherwise` last), `cellKind`, `terminalOutcome` (a `terminalOutcomes` member,
  never the bare string `unknown`, per the Task 1 Step 4c token ruling),
  `requestErrorId` (non-null **iff** the cell kind is reject),
  `recoveryErrorId` (non-null **iff** the cell kind is a recovery branch),
  `nextLifecycleStateId`, `epochRule`,
  `firstSoundPhase`, `deadline`, `authority`, `steps[]`,
  `postconditionObligationIds[]`, `evidence[]`, the fixed safety quad
  `{failure:"fail-closed", defaults:"explicit-only", warnings:"never-sufficient",
  evidence:"required"}`, `fallbackPolicy:"forbidden"`,
  `approximationPolicy:"forbidden"`, `retryPolicy`, `cancellationPolicy`,
  `cleanupPolicy`, `invariants[]`, `delegatedPackets[]`, `diagnostic`, and
  `implementationStatus:"planned"`.

- [ ] **Step 5: Generate and verify determinism**

  ```sh
  node docs/greenfield/research/invariants/generate-operation-contracts.mjs
  node docs/greenfield/research/invariants/generate-operation-contracts.mjs --check
  ```

---

### Task 10: Author the operation-pair concurrency ledger

**Files:**

- Create: `docs/greenfield/research/invariants/PACKET-E-CONCURRENCY-MATRIX.json` (generated)
- Modify: `docs/greenfield/research/invariants/generate-operation-contracts.mjs`

- [ ] **Step 1: Fix the axis and totality rule**

  Operations × operations. LIFECYCLE #21 and TAXONOMY #50 make it **total**: an
  absent entry is a specification error, never permission. Consider restricting
  rows and columns to mutating operations to keep the ledger reviewable; record
  the restriction and its justification explicitly if applied.

  Record alongside it the deferral of the Packet A data-plane rows and columns
  (file, directory, copy, transfer, endpoint, port), which
  `PACKET-E-RESULT-ERROR-CONTRACT-DESIGN.md:257-259` and the taxonomy record at
  `:685-687` require to participate but whose names Packet A has not yet closed.
  A totality claim that silently excludes them is false.

- [ ] **Step 2: Encode the lane model**

  One effectful lifecycle Operation holds fenced Sandbox authority at a time
  unless an exact capability permits the pair. Concurrent Exec is allowed while
  admission is `accepting`. Signal and termination Operations do not implicitly
  acquire the Sandbox lifecycle lane.

- [ ] **Step 3: Generate, verify totality, and verify `--check`**

---

### Task 11: Author the validator and mutation harness

**Files:**

- Create: `docs/greenfield/research/invariants/validate-operation-contracts.jq`
- Create: `docs/greenfield/research/invariants/test-operation-contracts.sh`
- Create: `docs/greenfield/research/invariants/fixtures/operation-invalid-witnesses.json`

- [ ] **Step 1: Write the failing harness first**

  Author `test-operation-contracts.sh` before the validator and observe it fail
  because `validate-operation-contracts.jq` does not exist.

- [ ] **Step 2: Implement the validator**

  Arguments: `--arg operationRegistrySha256`, `--arg caseContractsSha256`,
  `--arg invariantRegistrySha256`, `--arg validationScope catalog|full`, plus
  `--slurpfile` for the registry, the catalog, `invariants.json`,
  `PACKET-A-SURFACE-COVERAGE.json`, `PACKET-B-ARTIFACT-FIELDS.json`, and
  `PACKET-D-CASE-CONTRACTS.json`.

  It must include: the three digest pins as jq defs; `unknown_keys` on **every**
  object (Packet A is the only ledger without one and must not be the model);
  `placeholder_strings`; `unsafe_semantic_strings`; per-case equality against the
  catalog entry; recomputed obligation identities; total and disjoint cell
  coverage emitting `uncovered … cell:` and `overlapping … cell:`; and error
  accumulation terminating in
  `if $errors|length == 0 then <doc> else error($errors|join("\n")) end`. Never
  short-circuit on the first error — the harness matches substrings of the
  joined message.

  Encode the Task 1 Step 4 meta-rules here: an absent cell, a wildcard or
  default outcome, and an absent concurrency pair are each validator errors.

- [ ] **Step 3: Implement at least 60 mutation cases**

  Packet C has 66, Packet D 89, provider contracts 35. Cover at minimum:
  uncovered cell, overlapping cell, unknown operation, unknown state, unknown
  outcome, reject cell without `requestErrorId`, epoch reuse, `accepting` while
  not `running`, terminal outcome rewritten, unknown invariant, missing
  traceability, mutated safety quad, mutated obligation identifier, placeholder
  content, best-effort prose, unknown key, `status: "reviewed"` claimed too
  early, tandem catalog rewrite, and coordinated regeneration.

  Add specifically: an actual uppercase `UNKNOWN` placeholder (must still be
  rejected, proving the Task 1 Step 4c namespacing did not weaken the guard); an
  unknown recovery-error variant; a recovery branch relabelled as a reject
  branch; and a vocabulary entry whose `lockedSourceToken` names a token absent
  from the design records.

  Copy Packet D's two harness patterns: `expect_coordinated_regeneration_failure`
  (copy the generator and inputs to a temp directory, mutate, regenerate, assert
  the semantic validator still rejects) and the
  `--arg validationScope catalog|full` split.

  Use the **real** production ledgers as fixtures, per Packet C/D convention —
  not minimal synthetic ones. Standard harness shape: `set -euo pipefail`,
  `mktemp -d` with an EXIT trap, a `run_validator` wrapper,
  `expect_pass`/`expect_failure`, a `pass_count`, and a final
  `echo "operation contract validator: ${pass_count} cases passed"`.

- [ ] **Step 4: Author the invalid-witness fixture catalogue**

  Closed `{id, invalidState, nearbyValidWitness}` records with an exact count
  assertion, mirroring `fixtures/composition-invalid-witnesses.json`. If Packet
  E adds records to the **existing** Packet D fixture instead, the `length == 50`
  assertion at `test-composition-coverage.sh:272` moves in lockstep.

- [ ] **Step 5: Run the harness to green**

---

### Task 12: Wire Packet E into the inventory gate

**Files:**

- Modify: `docs/greenfield/research/invariants/check-inventory.sh`

- [ ] **Step 1: Add paths, existence checks, digests, and pins**

  Path variables after `:15`; the existence loop after `:28`; digest
  computation after `:53`; pin literals after `:62`. The existence block exits
  before anything else runs when a file is missing.

- [ ] **Step 2: Insert the validator block**

  After the Packet D block at `:148` and before the counter section at `:150`:
  `test-operation-contracts.sh`, then
  `node generate-operation-contracts.mjs --check`, then the
  `jq -e … -f validate-operation-contracts.jq` invocation mirroring the argument
  shape at `:115-125` (four `--arg` plus four `--slurpfile`), extended to the
  ten bindings Task 11 Step 2 specifies, then an inline absolute-count `jq -e`
  mirroring `:126-148`.

- [ ] **Step 3: Add the Packet E counter block**

  Counters after `:223`, echoes after `:234`, in the existing style: operations
  × lifecycle states = cells, rule groups, outcomes by value case, invariants
  introduced. Do **not** fold Packet E identifiers into the hard-coded 17-ID
  Packet D whitelist at `:197-223`; Packet E gets its own counter block.

- [ ] **Step 4: Rewrite the closing line**

  `:235` becomes `Gate 2A remains open for Packet F`.

- [ ] **Step 5: Full gate run**

  ```sh
  docs/greenfield/research/invariants/check-inventory.sh
  ```

  Expected: exit 0 with the Packet E counters present and the closing line
  naming only Packet F.

---

### Task 13: Update the prose, review records, and protocol documents

**Files:**

- Modify: `docs/greenfield/research/invariants/INVENTORY-REVIEW.md`
- Modify: `docs/greenfield/research/invariants/PACKET-E-OPERATION-CONTRACT-REVIEW.md`
- Modify: `docs/greenfield/research/INVARIANT-ENFORCEMENT.md`
- Modify: `docs/greenfield/research/invariants/PACKET-D-COMPOSITION-REVIEW.md`
- Modify: `docs/greenfield/research/invariants/PACKET-D-RESEARCH-NOTES.md`
- Modify: `docs/greenfield/DESIGN.md`
- Modify: `docs/greenfield/CONFIGURATION-BOUNDARY-AUDIT.md`
- Modify: `docs/greenfield/research/prototypes/README.md`
- Modify: `README.md`, `CONTRIBUTING.md` (only if a new command enters the
  verification block)

- [ ] **Step 1: Update `INVENTORY-REVIEW.md`**

  Baseline counts (`:18-33` — `:33` is the continuation carrying
  "complete-contract groups, with 89 focused validator checks"), the
  owner-distribution table (`:39-48`, which also gains the ninth owner row), the
  composition-semantics row (`:85`, which restates the 54 × 140 = 7,560 /
  634-group sentence in nearly the same words as `:32` — updating only one
  leaves a live contradiction), the lifecycle-semantics row (`:88`) from
  `partial` to `reviewed`, the dynamic-state row (`:89`) per the Task 2 Step 5
  disposition, the valid-expressiveness row (`:91`, whose `VAL-001` through
  `VAL-042` envelope must become the new range — this is the **only** prose
  location in the repository pinning that bound, and Task 1 Step 5 allocates
  `VAL-043` onward, so it contradicts the corpus from batch 1 onward), the
  security row per the Task 1 Step 3 ruling, the digest-bound machine snapshot
  (`:186-190`), the Packet D digest quotations (`:221-227`), the closing status
  (`:230-231`), and the Packet E section (`:233-313`) rewritten from "these
  foundations do not close Packet E" to the completed review record with its
  ledger links.

  The top status line becomes: Packets A through E reviewed; Packet F remains.
  If the dynamic-state row is left `partial`, the status line must say so rather
  than claiming Packet E complete.

  Take the widened universe from the `check-inventory.sh` counter lines captured
  in Tasks 4-7 Step 7. Verify before finishing: `grep -n '140\|7,560\|VAL-042'`
  on this file returns nothing stale.

- [ ] **Step 2: Update `INVARIANT-ENFORCEMENT.md`**

  Add the Packet E ledger links to the list at `:172-215`, update the counts
  paragraph at `:216-245`, and update the inventory-mode description at
  `:396-402` to name the Packet E validator. Update the mermaid phase graph at
  `:277-337` only if Task 1 Step 2 selected Option B.

- [ ] **Step 3: Update the Packet D records**

  `PACKET-D-COMPOSITION-REVIEW.md` at `:20`, `:41-43` (and `:46` if Task 11
  Step 4 moved the invalid-witness count), `:70-81` (the effect table — `:81` is
  the `no-authority:hard-contract-nonwidening` row, and the eight rows must
  still sum to `54 × N`), `:86`, `:131-135` (five per-path vectors, each of
  which must still sum to the new vector width), `:271-281` (six review evidence
  digests, including the validator's own — editing
  `validate-composition-coverage.jq` invalidates its recorded digest),
  `:283-289` (the exact effect partition and the structural / hard-contract cell
  counts), `:297-298`, `:309-312`; and `PACKET-D-RESEARCH-NOTES.md:87-88`.

  Read the new effect partition off the "Gate 2A Packet D effects" counter line
  captured in Tasks 4-7 Step 7 — do not recompute the old numbers by hand. This
  step also re-pins the file's six digests, which would otherwise give any
  stale number fresh authority. No script reads this markdown, so nothing else
  catches it. Verify before finishing: `grep -n '140\|7,560\|7560\|634'` on this
  file returns nothing stale.

  State plainly that Packet D's matrix was widened by Packet E registration and
  that its reviewed verdicts stand for the paths and classification semantics,
  not for the new cells' individual classifications.

- [ ] **Step 4: Update the design and audit documents**

  `DESIGN.md:109-113` (the 54-path / 140-invariant / 7,560-cell sentence),
  `CONFIGURATION-BOUNDARY-AUDIT.md:144`, and
  `research/prototypes/README.md:103-104`.

- [ ] **Step 5: Write the Packet E decision record**

  `PACKET-E-OPERATION-CONTRACT-REVIEW.md` must state: the Task 1 rulings and
  their rationale; the per-dimension ledger-axis disposition from Task 1
  Step 4b; the unresolved Packet A data-plane method-name dependency; the
  obligation partition summary (178 listed → distinct →
  registered / ledger-rule / witness-extension / delegated); the exact ledger
  digests; the observed validator and harness counts; the inherited A/B/C/D
  delegations discharged; what remains delegated to Packet F; and the explicit
  statement that Packet E closes Gate 2A's Packet E scope but **not** Gate 4B,
  since all hooks and tests remain planned.

  Preserve the `CONTRIBUTING.md` note that `check-enforcement-closure.sh` is
  expected to fail, verbatim.

---

### Task 14: Independent verification and Gate 2A exit preparation

- [ ] **Step 1: Cold reconstruction**

  An independent reviewer, without reading the authoring notes, reconstructs
  from the ledgers alone: the operation count, lifecycle-state count, cell
  count, rule-group count, registered invariant count, the resulting `N`, and
  `54 × N`. Discrepancies are defects in the ledger, not in the reviewer.

- [ ] **Step 2: Adversarial semantic review**

  Attempt coordinated mutations that preserve every digest and count but change
  meaning: relabel an owner and its classification column together; move a
  `firstSoundPhase` and its authoritative hook together; swap a cell kind and
  its outcome partition together; rewrite the catalog and the generated matrix
  in tandem. Each must be rejected by a semantic rule, not by a digest pin.

- [ ] **Step 3: Full suite**

  ```sh
  docs/greenfield/research/invariants/check-inventory.sh
  docs/greenfield/research/prototypes/test-all.sh
  docs/greenfield/research/invariants/check-enforcement-closure.sh
  ```

  Expected: the first two exit 0; the third remains red with a grown error
  volume. `test-all.sh` wraps Gate 2A in a nix shell that does **not** contain
  `node` — it must be on the ambient PATH.

- [ ] **Step 4: Draft the Gate 2A exit record fragment**

  Per `INVENTORY-REVIEW.md:350-360`: design revision and registry digest
  reviewed, packets completed, resources/operations/targets/extensions included,
  intentionally unsupported or future scope, reviewer findings and disposition,
  inventory-validator result, and the count of remaining `partial`/`unwalked`
  rows.

  State explicitly which rows remain open and to which packet each is assigned.
  If the dynamic-state row (`:89`) is still `partial` after Task 2 Step 5, it
  must be counted and named — a row assigned to Packet E that remains `partial`
  contradicts a top status line claiming Packet E reviewed.

---

## Plan Self-Review

- **Coherence repair precedes the walk.** Tasks 1A-1C repair the phase model,
  build the model-coherence gate, and land eight live defects found in the
  already-reviewed packets. This ordering is not optional: Packet E is about to
  assign roughly 185 phase pairs against a model whose two copies disagree on
  four ordered pairs, author 185 corpus cases against a phase table missing
  three rows, and add classification cells under a rule that has already
  produced 56 uncovered active-effect pairs. Fixing after would mean fixing at
  325-invariant scale instead of 140.

- **Spec coverage.** Task 1 resolves the structural decisions that
  determine roughly half of all owner assignments and the legality of every
  phase pair. Task 2 performs the partition and one-pass identifier allocation
  the protocol requires before implementation may consume a decision record.
  Task 3 prepares the machinery red-first. Tasks 4-7 register the invariants in
  owner-grouped batches, each independently green. Tasks 8-11 build the Packet E
  ledger, generator, concurrency matrix, validator, and mutation harness on the
  Packet C/D pattern. Task 12 wires the gate. Task 13 updates every prose
  location that quotes a count or digest. Task 14 supplies the independent cold
  and adversarial review that Packets C and D both required before their
  verdicts were accepted.

- **Known deliberate reduction.** The exhaustive ledger encodes two axes
  (operations × lifecycle states) with the remaining locked dimensions factored
  into ordered `valueCases`, per-case `predicateId` conditions, registry
  invariants, or explicit Packet F delegations; the per-dimension disposition is
  recorded in the Task 1 Step 4b ruling and restated in
  `PACKET-E-OPERATION-CONTRACT-REVIEW.md`. The concurrency ledger may be
  restricted to
  mutating operations rather than the full operation × operation product; the
  restriction and its justification must be recorded explicitly if applied.
  Concrete retention durations and reconciliation deadlines are registered as
  ledger policy fields rather than as numeric commitments; the invariants
  (records survive target deletion, retention independence, no caller deletion
  before expiry) are registered now. Wire spelling is deliberately excluded from
  every invariant statement.

- **Ordering justification.** Identifier allocation precedes all registration
  because identifiers propagate into the corpus, the registry, 54 positional
  classification vectors, and roughly a thousand generated rule selectors.
  Registration precedes the ledger because the ledger's traceability check
  requires its referenced identifiers to exist. Digest re-pinning follows the
  semantic suite in every batch, never precedes it. The ledger-versus-registry
  ruling is made in Task 1 rather than discovered in Task 8, because it changes
  the entry count by 10-15 and therefore changes the identifier block. Count
  literals are re-pinned once per batch (Step 4b), never once to the final `N`,
  because the registry length moves four times and every pinned equality is
  absolute — a single final pinning would make at most one batch green.

- **Type and count consistency.** Every count literal that pins 140 or 7,560 is
  enumerated in Task 3 Step 2 with its file and line. Every derived count — rule
  groups, effect partitions, error-line volume — is explicitly marked as read
  rather than predicted. Both copies of each digest pin are named together.

- **Placeholder scan.** No task contains `TBD`, a deferred implementation
  placeholder, or an unspecified "write tests" step. Every validator, mutation
  family, fixture, ledger file, and verification command is named. This matters
  mechanically as well as editorially: the registry and every ledger validator
  reject the literal strings `TBD`, `TODO`, `FIXME`, and `UNKNOWN` anywhere in
  their content.

- **Self-consistency.** This plan contains no commit step, consistent with the
  standing Global Constraint against staging, committing, pushing, or
  publishing, and consistent with the four prior packet-review plans.
