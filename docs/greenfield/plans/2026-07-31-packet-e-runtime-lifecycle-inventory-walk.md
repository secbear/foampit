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

### Task 1: Resolve the four blocking structural decisions

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

  Record the selected option and its rationale:

  - **Option A (extend):** add a ninth owner value for the Core control plane.
    Touches `validate-registry.jq:48-58`, the corpus "Locked Owners" table
    (corpus lines 42-56), `validate-surface-coverage.jq`'s owner enum, and the
    `INVENTORY-REVIEW.md` owner-distribution table. It does **not** force a
    `PACKET-D-COMPOSITION-PATHS.json` change unless a path adds the owner to
    `reachableOwners` — and if no path does, every cell for a Core-owned
    invariant is mechanically `F` (no-authority: foreign-owner), which is the
    correct and intended reading for a runtime-service rule on a configuration
    composition path.
  - **Option B (reuse):** map Core lifecycle semantics onto `live`, Process
    semantics onto `exec`, and leave `runtime` driver-scoped. Requires
    restating the `live` owner label in `INVENTORY-REVIEW.md` and the corpus
    owners table, and grows `live` from 5 to roughly 90 entries.

  Whichever is selected, the ruling is recorded once and applied uniformly. Do
  not mix.

- [ ] **Step 2: Record the phase-graph ruling**

  Three Packet E flows have no representation in the 23-phase vocabulary:

  1. `StartSandbox` on a stopped Sandbox must re-enter `D0`/`R0`, but the graph
     has only `L1 -> T0`.
  2. Retention, tombstone, and post-deletion obligations have no node after
     `T0`.
  3. System-originated reconciliation, adoption, fencing, and quarantine
     Operations have no ingress phase comparable to `F0`/`S0`.

  Record the selected option:

  - **Option A (no phase change — recommended default):** partition around the
    gaps. A Start-on-stopped obligation becomes two entries: the Core admission
    rule at `firstSoundPhase L0 -> rejectionDeadline L1`, and the launch
    postcondition rule on the `C0 -> R1` branch. Retention obligations are
    committed at `T0` (defensible: the obligation is committed at teardown even
    though a violation manifests later). System-originated Operations reuse the
    existing ingress most closely matching their trigger. Costs nothing and
    reopens nothing.
  - **Option B (extend):** add ingress and post-teardown phases. Any new phase
    must be added to **four** models in lockstep — `validate-registry.jq:1-6`
    (`phase_order`) and `:20-46` (`phase_paths`),
    `generate-composition-coverage.mjs:171-196`,
    `validate-composition-coverage.jq:1147-1171` (re-asserted whole at
    `:1458-1489`) — plus the corpus "Observable Product Phases" table and the
    `INVARIANT-ENFORCEMENT.md` mermaid graph. Per
    `INVARIANT-ENFORCEMENT.md:140` this **reopens both gates**.

  If Option B is selected it becomes Task 1a and must complete, with all four
  models green, before any identifier is allocated.

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
  `rejectionDeadline` must be reachable along one of the 24 explicit
  `phase_paths` (`validate-registry.jq:20-46`). The traps that matter here:
  **`L0 -> E0` and `E0 -> L1` both fail** — the live and exec branches never
  coexist on a single path — and there is no node after `T0`.

  Legal Packet E deadline ranges: `C0 -> {C0,O0,H0,D0,R0,R1,L0,L1,E0,E1,T0}`,
  `R1 -> {R1,L0,L1,E0,E1,T0}`, `L0 -> {L0,L1,T0}`, `L1 -> {L1,T0}`,
  `E0 -> {E0,E1,T0}`, `E1 -> {E1,T0}`, `T0 -> {T0}`.

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

- [ ] **Step 5: Record the final sizing**

  State the resulting counts: registry entries added, corpus invalid cases,
  corpus valid cases, resulting `N`, resulting cell count `54 × N`, resulting
  planned hooks and tests. These numbers drive every literal in Task 3.

---

### Task 3: Parameterize the machinery for `N != 140` (red-first)

**Files:**

- Modify: `docs/greenfield/research/invariants/test-registry.sh`
- Modify: `docs/greenfield/research/invariants/check-inventory.sh`
- Modify: `docs/greenfield/research/invariants/generate-composition-coverage.mjs`
- Modify: `docs/greenfield/research/invariants/validate-composition-coverage.jq`
- Modify: `docs/greenfield/research/invariants/test-composition-coverage.sh`

**Interfaces:**

- Consumes: the Task 2 final counts.
- Produces: a machinery that fails RED against the current 140-entry registry
  and will pass once batch 1 lands.

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

  Thirteen machine locations pin `140` or `7560`. All must move together:

  | File | Line | Literal |
  |---|---|---|
  | `test-registry.sh` | 396 | `(.invariants \| length == 140)` |
  | `check-inventory.sh` | 131 | registry length `140` |
  | `check-inventory.sh` | 134 | `reviewedInvariantIds` length `140` |
  | `check-inventory.sh` | 139 | `.expectedCellCount == 7560` |
  | `check-inventory.sh` | 140 | selector expansion `== 7560` |
  | `generate-composition-coverage.mjs` | 71-72 | `invariantIds.length === 140` + message |
  | `generate-composition-coverage.mjs` | 526 | `expectedCellCount === 7560` |
  | `generate-composition-coverage.mjs` | 532 | unique-cell count `7560` |
  | `validate-composition-coverage.jq` | 1988 | `test("^[FLIH]{140}$")` |
  | `validate-composition-coverage.jq` | 1997 | `test("^[FLIH]{140}$")` |
  | `validate-composition-coverage.jq` | 2000 | message naming 140 |
  | `validate-composition-coverage.jq` | 2359 | `(.invariantIds \| length) == 140` |
  | `validate-composition-coverage.jq` | 2361 | message naming the 140-ID order |
  | `test-composition-coverage.sh` | 677-681, 686, 699 | `140` / `7560` gate and messages |

  The generator literals at `mjs:71` and `:526` must be updated **before**
  regeneration or generation throws before writing anything.

- [ ] **Step 3: Re-check the off-by-one mutation fixture**

  `test-composition-coverage.sh:300` names a fixture case `vector-width-139`.
  Confirm it still means "N − 1" after the count change, and rename it if the
  literal name is now misleading. Do not delete the mutation.

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
- Modify: `docs/greenfield/research/invariants/check-inventory.sh`
- Modify: `docs/greenfield/research/invariants/validate-composition-coverage.jq`

- [ ] **Step 1: Author the corpus cases**

  One `#### \`<ID>\`` heading per new invariant, matching
  `^#### \`([A-Z][A-Z0-9]*-[0-9]{3})\`` exactly — four hashes, one space,
  backticks around the identifier. One `### \`VAL-nnn\`` heading per new valid
  witness — **three** hashes.

  Place invalid cases inside the topically correct existing `###` family or open
  a new `### Packet E …` family. Follow the body convention used by all 140
  current cases, in order: `- Owner:`, `- First-sound phase:`,
  `- Rejection deadline:`, `- Invariant:`, `- Minimum witness:`,
  `- Required diagnostic:` (or `- Required result:`). All 140 agree exactly
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

  Reuse existing `compositionPaths` tokens. The 68-token vocabulary is pinned in
  three places; introducing a new token forces editing
  `PACKET-D-COMPOSITION-PATHS.json`, the jq alias literal, the `== 68` count,
  and two digest pins, and **reopens Packet D** under that file's
  `reopenPolicy`.

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
  `O ∉ P.reachableOwners` the code is `F` and is always effect-legal. Only paths
  where `O ∈ P.reachableOwners` — `live` 1, `exec` 1, `framework` 3, `create` 6,
  `service` 7, `operator` 9, `runtime` 12, `artifact` 27 — plus the four typed
  request caller paths (`direct-api`, `framework-adapter`, `cli-adapter`,
  `managed-service`) where `B` is a live option, require judgement.

  Use `L` (same-owner-stage-or-fact-class) rather than `F` where the owner
  matches the path but the stage does not. The validator checks only effect
  legality and the pinned sets; the `F`/`L`/`I`/`H` distinction is
  reviewer-enforced, so choose honestly.

  Do not join the pinned exact-set groups: `target-lowering` (89),
  `serialized-resolved-reentry` (107 both sides), and the three
  provider-construction paths (fixed 9-ID list).

  Cheap inner loop, no regeneration:

  ```sh
  cd docs/greenfield/research/invariants
  jq -e --arg validationScope catalog \
    --arg pathsRegistrySha256 "$(shasum -a 256 PACKET-D-COMPOSITION-PATHS.json | awk '{print $1}')" \
    --arg caseContractsSha256 "$(shasum -a 256 PACKET-D-CASE-CONTRACTS.json | awk '{print $1}')" \
    --arg invariantRegistrySha256 "$(shasum -a 256 invariants.json | awk '{print $1}')" \
    --slurpfile paths PACKET-D-COMPOSITION-PATHS.json \
    --slurpfile registry invariants.json \
    -f validate-composition-coverage.jq PACKET-D-CASE-CONTRACTS.json >/dev/null
  ```

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
  - `processStates` (5): `accepted`, `starting`, `running`, `unknown`,
    `terminated`.
  - `processTerminationVariants` (9) — four are stated only in the document
    body, not in any numbered list.
  - `operationStates` (7) and `terminalOutcomes` (4): `succeeded`, `failed`,
    `cancelled`, `unknown`.
  - `requestErrorVariants` — the closed 31-variant union.
  - `modeContract` — a canonical `mode -> phase -> component` table mirroring
    `validate-target-realization.jq:25-63`. **Lock this before authoring any
    case**; the validator recomputes canonical phase and component per mode, and
    changing it later invalidates every obligation identifier.

  Align names with the existing prototype's `ContractModel`
  (`prototypes/packet-e-contract-compiler/src/model.ts:17-40`) rather than
  inventing parallel vocabulary.

- [ ] **Step 3: Author the operation records**

  One record per Core operation with a closed key set: `id`, `callClass`,
  `targetKind`, `owner`, `capabilityGate`, `mutationClass`,
  `resultCarrierKind`, `allowedRequestErrors[]`, `allowedKnownFailures[]`,
  `allowedAmbiguities[]`, `recoveryCoordinates[]`, `refinesPacketASurfaces[]`,
  `refinesPacketBFields[]`, `invariants[]`, `delegatedPackets[]`, `rationale`.

  Coverage is total: the six mandatory driver operations, all reads and
  observations, all Process transport and control commands, and every
  capability-gated operation. The 13 rejected names must appear nowhere.

- [ ] **Step 4: Close the inherited delegations**

  `introducedInvariants[]` must reference only identifiers present in
  `invariants.json`, and every one must be referenced by at least one operation
  — the bidirectional pattern from Packet B.

  Additionally, every Packet A surface with `delegatedPacket == "E"` (the 20
  named surfaces, from `artifact.lifetime-maximum` through
  `runtime.cleanup-errors`) must be named by some operation; the 5 Packet B
  fields delegating `"E"` must be resolved; and the 6 Packet C rules carrying
  those delegations must be discharged.

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
  attempt the 16-dimension flat product implied by the taxonomy document.

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
  `otherwise` last), `cellKind`, `terminalOutcome`, `requestErrorId` (non-null
  **iff** the cell kind is reject), `nextLifecycleStateId`, `epochRule`,
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
  `jq -e … -f validate-operation-contracts.jq` invocation mirroring the
  seven-argument shape at `:115-125`, then an inline absolute-count `jq -e`
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

  Baseline counts (`:18-32`), the owner-distribution table (from `:38`), the
  lifecycle-semantics row (`:88`) from `partial` to `reviewed`, the dynamic-state
  and security rows as the Task 1 Step 3 ruling determines, the Packet D digest
  quotations (`:221-227`), the closing status (`:230-231`), and the Packet E
  section (`:233-313`) rewritten from "these foundations do not close Packet E"
  to the completed review record with its ledger links.

  The top status line becomes: Packets A through E reviewed; Packet F remains.

- [ ] **Step 2: Update `INVARIANT-ENFORCEMENT.md`**

  Add the Packet E ledger links to the list at `:172-215`, update the counts
  paragraph at `:216-245`, and update the inventory-mode description at
  `:396-402` to name the Packet E validator. Update the mermaid phase graph at
  `:277-337` only if Task 1 Step 2 selected Option B.

- [ ] **Step 3: Update the Packet D records**

  `PACKET-D-COMPOSITION-REVIEW.md` at `:41-43`, `:70-80`, `:271-281` (six review
  evidence digests, including the validator's own — editing
  `validate-composition-coverage.jq` invalidates its recorded digest),
  `:283-284`, `:297-298`, `:309-311`; and
  `PACKET-D-RESEARCH-NOTES.md:87-88`.

  State plainly that Packet D's matrix was widened by Packet E registration and
  that its reviewed verdicts stand for the paths and classification semantics,
  not for the new cells' individual classifications.

- [ ] **Step 4: Update the design and audit documents**

  `DESIGN.md:109-113` (the 54-path / 140-invariant / 7,560-cell sentence),
  `CONFIGURATION-BOUNDARY-AUDIT.md:144`, and
  `research/prototypes/README.md:103-104`.

- [ ] **Step 5: Write the Packet E decision record**

  `PACKET-E-OPERATION-CONTRACT-REVIEW.md` must state: the four Task 1 rulings
  and their rationale; the obligation partition summary (178 listed → distinct →
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
  rows. Packet F's rows will still be open; state that explicitly.

---

## Plan Self-Review

- **Spec coverage.** Task 1 resolves the four blocking structural decisions that
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

- **Known deliberate reduction.** The concurrency ledger may be restricted to
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
  the entry count by 10-15 and therefore changes the identifier block.

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
