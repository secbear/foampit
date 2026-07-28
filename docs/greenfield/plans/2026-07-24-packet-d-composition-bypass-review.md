# Gate 2A Packet D Composition and Bypass Review Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> `superpowers:subagent-driven-development` or
> `superpowers:executing-plans` to execute this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking.

**Goal:** Prove that every supported configuration-composition path, native
extension surface, frontend boundary, and downstream corruption path either
cannot affect an invariant or reaches the exact authoritative validator before
an invalid value can become usable.

**Architecture:** Packet D adds a closed `CompositionPath` registry and a
generated invariant × path coverage matrix over the complete invariant
registry. Compact selector rules classify every cell, but expansion must cover
the absolute locked universe exactly once. A separately pinned case-contract
catalog prevents a generated matrix from authorizing a coordinated semantic
rewrite. Frontend-specific research and executable witnesses map Nix, CUE,
Nickel, Pkl, and the Dhall control onto the generic paths without making a
frontend the semantic authority.

**Tech Stack:** Markdown, JSON, `jq`, Bash, Node.js, the pinned Nix/CUE/Nickel/
Pkl/Dhall prototype environment, primary-source Parallel research, and
independent cold-reader and adversarial reviews.

**Current Packet D status:** **Candidate complete — corrected matrix and
prototypes green; independent cold-reader and adversarial sign-off pending**

## Global Constraints

- Packet D is greenfield design work under `docs/greenfield/`; predecessor
  implementation code is not an input.
- The product semantic authority remains the final normalized Artifact and
  versioned trust-boundary validators, not a frontend's merge system.
- Source-language rejection is useful but never sufficient at a trust
  boundary.
- Every supported composition path is a review coordinate with a stable ID,
  not necessarily a public option or API name.
- Every composition path must be evaluated against every registered invariant.
  “Not applicable” is forbidden; the precise result is either
  `may-contribute`, `may-narrow`, `may-select`, `no-authority`, or
  `boundary-input`, each with an exact validator chain.
- `no-authority` means the path is structurally unable to author that
  invariant and an exact boundary rejects any attempted foreign-owned value.
  It is not permission to omit the cell.
- The corrected locked path universe contains exactly these 54 first-class
  IDs: `artifact-ordinary-authoring`, `artifact-imports`,
  `artifact-import-order`, `artifact-profile-expansion`,
  `artifact-explicit-override`, `artifact-semantic-refinement`,
  `artifact-strongest-override`, `artifact-native-language-escape`,
  `operator-configuration-authoring`, `operator-configuration-imports`,
  `operator-configuration-precedence`,
  `operator-configuration-refinement`,
  `operator-configuration-native-escape`,
  `managed-service-definition-authoring`,
  `managed-service-definition-imports`,
  `managed-service-definition-precedence`,
  `managed-service-definition-refinement`,
  `managed-service-definition-native-escape`, `resolved-driver-handoff`,
  `serialized-resolved-reentry`, `generated-runtime-configuration`,
  `direct-driver-invocation`, `raw-runtime-config-input`, `frontend-output`,
  `raw-wire-input`, `schema-migration`, `namespaced-extension`,
  `typed-nix-handle`, `native-guest-module`, `target-native-extension`,
  `create-native-extension`, `operator-native-extension`,
  `service-native-extension`, `live-native-extension`,
  `exec-native-extension`, `adapter-native-extension`,
  `provider-native-adapter`, `provider-native-operation`,
  `corrupted-manifest`, `target-lowering`, `built-artifact-load`,
  `direct-api`, `framework-adapter`, `cli-adapter`, `managed-service`,
  `direct-native-nix-value`, `frontend-adaptation`,
  `unsafe-opaque-extension`, `provider-side-construction`,
  `provider-build-cache`, `prebuilt-member-transfer`,
  `oci-descriptor-transfer`, `provider-cache-hit`, and
  `corrupted-provider-build-result`.
- The invariant dimension is the exact `invariants.json` ID set. The validator
  must reject a missing, renamed, or additional invariant or path unless the
  versioned review universe and independent digest pins change together.
- All 54 × 140 = 7,560 current cells must expand exactly once. If Packet D
  registers another invariant, the expected cell count must increase by 54 per
  new invariant before review can close.
- Native extensions are lifecycle-scoped. There is no unrestricted
  `targets.<target>.native` authority.
- Artifact-native guest modules may express guest/build configuration but may
  not author host bindings, live placement, secrets, provider objects,
  runtime-profile selection, support claims, or conformance claims.
- Create-, operator-, service-, live-, Exec-, adapter-, and provider-native
  inputs may only affect their owned resource and phase. None may widen the
  immutable Artifact contract or mint built content identity.
- Target-native paths preserve all 324 reviewed Packet C field/profile
  decisions. They may add target-specific content only within a registered
  extension contract.
- Typed Nix handles bind the exact machine-owned
  `sourceGraphClosureDigest`, `registryNamespace`, `registryVersion`,
  `registryDigest`, `exportAttribute`, `nativeInterfaceVersion`,
  `targetSystem`, `affectedMember`, and `expectedSemanticProjection` tuple.
  `registryDigest` remains distinct from `sourceGraphClosureDigest`, and
  `semanticIdentityComparison` is required before construction. Arbitrary
  evaluator values never cross canonical wire or become portable identity.
- Raw canonical input, migrated input, built manifests, serialized resolved
  reentry, and attempted direct/raw driver inputs are always untrusted and
  revalidated or rejected independently.
- Resource source branches remain distinct:
  `P1 -> A0/A1/W0` for Artifact, `P1 -> OC0/O0` for Operator
  Configuration, and `P1 -> MS0/S0` for Managed-Service Definition.
- Serialized resolved reentry is wholly untrusted at
  `RW0 -> C0/O0/H0/D0` and replays the exact 89 built-load and 30
  resolved-stage arrays before fresh private construction.
- Generated backend configuration is D0 output. Direct driver invocation and
  raw runtime configuration have no admitted value.
- `prebuilt-member-transfer` and `oci-descriptor-transfer` end at H0;
  `provider-cache-hit` ends at D0; and `provider-side-construction`,
  `provider-build-cache`, and `corrupted-provider-build-result` end at N1.
  Each hands off to `built-artifact-load` as a separate C0 path. These are
  handoff records, not phase-edge assertions or authority to skip C0 manifest
  loading.
- Framework and CLI share typed Create/live/Exec translation. Teardown remains
  delegated to Packet E.
- “Best effort,” warning-only, implicit fallback, backend-default inheritance,
  unchecked raw arguments, and unchecked arbitrary shell are forbidden.
- Normative machine records use closed structured fields and stable IDs.
  Explanations, rationales, examples, and remediation are non-normative.
- Every invalid witness has a nearby valid witness.
- Newly discovered semantic invalid states receive corpus and registry IDs
  before explanatory prose.
- Packet D does not close Gate 2A; Packets E and F remain required.
- All enforcement hooks and executable conformance tests remain honestly
  `planned` until implementation.
- Preserve unrelated workspace content. Do not stage, commit, push, or publish
  without explicit user authorization.

---

### Task 1: Lock CompositionPath vocabulary and the complete path universe

**Files:**

- Read:
  `docs/greenfield/DESIGN.md`
- Read:
  `docs/greenfield/CONFIGURATION-BOUNDARY-AUDIT.md`
- Read:
  `docs/greenfield/research/INVARIANT-ENFORCEMENT.md`
- Read:
  `docs/greenfield/research/invariants/invariants.json`
- Create:
  `docs/greenfield/research/invariants/PACKET-D-COMPOSITION-PATHS.json`
- Modify:
  `docs/greenfield/DESIGN.md`
- Modify:
  `docs/greenfield/CONFIGURATION-BOUNDARY-AUDIT.md`

**Interfaces:**

- Consumes: the locked ownership/phase model, all 140 registered invariants,
  Packet A's scoped extension surfaces, and Packet B/C delegations.
- Produces: one closed registry of generic composition-path coordinates,
  frontend mappings, reachable owners, allowed effect, strongest bypass,
  mandatory boundaries, and later-packet delegation.

- [ ] Define `CompositionPath` as a route by which a value or operation can
  contribute to, transform, transport, or attempt to bypass a product-owned
  resource contract.
- [ ] Record all 54 locked path IDs from Global Constraints with one of:
  `authoring`, `frontend-boundary`, `artifact-native`, `lifecycle-native`,
  `provider-native`, `downstream-boundary`, or `caller`.
- [ ] For every path record closed `sourceOwner`, `reachableOwners`,
  `allowedEffects`, `firstBoundary`, `finalBoundary`, `strongestBypassClass`,
  `frontendMappings`, `targetApplicability`, and `delegatedPackets`.
- [ ] Require each `frontendMappings` entry to name an exact candidate,
  mechanism, research pin, and executable witness or an explicit
  `research-control-only`/`unsupported` result.
- [ ] State that exact frontend syntax is evidence for a generic path, never a
  second semantic contract.
- [ ] State that adding any future composition or extension facility reopens
  Packet D and changes the locked universe.

### Task 2: Add the complete coverage validator test-first

**Files:**

- Create:
  `docs/greenfield/research/invariants/test-composition-coverage.sh`
- Create after the red run:
  `docs/greenfield/research/invariants/validate-composition-coverage.jq`
- Create:
  `docs/greenfield/research/invariants/fixtures/composition-invalid-witnesses.json`

**Interfaces:**

- Consumes: `PACKET-D-COMPOSITION-PATHS.json`, `invariants.json`, and the
  generated coverage record.
- Produces: a pass/fail expansion proving every invariant × path cell exists
  exactly once and has a closed authority result.

- [ ] Add a positive test against the real invariant/54-path universe; do
  not use a shrinkable minimal-universe fixture.
- [ ] Add failing mutations for missing/renamed/extra paths, missing/renamed
  invariants, an uncovered cell, overlapping selectors, unknown invariant,
  unknown path, duplicate rule/case ID, empty selectors, and a shrunken
  expected-cell count.
- [ ] Add failing mutations for unknown effect, `not-applicable`, empty
  boundary chain, first-sound phase after deadline, authority absent from the
  chain, a native surface reaching a foreign owner, and a later phase used
  when an earlier boundary has complete information.
- [ ] Add failing mutations for a target-native path that omits a Packet C
  profile, a typed handle without registry digest, a guest module that can
  author host/runtime state, and a caller/native path that mints Artifact or
  conformance identity.
- [ ] Add failing mutations for self-consistent relabeling of effect,
  authority, boundary chain, test obligations, or delegation.
- [ ] Run the harness before the validator exists and confirm RED is caused by
  the missing validator.
- [ ] Implement closed-schema, exact-universe, phase-order, authority,
  ownership, traceability, and independent-digest checks.
- [ ] Run until every focused positive and negative case passes.

**Verification:**

```sh
docs/greenfield/research/invariants/test-composition-coverage.sh
```

Expected: every focused Packet D structural and mutation-resistance case
passes.

### Task 3: Complete primary-source composition research

**Files:**

- Create:
  `docs/greenfield/research/invariants/PACKET-D-RESEARCH-NOTES.md`
- Modify:
  `docs/greenfield/research/configuration-language-primary-source.json`
- Modify:
  `docs/greenfield/research/configuration-language-source-review.md`

**Interfaces:**

- Consumes: pinned upstream language/module documentation and the existing
  prototype suite.
- Produces: exact source-backed semantics and limitations for each frontend
  mapping in the path registry.

- [ ] Research Nix module imports, definition priorities, `mkOverride`,
  `mkForce`, `mkDefault`, list/order combinators, submodules, freeform types,
  `_module.args`, `specialArgs`, assertions, laziness, forcing, and source
  locations.
- [ ] Research CUE unification, closed definitions, embeddings, pattern
  constraints, defaults, disjunctions, imports/modules, comprehensions, and
  export boundaries.
- [ ] Research Nickel merge priorities, contracts, `force`, imports,
  recursive records, dynamic fields, foreign functions, and serialization.
- [ ] Research Pkl imports, `amends`, `extends`, object amendments, `open` and
  `dynamic`, hidden/local members, external readers, and output rendering.
- [ ] Retain Dhall as a research control for imports, semantic integrity
  hashes, record preference, recursive merge, unions, and normalization; do
  not imply initial product support.
- [ ] Research canonical JSON duplicate-key, numeric, Unicode, ordering,
  migration, and corrupted-input boundaries only from primary standards or
  implementation documentation.
- [ ] Record exact revision/date, supported fact, limitation, Packet D
  consequence, and executable witness for every accepted claim.

### Task 4: Generate and populate invariant × path coverage

**Files:**

- Create:
  `docs/greenfield/research/invariants/generate-composition-coverage.mjs`
- Create:
  `docs/greenfield/research/invariants/PACKET-D-COMPOSITION-COVERAGE.json`
- Create:
  `docs/greenfield/research/invariants/PACKET-D-CASE-CONTRACTS.json`

**Interfaces:**

- Consumes: all registered invariants, the 54-path registry, Packet A
  ownership, Packet B field semantics, Packet C realization/transport
  contracts, and reconciled research.
- Produces: compact selector rules expanding to the exact invariant × path
  universe and an independently pinned exact structured contract catalog.

- [ ] Define each selector rule with stable identity, invariant selectors,
  path selectors, value cases, `allowedEffect`, first-sound phase, deadline,
  authority, ordered boundary chain, diagnostic identity, evidence/test
  obligations, and later-packet delegation.
- [ ] Allow only `may-contribute`, `may-narrow`, `may-select`,
  `no-authority`, and `boundary-input`.
- [ ] For `no-authority`, name the structural exclusion and the exact boundary
  that rejects a forged foreign-owned field.
- [ ] For `boundary-input`, require full revalidation and prohibit trust in
  source/front-end claims.
- [ ] Make every authoring/override path converge on final Artifact validation
  and canonical-wire validation before Nix construction.
- [ ] Make native handles resolve only inside the pinned Nix construction
  registry and compare semantic identity before construction.
- [ ] Make target/native/build paths re-enter Packet C manifest/profile,
  identity, and realization checks.
- [ ] Preserve Packet A lifecycle ownership while explicitly delegating
  transition, retry, rollback, and teardown behavior to Packet E.
- [ ] Delegate disclosure/redaction/provenance visibility to Packet F without
  delegating bypass prevention.
- [ ] Generate an exact case-contract catalog and independently pin the
  complete path registry and case-catalog SHA-256 values in the validator.
- [ ] Prove the selector expansion covers exactly
  `54 × current invariant count` cells with no overlaps.

### Task 5: Expand executable strongest-bypass witnesses

**Files:**

- Modify:
  `docs/greenfield/research/prototypes/nix-baseline/cases.nix`
- Modify:
  `docs/greenfield/research/prototypes/nix-baseline/test.sh`
- Modify:
  `docs/greenfield/research/prototypes/cue/cases/`
- Modify:
  `docs/greenfield/research/prototypes/cue/test.sh`
- Modify:
  `docs/greenfield/research/prototypes/nickel/cases/`
- Modify:
  `docs/greenfield/research/prototypes/nickel/test.sh`
- Modify:
  `docs/greenfield/research/prototypes/pkl/cases/`
- Modify:
  `docs/greenfield/research/prototypes/pkl/test.sh`
- Modify:
  `docs/greenfield/research/prototypes/dhall/cases/`
- Modify:
  `docs/greenfield/research/prototypes/dhall/test.sh`
- Modify:
  `docs/greenfield/research/prototypes/native-handles-test.sh`
- Modify:
  `docs/greenfield/research/prototypes/wire-validator/fixtures/`
- Modify:
  `docs/greenfield/research/prototypes/wire-validator/test.sh`

**Interfaces:**

- Consumes: Packet D path mappings and exact invalid/valid witness IDs.
- Produces: at least one real evaluator/boundary execution for every serious
  frontend's strongest relevant bypass and every shared downstream trust
  boundary.

- [ ] Add Nix import-order, `mkForce`, stronger-priority, raw/freeform
  submodule, `_module.args`/`specialArgs`, lazy-unforced-target, and native
  guest ownership attempts plus valid refinement/order controls.
- [ ] Add CUE embedding, open/pattern field, conflicting default, import, and
  exported-output corruption attempts plus valid closed/unified controls.
- [ ] Add Nickel `force`, priority/merge, dynamic field, recursive record,
  import, and serialization corruption attempts plus valid contract controls.
- [ ] Add Pkl amendment, `amends`/`extends`, `open`/`dynamic`, hidden/local,
  external-reader, and rendered-output corruption attempts plus valid class
  controls.
- [ ] Add Dhall record-preference, recursive-merge, unhashed import, changed
  frozen import, and normalization controls.
- [ ] Add native-handle digest mismatch, unknown registry/member, value/reference
  mismatch, unsafe guest ownership, and valid pinned handle cases.
- [ ] Add raw-wire duplicate key, unknown field, non-canonical number,
  unsupported schema migration, forged provenance/support claim, corrupted
  manifest, and corrupted resolved-driver-input cases.
- [ ] Require the original mechanism to accept or represent the attempted
  bypass before the product-owned final boundary rejects it; a syntax error
  alone does not prove bypass resistance.

### Task 6: Register newly discovered composition invalid states

**Files:**

- Modify:
  `docs/greenfield/research/CONFIGURATION-LANGUAGE-CORPUS.md`
- Modify:
  `docs/greenfield/research/invariants/invariants.json`
- Modify:
  `docs/greenfield/research/invariants/PACKET-D-COMPOSITION-COVERAGE.json`

**Interfaces:**

- Consumes: the completed path matrix and executable research findings.
- Produces: exact corpus/registry entries for composition failures not already
  represented by `CMP-*`, `NAT-*`, `WIRE-*`, or owner-specific invariants.

- [ ] Compare every proposed rule against the entire registry, especially
  `CMP-001`–`CMP-008`, `NAT-001`–`NAT-002`, `WIRE-001`–`WIRE-004`,
  `DRV-001`, `SVC-*`, `CRT-*`, `LIVE-*`, `EXE-*`, and `FWK-*`.
- [ ] Strengthen an existing invariant only if invalid state, owner,
  first-sound phase, deadline, disposition, and diagnostic remain identical.
- [ ] Add corpus invalid and nearby valid witnesses before registry entries.
- [ ] Run exact-set validation and observe the intended RED mismatch.
- [ ] Add complete target, trust-boundary, composition-path, diagnostic, hook,
  and test records, keeping all implementation evidence `planned`.
- [ ] Regenerate the matrix, update the absolute expected cell count by 54 for
  each new invariant, and update independent digest pins through review.

### Task 7: Integrate Packet D into Gate 2A

**Files:**

- Modify:
  `docs/greenfield/research/invariants/check-inventory.sh`
- Modify:
  `docs/greenfield/research/INVARIANT-ENFORCEMENT.md`
- Modify:
  `docs/greenfield/research/invariants/INVENTORY-REVIEW.md`
- Create:
  `docs/greenfield/research/invariants/PACKET-D-COMPOSITION-REVIEW.md`

**Interfaces:**

- Consumes: validated path registry, complete coverage matrix, new invariants,
  research notes, and executable witnesses.
- Produces: mandatory Gate 2A checks and a reader-facing Packet D decision
  record.

- [ ] Run the Packet D focused harness from `check-inventory.sh`.
- [ ] Validate the real path registry, exact invariant universe, coverage
  expansion, case contracts, and digest pins.
- [ ] Report path count, invariant count, expanded-cell count, effect counts,
  frontend mappings, native-surface counts, and Packet D invariant count.
- [ ] Document the exact validator chain for each path category and strongest
  bypass mechanism.
- [ ] Document every obligation delegated to Packet E or F.
- [ ] State explicitly that Packet D completion does not close Gate 2A.

### Task 8: Reader testing, adversarial review, and full verification

**Files:**

- Modify as findings require:
  `docs/greenfield/research/invariants/PACKET-D-COMPOSITION-PATHS.json`
- Modify as findings require:
  `docs/greenfield/research/invariants/PACKET-D-COMPOSITION-COVERAGE.json`
- Modify as findings require:
  `docs/greenfield/research/invariants/PACKET-D-CASE-CONTRACTS.json`
- Modify as findings require:
  `docs/greenfield/research/invariants/PACKET-D-COMPOSITION-REVIEW.md`

**Interfaces:**

- Consumes: complete Packet D artifacts without conversation history.
- Produces: corrected reviewed records and fresh verification evidence.

- [ ] Ask a cold reader to reconstruct every path category, allowed effect,
  ownership exclusion, final validator chain, strongest bypass, and E/F
  delegation using only Packet D artifacts.
- [ ] Ask an adversarial reviewer to find an omitted path, shrinkable
  universe, self-authorized catalog, ownership crossover, late validator,
  frontend-trust assumption, target-native Packet C bypass, native-handle
  identity hole, or corruption path without revalidation.
- [ ] Correct every actionable ambiguity and have an independent reviewer
  recheck the settled artifacts.
- [ ] Run JSON parsing, Bash syntax, Node syntax, and generator drift checks.
- [ ] Run focused registry and Packet A/B/C/D ledger tests.
- [ ] Run `docs/greenfield/research/prototypes/test-all.sh`.
- [ ] Confirm Gate 4B still fails only because registered hooks, executable
  conformance tests, and implementation evidence remain planned.

**Final verification:**

```sh
docs/greenfield/research/prototypes/test-all.sh
```

Expected: inventory checks, every language prototype, native-handle checks,
wire validation, and pipeline equivalence pass. Gate 2A remains open only for
Packets E and F.
