# Gate 2A Packet C Target Realization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> `superpowers:subagent-driven-development` or
> `superpowers:executing-plans` to execute this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking.

**Goal:** Classify and specify how every reviewed Artifact field is preserved,
lowered, rejected, deferred to a later authoritative boundary, or proven by
conformance for every initial target/runtime profile and remote-provider
transport boundary.

**Architecture:** Packet C adds a target-profile registry and a compact
machine-readable rule set whose selectors expand to an exact Cartesian matrix
of Packet B field identity × target profile. A validator rejects gaps,
overlaps, vague outcomes, late rejection, backend defaults, unowned
requirements, and unsupported claims. A generator-owned case-contract catalog,
with its content digest independently pinned in the validator, locks every
case's structured condition, outcome, phase, authority, step chain, evidence
classes, and later-packet delegation.
Remote-provider transport remains a separate contract registry so deployment
topology cannot become a target or silently reinterpret Artifact semantics.

**Tech Stack:** Markdown, JSON, `jq`, Bash, the pinned Nix prototype
environment, primary-source Parallel research, and independent reader and
adversarial reviews.

## Global Constraints

- Packet B's 81 Artifact fields are the complete input dimension for Packet C.
- Initial target profiles are bubblewrap on Linux, microVM/Firecracker,
  microVM/Cloud Hypervisor, and OCI on Linux.
- Runtime-profile identities in research artifacts are stable review
  coordinates, not locked public option names.
- Remote-provider transport is not a target profile.
- The product owns direct bubblewrap lowering; jail.nix remains prior art and
  is not the foundational compiler.
- A pinned microvm.nix adapter may construct guest artifacts; the product does
  not expose its option tree or use `config.microvm.declaredRunner` as the
  runtime contract.
- Artifact source states target/profile requirements. Builders emit support and
  conformance facts; manifest load verifies them.
- Every field/profile cell has a structurally complete ordered value partition
  and stable predicate coordinates. Each value case has exactly one result:
  conforming lowering, explicit build-time unsupported,
  creation/operator/preflight requirement, or observed runtime conformance
  requirement. Executable semantic predicates remain Gate 4B implementation
  work.
- Each value-case result records the earliest sound phase, rejection/proof deadline,
  owning component, manifest projection, diagnostic, and evidence obligation.
- Normative decisions are closed structured fields or stable obligation IDs.
  Explanations, rationales, remediation, and examples are explicitly
  non-normative.
- The complete target-profile registry and exact case-contract catalog have
  validator-owned SHA-256 pins. A coordinated mutation of a generated record
  and its mirror cannot silently redefine the reviewed contract.
- “Best effort,” warnings, target defaults, implicit fallback, and silent
  target disappearance are forbidden.
- A remote provider may accept an already built member, build from pinned
  inputs, or expose a provider-native capability, but every mode must preserve
  identity and make unsupported semantics explicit.
- New semantic invalid states receive corpus and registry IDs before
  explanatory prose.
- Every invalid witness has a nearby valid witness.
- Packet C does not close Gate 2A; Packets D–F remain required.
- Preserve unrelated untracked workspace content.
- Do not stage, commit, push, or publish without explicit user authorization.

---

### Task 1: Lock Packet C resources and target/profile terminology

**Files:**

- Read:
  `docs/greenfield/DESIGN.md`
- Read:
  `docs/greenfield/TARGET-IMPLEMENTATION-STRATEGY.md`
- Read:
  `docs/greenfield/research/INVARIANT-ENFORCEMENT.md`
- Read:
  `docs/greenfield/research/invariants/PACKET-B-ARTIFACT-FIELDS.json`
- Create:
  `docs/greenfield/research/invariants/PACKET-C-TARGET-PROFILES.json`
- Modify:
  `docs/greenfield/DESIGN.md`
- Modify:
  `docs/greenfield/TARGET-IMPLEMENTATION-STRATEGY.md`

**Interfaces:**

- Consumes: Packet B's Artifact-field identities and locked target strategy.
- Produces: typed target family, runtime profile, target member, driver,
  builder, provider transport, and conformance-claim identities.

- [x] Define the four initial target-profile review coordinates and their
  target family, workload platform, builder boundary, runtime boundary, and
  required external implementations.
- [x] State that Artifact source selects/requires profile identities while
  builder/member manifests alone advertise proven support.
- [x] Separate target construction from provider transport and deployment.
- [x] Correct any parent-document wording that still permits Artifact authors
  to mint support or passing-conformance claims.
- [x] Record whether one byte-identical member may advertise multiple
  compatible profiles and which facts must differ before a separate member is
  required.

### Task 2: Add the realization-matrix validator test-first

**Files:**

- Validate directly against the complete Packet B ledger, invariant registry,
  four-profile registry, and generated 324-cell realization record. Minimal
  profile/field fixtures are forbidden because they make the versioned
  universe shrinkable in the validator harness.
- Create:
  `docs/greenfield/research/invariants/test-target-realization.sh`
- Create after the red run:
  `docs/greenfield/research/invariants/validate-target-realization.jq`

**Interfaces:**

- Consumes: Packet B field ledger, target-profile registry, realization rules,
  and invariant registry.
- Produces: a pass/fail expansion proving every field × profile cell is covered
  exactly once.

- [x] Define closed outcome, phase, authority, lowering-strength, and evidence
  enums.
- [x] Validate directly against the versioned 81-field/four-profile universe;
  do not permit a minimal fixture to shrink the validator's universe.
- [x] Add failing cases for an uncovered cell, overlapping rules, unknown
  field/profile/invariant, duplicate identity, empty selector, invalid phase
  ordering, missing owner, missing manifest behavior, missing diagnostic,
  missing evidence, placeholder text, target-default inheritance, best-effort
  lowering, and unsupported-without-build-time failure.
- [x] Run the focused harness before the validator exists and verify RED is
  caused by the missing validator.
- [x] Implement only the checks required by the failing fixtures.
- [x] Run the focused harness until every case passes.

**Verification:**

```sh
docs/greenfield/research/invariants/test-target-realization.sh
```

Expected: every focused Packet C validator case passes.

### Task 3: Perform independent primary-source target research

**Files:**

- Create:
  `docs/greenfield/research/invariants/PACKET-C-RESEARCH-NOTES.md`

**Interfaces:**

- Consumes: exact upstream documentation and source for each target mechanism.
- Produces: evidence-backed capability, limitation, default, phase, and
  conformance findings for matrix reconciliation.

- [x] Research bubblewrap argument semantics, namespaces, filesystem setup,
  seccomp input, environment, process/session behavior, capability handling,
  network behavior, and kernel/privilege prerequisites.
- [x] Recheck jail.nix only as prior art and document which combinators are
  build-determined, runtime-bound, opaque, or unsafe.
- [x] Research microvm.nix guest outputs and option/assertion boundaries
  separately from its generated runner.
- [x] Research Firecracker API, jailer, device model, networking, rate limits,
  snapshots, process confinement, and host prerequisites.
- [x] Research Cloud Hypervisor API, virtiofs/vsock, devices, resources,
  snapshots, process confinement, and host prerequisites.
- [x] Research OCI Image and Runtime Specification separation, Linux runtime
  configuration, hooks/defaults, namespaces, mounts, resources, devices,
  security, annotations, and lifecycle guarantees.
- [x] Research remote-provider artifact ingestion and capability-discovery
  patterns using Modal, E2B, and other materially relevant primary APIs without
  making any provider part of the portable schema.
- [x] Record source date/revision, exact supported fact, limitation, and Packet
  C consequence for every accepted research claim.

### Task 4: Build and populate the target realization rule set

**Files:**

- Create:
  `docs/greenfield/research/invariants/PACKET-C-TARGET-REALIZATION.json`
- Create:
  `docs/greenfield/research/invariants/PACKET-C-CASE-CONTRACTS.json`
- Create:
  `docs/greenfield/research/invariants/generate-target-realization.mjs`

**Interfaces:**

- Consumes: all 81 Packet B fields, four target profiles, registry invariants,
  and reconciled research.
- Produces: selector rules that expand to exactly 324 field/profile cells.

- [x] Define each rule with stable identity, field selectors, profile
  selectors, outcome, earliest phase, deadline, authority, realization
  mechanism, manifest behavior, prohibited backend behavior, diagnostic,
  evidence classes, invariant references, and later-packet delegation.
- [x] Classify portable semantic preservation separately from physical
  mechanism so different implementations cannot claim false equivalence.
- [x] Record `preserved-no-emission`, `manifest-only`, `built-content`,
  `create-binding`, `operator-binding`, `host-preflight`,
  `driver-preparation`, and `post-start-probe` as typed realization modes, not
  prose conventions.
- [x] Require explicit build-time unsupported results when an enabled profile
  cannot meet a mandatory Artifact requirement.
- [x] Distinguish Artifact-built bytes from runtime allocations and host
  bindings for every filesystem, network, resource, identity, device, secret,
  snapshot, and output field.
- [x] Prove the final selector expansion covers exactly 324 cells with no
  overlaps.
- [x] Generate an exact case-contract catalog from the reviewed rule source
  and require the validator to compare every structured case control against
  it. Independently pin the catalog digest in the validator so a coordinated
  source/catalog edit cannot self-authorize relabeling of outcomes, evidence,
  steps, or delegation.

### Task 5: Specify remote-provider transport contracts separately

**Files:**

- Create:
  `docs/greenfield/research/invariants/PACKET-C-PROVIDER-CONTRACTS.json`
- Create:
  `docs/greenfield/research/invariants/test-provider-contracts.sh`
- Create after the red run:
  `docs/greenfield/research/invariants/validate-provider-contracts.jq`

**Interfaces:**

- Consumes: Artifact Set/member identities, manifests, target profiles, and
  provider research.
- Produces: provider-neutral transport modes and explicit capability/admission
  obligations without creating a portable “remote target.”

- [x] Define contracts for prebuilt member transfer, OCI
  descriptor/registry transfer, and provider-side construction from pinned
  source inputs.
- [x] For every contract record content identity verification, provenance,
  accepted member kinds, capability discovery, secret/provider ownership,
  cache behavior, unsupported semantics, admission phase, runtime evidence,
  and deletion/retention boundary.
- [x] Reject provider-native defaults and opaque “run this environment”
  requests that cannot prove equivalence to the Artifact manifest.
- [x] State when a provider adapter may expose a separate explicitly
  non-conforming capability instead of claiming portable conformance.
- [x] Validate that transport choice does not change portable semantic
  identity.
- [x] Add red-first validation for required contract classes, identities,
  admission phases, verification, cache, secret, evidence, unsupported, and
  retention boundaries.
- [x] Encode provider identity, unsupported behavior, cache, secret, and
  retention semantics as closed contracts; encode required inputs,
  prohibitions, admission requirements, runtime evidence, and unsupported
  conditions as exact contract-specific obligation-ID sets.

### Task 6: Register newly discovered target invalid states

**Files:**

- Modify:
  `docs/greenfield/research/CONFIGURATION-LANGUAGE-CORPUS.md`
- Modify:
  `docs/greenfield/research/invariants/invariants.json`
- Modify:
  `docs/greenfield/research/invariants/PACKET-C-TARGET-REALIZATION.json`

**Interfaces:**

- Consumes: reconciled target and provider findings.
- Produces: exact corpus/registry cases for every Packet C rule not already
  represented.

- [x] Compare every proposed rule against existing `TGT-*`, `DRV-*`, `MAN-*`,
  `CRT-*`, `LIVE-*`, `EXE-*`, `WIRE-*`, and Packet B invariants.
- [x] Strengthen an existing invariant only when invalid state, owner,
  first-sound phase, deadline, diagnostic, and remediation match.
- [x] Add corpus cases and nearby valid witnesses before registry entries.
- [x] Run exact-set validation and observe failure before adding registry
  entries.
- [x] Add complete planned authorities, tests, diagnostics, target/profile
  applicability, trust boundaries, and composition paths.
- [x] Keep all implementation hooks and evidence honestly planned.

### Task 7: Integrate Packet C into Gate 2A

**Files:**

- Modify:
  `docs/greenfield/research/invariants/check-inventory.sh`
- Modify:
  `docs/greenfield/research/INVARIANT-ENFORCEMENT.md`
- Modify:
  `docs/greenfield/research/invariants/INVENTORY-REVIEW.md`
- Create:
  `docs/greenfield/research/invariants/PACKET-C-TARGET-REALIZATION-REVIEW.md`

**Interfaces:**

- Consumes: validated target registry, expanded realization rules, provider
  contracts, and updated invariant registry.
- Produces: mandatory Gate 2A checks and a reader-facing Packet C decision
  record.

- [x] Run the Packet C focused fixture harness from `check-inventory.sh`.
- [x] Validate the real Packet C target registry and realization rules.
- [x] Report target-profile count, field count, expanded-cell count, outcome
  counts, provider-contract count, and introduced-invariant count.
- [x] Document exact unsupported combinations and their rejection phase.
- [x] Document every obligation delegated to Packet D, E, or F.
- [x] State explicitly that Packet C completion does not close Gate 2A.

### Task 8: Reader testing, adversarial review, and full verification

**Files:**

- Modify as findings require:
  `docs/greenfield/research/invariants/PACKET-C-TARGET-REALIZATION.json`
- Modify as findings require:
  `docs/greenfield/research/invariants/PACKET-C-CASE-CONTRACTS.json`
- Modify as findings require:
  `docs/greenfield/research/invariants/PACKET-C-PROVIDER-CONTRACTS.json`
- Modify as findings require:
  `docs/greenfield/research/invariants/PACKET-C-TARGET-REALIZATION-REVIEW.md`

**Interfaces:**

- Consumes: complete Packet C artifacts without conversation history.
- Produces: corrected final records and fresh verification evidence.

- [x] Ask a cold reader to reconstruct every target/profile boundary,
  unsupported combination, authority phase, provider transport mode, and
  builder-versus-runtime claim using only Packet C artifacts.
- [x] Ask an adversarial reviewer to find missing cells, false equivalence,
  hidden backend defaults, late errors, unsupported dynamic claims, provider
  leakage, insufficient evidence, and compile-time certainty overclaims.
- [x] Correct every actionable ambiguity and have an independent schema
  reviewer recheck it.
- [x] Run JSON parsing and Bash syntax checks.
- [x] Run focused registry and Packet A/B/C ledger tests.
- [x] Run `docs/greenfield/research/prototypes/test-all.sh`.
- [x] Confirm Gate 4B still fails only because implementation hooks and
  executable conformance evidence remain planned.

**Final verification:**

```sh
docs/greenfield/research/prototypes/test-all.sh
```

Expected: inventory checks, every language prototype, native-handle checks,
wire validation, and pipeline equivalence pass. Gate 2A remains open for
Packets D–F.
