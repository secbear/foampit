# Packet E Operation Contract Inventory Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> `superpowers:subagent-driven-development` (recommended) or
> `superpowers:executing-plans` to implement this plan task-by-task. Use
> `superpowers:test-driven-development` for every behavior change and
> `superpowers:verification-before-completion` before each stage is accepted.
> Every stage also requires the adversarial gate below; do not pause for routine
> human approval between stages.

**Goal:** Implement the locked Packet E operation-contract inventory as a
standalone, language-neutral semantic authority with independently checked
normalization, complete coverage/proof obligations, closed trust/evidence
envelopes, and executable durable-state reference models.

**Architecture:** Product-owned closed JSON catalogs are the authored semantic
source. A dependency-free normalizer emits a canonical `ContractModel` and
proof material but cannot accept its own output. Independent raw-byte, schema,
`jq`, CUE, model-interpreter, transition-oracle, interaction, and Lean-kernel
checks establish acceptance. Runtime evidence is modeled through closed
provider-neutral schemas and an executable SQLite reference oracle; the
reference oracle is not a production runtime-language decision. Packet C and
Packet F measurements, reports, keys, and live logs remain foreign imports and
protected operational data.

**Tech Stack:** The exact Nixpkgs revision and store derivations committed by
Stage 00; Node.js without third-party runtime packages for canonicalization and
normalization; `jq`; CUE; Lean 4 plus pinned libraries; Nix-pinned
`check-jsonschema`; Python's standard library and SQLite for the executable
durability oracle; Bash only as a strict orchestrator. The flake must evaluate
on `x86_64-linux`, `aarch64-linux`, `x86_64-darwin`, and `aarch64-darwin`.
Execution support is claimed per-system only after its CI job has passed.

**Source design:** [PACKET-E-OPERATION-CONTRACT-INVENTORY-DESIGN.md](../research/invariants/PACKET-E-OPERATION-CONTRACT-INVENTORY-DESIGN.md)

**Status:** Awaiting stage-plan adversarial approval. Completion produces an
honest Packet E Gate 2A decision; it closes Packet E's Gate 2A requirement only
if every required static Packet A/B/C/F specification import resolves to its
exact revision and digest. It cannot close Gate 4B or claim backend support
until real Packet C/F hooks, trust material, conformance executions, current
measurements, and reports exist.

---

## Non-negotiable implementation boundaries

- `PacketEScopeManifest` is the sole membership authority. A non-authoritative
  tooling inventory at `packet-e-tooling/source-inventory.json` provides a
  deterministic ordered byte-input list, schema binding, and typed role
  (`catalog-semantic`, `assurance-definition`, or `generated`) for preflight.
  It must exact-match the identities and source-schema digests pinned by
  `PacketEScopeManifest`; it cannot add authority. Invalid fixtures and review
  records are enumerated by their test-case/review manifests and never enter
  the accepted source inventory.
- `packet-e-tooling/tool-inventory.json` exact-lists every script, checker,
  proof source, build input, executable entrypoint, and workflow used for
  assurance. `packet-e-tooling/test-inventory.json` exact-lists every test
  runner and raw fixture—including deliberately invalid JSON—with its expected
  diagnostic. Scope and baseline bind the ordered digests of both inventories.
  Neither inventory owns semantics, but unlisted tooling/tests cannot
  contribute evidence.
- The normalizer accepts only preflight-attested `catalog-semantic` files.
  Proofs, scope, review baseline, witnesses, generated outputs, and assurance
  definitions are unavailable to normalization.
- `CatalogDenotation`, not JSON Schema, CUE, the normalizer, TypeSpec, or the
  executable reference model, defines the catalog's meaning.
- The normalizer emits no pass/fail decision, certificate, baseline update, or
  expected test result.
- The independent normalization checker shares no production imports with the
  normalizer. Shared test fixtures and wire schemas are allowed; shared
  semantic code is not.
- Expected identities, counts, axis signatures, applicability commitments,
  oracle outcomes, and mutation results are pinned independently of the
  catalog being tested. No checker may regenerate its expected universe from
  the input under test.
- All JSON is checked as raw bytes before generic parsing. Recursive duplicate
  keys, invalid UTF-8, invalid RFC 8259 tokens, noncanonical semantic decimal
  strings, and forbidden host-path data fail closed.
- JSON schemas are closed and versioned. Unknown fields, unknown
  discriminators, missing explicit policies, wildcard/default cases, and
  nullable semantic handles fail closed.
- The full interaction candidate universe remains symbolic:
  `2^19 - 1 = 524287`. It must never be materialized as 524,287 catalog rows.
- Lean proofs contain no `sorry`, `admit`, project-local semantic axiom,
  `False` axiom, unclassified imported axiom, hidden semantic premise, or
  unpinned dependency.
- Full `BackendMeasurement` and `BackendConformanceReport` bodies never enter
  the Packet E source tree. Packet E owns only the normalized observation,
  evaluation, admission, log-verification, and current-view envelopes.
- The SQLite code is a deterministic, independently authored executable
  reference for process-crash atomicity. It consumes the exact certified
  `ContractModel` bytes and pinned interpreter identity and must reject drift.
  It is not normative and does not select Python, SQLite, or any other
  language/store for the Foampit runtime. Power-loss, kernel panic, filesystem
  corruption, short-write, `ENOSPC`, device-cache, and storage-hardware
  durability are explicitly outside this reference claim.
- Synthetic keys, attestations, measurements, reports, receipts, and clocks
  live only under `fixtures/packet-e/`. They cannot satisfy `gate-2a` static
  imports or `operational` evidence.
- Validation has three explicit outcomes:
  `structure-valid/gate-2a-open` permits unresolved required static imports;
  `packet-e-gate-2a-valid` requires every static Packet A/B/C/F specification
  import to resolve exactly; `gate-4b-operationally-current` additionally
  requires real current measurements, logs, reports, keys, and witnesses.
  No outcome may silently substitute fixtures for foreign evidence.
- Diagnostics expose stable IDs and semantic paths, never secrets, raw
  provider payloads, credentials, unrestricted host paths, or native stack
  traces.
- The existing Packet E TypeSpec compiler remains research evidence. New
  authority code may copy no semantic tables from it and may not import it.
- No stage weakens the locked design to make a spike or test pass. A failed
  feasibility gate stops dependent stages and records the unmet contract.

## Stage acceptance protocol

Every task below is one stage. A stage is accepted only after all of the
following are true:

1. The stage's RED test was observed failing for the intended missing or broken
   behavior.
2. The focused tests and the cumulative `packet-e-all.sh` suite pass. Stage 00
   uses its own spike runner because the cumulative runner does not yet exist.
3. Generated files reproduce byte-for-byte in a fresh temporary tree.
4. The implementation is committed as a candidate commit without its review
   record.
5. Three independent adversarial reviewers inspect that exact candidate commit:
   semantic correctness/requirement coverage, formal independence/anti-
   Goodhart properties, and security/durability/trust boundaries.
6. Every blocker or major finding is fixed in a new candidate commit, the
   focused and cumulative suites are rerun, and the relevant reviewer rechecks
   it. A stage with any open blocker or major finding is rejected.
7. `reviews/stage-NN.md` records the final reviewed subject commit and tree,
   commands, results,
   findings, resolutions, residual minor risks, and the explicit
   `accepted`/`rejected` disposition.
8. The review record is committed separately as evidence. It names the
   reviewed subject commit and never claims that the evidence-only commit was
   itself the reviewed subject. The next stage begins only after that evidence
   commit.

Reviewers may request additional tests, mutations, or proof obligations. They
may not waive a locked contract. Routine stage review replaces human
checkpoints; only a genuine scope/authority conflict not answered by the
locked design is escalated.

Every stage that adds or changes any semantic or assurance input—JSON, code,
proof, build file, executable, workflow, or test—must update the applicable
source/tool/test inventory, exact schema registry, `PacketEScopeManifest`
identity/digest membership where applicable, genesis/current review baseline,
and required typed semantic/assurance change record in the same candidate
commit. The cumulative test rejects a missing update. The baseline and
change-record machinery is established before the first catalog commit.

Fixture convention is exact: each stage owns
`fixtures/packet-e/<stage>/valid.json`,
`fixtures/packet-e/<stage>/cases.json`, and one raw input per diagnostic at
`fixtures/packet-e/<stage>/invalid/<diagnostic-id>.json`. The validator under
test returns nonzero and prints the expected stable diagnostic ID. The focused
test runner supports `--case <diagnostic-id>`, asserts the validator's status
and diagnostic, and returns zero on GREEN. Before implementation, that same
focused runner returns nonzero because it observes the stage's
`*-unimplemented` diagnostic instead of the expected diagnostic. The
cumulative suite invokes focused runners, never raw invalid validators.

## Execution graph

```text
Stage 00 feasibility spikes/toolchain
  └─ Stage 01 harness/raw-byte boundary/CI
       └─ Stage 02 scope, schemas, and genesis governance
            └─ Stages 03A–03D Core catalog tranches
                 ├─ Stage 04 denotation/normalization/interpreter authority
                 │    └─ Stage 05 proof-independent coverage specs
                 │         └─ Stage 06 independent oracle freeze
                 │              └─ Stage 07 universal proofs + finalized shards
                 └─ Stage 08 foreign trust/decoder boundary
                      └─ Stage 09 evaluation envelopes/provenance paths
                           └─ Stage 10 attempt model/process-crash store
                                └─ Stage 11 durable witnessed logs/rotation
                                     └─ Stage 12 reports/current view
Stage 07 + Stage 12
  └─ Stage 13 diagnostics/change-control audit
       └─ Stage 14 three-level inventory integration
            └─ Stage 15 subject verification + external CI attestation
```

---

### Stage 00: Blocker-first feasibility spikes

**Files:**

- Create:
  `docs/greenfield/research/prototypes/packet-e-assurance-spikes/README.md`
- Create:
  `docs/greenfield/research/prototypes/packet-e-assurance-spikes/flake.nix`
- Create:
  `docs/greenfield/research/prototypes/packet-e-assurance-spikes/flake.lock`
- Create:
  `docs/greenfield/research/prototypes/packet-e-assurance-spikes/normalization/normalizer.mjs`
- Create:
  `docs/greenfield/research/prototypes/packet-e-assurance-spikes/normalization/checker.mjs`
- Create:
  `docs/greenfield/research/prototypes/packet-e-assurance-spikes/normalization/dependency-audit.mjs`
- Create:
  `docs/greenfield/research/prototypes/packet-e-assurance-spikes/normalization/cases.json`
- Create:
  `docs/greenfield/research/prototypes/packet-e-assurance-spikes/formal/lakefile.toml`
- Create:
  `docs/greenfield/research/prototypes/packet-e-assurance-spikes/formal/lean-toolchain`
- Create:
  `docs/greenfield/research/prototypes/packet-e-assurance-spikes/formal/PacketESpike.lean`
- Create:
  `docs/greenfield/research/prototypes/packet-e-assurance-spikes/formal/audit.mjs`
- Create:
  `docs/greenfield/research/prototypes/packet-e-assurance-spikes/durability/model.py`
- Create:
  `docs/greenfield/research/prototypes/packet-e-assurance-spikes/durability/sqlite_store.py`
- Create:
  `docs/greenfield/research/prototypes/packet-e-assurance-spikes/durability/crash_driver.py`
- Create:
  `docs/greenfield/research/prototypes/packet-e-assurance-spikes/durability/test.sh`
- Create:
  `docs/greenfield/research/prototypes/packet-e-assurance-spikes/run.sh`
- Create:
  `docs/greenfield/research/prototypes/packet-e-assurance-spikes/toolchain.json`
- Create:
  `docs/greenfield/research/invariants/reviews/stage-00.md`

**Interfaces:**

- Consumes: two deliberately small closed catalog documents and independent
  expected fixtures.
- Produces: feasibility evidence only; no production catalog, baseline,
  certificate, or gate claim.

- [ ] **Step 1: Write RED normalization-spike tests**

  Require a two-file source set with selectors, profiles, internal references,
  pinned foreign imports, nontrivial ordering, canonical model bytes,
  source-field reachability proof material, and an independent checker. Add
  mutations for an omitted source field, changed selector/profile/reference/
  import/order rule, constant normalizer output, checker/normalizer co-drift,
  and a source/model digest mismatch.

- [ ] **Step 2: Write RED formal-spike tests**

  Require Lean to consume exact canonical JSON proof material and prove one
  unbounded population-abstraction theorem, one induction/symmetry theorem,
  one mixed-family increment-commutation theorem, one proof-independent
  symbolic `CoverageShardSpec` disjointness/exhaustiveness/cardinality theorem,
  and one contextual-reduction theorem quantified over another family,
  interleavings, and the complete carrier. Add negative fixtures for `sorry`,
  an extra/transitive third-party axiom, a local premise, conclusion-as-
  assumption, and premise smuggling through a subtype, `Nonempty`, `Exists`,
  semantic `Decidable`, a typeclass argument, an opaque definition, and nested
  `Type` parameter. Audit the elaborated interface and transitive dependency/
  axiom closure, not source spelling.

- [ ] **Step 3: Write RED durability-spike tests**

  Model atomic log append, attempt-state compare-and-swap, slot-head
  compare-and-swap, and conflict-resolution multi-CAS in SQLite WAL mode. Kill
  a subprocess at `before-begin`, after each statement, `before-commit`, and
  `after-commit-before-reply`; reopen the database and require exactly the
  predecessor or complete successor state—never a partial state. This spikes
  process-crash transaction atomicity only, not power/storage durability.

- [ ] **Step 4: Run the spike suite and record RED**

  Run:

  ```sh
  nix develop ./docs/greenfield/research/prototypes/packet-e-assurance-spikes \
    --command ./docs/greenfield/research/prototypes/packet-e-assurance-spikes/run.sh
  ```

  Expected: all three spike groups fail because their implementations do not
  exist.

- [ ] **Step 5: Implement the minimum independent spikes**

  Keep the normalizer and checker in separate directories with a dependency
  audit that rejects cross-imports. Keep formal theorem inputs byte-bound.
  Keep the durability transition model pure and compare it with every SQLite
  transition and recovery.

- [ ] **Step 6: Run GREEN and the feasibility stop conditions**

  Expected: all mutations are killed; Lean kernel checking completes within the
  documented CI budget; crash recovery observes only predecessor/successor.
  Stop dependent work if any result requires shared semantic code, unchecked
  axioms, bounded-only reasoning where the design requires universality, or a
  non-atomic recovery assumption.

- [ ] **Step 7: Pin the production assurance toolchain**

  Record exact Nixpkgs, Node, `jq`, CUE, Lean/library,
  `check-jsonschema`, Python, and SQLite versions and store derivations in
  `toolchain.json`. Later production tooling must reproduce this manifest;
  spike semantic code is not promoted.

- [ ] **Step 8: Commit the Stage 00 candidate**

  Commit the spike implementation and `toolchain.json`, excluding
  `reviews/stage-00.md`.

- [ ] **Step 9: Run and record the Stage 00 adversarial gate**

  Record exact tool versions, elapsed proof time, crash schedule, reviewer
  findings, final candidate commit/tree, and accepted/rejected status in
  `reviews/stage-00.md`.

- [ ] **Step 10: Commit the evidence-only review record**

  ```sh
  git add docs/greenfield/research/invariants/reviews/stage-00.md
  git commit -m "review: accept Packet E assurance feasibility spike"
  ```

---

### Stage 01: Reproducible harness and raw-byte boundary

**Files:**

- Create:
  `docs/greenfield/research/invariants/packet-e-tooling/flake.nix`
- Create:
  `docs/greenfield/research/invariants/packet-e-tooling/flake.lock`
- Create:
  `docs/greenfield/research/invariants/packet-e-tooling/preflight-json.mjs`
- Create:
  `docs/greenfield/research/invariants/packet-e-tooling/canonical-json.mjs`
- Create:
  `docs/greenfield/research/invariants/packet-e-tooling/check-toolchain.sh`
- Create:
  `docs/greenfield/research/invariants/packet-e-tooling/source-inventory.json`
- Create:
  `docs/greenfield/research/invariants/packet-e-tooling/tool-inventory.json`
- Create:
  `docs/greenfield/research/invariants/packet-e-tooling/test-inventory.json`
- Create:
  `docs/greenfield/research/invariants/packet-e-tooling/schema-registry.json`
- Create:
  `docs/greenfield/research/invariants/packet-e-tooling/bootstrap-schemas/source-inventory.schema.json`
- Create:
  `docs/greenfield/research/invariants/packet-e-tooling/bootstrap-schemas/tool-inventory.schema.json`
- Create:
  `docs/greenfield/research/invariants/packet-e-tooling/bootstrap-schemas/test-inventory.schema.json`
- Create:
  `docs/greenfield/research/invariants/packet-e-tooling/bootstrap-schemas/schema-registry.schema.json`
- Create:
  `docs/greenfield/research/invariants/packet-e-tooling/bootstrap-schemas/attested-source-set.schema.json`
- Create:
  `docs/greenfield/research/invariants/packet-e-tooling/bootstrap-schemas/toolchain.schema.json`
- Create:
  `docs/greenfield/research/invariants/packet-e-tooling/bootstrap-schemas/json-schema-dialect-meta.schema.json`
- Create:
  `docs/greenfield/research/invariants/packet-e-tooling/validate-bootstrap.sh`
- Create:
  `docs/greenfield/research/invariants/packet-e-tooling/packet-e-all.sh`
- Create: `.github/workflows/packet-e.yml`
- Create:
  `docs/greenfield/research/invariants/fixtures/packet-e/preflight/`
- Create:
  `docs/greenfield/research/invariants/test-packet-e-preflight.sh`
- Create:
  `docs/greenfield/research/invariants/reviews/stage-01.md`

**Interfaces:**

- `preflight-json.mjs <source-inventory> <root>` emits a canonical
  `AttestedSourceSet` containing exact relative paths, byte lengths, per-file
  SHA-256 values, and the ordered source-set digest.
- It emits stable diagnostic JSON to stderr and no partially parsed value on
  failure.

- [ ] **Step 1: Write RED fixtures and shell tests**

  Exact cases are `packet-e/json-duplicate-key`,
  `packet-e/json-invalid-utf8`, `packet-e/json-trailing-token`,
  `packet-e/json-malformed-escape`, `packet-e/decimal-noncanonical`,
  `packet-e/path-symlink-escape`, `packet-e/path-absolute`,
  `packet-e/source-missing`, `packet-e/source-unlisted-authority`,
  `packet-e/source-order`, and `packet-e/unicode-invalid`. Cover nested
  duplicate keys, invalid UTF-8, trailing tokens, malformed
  escapes, noncanonical semantic decimal strings, symlink/path escape,
  absolute host paths, missing listed files, unlisted authoritative files,
  reordered manifest entries, and valid Unicode edge cases.
  Bootstrap cases additionally include `packet-e/bootstrap-unknown-field`,
  `packet-e/bootstrap-duplicate-path`, `packet-e/bootstrap-role-substitution`,
  `packet-e/bootstrap-tool-omitted`, `packet-e/bootstrap-fixture-omitted`, and
  `packet-e/bootstrap-expected-diagnostic-drift`,
  `packet-e/bootstrap-inventory-self-reference`, and
  `packet-e/bootstrap-registry-substitution`. Schema-language cases include
  `packet-e/bootstrap-schema-unknown-keyword`,
  `packet-e/bootstrap-schema-additional-properties-misspelled`,
  `packet-e/bootstrap-schema-dialect-changed`,
  `packet-e/bootstrap-schema-network-resolution`, and
  `packet-e/bootstrap-registry-schema-as-meta-schema`.

- [ ] **Step 2: Run and observe RED**

  ```sh
  nix develop ./docs/greenfield/research/invariants/packet-e-tooling \
    --command ./docs/greenfield/research/invariants/test-packet-e-preflight.sh \
    --case packet-e/json-duplicate-key
  ```

  Expected RED: nonzero with first diagnostic
  `packet-e/preflight-unimplemented`. Expected GREEN:
  `packet-e/json-duplicate-key`.

- [ ] **Step 3: Implement raw-byte preflight**

  Use a token-level parser that detects duplicate keys before object
  construction. Normalize no source bytes. Canonicalization is a separate
  operation over already-attested parsed values. Reject path traversal and
  resolve all paths relative to the declared Packet E root.

- [ ] **Step 4: Close and validate the bootstrap trust root**

  Raw-preflight the three inventories, schema registry, `AttestedSourceSet`,
  Stage 00 toolchain manifest, their six instance schemas, and the separate
  closed bootstrap schema-dialect meta-schema before generic parsing. The
  deliberately restricted, offline dialect meta-schema exact-allows the JSON
  Schema keywords/dialect used here, rejects unknown keywords and remote
  resolution, and is not the registry-instance schema. Validate each of the
  six instance schemas against that pinned dialect meta-schema; separately
  validate `schema-registry.json` against
  `schema-registry.schema.json`; only then validate the inventories,
  `AttestedSourceSet`, and toolchain manifest against their registered schemas
  with Nix-pinned `check-jsonschema`. Independently pin all seven schema digests
  in both checker source and Nix derivation; require exact agreement so an
  inventory, registry, or schema cannot authorize itself or replace the
  bootstrap schema root. The source/tool/test inventories are not used to
  enumerate, copy, hash, or admit evidence until this chain passes.

- [ ] **Step 5: Pin and verify the toolchain**

  Commit the lockfile. `check-toolchain.sh` must compare exact versions and
  derivation identities with Stage 00's committed manifest. The CI workflow
  evaluates all four flake systems and runs the suite on every available
  native runner; each check summary names evaluated versus executed systems.
  No global executable may satisfy a check and no unexecuted system gets an
  execution-support claim.

- [ ] **Step 6: Run GREEN and fresh-temp isolation**

  Copy only the exact union of source-, tool-, and test-inventory entries to a
  fresh temporary directory. Run the suite with an empty package cache and a sanitized
  environment. Expected: byte-identical attestation and no absolute workspace
  path in outputs.

- [ ] **Step 7: Commit the Stage 01 candidate**

  Commit all Stage 01 files except `reviews/stage-01.md`.

- [ ] **Step 8: Run and record the Stage 01 adversarial gate**

- [ ] **Step 9: Commit the evidence-only review record**

  ```sh
  git add docs/greenfield/research/invariants/reviews/stage-01.md
  git commit -m "review: accept Packet E raw-byte boundary"
  ```

---

### Stage 02: Scope authority, closed schemas, and genesis governance

**Files:**

- Create: `docs/greenfield/research/invariants/packet-e/scope-manifest.json`
- Create:
  `docs/greenfield/research/invariants/packet-e/review-baseline.json`
- Create:
  `docs/greenfield/research/invariants/packet-e/semantic-change-records.json`
- Create:
  `docs/greenfield/research/invariants/packet-e/assurance-change-records.json`
- Create: `docs/greenfield/research/invariants/packet-e/explanations.json`
- Create:
  `docs/greenfield/research/invariants/packet-e/schemas/scope-manifest.schema.json`
- Create:
  `docs/greenfield/research/invariants/packet-e/schemas/review-baseline.schema.json`
- Create:
  `docs/greenfield/research/invariants/packet-e/schemas/semantic-change-records.schema.json`
- Create:
  `docs/greenfield/research/invariants/packet-e/schemas/assurance-change-records.schema.json`
- Create:
  `docs/greenfield/research/invariants/packet-e/schemas/explanations.schema.json`
- Create:
  `docs/greenfield/research/invariants/packet-e-tooling/validate-json-schemas.py`
- Create:
  `docs/greenfield/research/invariants/packet-e-tooling/validate-source-authority.mjs`
- Create:
  `docs/greenfield/research/invariants/test-packet-e-schemas.sh`
- Create:
  `docs/greenfield/research/invariants/fixtures/packet-e/schema/`
- Create: `docs/greenfield/research/invariants/reviews/stage-02.md`

**Interfaces:**

- `packet-e-tooling/schema-registry.json` exact-maps every authored/generated
  document kind and version to one schema digest but owns no membership.
- `scope-manifest.json` independently pins the 32 method IDs, 19 family IDs,
  axes, foreign participants, and symbolic interaction count.
- `review-baseline.json` begins at a typed genesis predecessor. All later
  semantic and assurance changes are predecessor-bound before acceptance.

- [ ] **Step 1: Write RED schema/authority tests**

  Test unknown properties, missing/unknown discriminators, schema-ID
  collisions, unregistered documents, listed-but-missing schemas, self-
  inclusion cycles, schema drift, an added 33rd method, a removed family, and
  a changed `524287` interaction count.

- [ ] **Step 2: Run and observe RED**

  ```sh
  nix develop ./docs/greenfield/research/invariants/packet-e-tooling \
    --command ./docs/greenfield/research/invariants/test-packet-e-schemas.sh \
    --case packet-e/schema-unknown-property
  ```

  Expected RED: `packet-e/schema-validator-unimplemented`. Expected GREEN:
  `packet-e/schema-unknown-property`.

- [ ] **Step 3: Implement the closed meta-schema and registry**

  Pin `check-jsonschema` in the Nix environment. Every record uses explicit
  `schemaVersion` and stable identity. Reject
  permissive extension points. Hash schema bytes after raw preflight. Keep the
  scope manifest outside the catalog normalization input so it remains an
  independent review oracle.

- [ ] **Step 4: Implement exact source authority**

  Prove that every Packet E identity is owned by the scope manifest; every
  tooling-inventory file is listed once with one typed role and registered
  schema; catalog-semantic inventory matches the CatalogDenotation source
  schema set; generated/review/fixture files are excluded from semantic
  source; and foreign operational stores are outside the tree.

- [ ] **Step 5: Establish genesis baseline and typed change records**

  The genesis baseline pins the initial scope, schema, toolchain, diagnostic,
  and governance identities. Empty semantic/assurance histories are valid only
  at genesis. Add mutations for an unbound predecessor, wrong change kind,
  restamped digest, missing rationale, and a post-genesis change without a
  record.

- [ ] **Step 6: Run GREEN, mutation suite, and cumulative suite**

- [ ] **Step 7: Commit the Stage 02 candidate**

- [ ] **Step 8: Run and record the Stage 02 adversarial gate**

- [ ] **Step 9: Commit the evidence-only review record**

  ```sh
  git add docs/greenfield/research/invariants/reviews/stage-02.md
  git commit -m "review: accept Packet E scope and genesis authority"
  ```

---

### Stage 03A: Domain, variant, method, and carrier identities

**Files:**

- Create: `docs/greenfield/research/invariants/packet-e/domains.json`
- Create: `docs/greenfield/research/invariants/packet-e/semantic-variants.json`
- Create: `docs/greenfield/research/invariants/packet-e/methods.json`
- Create: `docs/greenfield/research/invariants/packet-e/system-triggers.json`
- Create:
  `docs/greenfield/research/invariants/packet-e/durable-operation-kinds.json`
- Create:
  `docs/greenfield/research/invariants/packet-e/process-completion-contracts.json`
- Create:
  `docs/greenfield/research/invariants/packet-e-tooling/validate-packet-e-catalog.jq`
- Create:
  `docs/greenfield/research/invariants/test-packet-e-catalog.sh`
- Create:
  `docs/greenfield/research/invariants/fixtures/packet-e/catalog-identity/`
- Create: `docs/greenfield/research/invariants/reviews/stage-03a.md`
- Create the six same-basename closed schemas under `packet-e/schemas/`.
- Modify the tooling inventory/registry, scope manifest, baseline, and typed
  change records required by the global protocol.

**Interfaces:** These files establish exact identity and ownership only. They
contain the independently reviewed 32 method identities and canonical carrier
references; later catalog tranches fill referenced semantics without
restatement.

- [ ] **Step 1: Write RED exact-set/ownership cases**

  Cases include `packet-e/method-set`, `packet-e/variant-set`,
  `packet-e/duplicate-owner`, `packet-e/default-name`,
  `packet-e/wildcard-case`, `packet-e/unreachable-variant`, and
  `packet-e/carrier-restatement`. Expected sets live in
  `fixtures/packet-e/catalog-identity/expected.json` and are not generated
  from catalog input.

- [ ] **Step 2: Run exact RED**

  ```sh
  nix develop ./docs/greenfield/research/invariants/packet-e-tooling \
    --command ./docs/greenfield/research/invariants/test-packet-e-catalog.sh \
    --phase identity --case packet-e/method-set
  ```

  Expected RED: `packet-e/catalog-identity-unimplemented`. Expected GREEN:
  `packet-e/method-set`.

- [ ] **Step 3: Implement the identity tranche and exact-set validator**

  Reject missing, extra, duplicate, unreachable, wrong-kind, stale-revision,
  and unowned identities. Define each semantic identity once and reuse only by
  stable ID plus revision.

- [ ] **Step 4: Run GREEN, cumulative suite, and byte regeneration**

- [ ] **Step 5: Commit the Stage 03A candidate**

- [ ] **Step 6: Run the three-role review and commit only
  `reviews/stage-03a.md` as acceptance evidence**

---

### Stage 03B: Acceptance, recovery, idempotency, and retention

**Files:**

- Create:
  `docs/greenfield/research/invariants/packet-e/observation-commit-contracts.json`
- Create:
  `docs/greenfield/research/invariants/packet-e/acceptance-commit-contracts.json`
- Create:
  `docs/greenfield/research/invariants/packet-e/idempotency-namespace-contracts.json`
- Create: `docs/greenfield/research/invariants/packet-e/recovery-contracts.json`
- Create: `docs/greenfield/research/invariants/packet-e/retention-policies.json`
- Create the five same-basename schemas under `packet-e/schemas/`.
- Create:
  `docs/greenfield/research/invariants/fixtures/packet-e/catalog-lifecycle/`
- Create: `docs/greenfield/research/invariants/reviews/stage-03b.md`
- Modify methods, tooling inventory/registry, scope, baseline, and typed change
  records.

- [ ] **Step 1: Write RED lifecycle cases**

  Cases include `packet-e/acceptance-recovery-atomicity`,
  `packet-e/idempotency-key-policy`, `packet-e/idempotency-content-mismatch`,
  `packet-e/namespace-epoch-retention`, `packet-e/post-gc-proof`,
  `packet-e/retention-snapshot`, `packet-e/admission-revision-race`, and
  `packet-e/observation-commit-order`.

- [ ] **Step 2: Run exact RED**

  ```sh
  nix develop ./docs/greenfield/research/invariants/packet-e-tooling \
    --command ./docs/greenfield/research/invariants/test-packet-e-catalog.sh \
    --phase lifecycle --case packet-e/acceptance-recovery-atomicity
  ```

- [ ] **Step 3: Implement the lifecycle tranche**

  Separate intent, acceptance commit, recovery binding, observation commit,
  namespace epoch/history, and post-GC unprovability. Every method explicitly
  defines absent-key and same-key/different-content behavior.

- [ ] **Step 4: Run GREEN and required lifecycle/crash mutations**

- [ ] **Step 5: Commit candidate; adversarially review the exact SHA; commit
  only `reviews/stage-03b.md` as acceptance evidence**

---

### Stage 03C: Evidence, multiplicity, population, and Snapshot semantics

**Files:**

- Create:
  `docs/greenfield/research/invariants/packet-e/evidence-requirements.json`
- Create:
  `docs/greenfield/research/invariants/packet-e/evidence-decoding-contracts.json`
- Create:
  `docs/greenfield/research/invariants/packet-e/multiplicity-contracts.json`
- Create:
  `docs/greenfield/research/invariants/packet-e/population-abstraction-contracts.json`
- Create: `docs/greenfield/research/invariants/packet-e/snapshot-classes.json`
- Create:
  `docs/greenfield/research/invariants/packet-e/snapshot-compatibility.json`
- Create the six same-basename schemas under `packet-e/schemas/`.
- Create:
  `docs/greenfield/research/invariants/fixtures/packet-e/catalog-evidence/`
- Create: `docs/greenfield/research/invariants/reviews/stage-03c.md`
- Modify methods, tooling inventory/registry, scope, baseline, and typed change
  records.

- [ ] **Step 1: Write RED evidence/population/Snapshot cases**

  Cases include `packet-e/evidence-owner`, `packet-e/decoder-outcome-set`,
  `packet-e/multiplicity-binding`, `packet-e/logical-only-population`,
  `packet-e/population-domain-signature`, `packet-e/snapshot-component-set`,
  `packet-e/snapshot-quiescence`, and
  `packet-e/snapshot-compatibility-totality`.

- [ ] **Step 2: Run exact RED**

  ```sh
  nix develop ./docs/greenfield/research/invariants/packet-e-tooling \
    --command ./docs/greenfield/research/invariants/test-packet-e-catalog.sh \
    --phase evidence --case packet-e/multiplicity-binding
  ```

- [ ] **Step 3: Implement the tranche without proof self-reference**

  Catalog semantic records may reference required proof identities but never
  contain proof terms, checked results, or coverage maturity. Proof material is
  `assurance-definition` or generated, never `catalog-semantic`.

- [ ] **Step 4: Run GREEN and one distinguishing mutation per owned field**

- [ ] **Step 5: Commit candidate; adversarially review the exact SHA; commit
  only `reviews/stage-03c.md` as acceptance evidence**

---

### Stage 03D: Coverage rules, non-denotability obligations, and full closure

**Files:**

- Create: `docs/greenfield/research/invariants/packet-e/coverage-rules.json`
- Create:
  `docs/greenfield/research/invariants/packet-e/non-denotability-proofs.json`
- Create the two same-basename schemas under `packet-e/schemas/`.
- Create:
  `docs/greenfield/research/invariants/fixtures/packet-e/catalog-closure/`
- Create: `docs/greenfield/research/invariants/reviews/stage-03d.md`
- Modify tooling inventory/registry, scope, baseline, and typed change records.

- [ ] **Step 1: Write RED closure/reference cases**

  Cases include `packet-e/reference-dangling`, `packet-e/reference-kind`,
  `packet-e/reference-revision`, `packet-e/reference-cycle`,
  `packet-e/required-unreferenced`, `packet-e/non-denotability-missing`, and
  `packet-e/catalog-exact-closure`.

- [ ] **Step 2: Run exact RED**

  ```sh
  nix develop ./docs/greenfield/research/invariants/packet-e-tooling \
    --command ./docs/greenfield/research/invariants/test-packet-e-catalog.sh \
    --phase closure --case packet-e/catalog-exact-closure
  ```

- [ ] **Step 3: Implement graph-wide exact closure**

  `non-denotability-proofs.json` is assurance-role input. Catalog semantics
  reference proof IDs and claimed inapplicability; the normalizer cannot read
  proof terms or results.

- [ ] **Step 4: Run every catalog mutation and the cumulative suite**

- [ ] **Step 5: Commit candidate; adversarially review the exact SHA; commit
  only `reviews/stage-03d.md` as acceptance evidence**

---

### Stage 04: Catalog denotation and independently checked normalization

**Files:**

- Create: `docs/greenfield/research/invariants/packet-e/catalog-denotation.json`
- Create:
  `docs/greenfield/research/invariants/packet-e/catalog-source-field-reachability.json`
- Create:
  `docs/greenfield/research/invariants/packet-e/catalog-normalization-checker.json`
- Create:
  `docs/greenfield/research/invariants/packet-e/contract-model-interpreter.json`
- Create:
  `docs/greenfield/research/invariants/packet-e/semantic-comparison-carrier.json`
- Create:
  `docs/greenfield/research/invariants/packet-e-tooling/generate-contract-model.mjs`
- Create:
  `docs/greenfield/research/invariants/packet-e-tooling/check-normalization/index.mjs`
- Create:
  `docs/greenfield/research/invariants/packet-e-tooling/check-normalization/proof-replay.mjs`
- Create:
  `docs/greenfield/research/invariants/packet-e-tooling/check-normalization/dependency-audit.mjs`
- Create:
  `docs/greenfield/research/invariants/packet-e-tooling/check-model-interpreter/index.mjs`
- Create:
  `docs/greenfield/research/invariants/packet-e-tooling/check-model-interpreter/dependency-audit.mjs`
- Create:
  `docs/greenfield/research/invariants/packet-e/generated/contract-model.json`
- Create:
  `docs/greenfield/research/invariants/packet-e/generated/normalization-proof-material.json`
- Create:
  `docs/greenfield/research/invariants/packet-e/generated/catalog-normalization-certificate.json`
- Create:
  `docs/greenfield/research/invariants/packet-e/schemas/catalog-denotation.schema.json`
- Create:
  `docs/greenfield/research/invariants/packet-e/schemas/catalog-source-field-reachability.schema.json`
- Create:
  `docs/greenfield/research/invariants/packet-e/schemas/catalog-normalization-checker.schema.json`
- Create:
  `docs/greenfield/research/invariants/packet-e/schemas/contract-model-interpreter.schema.json`
- Create:
  `docs/greenfield/research/invariants/packet-e/schemas/semantic-comparison-carrier.schema.json`
- Create:
  `docs/greenfield/research/invariants/packet-e/schemas/contract-model.schema.json`
- Create:
  `docs/greenfield/research/invariants/packet-e/schemas/normalization-proof-material.schema.json`
- Create:
  `docs/greenfield/research/invariants/packet-e/schemas/catalog-normalization-certificate.schema.json`
- Create:
  `docs/greenfield/research/invariants/test-packet-e-normalization.sh`
- Create:
  `docs/greenfield/research/invariants/fixtures/packet-e/normalization/`
- Create: `docs/greenfield/research/invariants/reviews/stage-04.md`
- Modify tooling inventory/registry, scope, baseline, and typed change records.

**Interfaces:**

- The generator consumes only an `AttestedSourceSet` with the exact catalog
  source-set digest and emits canonical model/proof bytes.
- The checker consumes catalog bytes, denotation/reachability authority, model
  bytes, and proof material; only it may emit a certificate.
- The interpreter checker establishes exact runtime-input byte identity and
  extensional equivalence over the complete `SemanticComparisonCarrier`.

- [ ] **Step 1: Write end-to-end RED normalization tests**

  Require source reorder invariance, canonical round-trip/injectivity,
  exhaustive semantic-field reachability, selector/profile preservation,
  exact source/model digests, and denotation equality.
  Exact primary cases are `packet-e/normalization-field-omitted`,
  `packet-e/normalization-selector`, `packet-e/normalization-profile`,
  `packet-e/normalization-reference`, `packet-e/normalization-import`,
  `packet-e/normalization-order`, and
  `packet-e/model-interpreter-extensional-equivalence`.

- [ ] **Step 2: Add anti-Goodhart RED mutations**

  Cover omitted/ignored source fields, constant output, self-issued
  certificate, self-hashing cycle, checker/normalizer shared import, co-drift,
  changed executable under unchanged formal denotation, lossy comparison
  adapter, runtime-byte substitution, nondeterministic may/must collapse, and
  a model field missing from the comparison carrier.

- [ ] **Step 3: Run and observe exact RED**

  ```sh
  nix develop ./docs/greenfield/research/invariants/packet-e-tooling \
    --command ./docs/greenfield/research/invariants/test-packet-e-normalization.sh \
    --case packet-e/normalization-field-omitted
  ```

  Expected RED: `packet-e/normalization-checker-unimplemented`. Expected GREEN:
  `packet-e/normalization-field-omitted`.

- [ ] **Step 4: Implement the restricted denotation and normalizer**

  Keep the semantic DSL total, versioned, and closed. Generator code is
  dependency-free and deterministic. It emits no verdict and cannot update
  committed generated files in check mode.

- [ ] **Step 5: Implement the independent checker and model interpreter**

  Build the checker in a separate module tree with a machine-audited import
  denylist. Recompute field reachability and denotation directly. This stage
  must establish full-domain normalization preservation and executable-
  interpreter extensional equivalence for the closed denotation fragment,
  including symbolic domains, using the Stage 00-proven complete checker or
  kernel path. It has no dependency on Stages 05–07. If full-domain checking
  cannot be issued here, Stage 04 is rejected and execution stops.

  Direct acceptance invocations are:

  ```sh
  nix develop ./docs/greenfield/research/invariants/packet-e-tooling \
    --command node \
    ./docs/greenfield/research/invariants/packet-e-tooling/check-normalization/dependency-audit.mjs
  nix develop ./docs/greenfield/research/invariants/packet-e-tooling \
    --command node \
    ./docs/greenfield/research/invariants/packet-e-tooling/check-normalization/index.mjs \
    --check
  nix develop ./docs/greenfield/research/invariants/packet-e-tooling \
    --command node \
    ./docs/greenfield/research/invariants/packet-e-tooling/check-model-interpreter/index.mjs \
    --check
  ```

- [ ] **Step 6: Generate committed outputs and prove reproducibility**

  ```sh
  nix develop ./docs/greenfield/research/invariants/packet-e-tooling \
    --command node \
    ./docs/greenfield/research/invariants/packet-e-tooling/generate-contract-model.mjs \
    --write
  nix develop ./docs/greenfield/research/invariants/packet-e-tooling \
    --command ./docs/greenfield/research/invariants/test-packet-e-normalization.sh
  ```

  Regeneration in two clean temporary trees must produce identical bytes.

- [ ] **Step 7: Commit the Stage 04 candidate**

- [ ] **Step 8: Run the three-role review and commit only
  `reviews/stage-04.md` as acceptance evidence**

  ```sh
  git add docs/greenfield/research/invariants/reviews/stage-04.md
  git commit -m "review: accept Packet E normalization authority"
  ```

---

### Stage 05: Proof-independent family universes and coverage-shard specs

**Files:**

- Create:
  `docs/greenfield/research/invariants/packet-e/interaction-obligations.json`
- Create:
  `docs/greenfield/research/invariants/packet-e/generated/family-instance-universes.json`
- Create:
  `docs/greenfield/research/invariants/packet-e/generated/coverage-ledger.json`
- Create:
  `docs/greenfield/research/invariants/packet-e/schemas/interaction-obligations.schema.json`
- Create:
  `docs/greenfield/research/invariants/packet-e/schemas/family-instance-universe.schema.json`
- Create:
  `docs/greenfield/research/invariants/packet-e/schemas/coverage-shard-spec.schema.json`
- Create:
  `docs/greenfield/research/invariants/packet-e/schemas/coverage-shard.schema.json`
- Create:
  `docs/greenfield/research/invariants/packet-e/schemas/coverage-ledger.schema.json`
- Create:
  `docs/greenfield/research/invariants/packet-e-tooling/generate-coverage.mjs`
- Create:
  `docs/greenfield/research/invariants/packet-e-tooling/check-interactions.mjs`
- Create:
  `docs/greenfield/research/invariants/packet-e-tooling/check-shards.mjs`
- Create:
  `docs/greenfield/research/invariants/packet-e-tooling/validate-packet-e-coverage.jq`
- Create:
  `docs/greenfield/research/invariants/test-packet-e-coverage.sh`
- Create:
  `docs/greenfield/research/invariants/fixtures/packet-e/coverage/`
- Create: `docs/greenfield/research/invariants/reviews/stage-05.md`
- Modify tooling inventory/registry, scope, baseline, and typed change records.

**Interfaces:**

- `FamilyInstanceUniverse` exact-pins participants, constructors, target/lane/
  state/capability/authority/evidence/ordering/effect facts, and foreign
  imports for each family.
- The interaction checker reconstructs all non-empty family subsets
  symbolically and validates classification without consuming recorded
  outcomes.
- The Stage 05 `coverage-ledger.json` is explicitly `proof-open`: it embeds
  proof-independent `CoverageShardSpec` records and contains no finalized
  `CoverageShard`, certificate, witness, maturity, evidence digest, or final
  Merkle-root claim.

- [ ] **Step 1: Write RED universe/coverage tests**

  Assert exact axes, projections, cell formulas, applicability commitments,
  `19` families, `524287` non-empty subsets, retained singletons, both directed
  Packet E/Packet A interactions, Packet E self-pairs, and aggregate
  populations.

- [ ] **Step 2: Write RED shard/cardinality mutations**

  Delete a constructor, foreign participant, fact, axis, singleton, tuple, or
  shard interval; introduce overlap, cap an unbounded population, corrupt a
  formula/Merkle root, change only an unwitnessed symbolic region, merge
  semantically different populations, or make resource pressure shrink scope.

- [ ] **Step 3: Run exact RED**

  ```sh
  nix develop ./docs/greenfield/research/invariants/packet-e-tooling \
    --command ./docs/greenfield/research/invariants/test-packet-e-coverage.sh \
    --case packet-e/interaction-powerset-cardinality
  ```

  Expected RED: `packet-e/coverage-spec-unimplemented`. Expected GREEN:
  `packet-e/interaction-powerset-cardinality`.

- [ ] **Step 4: Implement independent universe and coverage derivations**

  Universe, coordinates, family algebra, candidate subsets, applicability,
  shard partitions, and expected counts derive only from the scope manifest,
  independently authored family-universe inputs, pinned formula vocabulary,
  interaction obligations, and pinned imports. The catalog/model is
  inaccessible while those structures are built. Only after the complete
  coordinate universe is frozen may a separate comparison phase read the
  certified model to compute its side of the carrier relation. Add an import/
  access audit that kills any catalog/model read during universe,
  applicability, partition, or cardinality construction. Do not enumerate the
  complete powerset.

- [ ] **Step 5: Implement deterministic bounded expansion**

  For every symbolic spec, compare independently generated bounded expansions
  as sanity evidence only. Do not claim they prove universal disjointness,
  exhaustiveness, or cardinality. Specs precede certificates and finalized
  shards to avoid content-addressing cycles.

- [ ] **Step 6: Run GREEN and cumulative suite**

- [ ] **Step 7: Commit the Stage 05 candidate**

- [ ] **Step 8: Run the three-role review and commit only
  `reviews/stage-05.md` as acceptance evidence**

  ```sh
  git add docs/greenfield/research/invariants/reviews/stage-05.md
  git commit -m "review: accept Packet E proof-independent coverage specs"
  ```

---

### Stage 06: Independent transition oracle and structural agreement

**Files:**

- Create:
  `docs/greenfield/research/invariants/packet-e/transition-oracle-vocabulary.json`
- Create:
  `docs/greenfield/research/invariants/packet-e/transition-oracle-rules.json`
- Create:
  `docs/greenfield/research/invariants/packet-e/witnesses/positive.json`
- Create:
  `docs/greenfield/research/invariants/packet-e/witnesses/negative.json`
- Create:
  `docs/greenfield/research/invariants/packet-e/witnesses/delegated.json`
- Create:
  `docs/greenfield/research/invariants/packet-e/schemas/transition-oracle-vocabulary.schema.json`
- Create:
  `docs/greenfield/research/invariants/packet-e/schemas/transition-oracle-rules.schema.json`
- Create:
  `docs/greenfield/research/invariants/packet-e/schemas/witnesses.schema.json`
- Create:
  `docs/greenfield/research/invariants/packet-e-tooling/transition-oracle.mjs`
- Create:
  `docs/greenfield/research/invariants/packet-e-tooling/packet-e.cue`
- Create:
  `docs/greenfield/research/invariants/packet-e-tooling/validate-packet-e-ledger.jq`
- Create:
  `docs/greenfield/research/invariants/packet-e-tooling/check-partitions.mjs`
- Create:
  `docs/greenfield/research/invariants/test-packet-e-oracles.sh`
- Create:
  `docs/greenfield/research/invariants/fixtures/packet-e/oracles/`
- Create: `docs/greenfield/research/invariants/reviews/stage-06.md`
- Modify tooling inventory/registry, scope, baseline, and typed change records.

**Interfaces:**

- The oracle consumes only separately pinned vocabulary, exogenous assumptions,
  authored rules, and candidate coordinates. It cannot import catalog/model/
  ledger expected outcomes.
- Stage 06 freezes exact oracle bytes/digests before any universal oracle-
  equivalence proof is authored.

- [ ] **Step 1: Write RED independence and structural-agreement tests**

  Detect imports of expected outcomes, catalog-derived bridge lemmas,
  coordinate/result tag permutations, lossy adapters, constant carriers,
  selector gaps/overlaps, applicability laundering, classifier drift,
  directional-pair reversal, missing self-pairs, and catalog/oracle co-drift.

- [ ] **Step 2: Run exact RED**

  ```sh
  nix develop ./docs/greenfield/research/invariants/packet-e-tooling \
    --command ./docs/greenfield/research/invariants/test-packet-e-oracles.sh \
    --case packet-e/oracle-expected-outcome-import
  ```

  Expected RED: `packet-e/oracle-unimplemented`. Expected GREEN:
  `packet-e/oracle-expected-outcome-import`.

- [ ] **Step 3: Implement and freeze the independent oracle**

  Encode enabledness, admission, ordered gates, may/must next-state relation,
  outcomes, postconditions, evidence, ordering, effects, and non-denotability.
  Replay positive/negative/delegated witnesses without reading recorded
  outcomes. Freeze vocabulary/rules/assumption input digests before Stage 07.

- [ ] **Step 4: Implement `jq`, CUE, partition, and interaction checks**

  Each mechanism reconstructs the exact sets it can check. Record universal
  proof obligations as open for Stage 07 rather than laundering finite
  agreement into proof.

- [ ] **Step 5: Run GREEN and freeze canonical oracle bytes**

- [ ] **Step 6: Commit candidate; adversarially review the exact SHA; commit
  only `reviews/stage-06.md` as acceptance evidence**

---

### Stage 07A: Lean premise, dependency, and axiom closure

**Files:**

- Create:
  `docs/greenfield/research/invariants/packet-e/proof-assumption-sets.json`
- Create:
  `docs/greenfield/research/invariants/packet-e/parameterized-proof-certificates.json`
- Create:
  `docs/greenfield/research/invariants/packet-e/proofs/lean/lakefile.toml`
- Create:
  `docs/greenfield/research/invariants/packet-e/proofs/lean/lean-toolchain`
- Create:
  `docs/greenfield/research/invariants/packet-e/proofs/lean/PacketE/Authority.lean`
- Create:
  `docs/greenfield/research/invariants/packet-e/proofs/lean/Main.lean`
- Create:
  `docs/greenfield/research/invariants/packet-e/schemas/proof-assumption-sets.schema.json`
- Create:
  `docs/greenfield/research/invariants/packet-e/schemas/parameterized-proof-certificates.schema.json`
- Create:
  `docs/greenfield/research/invariants/packet-e-tooling/check-lean-closure.mjs`
- Create:
  `docs/greenfield/research/invariants/test-packet-e-proofs.sh`
- Create:
  `docs/greenfield/research/invariants/fixtures/packet-e/proof-closure/`
- Create: `docs/greenfield/research/invariants/reviews/stage-07a.md`
- Modify tooling inventory/registry, scope, baseline, and typed change records.

- [ ] **Step 1: Write exact RED interface-smuggling cases**

  Include every Stage 00 smuggling class plus partial application, unresolved
  premise, third-party transitive axiom, unpinned import, conclusion-as-
  assumption, generated-outcome premise, catalog-derived bridge lemma, and
  tainted transitive lemma. Also include a contradictory assumption pair,
  domain-shrinking assumption, excluded positive/negative/ambiguity/crash/
  boundary witness, cyclic assumption dependency, stale authority,
  solver `unknown`/timeout, unused declared assumption, and omitted transitive
  dependency-manifest entry. Add
  `packet-e/oracle-assumption-model-predicate` where an otherwise valid
  `ContractModel` predicate is smuggled into a `transition-oracle` or
  `oracle-equivalence` assumption set.

- [ ] **Step 2: Run exact RED**

  ```sh
  nix develop ./docs/greenfield/research/invariants/packet-e-tooling \
    --command ./docs/greenfield/research/invariants/test-packet-e-proofs.sh \
    --phase closure --case packet-e/proof-hidden-subtype-premise
  ```

  Expected RED: `packet-e/proof-closure-unimplemented`. Expected GREEN:
  `packet-e/proof-hidden-subtype-premise`.

- [ ] **Step 3: Implement elaborated-interface and transitive closure audit**

  For every elaborated free proposition, require exact declared-set membership
  and an independent entailment certificate from a named authoritative
  `ContractModel` predicate or pinned foreign specification import. Traverse
  every imported lemma and axiom. Reject a proposition if it contains or
  entails the theorem conclusion, depends on generated outcomes, or is
  dynamically derived from ledger/oracle results. For oracle-equivalence
  certificates, every assumption is exogenous/foreign-only: the model relation
  is a theorem operand, never a source of a bridge assumption, and catalog/
  model/ledger/witness outcomes cannot entail an oracle premise.
  Purpose-specific validation rejects every catalog/model-derived assumption
  or transitive lemma for both `transition-oracle` and `oracle-equivalence`,
  even when that proposition is authoritative for another proof purpose.
  Independently check one joint-satisfiability witness for the complete
  assumption set, exact preservation of the full `PacketEScopeManifest`
  domain, denotability/preservation of every assigned positive, negative,
  ambiguity, crash, and boundary witness, and acyclicity of the assumption
  dependency graph. Require bidirectional set equality—including canonical
  elaborated proposition identity and type—between declared assumptions and
  the complete elaborated interface; unused declarations and undeclared
  propositions both fail.

- [ ] **Step 4: Bind exact JSON/translation bytes and audit `#print axioms`**

  Independently reconstruct the complete transitive certificate-dependency
  manifest from the candidate tuple and checked proof term and require exact
  set equality with the declaration. A subset, stale authority, unresolved
  dependency, solver `unknown`, or timeout fails closed.

- [ ] **Step 5: Commit candidate; adversarially review the exact SHA; commit
  only `reviews/stage-07a.md` as acceptance evidence**

---

### Stage 07B: Population, composition, partition, and cardinality proofs

**Files:**

- Create:
  `docs/greenfield/research/invariants/packet-e/proofs/lean/PacketE/Population.lean`
- Create:
  `docs/greenfield/research/invariants/packet-e/proofs/lean/PacketE/Partitions.lean`
- Create:
  `docs/greenfield/research/invariants/fixtures/packet-e/proof-population/`
- Create: `docs/greenfield/research/invariants/reviews/stage-07b.md`
- Modify certificates, baseline, and typed assurance records.

- [ ] **Step 1: Write RED universal obligations**

  Require domain equality/totality, permutation, complete-carrier congruence,
  forward/backward simulation, scalar/multi-index induction, mixed-increment
  commutation, contextual composition, classifier exactly-one, applicability
  partitioning, symbolic shard disjointness/exhaustiveness, and cardinality.

- [ ] **Step 2: Run exact RED**

  ```sh
  nix develop ./docs/greenfield/research/invariants/packet-e-tooling \
    --command ./docs/greenfield/research/invariants/test-packet-e-proofs.sh \
    --phase population --case packet-e/proof-mixed-increment
  ```

- [ ] **Step 3: Prove universal properties with structural
  induction/symmetry**

  Bounded expansions remain sanity checks. Fail closed on unsupported theory
  or solver unknown.

- [ ] **Step 4: Commit candidate; adversarially review the exact SHA; commit
  only `reviews/stage-07b.md` as acceptance evidence**

---

### Stage 07C: Universal model/oracle equivalence and finalized shards

**Files:**

- Create:
  `docs/greenfield/research/invariants/packet-e/proofs/lean/PacketE/Equivalence.lean`
- Modify:
  `docs/greenfield/research/invariants/packet-e/generated/coverage-ledger.json`
- Create:
  `docs/greenfield/research/invariants/fixtures/packet-e/proof-equivalence/`
- Create: `docs/greenfield/research/invariants/reviews/stage-07c.md`
- Modify certificates, baseline, tooling inventory, and typed assurance records.

- [ ] **Step 1: Write RED complete-carrier equivalence cases**

  Bind exact certified model bytes, frozen oracle vocabulary/rules/assumptions,
  and each exact `CoverageShardSpec`. Require universal
  ledger-to-model and model-to-oracle equality over every
  `SemanticComparisonCarrier` field.

- [ ] **Step 2: Run exact RED**

  ```sh
  nix develop ./docs/greenfield/research/invariants/packet-e-tooling \
    --command ./docs/greenfield/research/invariants/test-packet-e-proofs.sh \
    --phase equivalence --case packet-e/proof-comparison-field-omitted
  ```

- [ ] **Step 3: Prove equivalence and finalize coverage shards**

  Each canonical `CoverageShard` binds its proof-independent spec digest,
  witness IDs/digests, certificate IDs/digests, maturity, and evidence digest
  without copying the replaceable semantic formula. Recompute the coverage
  ledger and Merkle root over finalized shard bytes only. Reject any
  certificate/finalized-shard content cycle.

- [ ] **Step 4: Run Lean, oracle, `jq`, CUE, interaction, shard, and mutation
  agreement**

- [ ] **Step 5: Commit candidate; adversarially review the exact SHA; commit
  only `reviews/stage-07c.md` as acceptance evidence**

---

### Stage 08: Foreign trust imports and verification-decoder boundary

**Files:**

- Create:
  `docs/greenfield/research/invariants/packet-e/backend-semantic-trial-sets.json`
- Create:
  `docs/greenfield/research/invariants/packet-e/backend-conformance-evaluators.json`
- Create:
  `docs/greenfield/research/invariants/packet-e/verification-decoder-artifacts.json`
- Create:
  `docs/greenfield/research/invariants/packet-e/conformance-evidence-trust-policies.json`
- Create:
  `docs/greenfield/research/invariants/packet-e/packet-c-conformance-protocol-imports.json`
- Create:
  `docs/greenfield/research/invariants/packet-e/packet-c-backend-report-imports.json`
- Create:
  `docs/greenfield/research/invariants/packet-e/packet-c-support-evidence-log-imports.json`
- Create:
  `docs/greenfield/research/invariants/packet-e/packet-f-measurement-acquisition-trust-imports.json`
- Create:
  `docs/greenfield/research/invariants/packet-e/packet-f-evidence-attestation-trust-imports.json`
- Create:
  `docs/greenfield/research/invariants/packet-e-tooling/validate-packet-e-trust.jq`
- Create:
  `docs/greenfield/research/invariants/test-packet-e-trust.sh`
- Create:
  `docs/greenfield/research/invariants/fixtures/packet-e/test-trust/`
- Create: `docs/greenfield/research/invariants/reviews/stage-08.md`
- Create same-basename closed schemas for every Stage 08 JSON source.
- Modify tooling inventory/registry, scope, baseline, and typed change records.

**Interfaces:**

- `--level structure` validates closed import definitions and reports the exact
  unresolved required specification imports.
- `--level gate-2a` requires every static Packet A/B/C/F specification import
  to resolve to exact ID/revision/digest and fails otherwise.
- `--level operational` additionally requires real key/issuer/failure-domain/
  validity/revocation and current operational evidence, and rejects every
  synthetic trust root.

- [ ] **Step 1: Write RED inventory/closure tests**

  Cover foreign revision/digest drift, self-asserted Packet C measurement,
  Packet-C-controlled evaluator/decoder, issuer/artifact mismatch, revoked or
  ambiguously valid keys, non-independent issuers, replayed nonce/coordinate,
  synthetic key leakage, unresolved required specification imports at
  `gate-2a`, and missing real operational imports at `operational`.

- [ ] **Step 2: Run exact RED**

  ```sh
  nix develop ./docs/greenfield/research/invariants/packet-e-tooling \
    --command ./docs/greenfield/research/invariants/test-packet-e-trust.sh \
    --level structure --case packet-e/import-revision-drift
  ```

- [ ] **Step 3: Author trust/import envelopes**

  Separate `required-specification` imports from `operational-evidence`
  imports machine-readably. Resolve every available static import against the
  exact foreign bytes. Mark unavailable Packet C/F specification imports
  explicitly Gate-2A-blocking; mark absent live measurements/logs/reports
  Gate-4B-blocking. Do not fabricate either class.

- [ ] **Step 4: Implement trust validation and decoder compatibility checks**

  Bind source/build/executable decoder identity and compatibility certificate.
  Require measurement acquisition and decoding/attestation trust to remain
  separate policies and failure domains.

- [ ] **Step 5: Run all three levels with exact expected disposition**

  `structure` must pass. `gate-2a` passes only if all static specification
  imports resolve; otherwise the test asserts its exact unresolved set.
  `operational` remains open until real foreign operational artifacts exist.

- [ ] **Step 6: Commit the Stage 08 candidate**

- [ ] **Step 7: Run the three-role review and commit only
  `reviews/stage-08.md` as acceptance evidence**

  ```sh
  git add docs/greenfield/research/invariants/reviews/stage-08.md
  git commit -m "review: accept Packet E conformance trust boundaries"
  ```

---

### Stage 09: Normalized observation and evaluation envelopes

**Files:**

- Create:
  `docs/greenfield/research/invariants/packet-e/schemas/backend-normalized-observation.schema.json`
- Create:
  `docs/greenfield/research/invariants/packet-e/schemas/backend-conformance-evaluation.schema.json`
- Create:
  `docs/greenfield/research/invariants/packet-e-tooling/validate-evaluation.mjs`
- Create:
  `docs/greenfield/research/invariants/packet-e-tooling/reference/protected_store_fixture.mjs`
- Create:
  `docs/greenfield/research/invariants/packet-e-tooling/reference/verification_decoder_fixture.mjs`
- Create:
  `docs/greenfield/research/invariants/packet-e-tooling/verify-decoder-attestation.mjs`
- Create:
  `docs/greenfield/research/invariants/test-packet-e-evaluation.sh`
- Create:
  `docs/greenfield/research/invariants/fixtures/packet-e/evaluation/`
- Create: `docs/greenfield/research/invariants/reviews/stage-09.md`
- Modify tooling inventory/registry, scope, baseline, and typed change records.

**Interfaces:**

- Consumes: imported measurement summary, authenticated raw/payload
  correlations, decoder attestation, evaluator identity, trial coordinate, and
  freshness data.
- Produces: deterministic provider-neutral evaluation bytes. It does not own a
  full Packet C/F measurement schema.

- [ ] **Step 1: Write RED provenance/evaluation tests**

  Reject mismatched raw/payload digest, harness artifact, realized seed,
  schedule, fault point, environment bound, repetition, backend/profile/
  version/trial, decoder, issuer, nonce, validity, revocation, or evaluator.
  Reject failed/inconclusive omission and nondeterministic evaluation.

- [ ] **Step 2: Write RED mode-path tests**

  `direct-recompute` must retrieve fixture raw bytes through a least-privilege,
  audited protected-store adapter, verify the raw digest, run the exact pinned
  decoder executable, and compare canonical normalized bytes.
  `attested-decode` must cryptographically verify a real Ed25519 test signature
  over the complete canonical decoder/provenance transcript under the pinned
  synthetic test policy. An unresolved opaque reference cannot pass either
  mode. Include cross-coordinate, cross-decoder, cross-nonce, revoked-key, and
  algorithm-confusion mutations.

- [ ] **Step 3: Run exact RED**

  ```sh
  nix develop ./docs/greenfield/research/invariants/packet-e-tooling \
    --command ./docs/greenfield/research/invariants/test-packet-e-evaluation.sh \
    --mode direct-recompute --case packet-e/raw-reference-unresolvable
  ```

  Expected RED: `packet-e/evaluation-mode-unimplemented`. Expected GREEN:
  `packet-e/raw-reference-unresolvable`.

- [ ] **Step 4: Implement the closed envelopes and deterministic evaluator**

  Imported summaries route to one of the two verified provenance paths; they
  are never sufficient by themselves. Prevent Packet E tooling from logging
  raw evidence. Bind every result to exact semantic model, trial/evaluator,
  acquisition, decoder, protocol, realized-coordinate, payload, and freshness
  identities.

- [ ] **Step 5: Run GREEN for both modes and the secret-safety scan**

- [ ] **Step 6: Commit the Stage 09 candidate**

- [ ] **Step 7: Run the three-role review and commit only
  `reviews/stage-09.md` as acceptance evidence**

  ```sh
  git add docs/greenfield/research/invariants/reviews/stage-09.md
  git commit -m "review: accept Packet E normalized evidence validation"
  ```

---

### Stage 10: EvaluationSlot attempts and process-crash-atomic reference store

**Files:**

- Create:
  `docs/greenfield/research/invariants/packet-e/schemas/evaluation-slot.schema.json`
- Create:
  `docs/greenfield/research/invariants/packet-e/schemas/evaluation-attempt-coordinate.schema.json`
- Create:
  `docs/greenfield/research/invariants/packet-e/schemas/evaluation-attempt-state.schema.json`
- Create:
  `docs/greenfield/research/invariants/packet-e/schemas/slot-evaluation.schema.json`
- Create:
  `docs/greenfield/research/invariants/packet-e/schemas/evaluation-evidence-log-entry.schema.json`
- Create:
  `docs/greenfield/research/invariants/packet-e-tooling/reference/evidence_store/model.py`
- Create:
  `docs/greenfield/research/invariants/packet-e-tooling/reference/evidence_store/sqlite_store.py`
- Create:
  `docs/greenfield/research/invariants/packet-e-tooling/reference/evidence_store/crash_driver.py`
- Create:
  `docs/greenfield/research/invariants/test-packet-e-attempt-state.sh`
- Create:
  `docs/greenfield/research/invariants/fixtures/packet-e/attempt-state/`
- Create: `docs/greenfield/research/invariants/reviews/stage-10.md`
- Modify tooling inventory/registry, scope, baseline, and typed change records.

**Interfaces:**

- The pure transition model is an independently authored executable reference,
  not normative semantics. It consumes the exact certified `ContractModel`
  bytes and pinned interpreter identity and rejects any mismatch. SQLite must
  refine it for reserve, bind, complete, retry/takeover, conflict, and
  resolution.
- Slot identity excludes realized retry-selected nonce/time/seed values. Every
  attempt and slot-head mutation uses predecessor-bound CAS.

- [ ] **Step 1: Write RED pure-model state tests**

  Cover the legal reserved → measurement-bound → completed path and every
  fail-closed state. Reject phase skip, stale predecessor, nonterminal retry,
  invalid lease takeover, missing successor, incomplete aggregate, slot-
  selection by retry nonce/time, and cyclic `SlotEvaluation` preimages.

- [ ] **Step 2: Write RED SQLite refinement/crash tests**

  Exact injectable subprocess fault points are `before-begin`,
  `after-log-insert`, `after-attempt-cas`, `after-slot-head-cas`,
  `after-each-conflict-attempt-cas`, `before-commit`, and
  `after-commit-before-reply`. At each point, race non-equivalent successors,
  kill the process, reopen, and compare the complete observable store to the
  pure predecessor or successor. Conflict resolution must atomically CAS all
  affected attempts and the slot head in one transaction. Add
  `packet-e/reference-model-drift` by changing certified model bytes or
  interpreter identity.

- [ ] **Step 3: Run exact RED**

  ```sh
  nix develop ./docs/greenfield/research/invariants/packet-e-tooling \
    --command ./docs/greenfield/research/invariants/test-packet-e-attempt-state.sh \
    --fault-point after-attempt-cas --case packet-e/partial-state
  ```

- [ ] **Step 4: Implement the pure model**

  Define total transitions and stable diagnostics first. Keep wall-clock and
  randomness as explicit inputs. Terminality, retryability, takeover, and
  conflict resolution are distinct typed decisions.

- [ ] **Step 5: Implement and refine the SQLite store**

  Enable and assert effective `journal_mode=WAL`, `synchronous=FULL`,
  `foreign_keys=ON`, and the pinned checkpoint policy. Record SQLite version
  and local-filesystem assumptions. Store canonical bytes and digests, not
  reconstructed mutable objects. Revalidate predecessor and all affected
  states inside the transaction. The claim is transaction atomicity under
  process termination; it excludes power loss, kernel/filesystem/device
  failure, short write, `ENOSPC`, and I/O error.

- [ ] **Step 6: Run GREEN, race, and crash matrix**

  Run multiple deterministic process schedules and randomized schedules with
  recorded seeds. A randomized pass supplements but never replaces the exact
  boundary matrix.

- [ ] **Step 7: Commit the Stage 10 candidate**

- [ ] **Step 8: Run the three-role review and commit only
  `reviews/stage-10.md` as acceptance evidence**

  ```sh
  git add docs/greenfield/research/invariants/reviews/stage-10.md
  git commit -m "review: accept Packet E attempt reference model"
  ```

---

### Stage 11: Witnessed append-only logs, quorum, and rotation

**Files:**

- Create:
  `docs/greenfield/research/invariants/packet-e/schemas/evaluation-evidence-checkpoint.schema.json`
- Create:
  `docs/greenfield/research/invariants/packet-e/schemas/support-evidence-log-entry.schema.json`
- Create:
  `docs/greenfield/research/invariants/packet-e/schemas/support-evidence-checkpoint.schema.json`
- Create:
  `docs/greenfield/research/invariants/packet-e/schemas/quorum-publication-receipt.schema.json`
- Create:
  `docs/greenfield/research/invariants/packet-e/schemas/witness-set-transition.schema.json`
- Create:
  `docs/greenfield/research/invariants/packet-e-tooling/reference/evidence_store/witnessed_log.py`
- Create:
  `docs/greenfield/research/invariants/packet-e-tooling/reference/evidence_store/witness_state.py`
- Create:
  `docs/greenfield/research/invariants/packet-e-tooling/validate-witnessed-logs.mjs`
- Create:
  `docs/greenfield/research/invariants/test-packet-e-witnessed-logs.sh`
- Create:
  `docs/greenfield/research/invariants/fixtures/packet-e/witnessed-logs/`
- Create: `docs/greenfield/research/invariants/reviews/stage-11.md`
- Modify tooling inventory/registry, scope, baseline, and typed change records.

**Interfaces:**

- Log-entry/checkpoint Merkle preimages exclude the receipt/signature that
  attests them.
- Publication requires threshold plus failure-domain independence and policy-
  epoch validity.
- A policy declares Byzantine bound `f`, effective distinct-domain population
  `n`, and effective-domain threshold `k`. Validation requires
  `n >= 3f + 1`, `k >= 2f + 1`, `k <= n`, and minimum two-quorum intersection
  `2k - n > f`. Identities are collapsed through the pinned identity-to-domain
  mapping before computing `n`, `k`, or intersection.
- Rotation requires continuous old/new quorum handoff. External recovery
  invalidates prior support and requires remeasurement.

- [ ] **Step 1: Write RED log/quorum tests**

  Cover extension/inclusion, issuer-only checkpoint, partial quorum, duplicate
  operator counted twice, non-intersecting quorum configuration, rollback,
  equivocation, stale head, withheld newer checkpoint, receipt/root cycle,
  wrong-entry receipt, invalid time/revocation, lease mutation without log
  extension, stale takeover proof, algorithm confusion, key substitution,
  cross-log, cross-coordinate, and cross-epoch replay. Mutate every signed
  field independently.
  Exact arithmetic RED cases include `n=3,f=1,k=2`, identity-rich/domain-poor
  sets, `k>n`, `n<3f+1`, `k<2f+1`, `2k-n<=f`, and old/new rotation where
  either policy violates a formula. Both old and new policies must be
  independently safe, and the handoff must be co-signed by valid quorums under
  both exact policies before activation.

- [ ] **Step 2: Write RED rotation/recovery tests**

  Reject rotation without old/new co-signature, stale-prefix initialization,
  missing policy epoch, expired handoff, old witness acceptance after handoff,
  and external recovery that preserves old current support.

- [ ] **Step 3: Write RED durable witness crash tests**

  Run each witness in a separate process with a separate SQLite file and pinned
  identity-to-failure-domain policy. Kill before/after witness last-signed-state
  commit, signature release, each receipt signature collection, receipt
  assembly, old/new handoff commit, and new-witness initialization of both log
  heads. Lost or corrupt anti-equivocation state makes that witness
  unavailable; no signer reconstructs it from a caller-supplied head.

- [ ] **Step 4: Run exact RED**

  ```sh
  nix develop ./docs/greenfield/research/invariants/packet-e-tooling \
    --command ./docs/greenfield/research/invariants/test-packet-e-witnessed-logs.sh \
    --fault-point after-witness-state-commit-before-signature \
    --case packet-e/witness-equivocation
  ```

- [ ] **Step 5: Implement log verification and durable witness transitions**

  Keep quorum receipts separate from Merkle entries. Define one closed,
  canonical, domain-separated signature preimage nested in the receipt schema:
  protocol coordinate, log ID, entry/checkpoint identity, size/root, prior
  witnessed checkpoint, slot-head/pending-set digest where applicable, nonce,
  observation time, max-age, policy epoch, trust-policy ID/digest, signature
  suite, key ID, and witness identity. Verify real Ed25519 fixture signatures.
  Derive failure domain from the pinned policy mapping, never receipt input.
  Persist signer anti-equivocation state before releasing a signature.

- [ ] **Step 6: Run GREEN and adversarial schedule/crash matrix**

- [ ] **Step 7: Commit the Stage 11 candidate**

- [ ] **Step 8: Run the three-role review and commit only
  `reviews/stage-11.md` as acceptance evidence**

  ```sh
  git add docs/greenfield/research/invariants/reviews/stage-11.md
  git commit -m "review: accept Packet E witnessed log model"
  ```

---

### Stage 12: Reports, anti-rollback bootstrap, and current support

**Files:**

- Create:
  `docs/greenfield/research/invariants/packet-e/schemas/current-support-evidence-view.schema.json`
- Create:
  `docs/greenfield/research/invariants/packet-e-tooling/validate-current-view.mjs`
- Create:
  `docs/greenfield/research/invariants/packet-e-tooling/reference/evidence_store/verifier_state.py`
- Create:
  `docs/greenfield/research/invariants/test-packet-e-current-view.sh`
- Create:
  `docs/greenfield/research/invariants/fixtures/packet-e/current-view/`
- Create: `docs/greenfield/research/invariants/reviews/stage-12.md`
- Modify tooling inventory/registry, scope, baseline, and typed change records.

**Interfaces:**

- Exact join:
  trials → slots/attempts → evaluation checkpoint → backend report → support
  checkpoint → current view.
- A newer pending/completed evaluation not covered by the selected report makes
  the view non-current.

- [ ] **Step 1: Write RED exact-join/currentness tests**

  Reject missing/inconclusive/failed evaluation suppression, incomplete
  repetitions, pending/conflicted slot, nonterminal attempt, non-latest
  evaluation checkpoint, report/checkpoint mismatch, stale/expired/revoked
  report, forked support head, and omitted newer evaluation.

- [ ] **Step 2: Write RED bootstrap/anti-rollback tests**

  On empty or lost local state require a fresh nonce-bound witness quorum and
  consistency from pinned genesis. Reject old valid prefixes, competing or
  incomparable heads, ambiguous maxima, stale time, and rollback from the
  durably persisted last-seen checkpoint.

- [ ] **Step 3: Write RED durable verifier/rotation crash tests**

  Extend the crash driver with exact kill points before/after atomic persistence
  of Evaluation head, Support head, exact successor trust-policy ID/revision/
  digest, witness-set ID/digest, witness-set-transition ID/digest, policy
  epoch, last-seen time, and success return; and before/after new-witness
  initialization of both heads and durable handoff fencing. A partial dual-log/
  policy/witness transition update, stale returned success, or new quorum
  activated before durable handoff must fail.

- [ ] **Step 4: Run exact RED**

  ```sh
  nix develop ./docs/greenfield/research/invariants/packet-e-tooling \
    --command ./docs/greenfield/research/invariants/test-packet-e-current-view.sh \
    --fault-point after-evaluation-head-before-support-head \
    --case packet-e/verifier-partial-head-state
  ```

- [ ] **Step 5: Implement fail-closed current-view and durable verifier state**

  Derive, never author, `CurrentSupportEvidenceView`. Persist accepted
  checkpoints, successor policy identity/digest, witness-set identity/digest,
  transition identity/digest, and epoch in one atomic successor before
  accepting the view. The review baseline must bind the accepted policy,
  witness set, and transition schemas/identities. Use deterministic maximum
  selection only for mutually consistent chains; forks fail closed.

- [ ] **Step 6: Run GREEN and cross-log/crash mutation suite**

- [ ] **Step 7: Commit the Stage 12 candidate**

- [ ] **Step 8: Run the three-role review and commit only
  `reviews/stage-12.md` as acceptance evidence**

  ```sh
  git add docs/greenfield/research/invariants/reviews/stage-12.md
  git commit -m "review: accept Packet E current support derivation"
  ```

---

### Stage 13: Change-control audit, mutation ownership, and diagnostics

**Files:**

- Modify:
  `docs/greenfield/research/invariants/packet-e/review-baseline.json`
- Modify:
  `docs/greenfield/research/invariants/packet-e/semantic-change-records.json`
- Modify:
  `docs/greenfield/research/invariants/packet-e/assurance-change-records.json`
- Modify: `docs/greenfield/research/invariants/packet-e/explanations.json`
- Create:
  `docs/greenfield/research/invariants/packet-e-tooling/mutation-ownership.json`
- Create:
  `docs/greenfield/research/invariants/packet-e/generated/review-summary.json`
- Create:
  `docs/greenfield/research/invariants/packet-e/schemas/review-summary.schema.json`
- Create:
  `docs/greenfield/research/invariants/packet-e-tooling/check-review-baseline.mjs`
- Create:
  `docs/greenfield/research/invariants/packet-e-tooling/check-diagnostics.mjs`
- Create:
  `docs/greenfield/research/invariants/test-packet-e-change-control.sh`
- Create:
  `docs/greenfield/research/invariants/test-packet-e-security-mutations.sh`
- Create:
  `docs/greenfield/research/invariants/fixtures/packet-e/change-control/`
- Create: `docs/greenfield/research/invariants/reviews/stage-13.md`
- Modify tooling inventory/registry, scope, baseline, and typed change records.

**Interfaces:**

- The baseline pins stable semantic/assurance identities and derivation
  digests, never dynamic measurements, entries, checkpoints, reports, or
  current views.
- Relation-changing edits require `SemanticChangeRecord`; checker/trust/proof/
  schema changes require `AssuranceChangeRecord`; some edits require both.

- [ ] **Step 1: Write RED change-control tests**

  Mutate semantic bytes, denotation, normalizer, checker, interpreter,
  reachability, proof, oracle, trial set, evaluator, decoder, trust policy,
  witness set, schema, imported revision, applicability commitment, and
  generated ledger. Require the correct typed change record and reject
  restamped digests without reviewed intent.

- [ ] **Step 2: Write RED diagnostic-safety tests**

  Require stable diagnostic ID, primary semantic path, related paths,
  authority phase, non-secret explanation, remediation, and Packet F
  disclosure class. Inject credentials, provider payloads, host paths, and
  stack traces and prove they cannot appear.

- [ ] **Step 3: Run exact RED**

  ```sh
  nix develop ./docs/greenfield/research/invariants/packet-e-tooling \
    --command ./docs/greenfield/research/invariants/test-packet-e-change-control.sh \
    --case packet-e/semantic-change-record-missing
  nix develop ./docs/greenfield/research/invariants/packet-e-tooling \
    --command ./docs/greenfield/research/invariants/test-packet-e-security-mutations.sh \
    --case packet-e/diagnostic-secret-leak
  ```

- [ ] **Step 4: Audit the already-active baseline/change validation**

  Replay every predecessor-bound change from the Stage 02 genesis through the
  current baseline. Separate semantic relation changes from assurance
  implementation changes. Verify the exact source/model/proof/tool/import
  dependency graph rather than trusting a coordinated digest update. A stage
  without its contemporaneous required record must already have failed; Stage
  13 tests that this protection was continuous, not retrofitted.

- [ ] **Step 5: Generate and validate the mutation ownership ledger**

  Every locked-design mutation has exactly one earliest owner. Every owner has
  a real executable test and stable diagnostic; later duplicate defenses are
  labeled defense-in-depth.

- [ ] **Step 6: Run GREEN and whole-tree secret/path scan**

- [ ] **Step 7: Commit the Stage 13 candidate**

- [ ] **Step 8: Run the three-role review and commit only
  `reviews/stage-13.md` as acceptance evidence**

  ```sh
  git add docs/greenfield/research/invariants/reviews/stage-13.md
  git commit -m "review: accept Packet E change-control audit"
  ```

---

### Stage 14: Standalone inventory integration and Gate 2A decision

**Files:**

- Create:
  `docs/greenfield/research/invariants/check-packet-e-inventory.sh`
- Create:
  `docs/greenfield/research/invariants/test-packet-e-levels.sh`
- Create: `tests/standalone-packet-e-inventory.sh`
- Modify: `docs/greenfield/research/invariants/check-inventory.sh`
- Modify: `docs/greenfield/research/invariants/INVENTORY-REVIEW.md`
- Modify: `README.md`
- Create: `docs/greenfield/research/invariants/reviews/stage-14.md`

**Interfaces:**

- `check-packet-e-inventory.sh structure` proves structural validity and emits
  the exact unresolved static-import set; Gate 2A may remain open.
- `check-packet-e-inventory.sh gate-2a` requires every static Packet A/B/C/F
  specification import to resolve exactly.
- `check-packet-e-inventory.sh operational` additionally requires approved
  external stores and real current Packet C/F operational evidence.
- The repository's default inventory check invokes `structure` and, when the
  static import set is complete, also requires `gate-2a`.

- [ ] **Step 1: Write the standalone RED test**

  Copy exactly the union of source-, tool-, and test-inventory entries and
  scope-owned sources to a clean temporary tree. This includes manifest-
  enumerated invalid fixtures and test runners without treating them as
  accepted semantic sources. Exclude `.git`, caches, the old TypeSpec
  prototype, and every unlisted repository file. Expect the runner to fail
  before integration exists.

- [ ] **Step 2: Integrate the ordered full harness**

  Order:

  1. toolchain and raw-byte preflight;
  2. exact source/schema authority;
  3. catalog and reference closure;
  4. normalization certificate/model interpreter;
  5. coverage/family/interaction/shard checks;
  6. Lean kernel and assumption closure;
  7. `jq`, CUE, partition, transition-oracle agreement;
  8. trust/import validation;
  9. evaluation/state/log/current-view reference tests;
  10. change-control, mutation ownership, and diagnostics;
  11. generated byte-for-byte drift check; and
  12. mode-specific gate summary.

- [ ] **Step 3: Run all three levels with exact dispositions**

  ```sh
  ./tests/standalone-packet-e-inventory.sh
  ./docs/greenfield/research/invariants/test-packet-e-levels.sh structure
  ./docs/greenfield/research/invariants/test-packet-e-levels.sh gate-2a
  ./docs/greenfield/research/invariants/test-packet-e-levels.sh operational
  ./docs/greenfield/research/invariants/check-inventory.sh
  ```

  Each wrapper invokes the raw gate, captures its status and complete canonical
  output despite strict Bash mode, and returns zero only after it matches the
  checked expected-disposition file and exact unresolved set. Raw gate commands
  remain nonzero while open. `structure` must pass;
  `gate-2a` passes only with an empty required-specification import set;
  `operational` passes only with real approved current evidence. A currently
  expected open level returns the stable open-status code and exact unresolved
  set; shell orchestration treats that declared result as a successful test,
  not as gate closure.

- [ ] **Step 4: Update the inventory review honestly**

  Record Packet E Gate 2A closed only if `gate-2a` passed with every static
  specification import resolved. Otherwise record
  `structure-valid/gate-2a-open` and the exact blockers. Keep Gate 4B and
  backend support open unless `operational` has real approved evidence. Do not
  equate synthetic tests or reference-store success with production
  conformance.

- [ ] **Step 5: Commit the Stage 14 candidate**

- [ ] **Step 6: Run the three-role review and commit only
  `reviews/stage-14.md` as acceptance evidence**

  ```sh
  git add docs/greenfield/research/invariants/reviews/stage-14.md
  git commit -m "review: accept Packet E standalone inventory gate"
  ```

---

### Stage 15: Exact-subject clean-clone verification and external CI attestation

**Files:**

- Create: `docs/greenfield/research/invariants/reviews/stage-15.md`

**Interfaces:**

- Produces a reproducible verification record for one exact subject commit and
  an external CI attestation for the later evidence-only commit.
- Makes no production deployment, backend support, or Gate 4B claim.

- [ ] **Step 1: Freeze and review the exact subject commit**

  Commit all implementation/review-summary changes before Stage 15 evidence.
  Run the three-role final review over that exact subject SHA/tree. Fix every
  blocker/major in a new subject commit and repeat review until approved. Do
  not create `stage-15.md` yet.

- [ ] **Step 2: Clone the subject locally without object sharing**

  From the repository root, run:

  ```sh
  subject_sha="$(git rev-parse HEAD)"
  local_clone_base="$(mktemp -d "${TMPDIR:-/tmp}/foampit-packet-e-local.XXXXXX")"
  git clone --no-local "$(pwd)" "${local_clone_base}/repo"
  git -C "${local_clone_base}/repo" checkout --detach "${subject_sha}"
  test "$(git -C "${local_clone_base}/repo" rev-parse HEAD)" = "${subject_sha}"
  ```

  This proves no untracked/local-only file dependency before the first push of
  the subject.

- [ ] **Step 3: Run the complete original behavior in the subject clone**

  ```sh
  (
    cd "${local_clone_base}/repo"
    ./tests/standalone-contract-compiler.sh
    ./tests/standalone-packet-e-inventory.sh
    ./docs/greenfield/research/invariants/check-inventory.sh
  )
  ```

  Also run all three validation levels and compare exact declared
  dispositions. An open level must be open for its recorded import/evidence
  set—not missing tooling or malformed Packet E data.

- [ ] **Step 4: Reproduce all generated bytes**

  Regenerate into a second clean tree and compare semantic model, proof
  material, certificate, family universes, coverage ledger, shard
  commitments embedded in the coverage ledger, tooling mutation-ownership
  data, and review summary byte-for-byte.

- [ ] **Step 5: Map the blast radius**

  Record every modified consumer and test actually checked. Explicitly list
  unverified production backends, Packet C/F hooks, external witnesses,
  protected stores, and live measurements.

- [ ] **Step 6: Push the verified subject, then verify the remote SHA**

  Push the branch at the exact subject SHA. Clone/fetch from the remote into a
  second clean directory, verify the checked-out SHA equals the subject, and
  rerun the complete suite. A push that changes the subject invalidates prior
  evidence.

  ```sh
  git push origin HEAD
  remote_url="$(git remote get-url origin)"
  remote_clone_base="$(mktemp -d "${TMPDIR:-/tmp}/foampit-packet-e-remote.XXXXXX")"
  git clone "${remote_url}" "${remote_clone_base}/repo"
  git -C "${remote_clone_base}/repo" checkout --detach "${subject_sha}"
  test "$(git -C "${remote_clone_base}/repo" rev-parse HEAD)" = "${subject_sha}"
  (
    cd "${remote_clone_base}/repo"
    ./tests/standalone-contract-compiler.sh
    ./tests/standalone-packet-e-inventory.sh
    ./docs/greenfield/research/invariants/check-inventory.sh
  )
  ```

- [ ] **Step 7: Commit an evidence-only record**

  `reviews/stage-15.md` names the subject SHA/tree, remote SHA, commands,
  results, reviewer findings, generated-byte comparison, and blast radius. It
  explicitly states that the evidence commit is outside the verified subject.

  ```sh
  git add docs/greenfield/research/invariants/reviews/stage-15.md
  git commit -m "test: attest verified Packet E subject"
  git push
  ```

- [ ] **Step 8: Require external CI on the evidence commit**

  Wait for `.github/workflows/packet-e.yml` to verify the evidence commit from
  a fresh checkout and publish its signed provider check result outside the
  Git commit graph. The task is not complete until that check is green. The
  final report distinguishes verified subject SHA, evidence commit SHA, and CI
  check identity.

---

## Final acceptance checklist

- [ ] All 21 stage review records are `accepted` with no open blocker/major.
- [ ] `PacketEScopeManifest` is the sole membership authority; the tooling
  inventory exact-matches it and generated, fixture, review, and foreign
  operational data are non-authoritative.
- [ ] The exact 32-method and 19-family universes are independently pinned.
- [ ] The symbolic interaction universe is proven equal to 524,287 without
  full materialization.
- [ ] Every catalog field reaches `CatalogDenotation`, normalized model, and
  complete comparison relation or is explicitly classified nonsemantic.
- [ ] The independent checker—not the normalizer—issues the exact
  normalization certificate.
- [ ] Lean kernel checks all universal certificates with audited axiom and
  premise closure.
- [ ] Generator, interpreter, `jq`, CUE, transition oracle, interaction
  checker, shard verifier, and Lean obligations agree.
- [ ] Every locked mutation has an executable owning check and stable safe
  diagnostic.
- [ ] The reference SQLite store refines the pure model under every declared
  process-transaction/crash boundary, with broader power/storage failures
  explicitly unclaimed.
- [ ] Evaluation and Support logs are fork-evident, quorum-published,
  rotation-safe, and anti-rollback in the executable model.
- [ ] Current support fails closed for missing, stale, pending, conflicted,
  inconclusive, revoked, expired, rolled-back, or unreported evidence.
- [ ] Structure level passes from a clean clone.
- [ ] Gate 2A closes only if every static specification import resolves.
- [ ] Operational level remains explicitly open until real foreign artifacts
  exist.
- [ ] Gate 2A and Gate 4B statuses are reported separately and honestly.
