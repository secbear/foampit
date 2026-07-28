# Packet D Resource Composition and Driver Boundary Correction Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> `superpowers:subagent-driven-development` (recommended) or
> `superpowers:executing-plans` to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace Packet D's false-complete 42-path model with the approved
54-path, 140-invariant resource-scoped composition and resolved-driver trust
model, backed by executable strongest-bypass witnesses and independent review.

**Architecture:** Artifact, Operator Configuration, and Managed-Service
Definition source composition terminate at distinct product validators.
Resolved runtime state uses private stage types; serialized reentry is wholly
untrusted; generated backend configuration is D0 output; direct/raw driver
entry is forbidden. The generated matrix remains a full path × invariant
cross-product, while semantic relationship checks—not digest pins alone—enforce
ownership, applicability, phase, replay, identity, and delegation.

**Tech Stack:** Markdown, JSON, `jq`, Bash, Node.js, Nix module evaluation,
Rust research witnesses, and the pinned prototype Nix environment.

## Global Constraints

- This is greenfield design work under `docs/greenfield/`; existing product
  implementation code is not an input.
- The approved design authority is
  `docs/greenfield/research/invariants/PACKET-D-RESOURCE-COMPOSITION-DRIVER-BOUNDARY-DESIGN.md`.
- The corrected universe is exactly 54 paths and, after registration, exactly
  140 invariants: 7,560 cells.
- `OC0`, `MS0`, and `RW0` are distinct phases; none aliases Artifact `A1` or
  canonical Artifact wire `W0`.
- Active `may-contribute`, `may-narrow`, and `may-select` cells require the
  invariant owner to occur in the path's `reachableOwners`.
- Serialized resolved reentry replays the exact 89 built-load invariants and
  the exact 30 C0–D0 resolved-stage invariants.
- A direct driver invocation and raw runtime input have no conforming value
  case. Drivers accept only the private product-owned `PreparedLaunch` stage.
- Generated backend configuration is D0 output and suppresses every
  undeclared backend default.
- Every new invalid witness has a nearby valid witness.
- Production hooks and tests remain `planned`; disposable research evidence
  must not be relabeled as production closure.
- Packet D does not close Gate 2A; Packets E and F remain required.
- Preserve unrelated workspace content, including `prompt`. Do not stage,
  commit, push, or publish.

---

### Task 1: Register the ten correction invariants and nearby valid witnesses

**Files:**

- Modify:
  `docs/greenfield/research/CONFIGURATION-LANGUAGE-CORPUS.md`
- Modify:
  `docs/greenfield/research/invariants/invariants.json`
- Modify:
  `docs/greenfield/research/invariants/fixtures/composition-invalid-witnesses.json`
- Modify:
  `docs/greenfield/research/invariants/test-registry.sh`
- Modify:
  `docs/greenfield/research/invariants/validate-registry.jq`
- Modify if its argument plumbing requires the new phase set:
  `docs/greenfield/research/invariants/validate-registry.sh`
- Test:
  `docs/greenfield/research/invariants/validate-registry.sh`

**Interfaces:**

- Consumes: the approved invariant table and the existing invariant/valid
  witness schema.
- Produces: ordered registry IDs `OPS-003`–`OPS-005`, `SVC-003`–`SVC-005`,
  `WIRE-007`, and `DRV-002`–`DRV-004`, plus `VAL-040`–`VAL-042`.

- [ ] **Step 1: Add a failing exact registration assertion**

Add this inventory-mode assertion to `test-registry.sh` before modifying the
registry:

```sh
jq -e '
  [.invariants[].id] as $ids |
  all([
    "OPS-003","OPS-004","OPS-005",
    "SVC-003","SVC-004","SVC-005",
    "WIRE-007","DRV-002","DRV-003","DRV-004"
  ][]; $ids | index(.) != null) and
  (.invariants | length == 140)
' "${registry}" >/dev/null
```

- [ ] **Step 2: Run the registry test and confirm RED**

Run:

```sh
docs/greenfield/research/invariants/test-registry.sh inventory
```

Expected: non-zero because the ten IDs are absent or the count is still 130.

- [ ] **Step 3: Add the invalid and valid corpus records**

Append ten invalid sections with these exact ownership/phase contracts:

```text
OPS-003 operator P1 -> OC0
OPS-004 operator P1 -> OC0
OPS-005 operator P1 -> OC0
SVC-003 service  P1 -> MS0
SVC-004 service  P1 -> MS0
SVC-005 service  P1 -> MS0
WIRE-007 runtime RW0 -> RW0
DRV-002 runtime RW0 -> C0
DRV-003 runtime H0  -> D0
DRV-004 runtime D0  -> D0
```

Use the statements and remediation from the approved design. Add:

```text
VAL-040 Pinned, closed, provenance-complete Operator Configuration
VAL-041 Pinned, closed, provenance-complete Managed-Service Definition
VAL-042 Revalidated resolved reentry producing a private PreparedLaunch
```

`OPS-003`–`OPS-005` use `VAL-040`; `SVC-003`–`SVC-005` use `VAL-041`;
`WIRE-007` and `DRV-002`–`DRV-004` use `VAL-042`.

- [ ] **Step 4: Add exact registry objects**

Each new registry object must include the existing closed keys and these
authoritative hooks:

```json
[
  {"id":"OPS-003","phase":"OC0","component":"operator-configuration-validator"},
  {"id":"OPS-004","phase":"OC0","component":"operator-configuration-validator"},
  {"id":"OPS-005","phase":"OC0","component":"operator-configuration-validator"},
  {"id":"SVC-003","phase":"MS0","component":"managed-service-definition-validator"},
  {"id":"SVC-004","phase":"MS0","component":"managed-service-definition-validator"},
  {"id":"SVC-005","phase":"MS0","component":"managed-service-definition-validator"},
  {"id":"WIRE-007","phase":"RW0","component":"resolved-reentry-wire-validator"},
  {"id":"DRV-002","phase":"C0","component":"resolved-reentry-stage-constructor"},
  {"id":"DRV-003","phase":"D0","component":"prepared-launch-identity-validator"},
  {"id":"DRV-004","phase":"D0","component":"driver-entry-validator"}
]
```

All hook/test paths use `planned/<lowercase-id>/...`, all statuses remain
`planned`, diagnostics are secret-safe, and composition paths name only IDs
from Task 2.

- [ ] **Step 5: Extend the closed registry phase set**

Add `OC0`, `MS0`, and `RW0` to the registry validator's closed phase
vocabulary. Preserve the existing unknown-phase negative mutation so any
unregistered phase still fails.

- [ ] **Step 6: Add ten invalid witness catalog entries**

Extend `composition-invalid-witnesses.json` to exactly 50 entries. Each new
entry uses its invariant ID as `id`, its corpus invalid state as
`invalidState`, and `VAL-040`, `VAL-041`, or `VAL-042` as
`nearbyValidWitness`.

- [ ] **Step 7: Run registry and corpus validation**

Run:

```sh
docs/greenfield/research/invariants/test-registry.sh inventory
docs/greenfield/research/invariants/validate-registry.sh \
  inventory \
  docs/greenfield/research/invariants/invariants.json \
  docs/greenfield/research/CONFIGURATION-LANGUAGE-CORPUS.md
```

Expected: both commands exit 0 and report 140 registered invariants.

---

### Task 2: Replace the path registry with the exact 54-path universe

**Files:**

- Modify:
  `docs/greenfield/research/invariants/PACKET-D-COMPOSITION-PATHS.json`
- Modify:
  `docs/greenfield/research/invariants/test-composition-coverage.sh`
- Modify:
  `docs/greenfield/research/invariants/validate-composition-coverage.jq`

**Interfaces:**

- Consumes: the approved 54 path IDs, owner model, phase graph, and existing 42
  path records.
- Produces: one closed path registry with resource-qualified Artifact IDs, ten
  new declarative resource paths, and five unambiguous driver paths.

- [ ] **Step 1: Replace literal-universe tests before changing paths**

Define this exact path array in both the test and validator:

```jq
[
  "artifact-ordinary-authoring",
  "artifact-imports",
  "artifact-import-order",
  "artifact-profile-expansion",
  "artifact-explicit-override",
  "artifact-semantic-refinement",
  "artifact-strongest-override",
  "artifact-native-language-escape",
  "operator-configuration-authoring",
  "operator-configuration-imports",
  "operator-configuration-precedence",
  "operator-configuration-refinement",
  "operator-configuration-native-escape",
  "managed-service-definition-authoring",
  "managed-service-definition-imports",
  "managed-service-definition-precedence",
  "managed-service-definition-refinement",
  "managed-service-definition-native-escape",
  "resolved-driver-handoff",
  "serialized-resolved-reentry",
  "generated-runtime-configuration",
  "direct-driver-invocation",
  "raw-runtime-config-input"
]
```

Append the unchanged 31 non-replaced existing path IDs in their existing
relative order. Assert total length 54 and reject every old unqualified
Artifact or conflated driver ID.

- [ ] **Step 2: Run the focused test and confirm RED**

Run:

```sh
docs/greenfield/research/invariants/test-composition-coverage.sh
```

Expected: non-zero with a path-universe mismatch.

- [ ] **Step 3: Rename the eight Artifact paths and preserve aliases**

Rename first-class IDs only. Map historical registry aliases such as
`ordinary-authoring`, `imports`, and `strongest-override` to the corresponding
new `artifact-*` IDs.

- [ ] **Step 4: Add the five Operator and five Service source records**

Use these closed contracts:

```json
{
  "operator": {
    "sourceOwner": "operator",
    "reachableOwners": ["operator"],
    "firstBoundary": "operator-configuration-source-completion",
    "finalBoundary": "operator-configuration-validation",
    "targetApplicability": ["portable"],
    "delegatedPackets": ["E", "F"]
  },
  "service": {
    "sourceOwner": "service",
    "reachableOwners": ["service"],
    "firstBoundary": "managed-service-definition-source-completion",
    "finalBoundary": "managed-service-definition-validation",
    "targetApplicability": ["portable"],
    "delegatedPackets": ["E", "F"]
  }
}
```

Authoring/import paths allow `may-contribute`; precedence allows
`may-contribute`, `may-select`, and `may-narrow`; refinement allows
`may-select` and `may-narrow`; native escape allows only `no-authority`.
Frontend mappings are Nix-only and cite `NIX-MODULE-SYSTEM-2026-07-24`.

- [ ] **Step 5: Replace the three conflated driver records with five records**

Use exactly these effect sets:

```json
{
  "resolved-driver-handoff": ["may-contribute","may-narrow","no-authority"],
  "serialized-resolved-reentry": ["boundary-input","no-authority"],
  "generated-runtime-configuration": ["boundary-input","no-authority"],
  "direct-driver-invocation": ["no-authority"],
  "raw-runtime-config-input": ["no-authority"]
}
```

The two forbidden paths have `sourceOwner: "runtime"`,
`reachableOwners: []`, first/final boundary `driver-entry-validation`, and no
valid frontend mapping.

- [ ] **Step 6: Add `OC0`, `MS0`, and `RW0` reachability**

Add these directed edges without adding a cycle:

```json
{
  "P1": ["A0", "OC0", "MS0"],
  "OC0": ["O0"],
  "MS0": ["S0"],
  "RW0": ["C0"]
}
```

Preserve the existing `S0 -> C0 | L0 | E0 | T0` and
`C0 -> O0 -> H0 -> D0` branches.

- [ ] **Step 7: Validate closed records**

Run:

```sh
jq -e . docs/greenfield/research/invariants/PACKET-D-COMPOSITION-PATHS.json
docs/greenfield/research/invariants/test-composition-coverage.sh
```

Expected: JSON parsing passes; the focused test remains red only because the
case catalog/generator still represents the old universe.

---

### Task 3: Rebuild the independent case catalog and semantic relationship checks

**Files:**

- Modify:
  `docs/greenfield/research/invariants/PACKET-D-CASE-CONTRACTS.json`
- Modify:
  `docs/greenfield/research/invariants/test-composition-coverage.sh`
- Modify:
  `docs/greenfield/research/invariants/validate-composition-coverage.jq`

**Interfaces:**

- Consumes: 54 paths, 140 invariant owners, canonical native-handle contract,
  Packet C profiles, exact replay sets, Packet E/F taxonomy, and cross-path
  handoffs.
- Produces: one independently reviewed 140-character classification vector
  and one exact contract entry per path.

- [ ] **Step 1: Make the existing repair assertions target the new IDs**

Update the intentionally red `repaired-machine-contracts` assertion to use
`artifact-ordinary-authoring` and the five new driver paths. Change the invalid
witness assertion from 40 to exactly 50.

- [ ] **Step 2: Add semantic checks that cannot be replaced by a digest**

Add these validator predicates:

```jq
def active_effect:
  . == "may-contribute" or . == "may-narrow" or . == "may-select";

all(expanded_cells[];
  if (.allowedEffect | active_effect)
  then (.path.reachableOwners | index(.invariant.owner)) != null
  else true
  end
)
```

Also require:

```text
path targetApplicability -> exact targetProfileIds projection
CLI typed-request cells == framework typed-request cells
NAT-002/NAT-003 active or boundary-input -> canonical native handle contract
direct-driver-invocation/raw-runtime-config-input -> all 140 cells no-authority
serialized-resolved-reentry -> exact 89 built-load + 30 resolved replay sets
delegatedPackets -> exact delegatedConcernTaxonomy expansion
crossPathHandoffs -> existing source/target path and exact boundary IDs
```

- [ ] **Step 3: Define target applicability projection**

Use one shared semantic function:

```jq
def projected_profiles($applicability; $all):
  if ($applicability | index("portable")) != null then []
  elif ($applicability | index("all-packet-c-profiles")) != null then $all
  else
    [
      $applicability[] |
      select(. != "remote-provider")
    ] as $explicit |
    if ($explicit | length) == 0 and
       ($applicability | index("remote-provider")) != null
    then $all
    else $explicit
    end
  end;
```

`remote-provider` alone projects to all Packet C member profiles; when explicit
profile IDs coexist with it, the explicit IDs narrow the set. Therefore
`native-guest-module` projects to the two microVM profiles and
`oci-descriptor-transfer` to only `oci-linux-v1`.

- [ ] **Step 4: Define the two source contract templates**

Add:

```json
{
  "operator-source": {
    "firstSoundPhase": "P1",
    "rejectionDeadline": "OC0",
    "authority": {"phase":"OC0","component":"operator-configuration-validator"}
  },
  "managed-service-source": {
    "firstSoundPhase": "P1",
    "rejectionDeadline": "MS0",
    "authority": {"phase":"MS0","component":"managed-service-definition-validator"}
  }
}
```

Both chains begin at source semantics, include dependency/precedence/final
validation steps, and end at their resource validator. They never traverse
Artifact phases.

- [ ] **Step 5: Define the five driver contract templates**

Use:

```text
resolved-driver-handoff: C0 -> O0 -> H0 -> D0, private-type only
serialized-resolved-reentry: RW0 -> C0 -> O0 -> H0 -> D0, full replay
generated-runtime-configuration: D0 total generator -> D0 validator
direct-driver-invocation: D0 driver-entry rejection only
raw-runtime-config-input: D0 driver-entry rejection only
```

Forbidden-path `fullRevalidation` is false because no value is admitted.
Serialized reentry and generated configuration set it true.

- [ ] **Step 6: Walk every new path against all 140 invariants**

Apply these owner rules before mechanism-specific refinement:

```text
operator source paths: only operator-owned invariants may be C/N/S
service source paths: only service-owned invariants may be C/N/S
native escape paths: every cell is no-authority
forbidden driver paths: every cell is no-authority
```

For Operator/Service precedence and refinement, classify only the facts named
by their existing owner invariants and the new `OPS-*`/`SVC-*` rules. Do not
grant authority to Artifact, Create, live, Exec, framework, or runtime facts.

- [ ] **Step 7: Repair the previously found semantic defects**

Require:

```text
artifact-ordinary-authoring × XRS-007 = F
artifact-ordinary-authoring × XRS-008 = F
CLI and framework CRT-001..006, LIVE-001..004, EXE-001..007 cells equal
native-guest-module/target-native-extension carry native identity and total effect obligations
all active/boundary NAT-002/NAT-003 cells inherit the canonical conditional tuple
```

- [ ] **Step 8: Run the case-catalog mutation tests**

Run:

```sh
docs/greenfield/research/invariants/test-composition-coverage.sh
```

Expected: remain red only because generated coverage is stale; every direct
case-catalog mutation must fail for its named semantic reason.

---

### Task 4: Regenerate the 7,560-cell matrix without self-authorizing semantics

**Files:**

- Modify:
  `docs/greenfield/research/invariants/generate-composition-coverage.mjs`
- Regenerate:
  `docs/greenfield/research/invariants/PACKET-D-COMPOSITION-COVERAGE.json`
- Modify:
  `docs/greenfield/research/invariants/check-inventory.sh`

**Interfaces:**

- Consumes: the independently reviewed path registry and case catalog.
- Produces: 54 × 140 exact cells grouped only by identical complete structured
  contracts.

- [ ] **Step 1: Remove every literal 42-path assumption**

Replace:

```js
assert(pathIds.length === 42, "Packet D requires exactly 42 composition paths");
```

with:

```js
assert(
  pathIds.length === pathsDocument.reviewedPathCount &&
    pathsDocument.reviewedPathCount === 54,
  "Packet D path count must equal the approved 54-path registry",
);
```

Compute `expectedCellCount` as `pathIds.length * invariantIds.length`.

- [ ] **Step 2: Add the new phases and graph edges**

Add `OC0`, `MS0`, and `RW0` to phase identity/order data and use reachability,
not lexical phase order, to validate chains.

- [ ] **Step 3: Generate conditional native contracts per invariant cell**

For `NAT-002` and `NAT-003`, active/boundary-input cells use:

```js
{
  condition: { kind: "when-native-handle-present" },
  nativeHandleContract: contractsDocument.nativeHandleContract,
}
```

Other frontend/wire values retain `{kind:"all-values"}` and `null` native
contract. Native path entries require the tuple for all values.

- [ ] **Step 4: Copy normative taxonomy, replay, applicability, and handoffs**

The generated top level includes exact closed fields:

```json
{
  "delegatedConcernTaxonomy": {},
  "resolvedReentryReplay": {},
  "crossPathHandoffs": [],
  "targetApplicabilityProjection": {}
}
```

These values are copied from the reviewed catalog and independently compared
by the validator.

- [ ] **Step 5: Generate and run the focused suite**

Run:

```sh
node docs/greenfield/research/invariants/generate-composition-coverage.mjs
node docs/greenfield/research/invariants/generate-composition-coverage.mjs --check
docs/greenfield/research/invariants/test-composition-coverage.sh
```

Expected: generator check exits 0; focused suite exits 0; coverage reports
7,560 unique cells.

- [ ] **Step 6: Update exact digest pins only after semantic tests pass**

Compute:

```sh
shasum -a 256 \
  docs/greenfield/research/invariants/PACKET-D-COMPOSITION-PATHS.json \
  docs/greenfield/research/invariants/PACKET-D-CASE-CONTRACTS.json \
  docs/greenfield/research/invariants/invariants.json
```

Update the three validator/check-inventory pins. Keep prose explicit that
digests provide drift detection and review friction, not semantic authority.

---

### Task 5: Add Operator and Managed-Service Nix composition witnesses

**Files:**

- Create:
  `docs/greenfield/research/prototypes/nix-resource-composition/operator-module.nix`
- Create:
  `docs/greenfield/research/prototypes/nix-resource-composition/service-module.nix`
- Create:
  `docs/greenfield/research/prototypes/nix-resource-composition/cases.nix`
- Create:
  `docs/greenfield/research/prototypes/nix-resource-composition/test.sh`
- Modify:
  `docs/greenfield/research/prototypes/test-all.sh`
- Modify:
  `docs/greenfield/research/prototypes/PROTOTYPE-NOTES.md`

**Interfaces:**

- Consumes: the `OC0`/`MS0` contracts and pinned Nixpkgs already used by the
  prototype suite.
- Produces: real Nix module evaluation for valid and invalid Operator/Service
  source composition.

- [ ] **Step 1: Write a failing test runner**

The test table must name these exact cases:

```text
operator ordinary authoring
operator pinned import
operator precedence and contributor ledger
operator semantic narrowing
operator mkForce cannot widen hard ceiling
operator freeform/native escape rejected at OC0
operator mutable/unpinned dependency rejected
service ordinary authoring
service pinned import
service precedence and contributor ledger
service semantic narrowing
service mkForce cannot bypass typed Core API
service freeform/native escape rejected at MS0
service mutable/unpinned dependency rejected
```

Run the empty runner and confirm it fails because `cases.nix` is absent.

- [ ] **Step 2: Define closed Operator options and final assertions**

The module exposes only:

```nix
{
  drivers,
  providers,
  placementClasses,
  hardCeilings,
  credentialReferences,
  contributorLedger,
}
```

Assertions reject credential values, unknown/freeform fields, widened hard
ceilings, unregistered selections, incomplete contributors, and dependency
records without immutable source identity.

- [ ] **Step 3: Define closed Managed-Service options and final assertions**

The module exposes only:

```nix
{
  artifactReference,
  createRequest,
  desiredLifecycle,
  serviceMetadata,
  contributorLedger,
}
```

Assertions reject driver calls, raw runtime arguments, Artifact-policy fields,
untyped operations, incomplete contributors, and mutable dependencies.

- [ ] **Step 4: Represent every strongest bypass before final rejection**

Use actual module imports, `mkDefault`, `mkOverride`, `mkForce`, ordered
definitions, `_module.args`/freeform attempts, and delayed final assertions.
A parser/type error alone is not sufficient unless structural exclusion is the
claimed product mechanism.

- [ ] **Step 5: Run and integrate**

Run:

```sh
bash docs/greenfield/research/prototypes/nix-resource-composition/test.sh
```

Expected: all 14 named cases pass. Add the runner to `test-all.sh` immediately
after the strengthened Artifact Nix baseline.

---

### Task 6: Add resolved reentry and private driver-stage witnesses

**Files:**

- Create:
  `docs/greenfield/research/prototypes/resolved-reentry/Cargo.toml`
- Create:
  `docs/greenfield/research/prototypes/resolved-reentry/src/main.rs`
- Create:
  `docs/greenfield/research/prototypes/resolved-reentry/test.sh`
- Modify:
  `docs/greenfield/research/prototypes/downstream-boundaries/validate-resolved-driver.jq`
- Modify:
  `docs/greenfield/research/prototypes/downstream-boundaries/test.sh`
- Modify:
  `docs/greenfield/research/prototypes/test-all.sh`
- Modify:
  `docs/greenfield/research/prototypes/PROTOTYPE-NOTES.md`

**Interfaces:**

- Consumes: exact `RW0` envelope, 89+30 replay sets, and the
  `PreparedLaunch -> GeneratedRuntimeConfiguration` trust chain.
- Produces: executable proof that serialization never creates a private stage
  and raw/direct driver input has no accepted path.

- [ ] **Step 1: Write failing shell cases**

Require these exact cases:

```text
closed bounded resolved envelope
unknown/duplicate/oversize/deep/unsupported envelope rejection
authenticated envelope still revalidates semantics
89 built-load invariant replay set equality
30 resolved-stage invariant replay set equality
changed current admission invalidates cached candidate
serialized path/token cannot recreate retained handle
deterministic reconstruction creates a fresh PreparedLaunch
direct driver invocation rejected
raw runtime map and raw argument input rejected
generated configuration is total and closed
backend default omission rejected
post-generation corruption rejected
```

- [ ] **Step 2: Define separate public candidates and private stages**

Rust public deserialization targets only:

```rust
struct ResolvedReentryEnvelope { /* closed versioned candidate */ }
struct DecodedResolvedCandidate { /* still untrusted */ }
```

Keep constructors and fields private for:

```rust
struct ResolvedCreation { /* C0-owned */ }
struct AdmittedCreation { /* O0-owned */ }
struct PreparedLaunch { /* H0/D0-owned */ }
```

Only `revalidate_reentry(...) -> Result<PreparedLaunch, Diagnostic>` may
construct `PreparedLaunch`. The driver function accepts `PreparedLaunch`, not
`serde_json::Value`, a public record, or backend arguments.

- [ ] **Step 3: Encode exact replay-set constants**

The executable witness loads or embeds the exact 89 and 30 ID arrays and fails
when either array has a missing, extra, or duplicate ID.

- [ ] **Step 4: Extend generated configuration validation**

The downstream validator checks identity, profile, retained source, workspace,
network, resources, identity/security, devices, secrets, snapshots, output,
protocol versions, and explicit backend-default suppression. Unknown fields,
raw host paths, raw arguments, or implicit defaults fail `DRV-001`/`DRV-004`.

- [ ] **Step 5: Run and integrate**

Run:

```sh
bash docs/greenfield/research/prototypes/resolved-reentry/test.sh
bash docs/greenfield/research/prototypes/downstream-boundaries/test.sh
```

Expected: all named cases pass; add the new runner to `test-all.sh` before
downstream-boundary tests.

---

### Task 7: Integrate the corrected decision into the greenfield specification

**Files:**

- Modify:
  `docs/greenfield/DESIGN.md`
- Modify:
  `docs/greenfield/CONFIGURATION-BOUNDARY-AUDIT.md`
- Modify:
  `docs/greenfield/research/INVARIANT-ENFORCEMENT.md`
- Modify:
  `docs/greenfield/research/invariants/PACKET-D-COMPOSITION-REVIEW.md`
- Modify:
  `docs/greenfield/research/invariants/PACKET-D-RESEARCH-NOTES.md`
- Modify:
  `docs/greenfield/research/invariants/INVENTORY-REVIEW.md`
- Modify:
  `docs/greenfield/plans/2026-07-24-packet-d-composition-bypass-review.md`
- Modify:
  `docs/greenfield/research/prototypes/README.md`

**Interfaces:**

- Consumes: final machine counts, phase graph, replay sets, prototype totals,
  and review results.
- Produces: one non-contradictory product/spec narrative whose claims are
  reconstructable from machine records.

- [ ] **Step 1: Replace all stale 42×130/5,460 claims**

Use generated values from:

```sh
jq '{paths:(.pathIds|length), invariants:(.invariantIds|length), cells:.expectedCellCount, rules:(.rules|length)}' \
  docs/greenfield/research/invariants/PACKET-D-COMPOSITION-COVERAGE.json
```

Expected before review: 54 paths, 140 invariants, 7,560 cells.

- [ ] **Step 2: Integrate phases and resource-qualified paths**

Main design text must state:

```text
P1 -> A0/A1/W0 for Artifact
P1 -> OC0/O0 for Operator Configuration
P1 -> MS0/S0 for Managed-Service Definition
RW0 -> C0/O0/H0/D0 for serialized resolved reentry
```

- [ ] **Step 3: Correct provider and caller prose**

Provider transfer ends at H0/D0 and then enters `built-artifact-load` as a
separate C0 path; never write `H0 -> C0` as one phase chain. Framework and CLI
share typed Create/live/Exec translation. Teardown remains delegated to Packet
E rather than claimed by Packet D.

- [ ] **Step 4: Record exact evidence totals**

Read totals from the runners. Preserve Pkl 18 and Dhall 12. Do not copy old
counts from prose.

- [ ] **Step 5: Keep Packet D status candidate until independent review**

Set Packet D to:

```text
Candidate complete — corrected matrix and prototypes green; independent
cold-reader and adversarial sign-off pending
```

Do not mark `Reviewed` in this task.

---

### Task 8: Full verification and independent sign-off

**Files:**

- Verify all files under:
  `docs/greenfield/`
- Modify only after review:
  `docs/greenfield/research/invariants/PACKET-D-COMPOSITION-REVIEW.md`
- Modify only after review:
  `docs/greenfield/research/invariants/INVENTORY-REVIEW.md`

**Interfaces:**

- Consumes: completed Tasks 1–7.
- Produces: fresh evidence and an independently reviewed Packet D decision.

- [ ] **Step 1: Run structural checks**

```sh
find docs/greenfield -type f -name '*.json' -print0 |
  xargs -0 -n1 jq -e . >/dev/null
bash -n docs/greenfield/research/invariants/*.sh
bash -n docs/greenfield/research/prototypes/**/*.sh
node --check docs/greenfield/research/invariants/generate-composition-coverage.mjs
node docs/greenfield/research/invariants/generate-composition-coverage.mjs --check
```

Expected: all commands exit 0.

- [ ] **Step 2: Run the integrated inventory**

```sh
bash docs/greenfield/research/invariants/check-inventory.sh
```

Expected: exit 0 and report 54 paths × 140 invariants = 7,560 cells.

- [ ] **Step 3: Run the complete pinned prototype suite**

```sh
bash docs/greenfield/research/prototypes/test-all.sh
```

Expected: exit 0, including Operator/Service composition, resolved reentry,
Pkl 18, Dhall 12, and downstream driver boundaries.

- [ ] **Step 4: Confirm production closure remains honestly open**

```sh
bash docs/greenfield/research/invariants/check-enforcement-closure.sh
```

Expected: exit 5 only for `planned` production hooks/tests and missing Gate 4B
evidence. Any schema or registry error is a failure.

- [ ] **Step 5: Dispatch three fresh read-only reviews**

Require:

```text
1. Cold reconstruction: derive 54 paths, 140 invariants, 7,560 cells, phases,
   replay sets, profile projection, and handoffs using machine files only.
2. Adversarial semantics: attempt owner crossover, retroactive rejection,
   native identity omission, CLI divergence, provider phase cycle, and
   direct/raw driver admission.
3. Prototype evidence: verify original Nix/runtime mechanisms are represented
   before product-owned rejection and all reported counts match execution.
```

- [ ] **Step 6: Fix every Critical/Important finding and rerun affected reviews**

No severity is waived through prose. Material fixes rerun the focused,
integrated, and affected prototype suites.

- [ ] **Step 7: Mark Packet D reviewed only after sign-off**

Update status to `Reviewed`, record reviewer evidence, final digests, effect
counts, path/invariant/cell/rule totals, and the fact that Gate 2A remains open
only for Packets E and F.
