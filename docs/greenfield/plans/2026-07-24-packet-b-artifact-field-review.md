# Gate 2A Packet B Artifact Field Review Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> `superpowers:subagent-driven-development` or
> `superpowers:executing-plans` to execute this plan task-by-task. Steps use
> checkbox syntax for tracking.

**Goal:** Exhaustively review every portable Artifact Definition field family,
register every missing semantic invariant and valid boundary witness, and
produce a machine-checkable ledger that delegates target, composition,
lifecycle, and disclosure details without losing them.

**Architecture:** The executable corpus remains the normative human semantic
specification and `invariants.json` remains the machine traceability source of
truth. Packet B adds a second machine-readable ledger at Artifact-field
granularity. A focused `jq` validator checks family completeness, registry
references, delegation, introduced-invariant coverage, and placeholder-free
review state before the common Gate 2A inventory command can pass.

**Tech stack:** Markdown, JSON, `jq`, Bash, the pinned Nix prototype
environment, and Parallel primary-source research where current standards
semantics are material.

## Global Constraints

- Nix remains the deterministic construction substrate.
- Packet B reviews Artifact-owned portable semantics only.
- Concrete creation bindings, operator infrastructure, live operations, Exec,
  and framework lifecycle must not be pulled into the Artifact.
- Target realization belongs to Packet C, composition and escape hatches to
  Packet D, lifecycle to Packet E, and security/disclosure/evidence to Packet F.
- A delegated field remains in the Packet B ledger with an exact destination
  packet and rationale.
- New normative rules receive corpus and registry IDs before explanatory prose.
- Every invalid witness has a nearby valid witness.
- No invariant is marked `closed`; all implementation hooks and tests remain
  honest about current prototype status.
- Web research uses Parallel only and cites primary sources.
- Preserve unrelated untracked workspace content.
- Do not commit, stage, push, or publish unless the user explicitly requests
  it.

---

### Task 1: Lock the Artifact field inventory

**Files:**

- Read:
  `docs/greenfield/DESIGN.md`
- Read:
  `docs/greenfield/OPTION-SURFACE-RESEARCH.md`
- Read:
  `docs/greenfield/CONFIGURATION-BOUNDARY-AUDIT.md`
- Read:
  `docs/greenfield/research/CONFIGURATION-LANGUAGE-CORPUS.md`
- Read:
  `docs/greenfield/research/invariants/PACKET-A-SURFACE-COVERAGE.json`
- Create:
  `docs/greenfield/research/invariants/PACKET-B-ARTIFACT-FIELDS.json`

**Interfaces:**

- Consumes: Packet A rows whose `resource` is `artifact` or `manifest`.
- Produces: one field row per portable Artifact field or closed alternative.

- [x] Extract the complete field list for profile, metadata, environment,
  process defaults, workspace, filesystem, network, resources, identity,
  security, secret slots, requirements, provenance, outputs, and targets.
- [x] Give every row a stable dotted field identity.
- [x] Record portable meaning, owner, value shape, omission semantics, forbidden
  inputs, manifest projection, applicable current invariants, review outcome,
  and any delegated packets.
- [x] Check that every Packet A Artifact row is refined by at least one Packet B
  row.

### Task 2: Add Packet B ledger validation test-first

**Files:**

- Create:
  `docs/greenfield/research/invariants/fixtures/minimal-artifact-field-review.json`
- Create:
  `docs/greenfield/research/invariants/test-artifact-field-review.sh`
- Create after the red run:
  `docs/greenfield/research/invariants/validate-artifact-field-review.jq`

**Interfaces:**

- Consumes: Packet B field ledger and invariant registry.
- Produces: a pass/fail result suitable for `check-inventory.sh`.

- [x] Add a minimal valid review fixture.
- [x] Add failing cases for duplicate field identity, missing required family,
  unknown owner, unknown outcome, covered row without an invariant, unknown
  invariant reference, invalid delegation, missing portable meaning, missing
  omission semantics, and placeholder content.
- [x] Add failing cases proving every `introducedInvariant` exists and is
  referenced by a field row.
- [x] Run the test harness before creating the validator.
- [x] Verify the harness fails because the validator is absent.
- [x] Implement only the rules exercised by the failing cases.
- [x] Run the harness until every focused case passes.

**Verification:**

```sh
docs/greenfield/research/invariants/test-artifact-field-review.sh
```

Expected: all Packet B ledger cases pass.

### Task 3: Reconcile research and select invariants

**Files:**

- Modify:
  `docs/greenfield/research/invariants/PACKET-B-ARTIFACT-FIELDS.json`
- Create:
  `docs/greenfield/research/invariants/PACKET-B-RESEARCH-NOTES.md`

**Interfaces:**

- Consumes: three independent subagent reports and primary-source checks.
- Produces: accepted, rejected-as-duplicate, and delegated findings.

- [x] Compare every proposed invariant against existing `STR-*`, `SUM-*`,
  `XRS-*`, `TGT-*`, `CMP-*`, `WIRE-*`, `MAN-*`, and Packet A API rules.
- [x] Merge proposals only when their invalid state, earliest sound phase, and
  remediation are genuinely identical.
- [x] Reject backend-mechanism proposals from Packet B and delegate them to
  Packet C.
- [x] Reject lifecycle timing/operation proposals from Packet B and delegate
  them to Packet E.
- [x] Record why every researched proposal was accepted, merged, or delegated.

### Task 4: Register Packet B corpus cases

**Files:**

- Modify:
  `docs/greenfield/research/CONFIGURATION-LANGUAGE-CORPUS.md`
- Modify:
  `docs/greenfield/research/invariants/invariants.json`

**Interfaces:**

- Consumes: accepted Packet B invariant specifications.
- Produces: exact corpus/registry entries and valid witnesses.

- [x] Add one corpus heading per accepted invalid-state ID.
- [x] For each case record owner, first-sound phase, deadline, exact invariant,
  minimum witness, and required diagnostic.
- [x] Add valid cases that prove advanced environment, filesystem, network,
  resource, identity/security, secret, output, and profile configurations
  remain expressible.
- [x] Run inventory validation and observe exact-set failure before registry
  updates.
- [x] Add complete registry entries with targets, trust boundaries,
  composition paths, one planned authority, planned test classes, and
  secret-safe diagnostics.
- [x] List all new IDs in the Packet B ledger's `introducedInvariants`.
- [x] Run exact-set and witness-reference validation until green.

**Verification:**

```sh
docs/greenfield/research/invariants/validate-registry.sh \
  inventory \
  docs/greenfield/research/invariants/invariants.json \
  docs/greenfield/research/CONFIGURATION-LANGUAGE-CORPUS.md
```

Expected: zero corpus, registry, or witness-reference differences.

### Task 5: Integrate Packet B into Gate 2A

**Files:**

- Modify:
  `docs/greenfield/research/invariants/check-inventory.sh`
- Modify:
  `docs/greenfield/research/INVARIANT-ENFORCEMENT.md`
- Modify:
  `docs/greenfield/research/invariants/INVENTORY-REVIEW.md`
- Create:
  `docs/greenfield/research/invariants/PACKET-B-ARTIFACT-FIELD-REVIEW.md`

**Interfaces:**

- Consumes: validated Packet B ledger and registry.
- Produces: a mandatory Gate 2A check and human decision record.

- [x] Run the Packet B fixture harness from `check-inventory.sh`.
- [x] Validate the real Packet B ledger against the real registry.
- [x] Report Artifact field-row and invariant counts in inventory output.
- [x] Mark the single-resource/Artifact-field review dimension reviewed only if
  every required family is present.
- [x] Record every remaining delegation to Packets C–F.
- [x] State explicitly that Packet B completion does not close Gate 2A.

### Task 6: Reader testing and full verification

**Files:**

- Modify as findings require:
  `docs/greenfield/research/invariants/PACKET-B-ARTIFACT-FIELD-REVIEW.md`
- Modify as findings require:
  `docs/greenfield/research/invariants/PACKET-B-ARTIFACT-FIELDS.json`

**Interfaces:**

- Consumes: the complete Packet B artifacts without conversation history.
- Produces: corrected reader-facing documentation and final verification
  evidence.

- [x] Ask a fresh reader subagent to answer field ownership, omission,
  invalid-state, phase, and delegation questions using only Packet B artifacts.
- [x] Ask a separate reviewer to find contradictions, invisible defaults,
  backend leakage, missing valid cases, and false claims of compile-time
  certainty.
- [x] Correct every actionable ambiguity before verification.
- [x] Run JSON parsing and Bash syntax checks.
- [x] Run focused registry and Packet A/Packet B ledger tests.
- [x] Run `docs/greenfield/research/prototypes/test-all.sh`.
- [x] Confirm Gate 4B still fails for the expected planned implementation
  obligations.

**Final verification:**

```sh
docs/greenfield/research/prototypes/test-all.sh
```

Expected: inventory checks, every language prototype, native-handle checks,
wire validation, and pipeline equivalence pass. Gate 2A remains open for
Packets C–F.
