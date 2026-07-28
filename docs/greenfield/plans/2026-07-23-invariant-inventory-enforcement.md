# Invariant Inventory and Enforcement Implementation Plan

> Status: active. This plan implements the protocol in
> `docs/greenfield/research/INVARIANT-ENFORCEMENT.md`; it does not implement the
> product's complete semantic rules.

**Goal:** Make the invariant inventory and enforcement obligations complete,
machine-checkable, and mandatory before candidate scoring or the
configuration-language ADR.

**Architecture:** Keep the executable corpus as the human-readable semantic
specification and add a language-neutral JSON traceability registry. A small
`jq` validator checks registry structure, phase ordering, corpus coverage, and
closure evidence without selecting a product implementation language. Shell
tests exercise valid and deliberately invalid registries before the validator
is trusted.

**Research tooling:** JSON, `jq`, POSIX-compatible shell, Nix-pinned prototype
test environment.

---

## Task 1: Lock the protocol and research gates

**Files:**

- Create:
  `docs/greenfield/research/INVARIANT-ENFORCEMENT.md`
- Modify:
  `docs/greenfield/DESIGN.md`
- Modify:
  `docs/greenfield/CONFIGURATION-LANGUAGE-RESEARCH.md`
- Modify:
  `docs/greenfield/research/CONFIGURATION-LANGUAGE-CORPUS.md`
- Modify:
  `docs/greenfield/research/prototypes/PROTOTYPE-NOTES.md`

**Steps:**

1. Define the honest validity guarantee: by-construction exclusion where
   information is complete; otherwise rejection at the earliest sound
   boundary.
2. Define Gate 2A, including the exhaustive state-space walk and inventory exit
   criteria.
3. Define Gate 4B, including hook, test, target, bypass, diagnostic, and
   corruption-evidence closure criteria.
4. Insert both gates into the controlling research order.
5. Make scoring, blind review, and the ADR depend on Gate 4B.
6. Link the protocol from the locked greenfield design and corpus.

**Verification:**

```sh
rg -n "Gate 2A|Gate 4B|INVARIANT-ENFORCEMENT" docs/greenfield
```

Expected: the controlling design, research plan, corpus, prototype notes, and
protocol all point to the same two gates.

## Task 2: Specify the registry contract with failing tests

**Files:**

- Create:
  `docs/greenfield/research/invariants/test-registry.sh`
- Create:
  `docs/greenfield/research/invariants/fixtures/minimal-valid.json`
- Create invalid fixtures under:
  `docs/greenfield/research/invariants/fixtures/`

**Steps:**

1. Add a minimal valid inventory fixture.
2. Add one invalid fixture for each structural rule:
   duplicate ID, unknown owner, unknown phase, reversed phase order, missing
   valid witness, missing invalid witness, missing hook, missing test, missing
   diagnostic, and placeholder content.
3. Add closure-only invalid fixtures: non-closed status, planned hook, planned
   test, missing authoritative hook, missing required corruption test, and
   missing bypass/target evidence.
4. Make the harness assert each fixture's expected diagnostic fragment.
5. Run the harness before implementing the validator.

**Expected RED result:** the harness fails because
`validate-registry.jq` does not exist.

## Task 3: Implement inventory-mode validation

**Files:**

- Create:
  `docs/greenfield/research/invariants/validate-registry.jq`
- Modify:
  `docs/greenfield/research/invariants/test-registry.sh`

**Steps:**

1. Parse registry version and invariant list.
2. Reject duplicate invariant IDs.
3. Validate owner, scope, status, phase, disposition, hook role/status, and test
   kind/status enums.
4. Validate first-sound/deadline ordering.
5. Require witnesses, targets, trust boundaries, composition paths, hooks,
   tests, and diagnostic obligations.
6. Reject empty or placeholder values such as `TBD`, `TODO`, and `unknown`.
7. Run the focused tests until every inventory fixture passes.

**Verification:**

```sh
docs/greenfield/research/invariants/test-registry.sh inventory
```

Expected: all inventory-mode validator cases pass.

## Task 4: Add corpus/registry exact-set validation

**Files:**

- Create:
  `docs/greenfield/research/invariants/invariants.json`
- Modify:
  `docs/greenfield/research/invariants/test-registry.sh`
- Modify:
  `docs/greenfield/research/CONFIGURATION-LANGUAGE-CORPUS.md`

**Steps:**

1. Seed one registry entry for every currently locked invalid-state identifier.
2. Extract invariant IDs from the corpus headings without interpreting
   candidate syntax.
3. Compare the sorted unique corpus and registry sets in both directions.
4. Fail on an invariant present only in prose or only in the registry.
5. Record valid corpus case identifiers as witnesses where applicable.
6. Run inventory validation against the real registry.

**Verification:**

```sh
docs/greenfield/research/invariants/test-registry.sh inventory
```

Expected: 100% exact identifier coverage and a structurally complete inventory.

## Task 5: Implement closure-mode validation test-first

**Files:**

- Modify:
  `docs/greenfield/research/invariants/test-registry.sh`
- Modify:
  `docs/greenfield/research/invariants/validate-registry.jq`
- Create closure fixtures under:
  `docs/greenfield/research/invariants/fixtures/`

**Steps:**

1. First add closure cases that inventory mode accepts but closure mode must
   reject.
2. Require in-scope status `closed`.
3. Require concrete non-planned hook and test references.
4. Require exactly one authoritative hook per applicable product path.
5. Require `wire-corruption` for source-level exclusions and all frontend trust
   boundaries.
6. Require test evidence for every declared composition path and target.
7. Require executable diagnostic assertions.
8. Add optional filesystem/reverse-reference checks for concrete registries.
9. Run focused tests until the closure cases pass.

**Verification:**

```sh
docs/greenfield/research/invariants/test-registry.sh closure
```

Expected: the minimal closed fixture passes and every incomplete fixture fails
for its intended reason.

## Task 6: Trace the current prototype honestly

**Files:**

- Modify:
  `docs/greenfield/research/invariants/invariants.json`
- Modify existing files under:
  `docs/greenfield/research/prototypes/`

**Steps:**

1. Link implemented corpus rules to current Nix, CUE, Nickel, Pkl, Dhall, native
   handle, shared pipeline, and wire-validator evidence.
2. Put the invariant identifier in each linked test or fixture.
3. Mark only executable prototype hooks/tests as `prototype`/`passing`.
4. Leave unimplemented obligations `planned`; do not mark the registry closed.
5. Generate an open-obligations report grouped by owner, phase, target, and
   bypass path.

**Verification:**

```sh
docs/greenfield/research/invariants/test-registry.sh inventory
docs/greenfield/research/prototypes/test-all.sh
```

Expected: inventory validation and the existing prototype suite pass; closure
validation fails only on accurately listed open work.

## Task 7: Add the gate to the complete prototype suite

**Files:**

- Modify:
  `docs/greenfield/research/prototypes/test-all.sh`
- Modify:
  `docs/greenfield/research/prototypes/README.md`

**Steps:**

1. Run inventory-mode registry validation before candidate fixtures.
2. Add a separately named closure check that is mandatory only when Gate 4B is
   being evaluated.
3. Document local and CI commands and their intended stage.
4. Keep all tools pinned/offline through the prototype Nix environment.

**Verification:**

```sh
docs/greenfield/research/prototypes/test-all.sh
```

Expected: the complete current suite passes and visibly reports the inventory
gate.

## Task 8: Close Gate 2A by review

Progress: **Packet A complete on 2026-07-23; Packets B–F remain open.**

**Files:**

- Modify:
  `docs/greenfield/research/invariants/invariants.json`
- Create:
  `docs/greenfield/research/invariants/INVENTORY-REVIEW.md`

**Steps:**

1. Walk all twelve inventory dimensions in the protocol.
2. Review every portable field, target/profile, resource boundary, lifecycle
   operation, trust boundary, and extension mechanism.
3. Add missing invariants and fixtures before editing candidate
   implementations.
4. Run a reader review for ambiguous ownership, phases, and disposition.
5. Record reviewed scope, known exclusions, and exact open implementation work.

**Exit check:**

```sh
docs/greenfield/research/invariants/check-inventory.sh
```

Expected: zero structural, coverage, ownership, phase, or placeholder failures,
plus an approved review record. This closes Gate 2A only.

## Task 9: Close Gate 4B before scoring

**Files:**

- Modify implementation and tests referenced by the registry.
- Create:
  `docs/greenfield/research/invariants/ENFORCEMENT-CLOSURE.md`

**Steps:**

1. Implement every open authoritative hook and defensive boundary check.
2. Complete positive, negative, bypass, corruption, target-conformance,
   diagnostic, preflight, and runtime-probe evidence as applicable.
3. Run every candidate twice with relevant import orders reversed and in pinned
   offline mode.
4. Run every target conformance suite applicable to v1.
5. Produce the closure report from registry state and independently review it.

**Exit check:**

```sh
docs/greenfield/research/invariants/test-registry.sh closure
docs/greenfield/research/prototypes/test-all.sh
```

Expected: both commands pass with no deferred v1 claim. Only then may blind
transcript review, scoring, adversarial review, and the authoring-language ADR
proceed.
