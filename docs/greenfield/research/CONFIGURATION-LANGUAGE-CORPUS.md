# Configuration-Language Executable Corpus

Status: **Locked comparison protocol; invariant inventory and fixture
implementation open**

This corpus is the common oracle for the Artifact authoring-language research.
Every candidate is compared against the same product invariants, ownership
boundaries, inputs, and observable outcomes.

The corpus is language-neutral. Names shown in examples are conceptual fixture
labels, not proposed public API, option, resource, command, or error-code names.

The corpus is paired with the normative
[Invariant Inventory and Enforcement Protocol](./INVARIANT-ENFORCEMENT.md).
Corpus cases define semantic witnesses; the machine-readable registry proves
that every invariant also has an owner, phase, disposition, enforcement hook,
test obligation, diagnostic contract, target scope, and bypass analysis. The
corpus is not considered exhaustive merely because its current cases are
locked. Gate 2A closes only after the protocol's complete state-space review.

## Purpose

The corpus answers a narrower question than "can this language express the
configuration?"

For each candidate it determines:

1. whether every supported construction path invokes the invariant;
2. the earliest phase at which all information needed by the invariant exists;
3. the actual phase at which the candidate rejects an invalid case;
4. whether a later composition step can bypass an earlier constraint;
5. whether the failure identifies the owner, values, definitions, and
   remediation;
6. whether valid advanced configurations retain required expressiveness;
7. whether the same normalized Artifact value reaches Nix construction.

The corpus does not reward an early parser error if the candidate merely makes
the valid form impossible to express. It does not penalize evaluation-time
validation when that is the earliest sound phase. It does penalize any value
that crosses its rejection deadline or is silently reinterpreted.

## Locked Owners

Every fixture and diagnostic has exactly one primary owner:

| Owner ID | Owner | Information controlled |
|---|---|---|
| `artifact` | Artifact Definition | Immutable content, hard policy, required capabilities, binding-slot contracts, supported target artifacts/profiles, target construction, native guest extensions |
| `create` | `CreateSandbox` | Artifact selection, runtime-profile selection, binding values, concrete allocations within Artifact bounds, creation-local lifecycle choices |
| `operator` | Operator Configuration | Driver/provider registration, hosts, credentials, infrastructure, capacity, placement, global limits |
| `service` | Managed-Service Definition | Declarative calls to the same Core Sandbox API; never a second lifecycle or policy authority |
| `live` | Live Sandbox operation | One operation against an existing Sandbox, within immutable bounds and advertised capabilities |
| `exec` | `Exec` input | One Process request inside an existing Sandbox; may narrow but never alter its isolation boundary |
| `framework` | Framework/CLI adapter | Agent lifecycle translation and tool routing; never Artifact environment or runtime policy |
| `runtime` | Core runtime/driver mechanism | Trusted decoding, resolution, preparation, supervision, conformance, cleanup, and evidence mechanisms; never caller policy |
| `core` | Core Sandbox API control plane | Durable Operation acceptance and records, identity and coordinate allocation, authority fencing, idempotency binding, terminal outcome commitment, retention and tombstones, and reconciliation; never a caller request surface and never a driver mechanism |

Framework, service, live, Exec, and runtime owners remain separate from
Artifact authoring. Their fixtures exercise the shared product boundary; they
are not added to the Artifact schema to make the corpus easier.

## Observable Product Phases

Language-internal terms such as "compile time," "runtime contract," and
"normalization" do not replace these product phases.

| Phase | Label | Complete information available |
|---|---|---|
| `P0` | Source parse | Candidate source grammar |
| `P1` | Source semantics | Candidate static types, contracts, imports, language-level composition |
| `OC0` | Operator Configuration validation | Complete Operator Configuration source semantics: hosts, drivers, credentials, capacity, admission policy, global ceilings, evidence sinks |
| `MS0` | Managed-Service Definition validation | Complete Managed-Sandbox Service Definition source semantics before any reconciliation |
| `A0` | Artifact normalization | Fully expanded profiles/defaults/imports and all Artifact-owned fields |
| `A1` | Artifact final validation | Complete normalized Artifact plus target-capability declarations and native-extension summaries |
| `W0` | Canonical-wire validation | Versioned, fully concrete, language-neutral Artifact value |
| `N0` | Nix construction evaluation | Validated Artifact value plus pinned Nix inputs, packages, derivations, dev shells, target constructors |
| `N1` | Nix build | Derivation builders execute in the Nix sandbox |
| `F0` | Framework/CLI translation | Framework or CLI request plus adapter-owned state before it becomes a Core Sandbox API operation |
| `S0` | Managed-service reconciliation | Declarative service state plus observed controller state before it becomes a Core Sandbox API operation |
| `RW0` | Serialized resolved reentry | A wholly untrusted serialized resolved-runtime envelope, before any private stage is reconstructed |
| `C0` | Creation resolution | Artifact manifest plus the complete resolved creation input for one launch |
| `O0` | Operator admission | Creation request plus operator policy, registered drivers/providers, capacity and placement model |
| `H0` | Host/provider preflight | Current host/provider capabilities, paths, quota, credentials, KVM/device state |
| `D0` | Driver preparation | Resolved target-specific runtime value before external mutation/launch |
| `R0` | Runtime launch | Sandbox process, container, VM, or remote instance starts |
| `R1` | Post-create conformance | Trusted probes of the created isolation boundary complete before untrusted work is accepted |
| `L0` | Live-operation validation | Existing Sandbox state, advertised capabilities, immutable bounds, and one live-operation request |
| `L1` | Live-operation mutation | A validated live operation may mutate the existing Sandbox |
| `E0` | Exec validation | Existing Sandbox state and bounds plus one complete `Exec` request |
| `E1` | Process launch | A validated Process starts inside the existing Sandbox |
| `T0` | Teardown and final evidence | Termination, cleanup, revocation, output collection, and final evidence |

The `C0` creation input may be a `CreateSandbox` request, a decoded serialized
resolved-reentry envelope arriving from `RW0`, or the durably recorded creation
selections replayed by a `StartSandbox` or same-Sandbox `RestoreSandbox`. `C0`
is the phase at which one launch's resolved input is complete; it does not
presuppose a `CreateSandbox` request.

These phases form a graph. `F0` and `S0` may feed create, live, Exec, or
teardown operations. Live and Exec are repeatable sibling branches after `R1`;
neither is globally ordered before the other. A rejection deadline must be
reachable from the first-sound phase on a valid path, not merely appear later
in this table.

### First-sound phase and rejection deadline

Each invalid fixture records:

- **first-sound phase** — the first phase with enough information to decide the
  invariant without guessing future inputs;
- **rejection deadline** — the latest phase at which rejection remains a
  correct product implementation.

A candidate may reject earlier than the first-sound product phase only because
its source representation structurally excludes the invalid state. That is
recorded as an ergonomics/correctness benefit, but the shared semantic
validator must still reject a corrupted canonical value by the deadline.

No candidate receives credit for requiring Artifact source to know
creation-time bindings, operator state, or host facts.

## Fixture Model

The implemented corpus will use one directory per case:

```text
cases/<case-id>/
  README.md
  artifact.<candidate-extension>
  canonical-input.json        # only for trust-boundary corruption cases
  create.json                 # only when CreateSandbox input is needed
  operator.json               # only when operator input is needed
  host.json                   # deterministic fake host/provider facts
  expected.json
```

The `.json` files are test-harness representations, not proposed public wire
schemas. The final wire encoding is decided by the ADR.

`expected.json` records:

```text
case identifier
valid or invalid
primary owner
first-sound phase
rejection deadline
invariant statement
required diagnostic paths
required related definitions
required remediation concept
normalized semantic digest for valid fixtures
allowed target outcomes
```

Candidate harnesses additionally capture:

```text
tool and pinned version
source hash
exact argv
working directory
environment allowlist
network availability
exit status
stdout bytes
stderr bytes
elapsed time
maximum resident memory
normalized output bytes
canonical output bytes and digest
diagnostic conversion result
```

## Structured Diagnostic Oracle

Human wording may differ. A conforming failure must be losslessly convertible
to a product diagnostic containing:

| Field | Requirement |
|---|---|
| fixture ID | Present in harness result; not necessarily public |
| invariant | Stable machine identity for the semantic rule |
| owner | Exactly one primary configuration owner |
| phase | Actual product phase |
| severity | Error for all invalid corpus cases |
| primary path | The field/resource that cannot be accepted |
| primary source span | File and line/column when the source language provides spans |
| related paths | Every field needed to understand a cross-field conflict |
| related definitions | Imported/default/profile/native sources that contributed |
| actual values | Secret-safe summary; secret values are never rendered |
| constraint | Bound, capability, policy, or ownership rule violated |
| remediation | Which owner may change what, without suggesting policy widening |
| cause chain | Preserved frontend/Nix/driver error without opaque string flattening |

For a failure across imports, pointing only at the final generated JSON or Nix
consumer is insufficient. For a trust-boundary corruption case with no author
source, the canonical input path is the valid primary location.

## Canonical-Output Oracle for Valid Cases

Every valid fixture must produce one semantic Artifact value independent of:

- candidate source-language field order;
- import order where composition is declared order-independent;
- whitespace and comments;
- map/object iteration order;
- frontend JSON formatting;
- absolute checkout path;
- online versus offline evaluation after all inputs are pinned.

The harness passes each candidate's fully concrete output through the same
product canonicalizer. It then compares:

1. canonical schema version;
2. semantic tree equality;
3. canonical bytes;
4. content digest;
5. target artifact identities excluding explicitly platform-dependent outputs;
6. field-level provenance as a separate, non-hashed explanation record.

The source language's serializer is never treated as canonical merely because
it emits JSON.

## Invalid Cases

### Structural Artifact invalidity

#### `STR-001` Relative filesystem destination

- Owner: `artifact`
- First-sound phase: `P1`
- Rejection deadline: `A1`
- Invariant: every workspace, immutable-input, mount-slot, scratch,
  persistent-volume, secret-file, and declared-output resource-root destination
  is normalized and absolute.
- Minimum witness: one resource-root destination is relative.
- Required diagnostic: destination path, contributing source, and an
  absolute-path remediation.
- Trust-boundary replay: inject the relative path directly at `W0`; it must be
  rejected before `N0`.

#### `STR-002` Duplicate logical slot identity

- Owner: `artifact`
- First-sound phase: `A0`
- Rejection deadline: `A1`
- Invariant: binding-slot identities are unique after all imports and profiles
  expand.
- Minimum witness: two modules define the same logical slot with otherwise
  compatible values.
- Required diagnostic: both definitions, not only the second occurrence.

#### `STR-003` Malformed quantity

- Owner: `artifact`
- First-sound phase: `P1`
- Rejection deadline: `A1`
- Invariant: byte quantities and durations normalize to bounded,
  unit-explicit values; implicit or malformed units are forbidden.
- Minimum witness: one malformed memory quantity and one malformed duration,
  executed as subcases.
- Required diagnostic: original token, expected dimensional form, and field
  path.

#### `STR-004` Secret or provider value in immutable input

- Owner: `artifact`
- First-sound phase: `P1`
- Rejection deadline: `W0`
- Invariant: Artifact Definitions contain secret-slot contracts only, never
  secret or provider references, provider or account identities, lookup
  expressions, values, or value-derived hashes.
- Minimum witness: a literal value or provider reference where a slot
  descriptor is expected.
- Required diagnostic: the value must be redacted; remediation identifies
  `CreateSandbox`/operator delivery without naming a credential.
- Nix assertion: no secret material occurs in evaluated Nix values, derivation
  arguments, store paths, logs, or canonical bytes.

#### `STR-005` Ambiguous activation or default entry command

- Owner: `artifact`
- First-sound phase: `P1`
- Rejection deadline: `A1`
- Invariant: every activation or Artifact-default entry command is a non-empty
  argv; activation is explicitly ordered, and neither field accepts a shell
  string or implicit interactive `shellHook`.
- Minimum witness: empty argv, a shell string, or an imported interactive hook.
- Required diagnostic: path, contributing source, and the explicit ordered-argv
  requirement.

#### `STR-006` Unknown capability identity

- Owner: `artifact`
- First-sound phase: `P1`
- Rejection deadline: `A1`
- Invariant: required and provided capabilities come from the canonical schema
  version's closed capability vocabulary or a separately namespaced extension
  contract.
- Minimum witness: misspelled built-in capability.
- Required diagnostic: unknown identity, schema version, and valid extension
  mechanism; no silent ignore.

#### `STR-007` Unsupported schema version

- Owner: `artifact`
- First-sound phase: `P1`
- Rejection deadline: `W0`
- Invariant: schema major versions are explicit and unsupported majors never
  downgrade or fall back.
- Minimum witness: future unknown major.
- Required diagnostic: supported version range and migration direction.

#### `STR-008` Undeclared field

- Owner: `artifact`
- First-sound phase: `P1`
- Rejection deadline: `A1`
- Invariant: portable Artifact records are closed except at explicit,
  namespaced extension points.
- Minimum witness: one typo adjacent to a valid field.
- Required diagnostic: exact unknown field and nearest valid location; no value
  passthrough.

### Sum-type Artifact invalidity

#### `SUM-001` Invalid workspace materialization contract

- Owner: `artifact`
- First-sound phase: `P1`
- Rejection deadline: `A1`
- Invariant: a workspace declares either one mandatory materialization or a
  non-empty set of permitted alternatives, contains no fields from multiple
  concrete source alternatives, and never makes the creation-time selection.
- Minimum witness: live-share and copy-in source fields coexist inside one
  alternative, or the Artifact selects one permitted alternative for a run.
- Required diagnostic: the conflicting members and the boundary between
  Artifact permission and Create-time selection.

#### `SUM-002` Ephemeral and externally named storage

- Owner: `artifact`
- First-sound phase: `P1`
- Rejection deadline: `A1`
- Invariant: ephemeral storage and externally identified persistent storage are
  distinct alternatives.
- Minimum witness: ephemeral lifecycle plus external storage identity.

#### `SUM-003` Incomplete memory-snapshot semantics

- Owner: `artifact`
- First-sound phase: `A0`
- Rejection deadline: `A1`
- Invariant: a memory snapshot declares the required treatment of device and
  externally held state.
- Minimum witness: memory included while external/device state behavior is
  absent.
- Required diagnostic: missing semantic decision, not a backend-specific flag.

#### `SUM-004` Network disabled with egress allowlist

- Owner: `artifact`
- First-sound phase: `P1`
- Rejection deadline: `A1`
- Invariant: a disabled network has no egress rules, DNS policy, proxy slot, or
  network credential dependency.
- Minimum witness: network disabled plus one allowed destination.
- Required diagnostic: both mode and incompatible subordinate policy.

#### `SUM-005` Immutable and writable volume

- Owner: `artifact`
- First-sound phase: `P1`
- Rejection deadline: `A1`
- Invariant: immutable artifact content and runtime writable storage are
  different resource kinds.
- Minimum witness: one logical volume claims both roles.

### Cross-resource and ownership invalidity

#### `XRS-001` Allocation below Artifact minimum

- Owner: `create`
- First-sound phase: `C0`
- Rejection deadline: `C0`
- Invariant: a creation allocation lies within Artifact-declared bounds.
- Minimum witness: valid Artifact minimum plus smaller requested allocation.
- Required diagnostic: Artifact bound, requested value, and `create` owner.
- Prohibition: Artifact authoring must not require a concrete allocation to
  reject this case.

#### `XRS-002` Creation access widens hard policy

- Owner: `create`
- First-sound phase: `C0`
- Rejection deadline: `C0`
- Invariant: creation-time values may select/refine permitted access but never
  widen Artifact hard policy.
- Minimum witness: Artifact offline/denied policy plus requested external
  egress.
- Required diagnostic: requested widening and immutable upper bound; remediation
  must not suggest an override.

#### `XRS-003` Read-only workspace resolves writable

- Owner: `create`
- First-sound phase: `C0`
- Rejection deadline: `D0`
- Invariant: binding resolution preserves or narrows declared access.
- Minimum witness: read-only workspace contract plus writable live
  share/device.
- Required diagnostics at both `C0` and defensive `D0` trust boundaries.

#### `XRS-004` Secret delivery targets immutable output

- Owner: `create`
- First-sound phase: `C0`
- Rejection deadline: `D0`
- Invariant: secret material is delivered only through declared ephemeral
  runtime channels, never a Nix store path, immutable image layer, or Artifact
  content field.
- Minimum witness: valid secret slot plus immutable-image delivery target.
- Required diagnostic: redacted slot identity and prohibited channel.

#### `XRS-005` Runtime host path in Artifact

- Owner: `artifact`
- First-sound phase: `P1`
- Rejection deadline: `A1`
- Invariant: Artifact Definitions declare binding slots and in-sandbox
  destinations, not current host source paths.
- Minimum witness: absolute host source path embedded in Artifact source.
- Required diagnostic: boundary explanation and `CreateSandbox` binding owner.

#### `XRS-006` Provider credential in creation input

- Owner: `operator`
- First-sound phase: `C0`
- Rejection deadline: `O0`
- Invariant: provider/host credentials are operator configuration, referenced
  indirectly by creations.
- Minimum witness: creation request contains provider token/value.
- Required diagnostic: redact value; distinguish provider selection from
  provider credential ownership.

#### `XRS-007` Framework lifecycle in Artifact

- Owner: `framework`
- First-sound phase: `P1`
- Rejection deadline: `A1`
- Invariant: agent install/run/trajectory hooks and framework retry/lifecycle
  behavior belong to adapters, not immutable sandbox Artifact definition.
- Minimum witness: Artifact attempts to define a post-agent-run hook.
- Required diagnostic: identify the framework boundary; do not invent a generic
  Artifact lifecycle abstraction.

#### `XRS-008` Operator driver settings in Artifact

- Owner: `operator`
- First-sound phase: `P1`
- Rejection deadline: `A1`
- Invariant: driver binary paths, sockets, credentials, capacity, placement,
  and global timeouts are operator configuration.
- Minimum witness: Artifact sets a concrete VMM binary path or remote-provider
  endpoint.

### Cross-target invalidity

#### `TGT-001` Artifact requires live workspace but only Firecracker is supported

- Owner: `artifact`
- First-sound phase: `A0`
- Rejection deadline: `A1`
- Invariant: every enabled Artifact target/profile satisfies every mandatory
  portable requirement.
- Minimum witness: mandatory live shared workspace and only a target profile
  whose declared capability set lacks that materialization.
- Required diagnostic: requirement, target/profile, missing capability, and
  both contributing source locations.
- Prohibition: this may not survive until VM launch.

#### `TGT-002` Creation selects Firecracker with live binding

- Owner: `create`
- First-sound phase: `C0`
- Rejection deadline: `C0`
- Invariant: selected runtime profile and concrete bindings form one supported
  combination advertised by the Artifact.
- Minimum witness: Artifact permits copy-in and live materializations across
  different supported profiles; creation chooses the incompatible pair.
- Required diagnostic: Artifact itself remains valid; blame the selection, not
  the target declaration.

#### `TGT-003` Runtime-profile support claim lacks member-bound evidence

- Owner: `artifact`
- First-sound phase: `N1`
- Rejection deadline: `C0`
- Invariant: a built target member may advertise support for a required
  capability only when builder-produced evidence proves that its runtime
  profile passed the applicable versioned conformance suite.
- Minimum witness: a member claims a runtime profile because its executable
  has the expected version, but builder evidence does not cover the exact
  member, companion components, build features, suppressed defaults, and
  applicable conformance-suite result. A non-setuid Bubblewrap profile paired
  with a setuid build is one concrete witness.
- Required diagnostic: target member, runtime profile, required capability,
  complete expected component/profile identity, expected suite/version, and
  missing, mismatched, or failed builder evidence.

#### `TGT-004` Mandatory capability absent from one enabled target

- Owner: `artifact`
- First-sound phase: `A0`
- Rejection deadline: `A1`
- Invariant: mandatory portable semantics are supported by every enabled
  target; intentionally different common semantics require separate named
  Artifact Definitions with distinct semantic identities.
- Minimum witness: two targets, one missing a mandatory capability.
- Required diagnostic: all affected targets and the option to split behavior
  into separate named Artifact Definitions rather than silently degrade.

#### `TGT-005` Native target configuration contradicts common network policy

- Owner: `artifact`
- First-sound phase: `A1`
- Rejection deadline: `N0`
- Invariant: target-native additions may refine implementation details but may
  not contradict portable hard policy.
- Minimum witness: common network disabled; native target config adds a network
  interface or egress path.
- Required diagnostic: common policy and native definition source.

#### `TGT-006` Target ignores required resource ceiling

- Owner: `artifact`
- First-sound phase: `A1`
- Rejection deadline: `N0`
- Invariant: enabled targets must enforce every required ceiling or reject the
  Artifact; unsupported ceilings are never warnings/no-ops.
- Minimum witness: target lowerer lacks enforcement for a required resource
  ceiling.

#### `TGT-007` Target-specific addition changes common environment

- Owner: `artifact`
- First-sound phase: `A1`
- Rejection deadline: `N0`
- Invariant: target-specific additions may add target machinery but may not
  change the common user environment's package, variable, activation, user, or
  workspace semantics.
- Minimum witness: one target-native module replaces a common environment
  variable or activation entry.

#### `TGT-008` No supported target remains

- Owner: `artifact`
- First-sound phase: `A0`
- Rejection deadline: `A1`
- Invariant: the normalized Artifact produces at least one explicitly named
  usable target artifact/runtime profile.
- Minimum witness: profile refinements eliminate every declared target.
- Required diagnostic: elimination reasons per target; no implicit backend.

### Composition invalidity

#### `CMP-001` Imported workspace conflict

- Owner: `artifact`
- First-sound phase: `P1`
- Rejection deadline: `A1`
- Invariant: order-independent composition of incompatible concrete workspace
  requirements fails rather than choosing one.
- Minimum witness: two imports select incompatible materializations at equal
  authority.
- Required diagnostic: both import locations and composition path.

#### `CMP-002` Later module weakens hard network policy

- Owner: `artifact`
- First-sound phase: `P1`
- Rejection deadline: `A1`
- Invariant: hard-policy composition is monotonic refinement. The final
  semantic authority compares the normalized value with an independently
  preserved immutable bound and contribution ledger, so a source-language
  force/priority/preference/update operator cannot erase the bound and then
  present the widened result as valid.
- Minimum witness: base allows no egress; later composition allows one
  destination. For Nix, the witness includes an override priority stronger
  than `mkForce`, such as `mkOverride (-1)`, that removes the lower-priority
  definition before ordinary final-value validation.
- Candidate obligation: exercise the strongest author-accessible override
  mechanism, not only ordinary merge.

#### `CMP-003` Profile conflicts with explicit field

- Owner: `artifact`
- First-sound phase: `A0`
- Rejection deadline: `A1`
- Invariant: profile expansion is visible and deterministic; an incompatible
  explicit value produces a conflict unless the profile contract explicitly
  marks that field as a replaceable default.
- Minimum witness: selected profile and explicit field disagree.
- Required diagnostic: expanded profile origin, explicit origin, and declared
  precedence/refinement rule.

#### `CMP-004` Slot types conflict across imports

- Owner: `artifact`
- First-sound phase: `P1`
- Rejection deadline: `A1`
- Invariant: the same logical slot cannot have incompatible binding kinds,
  cardinalities, delivery channels, or access contracts.
- Minimum witness: same slot identity, two incompatible kinds.

#### `CMP-005` Guest module claims host/runtime ownership

- Owner: `artifact`
- First-sound phase: `A1`
- Rejection deadline: `N0`
- Invariant: a native guest NixOS module may configure guest services and
  in-guest state only; it cannot define host shares, host network interfaces,
  VMM processes, provider resources, credentials, or runtime allocations.
- Minimum witness: guest module attempts to configure a host share/interface.
- Required diagnostic: native Nix declaration location and prohibited owner.

#### `CMP-006` Unsafe extension claims full conformance

- Owner: `artifact`
- First-sound phase: `A1`
- Rejection deadline: `W0`
- Invariant: unvalidated namespaced/native extensions are explicitly unsafe or
  partial and cannot mint built-in capability/conformance claims.
- Minimum witness: opaque extension asserts a standard capability identity.

#### `CMP-007` Import-order changes semantic result

- Owner: `artifact`
- First-sound phase: `P1`
- Rejection deadline: `A1`
- Invariant: composition declared order-independent produces the same result
  and provenance regardless of import order.
- Minimum witness: two compatible refinements evaluated in both orders.
- Failure condition: differing semantic result, hidden winner, or differing
  hard-policy bound.

#### `CMP-008` Override bypasses final validator

- Owner: `artifact`
- First-sound phase: `A1`
- Rejection deadline: `W0`
- Invariant: no language-native escape hatch can make an invalid normalized
  value cross the canonical boundary.
- Minimum witness: use Nix `mkOverride`/Nickel `force`/Dhall `//` or `with`/Pkl
  openness or amendment/any comparable CUE embedding edge to bypass an earlier
  rule.
- Required result: either the supported API makes the expression unavailable
  or final validation rejects the result.

#### `CMP-009` Frontend dependency closure is mutable or incomplete

- Owner: `artifact`
- First-sound phase: `P1`
- Rejection deadline: `W0`
- Invariant: every semantic import, module, resource, external reader, and
  fallback is included in one transitively immutable, content-pinned,
  provenance-recorded dependency closure that evaluates offline
  deterministically.
- Minimum witness: an environment/search-path import, unhashed network import,
  Pkl external reader, Nickel foreign import, Dhall fallback, or Nix source
  dependency changes the normalized Artifact without changing the recorded
  dependency identity.
- Required result: unsupported ambient inputs are unavailable; supported
  inputs are pinned and a changed transitive dependency changes identity or is
  rejected before canonical publication.

#### `CMP-010` Composition provenance is incomplete

- Owner: `artifact`
- First-sound phase: `A1`
- Rejection deadline: `W0`
- Invariant: normalized composition provenance records every winning, losing,
  default, profile, import, override, native, and migration contributor with
  immutable identity and semantic role; non-semantic source spans and display
  ordering remain outside the semantic digest.
- Minimum witness: an override discards the losing hard-policy definition and
  the emitted provenance records only the winner, or reversed order changes
  the contributor set.
- Required diagnostic: identify the missing contributor class and the
  affected semantic field without making source spans part of Artifact
  identity.

#### `CMP-011` Extension effect projection is incomplete

- Owner: `artifact`
- First-sound phase: `A1`
- Rejection deadline: `N0`
- Invariant: every extension used by a conforming Artifact has a registered,
  versioned, closed contract and a total product-derived effect projection
  into the common field/profile and identity models; opaque or unprojectable
  effects cannot produce conforming Artifact, member, capability, or evidence
  types.
- Minimum witness: a native or namespaced extension changes one target's
  environment, runtime configuration, or bytes while omitting the applicable
  Packet C field/profile obligation or affected identity domain.
- Required result: reject the extension or classify its output as a distinct
  explicitly non-conforming type; a boolean `unsafe` flag cannot authorize
  ordinary conformance claims.

### Canonical and trust-boundary invalidity

#### `WIRE-001` Duplicate canonical object key

- Owner: `artifact`
- First-sound phase: `W0`
- Rejection deadline: `W0`
- Invariant: canonical decoding rejects duplicate keys before semantic
  interpretation.

#### `WIRE-002` Non-canonical equivalent encoding

- Owner: `artifact`
- First-sound phase: `W0`
- Rejection deadline: `W0`
- Invariant: semantically equal source values map to one canonical byte string;
  a non-canonical incoming encoding is normalized or rejected according to the
  eventual wire ADR, never hashed as a distinct Artifact.

#### `WIRE-003` Corrupted frontend output

- Owner: `artifact`
- First-sound phase: `W0`
- Rejection deadline: `W0`
- Invariant: the canonical boundary independently rejects a structurally valid
  but semantically invalid value even if a frontend compiler is buggy.
- Minimum witness: direct canonical input for `SUM-004`.
- Architectural constraint: the shared product semantic implementation is
  reused, not manually duplicated.

#### `WIRE-004` Source-language value leaks to driver

- Owner: `artifact`
- First-sound phase: `W0`
- Rejection deadline: `D0`
- Invariant: runtime drivers receive generated target-specific product types,
  never CUE/Nickel/Dhall/Pkl/Nix evaluator values or untyped generic maps.

#### `WIRE-005` Frontend translation is lossy or permissive

- Owner: `artifact`
- First-sound phase: `W0`
- Rejection deadline: `W0`
- Invariant: every renderer-to-wire adaptation is versioned and total over the
  semantic schema and fails closed on unknown, omitted, unserializable,
  rounded, duplicated, or reinterpreted values.
- Minimum witness: a frontend emits an extra semantic field that the adapter
  silently projects away, allowing the reduced value to pass validation.
- Required result: the adaptation rejects before canonicalization and names
  the unsupported or lossy path.

#### `WIRE-006` Canonical decoding is unbounded or accepts an invalid domain

- Owner: `artifact`
- First-sound phase: `W0`
- Rejection deadline: `W0`
- Invariant: canonical decoding rejects malformed syntax, trailing bytes,
  invalid UTF-8, unsupported numeric or Unicode representations, excessive
  nesting, and oversized input before semantic interpretation.
- Atomic ownership: `WIRE-001` owns duplicate-object-key rejection;
  `WIRE-006` owns the remaining bounded decoder and accepted-domain contract.
- Minimum witness: one nearby valid document for each configured resource
  bound plus a malformed, trailing, invalid-domain, over-depth, and over-size
  document.
- Required result: deterministic structured rejection without partial
  interpretation or implementation-dependent coercion.

#### `WIRE-007` Serialized resolved-stage envelope is open or ambiguously decoded

- Owner: `runtime`
- First-sound phase: `RW0`
- Rejection deadline: `RW0`
- Invariant: a serialized resolved-stage envelope is open, unbounded,
  ambiguously decoded, unsupported, or accepted without strict versioned
  decoding.
- Required result: accept only the bounded, closed, versioned reentry envelope
  and treat every decoded value as an untrusted candidate for full replay.

#### `MIG-001` Schema migration is ambiguous or non-idempotent

- Owner: `artifact`
- First-sound phase: `W0`
- Rejection deadline: `W0`
- Invariant: each supported old schema version has one versioned,
  deterministic migration that validates old input first, preserves or
  explicitly rejects extension data, validates the current result, and is
  idempotent; downgrade, fallback chains, and frontend-owned migration are
  forbidden.
- Minimum witness: the same old input takes two migration paths, silently
  loses extension data, changes on a second migration, or falls back to an
  older interpretation after current validation fails.
- Required result: one current canonical value or a structured migration
  rejection naming the source and target versions.

### Operator and host invalidity

These cases ensure the authoring language does not absorb facts it cannot know.

#### `OPS-001` Requested runtime profile has no registered driver

- Owner: `operator`
- First-sound phase: `O0`
- Rejection deadline: `O0`
- Invariant: Artifact support is not proof that the current operator provides a
  matching driver.
- Required diagnostic: selected profile and missing registration; Artifact
  remains valid.

#### `OPS-002` Operator maximum below Artifact minimum

- Owner: `operator`
- First-sound phase: `O0`
- Rejection deadline: `O0`
- Invariant: placement is rejected when operator bounds and Artifact bounds
  have an empty intersection.

#### `OPS-003` Operator Configuration dependency closure is mutable or incomplete

- Owner: `operator`
- First-sound phase: `P1`
- Rejection deadline: `OC0`
- Invariant: Operator Configuration dependency closure is mutable, incomplete,
  ambient, or not reproducible offline.
- Required result: pin and close the complete dependency graph, evaluate
  without ambient inputs, and reject it before Operator admission.

#### `OPS-004` Operator Configuration precedence or provenance is ambiguous

- Owner: `operator`
- First-sound phase: `P1`
- Rejection deadline: `OC0`
- Invariant: Operator composition precedence or contributor provenance is
  ambiguous, incomplete, or permits a force-class bypass.
- Required result: retain the complete ordered contributor ledger and reject
  ambiguous, undeclared, or force-class policy bypasses at final validation.

#### `OPS-005` Operator Configuration escapes final validation

- Owner: `operator`
- First-sound phase: `P1`
- Rejection deadline: `OC0`
- Invariant: a native/freeform source escape constructs validated Operator
  Configuration without the `OC0` validator.
- Required result: native/freeform input may describe a candidate only; `OC0`
  is the sole constructor of a validated Operator Configuration.

#### `HOST-001` KVM unavailable

- Owner: `operator`
- First-sound phase: `H0`
- Rejection deadline: `H0`
- Invariant: current virtualization capability is preflight state, not Artifact
  source input.
- Required diagnostic: host/provider fact and selected profile; no fallback to
  another backend.

#### `HOST-002` Bound host path absent

- Owner: `create`
- First-sound phase: `H0`
- Rejection deadline: `H0`
- Invariant: a concrete path binding is checked on the selected host before
  driver mutation.

#### `HOST-003` Provider quota or credentials invalid

- Owner: `operator`
- First-sound phase: `H0`
- Rejection deadline: `H0`
- Invariant: mutable provider state fails as an operator/preflight diagnostic,
  not as an Artifact validation error.
- Required diagnostic: credential value redacted.

#### `DRV-001` Driver receives value outside resolved constraints

- Owner: `runtime`
- First-sound phase: `D0`
- Rejection deadline: `D0`
- Invariant: drivers defensively validate complete generated resolved types,
  emit total target configuration that suppresses every undeclared backend
  default, and never use best-effort, try/fallback, raw-hook, or implicit
  inheritance behavior.
- Minimum witnesses:
  - harness-corrupted resolved value below the Artifact minimum;
  - Bubblewrap `--unshare-all` or a `*-try` operation for a required namespace;
  - omitted OCI runtime fields that reactivate image or runtime defaults;
  - VMM configuration inheriting an undeclared device, nested virtualization,
    console, host path, interface, or helper.

#### `DRV-002` Reentry mints a private validated runtime stage

- Owner: `runtime`
- First-sound phase: `RW0`
- Rejection deadline: `C0`
- Invariant: deserialization, copying, a cache hit, or a foreign object mints
  a private validated runtime stage.
- Required result: construct a fresh private stage only through the product
  `C0` constructor after strict decoding and complete replay.

#### `DRV-003` PreparedLaunch identity fails to rederive upstream bindings

- Owner: `runtime`
- First-sound phase: `H0`
- Rejection deadline: `D0`
- Invariant: `PreparedLaunch` identity omits or fails to rederive an earlier
  product identity, registration, admission, or retained-object binding.
- Required result: extend and rederive identity across every earlier
  product-owned stage and current retained-object acquisition before driver
  preparation.

#### `DRV-004` Driver accepts non-private or raw configuration input

- Owner: `runtime`
- First-sound phase: `D0`
- Rejection deadline: `D0`
- Invariant: a driver accepts anything other than the product-owned private
  `PreparedLaunch` stage or accepts raw/backend-default configuration as input.
- Required result: admit only product-owned private `PreparedLaunch` values
  and reject direct, raw, copied, deserialized, or backend-default input before
  external mutation.

### Built Artifact and manifest invalidity

#### `MAN-001` Manifest identity does not match Artifact content

- Owner: `artifact`
- First-sound phase: `N1`
- Rejection deadline: `C0`
- Invariant: every target member, manifest, and referenced immutable output
  agrees with the Artifact Set identity and recorded content digests.
- Minimum witness: a valid built target member paired with a manifest whose
  content digest names a different output.
- Required diagnostic: Artifact reference, target member, expected and observed
  digest; no attempt to rebuild or substitute a different member.

#### `MAN-002` Unsupported target or guest protocol in built manifest

- Owner: `artifact`
- First-sound phase: `N1`
- Rejection deadline: `C0`
- Invariant: a built manifest names only registered target, driver-contract,
  guest-runtime, and evidence protocol versions; unsupported required versions
  never fall back.
- Minimum witness: a structurally valid manifest with a future required guest
  protocol major.
- Required diagnostic: unsupported identity/version and supported range while
  leaving the Artifact bytes untrusted.

#### `MAN-003` Secret or provider reference appears in built manifest

- Owner: `artifact`
- First-sound phase: `N1`
- Rejection deadline: `C0`
- Invariant: built manifests contain secret-slot contracts only and never
  secret values, provider secret references, account identifiers, or
  value-derived hashes.
- Minimum witness: inject a provider secret reference into an otherwise valid
  target manifest.
- Required diagnostic: redact the value and identify the Artifact build as
  invalid; do not reinterpret it as a runtime binding.

### `CreateSandbox` request invalidity

#### `CRT-001` Required binding is absent

- Owner: `create`
- First-sound phase: `C0`
- Rejection deadline: `C0`
- Invariant: every required Artifact binding slot has exactly the required
  cardinality in the creation request before allocation begins.
- Minimum witness: omit the required workspace binding from a valid Artifact.
- Required diagnostic: slot identity, binding kind, required cardinality, and
  `create` ownership.

#### `CRT-002` Binding is undeclared or has an incompatible kind

- Owner: `create`
- First-sound phase: `C0`
- Rejection deadline: `C0`
- Invariant: each creation binding resolves one declared Artifact slot and
  matches its kind, destination, access, delivery, and audience contract.
- Minimum witness: bind a volume to an undeclared secret slot identity.
- Required diagnostic: binding and nearest declared slot contracts; no
  best-effort conversion between kinds.

#### `CRT-003` Single-cardinality slot is bound more than once

- Owner: `create`
- First-sound phase: `C0`
- Rejection deadline: `C0`
- Invariant: binding cardinality is checked after API decoding and before
  resource resolution; duplicate bindings never use first- or last-wins.
- Minimum witness: two workspace sources bind the same single-cardinality slot.
- Required diagnostic: both request locations and the slot declaration.

#### `CRT-004` Idempotency key is reused with different semantics

- Owner: `create`
- First-sound phase: `C0`
- Rejection deadline: `C0`
- Invariant: one caller/idempotency-key scope identifies one canonical creation
  request; replay with different Artifact, target, bindings, allocations, or
  lifecycle semantics conflicts instead of creating or returning another
  Sandbox.
- Minimum witness: repeat a successful key with a different Artifact reference.
- Required diagnostic: key fingerprint and conflicting request fields without
  exposing secret binding values.

#### `CRT-005` Requested target or runtime profile is absent from the Artifact

- Owner: `create`
- First-sound phase: `C0`
- Rejection deadline: `C0`
- Invariant: a creation selects exactly one target member and runtime profile
  explicitly advertised by the referenced Artifact.
- Minimum witness: request an OCI member from an Artifact containing only
  bubblewrap and Firecracker members.
- Required diagnostic: requested identity and complete available identities;
  no implicit backend substitution.

#### `CRT-006` Initial process bypasses the Exec contract

- Owner: `create`
- First-sound phase: `C0`
- Rejection deadline: `C0`
- Invariant: when creation includes an initial Process, its argv, environment,
  identity, secrets, PTY, timeout, and output semantics use the same validated
  Process contract as `Exec`; Create does not define a weaker command channel.
- Minimum witness: an initial process uses a shell string where Exec requires a
  non-empty argv.
- Required diagnostic: nested Process field and shared Exec rule.

### Managed-service invalidity

#### `SVC-001` Managed service invents a second sandbox policy

- Owner: `service`
- First-sound phase: `S0`
- Rejection deadline: `S0`
- Invariant: a Managed-Sandbox Service Definition owns desired reconciliation
  and lifecycle choices but expresses sandbox policy only through the same
  Artifact and Core Sandbox API request fields as every other caller.
- Minimum witness: service-only option widens network or filesystem authority
  without a corresponding valid Core Sandbox API field.
- Required diagnostic: service field, canonical API owner, and immutable
  Artifact bound.

#### `SVC-002` Managed service invokes a driver outside the Core API

- Owner: `service`
- First-sound phase: `S0`
- Rejection deadline: `S0`
- Invariant: the supported managed-service controller reaches drivers only
  through the Core Sandbox API and cannot create a second lifecycle,
  validation, identity, or evidence path.
- Minimum witness: generated service unit invokes a VMM, bubblewrap, OCI
  runtime, or provider client directly.
- Required result: the supported service compiler makes the direct driver path
  unavailable and architecture tests reject a generated unit that bypasses the
  API.

#### `SVC-003` Managed-Service Definition dependency closure is mutable or incomplete

- Owner: `service`
- First-sound phase: `P1`
- Rejection deadline: `MS0`
- Invariant: Managed-Service Definition dependency closure is mutable,
  incomplete, ambient, or not reproducible offline.
- Required result: pin and close the complete service dependency graph,
  evaluate without ambient inputs, and reject it before service translation.

#### `SVC-004` Service precedence or provenance is ambiguous

- Owner: `service`
- First-sound phase: `P1`
- Rejection deadline: `MS0`
- Invariant: Service composition precedence or contributor provenance is
  ambiguous, incomplete, or permits a force-class bypass.
- Required result: retain the complete ordered contributor ledger and reject
  ambiguous, undeclared, or force-class service bypasses at final validation.

#### `SVC-005` Managed-Service Definition escapes final validation or the Core API

- Owner: `service`
- First-sound phase: `P1`
- Rejection deadline: `MS0`
- Invariant: a native/freeform source escape constructs a validated
  Managed-Service Definition or direct driver action without `MS0` and the
  typed Core API.
- Required result: native/freeform input may describe a candidate only; `MS0`
  and the typed Core API remain the sole supported construction and execution
  path.

### Live Sandbox operation invalidity

#### `LIVE-001` Live update widens immutable policy

- Owner: `live`
- First-sound phase: `L0`
- Rejection deadline: `L0`
- Invariant: a live update changes only an explicitly mutable subset and never
  widens Artifact hard policy, resolved creation bounds, or operator policy.
- Minimum witness: add egress to an offline Sandbox through a provider update
  API.
- Required diagnostic: immutable bound, requested mutation, and whether a new
  Sandbox is required.

#### `LIVE-002` Operation requires an unadvertised capability

- Owner: `live`
- First-sound phase: `L0`
- Rejection deadline: `L0`
- Invariant: pause, resume, snapshot, fork, resize, attach, shell, port, file,
  and other optional live operations execute only when the concrete Sandbox
  advertises the required conformed capability and compatible state.
- Minimum witness: request memory snapshot from a Sandbox without the
  conformed snapshot capability.
- Required diagnostic: operation, capability identity, concrete Sandbox
  profile, and available alternatives; no provider best effort.

#### `LIVE-003` File operation crosses the Sandbox file contract

- Owner: `live`
- First-sound phase: `L0`
- Rejection deadline: `L0`
- Invariant: upload, download, list, stat, and remove operate only on permitted
  in-sandbox paths and preserve protected, immutable, secret, and ownership
  constraints.
- Minimum witness: remove an immutable Artifact path or download a secret-slot
  destination.
- Required diagnostic: safe logical path and violated contract; never return
  the secret or a current-host backing path.

#### `LIVE-004` Port operation exceeds declared network authority

- Owner: `live`
- First-sound phase: `L0`
- Rejection deadline: `L0`
- Invariant: expose, resolve, and revoke operate only on declared port slots and
  within Artifact, creation, and operator network authority.
- Minimum witness: publish an undeclared guest port from an Artifact with
  network disabled.
- Required diagnostic: port slot, immutable network bound, and requested live
  operation; no implicit public gateway.

### `Exec` request invalidity

#### `EXE-001` Empty Process argv

- Owner: `exec`
- First-sound phase: `E0`
- Rejection deadline: `E0`
- Invariant: every Process has a non-empty argv array and never relies on an
  implicit shell string.
- Minimum witness: empty argv.
- Required diagnostic: Process argv path and the non-empty argv requirement.

#### `EXE-002` Process working directory is outside the Sandbox namespace

- Owner: `exec`
- First-sound phase: `E0`
- Rejection deadline: `E0`
- Invariant: Process cwd is an absolute permitted in-sandbox path and never a
  host path, provider path, or driver implementation path.
- Minimum witness: current-host checkout path supplied as Process cwd.
- Required diagnostic: redact host-specific prefixes where required and name
  the in-sandbox workspace path.

#### `EXE-003` Non-secret environment bypasses a secret or reserved channel

- Owner: `exec`
- First-sound phase: `E0`
- Rejection deadline: `E0`
- Invariant: the ordinary Process environment delta contains non-secret,
  non-reserved values only; declared secret slots and trusted runtime variables
  use their dedicated typed channels.
- Minimum witness: populate a declared secret environment destination through
  the ordinary environment map.
- Required diagnostic: variable or slot identity with value redacted and the
  permitted channel.

#### `EXE-004` Process identity or privileges widen the Sandbox

- Owner: `exec`
- First-sound phase: `E0`
- Rejection deadline: `E0`
- Invariant: Process user, groups, capabilities, rlimits, and scheduling may
  preserve or narrow the resolved Sandbox authority but never widen it.
- Minimum witness: request a capability absent from the Sandbox capability
  bound.
- Required diagnostic: Process request and Sandbox upper bound; no suggestion
  to use provider root.

#### `EXE-005` Exec-native extension changes the Sandbox isolation boundary

- Owner: `exec`
- First-sound phase: `E0`
- Rejection deadline: `E0`
- Invariant: an Exec-native extension may configure Process transport or
  process-local behavior only; it cannot add host mounts, devices, network
  interfaces, provider resources, or Sandbox-wide policy.
- Minimum witness: raw provider Exec extension attempts to attach a host
  volume.
- Required diagnostic: extension namespace, `exec` scope, and the create/live
  owner of the rejected operation.

#### `EXE-006` PTY is requested without conformed support

- Owner: `exec`
- First-sound phase: `E0`
- Rejection deadline: `E0`
- Invariant: a PTY request succeeds only when the concrete Sandbox advertises
  compatible conformed PTY and resize semantics.
- Minimum witness: request a PTY from a profile advertising only pipe-based
  Process I/O.
- Required diagnostic: requested terminal behavior and missing capability; no
  silent downgrade to pipes.

#### `EXE-007` Process deadline exceeds the Sandbox lifetime bound

- Owner: `exec`
- First-sound phase: `E0`
- Rejection deadline: `E0`
- Invariant: Process timeout/deadline and detached behavior fit within the
  remaining Sandbox lifetime, immutable maximum, and controller termination
  policy.
- Minimum witness: detached Process deadline later than the Sandbox's hard TTL.
- Required diagnostic: safe relative durations and the limiting owner; no
  implicit TTL renewal.

### Framework/CLI adapter invalidity

#### `FWK-001` Adapter bypasses Core API validation

- Owner: `framework`
- First-sound phase: `F0`
- Rejection deadline: `F0`
- Invariant: every framework and CLI action translates into a typed Core
  Sandbox API operation and receives the same validation, resolution,
  idempotency, authorization, and diagnostic behavior as direct callers.
- Minimum witness: adapter calls a provider SDK directly to create a Sandbox.
- Required result: supported adapters depend on the Core API boundary, not
  driver/provider clients.

#### `FWK-002` Adapter advertises an unsupported sandbox capability

- Owner: `framework`
- First-sound phase: `F0`
- Rejection deadline: `F0`
- Invariant: model-facing tools and framework capability registration reflect
  the concrete Core API operations and conformed capabilities available to the
  selected Sandbox; prompt/tool metadata never creates capability.
- Minimum witness: adapter registers a snapshot tool for a Sandbox lacking
  snapshot support.
- Required diagnostic: adapter tool/capability identity and concrete Sandbox
  capability source.

### Packet B Artifact field invalidity

These cases close field-level gaps discovered after the resource-level Packet A
walk. They remain language-neutral: a frontend may make a case syntactically
unrepresentable, but corrupted canonical input must still fail at the named
boundary.

#### `PLT-001` Platform inferred from the evaluator host

- Owner: `artifact`
- First-sound phase: `P1`
- Rejection deadline: `A1`
- Invariant: workload OS, architecture, and target system are explicit and
  never inherited from an evaluator, builder, operator, or runtime host.
- Minimum witness: platform omitted while multiple supported systems exist.
- Required diagnostic: missing platform and affected target declarations.

#### `STR-009` Non-descriptive profile identity

- Owner: `artifact`
- First-sound phase: `P1`
- Rejection deadline: `A1`
- Invariant: every selectable profile has a non-empty behavioral name, and the
  literal name `default` is forbidden.
- Minimum witness: a selectable profile named `default`.
- Required diagnostic: invalid name, definition source, and descriptive-name
  remediation.

#### `XRS-009` Invisible or heuristic profile selection

- Owner: `artifact`
- First-sound phase: `A0`
- Rejection deadline: `A1`
- Invariant: exactly one pinned implicit or explicit profile and its complete
  expansion are materialized without ambient, target, or backend heuristics.
- Minimum witness: the selected profile is absent from the normalized value.
- Required diagnostic: selection source, missing identity facts, and every
  unresolved field.

#### `XRS-010` Descriptive metadata controls another resource

- Owner: `artifact`
- First-sound phase: `P1`
- Rejection deadline: `A1`
- Invariant: name, description, and labels are inert descriptive metadata and
  never control identity, placement, credentials, lifecycle, or policy.
- Minimum witness: a label is interpreted as a provider placement selector.
- Required diagnostic: metadata path and the actual owning resource.

#### `STR-010` Untyped or unpinned Nix input identity

- Owner: `artifact`
- First-sound phase: `P1`
- Rejection deadline: `W0`
- Invariant: portable Nix references are typed pinned input, attribute, output,
  and target-system identities, never arbitrary Nix values or host paths.
- Minimum witness: a raw evaluator function or current-machine store path.
- Required diagnostic: offending reference kind and required typed identity.

#### `XRS-011` Lossy or open-ended devShell projection

- Owner: `artifact`
- First-sound phase: `N0`
- Rejection deadline: `N0`
- Invariant: devShell import retains only the closed supported environment
  projection and rejects every unsupported value instead of dropping it.
- Minimum witness: an interactive `shellHook` would otherwise disappear.
- Required diagnostic: devShell source, unsupported member, and explicit-field
  remediation.

#### `XRS-012` Ambient environment supplies an Artifact default

- Owner: `artifact`
- First-sound phase: `A0`
- Rejection deadline: `A1`
- Invariant: normalized environment equals explicit/profile-derived content;
  omitted values stay absent and host or caller environment never fills them.
- Minimum witness: host `PATH` changes normalized output.
- Required diagnostic: variable identity and ambient source, with values
  redacted when necessary.

#### `STR-011` Artifact-default cwd outside the Sandbox

- Owner: `artifact`
- First-sound phase: `A0`
- Rejection deadline: `A1`
- Invariant: default Process cwd is an absolute permitted in-sandbox path.
- Minimum witness: a current-host checkout path is used as cwd.
- Required diagnostic: cwd and the declared workspace/filesystem roots.

#### `XRS-013` Artifact-default Process widens Artifact bounds

- Owner: `artifact`
- First-sound phase: `A0`
- Rejection deadline: `A1`
- Invariant: every default Process field preserves environment, filesystem,
  identity, resource, and security bounds.
- Minimum witness: default Process adds a capability outside the ceiling.
- Required diagnostic: widening field and immutable upper bound.

#### `XRS-014` Backend-default request in Artifact Process

- Owner: `artifact`
- First-sound phase: `A0`
- Rejection deadline: `A1`
- Invariant: every normalized Artifact-default Process member is explicit,
  profile-derived, or absent; no portable value or sentinel may request
  inheritance from an image, provider, target, or backend.
- Minimum witness: argv uses an `inherit-image-entrypoint` sentinel.
- Required diagnostic: offending inheritance request and remediation to either
  declare the value or leave it absent. Target preservation is checked by
  `MAN-004` and Packet C.

#### `MAN-004` Software or default-Process projection mismatch

- Owner: `artifact`
- First-sound phase: `N1`
- Rejection deadline: `C0`
- Invariant: every target manifest exactly reproduces normalized software and
  default Process metadata and introduces no absent default.
- Minimum witness: a manifest adds one environment variable.
- Required diagnostic: target member and expected/observed field summaries.

#### `XRS-015` Concrete workspace source or mechanism in Artifact

- Owner: `artifact`
- First-sound phase: `P1`
- Rejection deadline: `A1`
- Invariant: workspace declares only its logical contract; checkout, payload,
  host/provider object, snapshot identity, and mechanism remain outside it.
- Minimum witness: a provider snapshot ID appears in workspace source.
- Required diagnostic: offending value kind and its Create/operator owner.

#### `XRS-016` Workspace requirement and slot disagree

- Owner: `artifact`
- First-sound phase: `A0`
- Rejection deadline: `A1`
- Invariant: required workspace and generated slot agree on destination,
  access, ownership, cardinality, and materializations.
- Minimum witness: read-write workspace produces a read-only slot.
- Required diagnostic: both definitions and expansion origins.

#### `XRS-017` Workspace access folds in lifecycle or result transfer

- Owner: `artifact`
- First-sound phase: `P1`
- Rejection deadline: `A1`
- Invariant: access/materialization are independent of synchronization,
  writeback, retention, snapshot, capture, and export.
- Minimum witness: `workspace.persistent = true`.
- Required diagnostic: conflated field and correct runtime owner.

#### `XRS-018` Workspace ownership selects host or launcher identity

- Owner: `artifact`
- First-sound phase: `P1`
- Rejection deadline: `A1`
- Invariant: workspace ownership is workload-visible only and never selects
  host maps, chown strategy, provider identity, or launcher privilege.
- Minimum witness: workspace specifies a host UID mapping.
- Required diagnostic: offending mapping and workload identity contract.

#### `XRS-019` Ambiguous filesystem destination topology

- Owner: `artifact`
- First-sound phase: `A0`
- Rejection deadline: `A1`
- Invariant: filesystem destinations are unique or explicitly composed with
  deterministic precedence that cannot shadow immutable/protected content.
- Minimum witness: scratch and immutable input claim one destination.
- Required diagnostic: every claimant, origin, and overlap relation.

#### `SUM-006` Incomplete or mutable immutable-input contract

- Owner: `artifact`
- First-sound phase: `P1`
- Rejection deadline: `A1`
- Invariant: immutable input is pinned/content-addressed read-only Artifact
  content and has no binding, lifecycle, writable, or volume state.
- Minimum witness: immutable input also declares writable access.
- Required diagnostic: conflicting resource kinds and source identity.

#### `SUM-007` Incomplete or concrete mount-slot contract

- Owner: `artifact`
- First-sound phase: `P1`
- Rejection deadline: `A1`
- Invariant: mount slot contains only logical identity, source-kind constraint,
  cardinality, destination, and access ceiling.
- Minimum witness: a host path or target mount mechanism appears in the slot.
- Required diagnostic: forbidden/missing member and correct owner.

#### `SUM-008` Incomplete or externally identified scratch

- Owner: `artifact`
- First-sound phase: `P1`
- Rejection deadline: `A1`
- Invariant: scratch is private one-Sandbox writable state with destination and
  hard maximum, not external identity, restore, retention, or actual size.
- Minimum witness: scratch has a provider volume ID.
- Required diagnostic: conflicting scratch and persistence semantics.

#### `SUM-009` Concrete or underspecified persistent-volume slot

- Owner: `artifact`
- First-sound phase: `P1`
- Rejection deadline: `A1`
- Invariant: persistent volume is a logical independent-lifecycle slot with
  destination, access, cardinality, and capacity bounds only.
- Minimum witness: slot contains a concrete volume/snapshot identity.
- Required diagnostic: logical slot member and forbidden runtime member.

#### `XRS-020` Static protected path is invalid or weakened

- Owner: `artifact`
- First-sound phase: `A0`
- Rejection deadline: `A1`
- Invariant: protected paths normalize beneath their root, have one immutable
  mode, and cannot be shadowed or widened by writable resources.
- Minimum witness: protected `.git` is shadowed by writable scratch.
- Required diagnostic: protected path, root, mode, and shadowing resource.

#### `NET-001` Incomplete or contradictory network authority

- Owner: `artifact`
- First-sound phase: `A0`
- Rejection deadline: `A1`
- Invariant: one closed network policy makes access, egress, DNS, ingress,
  credential slots, and required enforcement capability compatible.
- Minimum witness: controlled egress lacks an enforcement capability.
- Required diagnostic: mode, incompatible/missing member, and affected targets.

#### `NET-002` Host communication hidden inside network mode

- Owner: `artifact`
- First-sound phase: `A0`
- Rejection deadline: `A1`
- Invariant: every socket, vsock, bus, display/audio channel, broker, or
  inherited descriptor is separately typed and explicit.
- Minimum witness: network is none but native config exposes a host socket.
- Required diagnostic: channel type, endpoint contract, and source.

#### `RES-001` Ambiguous resource dimension or enforcement scope

- Owner: `artifact`
- First-sound phase: `P1`
- Rejection deadline: `A1`
- Invariant: every bound names unit, dimension, enforcement scope, and kind;
  concurrency/quota/weight and total/workload scopes are not interchangeable.
- Minimum witness: generic `memory = 8` or `cpu = 2`.
- Required diagnostic: missing dimension, scope, kind, or unit.

#### `RES-002` Artifact resource bounds have an empty range

- Owner: `artifact`
- First-sound phase: `A0`
- Rejection deadline: `A1`
- Invariant: values are positive where required, minimum does not exceed hard
  maximum, and related scoped bounds do not contradict.
- Minimum witness: memory minimum exceeds hard maximum.
- Required diagnostic: normalized range, units, and contributing definitions.

#### `IDN-001` Ambiguous or host-coupled workload identity

- Owner: `artifact`
- First-sound phase: `A0`
- Rejection deadline: `A1`
- Invariant: identity is deterministic workload-visible user/UID/GID/groups
  only; host maps, launcher/provider identity, and ambient groups are absent.
- Minimum witness: an undeclared supplementary group is inherited.
- Required diagnostic: workload identity member and forbidden ambient source.

#### `SEC-001` Inconsistent privilege or Linux capability ceiling

- Owner: `artifact`
- First-sound phase: `A0`
- Rejection deadline: `A1`
- Invariant: no-new-privileges, escalation, and canonical capability sets form
  one consistent privilege ceiling that no target default widens.
- Minimum witness: ambient capability is outside the permitted set.
- Required diagnostic: capability set relation and privilege ceiling.

#### `SEC-002` Unversioned or mechanism-confused kernel security requirement

- Owner: `artifact`
- First-sound phase: `A0`
- Rejection deadline: `A1`
- Invariant: seccomp, LSM/Landlock, syd, namespace, and similar requirements
  use registered versioned semantics and never stand in for the whole sandbox.
- Minimum witness: unversioned seccomp blob claims complete isolation.
- Required diagnostic: requirement identity/version/architecture and missing
  independent security property.

#### `DEV-001` Concrete or underspecified device requirement

- Owner: `artifact`
- First-sound phase: `A0`
- Rejection deadline: `A1`
- Invariant: device requirement contains logical class, count, access,
  isolation, and capability only, never live identity or placement.
- Minimum witness: a concrete `/dev` path or provider GPU ID.
- Required diagnostic: logical contract member and forbidden concrete value.

#### `DEV-002` Device injection edits undeclared Artifact semantics

- Owner: `artifact`
- First-sound phase: `A0`
- Rejection deadline: `A1`
- Invariant: all device/CDI-induced environment, mount, hook, group,
  capability, and host-channel effects project into ordinary Artifact policy.
- Minimum witness: opaque device contract adds an undeclared host mount.
- Required diagnostic: device identity and every unprojected edit class.

#### `SCT-001` Incomplete secret delivery alternative

- Owner: `artifact`
- First-sound phase: `A0`
- Rejection deadline: `A1`
- Invariant: each secret slot has typed alternatives containing exactly the
  applicable destination, audience, ownership/mode, lifetime, and snapshot
  constraints.
- Minimum witness: file delivery omits destination or mode.
- Required diagnostic: slot, alternative, and missing/inapplicable members
  without secret data.

#### `SCT-002` Secret destination conflicts with another resource

- Owner: `artifact`
- First-sound phase: `A0`
- Rejection deadline: `A1`
- Invariant: secret destination is not ordinary environment, immutable/output
  content, protected control state, or another incompatible writer.
- Minimum witness: secret file and declared output share one path.
- Required diagnostic: both safe logical paths and contributing definitions.

#### `SCT-003` Secret and snapshot contracts disagree

- Owner: `artifact`
- First-sound phase: `A0`
- Rejection deadline: `A1`
- Invariant: any snapshot-capable secret surface has explicit compatible
  inclusion treatment in both secret and snapshot contracts.
- Minimum witness: slot forbids inclusion while snapshot requires it.
- Required diagnostic: slot, snapshot class, and conflicting treatments.

#### `CAP-001` Unsatisfied or contradictory capability requirement

- Owner: `artifact`
- First-sound phase: `A0`
- Rejection deadline: `A1`
- Invariant: capabilities have registered/namespaced identity, compatible
  version, strength, and satisfiable dependency closure.
- Minimum witness: required capability depends on an absent incompatible
  version.
- Required diagnostic: capability edge, sources, and compatible alternatives.

#### `SNP-001` Incomplete snapshot capability contract

- Owner: `artifact`
- First-sound phase: `A0`
- Rejection deadline: `A1`
- Invariant: snapshot requirement names components and external-storage,
  secret, compatibility-domain, quiescing, and applicable device-state
  treatment.
- Minimum witness: memory snapshot omits device-state semantics.
- Required diagnostic: snapshot class and missing semantic decision.

#### `SUM-010` Conflated persistence semantics

- Owner: `artifact`
- First-sound phase: `A0`
- Rejection deadline: `A1`
- Invariant: scratch, volume binding, snapshot/restore, workspace sync, and
  output capture are distinct; generic persistence booleans are forbidden.
- Minimum witness: `persistent = true` stands for both volume and snapshot.
- Required diagnostic: conflated meanings and their separate resources.

#### `OUT-001` Incomplete or runtime-owned output declaration

- Owner: `artifact`
- First-sound phase: `A0`
- Rejection deadline: `A1`
- Invariant: output has unique identity, exact normalized in-sandbox path, and
  file/directory kind only; runtime capture/export choices are absent.
- Minimum witness: output contains an S3 destination or retention period.
- Required diagnostic: forbidden runtime field and correct operation owner.

#### `OUT-002` Declared output conflicts with filesystem policy

- Owner: `artifact`
- First-sound phase: `A0`
- Rejection deadline: `A1`
- Invariant: output is reachable and does not conflict with secret, protected,
  or immutable-only content.
- Minimum witness: output path lies inside protected `.git`.
- Required diagnostic: output and conflicting filesystem contracts.

#### `IDT-001` Portable semantic identity includes non-semantic provenance

- Owner: `artifact`
- First-sound phase: `W0`
- Rejection deadline: `W0`
- Invariant: digest includes normalized semantics and pinned profile content
  identity but excludes source spans, formatting, checkout path, timestamps,
  selector explicitness, and explanation provenance.
- Minimum witness: explicit versus implicit selection changes semantic digest.
- Required diagnostic: forbidden identity input and digest domain.

#### `IDT-002` Artifact identity domains are interchanged

- Owner: `artifact`
- First-sound phase: `N1`
- Rejection deadline: `C0`
- Invariant: semantic digest, member content digest, and Artifact Set identity
  are typed distinct domains.
- Minimum witness: member digest is supplied where set identity is required.
- Required diagnostic: expected/observed domain and affected member.

#### `TGT-009` Invalid target or runtime-profile declaration

- Owner: `artifact`
- First-sound phase: `A0`
- Rejection deadline: `A1`
- Invariant: target/profile identities are unique, explicit, registered or
  namespaced, and attached only in compatible pairs.
- Minimum witness: Firecracker profile is attached to an OCI target.
- Required diagnostic: identity, incompatible edge, and contributing sources.

#### `TGT-010` Divergent common semantics share one Artifact identity

- Owner: `artifact`
- First-sound phase: `A0`
- Rejection deadline: `A1`
- Invariant: one Artifact Set has one common contract; intentional divergence
  is expressed as separate named Artifact Definitions and identities.
- Minimum witness: one target silently receives network access unlike peers.
- Required diagnostic: divergent fields and separate-definition remediation.

#### `NAT-001` Artifact-native configuration has the wrong scope

- Owner: `artifact`
- First-sound phase: `A0`
- Rejection deadline: `A1`
- Invariant: native construction config is versioned, registered, and under an
  enabled target; wrong lifecycle scope or disabled target data is rejected.
- Minimum witness: disabled OCI target contains native runtime mounts.
- Required diagnostic: namespace, target, lifecycle owner, and source.

#### `NAT-002` Byte-changing native input is unpinned or unhashed

- Owner: `artifact`
- First-sound phase: `N0`
- Rejection deadline: `N0`
- Invariant: every byte-changing native input resolves through a typed pinned
  handle and affects the constructed member identity.
- Minimum witness: guest module changes bytes without changing member identity.
- Required diagnostic: native handle and affected target member.

#### `NAT-003` Native handle identity is incomplete

- Owner: `artifact`
- First-sound phase: `N0`
- Rejection deadline: `N0`
- Invariant: a native handle identity binds the complete pinned transitive
  source graph, registry namespace and version, export attribute, native
  interface version, target system, affected member, and expected semantic
  effect; a current store path or digest of one registry file is insufficient.
- Minimum witness: keep a handle ID and registry-file digest fixed while
  changing a transitive input, export attribute, target system, interface
  version, or affected member.
- Required result: identity changes or Nix construction rejects before
  derivation construction; the built manifest is independently checked again
  at load.

#### `LIF-001` Invalid or weakened Artifact lifetime ceiling

- Owner: `artifact`
- First-sound phase: `A0`
- Rejection deadline: `A1`
- Invariant: optional maximum lifetime is a positive finite hard ceiling;
  composition only narrows it, omission adds no Artifact ceiling, and backend
  defaults never enter Artifact semantics.
- Minimum witness: negative lifetime or later module widens the ceiling.
- Required diagnostic: normalized limits, sources, and monotonic remediation.

### Packet C target-realization and provider invalidity

#### `MAN-005` Target manifest incompletely projects portable semantics

- Owner: `artifact`
- First-sound phase: `N1`
- Rejection deadline: `C0`
- Invariant: every target-member manifest reproduces the complete normalized
  Artifact contract, explicit absences, target realization requirements, and
  default-suppression obligations for filesystem, network, resources,
  identity, security, devices, secrets, lifecycle, interfaces, and outputs.
- Minimum witness: an OCI member records its image digest but omits the
  requirement to suppress image volumes, network defaults, or a writable root.
- Required diagnostic: member identity, omitted or divergent field,
  normalized Artifact value, and rebuild remediation.
- Prohibition: a content digest over an incomplete manifest is not proof of
  semantic projection.

#### `MAN-006` Incompatible runtime profiles share one member manifest

- Owner: `artifact`
- First-sound phase: `N1`
- Rejection deadline: `C0`
- Invariant: one byte-identical content blob may be deduplicated across target
  members, but one member manifest may advertise multiple runtime profiles
  only when builder evidence independently proves each profile compatible with
  the exact member and their immutable hard requirements are identical.
- Minimum witness: Firecracker and Cloud Hypervisor reuse one member manifest
  despite different device baselines, helper/jailer requirements, live
  workspace support, snapshot envelope, and driver protocols.
- Required diagnostic: conflicting profile requirements, shared member
  identity, independently reusable blob identities, and separate-member
  remediation.

#### `HOST-004` Runtime implementation does not match the selected profile bundle

- Owner: `operator`
- First-sound phase: `H0`
- Rejection deadline: `H0`
- Invariant: host preflight verifies the exact registered implementation
  bundle, executable revisions, build features, mandatory helpers, process
  confinement, kernel facilities, and conformance versions required by the
  selected runtime profile.
- Minimum witnesses:
  - Bubblewrap has the correct version but is built or installed setuid;
  - Firecracker launches without jailer or an evidenced stronger jail;
  - Cloud Hypervisor requires fail-closed Landlock/outer confinement but the
    selected host cannot provide it.
- Required diagnostic: selected profile, mismatched component or host feature,
  expected identity, observed identity, and no-fallback remediation.

#### `HOST-005` Dynamic filesystem source changes after preflight

- Owner: `create`
- First-sound phase: `H0`
- Rejection deadline: `D0`
- Invariant: every dynamic filesystem source is safely resolved to an object
  identity retained through target attachment; validation by pathname followed
  by a later pathname reopen is forbidden.
- Minimum witness: preflight validates a workspace source path, an attacker
  replaces an ancestor or final object, and the driver later binds the
  replacement by path.
- Required diagnostic: redacted slot identity, expected and observed object
  identity, unsafe handoff boundary, and FD-pinned or equivalent remediation.

#### `SNP-002` Snapshot or restore state violates the proven compatibility envelope

- Owner: `live`
- First-sound phase: `L0`
- Rejection deadline: `L0`
- Invariant: each snapshot or restore operation revalidates the exact captured
  component set, external-storage state, device state, secret treatment,
  quiescing state, VMM/driver/guest/kernel/CPU compatibility, and clone identity
  refresh required by the advertised snapshot class.
- Minimum witnesses:
  - snapshot begins while a `forbid capture` secret remains resident;
  - restore uses an incompatible VMM build or CPU envelope;
  - a Firecracker snapshot is cloned repeatedly without refreshing identity,
    entropy, tokens, network state, TAP, and vsock bindings.
- Required diagnostic: operation, snapshot class, failed compatibility
  dimension, current state, and a secret-safe remediation.

#### `PRV-001` Provider transfer substitutes an unverifiable object

- Owner: `operator`
- First-sound phase: `H0`
- Rejection deadline: `H0`
- Invariant: provider transport preserves portable semantic identity and
  verifies the selected member bytes or OCI descriptor graph by digest after
  upload, download, and every cache hit; provider object IDs, aliases, tags,
  paths, and cache keys are non-semantic metadata.
- Minimum witness: a provider cache returns an object for the requested alias
  whose bytes do not match the selected member digest.
- Required diagnostic: transport mode, expected typed member/descriptor
  identity, observed digest, provider object reference as non-semantic
  metadata, and explicit transfer rejection.

#### `PRV-002` Provider-side construction lacks equivalence evidence

- Owner: `artifact`
- First-sound phase: `N0`
- Rejection deadline: `N1`
- Invariant: provider-side construction may claim portable conformance only
  from a versioned product construction protocol with complete pinned inputs,
  suppressed provider defaults, a returned output identity, provenance, and
  member-bound semantic and runtime conformance evidence.
- Minimum witness: an imperative provider environment recipe returns a
  provider template ID but no content identity or evidence relating it to the
  requested Artifact.
- Required diagnostic: construction protocol, missing pin/output/evidence
  class, provider-native non-conforming alternative, and remediation. The
  provider build adapter rejects before publishing a target member; the result
  later re-enters ordinary manifest verification before `C0`.

### Packet E authority fencing and effect-authority ordering

#### `FEN-001` Authoritative Core commit by a stale authority epoch

- Owner: `core`
- First-sound phase: `D0`
- Rejection deadline: `D0`
- Invariant: Every authoritative Core-state commit validates the complete capability of Sandbox ID, runtime epoch, and authority epoch against the durable authority high-water mark and commits only under the current authority epoch.
- Minimum witness: An authoritative Core-state commit accepted from a capability whose authority epoch is below the durable high-water mark.
- Required diagnostic: identifies `FEN-001`, names `capability.authorityEpoch`, `capability.runtimeEpoch`, `capability.sandboxId`, and states the remediation without disclosing secret values.

#### `FEN-002` Successor effect authority granted without fencing or drain proof

- Owner: `core`
- First-sound phase: `H0`
- Rejection deadline: `D0`
- Invariant: The Core grants a successor actor effect authority only after the target is proven, for this exact handoff, to validate the fencing token atomically or to provide a product-verifiable predecessor drain or termination boundary.
- Minimum witness: A successor actor granted effect authority against a target that neither validates a fencing token atomically nor offers a verifiable drain boundary.
- Required diagnostic: identifies `FEN-002`, names `capability.authorityEpoch`, `handoff.targetFencing`, `handoff.predecessorDrain`, and states the remediation without disclosing secret values.

#### `FEN-003` Driver claims exclusive effect authority without target fencing support

- Owner: `runtime`
- First-sound phase: `D0`
- Rejection deadline: `D0`
- Invariant: A driver declares for each effect boundary it exposes whether the target validates its fencing token atomically or offers a verifiable drain boundary, and refuses to dispatch an exclusive effect when it can prove neither.
- Minimum witness: A driver that dispatches an exclusive effect on an effect boundary for which it declares neither atomic fencing nor a verifiable drain.
- Required diagnostic: identifies `FEN-003`, names `driver.effectBoundary.fencingToken`, `driver.effectBoundary.drainProof`, `capability.authorityEpoch`, and states the remediation without disclosing secret values.

#### `FEN-004` Unfenced handoff reported as a definite outcome

- Owner: `core`
- First-sound phase: `R1`
- Rejection deadline: `R1`
- Invariant: When a handoff cannot establish exclusive effect authority, the affected resources are quarantined or reconciled and the Operation retains its ambiguous terminal outcome rather than a definite success or failure.
- Minimum witness: A handoff that could not be fenced whose Operation is published as a definite success.
- Required diagnostic: identifies `FEN-004`, names `operation.outcome`, `operation.ambiguity`, `capability.authorityEpoch`, and states the remediation without disclosing secret values.

#### `FEN-005` Driver retry or adoption without native idempotency or exact adoption proof

- Owner: `runtime`
- First-sound phase: `D0`
- Rejection deadline: `D0`
- Invariant: A driver retries the same external effect only under the provider's own idempotency token for that effect and adopts an existing external execution only with exact proof of its external identity, target, runtime epoch, and fencing.
- Minimum witness: A driver that retries an external effect after a transport timeout without a provider idempotency token for that effect.
- Required diagnostic: identifies `FEN-005`, names `driver.effectClass`, `driver.effectAttempt.idempotencyToken`, `driver.effectAttempt.adoptionProof`, and states the remediation without disclosing secret values.

#### `FEN-006` Provider status alone justifies a Core outcome

- Owner: `runtime`
- First-sound phase: `D0`
- Rejection deadline: `D0`
- Invariant: Every driver declares which native identities, state observations, fencing results, and supervision facts justify each Core outcome variant it may report, and reports no variant whose declared evidence it did not obtain.
- Minimum witness: A driver reporting a definite success on the strength of a provider status field alone.
- Required diagnostic: identifies `FEN-006`, names `driver.evidenceContract`, `driver.evidence.providerStatus`, `operation.outcome`, and states the remediation without disclosing secret values.

#### `FEN-007` Start authorizes a launch without fencing the prior runtime epoch

- Owner: `core`
- First-sound phase: `L1`
- Rejection deadline: `L1`
- Invariant: A Start commits its launch authorization only after the Sandbox's prior runtime epoch is permanently fenced, so no predecessor authority can commit Core state or act against the new epoch.
- Minimum witness: A Start that commits its launch authorization while the prior runtime epoch's authority can still commit Core state.
- Required diagnostic: identifies `FEN-007`, names `sandbox.status.runtime.epoch`, `sandbox.authorityEpoch`, `operation.result.resultingRuntimeEpoch`, and states the remediation without disclosing secret values.

### Packet E identity and coordinate integrity

#### `IDE-001` Sandbox identity reused across lifetimes

- Owner: `core`
- First-sound phase: `C0`
- Rejection deadline: `C0`
- Invariant: Every Sandbox ID identifies exactly one Sandbox lifetime and is never allocated again, including by re-creation after Delete, restore-as-create, or Fork child allocation.
- Minimum witness: A Create that proposes the Sandbox ID of a previously deleted Sandbox and is accepted as a new lifetime.
- Required diagnostic: identifies `IDE-001`, names `sandbox.id`, `create.sandboxId`, `operation.target.sandboxId`, and states the remediation without disclosing secret values.

#### `IDE-002` Create omits its initial runtime-epoch record

- Owner: `core`
- First-sound phase: `C0`
- Rejection deadline: `C0`
- Invariant: Every accepted Create durably records either the runtime epoch allocated for a runtime-creating Create or an explicit absence of any runtime epoch for a Create that ends stopped.
- Minimum witness: A Create accepted with a running runtime whose durable record carries no runtime-epoch value and no explicit absence marker.
- Required diagnostic: identifies `IDE-002`, names `operation.result.resultingRuntimeEpoch`, `sandbox.status.runtime.epoch`, `create.initialRuntime`, and states the remediation without disclosing secret values.

#### `IDE-003` Sandbox name reused before the former Sandbox is released

- Owner: `core`
- First-sound phase: `C0`
- Rejection deadline: `C0`
- Invariant: A Create accepts a Sandbox name only when no undeleted Sandbox holds that name and the prior holder's reservation has been released by Delete.
- Minimum witness: Two Creates accepted with the same Sandbox name while the first Sandbox is still undeleted.
- Required diagnostic: identifies `IDE-003`, names `create.name`, `sandbox.name`, and states the remediation without disclosing secret values.

#### `IDE-004` Runtime epoch reused within a Sandbox

- Owner: `core`
- First-sound phase: `L0`
- Rejection deadline: `L1`
- Invariant: Every runtime epoch is a positive, strictly increasing, never-reused integer within its Sandbox ID, durably committed before the launch it authorizes and consumed even when that launch fails or ends ambiguously.
- Minimum witness: A Start whose launch fails and whose successor Start reissues the same runtime-epoch integer.
- Required diagnostic: identifies `IDE-004`, names `sandbox.status.runtime.epoch`, `operation.result.resultingRuntimeEpoch`, `operation.target.expectedRuntimeEpoch`, and states the remediation without disclosing secret values.

#### `IDE-005` Exec request without a complete Sandbox runtime reference

- Owner: `exec`
- First-sound phase: `E0`
- Rejection deadline: `E0`
- Invariant: Every Exec request carries a complete Sandbox runtime reference naming the exact Sandbox ID and runtime epoch the execution is intended for.
- Minimum witness: An Exec request carrying a Sandbox ID with the runtime epoch absent.
- Required diagnostic: identifies `IDE-005`, names `exec.sandboxRuntimeRef`, `process.sandboxRuntimeRef`, and states the remediation without disclosing secret values.

#### `IDE-006` Stale runtime reference silently retargeted

- Owner: `live`
- First-sound phase: `L0`
- Rejection deadline: `L0`
- Invariant: A live request whose expected runtime epoch differs from the current epoch returns a typed stale-runtime result naming the requested Sandbox and expected epoch, and is never applied to the replacement runtime.
- Minimum witness: A live mutation whose expected runtime epoch is one behind the current epoch and is applied to the replacement runtime anyway.
- Required diagnostic: identifies `IDE-006`, names `operation.target.expectedRuntimeEpoch`, `sandbox.status.runtime.epoch`, and states the remediation without disclosing secret values.

#### `IDE-007` Exec silently applied to a replacement runtime

- Owner: `exec`
- First-sound phase: `E0`
- Rejection deadline: `E0`
- Invariant: An Exec whose referenced runtime epoch is no longer current returns a typed stale-runtime result and is never admitted against the replacement runtime.
- Minimum witness: An Exec naming a superseded runtime epoch that is admitted against the current runtime.
- Required diagnostic: identifies `IDE-007`, names `exec.sandboxRuntimeRef`, `sandbox.status.runtime.epoch`, and states the remediation without disclosing secret values.

#### `IDE-008` Coordinate substituted for another on the live request surface

- Owner: `live`
- First-sound phase: `L0`
- Rejection deadline: `L0`
- Invariant: Each live request coordinate keeps its own declared domain: a name alias resolves once to an ID-pinned handle and never persists as identity; a representation etag guards only the representation revision and neither satisfies nor is satisfied by an expected-runtime-epoch precondition; an event or output cursor is an observation position only and is accepted in no identity, target, precondition, or authority position; an idempotency key is a recovery coordinate only; and a runtime epoch is expressible only as an expected-value precondition and never as an assignable field.
- Minimum witness: A live mutation that carries an output cursor in the target position, or whose etag precondition is accepted in place of the expected-runtime-epoch precondition.
- Required diagnostic: identifies `IDE-008`, names `sandbox.name`, `sandbox.id`, `sandbox.etag`, and states the remediation without disclosing secret values.

#### `IDE-009` Snapshot manifest digest substituted for Snapshot identity

- Owner: `live`
- First-sound phase: `L0`
- Rejection deadline: `L0`
- Invariant: Every Snapshot-targeted operation identifies its target by Snapshot ID, and the manifest digest remains an integrity coordinate that resolves no resource.
- Minimum witness: A Snapshot-targeted operation whose target coordinate is a manifest digest rather than a Snapshot ID.
- Required diagnostic: identifies `IDE-009`, names `operation.target.snapshotId`, `snapshot.manifestDigest`, and states the remediation without disclosing secret values.

#### `IDE-010` Deleted or stale Snapshot handle retargeted to equal content

- Owner: `live`
- First-sound phase: `L0`
- Rejection deadline: `L0`
- Invariant: A Snapshot ID that no longer resolves returns a typed target-not-found result and is never resolved to a different Snapshot with equal manifest digest or equivalent content.
- Minimum witness: A Restore of a deleted Snapshot ID that succeeds against a different retained Snapshot with an equal manifest digest.
- Required diagnostic: identifies `IDE-010`, names `operation.target.snapshotId`, `snapshot.id`, `snapshot.manifestDigest`, and states the remediation without disclosing secret values.

#### `IDE-011` Operation accepted without the exact target its kind seals

- Owner: `core`
- First-sound phase: `L0`
- Rejection deadline: `L0`
- Invariant: Every accepted Operation records exactly the tagged target variant its operation kind requires, with every coordinate that variant seals present and resolved -- including the exact expected runtime epoch that every runtime-acting live mutation's target variant seals.
- Minimum witness: A runtime-acting live mutation accepted with a target variant whose sealed expected runtime epoch is absent.
- Required diagnostic: identifies `IDE-011`, names `operation.target`, `operation.method`, `operation.target.sandboxId`, and states the remediation without disclosing secret values.

#### `IDE-012` Process-targeted Operation retargeted during retry or reconciliation

- Owner: `core`
- First-sound phase: `L1`
- Rejection deadline: `L1`
- Invariant: A Process-targeted Operation keeps the exact Process ID, Sandbox ID, and runtime epoch committed at its acceptance through every retry, adoption, and reconciliation.
- Minimum witness: A Signal Operation retried against a replacement Process ID after its committed target disappeared.
- Required diagnostic: identifies `IDE-012`, names `operation.target.processId`, `operation.target.sandboxId`, `operation.target.runtimeEpoch`, and states the remediation without disclosing secret values.

#### `IDE-013` Runtime-replacing result omits its previous or resulting epoch

- Owner: `core`
- First-sound phase: `L1`
- Rejection deadline: `L1`
- Invariant: Every Operation result that replaces or creates a runtime records both the previous runtime epoch, or its explicit absence, and the resulting runtime epoch.
- Minimum witness: A Restore result recording only the resulting runtime epoch, with the previous epoch neither present nor explicitly absent.
- Required diagnostic: identifies `IDE-013`, names `operation.result.previousRuntimeEpoch`, `operation.result.resultingRuntimeEpoch`, `sandbox.status.runtime.epoch`, and states the remediation without disclosing secret values.

#### `IDE-014` Attachment continuity conflated with runtime continuity

- Owner: `core`
- First-sound phase: `L1`
- Rejection deadline: `L1`
- Invariant: Every lifecycle Operation able to change client attachment reports an explicit attachment outcome equivalent to preserved or reconnect-required, and that outcome never decides, substitutes for, or is decided by the runtime epoch.
- Minimum witness: A lifecycle Operation that leaves the runtime epoch unchanged because the client attachment was preserved.
- Required diagnostic: identifies `IDE-014`, names `operation.result.attachmentContinuity`, `operation.result.resultingRuntimeEpoch`, `sandbox.status.runtime.epoch`, and states the remediation without disclosing secret values.

#### `IDE-015` Process record not permanently bound to one Sandbox runtime

- Owner: `core`
- First-sound phase: `E0`
- Rejection deadline: `E0`
- Invariant: Every accepted Process receives a newly allocated Core Process ID permanently bound to exactly one Sandbox ID and runtime epoch, and that binding is never rewritten.
- Minimum witness: A Process record whose Sandbox runtime reference is rewritten to a newer epoch after its runtime was replaced.
- Required diagnostic: identifies `IDE-015`, names `process.id`, `process.sandboxRuntimeRef`, `exec.sandboxRuntimeRef`, and states the remediation without disclosing secret values.

#### `IDE-016` Native execution identifier used as durable public identity

- Owner: `runtime`
- First-sound phase: `D0`
- Rejection deadline: `D0`
- Invariant: Native PIDs, provider execution identifiers, provider resource identifiers, and VMM identities are recorded only as scoped decoded observations and never become or resolve durable public Sandbox, runtime, Process, Operation, or Snapshot identity.
- Minimum witness: A driver result in which the provider execution identifier is published as the Core Process ID.
- Required diagnostic: identifies `IDE-016`, names `driver.evidence.nativeExecutionId`, `process.id`, `sandbox.id`, and states the remediation without disclosing secret values.

#### `IDE-017` Runtime epoch accepted as Create input

- Owner: `create`
- First-sound phase: `C0`
- Rejection deadline: `C0`
- Invariant: The canonical Create request expresses no runtime epoch, leaving the first epoch server-allocated output-only state that no caller, native extension, or adapter can set, preserve, or reset.
- Minimum witness: A CreateSandbox request carrying a runtime-epoch value.
- Required diagnostic: identifies `IDE-017`, names `create.runtimeEpoch`, `sandbox.status.runtime.epoch`, and states the remediation without disclosing secret values.

#### `IDE-018` Runtime epoch written by a live request

- Owner: `live`
- First-sound phase: `L0`
- Rejection deadline: `L0`
- Invariant: A live request expresses the runtime epoch only as an expected-value precondition and never as an assignable field able to set, reset, preserve, or decrement it.
- Minimum witness: A live request that sets, resets, or decrements the Sandbox runtime epoch.
- Required diagnostic: identifies `IDE-018`, names `operation.target.expectedRuntimeEpoch`, `sandbox.status.runtime.epoch`, and states the remediation without disclosing secret values.

#### `IDE-019` Sandbox name mutated after Create

- Owner: `live`
- First-sound phase: `L0`
- Rejection deadline: `L0`
- Invariant: The Sandbox name is fixed at Create, and no metadata, expiration, or other live update request can express a replacement name.
- Minimum witness: An UpdateSandboxMetadata request carrying a replacement Sandbox name.
- Required diagnostic: identifies `IDE-019`, names `sandbox.name`, `live.metadata`, and states the remediation without disclosing secret values.

#### `IDE-020` Process identifier or output cursor used as an exec identity or authority coordinate

- Owner: `exec`
- First-sound phase: `E0`
- Rejection deadline: `E0`
- Invariant: Every output and event cursor on the exec branch is an observation position only, and the Core Process ID is the sole Process identity coordinate; neither is accepted in an identity, target, precondition, or authority position, and a native execution identifier is accepted in none of them.
- Minimum witness: A Process-control request whose target coordinate is an output cursor or a native PID rather than the Core Process ID.
- Required diagnostic: identifies `IDE-020`, names `process.status.output.cursor`, `process.id`, `exec.control.coordinate`, and states the remediation without disclosing secret values.

### Packet E durable acceptance, idempotency, and recovery

#### `OPA-001` Create rejected after durable creation intent exists

- Owner: `core`
- First-sound phase: `C0`
- Rejection deadline: `D0`
- Invariant: A CreateSandbox call returns a request rejection only while Core proves that no Operation, no dispatchable effect intent, no external invocation, and no recoverable accepted result exists; otherwise it is accepted and every later outcome is embedded in its Operation.
- Minimum witness: A CreateSandbox that returns a request rejection after its effect intent was durably recorded.
- Required diagnostic: identifies `OPA-001`, names `operation.id`, `operation.acceptedAt`, `create.idempotencyKey`, and states the remediation without disclosing secret values.

#### `OPA-002` Live request rejected after durable mutation intent exists

- Owner: `core`
- First-sound phase: `L0`
- Rejection deadline: `L1`
- Invariant: A live Sandbox, Process-signal, Snapshot, or Fork mutation returns a request rejection only while Core proves that no Operation, no dispatchable effect intent, no external invocation, and no recoverable accepted result exists.
- Minimum witness: A live mutation that returns a request rejection after its Operation and effect intent were durably committed.
- Required diagnostic: identifies `OPA-002`, names `operation.id`, `operation.acceptedAt`, `operation.target`, and states the remediation without disclosing secret values.

#### `OPA-003` Exec rejected after durable execution intent exists

- Owner: `core`
- First-sound phase: `E0`
- Rejection deadline: `E1`
- Invariant: An Exec returns a request rejection only while Core proves that no Process, no dispatchable effect intent, no external invocation, and no recoverable accepted result exists.
- Minimum witness: An Exec that returns a request rejection after its Core Process ID and launch token were durably allocated.
- Required diagnostic: identifies `OPA-003`, names `process.id`, `process.acceptedAt`, `exec.idempotencyKey`, and states the remediation without disclosing secret values.

#### `OPA-004` Launch dispatched before its acceptance commit

- Owner: `core`
- First-sound phase: `C0`
- Rejection deadline: `D0`
- Invariant: No launch or other external creation effect is dispatched before Core atomically commits the Operation handle, canonical request and digest, preallocated Sandbox identity, idempotency binding, allocated runtime epoch, effect intent, and effect-authority epoch.
- Minimum witness: A launch dispatched to a driver before the Operation's effect intent and effect-authority epoch were committed.
- Required diagnostic: identifies `OPA-004`, names `operation.id`, `operation.effectIntent`, `operation.effectAuthorityEpoch`, and states the remediation without disclosing secret values.

#### `OPA-005` Live effect dispatched before its acceptance commit

- Owner: `core`
- First-sound phase: `L0`
- Rejection deadline: `L1`
- Invariant: No live external effect is dispatched before Core atomically commits the Operation handle, canonical request and digest, sealed target with every applicable freshness precondition, idempotency binding, effect intent, and effect-authority epoch.
- Minimum witness: A live external effect dispatched before its Operation handle and effect intent were committed.
- Required diagnostic: identifies `OPA-005`, names `operation.id`, `operation.effectIntent`, `operation.effectAuthorityEpoch`, and states the remediation without disclosing secret values.

#### `OPA-006` Exec dispatched before its acceptance commit

- Owner: `core`
- First-sound phase: `E0`
- Rejection deadline: `E1`
- Invariant: No Exec is dispatched before Core atomically commits the Core Process ID, canonical request and digest, exact Sandbox runtime reference, idempotency binding, launch token, effect intent, and effect-authority epoch.
- Minimum witness: An Exec dispatched before its Core Process ID and launch token were durably committed.
- Required diagnostic: identifies `OPA-006`, names `process.id`, `process.launchToken`, `process.sandboxRuntimeRef`, and states the remediation without disclosing secret values.

#### `OPA-007` Create replay rejected against current mutable state

- Owner: `core`
- First-sound phase: `C0`
- Rejection deadline: `C0`
- Invariant: Idempotency lookup for a CreateSandbox request runs immediately after authorization and canonicalization and before target-state, capability, concurrency, capacity, and quota checks, so an equal replay recovers its original handle.
- Minimum witness: An equal CreateSandbox replay rejected for quota exhaustion instead of returning its original Operation.
- Required diagnostic: identifies `OPA-007`, names `create.idempotencyKey`, `operation.id`, and states the remediation without disclosing secret values.

#### `OPA-008` Live replay rejected against current mutable state

- Owner: `core`
- First-sound phase: `L0`
- Rejection deadline: `L0`
- Invariant: Idempotency lookup for a live mutation runs immediately after authorization and canonicalization and before lifecycle-state, concurrency, capacity, and quota checks, so a retry of an accepted mutation recovers its original Operation instead of being rejected as invalid for the current state.
- Minimum witness: An equal replay of an accepted Stop rejected as invalid for the current Sandbox phase.
- Required diagnostic: identifies `OPA-008`, names `operation.idempotencyCoordinate`, `operation.id`, `sandbox.status.phase`, and states the remediation without disclosing secret values.

#### `OPA-009` Exec replay rejected against current mutable state

- Owner: `core`
- First-sound phase: `E0`
- Rejection deadline: `E0`
- Invariant: Idempotency lookup for an Exec runs immediately after authorization and canonicalization and before execution-admission, concurrency, capacity, and quota checks, so an equal replay recovers its original Process.
- Minimum witness: An equal Exec replay rejected for a concurrency ceiling instead of returning its original Process.
- Required diagnostic: identifies `OPA-009`, names `exec.idempotencyKey`, `process.id`, `sandbox.executionAdmission`, and states the remediation without disclosing secret values.

#### `OPA-010` Live idempotency coordinate rebound to a different intent

- Owner: `core`
- First-sound phase: `L0`
- Rejection deadline: `L0`
- Invariant: One authenticated scope, method, and idempotency key binds exactly one canonical request digest for its published recovery window, so an equal replay returns the original Operation and a conflicting replay is rejected without dispatching any effect.
- Minimum witness: A live mutation replay under an existing idempotency coordinate with a different canonical digest that is accepted and dispatched.
- Required diagnostic: identifies `OPA-010`, names `operation.idempotencyCoordinate`, `operation.canonicalDigest`, `operation.id`, and states the remediation without disclosing secret values.

#### `OPA-011` Exec idempotency coordinate rebound to a different intent

- Owner: `core`
- First-sound phase: `E0`
- Rejection deadline: `E0`
- Invariant: One authenticated scope, method, and idempotency key binds exactly one canonical Exec digest for its published recovery window, so an equal replay returns the original Process and a conflicting replay is rejected without dispatching any execution.
- Minimum witness: An Exec replay under an existing idempotency coordinate with a different canonical Exec digest that is accepted and dispatched.
- Required diagnostic: identifies `OPA-011`, names `exec.idempotencyKey`, `process.canonicalDigest`, `process.id`, and states the remediation without disclosing secret values.

#### `OPA-012` Canonical request identity includes transport or presentation fields

- Owner: `core`
- First-sound phase: `L0`
- Rejection deadline: `L0`
- Invariant: The canonical request digest excludes transport-only fields, trace identifiers, and correlation metadata, and includes every field able to change target, authority, effect, policy, result, or postcondition.
- Minimum witness: Two otherwise identical live mutations differing only in trace identifier that produce different canonical digests.
- Required diagnostic: identifies `OPA-012`, names `operation.canonicalDigest`, `operation.correlationMetadata`, and states the remediation without disclosing secret values.

#### `OPA-013` Retired create idempotency record silently authorizes a new effect

- Owner: `core`
- First-sound phase: `C0`
- Rejection deadline: `C0`
- Invariant: A CreateSandbox replay whose idempotency coordinate is retired or older than the published recovery window returns a recovery error carrying its tagged prior-acceptance evidence and never becomes a new accepted creation.
- Minimum witness: A CreateSandbox replay under a retired idempotency coordinate that is accepted as a new creation.
- Required diagnostic: identifies `OPA-013`, names `create.idempotencyKey`, `error.recovery`, `operation.id`, and states the remediation without disclosing secret values.

#### `OPA-014` Retired live idempotency record silently authorizes a new mutation

- Owner: `core`
- First-sound phase: `L0`
- Rejection deadline: `L0`
- Invariant: A live mutation replay whose idempotency coordinate is retired or older than the published recovery window returns a recovery error carrying its tagged prior-acceptance evidence and never becomes a new accepted mutation.
- Minimum witness: A live mutation replay under a retired idempotency coordinate that is accepted as a new mutation.
- Required diagnostic: identifies `OPA-014`, names `operation.idempotencyCoordinate`, `error.recovery`, `operation.id`, and states the remediation without disclosing secret values.

#### `OPA-015` Retired exec idempotency record silently authorizes a new execution

- Owner: `core`
- First-sound phase: `E0`
- Rejection deadline: `E0`
- Invariant: An Exec replay whose idempotency coordinate is retired or older than the published recovery window returns a recovery error carrying its tagged prior-acceptance evidence and never becomes a new accepted execution.
- Minimum witness: An Exec replay under a retired idempotency coordinate that is accepted as a new execution.
- Required diagnostic: identifies `OPA-015`, names `exec.idempotencyKey`, `error.recovery`, `process.id`, and states the remediation without disclosing secret values.

#### `OPA-016` Terminal failed Operation automatically replayed as a new attempt

- Owner: `core`
- First-sound phase: `L0`
- Rejection deadline: `L0`
- Invariant: An accepted terminal failure is recovered as the original Operation's outcome, and creating a genuinely new attempt requires a new idempotency key together with operation-specific authority to attempt it again.
- Minimum witness: A replay under the coordinate of a terminally failed Operation that automatically dispatches a fresh attempt.
- Required diagnostic: identifies `OPA-016`, names `operation.idempotencyCoordinate`, `operation.outcome`, `operation.id`, and states the remediation without disclosing secret values.

#### `OPA-017` Cancellation request recorded as a cancellation fact

- Owner: `core`
- First-sound phase: `L0`
- Rejection deadline: `L1`
- Invariant: An accepted cancellation request monotonically records cancel_requested on the existing Operation and allocates no new Operation, leaving that Operation the sole authority for its terminal outcome.
- Minimum witness: A CancelOperation that records its target Operation as cancelled, or that allocates a second Operation to represent the cancellation.
- Required diagnostic: identifies `OPA-017`, names `operation.id`, `operation.state`, `operation.cancellationRequestedAt`, and states the remediation without disclosing secret values.

#### `OPA-018` Representation and idempotency result committed separately

- Owner: `core`
- First-sound phase: `L0`
- Rejection deadline: `L1`
- Invariant: An atomic Core-record update commits the new representation, its resulting revision, the idempotency binding, and the recoverable committed response in one commit, so an equal replay returns that response without applying the update again.
- Minimum witness: A metadata update whose representation is committed before its idempotency binding, so an equal replay applies the update a second time.
- Required diagnostic: identifies `OPA-018`, names `sandbox.etag`, `live.metadata`, `live.expiration`, and states the remediation without disclosing secret values.

#### `OPA-019` Non-atomic record storage exposed for atomic update methods

- Owner: `operator`
- First-sound phase: `OC0`
- Rejection deadline: `O0`
- Invariant: A Core deployment whose record storage cannot commit the representation and its idempotency result atomically fails admission for the atomic-update methods rather than advertising them or substituting a durable Operation.
- Minimum witness: A Core deployment on non-transactional record storage that still advertises UpdateSandboxMetadata as an atomic-update method.
- Required diagnostic: identifies `OPA-019`, names `operator.recordStorage.atomicCommit`, `operator.advertisedMethods`, and states the remediation without disclosing secret values.

#### `OPA-020` External effect attempted before its recovery classification is recorded

- Owner: `core`
- First-sound phase: `D0`
- Rejection deadline: `D0`
- Invariant: Before each external effect attempt on the launch traversal Core durably records the attempt with its exact parameters together with one of the four locked recovery classes: no durable intent, provider idempotency token available, external identity discoverable for adoption, or none available.
- Minimum witness: An external launch effect dispatched with no durable attempt record naming its recovery class.
- Required diagnostic: identifies `OPA-020`, names `driver.effectAttempt`, `driver.effectAttempt.recoveryClass`, `operation.effectIntent`, and states the remediation without disclosing secret values.

#### `OPA-021` Live external effect attempted before its recovery classification is recorded

- Owner: `core`
- First-sound phase: `L0`
- Rejection deadline: `L1`
- Invariant: Before dispatching any external effect on the live-mutation traversal, Core durably records the attempt with its exact parameters together with one of the four locked recovery classes — no durable intent, provider idempotency token available, external identity discoverable for adoption, or none available — and reports ambiguity with quarantine when no class applies.
- Minimum witness: A live external effect dispatched with no durable attempt record naming its recovery class.
- Required diagnostic: identifies `OPA-021`, names `operation.effectAttempt`, `operation.effectAttempt.recoveryClass`, `operation.effectAttempt.parameters`, and states the remediation without disclosing secret values.

#### `OPA-022` Exec external effect attempted before its recovery classification is recorded

- Owner: `core`
- First-sound phase: `E0`
- Rejection deadline: `E1`
- Invariant: Before dispatching any external effect on the Exec traversal, Core durably records the attempt with its exact parameters together with one of the four locked recovery classes — no durable intent, provider idempotency token available, external identity discoverable for adoption, or none available — and reports ambiguity with quarantine when no class applies.
- Minimum witness: An exec external effect dispatched with no durable attempt record naming its recovery class.
- Required diagnostic: identifies `OPA-022`, names `process.effectAttempt`, `process.effectAttempt.recoveryClass`, `process.effectAttempt.parameters`, and states the remediation without disclosing secret values.

#### `OPA-023` Create idempotency coordinate rebound to a different intent

- Owner: `core`
- First-sound phase: `C0`
- Rejection deadline: `C0`
- Invariant: One authenticated scope, method, and idempotency key binds exactly one canonical CreateSandbox request digest for its published recovery window; a replay under the same coordinate with a different canonical digest is refused as a conflict and dispatches no effect.
- Minimum witness: A CreateSandbox replay under an existing idempotency coordinate with a different canonical digest that is accepted.
- Required diagnostic: identifies `OPA-023`, names `create.idempotencyKey`, `operation.canonicalRequest`, `operation.canonicalDigest`, and states the remediation without disclosing secret values.

### Packet E outcome proof and terminal immutability

#### `PRF-001` Launch Operation terminalized beyond its proven evidence

- Owner: `core`
- First-sound phase: `R1`
- Rejection deadline: `R1`
- Invariant: A launch Operation commits `succeeded` only when every possibility remaining under Core's evidence satisfies its exact success postcondition with cancellation `notRequested` or proven `lost`, commits `failed` or `cancelled` only when no remaining possibility satisfies that postcondition, every possibility has `mutationAuthority = quiesced`, and residual effects are known, and otherwise commits `unknown` with its exact ambiguity variant.
- Minimum witness: A launch Operation committed `succeeded` while its evidence still admits a possibility in which the runtime never started.
- Required diagnostic: identifies `PRF-001`, names `operation.outcome`, `operation.outcome.failed.cause`, `operation.outcome.cancelled.proof`, and states the remediation without disclosing secret values.

#### `PRF-002` Live mutation Operation terminalized beyond its proven evidence

- Owner: `core`
- First-sound phase: `L1`
- Rejection deadline: `L1`
- Invariant: A live Sandbox, Snapshot, or Process-targeted mutation Operation commits `succeeded`, `failed`, or `cancelled` only when its exact evidence predicate for that arm holds over every remaining possibility, and otherwise commits `unknown`; a received cancellation request, an unresolved `cancellation = requested`, an internal timer expiry, or an RPC deadline never selects a definite arm.
- Minimum witness: A live mutation committed `cancelled` because an RPC deadline expired while the external effect could still act.
- Required diagnostic: identifies `PRF-002`, names `operation.outcome`, `operation.outcome.unknown.missingProofs`, `operation.cancellation`, and states the remediation without disclosing secret values.

#### `PRF-003` Exec dispatch outcome committed beyond its proven evidence

- Owner: `core`
- First-sound phase: `E1`
- Rejection deadline: `E1`
- Invariant: An accepted Exec dispatch commits a terminal Process outcome only when every possibility remaining under Core's evidence satisfies that outcome's exact predicate with quiesced dispatch authority and known residuals; every other nonempty knowledge set leaves the Process in reconcilable `unknown`.
- Minimum witness: A Process committed as exited from an observation not bound to its launch token.
- Required diagnostic: identifies `PRF-003`, names `process.state`, `process.termination`, `process.evidence.knowledgeSet`, and states the remediation without disclosing secret values.

#### `PRF-004` Teardown Operation terminalized beyond its proven evidence

- Owner: `core`
- First-sound phase: `T0`
- Rejection deadline: `T0`
- Invariant: A Stop, Delete, or other teardown Operation commits `succeeded`, `failed`, or `cancelled` only when its exact evidence predicate holds over every remaining possibility, and otherwise commits `unknown`; a cleanup attempt, a missing observation, native resource absence, or a provider acknowledgement never substitutes for cleanup completion, target absence, descendant quiescence, or the required Core postcondition.
- Minimum witness: A Delete committed `succeeded` because the provider returned not-found for the instance.
- Required diagnostic: identifies `PRF-004`, names `operation.outcome`, `operation.outcome.failed.cause`, `operation.residualObligations`, and states the remediation without disclosing secret values.

#### `PRF-005` Terminal Operation result rewritten

- Owner: `core`
- First-sound phase: `R1`
- Rejection deadline: `R1`
- Invariant: An Operation's committed terminal outcome and its payload are immutable, and later evidence, reconciliation, adoption, quarantine, or cleanup may only append a linked successor record that references the unchanged predecessor.
- Minimum witness: A launch Operation whose committed `unknown` outcome is rewritten to `succeeded` by a later reconciliation.
- Required diagnostic: identifies `PRF-005`, names `operation.outcome`, `operation.revision`, `operation.successorLinks`, and states the remediation without disclosing secret values.

#### `PRF-006` Compensation represented as rollback

- Owner: `core`
- First-sound phase: `T0`
- Rejection deadline: `T0`
- Invariant: A compensating effect recorded on the teardown or cleanup traversal is recorded as a new forward effect with its own durable record, evidence, and outcome, and never as erasure, reversal, or negation of the compensated Operation's external history -- including when in-sandbox state was restored from a Snapshot or filesystem capture.
- Minimum witness: A cleanup that marks the compensated Operation's external effects as rolled back.
- Required diagnostic: identifies `PRF-006`, names `operation.compensates`, `operation.outcome`, `operation.coreResolution`, and states the remediation without disclosing secret values.

#### `PRF-007` Observation deadline mutating or terminalizing its target

- Owner: `core`
- First-sound phase: `L0`
- Rejection deadline: `L0`
- Invariant: An observation, wait, or watch deadline ends only that observation and never cancels, mutates, terminalizes, requests cancellation of, or advances the durable state of the observed Sandbox, Operation, or Snapshot.
- Minimum witness: A Wait whose deadline expiry marks the observed Operation as timed out.
- Required diagnostic: identifies `PRF-007`, names `observation.deadline`, `operation.state`, `process.state`, and states the remediation without disclosing secret values.

#### `PRF-008` Interrupted effect attempt resolved without its committed intent

- Owner: `core`
- First-sound phase: `R0`
- Rejection deadline: `R1`
- Invariant: An effect attempt interrupted after dispatch is resolved only by evidence bound to its own committed effect intent, launch token, exact external identity, and authority epoch, and is otherwise terminalized `unknown`; it is never resolved by a fresh attempt, by a differently identified native execution, or by assuming the attempt's outcome.
- Minimum witness: An interrupted launch attempt resolved by dispatching a fresh attempt and adopting its outcome as the original's.
- Required diagnostic: identifies `PRF-008`, names `operation.effectIntent`, `operation.launchToken`, `operation.externalIdentity`, and states the remediation without disclosing secret values.

#### `PRF-009` Ambiguous launch outcome used as successor-effect permission

- Owner: `core`
- First-sound phase: `R1`
- Rejection deadline: `R1`
- Invariant: A launch Operation that terminalized `unknown` authorizes no relaunch, replacement, or adoption effect against the same intent, and any successor launch requires an independently proven fencing boundary, an exact adoption identity, or a newly authorized caller request with its own accepted intent.
- Minimum witness: A relaunch dispatched against the same intent solely because the prior launch Operation terminalized `unknown`.
- Required diagnostic: identifies `PRF-009`, names `operation.outcome.unknown.missingProofs`, `operation.coreResolution`, `operation.successorLinks`, and states the remediation without disclosing secret values.

#### `PRF-010` Ambiguous live outcome used as successor-effect permission

- Owner: `core`
- First-sound phase: `L1`
- Rejection deadline: `L1`
- Invariant: A live mutation Operation that terminalized `unknown` authorizes no repeated, replacement, or compensating external effect against the same target and epoch until fenced evidence, exact adoption identity, or a newly authorized request establishes the successor's authority.
- Minimum witness: A live external effect re-dispatched against the same target and epoch because the prior Operation terminalized `unknown`.
- Required diagnostic: identifies `PRF-010`, names `operation.outcome.unknown.missingProofs`, `operation.coreResolution`, `operation.target`, and states the remediation without disclosing secret values.

#### `PRF-011` Ambiguous teardown outcome used as cleanup or destruction permission

- Owner: `core`
- First-sound phase: `T0`
- Rejection deadline: `T0`
- Invariant: A Stop or Delete Operation that terminalized `unknown`, or `failed` with residual obligations, authorizes no assumed-complete cleanup, no identity release, and no successor destructive effect until an actor holding current authority durably discharges each exact residual obligation.
- Minimum witness: A Delete that terminalized `unknown` whose Sandbox identity is nonetheless released and tombstoned as complete.
- Required diagnostic: identifies `PRF-011`, names `operation.outcome.unknown.missingProofs`, `operation.residualObligations`, `operation.coreResolution`, and states the remediation without disclosing secret values.

#### `PRF-012` Launch-branch compensating effect represented as rollback

- Owner: `core`
- First-sound phase: `R1`
- Rejection deadline: `R1`
- Invariant: A compensating effect on the launch traversal is recorded as a new forward effect with its own durable record, evidence, and outcome, never as erasure, reversal, or negation of the compensated Operation's external history.
- Minimum witness: A failed launch whose compensating teardown marks the launch's external effects as never having occurred.
- Required diagnostic: identifies `PRF-012`, names `operation.compensates`, `operation.outcome`, `operation.externalEffectLedger`, and states the remediation without disclosing secret values.

#### `PRF-013` Terminal Operation result rewritten on a live reconciliation traversal

- Owner: `core`
- First-sound phase: `L1`
- Rejection deadline: `L1`
- Invariant: An Operation's committed terminal outcome and its payload are immutable on the live mutation traversal, and later evidence, reconciliation, adoption, quarantine, or cleanup resolving at the live outcome station may only append a linked successor record that references the unchanged predecessor.
- Minimum witness: A live mutation Operation whose committed `unknown` outcome is rewritten to `failed` by a later reconciliation.
- Required diagnostic: identifies `PRF-013`, names `operation.outcome`, `operation.revision`, `operation.successorLinks`, and states the remediation without disclosing secret values.

#### `PRF-014` Terminal Operation result rewritten on a teardown or cleanup reconciliation traversal

- Owner: `core`
- First-sound phase: `T0`
- Rejection deadline: `T0`
- Invariant: An Operation's committed terminal outcome and its payload are immutable on the teardown and cleanup traversal, and later evidence, reconciliation, adoption, quarantine, or cleanup resolving at teardown may only append a linked successor record that references the unchanged predecessor.
- Minimum witness: A teardown Operation whose committed terminal outcome is rewritten by a later cleanup reconciliation.
- Required diagnostic: identifies `PRF-014`, names `operation.outcome`, `operation.revision`, `operation.successorLinks`, and states the remediation without disclosing secret values.

### Packet E execution admission and Process launch authority

#### `ADM-001` Generic, compound, or provider-native verb on the public surface

- Owner: `live`
- First-sound phase: `L0`
- Rejection deadline: `L0`
- Invariant: The public caller-facing Core lifecycle and control union contains only named, typed, resource-oriented methods with one exact declared postcondition each, and admits no generic action, compound convenience verb, archive or migration verb, or provider-native verb.
- Minimum witness: One `InvokeAction` or `RestartSandbox` request admitted by the public method union.
- Required diagnostic: identifies `ADM-001`, names `request.method`, `api.publicMethodUnion`, and states the remediation without disclosing secret values.

#### `ADM-002` Public method admitted without one exact target-independent postcondition

- Owner: `live`
- First-sound phase: `L0`
- Rejection deadline: `L0`
- Invariant: Every admitted public method declares one exact target-independent success postcondition that capability gating narrows availability of but no target profile, driver, or provider may reinterpret.
- Minimum witness: One admitted method whose success postcondition is defined only by whichever driver serves it.
- Required diagnostic: identifies `ADM-002`, names `request.method`, `operationContract.successPredicate`, and states the remediation without disclosing secret values.

#### `ADM-003` Generic Sandbox update method

- Owner: `live`
- First-sound phase: `L0`
- Rejection deadline: `L0`
- Invariant: Sandbox representation changes use only the two narrow etag-guarded operations UpdateSandboxMetadata and SetSandboxExpiration, and no generic update method spans metadata, expiration, resources, network policy, runtime replacement, and provider tier under one contract.
- Minimum witness: One `UpdateSandbox` request carrying both a label and a resource allocation.
- Required diagnostic: identifies `ADM-003`, names `request.method`, `live.update`, and states the remediation without disclosing secret values.

#### `ADM-004` Attach, connect, detach, shell, or session as a Core method

- Owner: `live`
- First-sound phase: `L0`
- Rejection deadline: `L0`
- Invariant: Attachment, connection, shell, and Session ergonomics remain adapter-owned helpers composed from Sandbox reads, Exec, Process I/O, and the named lifecycle methods, and never become Core methods holding independent lifecycle authority.
- Minimum witness: One `AttachSandbox` method admitted on the Core surface and holding a lifecycle keepalive.
- Required diagnostic: identifies `ADM-004`, names `request.method`, `framework.session`, and states the remediation without disclosing secret values.

#### `ADM-005` Delete accepted against a Sandbox without a durable stopped proof

- Owner: `live`
- First-sound phase: `L0`
- Rejection deadline: `L0`
- Invariant: `DeleteSandbox` is admitted only against a Sandbox holding a current durable stopped proof and never performs a silent compound stop-then-delete; a system-originated expiry Delete is created at exactly the same station under the same proof and is linked to the Stop Operation whose outcome established it.
- Minimum witness: One `DeleteSandbox` admitted against a `running` Sandbox and silently stopping it first.
- Required diagnostic: identifies `ADM-005`, names `live.operation`, `sandbox.status.runtime.state`, `sandbox.expiration.action`, and states the remediation without disclosing secret values.

#### `ADM-006` Representation update changes runtime authority, epoch, or policy

- Owner: `live`
- First-sound phase: `L0`
- Rejection deadline: `L0`
- Invariant: An accepted `UpdateSandboxMetadata` or `SetSandboxExpiration` commits only the Core-owned representation record and its revision, leaving the runtime epoch, mutation authority, resolved Artifact policy, and running workload unchanged.
- Minimum witness: One metadata update whose commit also changes the resolved network policy.
- Required diagnostic: identifies `ADM-006`, names `live.metadata`, `live.expiration`, `sandbox.status.runtime.epoch`, and states the remediation without disclosing secret values.

#### `ADM-007` Exec accepted after execution admission closed or an expiry trigger was recorded

- Owner: `exec`
- First-sound phase: `E0`
- Rejection deadline: `E0`
- Invariant: An Exec request is admitted only while the bound Sandbox runtime's execution admission is durably accepting, and is refused with its exact typed reason once a lifecycle operation closes admission or an expiration instant is durably recorded as a system trigger.
- Minimum witness: One Exec accepted after `StopSandbox` durably closed execution admission.
- Required diagnostic: identifies `ADM-007`, names `exec.sandboxRuntimeRef`, `sandbox.status.execution.state`, `sandbox.status.execution.reason`, and states the remediation without disclosing secret values.

#### `ADM-008` Exec accepted against a provider-created epoch before Core sequences it

- Owner: `exec`
- First-sound phase: `E0`
- Rejection deadline: `E0`
- Invariant: An Exec is admitted against a runtime that a provider auto-wake, standby recovery, or lazy creation produced only after the Core has durably sequenced that runtime's epoch identity and execution admission.
- Minimum witness: One Exec admitted against a lazily created provider runtime with no Core epoch record.
- Required diagnostic: identifies `ADM-008`, names `exec.sandboxRuntimeRef`, `sandbox.status.runtime.epoch`, `operation.origin`, and states the remediation without disclosing secret values.

#### `ADM-009` Process launch dispatched under a revoked launch authority

- Owner: `core`
- First-sound phase: `E0`
- Rejection deadline: `E1`
- Invariant: A Process launch performs its first external dispatch only while its fenced launch-authority grant revalidates as current against the Core durable record.
- Minimum witness: One accepted Process dispatched externally after a concurrent Stop revoked its launch-authority grant.
- Required diagnostic: identifies `ADM-009`, names `process.status.state`, `process.launchAuthority`, `sandbox.status.execution.state`, and states the remediation without disclosing secret values.

#### `ADM-010` Process set captured before admission and launch authority close

- Owner: `core`
- First-sound phase: `L1`
- Rejection deadline: `L1`
- Invariant: A quiescing or absence-proving operation durably closes execution admission and revokes new Process launch authority before it snapshots the Process set of the current epoch.
- Minimum witness: One Stop that snapshots its Process set before the admission-closure record commits.
- Required diagnostic: identifies `ADM-010`, names `sandbox.status.execution.state`, `operation.capturedProcessSet`, `process.launchAuthority`, and states the remediation without disclosing secret values.

#### `ADM-011` Withheld launch authority regranted outside a succeeded same-epoch Resume

- Owner: `core`
- First-sound phase: `L1`
- Rejection deadline: `L1`
- Invariant: Launch authority withheld by a continuity-preserving Suspend is regranted only after the same-epoch ResumeSandbox Operation succeeds, while the Process's original deadline remains unexpired and no intervening TerminateProcess request exists.
- Minimum witness: One withheld Process granted launch authority while its Resume Operation was still nonterminal.
- Required diagnostic: identifies `ADM-011`, names `process.launchAuthority`, `operation.outcome`, `exec.deadline`, and states the remediation without disclosing secret values.

#### `ADM-012` Execution admission accepting on a launch traversal without a proven running epoch

- Owner: `core`
- First-sound phase: `R1`
- Rejection deadline: `R1`
- Invariant: A launch traversal publishes execution admission accepting only for a new runtime epoch proven present and executing under current fenced authority.
- Minimum witness: One launch publishing admission `accepting` while its new epoch was never observed executing.
- Required diagnostic: identifies `ADM-012`, names `sandbox.status.execution.state`, `sandbox.status.runtime.state`, `sandbox.status.runtime.epoch`, and states the remediation without disclosing secret values.

#### `ADM-013` Unsupported capability approximated by a driver

- Owner: `runtime`
- First-sound phase: `D0`
- Rejection deadline: `D0`
- Invariant: A driver reports an unsupported capability before any effect-producing work and never approximates it with a different native mechanism.
- Minimum witness: A driver serving a required memory-continuity suspend with a filesystem-retaining stop.
- Required diagnostic: identifies `ADM-013`, names `driver.input`, `driver.conformedCapabilities`, and states the remediation without disclosing secret values.

#### `ADM-014` Driver widens, narrows, or downgrades the requested postcondition

- Owner: `runtime`
- First-sound phase: `D0`
- Rejection deadline: `D0`
- Invariant: A driver's native lowering of a Core method establishes exactly the requested postcondition and never a colder, wider, or more destructive fallback.
- Minimum witness: A driver lowering a requested Suspend to a full stop because pause is unavailable.
- Required diagnostic: identifies `ADM-014`, names `driver.input`, `driver.nativeStep`, `operation.requestedPostcondition`, and states the remediation without disclosing secret values.

#### `ADM-015` Driver advertises Core Exec without full execution conformance

- Owner: `runtime`
- First-sound phase: `D0`
- Rejection deadline: `D0`
- Invariant: A driver advertises Core Exec only when it proves a targetable execution containment unit covering the Process and its owned descendants, durable output spooling with stable byte cursors and explicit truncation, exact terminal evidence, stdin ownership and close semantics, provable Process termination, and adoption of the same attempted execution after control-plane failure.
- Minimum witness: A driver advertising Core Exec while its output spool has no stable byte cursor.
- Required diagnostic: identifies `ADM-015`, names `driver.conformedCapabilities`, `driver.execConformance`, and states the remediation without disclosing secret values.

#### `ADM-016` Artifact asserts a dynamic Core or runtime fact

- Owner: `artifact`
- First-sound phase: `A1`
- Rejection deadline: `N0`
- Invariant: An Artifact Definition declares only frontend-independent static facts and cannot express current Sandbox or Process state, current runtime epoch or etag, resource capacity, provider admission, concurrent Operations, Snapshot retention or reference state, expiration races, provider availability, or evidence freshness.
- Minimum witness: One Artifact field asserting that the target Sandbox is currently `running`.
- Required diagnostic: identifies `ADM-016`, names `artifact.definition`, `artifact.targets`, and states the remediation without disclosing secret values.

#### `ADM-017` Start accepted against a Sandbox without a durable stopped proof

- Owner: `live`
- First-sound phase: `L0`
- Rejection deadline: `L0`
- Invariant: `StartSandbox` is admitted only against a Sandbox holding a current durable stopped proof, and never restarts a runtime that is still present under an unretired epoch.
- Minimum witness: One `StartSandbox` admitted against a Sandbox whose previous epoch is still unretired.
- Required diagnostic: identifies `ADM-017`, names `live.operation`, `sandbox.status.runtime.state`, `sandbox.status.runtime.epoch`, and states the remediation without disclosing secret values.

#### `ADM-018` Launch dispatched without operator re-admission of its resolved placement

- Owner: `operator`
- First-sound phase: `O0`
- Rejection deadline: `D0`
- Invariant: A launch is dispatched only after the operator admission plane re-admits its resolved placement, capacity, and tier for the current epoch; a placement admitted for a prior launch never carries forward.
- Minimum witness: One launch dispatched under the operator admission record granted to the previous epoch's launch.
- Required diagnostic: identifies `ADM-018`, names `operator.admission.placement`, `operator.admission.capacity`, `operator.admission.tier`, and states the remediation without disclosing secret values.

#### `ADM-019` Statically absent cross-target capability deferred to launch without an explicit target branch

- Owner: `artifact`
- First-sound phase: `A0`
- Rejection deadline: `A1`
- Invariant: A cross-target capability, semantic, or ceiling that is statically absent from an enabled target is rejected during Artifact validation unless the Artifact declares an explicit named target branch for it, and is never deferred to workload launch or runtime discovery.
- Minimum witness: One Artifact requiring a device only its microVM target provides while its process target is enabled with no branch.
- Required diagnostic: identifies `ADM-019`, names `artifact.targets`, `artifact.capabilities`, `artifact.targetBranch`, and states the remediation without disclosing secret values.

### Packet E concurrency lanes and operation-pair compatibility

#### `CNC-001` Stale provider event treated as serialization authority

- Owner: `runtime`
- First-sound phase: `D0`
- Rejection deadline: `D0`
- Invariant: A decoded provider, host, or VMM event is retained as non-authoritative evidence and is refused as a state transition whenever the authority epoch it belongs to is no longer current.
- Minimum witness: One provider event whose authority epoch is one behind the current epoch is decoded and applied as a runtime state transition.
- Required diagnostic: identifies `CNC-001`, names `driver.evidence.providerEvent`, `driver.evidence.authorityEpoch`, `capability.authorityEpoch`, and states the remediation without disclosing secret values.

#### `CNC-002` Incompatible concurrent lifecycle mutations both receive authority

- Owner: `core`
- First-sound phase: `L0`
- Rejection deadline: `L0`
- Invariant: At most one nonterminal Operation holds the fenced Sandbox lifecycle-mutation lane, and a request whose ordered operation pair with the lane holder is not an explicitly permitted row of the compatibility ledger is refused with the typed conflict naming that active Operation.
- Minimum witness: Concurrent `ResumeSandbox` and `StopSandbox` requests both accepted as nonterminal Operations.
- Required diagnostic: identifies `CNC-002`, names `sandbox.status.lifecycleOperation`, `live.operation.kind`, `operation.conflict.activeOperationId`, and states the remediation without disclosing secret values.

### Packet E runtime policy non-widening and capability rejection

#### `POL-001` Unsupported capability approximated at creation

- Owner: `create`
- First-sound phase: `C0`
- Rejection deadline: `C0`
- Invariant: A creation requiring a capability-gated Core behavior resolves a target profile advertising that exact conformed capability, and an unadvertised capability is rejected rather than approximated by a different mechanism, a weaker guarantee, or a provider default.
- Minimum witness: A creation requiring memory-continuity suspend resolved onto a profile advertising only filesystem-retaining stop.
- Required diagnostic: identifies `POL-001`, names `create.requiredCapabilities`, `resolution.effectiveCapabilities`, `create.profile`, and states the remediation without disclosing secret values.

#### `POL-002` Expiration removal widens a policy-owned lifecycle bound

- Owner: `live`
- First-sound phase: `L0`
- Rejection deadline: `L0`
- Invariant: `SetSandboxExpiration` assigns or removes only the caller-managed schedule, and every Artifact hard ceiling and Managed-Sandbox lifecycle policy in force remains binding after the update.
- Minimum witness: One expiration removal that leaves the Sandbox with no Artifact lifetime ceiling in force.
- Required diagnostic: identifies `POL-002`, names `live.setExpiration.expiration`, `sandbox.expiration`, `sandbox.policy.lifecycleCeilings`, and states the remediation without disclosing secret values.

#### `POL-003` Restore widens immutable Artifact policy

- Owner: `live`
- First-sound phase: `L0`
- Rejection deadline: `L0`
- Invariant: A same-Sandbox `RestoreSandbox` uses the exact immutable environment, filesystem, network, identity, device, secret, and target-profile policy pinned by the Sandbox's Artifact, and never replaces or widens any of them.
- Minimum witness: One `RestoreSandbox` admitted with a network policy wider than the Artifact's pinned one.
- Required diagnostic: identifies `POL-003`, names `live.restore`, `sandbox.artifact.policy`, `sandbox.policy.lifecycleCeilings`, and states the remediation without disclosing secret values.

#### `POL-004` Restore-as-create widens immutable Artifact policy

- Owner: `create`
- First-sound phase: `C0`
- Rejection deadline: `C0`
- Invariant: A restore-as-create request selects or refines permitted access within the pinned Artifact's hard policy and never replaces or widens immutable environment, filesystem, network, identity, device, secret, or target-profile policy.
- Minimum witness: One restore-as-create request adding a device the pinned Artifact does not permit.
- Required diagnostic: identifies `POL-004`, names `create.restoreFrom`, `artifact.policy`, `create.policySelection`, and states the remediation without disclosing secret values.

### Packet E Sandbox runtime-state truth and status projection

#### `SBX-001` Create request omits its resolved initial runtime selection

- Owner: `create`
- First-sound phase: `C0`
- Rejection deadline: `C0`
- Invariant: Every accepted CreateSandbox request and its Operation record carry the resolved `initialRuntime` value drawn from the closed `running`/`stopped` vocabulary, with no CLI, SDK, named-profile, schema, or provider default applied after acceptance or left invisible in the canonical request.
- Minimum witness: A CreateSandbox request with `initialRuntime` absent that a CLI or schema default fills in after acceptance.
- Required diagnostic: identifies `SBX-001`, names `create.initialRuntime`, `operation.request.initialRuntime`, `operation.canonicalRequest`, and states the remediation without disclosing secret values.

#### `SBX-002` Initially stopped creation performs launch effects

- Owner: `core`
- First-sound phase: `C0`
- Rejection deadline: `C0`
- Invariant: A creation whose resolved `initialRuntime` is `stopped` commits a durable Sandbox whose runtime state is `stopped` and never enters `provisioning` or performs a launch effect.
- Minimum witness: A creation resolved to `stopped` that allocates a runtime epoch or dispatches a driver launch before any Start.
- Required diagnostic: identifies `SBX-002`, names `create.initialRuntime`, `sandbox.status.runtime.state`, and states the remediation without disclosing secret values.

#### `SBX-003` Caller writes Sandbox runtime, desired state, or a presentation label

- Owner: `live`
- First-sound phase: `L0`
- Rejection deadline: `L0`
- Invariant: Sandbox `status` -- its `runtime`, `execution`, `lifecycleOperation`, and `conditions` members -- is an output-only projection: no public request type carries a runtime state, a caller-writable desired runtime state, or a verb-derived presentation label as input, so every lifecycle change is an explicit named command and never a reconciled declaration.
- Minimum witness: One live request type carrying a caller-populated `desiredRuntimeState` or `status` field.
- Required diagnostic: identifies `SBX-003`, names `live.request`, `request.desiredRuntimeState`, `sandbox.status.runtime.state`, and states the remediation without disclosing secret values.

#### `SBX-004` Verb-derived presentation label stored as Sandbox state

- Owner: `core`
- First-sound phase: `L1`
- Rejection deadline: `L1`
- Invariant: Sandbox runtime state is exactly one of `provisioning`, `running`, `suspended`, `stopped`, or `unknown`; every derived presentation label -- creating, starting, suspending, resuming, stopping, restoring, deleting, snapshotting, migrating -- is recomputed at read time from the durable Operation and that authoritative status, and is never independently stored or used as the serialization oracle.
- Minimum witness: One Sandbox status record storing `stopping` as its runtime state.
- Required diagnostic: identifies `SBX-004`, names `sandbox.status.runtime.state`, `sandbox.status.lifecycleOperation`, `operation.kind`, and states the remediation without disclosing secret values.

#### `SBX-005` Execution admission accepting without a proven running epoch

- Owner: `core`
- First-sound phase: `L1`
- Rejection deadline: `L1`
- Invariant: A live operation publishes execution admission `accepting` only for a retained runtime epoch proven present and executing under current fenced authority with runtime state `running`; every other runtime state commits `closed` with a typed reason.
- Minimum witness: One status commit publishing execution admission `accepting` while runtime state is `provisioning`.
- Required diagnostic: identifies `SBX-005`, names `sandbox.status.execution.state`, `sandbox.status.execution.reason`, `sandbox.status.runtime.state`, and states the remediation without disclosing secret values.

#### `SBX-006` Suspended reported without proven quiescence and continuity

- Owner: `core`
- First-sound phase: `L1`
- Rejection deadline: `L1`
- Invariant: A `SuspendSandbox` Operation succeeds only when workload execution is proven quiesced, no Process can execute, the current runtime epoch and the capability-required memory and Process continuity are proven retained, and execution admission is committed `closed`.
- Minimum witness: A Suspend terminalized as succeeded while the driver returned no Process-continuity proof.
- Required diagnostic: identifies `SBX-006`, names `sandbox.status.runtime.state`, `sandbox.status.runtime.epoch`, `sandbox.status.execution.state`, and states the remediation without disclosing secret values.

#### `SBX-007` Driver reports Suspend or Resume without same-epoch continuity evidence

- Owner: `runtime`
- First-sound phase: `L1`
- Rejection deadline: `L1`
- Invariant: A driver reports a successful Suspend or Resume only by returning target-specific evidence that the identical runtime epoch, its retained memory, and its Process continuity survived the transition.
- Minimum witness: A driver Suspend report claiming success with no epoch or continuity probe attached.
- Required diagnostic: identifies `SBX-007`, names `driver.continuityEvidence`, `driver.reportedEpoch`, `sandbox.status.runtime.epoch`, and states the remediation without disclosing secret values.

#### `SBX-008` Cold fallback reported as a successful Resume

- Owner: `core`
- First-sound phase: `L1`
- Rejection deadline: `L1`
- Invariant: A `ResumeSandbox` Operation succeeds only when post-effect evidence proves the retained runtime epoch resumed under exclusive authority with control and conformance re-proven, and an observed cold fallback, replacement instance, or reconstruction terminates that Resume as failed or unresolved rather than as same-epoch continuation.
- Minimum witness: A Resume reported as succeeded after the provider cold-booted a replacement instance.
- Required diagnostic: identifies `SBX-008`, names `sandbox.status.runtime.epoch`, `sandbox.status.runtime.state`, `operation.result`, and states the remediation without disclosing secret values.

#### `SBX-009` Running resize hides reboot, replacement, or partial application

- Owner: `core`
- First-sound phase: `L1`
- Rejection deadline: `L1`
- Invariant: A `ResizeSandboxResources` Operation against a `running` Sandbox succeeds only when evidence proves the complete requested allocation was applied atomically in place with the current epoch retained and without reboot, runtime replacement, or Process identity loss.
- Minimum witness: A running resize reported as succeeded after only the memory dimension was applied.
- Required diagnostic: identifies `SBX-009`, names `live.resize.allocation`, `sandbox.status.runtime.epoch`, `sandbox.resources.applied`, and states the remediation without disclosing secret values.

#### `SBX-010` Stopped resize claims current provider capacity

- Owner: `core`
- First-sound phase: `L1`
- Rejection deadline: `L1`
- Invariant: A `ResizeSandboxResources` Operation against a `stopped` Sandbox commits the validated concrete allocation for the next Start only, allocating no runtime epoch and claiming no current provider capacity.
- Minimum witness: A stopped resize whose success record reports reserved provider capacity.
- Required diagnostic: identifies `SBX-010`, names `live.resize.allocation`, `sandbox.status.runtime.state`, `sandbox.resources.nextRuntimeAllocation`, and states the remediation without disclosing secret values.

#### `SBX-011` Stop lowered to a destructive provider delete

- Owner: `runtime`
- First-sound phase: `L1`
- Rejection deadline: `L1`
- Invariant: A driver lowering `StopSandbox` uses only native steps that end the current runtime epoch and establish containment absence for it, leaving the logical Sandbox and its retained state intact, and never substitutes a provider delete, destroy, permanent kill, or other destructive removal.
- Minimum witness: A driver serving one `StopSandbox` by issuing the provider's delete-instance call.
- Required diagnostic: identifies `SBX-011`, names `driver.loweredOperation`, `driver.nativeStep`, `operation.requestedPostcondition`, and states the remediation without disclosing secret values.

#### `SBX-012` Unprovable runtime state approximated as stopped or running

- Owner: `core`
- First-sound phase: `L1`
- Rejection deadline: `L1`
- Invariant: When runtime presence or absence, claimed-epoch continuity, exclusive effect authority, containment emptiness, or external-effect liveness cannot be safely established, the committed Sandbox runtime state is `unknown` with execution admission `closed`.
- Minimum witness: One lifecycle mutation committing `stopped` while containment emptiness was never proven.
- Required diagnostic: identifies `SBX-012`, names `sandbox.status.runtime.state`, `sandbox.status.execution.state`, `sandbox.status.conditions`, and states the remediation without disclosing secret values.

#### `SBX-013` Provider or adapter phase mapped to Core runtime state

- Owner: `runtime`
- First-sound phase: `D0`
- Rejection deadline: `D0`
- Invariant: A decoded provider, host, or VMM lifecycle phase, status enum, or handle state is retained as non-authoritative evidence and is never mapped by name onto a Core Sandbox runtime state.
- Minimum witness: A driver mapping the provider phase named `running` directly onto Core runtime state `running`.
- Required diagnostic: identifies `SBX-013`, names `driver.providerStatus`, `driver.decodedEvidence`, `sandbox.status.runtime.state`, and states the remediation without disclosing secret values.

#### `SBX-014` Launch succeeds before control, conformance, and admission are proven

- Owner: `core`
- First-sound phase: `R1`
- Rejection deadline: `R1`
- Invariant: A Create-running, Start, or same-Sandbox Restore Operation succeeds only when the new runtime epoch is observed present and executing and its declared control, conformance, and `accepting` execution-admission postconditions are each proven.
- Minimum witness: A Start reported as succeeded with the runtime observed present but the control-attachment probe never run.
- Required diagnostic: identifies `SBX-014`, names `sandbox.status.runtime.state`, `sandbox.status.execution.state`, `sandbox.status.conditions`, and states the remediation without disclosing secret values.

#### `SBX-015` Driver claims launch success without its declared probes

- Owner: `runtime`
- First-sound phase: `R1`
- Rejection deadline: `R1`
- Invariant: A launch driver reports success only after executing its declared control-attachment, conformance, and execution-admission probes against the exact new runtime epoch and returning their evidence.
- Minimum witness: A driver launch report claiming success while its declared execution-admission probe was skipped.
- Required diagnostic: identifies `SBX-015`, names `driver.launchProbes`, `driver.conformanceEvidence`, `sandbox.status.runtime.epoch`, and states the remediation without disclosing secret values.

#### `SBX-016` Provider acknowledgement treated as the required Core postcondition

- Owner: `runtime`
- First-sound phase: `R1`
- Rejection deadline: `R1`
- Invariant: Backend acceptance checkpoints such as OCI `created`, containerd task registration, VMM configuration, guest-agent handshake, or provider request acknowledgement are decoded evidence only, and each Core postcondition is proven by the evidence its own contract names.
- Minimum witness: A driver discharging the `running` postcondition with a provider request acknowledgement alone.
- Required diagnostic: identifies `SBX-016`, names `driver.providerAcknowledgement`, `driver.launchEvidence`, `operation.result`, and states the remediation without disclosing secret values.

#### `SBX-017` Provider-driven expiry relabeled a successful Core Stop or Delete

- Owner: `core`
- First-sound phase: `R1`
- Rejection deadline: `R1`
- Invariant: An unpreventable provider expiry, idle stop, or reclamation is recorded as an uncontrolled provider-loss event requiring reconciliation, never retrospectively as a successful Core Stop or Delete.
- Minimum witness: A provider reclamation recorded by backdating a successful `StopSandbox` result.
- Required diagnostic: identifies `SBX-017`, names `sandbox.status.runtime.state`, `sandbox.status.conditions`, `operation.origin`, and states the remediation without disclosing secret values.

#### `SBX-018` Provider auto-wake runtime left unsequenced

- Owner: `core`
- First-sound phase: `R1`
- Rejection deadline: `R1`
- Invariant: A provider-created replacement runtime observed without a Core lifecycle request is durably sequenced as a new runtime epoch with its identity and execution-admission records committed.
- Minimum witness: One Exec admitted against a provider auto-woken runtime that carries no Core epoch record.
- Required diagnostic: identifies `SBX-018`, names `sandbox.status.runtime.epoch`, `sandbox.status.execution.state`, `operation.origin`, and states the remediation without disclosing secret values.

#### `SBX-019` Stopped published without a containment-absence proof

- Owner: `runtime`
- First-sound phase: `T0`
- Rejection deadline: `T0`
- Invariant: A driver publishes `stopped` only after proving its containment-specific absence boundary, such as cgroup emptiness for process targets or host VMM absence for VM targets, and never from a guest shutdown acknowledgement, power-down request, provider stop acknowledgement, or initial-child exit.
- Minimum witness: A driver publishing `stopped` from a bubblewrap initial-child exit status.
- Required diagnostic: identifies `SBX-019`, names `driver.containmentProof`, `sandbox.status.runtime.state`, `driver.decodedEvidence`, and states the remediation without disclosing secret values.

#### `SBX-020` Stop grace deadline treated as an absence proof

- Owner: `core`
- First-sound phase: `T0`
- Rejection deadline: `T0`
- Invariant: A Stop that cannot prove containment absence commits Sandbox runtime state `unknown` and retains its evidence, and the grace deadline alone never establishes absence.
- Minimum witness: A Stop committing `stopped` because the grace deadline elapsed.
- Required diagnostic: identifies `SBX-020`, names `sandbox.status.runtime.state`, `sandbox.status.conditions`, `driver.containmentProof`, and states the remediation without disclosing secret values.

#### `SBX-021` Delete succeeds with incomplete cleanup or a possibly live orphan

- Owner: `core`
- First-sound phase: `T0`
- Rejection deadline: `T0`
- Invariant: A `DeleteSandbox` Operation succeeds only when the live Sandbox aggregate and every Core-owned live resource covered by that Operation are proven absent and the cleanup proof is durable.
- Minimum witness: A Delete reported as succeeded with cleanup pending for one covered resource.
- Required diagnostic: identifies `SBX-021`, names `operation.result`, `sandbox.cleanup.proof`, `sandbox.tombstone`, and states the remediation without disclosing secret values.

#### `SBX-022` Start-authorized launch reuses a stale resolved manifest

- Owner: `create`
- First-sound phase: `C0`
- Rejection deadline: `C0`
- Invariant: The launch a Start authorizes re-resolves the Sandbox's Artifact, member, and runtime-profile manifest at the launch stage and refuses to launch from a stale or absent resolution.
- Minimum witness: One Start-authorized launch served from the manifest resolution produced at creation.
- Required diagnostic: identifies `SBX-022`, names `create.resolvedManifest`, `sandbox.artifact.resolvedManifest`, `sandbox.runtimeProfile`, and states the remediation without disclosing secret values.

#### `SBX-023` Suspend or Resume accepted without the paired same-epoch continuity capability

- Owner: `live`
- First-sound phase: `L0`
- Rejection deadline: `L0`
- Invariant: `SuspendSandbox` and `ResumeSandbox` are admitted only against a runtime whose conformed target advertises the paired same-epoch suspend-and-resume continuity capability; a target advertising one without the other admits neither.
- Minimum witness: One `SuspendSandbox` admitted against a target advertising suspend but no same-epoch resume.
- Required diagnostic: identifies `SBX-023`, names `live.operation`, `sandbox.capabilities.suspendResume`, `sandbox.status.runtime.state`, and states the remediation without disclosing secret values.

#### `SBX-024` Verb-derived presentation label stored as Sandbox state on a launch traversal

- Owner: `core`
- First-sound phase: `R1`
- Rejection deadline: `R1`
- Invariant: On a launch traversal, Sandbox runtime state is exactly one of `provisioning`, `running`, `suspended`, `stopped`, or `unknown`; every derived launch presentation label -- creating, starting, restoring -- is recomputed at read time from the durable Operation and that authoritative status, and is never independently stored or used as the serialization oracle.
- Minimum witness: One launch status record storing `creating` as its runtime state.
- Required diagnostic: identifies `SBX-024`, names `sandbox.status.runtime.state`, `sandbox.status.lifecycleOperation`, `operation.kind`, and states the remediation without disclosing secret values.

#### `SBX-025` Unprovable launch runtime state approximated as stopped or running

- Owner: `core`
- First-sound phase: `R1`
- Rejection deadline: `R1`
- Invariant: When a launch traversal cannot safely establish runtime presence or absence, claimed-epoch continuity, exclusive effect authority, containment emptiness, or external-effect liveness, the committed Sandbox runtime state is `unknown` with execution admission `closed`.
- Minimum witness: One launch committing `running` after its presence probe timed out.
- Required diagnostic: identifies `SBX-025`, names `sandbox.status.runtime.state`, `sandbox.status.execution.state`, `sandbox.status.conditions`, and states the remediation without disclosing secret values.

### Packet E Process output streams and sequenced Process control

#### `PIO-001` Output cursor advanced before durable persistence

- Owner: `core`
- First-sound phase: `E1`
- Rejection deadline: `E1`
- Invariant: A durable stdout, stderr, or merged-terminal output cursor advances only after the bytes it covers are durably persisted.
- Minimum witness: A stdout cursor is published past a byte range whose spool persistence has not yet committed.
- Required diagnostic: identifies `PIO-001`, names `process.status.output.cursor`, `process.output.persistedThrough`, and states the remediation without disclosing secret values.

#### `PIO-002` Cross-stream ordering promised without an explicitly merged terminal stream

- Owner: `core`
- First-sound phase: `E1`
- Rejection deadline: `E1`
- Invariant: stdout and stderr have independent monotonic cursors that preserve ordering within each stream, and no cross-stream ordering is promised unless the accepted Exec selected a terminal that explicitly merges them.
- Minimum witness: An Exec that selected no merging terminal publishes a single interleaved cursor covering both stdout and stderr.
- Required diagnostic: identifies `PIO-002`, names `process.status.output.cursor`, `exec.pty`, and states the remediation without disclosing secret values.

#### `PIO-003` Replayed output chunk without a stable sequence identity

- Owner: `core`
- First-sound phase: `E1`
- Rejection deadline: `E1`
- Invariant: Every output chunk returned after reattachment from a supplied cursor carries a stable sequence identity that lets the caller deduplicate duplicate deliveries.
- Minimum witness: A chunk redelivered after reattachment carries no sequence identity, so the caller cannot distinguish it from new output.
- Required diagnostic: identifies `PIO-003`, names `process.status.output.cursor`, `process.output.chunkSequence`, and states the remediation without disclosing secret values.

#### `PIO-004` Accepted Process input replayed

- Owner: `exec`
- First-sound phase: `E0`
- Rejection deadline: `E0`
- Invariant: Accepted Process input is never replayed: no operation over an accepted, sequenced input frame re-submits it.
- Minimum witness: An accepted, sequenced stdin frame is re-submitted as a new input write and is delivered to the Process a second time.
- Required diagnostic: identifies `PIO-004`, names `exec.control.sequence`, `process.control.receipt`, and states the remediation without disclosing secret values.

#### `PIO-005` Process termination conflated with output sealing

- Owner: `core`
- First-sound phase: `E1`
- Rejection deadline: `E1`
- Invariant: Process termination and output sealing are independent facts, and end of output is authoritative only after backend exit and output drain are both proven.
- Minimum witness: A Process's output stream is declared ended at the moment its exit status is committed, discarding still-undrained bytes.
- Required diagnostic: identifies `PIO-005`, names `process.status.termination`, `process.status.output.sealedAt`, and states the remediation without disclosing secret values.

#### `PIO-006` End of output declared without proven backend exit and drain

- Owner: `runtime`
- First-sound phase: `E1`
- Rejection deadline: `E1`
- Invariant: A driver supplies proven backend exit and output-drain evidence before the Core may seal a Process output stream.
- Minimum witness: A driver reports end of output because its read returned no data, without observing backend exit or draining the transport.
- Required diagnostic: identifies `PIO-006`, names `driver.outputDrainEvidence`, `process.status.output.sealedAt`, and states the remediation without disclosing secret values.

#### `PIO-007` Output truncation, limit, or expiry hidden from the caller

- Owner: `core`
- First-sound phase: `E1`
- Rejection deadline: `E1`
- Invariant: Output retention duration, byte limit, and truncation are explicit, and a read from an expired cursor returns the typed output-expired result reporting the earliest retained cursor where partial output remains.
- Minimum witness: A read from a cursor whose bytes have expired returns fewer bytes with an ordinary success result and no expiry signal.
- Required diagnostic: identifies `PIO-007`, names `process.status.output.cursor`, `process.output.retention`, `process.output.truncatedAt`, and states the remediation without disclosing secret values.

#### `PIO-008` Process-control command without its exact coordinate

- Owner: `exec`
- First-sound phase: `E0`
- Rejection deadline: `E0`
- Invariant: Every WriteProcessInput, CloseProcessInput, and ResizeProcessTerminal command carries its exact Process ID, Sandbox ID, runtime epoch, writer lease, and monotonically increasing sequence number as part of the command coordinate.
- Minimum witness: A stdin write is submitted as an ordinary retryable RPC carrying only the Process ID, with no lease or sequence.
- Required diagnostic: identifies `PIO-008`, names `exec.control.coordinate`, `exec.control.sequence`, `exec.control.writerLeaseId`, and states the remediation without disclosing secret values.

#### `PIO-009` Repeated Process-control sequence enqueues a duplicate command

- Owner: `core`
- First-sound phase: `E0`
- Rejection deadline: `E1`
- Invariant: A retained prior sequence resubmitted with the same canonical command recovers the same durable receipt and never enqueues a second ordered command, regardless of later Process or lease state.
- Minimum witness: A resubmitted stdin write at an already accepted sequence is enqueued a second time because the lease has since expired.
- Required diagnostic: identifies `PIO-009`, names `exec.control.sequence`, `process.control.receipt`, and states the remediation without disclosing secret values.

#### `PIO-010` Repeated sequence accepted with different canonical content

- Owner: `core`
- First-sound phase: `E0`
- Rejection deadline: `E0`
- Invariant: A retained prior sequence resubmitted with a different canonical command is refused as a typed Process-control conflict carrying the original and submitted digests, and dispatches no command.
- Minimum witness: Sequence 12 is resubmitted with different stdin bytes and is accepted as an ordinary write.
- Required diagnostic: identifies `PIO-010`, names `exec.control.sequence`, `process.control.receipt.canonicalCommandDigest`, and states the remediation without disclosing secret values.

#### `PIO-011` Out-of-order Process-control command accepted

- Owner: `core`
- First-sound phase: `E0`
- Rejection deadline: `E0`
- Invariant: A genuinely new Process-control command is accepted only at the exact next sequence for its live writer lease, and a future sequence leaving a gap is refused with its typed out-of-range result.
- Minimum witness: A Process-control command at sequence 15 is accepted while the lease's last accepted sequence is 12.
- Required diagnostic: identifies `PIO-011`, names `exec.control.sequence`, `process.control.lastAcceptedSequence`, and states the remediation without disclosing secret values.

#### `PIO-012` Writer lease controls a different Process or runtime epoch

- Owner: `core`
- First-sound phase: `E0`
- Rejection deadline: `E0`
- Invariant: A writer lease is bound to exactly one Process and runtime epoch and is never retargeted after runtime replacement, Process termination, attachment reconnection, or SDK Session rebinding.
- Minimum witness: A writer lease issued for a Process in the prior runtime epoch is used to write stdin to a Process in the new epoch.
- Required diagnostic: identifies `PIO-012`, names `exec.control.writerLeaseId`, `exec.control.coordinate`, `process.sandboxRuntimeRef`, and states the remediation without disclosing secret values.

#### `PIO-013` Input receipt represented as application consumption

- Owner: `core`
- First-sound phase: `E1`
- Rejection deadline: `E1`
- Invariant: A Process-control receipt proves only that Core durably deduplicated and ordered the command and owns its delivery obligation, and never that the process consumed input bytes, that an application reacted to a terminal resize, or that the Process remains alive.
- Minimum witness: A stdin write receipt is reported as proof that the process consumed the bytes and is still alive.
- Required diagnostic: identifies `PIO-013`, names `process.control.receipt.state`, `process.control.outcome`, and states the remediation without disclosing secret values.

#### `PIO-014` Terminal resize accepted for a Process without a terminal or after termination

- Owner: `exec`
- First-sound phase: `E0`
- Rejection deadline: `E0`
- Invariant: ResizeProcessTerminal is accepted only for a nonterminal Process whose accepted Exec selected a terminal, and travels the same ordered Process-control stream as input and close.
- Minimum witness: A ResizeProcessTerminal is accepted for a Process whose accepted Exec selected no terminal.
- Required diagnostic: identifies `PIO-014`, names `exec.control.resize`, `exec.pty`, `process.status.state`, and states the remediation without disclosing secret values.

#### `PIO-015` Input accepted after CloseProcessInput

- Owner: `core`
- First-sound phase: `E0`
- Rejection deadline: `E0`
- Invariant: CloseProcessInput commits an irreversible ordered close record, after which any later input write for that Process is refused.
- Minimum witness: A stdin write at sequence 21 is accepted after a CloseProcessInput close record is committed at sequence 20.
- Required diagnostic: identifies `PIO-015`, names `exec.control.close`, `process.control.log`, and states the remediation without disclosing secret values.

#### `PIO-016` Accepted Process-control command silently lost

- Owner: `core`
- First-sound phase: `E1`
- Rejection deadline: `E1`
- Invariant: Every accepted Process-control command terminalizes as delivered, discarded with a never-delivered proof under an exact Process-terminal rule, failed with a never-delivered proof and quiesced delivery authority, or `unknown` naming its missing proofs, and remains observable through the Process control status or retained evidence.
- Minimum witness: An accepted stdin write is dropped when its Process terminates and its receipt disappears from the Process control status.
- Required diagnostic: identifies `PIO-016`, names `process.control.receipt.state`, `process.control.outcome`, and states the remediation without disclosing secret values.

#### `PIO-017` Teardown discards retained output or an accepted Process-control command

- Owner: `core`
- First-sound phase: `T0`
- Rejection deadline: `T0`
- Invariant: Sandbox teardown drains and seals retained Process output and resolves every accepted Process-control command with one of its four declared terminal outcomes; nothing accepted is silently discarded by Stop or Delete.
- Minimum witness: A Delete completes with an accepted stdin write still unresolved and a retained output spool left unsealed.
- Required diagnostic: identifies `PIO-017`, names `process.status.output.cursor`, `process.output.sealed`, `process.control.command.outcome`, and states the remediation without disclosing secret values.

#### `PIO-018` More than one live stdin writer lease for one Process

- Owner: `core`
- First-sound phase: `E0`
- Rejection deadline: `E0`
- Invariant: At most one live stdin writer lease exists for a Process at any time, and a Process-control command bearing a lease that is not the current live lease is refused with the typed lease-conflict result.
- Minimum witness: Two concurrent clients each hold a live stdin writer lease for the same Process and both write to it.
- Required diagnostic: identifies `PIO-018`, names `exec.control.writerLeaseId`, `process.control.liveLeases`, and states the remediation without disclosing secret values.

#### `PIO-019` Teardown seal declared without driver-supplied backend exit and drain evidence

- Owner: `runtime`
- First-sound phase: `T0`
- Rejection deadline: `T0`
- Invariant: A driver supplies proven backend exit and output-drain evidence for every retained Process stream during Stop or Delete before the Core may seal that stream at teardown.
- Minimum witness: A Stop driver reports teardown complete and the Core seals a retained stream with no backend-exit or drain evidence supplied for it.
- Required diagnostic: identifies `PIO-019`, names `driver.outputDrainEvidence`, `process.status.output.sealedAt`, `process.output.sealed`, and states the remediation without disclosing secret values.

### Packet E Process state, termination, and replay

#### `PRC-001` Process terminal outcome mutated

- Owner: `core`
- First-sound phase: `E1`
- Rejection deadline: `E1`
- Invariant: A Process terminal outcome is immutable once committed, and every later signal acknowledgement, reaper observation, or provider event arriving after the outcome commit is retained as evidence rather than applied as a rewrite.
- Minimum witness: A reaper observation arriving after the terminal outcome commit rewrites `process.status.termination` from `exited(0)` to `signalled`.
- Required diagnostic: identifies `PRC-001`, names `process.status.termination`, `process.status.state`, and states the remediation without disclosing secret values.

#### `PRC-002` Terminal Operation unknown conflated with reconcilable Process unknown

- Owner: `core`
- First-sound phase: `E1`
- Rejection deadline: `E1`
- Invariant: Process `unknown` is a nonterminal reconcilable observation state drawn from the Process vocabulary, and is never projected as a terminal Operation outcome or treated as replay authorization.
- Minimum witness: A Process whose state is the reconcilable `unknown` is projected directly into the Operation outcome union as that Operation's terminal `unknown` result.
- Required diagnostic: identifies `PRC-002`, names `process.status.state`, `operation.outcome`, and states the remediation without disclosing secret values.

#### `PRC-003` Process-targeted Operation outcome terminalizes the Process

- Owner: `core`
- First-sound phase: `L1`
- Rejection deadline: `L1`
- Invariant: A Signal or Terminate Operation's committed terminal outcome describes only that Operation, and never writes a terminal outcome onto the targeted Process record.
- Minimum witness: A Signal Operation that commits `succeeded` also writes a terminal outcome onto the targeted Process record.
- Required diagnostic: identifies `PRC-003`, names `operation.outcome`, `operation.target.processId`, `process.status.state`, and states the remediation without disclosing secret values.

#### `PRC-004` Ambiguous Process automatically replaced

- Owner: `core`
- First-sound phase: `E1`
- Rejection deadline: `E1`
- Invariant: An accepted Process whose outcome is unproven is reconciled against its own launch token and is never replaced by a Core- or driver-initiated replacement dispatch.
- Minimum witness: An accepted Process whose outcome is unproven triggers a Core-initiated replacement dispatch of the same command.
- Required diagnostic: identifies `PRC-004`, names `process.status.state`, `process.launchToken`, `process.effectIntent`, and states the remediation without disclosing secret values.

#### `PRC-005` Termination arm asserted without its exact native evidence

- Owner: `runtime`
- First-sound phase: `E1`
- Rejection deadline: `E1`
- Invariant: The selected ProcessTermination arm is justified by exactly the native evidence that arm asserts, so a nonzero exit decodes to the exited arm, startFailed proves the command never became running, deadlineExceeded proves the original Process can neither launch nor continue, and lost runtime never decodes to an ordinary exit.
- Minimum witness: A lost runtime control channel with no wait status is decoded as an ordinary `exited` termination.
- Required diagnostic: identifies `PRC-005`, names `process.status.termination`, `driver.terminationEvidence`, and states the remediation without disclosing secret values.

#### `PRC-006` Lost runtime carries an invented exit code

- Owner: `core`
- First-sound phase: `E1`
- Rejection deadline: `E1`
- Invariant: The runtimeLost termination arm is a bare variant that carries no exit code, signal, or other execution-outcome payload.
- Minimum witness: A `runtimeLost` termination is written carrying exit code 0.
- Required diagnostic: identifies `PRC-006`, names `process.status.termination`, and states the remediation without disclosing secret values.

#### `PRC-007` Teardown leaves a Process nonterminal

- Owner: `core`
- First-sound phase: `T0`
- Rejection deadline: `T0`
- Invariant: A Stop or Delete traversal terminalizes every remaining nonterminal Process of the captured epoch with an exact recorded reason before the Sandbox is published stopped.
- Minimum witness: A Stop publishes the Sandbox as `stopped` while one captured Process is still `running`.
- Required diagnostic: identifies `PRC-007`, names `process.status.state`, `process.status.termination`, `sandbox.status.runtime.state`, and states the remediation without disclosing secret values.

#### `PRC-008` Process unknown resolved with a different execution identity or epoch

- Owner: `core`
- First-sound phase: `E1`
- Rejection deadline: `E1`
- Invariant: An unproven Process resolves to running or terminated only by reconciling the same Core launch token and, once learned, the same backend execution identity in the same runtime epoch.
- Minimum witness: Evidence bearing a backend process identity from a replaced runtime epoch resolves an unproven Process to `terminated`.
- Required diagnostic: identifies `PRC-008`, names `process.launchToken`, `process.sandboxRuntimeRef`, `driver.nativeExecutionIdentity`, and states the remediation without disclosing secret values.

#### `PRC-009` Authority-epoch advance or fencing used to terminalize a Process

- Owner: `core`
- First-sound phase: `E1`
- Rejection deadline: `E1`
- Invariant: Internal authority-epoch advancement or predecessor fencing removes only the ability to commit Core state; a Process becomes terminal solely on target-side fencing, a verifiable drain boundary, or other proof that it can no longer execute or produce external effects.
- Minimum witness: Advancing the Sandbox authority epoch immediately writes `fenced` onto every prior-epoch Process with no driver fencing proof.
- Required diagnostic: identifies `PRC-009`, names `process.status.state`, `process.status.termination`, `sandbox.authorityEpoch`, and states the remediation without disclosing secret values.

#### `PRC-010` Stale running observation retained after its only observer is lost

- Owner: `core`
- First-sound phase: `E1`
- Rejection deadline: `E1`
- Invariant: A Process whose only fresh observer is lost stops being reported as running and is restored to running only from fresh same-epoch evidence.
- Minimum witness: A Process keeps reporting `running` after its only supervision channel is lost, with no fresh observation behind the report.
- Required diagnostic: identifies `PRC-010`, names `process.status.state`, `process.observationFreshness`, and states the remediation without disclosing secret values.

#### `PRC-011` Old-epoch Process left nonterminal after runtime replacement

- Owner: `core`
- First-sound phase: `R1`
- Rejection deadline: `R1`
- Invariant: A launch traversal that replaces a runtime terminalizes every nonterminal Process of the replaced epoch with runtimeReplaced, runtimeLost, or fenced before the new epoch is published running.
- Minimum witness: A replacement launch publishes the new runtime epoch as `running` while one Process of the replaced epoch is still `starting`.
- Required diagnostic: identifies `PRC-011`, names `process.status.termination`, `sandbox.status.runtime.epoch`, and states the remediation without disclosing secret values.

#### `PRC-012` Suspend terminalizes an accepted but undispatched Process

- Owner: `core`
- First-sound phase: `L1`
- Rejection deadline: `L1`
- Invariant: A continuity-preserving Suspend withholds launch authority from an accepted but externally undispatched Process and leaves it accepted rather than terminalizing it.
- Minimum witness: A SuspendSandbox operation writes a terminal outcome onto an accepted Process whose launch was never externally dispatched.
- Required diagnostic: identifies `PRC-012`, names `process.status.state`, `process.launchAuthority`, and states the remediation without disclosing secret values.

#### `PRC-013` Process state transition outside the locked graph

- Owner: `core`
- First-sound phase: `E1`
- Rejection deadline: `E1`
- Invariant: Process state advances only along the locked edges from accepted to starting or terminated, from starting to running, `unknown`, or terminated, from running to `unknown` or terminated, and from `unknown` to running or terminated.
- Minimum witness: A `terminated` Process is advanced back to `running`.
- Required diagnostic: identifies `PRC-013`, names `process.status.state`, and states the remediation without disclosing secret values.

#### `PRC-014` Terminated Process carries an open or absent outcome

- Owner: `core`
- First-sound phase: `E1`
- Rejection deadline: `E1`
- Invariant: Every terminated Process carries exactly one arm of the closed ProcessTermination union with that arm's declared payload, and never an absent, open, or provider-defined outcome.
- Minimum witness: A `terminated` Process is written with a free-form provider reason string and no `ProcessTermination` arm.
- Required diagnostic: identifies `PRC-014`, names `process.status.termination`, and states the remediation without disclosing secret values.

#### `PRC-015` Replacement, fencing, or Stop causality asserted without target-side proof

- Owner: `core`
- First-sound phase: `T0`
- Rejection deadline: `T0`
- Invariant: The runtimeReplaced, fenced, and stoppedBySandbox termination arms are recorded only after target-side execution fencing or containment absence proves the Process cannot act, and stoppedBySandbox additionally requires proven deliberate Stop causality.
- Minimum witness: A Stop records `stoppedBySandbox` on a captured Process before any target-side containment-absence proof is returned.
- Required diagnostic: identifies `PRC-015`, names `process.status.termination`, `driver.containmentAbsenceProof`, and states the remediation without disclosing secret values.

#### `PRC-016` Process observation or wait deadline mutating or terminalizing its target

- Owner: `core`
- First-sound phase: `E1`
- Rejection deadline: `E1`
- Invariant: A `WaitProcess`, `GetProcess`, `ListProcesses`, or `ReadProcessOutput` deadline ends only that observation and never cancels, mutates, terminalizes, or advances the durable state of the observed Process or its output stream.
- Minimum witness: A `WaitProcess` deadline expiring cancels the observed Process and writes a `deadlineExceeded` termination onto it.
- Required diagnostic: identifies `PRC-016`, names `observation.deadline`, `process.status.state`, `process.status.output.cursor`, and states the remediation without disclosing secret values.

#### `PRC-017` Teardown rewrites a committed Process terminal outcome

- Owner: `core`
- First-sound phase: `T0`
- Rejection deadline: `T0`
- Invariant: Sandbox teardown retains every late signal acknowledgement, reaper observation, and provider event arriving during Stop or Delete as evidence linked to the Process, and never applies it as a rewrite of a committed Process terminal outcome.
- Minimum witness: A provider event arriving during Stop rewrites an already committed `exited(0)` Process outcome to `stoppedBySandbox`.
- Required diagnostic: identifies `PRC-017`, names `process.status.termination`, `process.status.state`, `driver.lateEvidence`, and states the remediation without disclosing secret values.

### Packet E signal and termination dispatch proof

#### `SIG-001` Arbitrary or unadvertised signal accepted

- Owner: `live`
- First-sound phase: `L0`
- Rejection deadline: `L0`
- Invariant: A SignalProcess request selects exactly one signal from the effective capability's closed advertised set for the targeted Process, Sandbox, and runtime epoch.
- Minimum witness: A SignalProcess request names a signal absent from `sandbox.capabilities.signals` for the targeted Process and epoch.
- Required diagnostic: identifies `SIG-001`, names `live.signal.signal`, `sandbox.capabilities.signals`, and states the remediation without disclosing secret values.

#### `SIG-002` Generic signal accepted while the Sandbox is suspended

- Owner: `live`
- First-sound phase: `L0`
- Rejection deadline: `L0`
- Invariant: A generic SignalProcess request against a suspended Sandbox is admitted only when the target advertises deterministic delivery semantics under suspension, while StopSandbox remains legal.
- Minimum witness: A generic SignalProcess is admitted against a suspended Sandbox whose target advertises no deterministic suspended-delivery semantics.
- Required diagnostic: identifies `SIG-002`, names `live.signal`, `sandbox.status.runtime.state`, `sandbox.capabilities.signals`, and states the remediation without disclosing secret values.

#### `SIG-008` Signal or termination admitted against a stopped or unprovable Sandbox

- Owner: `live`
- First-sound phase: `L0`
- Rejection deadline: `L0`
- Invariant: A SignalProcess or TerminateProcess request is admitted only against a Process whose Sandbox holds a proven running or suspended runtime state carrying a live runtime epoch; a stopped Sandbox and an unprovable runtime state are each rejected at admission, and neither is approximated as the other.
- Minimum witness: A TerminateProcess request is admitted against a Sandbox whose runtime state cannot be proven, and the unprovable state is treated as stopped.
- Required diagnostic: identifies `SIG-008`, names `live.signal`, `live.terminate`, `sandbox.status.runtime.state`, `sandbox.status.runtime.epoch`, and states the remediation without disclosing secret values.

#### `SIG-003` Driver reports signal dispatch without invoking the exact target-specific action

- Owner: `runtime`
- First-sound phase: `L1`
- Rejection deadline: `L1`
- Invariant: A driver reports a signal dispatch as accepted only after invoking the exact target-specific signal action and obtaining backend acceptance evidence, never by emulating it with VM power controls, Sandbox deletion, or a coarser containment verb.
- Minimum witness: A microVM driver reports a signal dispatch as accepted after issuing a VM reset instead of the guest signal action.
- Required diagnostic: identifies `SIG-003`, names `operation.outcome`, `driver.signalDispatchEvidence`, and states the remediation without disclosing secret values.

#### `SIG-004` Signal dispatch represented as delivery, handling, or exit

- Owner: `core`
- First-sound phase: `L1`
- Rejection deadline: `L1`
- Invariant: A successful SignalProcess Operation asserts only that the exact target-specific dispatch was invoked and accepted, and never that the signal was delivered, handled, obeyed, or that the Process exited.
- Minimum witness: A successful SignalProcess Operation declares that the signal was delivered and that the Process exited.
- Required diagnostic: identifies `SIG-004`, names `operation.outcome`, `operation.successPredicate`, `process.status.state`, and states the remediation without disclosing secret values.

#### `SIG-005` Duplicate signal or termination dispatch assumed idempotent

- Owner: `core`
- First-sound phase: `L1`
- Rejection deadline: `L1`
- Invariant: Core coordinates dispatch identities where the target declares support for them, and otherwise durably records the dispatch as possibly at-least-once, never claiming backend deduplication the target does not provide.
- Minimum witness: A retried TerminateProcess repeats the native call against a target that declares no dispatch-identity support while the Operation claims exactly-once delivery.
- Required diagnostic: identifies `SIG-005`, names `driver.signalDispatchEvidence`, `operation.effectAttempt`, and states the remediation without disclosing secret values.

#### `SIG-006` Process termination reported before it can no longer act

- Owner: `core`
- First-sound phase: `L1`
- Rejection deadline: `L1`
- Invariant: A TerminateProcess Operation succeeds only when the Process holds an immutable terminal outcome and is proven unable to continue acting, and generic signal dispatch never silently gains wait-for-exit semantics.
- Minimum witness: A TerminateProcess Operation commits `succeeded` while the targeted Process is still `running`.
- Required diagnostic: identifies `SIG-006`, names `operation.outcome`, `process.status.state`, `process.status.termination`, and states the remediation without disclosing secret values.

#### `SIG-007` Signal Operation committed `succeeded` without its three-part proof

- Owner: `core`
- First-sound phase: `L1`
- Rejection deadline: `L1`
- Invariant: A `SignalProcess` Operation commits `succeeded` only when the Sandbox ID, Process ID, runtime epoch, and authority were validated, the exact target was selected, and returned driver evidence proves the target-specific dispatch was accepted; any weaker knowledge set leaves the Operation nonterminal or terminalizes it `unknown`.
- Minimum witness: A SignalProcess Operation commits `succeeded` after the native call times out with no returned driver acceptance evidence.
- Required diagnostic: identifies `SIG-007`, names `operation.outcome`, `operation.target.processId`, `sandbox.status.runtime.epoch`, and states the remediation without disclosing secret values.

### Packet E adapter, Session, and desired-state boundary

#### `ADP-001` Framework Session used as a Core identity or authority coordinate

- Owner: `framework`
- First-sound phase: `F0`
- Rejection deadline: `F0`
- Invariant: Adapter Session identity stays outside the Core resource model and never appears in a Core request as a target, authority, precondition, or idempotency coordinate.
- Minimum witness: Send a Core request whose target coordinate is the adapter's Session identifier.
- Required diagnostic: identifies `ADP-001`, names `framework.session`, `framework.sandboxClient`, and states the remediation without disclosing secret values.

#### `ADP-002` Framework Session resume silently retargets an old runtime or Process handle

- Owner: `framework`
- First-sound phase: `F0`
- Rejection deadline: `L0`
- Invariant: A framework adapter rebinds a Session to a different runtime only explicitly, after determining which of same-epoch attachment, proven same-epoch suspended Process continuity, or replacement from retained state holds, and maps those three results respectively to reattachment, ResumeSandbox, and CreateSandbox or RestoreSandbox against a new epoch.
- Minimum witness: Resume a Session and reuse its stored Process handle against a Sandbox that has since been restored under a new epoch.
- Required diagnostic: identifies `ADP-002`, names `framework.session`, `live.operation.expectedRuntimeEpoch`, and states the remediation without disclosing secret values.

#### `ADP-003` Adapter phase presented as authoritative Core state

- Owner: `framework`
- First-sound phase: `F0`
- Rejection deadline: `F0`
- Invariant: A framework adapter presents Sandbox and Process lifecycle state only as the Core's own closed status values read from Core responses, never as an adapter-derived or provider-derived phase.
- Minimum witness: Display an adapter-derived `warming` phase as the Sandbox's lifecycle state.
- Required diagnostic: identifies `ADP-003`, names `framework.status`, `sandbox.status.phase`, and states the remediation without disclosing secret values.

#### `ADP-004` Adapter mints or rebinds an idempotency coordinate

- Owner: `framework`
- First-sound phase: `F0`
- Rejection deadline: `F0`
- Invariant: A framework adapter recovers an accepted request only by resending the caller's exact canonical request under its original idempotency key, and never substitutes a new key, a new canonical request, or a reused key for a canonically different intent.
- Minimum witness: Recover a timed-out creation by resending it under a newly minted idempotency key.
- Required diagnostic: identifies `ADP-004`, names `framework.idempotencyKey`, `framework.sandboxClient`, and states the remediation without disclosing secret values.

#### `ADP-005` Adapter advertises its own mutation serialization guarantee

- Owner: `framework`
- First-sound phase: `F0`
- Rejection deadline: `F0`
- Invariant: A framework adapter advertises no ordering, exclusion, or serialization guarantee for Core mutations beyond the Core's published operation-pair compatibility and precondition contract.
- Minimum witness: Advertise that the adapter serializes all mutations on a Sandbox through its own client-side lock.
- Required diagnostic: identifies `ADP-005`, names `framework.tools`, `framework.sandboxClient`, and states the remediation without disclosing secret values.

#### `ADP-006` Adapter adds a public error variant

- Owner: `framework`
- First-sound phase: `F0`
- Rejection deadline: `F0`
- Invariant: An adapter's caller-visible failure type is exactly the Core's closed public error, known-failure, and ambiguity union projected into the host language, with no added, merged, renamed, or provider-defined semantic variant.
- Minimum witness: Hand-write an `AdapterBusy` variant into the adapter's public failure type.
- Required diagnostic: identifies `ADP-006`, names `framework.errors`, and states the remediation without disclosing secret values.

#### `ADP-007` Adapter reinterprets a transport timeout as a Core outcome

- Owner: `framework`
- First-sound phase: `F0`
- Rejection deadline: `F0`
- Invariant: An adapter surfaces a transport timeout, transport cancellation, or connection loss as the transport condition it is, never as a Core Operation failure, a proven Core cancellation, or a Process outcome.
- Minimum witness: Report a gRPC `DEADLINE_EXCEEDED` on a Stop call as a failed Core Operation.
- Required diagnostic: identifies `ADP-007`, names `framework.errors`, `framework.transport`, and states the remediation without disclosing secret values.

#### `ADP-008` Adapter collapses Process exit into infrastructure failure

- Owner: `framework`
- First-sound phase: `F0`
- Rejection deadline: `F0`
- Invariant: An adapter reports a Core Process termination arm exactly as the Core published it and never collapses a nonzero exit, signal termination, or deadline outcome into an adapter or infrastructure error.
- Minimum witness: Raise an adapter infrastructure exception because the executed command exited non-zero.
- Required diagnostic: identifies `ADP-008`, names `framework.errors`, `process.termination`, and states the remediation without disclosing secret values.

#### `ADP-009` Adapter auto-replays an ambiguous effect

- Owner: `framework`
- First-sound phase: `F0`
- Rejection deadline: `F0`
- Invariant: An adapter never converts a Core ambiguity outcome into a replacement effect, and resolves ambiguity only by surfacing the ambiguity arm to the caller, by Core observation, or by Core idempotent recovery of the same coordinate.
- Minimum witness: Automatically re-issue an Exec under a new idempotency key after the Core returned an ambiguity arm.
- Required diagnostic: identifies `ADP-009`, names `framework.retryPolicy`, `operation.outcome`, and states the remediation without disclosing secret values.

#### `ADP-010` Adapter asserts provider fencing or cleanup proof

- Owner: `framework`
- First-sound phase: `F0`
- Rejection deadline: `F0`
- Invariant: An adapter reports fencing, containment absence, and cleanup completion only as the proof the Core published, and never derives, infers, or asserts such proof from provider or adapter observation.
- Minimum witness: Report cleanup complete because the adapter's provider poll no longer lists the instance.
- Required diagnostic: identifies `ADP-010`, names `framework.cleanup`, `operation.result.proof`, and states the remediation without disclosing secret values.

#### `ADP-011` Adapter composite presented as one Core Operation

- Owner: `framework`
- First-sound phase: `F0`
- Rejection deadline: `F0`
- Invariant: An adapter convenience composite such as attach or Stop-then-Delete is expressed as the exact declared sequence of named Core operations, surfaces every constituent Operation handle to the caller, and never presents itself as one Core Operation or one Core outcome.
- Minimum witness: Return a single synthesized Operation handle for an adapter Stop-then-Delete helper.
- Required diagnostic: identifies `ADP-011`, names `framework.composites`, `operation.id`, and states the remediation without disclosing secret values.

#### `ADP-012` Desired-state reconciler reaches the Core without etag and epoch preconditions or hides its system-originated Operations

- Owner: `service`
- First-sound phase: `S0`
- Rejection deadline: `L0`
- Invariant: A managed desired-state reconciler reaches the Core only by issuing named Core operations under etag and runtime-epoch preconditions, and exposes its system-originated Operations for observation.
- Minimum witness: Have the reconciler issue a StopSandbox with no etag and no runtime-epoch precondition.
- Required diagnostic: identifies `ADP-012`, names `service.reconciler`, `operation.target.expectedEtag`, `operation.target.expectedRuntimeEpoch`, and states the remediation without disclosing secret values.

#### `ADP-013` Managed desired-state revision or restart policy carried in a Core request field

- Owner: `service`
- First-sound phase: `S0`
- Rejection deadline: `S0`
- Invariant: A managed layer's desired-state revision and its restart/recreate policy live in the managed layer's own records; no Core request type carries either, so the Core never becomes a perpetual desired-state orchestrator.
- Minimum witness: Send a CreateSandbox request carrying a `desiredStateRevision` field.
- Required diagnostic: identifies `ADP-013`, names `service.desiredStateRevision`, `service.restartPolicy`, `request.method`, and states the remediation without disclosing secret values.

#### `ADP-014` Reconciler rewrites a predecessor Operation's terminal result

- Owner: `service`
- First-sound phase: `S0`
- Rejection deadline: `L0`
- Invariant: A reconciler that must correct a completed Core action appends a new linked successor Operation and never rewrites, reopens, or reinterprets a predecessor Operation's committed terminal result.
- Minimum witness: Rewrite a completed Stop Operation's terminal result to `failed` so the reconciler can retry it in place.
- Required diagnostic: identifies `ADP-014`, names `service.reconciler`, `operation.result`, `operation.linkedOperationId`, and states the remediation without disclosing secret values.

### Packet E public error, recovery, and transport projection

#### `ERR-001` Creation rejection outside the sealed error registry

- Owner: `core`
- First-sound phase: `C0`
- Rejection deadline: `C0`
- Invariant: Every synchronous rejection of a creation request is exactly one variant of the sealed public `RequestError` or `RecoveryError` registry admitted by that method's generated subset, with no catch-all variant, open string reason, arbitrary metadata reason, or provider-defined code.
- Minimum witness: Return a creation rejection whose variant is a catch-all carrying a free-text provider reason string.
- Required diagnostic: identifies `ERR-001`, names `requestError.variant`, `operationContract.allowedRequestErrors`, `operationContract.allowedRecoveryErrors`, and states the remediation without disclosing secret values.

#### `ERR-002` Live rejection outside the sealed error registry

- Owner: `core`
- First-sound phase: `L0`
- Rejection deadline: `L0`
- Invariant: Every synchronous rejection of a live Sandbox, Snapshot, or Operation request is exactly one variant of the sealed public `RequestError` or `RecoveryError` registry admitted by that method's generated subset, with no catch-all variant, open string reason, arbitrary metadata reason, or provider-defined code.
- Minimum witness: Emit a live rejection whose variant is registered for a different method and absent from this method's generated subset.
- Required diagnostic: identifies `ERR-002`, names `requestError.variant`, `operationContract.allowedRequestErrors`, `operationContract.allowedRecoveryErrors`, and states the remediation without disclosing secret values.

#### `ERR-003` Exec or Process-control rejection outside the sealed error registry

- Owner: `core`
- First-sound phase: `E0`
- Rejection deadline: `E0`
- Invariant: Every synchronous rejection of an Exec or sequenced Process-control request is exactly one variant of the sealed public `RequestError` or `RecoveryError` registry admitted by that method's generated subset, with no catch-all variant, open string reason, arbitrary metadata reason, or provider-defined code.
- Minimum witness: Reject a Process-control request with an Exec-specific open reason string outside the sealed registry.
- Required diagnostic: identifies `ERR-003`, names `requestError.variant`, `operationContract.allowedRequestErrors`, `operationContract.allowedProcessControlOutcomes`, and states the remediation without disclosing secret values.

#### `ERR-004` Creation rejection payload outside its closed schema

- Owner: `core`
- First-sound phase: `C0`
- Rejection deadline: `C0`
- Invariant: Every creation rejection payload is exactly the emitted variant's closed schema and contains no stack trace, secret or credential, host path, raw provider payload, unbounded native metadata, protected resource existence, unredacted command environment, or arbitrary detail map.
- Minimum witness: Return a creation rejection whose detail map echoes the host backing path of the failed binding.
- Required diagnostic: identifies `ERR-004`, names `requestError.details`, `requestError.message`, `operationContract.allowedRequestErrors`, and states the remediation without disclosing secret values.

#### `ERR-005` Live rejection payload outside its closed schema

- Owner: `core`
- First-sound phase: `L0`
- Rejection deadline: `L0`
- Invariant: Every live-operation rejection payload is exactly the emitted variant's closed schema and contains no stack trace, secret or credential, host path, raw provider payload, unbounded native metadata, protected resource existence, unredacted command environment, or arbitrary detail map.
- Minimum witness: Return a live rejection whose details field carries the raw provider error document for the failed operation.
- Required diagnostic: identifies `ERR-005`, names `requestError.details`, `requestError.details.safeTargetRef`, `requestError.message`, and states the remediation without disclosing secret values.

#### `ERR-006` Exec rejection payload outside its closed schema

- Owner: `core`
- First-sound phase: `E0`
- Rejection deadline: `E0`
- Invariant: Every Exec or Process-control rejection payload is exactly the emitted variant's closed schema and contains no stack trace, secret or credential, host path, raw provider payload, unbounded native metadata, protected resource existence, unredacted command environment, or arbitrary detail map.
- Minimum witness: Return an Exec rejection whose detail map echoes the submitted Process environment.
- Required diagnostic: identifies `ERR-006`, names `requestError.details`, `requestError.details.limit`, `process.request.env`, and states the remediation without disclosing secret values.

#### `ERR-007` Creation validation or existence disclosure before authorization

- Owner: `core`
- First-sound phase: `C0`
- Rejection deadline: `C0`
- Invariant: A creation request performs only the parsing needed to route and authenticate before authorization at a disclosure-safe scope, and an unauthorized request naming an existing creation target and an authorized request naming an absent one produce observationally equivalent public responses.
- Minimum witness: Return a distinct `AlreadyExists` rejection to an unauthorized caller who names an existing creation target.
- Required diagnostic: identifies `ERR-007`, names `operationContract.orderedAdmissionChecks`, `requestError.variant`, `requestError.details.safeName`, and states the remediation without disclosing secret values.

#### `ERR-008` Live validation or existence disclosure before authorization

- Owner: `core`
- First-sound phase: `L0`
- Rejection deadline: `L0`
- Invariant: A live request performs only the parsing needed to route and authenticate before authorization at a disclosure-safe operation and parent scope, and an unauthorized request against an existing target and an authorized request against an absent target produce observationally equivalent public responses.
- Minimum witness: Validate a live request body and return a field-level error before authorization runs, revealing that the named Sandbox exists.
- Required diagnostic: identifies `ERR-008`, names `operationContract.orderedAdmissionChecks`, `requestError.variant`, `requestError.details.safeTargetRef`, and states the remediation without disclosing secret values.

#### `ERR-009` Exec validation or existence disclosure before authorization

- Owner: `core`
- First-sound phase: `E0`
- Rejection deadline: `E0`
- Invariant: An Exec or Process-control request performs only the parsing needed to route and authenticate before authorization at a disclosure-safe operation and parent scope, and an unauthorized request against an existing Sandbox or Process and an authorized request against an absent one produce observationally equivalent public responses.
- Minimum witness: Return `ProcessNotFound` versus `PermissionDenied` distinguishably to an unauthorized caller probing Process identities.
- Required diagnostic: identifies `ERR-009`, names `operationContract.orderedAdmissionChecks`, `requestError.variant`, `process.id`, and states the remediation without disclosing secret values.

#### `ERR-010` Creation recovery expressed outside the closed recovery contract

- Owner: `core`
- First-sound phase: `C0`
- Rejection deadline: `C0`
- Invariant: Every creation rejection carries exactly one closed `CallerRecovery` consistent with its variant's semantic domain, and no boolean retryability flag substitutes for it and no `after` or `Retry-After` hint independently authorizes replay of an effect.
- Minimum witness: Return a creation rejection carrying a `retryable: true` flag instead of its registered `CallerRecovery`.
- Required diagnostic: identifies `ERR-010`, names `requestError.recovery`, `requestError.variant`, `operationContract.callerRecoveryByOutcome`, and states the remediation without disclosing secret values.

#### `ERR-011` Live recovery expressed outside the closed recovery contract

- Owner: `core`
- First-sound phase: `L0`
- Rejection deadline: `L0`
- Invariant: Every live-operation rejection carries exactly one closed `CallerRecovery` consistent with its variant's semantic domain, and no boolean retryability flag substitutes for it and no `after` or `Retry-After` hint independently authorizes replay of an effect.
- Minimum witness: Return a `RecoveryError` for an already-accepted live operation whose recovery instructs the caller to resubmit under a new idempotency key.
- Required diagnostic: identifies `ERR-011`, names `requestError.recovery`, `recoveryError.priorAcceptance`, `requestError.variant`, and states the remediation without disclosing secret values.

#### `ERR-012` Exec recovery expressed outside the closed recovery contract

- Owner: `core`
- First-sound phase: `E0`
- Rejection deadline: `E0`
- Invariant: Every Exec or Process-control rejection carries exactly one closed `CallerRecovery` consistent with its variant's semantic domain, and no boolean retryability flag substitutes for it and no `after` or `Retry-After` hint independently authorizes replay of a command or a replacement execution.
- Minimum witness: Return an expired Process-control coordinate with a recovery advising a replacement execution.
- Required diagnostic: identifies `ERR-012`, names `requestError.recovery`, `recoveryError.priorAcceptance`, `processControlReceipt.coordinate`, and states the remediation without disclosing secret values.

#### `ERR-013` Transport status treated as creation semantics

- Owner: `core`
- First-sound phase: `C0`
- Rejection deadline: `C0`
- Invariant: Canonical HTTP and gRPC status for a creation call is generated from the Core-authored variant and never the reverse, so a transport-local failure never becomes a Core rejection or Core outcome and an accepted result is delivered embedded in its durable handle under a successful transport status even when its terminal outcome is `failed`, `cancelled`, or `unknown`.
- Minimum witness: Convert a `DEADLINE_EXCEEDED` transport status on a creation call into a Core creation rejection.
- Required diagnostic: identifies `ERR-013`, names `operationContract.transportProjection`, `requestError.variant`, `operation.outcome`, and states the remediation without disclosing secret values.

#### `ERR-014` Transport status treated as live-operation semantics

- Owner: `core`
- First-sound phase: `L0`
- Rejection deadline: `L0`
- Invariant: Canonical HTTP and gRPC status for a live call is generated from the Core-authored variant and never the reverse, so transport `UNKNOWN`, `CANCELLED`, `DEADLINE_EXCEEDED`, or `UNAVAILABLE` never becomes the corresponding Operation outcome and retrieving an accepted handle whose terminal outcome is `failed`, `cancelled`, or `unknown` is a successful observation.
- Minimum witness: Record transport `UNAVAILABLE` on a live call as the Operation's `unknown` terminal outcome.
- Required diagnostic: identifies `ERR-014`, names `operationContract.transportProjection`, `operation.outcome`, `requestError.variant`, and states the remediation without disclosing secret values.

#### `ERR-015` Transport status treated as Exec semantics

- Owner: `core`
- First-sound phase: `E0`
- Rejection deadline: `E0`
- Invariant: Canonical HTTP and gRPC status for an Exec or Process-control call is generated from the Core-authored variant and never the reverse, so a transport failure never becomes a Core rejection, a Process termination, or a control-command outcome, and an accepted Process or receipt is returned under a successful transport status regardless of its embedded terminal outcome.
- Minimum witness: Report a client-side connection close during Exec as a Process termination.
- Required diagnostic: identifies `ERR-015`, names `operationContract.transportProjection`, `process.termination`, `processControlReceipt.state`, and states the remediation without disclosing secret values.

#### `ERR-016` Unrecognized native code extending the public union

- Owner: `runtime`
- First-sound phase: `D0`
- Rejection deadline: `D0`
- Invariant: An unrecognized native provider code, status, or future provider state is retained as protected evidence and mapped conservatively onto an already-registered public variant, and never adds, widens, parameterizes, or passes through a public variant at runtime.
- Minimum witness: Pass an unrecognized provider status code through as a new public error variant.
- Required diagnostic: identifies `ERR-016`, names `providerEvidence.nativeCode`, `providerEvidence.decodingAdapterVersion`, `requestError.variant`, and states the remediation without disclosing secret values.

#### `ERR-017` Raw provider evidence escaping redaction or size bounds

- Owner: `runtime`
- First-sound phase: `D0`
- Rejection deadline: `D0`
- Invariant: Decoded provider and driver evidence reaches a public response only as the emitted variant's declared payload plus a bounded opaque evidence identifier, and raw native payloads, unbounded metadata, and unredacted values remain confined to the protected evidence record.
- Minimum witness: Attach the full unredacted provider stderr to the public rejection details.
- Required diagnostic: identifies `ERR-017`, names `providerEvidence.payload`, `providerEvidence.evidenceId`, `providerEvidence.redaction`, and states the remediation without disclosing secret values.

### Packet E restore, Fork, and derivation semantics

#### `FRK-001` Restore accepted against a non-stopped Sandbox

- Owner: `live`
- First-sound phase: `L0`
- Rejection deadline: `L0`
- Invariant: Same-Sandbox RestoreSandbox is admitted only against a stopped Sandbox and only with a Snapshot proven complete and compatible with that Sandbox's pinned Artifact, member, and runtime-profile identity.
- Minimum witness: Issue same-Sandbox RestoreSandbox against a Sandbox whose runtime is still running.
- Required diagnostic: identifies `FRK-001`, names `live.restore`, `sandbox.status.runtime.state`, `snapshot.manifest`, and states the remediation without disclosing secret values.

#### `FRK-002` Restored or forked runtime admits execution without a successor Process contract

- Owner: `core`
- First-sound phase: `R1`
- Rejection deadline: `R1`
- Invariant: A restored, restore-as-created, or forked runtime admits execution only through a newly allocated durable Core Process carrying its own identity, provenance, deadline, termination-request handling, containment, stdin ownership, durable output cursors, and terminal-evidence contract.
- Minimum witness: Restore a runtime whose image resurrects a running command and accept work against it with no Core Process record allocated.
- Required diagnostic: identifies `FRK-002`, names `sandbox.status.runtime.epoch`, `process.id`, `process.sandboxRuntimeRef`, and states the remediation without disclosing secret values.

#### `FRK-003` Restore launch reactivates the source runtime epoch

- Owner: `core`
- First-sound phase: `R0`
- Rejection deadline: `R1`
- Invariant: A launch against an existing Sandbox -- StartSandbox, same-Sandbox Restore, or restore-as-create -- acts only under the newly allocated runtime epoch and never grants, restores, or re-enables mutation authority to any epoch that preceded it.
- Minimum witness: Publish a restored runtime that continues to accept mutations under the epoch it held before it was stopped.
- Required diagnostic: identifies `FRK-003`, names `operation.target.epoch`, `sandbox.status.runtime.epoch`, and states the remediation without disclosing secret values.

#### `FRK-004` Fork child shares source identity, authority, or an unsealed source

- Owner: `core`
- First-sound phase: `L0`
- Rejection deadline: `L1`
- Invariant: Every accepted Fork durably commits, before any capture or child-creation effect, a sealed target naming the exact immutable source Sandbox ID and source runtime epoch together with a newly preallocated child Sandbox ID; the child is a distinct Sandbox whose epoch line begins at 1 under its own mutation authority, sharing no Sandbox identity, Core Process identity, or authority coordinate with its source, and its complete Snapshot-equivalent provenance and ancestry are recorded in that same commit.
- Minimum witness: Accept a Fork whose child reuses the source Sandbox ID and continues the source's epoch line.
- Required diagnostic: identifies `FRK-004`, names `operation.target.source.sandboxId`, `operation.target.source.runtimeEpoch`, `operation.target.childSandboxId`, and states the remediation without disclosing secret values.

#### `FRK-005` Migration retains an epoch without an atomic fenced handoff

- Owner: `core`
- First-sound phase: `L1`
- Rejection deadline: `L1`
- Invariant: A migration retains the source runtime epoch only when Core holds proof of every locked handoff requirement and commits a definite terminal outcome for the migration Operation; every other relocation allocates a new epoch.
- Minimum witness: Commit a migration as succeeded with the epoch retained while the source-fencing proof is absent.
- Required diagnostic: identifies `FRK-005`, names `operation.target.epoch`, `sandbox.status.runtime`, and states the remediation without disclosing secret values.

#### `FRK-006` Driver reports a migration handoff without its target-side proofs

- Owner: `runtime`
- First-sound phase: `L1`
- Rejection deadline: `L1`
- Invariant: A driver executing a migration handoff returns evidence of compatible source and destination, exclusive target-enforced authority transfer, a fenced or terminated source, uninterrupted Process authority, routing handoff, and explicit disposition of open attachments and external connections, and refuses the transfer when it cannot produce all six.
- Minimum witness: Return a migration handoff success that omits the routing-handoff proof.
- Required diagnostic: identifies `FRK-006`, names `driver.migrationEvidence`, `sandbox.status.runtime.epoch`, `operation.target.epoch`, and states the remediation without disclosing secret values.

### Packet E retention, deletion independence, and tombstones

#### `RET-001` Sandbox deletion erasing independently retained records early

- Owner: `core`
- First-sound phase: `T0`
- Rejection deadline: `T0`
- Invariant: A successful Sandbox deletion removes only the live Sandbox aggregate and the live resources covered by that Operation, and every independently retained Operation, Process, output, event, evidence, and Snapshot record remains readable until its own retention contract expires.
- Minimum witness: Delete a Sandbox and observe that its Process output records become unreadable before their own retention contract expires.
- Required diagnostic: identifies `RET-001`, names `operation.retentionContract`, `sandbox.deletionScope`, `operation.id`, and states the remediation without disclosing secret values.

#### `RET-002` Delete admitted while a dependent Snapshot is unresolved

- Owner: `live`
- First-sound phase: `L0`
- Rejection deadline: `L0`
- Invariant: DeleteSandbox is admitted only when every dependent Snapshot has been deleted, exported or mirrored into Core-controlled retention, or otherwise proven independent of the Sandbox aggregate.
- Minimum witness: Issue DeleteSandbox while one Snapshot of that Sandbox is still stored inside the Sandbox aggregate and holds no independent retention.
- Required diagnostic: identifies `RET-002`, names `sandbox.dependentSnapshots`, `snapshot.references`, `snapshot.retentionHolds`, and states the remediation without disclosing secret values.

#### `RET-003` Expiration schedule without an explicit instant and action

- Owner: `live`
- First-sound phase: `L0`
- Rejection deadline: `L0`
- Invariant: A caller-managed Sandbox expiration is either explicit `none` or an exact absolute instant paired with an explicit `stop` or `delete` action, and neither member has a provider-, target-, or service-selected default.
- Minimum witness: Submit an expiration carrying an absolute instant with no action member and let the target's default action be applied.
- Required diagnostic: identifies `RET-003`, names `sandbox.expiration`, `sandbox.expiration.at`, `sandbox.expiration.action`, and states the remediation without disclosing secret values.

#### `RET-004` Expiration schedule conflated with a generic TTL

- Owner: `live`
- First-sound phase: `L0`
- Rejection deadline: `L0`
- Invariant: The caller-managed expiration schedule expresses only an absolute Sandbox expiry instant and its action, and never sets, reads, or stands in for maximum age from creation, idle duration, maximum runtime duration, Snapshot retention, or Operation, Process, event, and output retention.
- Minimum witness: Set the Sandbox expiration and have the same call also shorten Operation record retention.
- Required diagnostic: identifies `RET-004`, names `sandbox.expiration.at`, `sandbox.expiration.action`, `sandbox.retentionContract`, and states the remediation without disclosing secret values.

#### `RET-005` Bare duration standing for distinct Artifact time contracts

- Owner: `artifact`
- First-sound phase: `A0`
- Rejection deadline: `A1`
- Invariant: Every Artifact-declared time bound names its exact clock, subject, and enforcement contract, and one bare duration never stands for maximum lifetime, idle timeout, maximum age from creation, maximum runtime duration, or record retention.
- Minimum witness: Declare one `timeout` duration and rely on it as both the idle timeout and the maximum Sandbox lifetime.
- Required diagnostic: identifies `RET-005`, names `artifact.lifetime`, `artifact.lifetime.maximum`, `artifact.idle`, and states the remediation without disclosing secret values.

#### `RET-006` Caller deletion of a retained Operation record

- Owner: `live`
- First-sound phase: `L0`
- Rejection deadline: `L0`
- Invariant: Operation retention is service-enforced and independent of target deletion, and the closed public method surface exposes no caller-facing Operation deletion, purge, or retention-override request.
- Minimum witness: Call a caller-facing `DeleteOperation` or retention-override method against a retained Operation record.
- Required diagnostic: identifies `RET-006`, names `operation.retentionContract`, `operation.id`, `requestError.details.method`, and states the remediation without disclosing secret values.

#### `RET-007` Proven deletion without a durable identity tombstone

- Owner: `core`
- First-sound phase: `T0`
- Rejection deadline: `T0`
- Invariant: A Delete Operation reports success only after durably committing a retained tombstone that preserves the Sandbox identity and its audit coordinates so that the identity can never be reused.
- Minimum witness: Report DeleteSandbox success with the Sandbox identity record removed and no tombstone committed.
- Required diagnostic: identifies `RET-007`, names `sandbox.tombstone`, `sandbox.id`, `operation.outcome`, and states the remediation without disclosing secret values.

#### `RET-008` Expiry creates a redundant Stop against a proven stopped Sandbox

- Owner: `live`
- First-sound phase: `L0`
- Rejection deadline: `L0`
- Invariant: A durable expiration trigger creates a system-originated `StopSandbox` Operation only when an extant runtime remains, and creates none when the Sandbox already carries a current durable stopped proof.
- Minimum witness: Let an expiration trigger create a StopSandbox Operation against a Sandbox that already carries a current durable stopped proof.
- Required diagnostic: identifies `RET-008`, names `sandbox.expiration.action`, `sandbox.status.runtime.state`, `operation.origin`, and states the remediation without disclosing secret values.

#### `RET-009` Provider-native TTL, auto-stop, or auto-delete left enabled

- Owner: `runtime`
- First-sound phase: `D0`
- Rejection deadline: `D0`
- Invariant: Generated target configuration disables every provider-native TTL, idle-sleep, auto-stop, and auto-delete mechanism, or fences it behind the Core durable expiry sequence.
- Minimum witness: Emit a generated microVM configuration that leaves the provider's idle auto-stop timer at its default.
- Required diagnostic: identifies `RET-009`, names `driver.generatedConfiguration.expiry`, `driver.preparedLaunch`, `sandbox.expiration`, and states the remediation without disclosing secret values.

#### `RET-010` Snapshot deleted while an exact reference or retention hold protects it

- Owner: `live`
- First-sound phase: `L0`
- Rejection deadline: `L0`
- Invariant: `DeleteSnapshot` is admitted only when no exact reference and no retention hold protects the Snapshot, and the refusal names the protecting references.
- Minimum witness: Issue DeleteSnapshot against a Snapshot that a restore-as-create Sandbox still references exactly.
- Required diagnostic: identifies `RET-010`, names `live.deleteSnapshot`, `snapshot.references`, `snapshot.retentionHold`, and states the remediation without disclosing secret values.

### Packet E Snapshot resource contract and class integrity

#### `SOP-001` Snapshot identity reused after Snapshot deletion

- Owner: `core`
- First-sound phase: `L0`
- Rejection deadline: `L1`
- Invariant: Every Snapshot ID identifies exactly one retained Snapshot resource and is never allocated again, including after that Snapshot is deleted.
- Minimum witness: Delete a Snapshot and let the next capture commit the same Snapshot ID.
- Required diagnostic: identifies `SOP-001`, names `snapshot.id`, `operation.target.snapshotId`, and states the remediation without disclosing secret values.

#### `SOP-002` Snapshot class or source disposition is omitted or provider-selected

- Owner: `live`
- First-sound phase: `L0`
- Rejection deadline: `L0`
- Invariant: Every snapshot capture request carries one exact resolved Snapshot class identity together with its complete resolved class definition and one explicit source-after-capture disposition of runtimeStatePreserved or stopped.
- Minimum witness: Issue CreateSnapshot with no Snapshot class member and let the provider pick a class.
- Required diagnostic: identifies `SOP-002`, names `live.snapshot.class`, `live.snapshot.sourceAfterCapture`, and states the remediation without disclosing secret values.

#### `SOP-003` Filesystem Snapshot class relied on for runtime continuity

- Owner: `live`
- First-sound phase: `L0`
- Rejection deadline: `L0`
- Invariant: A capture or restore request derives no memory, Process, open-descriptor, clock, network-connection, or device continuity from a Snapshot class whose kind is filesystem.
- Minimum witness: Request restore with memory and open-descriptor continuity from a Snapshot whose resolved class kind is filesystem.
- Required diagnostic: identifies `SOP-003`, names `live.snapshot.class.kind`, `live.snapshot.class.componentSet`, and states the remediation without disclosing secret values.

#### `SOP-004` Runtime Snapshot succeeds with incomplete required components

- Owner: `core`
- First-sound phase: `L1`
- Rejection deadline: `L1`
- Invariant: A capture using a runtime Snapshot class terminalizes as succeeded only when every component its class marks required is durable and its compatibility metadata is committed.
- Minimum witness: Terminalize a runtime-class capture as succeeded with the memory component missing from the Snapshot manifest.
- Required diagnostic: identifies `SOP-004`, names `operation.result.snapshotId`, `snapshot.manifest.componentSet`, and states the remediation without disclosing secret values.

#### `SOP-005` Capture accepted while a Core Process is nonterminal

- Owner: `live`
- First-sound phase: `L0`
- Rejection deadline: `L0`
- Invariant: Every v1 snapshot capture and every Fork is admitted only while every Core Process bound to the source runtime epoch is terminal, because v1 Snapshot classes support only coreProcessHandling = rejectNonterminal.
- Minimum witness: Request CreateSnapshot while one Core Process in the source epoch is still running.
- Required diagnostic: identifies `SOP-005`, names `live.snapshot.class.coreProcessHandling`, `sandbox.processes`, and states the remediation without disclosing secret values.

#### `SOP-006` Preserved source changes runtime state or epoch across capture

- Owner: `core`
- First-sound phase: `L1`
- Rejection deadline: `L1`
- Invariant: A capture declaring sourceAfterCapture = runtimeStatePreserved, including every Fork, terminalizes as succeeded only when the source Sandbox finishes in its original runtime state under its original runtime epoch, with any temporary quiescence and authority fully restored and attachment or external-connection disruption recorded separately.
- Minimum witness: Publish a `runtimeStatePreserved` capture as succeeded after the source came back under a newly allocated runtime epoch.
- Required diagnostic: identifies `SOP-006`, names `operation.result.sourceAfterCapture`, `sandbox.status.runtime.epoch`, and states the remediation without disclosing secret values.

#### `SOP-007` Snapshot omits or overrides its pinned Artifact identity

- Owner: `live`
- First-sound phase: `L0`
- Rejection deadline: `L0`
- Invariant: Every Snapshot manifest commits the exact source Artifact Set member, runtime-profile identity, and relevant immutable manifest digests resolved for the source runtime, and the capture request never supplies, substitutes, or overrides them.
- Minimum witness: Submit a CreateSnapshot request that names an Artifact Set member other than the one the source runtime resolved.
- Required diagnostic: identifies `SOP-007`, names `snapshot.manifest.artifactIdentity`, `snapshot.manifest.runtimeProfile`, and states the remediation without disclosing secret values.

#### `SOP-008` `sourceAfterCapture = stopped` published without the full Stop postcondition

- Owner: `core`
- First-sound phase: `L1`
- Rejection deadline: `L1`
- Invariant: A capture declaring `sourceAfterCapture = stopped` publishes that disposition only after the full Stop postcondition holds for the source: every Process terminal, containment absence proven, and the prior epoch unable to act.
- Minimum witness: Publish `sourceAfterCapture = stopped` while the source's containment-absence proof is still outstanding.
- Required diagnostic: identifies `SOP-008`, names `snapshot.sourceAfterCapture`, `sandbox.status.runtime.state`, `driver.containmentProof`, and states the remediation without disclosing secret values.

#### `SOP-009` Snapshot class identity disagrees with its resolved kind, components, or treatments

- Owner: `live`
- First-sound phase: `L0`
- Rejection deadline: `L0`
- Invariant: A Snapshot's resolved class identity agrees with its declared kind, captured component set, external-storage state, secret treatment, compatibility envelope, quiescence state, device state, portability, and Process handling; any disagreement fails capture admission.
- Minimum witness: Submit a capture whose class identity is declared `runtime` while its resolved component set contains only filesystem components.
- Required diagnostic: identifies `SOP-009`, names `snapshot.class`, `snapshot.components`, `snapshot.secretTreatment`, and states the remediation without disclosing secret values.

#### `SOP-010` Driver reports Snapshot capture success without per-component durability evidence

- Owner: `runtime`
- First-sound phase: `L1`
- Rejection deadline: `L1`
- Invariant: A driver reports a runtime Snapshot capture successful only after returning per-component durability and compatibility-metadata evidence for every component the resolved class marks required, and otherwise reports failure naming the exact missing component.
- Minimum witness: Report a runtime capture successful while returning no durability evidence for the memory component.
- Required diagnostic: identifies `SOP-010`, names `driver.snapshotComponentEvidence`, `snapshot.components`, `snapshot.class`, and states the remediation without disclosing secret values.

## Valid Cases

Invalid-state rejection is insufficient if a language makes necessary
configuration impractical. Every candidate must accept these cases and emit the
same canonical semantic value.

### `VAL-001` Minimal visible-profile Artifact

- Explicitly selects one descriptively named profile.
- Profile expansion is fully inspectable; no invisible default exists.
- Contains one package, one environment variable, one activation argv, one
  copy-in workspace slot, disabled network policy, and one secret slot.
- Produces bubblewrap and Firecracker-compatible target artifacts/profiles.
- Uses the locked `workspace-edit-offline` profile identity only where the
  design already locks it.

### `VAL-002` Resource-bound refinement

- A reusable library establishes minimum and maximum CPU/memory bounds.
- A consuming module narrows the interval without replacing it.
- Provenance retains both definitions and the resulting bound.

### `VAL-003` Multiple named profiles

- Exposes multiple descriptive, visible profiles.
- No profile is named `default`.
- One profile may be selected by an explicit product-chosen default policy, but
  expansion records that selection and source.
- Artifact identity changes if the selected expanded semantics change, not
  merely because profile source formatting changes.

### `VAL-004` Shared environment, multiple targets

- One common package/environment/activation/workspace definition lowers to
  bubblewrap and one microVM target.
- Target-specific machinery does not alter the common environment.
- Target manifests advertise different runtime capabilities explicitly.

### `VAL-005` Guest NixOS service extension

- A native guest NixOS module adds an arbitrary guest systemd service and guest
  package.
- It does not set host/runtime-owned options.
- Final NixOS module evaluation succeeds.
- Provenance distinguishes portable Artifact fields from native guest module
  definitions.

### `VAL-006` Target-specific Artifact addition

- One target adds implementation-specific immutable content or guest machinery.
- Common policy and environment remain unchanged.
- The addition is namespaced, target-scoped, and reflected in target identity.

### `VAL-007` Separately scoped runtime/provider extension

- Artifact declares a namespaced binding/capability contract.
- `CreateSandbox` provides the instance binding.
- Operator Configuration supplies provider implementation and credentials.
- No layer contains another owner's values.

### `VAL-008` User-published reusable module

- Imports a pinned library package.
- Evaluates with the network disabled after dependency acquisition.
- Expanded output records library identity/content digest and per-field
  provenance.

### `VAL-009` Real Nix interoperability

- References a real Nix package and store path through the supported typed
  boundary.
- Consumes a real dev shell/environment input.
- Builds a trivial derivation from the normalized Artifact.
- Does not serialize arbitrary executable Nix source through the portable wire
  format.

### `VAL-010` Creation-time materialization choice

- Artifact permits copy-in and live materializations and advertises compatible
  profiles for each.
- One `CreateSandbox` selects Firecracker plus copy-in and succeeds.
- A separate run selects the live-compatible target plus a read-only live
  binding and succeeds.

### `VAL-011` Service/API equivalence

- Direct CLI and managed-service definitions issue semantically identical Core
  Sandbox API calls.
- They resolve to the same Artifact, runtime profile, bindings, and creation
  result.
- No managed-service-only policy or lifecycle semantics appear.

### `VAL-012` Framework/CLI adapter neutrality

- A generic CLI invocation and an initial SDK adapter both create/use the same
  sandbox through the Core Sandbox API.
- Framework install/run/trajectory behavior stays in the adapter.
- Artifact and canonical value are identical across adapter choices.

### `VAL-013` Schema-compatible evolution

- An older supported Artifact source/wire version migrates deterministically to
  the current canonical version.
- Unknown optional data is not silently discarded.
- A future unsupported major fails as `STR-007`.
- Repeated migration is idempotent.

### `VAL-014` Offline reproducibility

- All source-language modules, schemas, evaluator/compiler binaries, Nix inputs,
  and product libraries are pinned.
- With network disabled and caches prepared, evaluation and construction
  reproduce the same canonical digest and Nix outputs.
- Checkout path and source comments/formatting do not affect semantic identity.

### `VAL-015` Verified Artifact Set load

- A built Artifact Set contains multiple target members whose identities,
  content digests, manifest claims, and protocol versions agree.
- Builder-produced facts identify the applicable versioned conformance suites,
  and prove each advertised runtime-profile capability passed them.
- Runtime loading verifies the complete manifest before creation resolution.
- The manifest contains slot contracts and safe provenance but no secret value,
  provider reference, or current-host identity.

### `VAL-016` Complete idempotent creation

- One creation binds every required slot exactly once with compatible kinds,
  selects an advertised target/profile, and supplies allocations within bounds.
- An optional initial Process uses the same Process contract as `Exec`.
- Repeating the canonical request with the same caller/idempotency key returns
  the same logical result; the test does not depend on duplicate provider
  creation.

### `VAL-017` Managed-service/Core-API equivalence

- A managed-service controller expresses stable desired state, autostart,
  reconciliation, and cleanup while issuing only canonical Core Sandbox API
  operations.
- The equivalent direct requests produce the same resolved creation and live
  operations.
- Generated service units depend on the Core API client and never invoke a
  target driver directly.

### `VAL-018` Capability-bounded live operations

- File operations stay inside permitted mutable paths and never return secret
  content or host backing paths.
- A declared port is exposed and revoked within resolved network authority.
- A supported optional operation advertises and proves its conformed
  capability before mutation.

### `VAL-019` Narrow per-Process execution

- A Process uses non-empty argv, an in-sandbox cwd, ordinary non-secret
  environment values, and an explicitly supported I/O mode.
- Its user, capabilities, rlimits, timeout, and output capture preserve or
  narrow the Sandbox contract.
- The same Process contract succeeds as an initial Process and through `Exec`.

### `VAL-020` Visible pinned profile and inert metadata

- Implicit and explicit selection of the same pinned
  `workspace-edit-offline` profile produce the same expanded semantics.
- Selection origin remains visible explanation data while source identity,
  version, digest, and complete expansion are recorded.
- Descriptive labels survive unchanged and control no policy or runtime field.

### `VAL-021` Complete portable environment projection

- A typed pinned package and devShell reference project supported packages,
  variables, ordered search paths, and explicit activation.
- Unsupported hooks are absent by construction, and no host variable is
  inherited.
- Cold, warm, and offline evaluation produce the same canonical environment.

### `VAL-022` Artifact-default Process

- One Artifact declares non-empty argv, `/workspace` cwd, ordinary environment,
  and the declared unprivileged workload user.
- A sibling valid Artifact leaves the default Process absent.
- Every target manifest preserves the explicit case and introduces no default
  in the absent case.

### `VAL-023` Complete portable filesystem contract

- Workspace and its slot agree; immutable input, source-free mount slot,
  private bounded scratch, and logical volume slot occupy disjoint paths.
- Ownership is workload-visible and protected project-control paths remain
  beneath the workspace root.
- No resource contains a host/provider identity or lifecycle operation.

### `VAL-024` Explicit network and host-channel contracts

- One Artifact is offline with no host channels.
- Another uses a versioned controlled-egress capability, compatible DNS rules,
  declared ingress port slots, and one typed broker channel.
- No network or host authority is inferred from the target.

### `VAL-025` Scoped resource bounds

- CPU concurrency, CPU quota, total Sandbox memory, task ceiling, scratch
  capacity, and volume capacity use explicit units and scopes.
- Each minimum is below its hard maximum.
- Create selects concrete allocations within all bounds.

### `VAL-026` Workload identity, security, and device contract

- A deterministic unprivileged user and explicit groups combine with
  no-new-privileges and a consistent empty capability ceiling.
- Versioned syscall and filesystem-confinement requirements remain distinct.
- A logical device class projects every induced environment, mount, group,
  capability, and channel effect into ordinary policy.

### `VAL-027` Secret and snapshot compatibility

- Required file delivery and optional environment delivery use complete,
  typed, value-free secret-slot alternatives.
- A filesystem snapshot excludes the secret surface; a separate permitted
  snapshot class records compatible secret treatment.
- Provider references appear only in a valid Create binding.

### `VAL-028` Separate persistence and output resources

- Private scratch, a persistent-volume slot, a filesystem-snapshot capability,
  workspace materialization, and two output conventions coexist as distinct
  resources.
- Output paths are writable and do not overlap protected or secret paths.
- One runtime operation selects one output and fails if its strict collection
  cannot be completed; export destination and retention remain runtime values.

### `VAL-029` Explicit target and runtime-profile set

- The platform is explicit and target/profile identities are unique.
- Bubblewrap and microVM target members share one identical common contract;
  each runtime profile is attached to a compatible target.
- A separate named Artifact Definition imports the same common module when its
  common policy intentionally differs.

### `VAL-030` Typed semantic and built identities

- Explicit and implicit selection of identical profile content share one
  semantic digest despite different explanation provenance.
- Updating pinned profile content changes the semantic digest.
- Target-member digests and Artifact Set identity remain typed, distinct, and
  mutually verified.

### `VAL-031` Monotonic lifetime narrowing

- Artifact declares a finite hard maximum lifetime.
- Create selects a shorter lifetime and Exec selects a shorter deadline.
- A second Artifact omits the ceiling and records that omission without
  importing a target default.

### `VAL-032` Complete target member projection

- One normalized Artifact builds Bubblewrap, Firecracker, Cloud Hypervisor, and
  OCI members.
- Every member manifest records the complete common contract, explicit
  absences, target requirements, suppressed defaults, and builder evidence.
- Byte-identical blobs are deduplicated, while Firecracker and Cloud Hypervisor
  retain distinct member manifests because their hard runtime requirements
  differ.

### `VAL-033` Profile-matched FD-safe runtime preparation

- Operator preflight verifies the complete pinned implementation bundle and
  every required host facility.
- A workspace source is resolved once to a retained object descriptor and that
  same object is attached by the driver.
- All backend defaults, try/fallback operations, raw hooks, and undeclared
  descriptors are absent.

### `VAL-034` Compatible secret-safe microVM snapshot

- Snapshot class explicitly includes memory and VMM state and separately
  accounts for disk and external storage.
- Required quiescing and secret scrub complete before capture.
- Restore uses the proven VMM/guest/kernel/CPU envelope and rebinds runtime
  identities while refreshing clone identity, entropy, tokens, and network
  state.

### `VAL-035` Verified content-preserving provider transfer

- A provider accepts a prebuilt member or digest-addressed OCI descriptor.
- The adapter verifies the complete content graph after transfer and cache
  lookup.
- Provider object IDs, credentials, placement, cache state, and retention
  remain non-semantic operator facts.

### `VAL-036` Evidenced provider-side construction

- The adapter sends a versioned construction request with complete pinned
  inputs and explicit provider-default suppression.
- The provider returns a new member identity, logs, provenance, and required
  conformance evidence.
- The adapter verifies bit identity when claimed, otherwise records a distinct
  member identity linked to the same semantic identity only after semantic and
  conformance equivalence succeeds.

### `VAL-037` Complete composition-contributor ledger

- A valid composition includes an imported product profile, an ordinary author
  contribution, a declared replaceable default selected by an explicit
  override, one losing contribution, and a registered native or migration
  contribution.
- Normalization records each contributor's immutable identity and semantic role
  as winning, losing, default, profile, import, override, native, or migration
  without treating display-only source spans or input order as semantic.
- Reversing order-independent imports preserves the complete contributor set
  and canonical semantic identity.

### `VAL-038` Exactly bounded canonical document

- One canonical document is valid UTF-8, uses only the accepted numeric and
  Unicode domains, and reaches exactly the configured maximum nesting depth
  without exceeding it.
- A second canonical document reaches exactly the configured maximum byte
  length without trailing data or partial interpretation.
- Both documents decode deterministically and proceed to ordinary semantic
  validation; the corresponding one-step-over documents are rejected at W0.

### `VAL-039` Complete native-handle identity

- A registered native handle binds the complete pinned transitive source-graph
  closure, registry namespace/version/digest, export attribute, native
  interface version, target system, affected member, and expected semantic
  projection.
- The semantic projection matches the declared extension effect before
  construction, and the validated tuple contributes to the constructed
  member's content identity.
- Re-evaluating the identical handle is deterministic; changing any tuple
  member either changes the constructed identity or is rejected before
  construction.

### `VAL-040` Pinned, closed, provenance-complete Operator Configuration

- A fully composed Operator Configuration records its pinned dependency
  closure, deterministic offline evaluation result, and complete contributor
  ledger including defaults, overrides, and losing definitions.
- The `OC0` validator produces the closed typed configuration only after every
  contributor's precedence and authority are accounted for.

### `VAL-041` Pinned, closed, provenance-complete Managed-Service Definition

- A fully composed Managed-Service Definition records its pinned dependency
  closure, deterministic offline evaluation result, and complete contributor
  ledger including defaults, overrides, and losing definitions.
- The `MS0` validator produces the closed typed service definition only after
  every contributor's precedence and authority are accounted for.

### `VAL-042` Revalidated resolved reentry producing a private PreparedLaunch

- A bounded, versioned resolved reentry envelope is strictly decoded, then its
  Artifact/member identity and resolved-stage facts are fully replayed.
- The product reacquires current Operator and host state and constructs a fresh
  private `PreparedLaunch`; no serialized or copied object is reused as one.

### `VAL-043` Commit under the current authority epoch

- A driver holds a capability naming Sandbox ID, runtime epoch 4, and authority epoch 7.
- Core validates all three against the durable authority high-water mark and commits only while 7 is current.
- After a handoff raises the mark to 8, the identical capability is refused and its holder is told to reacquire rather than being silently upgraded.

### `VAL-044` Fenced successor handoff

- Before granting successor effect authority, Core confirms for this exact handoff that the target validates the fencing token atomically.
- Where the target cannot fence, Core instead obtains a product-verifiable predecessor drain or termination boundary and records which proof it used.
- With neither proof available the affected resources are quarantined and reconciled, and no successor authority is granted.

### `VAL-045` Per-boundary fencing declaration

- A driver declares, for each effect boundary it exposes, whether the target validates its fencing token atomically or offers a verifiable drain boundary.
- An exclusive effect on a boundary with declared atomic fencing dispatches normally under the current authority epoch.
- An exclusive effect on a boundary with neither proof is refused before dispatch and the Operation is routed to reconciliation instead.

### `VAL-046` Ambiguity retained on an unfenced handoff

- A handoff cannot establish exclusive effect authority, so the affected Sandbox and its runtime are quarantined.
- The Operation terminalizes with its ambiguous outcome and the exact ambiguity variant naming the fencing proof Core lacks.
- A later reconciliation that obtains fencing evidence appends a linked successor resolution rather than editing the ambiguous outcome.

### `VAL-047` Idempotent retry and proven adoption

- A driver retries a create-instance call only under the provider's own idempotency token for that effect, reusing the token verbatim.
- An existing external execution is adopted only after its external identity, target, runtime epoch, and fencing all match the committed intent exactly.
- With neither a provider idempotency token nor exact adoption proof, the driver reconciles and reports ambiguity instead of retrying.

### `VAL-048` Declared evidence per outcome variant

- A driver publishes, for each Core outcome variant it may report, the native identities, state observations, fencing results, and supervision facts required to justify it.
- A launch reported as succeeded carries exactly the declared observation set for that variant.
- A provider response carrying only a status string maps to the ambiguity variant, naming the declared evidence the driver did not obtain.

### `VAL-049` Prior epoch fenced before Start commits

- A Start on a stopped Sandbox permanently fences runtime epoch 2 and its authority before committing the launch authorization for epoch 3.
- A predecessor holder of epoch 2 authority is thereafter refused at every authoritative Core commit.
- Where fencing cannot be completed the Start is not authorized, and the Sandbox is reconciled instead of relaunched.

### `VAL-050` Fresh identity for every lifetime

- A Create allocates a never-issued Sandbox ID, and a later Delete retires that ID permanently.
- A re-creation with the same name and byte-identical Artifact receives a different Sandbox ID.
- A Fork child and a restore-as-create each allocate their own fresh Sandbox ID while recording the parent or source Snapshot identity as provenance only.

### `VAL-051` Epoch one or an explicit no-runtime marker

- A Create that ends running durably commits runtime epoch 1 before the launch it authorizes and returns it on the Create result.
- A Create that ends stopped commits an explicit no-runtime marker rather than leaving the epoch absent, null, or zero.
- Both records occupy the same result field, so a later Start can allocate the next epoch without inferring one.

### `VAL-052` Name released by Delete before reuse

- A Create takes the name `agent-workspace` while no undeleted Sandbox holds it.
- A Delete of the holder releases the reservation, and a later Create takes the same name with a fresh Sandbox ID.
- The two lifetimes stay distinguishable by Sandbox ID, and the name resolves to exactly one Sandbox at any instant.

### `VAL-053` Strictly increasing epoch committed before launch

- A Sandbox created running holds epoch 1; a Stop followed by a Start commits epoch 2 durably before dispatching the launch.
- That Start's launch fails ambiguously and epoch 2 stays consumed, so the next Start commits epoch 3.
- A same-Sandbox Restore and a Fork each consume the next unused epoch within their own Sandbox ID.

### `VAL-054` Exec pinned to an observed Sandbox runtime

- The caller reads Sandbox ID and runtime epoch from the Create or Get result and copies both into the Exec request.
- Both coordinates are required fields of the canonical Exec request, so a partial reference is not expressible.
- The accepted Process records exactly the pair it was admitted against.

### `VAL-055` Typed stale-runtime result on epoch mismatch

- A caller holding epoch 3 issues a live mutation after a Stop/Start installed epoch 4.
- Core returns the typed stale-runtime result naming the requested Sandbox and the expected epoch 3, and dispatches nothing.
- The caller refreshes its handle, observes epoch 4, and reissues the identical mutation, which is admitted unchanged.

### `VAL-056` Exec refused against a replaced runtime

- A cached handle naming epoch 2 is used for an Exec after a Restore installed epoch 3.
- Core returns the typed stale-runtime result; no Core Process ID is allocated and no execution is dispatched.
- After refreshing to epoch 3 the same Exec request body is admitted unchanged.

### `VAL-057` Coordinates kept in their declared domains

- A request resolves the name alias once, pins the returned Sandbox ID, and carries only that ID thereafter.
- An etag precondition and an expected-runtime-epoch precondition are evaluated independently, so satisfying one never satisfies or excuses the other.
- An output or event cursor appears only in an observation request, and the runtime epoch appears only as an expected-value precondition.

### `VAL-058` Snapshot targeted by identity, verified by digest

- A Restore names the Snapshot ID in its target position and separately carries the manifest digest it expects.
- The digest is checked for content integrity only after the Snapshot ID resolves, and resolves nothing on its own.
- The canonical request type offers no position in which a manifest digest can act as a target.

### `VAL-059` Retired Snapshot ID returns target-not-found

- A Snapshot is deleted, and a later Restore naming its ID returns the typed target-not-found result.
- A second, distinct Snapshot with an identical manifest digest exists in the store and is not substituted.
- The caller lists Snapshots, selects the surviving Snapshot ID explicitly, and restores from it.

### `VAL-060` Every Operation carries its sealed target variant

- A Stop carries the Sandbox target variant with the Sandbox ID and the expected runtime epoch observed on the handle.
- A Signal carries the Process target variant with Process ID, Sandbox ID, and runtime epoch, all resolved.
- Each accepted Operation durably records exactly the tagged variant its method declares, with no sealed coordinate left absent or unresolved.

### `VAL-061` Retry reconciles only the committed target

- A Signal Operation commits its Process ID, Sandbox ID, and runtime epoch at acceptance.
- A transport retry and a later reconciliation both resolve strictly against that committed triple.
- Where no Process exists under that triple, a linked successor Operation is created rather than retargeting the original.

### `VAL-062` Both epochs recorded on a runtime-replacing result

- A Start from stopped records the previous runtime epoch as explicitly absent and the resulting epoch as 2.
- A same-Sandbox Restore records previous epoch 2 and resulting epoch 3.
- The Sandbox status epoch after commit equals the recorded resulting epoch, so no reader has to infer the transition.

### `VAL-063` Attachment continuity reported as its own outcome

- A live resize preserves the runtime, reports attachment `preserved`, and leaves the runtime epoch unchanged for an independent reason.
- A Restore replaces the runtime, reports attachment `reconnect-required`, and separately records the newly allocated epoch.
- Neither field is derived from the other: a preserved attachment never implies epoch continuity, and an unchanged epoch never implies the attachment survived.

### `VAL-064` Process permanently bound to one runtime

- An accepted Exec allocates a fresh Core Process ID bound to the exact Sandbox ID and runtime epoch it was admitted against.
- When that runtime is later replaced, the Process record keeps its original binding and terminalizes under it.
- A subsequent Exec against the new epoch allocates a different Core Process ID.

### `VAL-065` Native identifiers kept as scoped evidence

- A driver records the guest PID and the VMM instance identity as scoped protected evidence attached to the launch attempt.
- Public Sandbox, runtime, Process, Operation, and Snapshot identities remain Core-allocated and resolve without consulting any native identifier.
- Those same native identifiers remain usable for reconciliation and adoption proof without ever appearing in an identity, target, or authority position.

### `VAL-066` Server-allocated first epoch

- The canonical CreateSandbox request type has no runtime-epoch field, so no caller, adapter, or create-native extension can supply, preserve, or reset one.
- The Create result returns the allocated epoch and clients read it from there.
- A restore-as-create records the source Snapshot's provenance and still receives a freshly allocated first epoch.

### `VAL-067` Epoch expressible only as a precondition

- A live mutation carries `expectedRuntimeEpoch` as a precondition, and the request type contains no assignable epoch field.
- Core allocates the next epoch for any runtime-replacing mutation and returns it on the result.
- A live-native extension inherits the same request type and therefore cannot introduce a settable epoch.

### `VAL-068` Name fixed at Create, metadata still mutable

- UpdateSandboxMetadata changes labels and annotations and has no field able to express a Sandbox name.
- SetSandboxExpiration changes only the expiration and leaves the name untouched.
- A caller wanting a different alias creates a new Sandbox and deletes the old one, releasing the old name for reuse.

### `VAL-069` Cursors observe, Process IDs identify

- A process output read carries a cursor in the observation request and returns the next cursor.
- Signal and Terminate carry only the Core Process ID in the target position.
- Native execution identifiers appear in evidence only and are accepted in no identity, target, precondition, or authority position.

### `VAL-070` Request rejection only before acceptance

- A CreateSandbox with an unbound required slot is refused as a request rejection while no Operation, dispatchable effect intent, external invocation, or recoverable accepted result exists.
- Once acceptance commits, a provider failure is reported as the Operation's failed outcome rather than as a request rejection.
- The two are distinguishable by construction: a request rejection carries no Operation handle, and every accepted request carries one.

### `VAL-071` Live rejection only before acceptance

- A live resize outside immutable bounds is refused as a request rejection before any Operation, effect intent, external invocation, or recoverable accepted result exists.
- After acceptance, a driver failure is embedded in the Operation's terminal outcome instead of surfacing as a rejection.
- The four acceptance conditions are proven together, so no code path can return a rejection once a dispatchable intent is durable.

### `VAL-072` Exec rejection only before acceptance

- An Exec with empty argv is refused before any Process, dispatchable effect intent, external invocation, or recoverable accepted result exists.
- After acceptance, a failure to start is reported as the Process's terminal state rather than as a request rejection.
- A rejected Exec allocates no Core Process ID; every accepted Exec allocates one.

### `VAL-073` Acceptance committed atomically before launch

- One atomic write commits the Operation handle, canonical request and digest, preallocated Sandbox identity, idempotency binding, allocated runtime epoch, effect intent, and effect-authority epoch.
- Only after that write completes does the driver receive the launch.
- A crash between the commit and the dispatch leaves a recoverable Operation that reconciliation can resolve against its own committed intent.

### `VAL-074` Live acceptance committed before dispatch

- One atomic write commits the Operation handle, canonical request and digest, sealed target with every applicable freshness precondition, idempotency binding, effect intent, and effect-authority epoch.
- The live external effect is dispatched only after that write.
- An interrupted dispatch stays recoverable because the committed intent names exactly what was attempted and against which target and epoch.

### `VAL-075` Exec acceptance committed before dispatch

- One atomic write commits the Core Process ID, canonical request and digest, exact Sandbox runtime reference, idempotency binding, launch token, effect intent, and effect-authority epoch.
- Only then is the execution dispatched into the Sandbox.
- The launch token lets any later observation bind evidence to this exact attempt rather than to some other execution.

### `VAL-076` Create idempotency resolved before mutable-state checks

- A CreateSandbox replay is authorized and canonicalized, then looked up by idempotency coordinate before quota, capacity, concurrency, and target-state checks run.
- An equal replay returns the original Operation handle even though the quota that admitted the first request is now exhausted.
- A first-time request continues into the mutable-state checks with no change in behaviour.

### `VAL-077` Live idempotency resolved before lifecycle checks

- A live mutation replay is looked up by idempotency coordinate immediately after authorization and canonicalization.
- An equal replay of an accepted Stop returns the original Operation even though the Sandbox has since reached the stopped phase.
- A first-time request proceeds to lifecycle-state, concurrency, capacity, and quota checks unchanged.

### `VAL-078` Exec idempotency resolved before admission checks

- An Exec replay is looked up by idempotency coordinate before execution-admission, concurrency, capacity, and quota checks.
- An equal replay returns the original Process even though the Sandbox has since reached its concurrent-process ceiling.
- A first-time Exec proceeds to execution admission unchanged.

### `VAL-079` One live coordinate, one canonical intent

- An authenticated scope, method, and idempotency key bind exactly one canonical request digest for the published recovery window.
- An equal replay returns the original Operation and dispatches no second effect.
- A replay under the same coordinate with a different canonical digest is refused with the typed idempotency conflict and dispatches nothing.

### `VAL-080` One exec coordinate, one canonical intent

- An authenticated scope, method, and idempotency key bind exactly one canonical Exec digest for the published recovery window.
- An equal replay returns the original Process and dispatches no second execution.
- A replay under the same coordinate with different argv, environment, or working directory is refused with the typed idempotency conflict.

### `VAL-081` Semantic-only canonical digest

- The canonical digest covers every field able to change target, authority, effect, policy, result, or postcondition.
- Trace identifiers, correlation metadata, and transport-only headers are excluded, so the same intent submitted twice under different trace IDs is one canonical request.
- Adding any field able to change the effect changes the digest and therefore conflicts with a prior binding rather than silently reusing it.

### `VAL-082` Expired create record returns recovery evidence

- A CreateSandbox replay whose coordinate has aged out of the published recovery window returns a recovery error rather than a fresh acceptance.
- The error carries tagged prior-acceptance evidence naming the original Operation.
- No new creation is accepted until the caller observes the prior outcome or submits a fresh key with explicit new intent.

### `VAL-083` Expired live record returns recovery evidence

- A live mutation replay whose coordinate is retired or older than the published recovery window returns a recovery error.
- The error carries tagged prior-acceptance evidence naming the original Operation.
- The caller must observe the prior outcome or supply a fresh key; the expired coordinate authorizes no new mutation.

### `VAL-084` Expired exec record returns recovery evidence

- An Exec replay whose coordinate is retired or older than the published recovery window returns a recovery error.
- The error carries tagged prior-acceptance evidence naming the original Process.
- Explicit observation of the prior Process is required before any new execution is formed.

### `VAL-085` Failed Operation recovered, not replayed

- A replay under the coordinate of a terminally failed Operation returns that Operation and its failed outcome.
- Nothing is dispatched on the replay path, so a retry loop cannot manufacture repeated external effects.
- A genuinely new attempt uses a new idempotency key and carries the operation-specific authority to attempt the effect again.

### `VAL-086` Cancellation requested, outcome still owned by the Operation

- CancelOperation records `cancel_requested` monotonically on the existing Operation and allocates no new Operation.
- That Operation later publishes `cancelled` only once exclusion of the effect is proven, and otherwise publishes succeeded, failed, or its ambiguous outcome.
- A second cancellation request is absorbed by the same monotonic marker and changes nothing else.

### `VAL-087` Representation and recovery committed together

- UpdateSandboxMetadata commits the new representation, its resulting etag, the idempotency binding, and the recoverable committed response in one write.
- An equal replay returns that stored response without reapplying the update, so the etag does not advance twice.
- There is no window in which the representation is durable and its recovery record is not, because there is only one commit.

### `VAL-088` Atomic-update methods admitted only on transactional storage

- An Operator Configuration selecting transactional record storage passes admission and advertises the atomic-update methods.
- A configuration selecting non-transactional storage fails admission at `O0` with a diagnostic naming the storage capability and the affected methods.
- The deployment may not substitute a durable Operation for the atomic update, so every caller sees a method set the storage can actually honour.

### `VAL-089` Launch attempt recorded with its recovery class

- Before each external launch effect, Core durably writes the attempt with its exact parameters and one of the four locked recovery classes.
- A provider offering an idempotency token is recorded under that class, and the same token is reused verbatim on any retry.
- Where no class applies, the attempt is recorded as `none available` and any interruption is reported as ambiguity with quarantine rather than retried.

### `VAL-090` Live attempt recorded with its recovery class

- Before dispatching a live external effect, Core durably writes the attempt, its exact parameters, and one of the four locked recovery classes.
- A provider-idempotent effect is recorded under that class and its token is reused verbatim on retry.
- Where no class applies, the attempt is recorded as `none available` and quarantined as ambiguous if interrupted.

### `VAL-091` Exec attempt recorded with its recovery class

- Before dispatching an exec external effect, Core durably writes the attempt, its exact parameters, and one of the four locked recovery classes.
- The record is bound to the Process's launch token so later evidence resolves this attempt and no other.
- Where no class applies, the attempt is recorded as `none available` and quarantined as ambiguous if interrupted.

### `VAL-092` One create coordinate, one canonical intent

- An authenticated scope, method, and idempotency key bind exactly one canonical CreateSandbox digest for the published recovery window.
- An equal replay returns the original Operation and the same Sandbox identity without creating a second Sandbox.
- A replay under the same coordinate naming a different Artifact, binding, or allocation is refused as a conflict and dispatches nothing.

### `VAL-093` Launch outcome bounded by the proven knowledge set

- A launch commits `succeeded` only when every possibility remaining under Core's evidence satisfies the exact success postcondition, cancellation is `notRequested` or proven lost, mutation authority is quiesced, and residual effects are known.
- `failed` or `cancelled` is committed only when no remaining possibility satisfies that postcondition.
- Every other nonempty knowledge set commits `unknown` with its exact ambiguity variant, which a later linked successor may resolve.

### `VAL-094` Live outcome bounded by evidence

- A live mutation commits a definite arm only when that arm's evidence predicate holds over every remaining possibility.
- An unresolved `cancellation = requested`, an internal timer expiry, or an expired RPC deadline leaves the Operation `unknown` with its missing proofs enumerated.
- Reconciliation later appends a linked successor once fenced evidence resolves the ambiguity, leaving the original record intact.

### `VAL-095` Exec outcome bounded by launch-token evidence

- A Process terminalizes only when every remaining possibility satisfies that outcome's exact predicate, dispatch authority is quiesced, and residuals are known.
- All accepted evidence is bound to the same launch token, so another execution's exit cannot terminalize this Process.
- Every other nonempty knowledge set leaves the Process in reconcilable `unknown`.

### `VAL-096` Teardown outcome proven, not assumed

- A Delete commits `succeeded` only when target absence, descendant quiescence, and cleanup completion hold over every remaining possibility.
- A missing observation or a provider acknowledgement of a cleanup call is recorded as evidence, never as completion.
- Otherwise the Operation commits `unknown` with its residual obligations enumerated and observable.

### `VAL-097` Terminal launch result appended, never edited

- A launch Operation's terminal outcome and payload become immutable at commit.
- A later adoption that discovers the runtime did in fact start appends a linked successor resolution Operation referencing the unchanged predecessor.
- Readers reconstruct the full history from predecessor and successor links without any committed record having changed.

### `VAL-098` Teardown compensation recorded as a forward effect

- A teardown-branch compensation is recorded as a new Operation with its own durable record, evidence, and outcome, linked by a `compensates` reference.
- The compensated Operation's outcome and its external-effect ledger entries stay unchanged.
- Restoring in-sandbox state from a Snapshot or filesystem capture is likewise a forward effect and marks no prior external effect as reversed.

### `VAL-099` Observation deadlines end only the observation

- A Wait with a five-second deadline returns the latest Operation state together with an explicit condition-met flag set false.
- The observed Operation, Sandbox, Process, and Snapshot records are byte-identical before and after the expiry.
- Reissuing the Wait resumes observation without anything having been advanced, cancelled, or terminalized in the meantime.

### `VAL-100` Interrupted attempt resolved by its own intent

- A crash between dispatch and terminalization leaves a committed effect intent, launch token, exact external identity, and authority epoch.
- Resumption queries the provider for exactly that external identity and resolves the Operation only from evidence bound to it.
- Where that evidence cannot be obtained the Operation terminalizes `unknown`; no second attempt is dispatched to discover the first one's fate.

### `VAL-101` Ambiguous launch does not authorize relaunch

- A launch that terminalized `unknown` leaves the Sandbox quarantined with its missing proofs recorded and observable.
- A successor launch proceeds only after an independently proven fencing boundary or an exact adoption identity is established.
- Alternatively a newly authorized caller request with its own idempotency key and accepted intent begins a fresh traversal.

### `VAL-102` Ambiguous live outcome quarantines instead of retrying

- A live mutation that terminalized `unknown` blocks repeated, replacement, and compensating external effects against the same target and epoch.
- A linked reconciliation Operation first gathers fenced evidence or an exact adoption identity.
- A newly authorized caller request carrying its own accepted intent may also establish successor authority.

### `VAL-103` Residual obligations discharged before further destruction

- A Delete that terminalized `unknown`, or failed with residuals, keeps each residual obligation open and observable and releases no identity.
- A linked cleanup Operation held by an actor with current authority durably discharges each exact obligation.
- Only once every obligation is discharged may a successor destructive effect, tombstone, or identity release proceed.

### `VAL-104` Launch-branch compensation as a forward effect

- A partially created runtime is removed by a new compensating Operation carrying its own durable record, evidence, and outcome.
- The compensated launch Operation keeps its committed outcome and every entry in its external-effect ledger.
- The `compensates` link makes the pairing readable without either record being edited.

### `VAL-105` Terminal live result appended, never edited

- A live mutation Operation's terminal outcome and payload become immutable at commit.
- A later reconciliation that resolves an `unknown` appends a linked successor Operation referencing the unchanged predecessor.
- The predecessor's revision does not advance and its payload bytes do not change.

### `VAL-106` Terminal teardown result appended, never edited

- A teardown Operation's committed terminal outcome and payload become immutable at commit.
- A cleanup reconciliation that later proves target absence appends a linked successor Operation referencing the unchanged predecessor.
- Residual obligations are discharged on the successor record, leaving the predecessor's outcome and revision untouched.

### `VAL-107` Precise named methods on the public union

- Restart intent is expressed as observed `StopSandbox` then `StartSandbox`, each with its own Operation and epoch consequences.
- Kill intent is expressed as `SignalProcess` or `TerminateProcess`, and teardown as `StopSandbox` then `DeleteSandbox`.
- Every admitted method is named, typed, and resource-oriented with one declared postcondition; an SDK composite helper may still issue exactly these calls.

### `VAL-108` One exact postcondition per method

- `SuspendSandbox` declares the single postcondition `suspended` with execution admission `closed`, identical on every target.
- Capability gating removes the method from unsupported targets rather than letting them reinterpret its meaning.
- The generated operation contract carries a success predicate for every method in the union.

### `VAL-109` Two narrow etag-guarded representation updates

- `UpdateSandboxMetadata` changes labels and correlation metadata under an etag precondition.
- `SetSandboxExpiration` changes the caller-managed schedule under the same guard.
- Resources, network policy, runtime replacement, and provider tier are reached only through their own operations with their own authorization, capability, and epoch contracts.

### `VAL-110` Adapter-owned attachment over Core primitives

- An SDK Session object is composed from Sandbox reads, `Exec`, Process I/O streams, and the named lifecycle methods.
- Rebinding after a control-plane failure is the adapter's explicit responsibility and consumes no Core lifecycle authority.
- The Core method union contains no attach, connect, detach, shell, or session arm.

### `VAL-111` Delete against a proven stopped Sandbox

- A caller observes `StopSandbox` succeed, then issues `DeleteSandbox` against the durable stopped proof it established.
- An expiry-triggered Delete is created at the same admission station under the same proof and links the Stop Operation id that produced it.
- A Delete against a `running`, `suspended`, or `unknown` Sandbox is refused with its typed reason and performs no stop.

### `VAL-112` Representation update touching only the Core record

- An accepted `UpdateSandboxMetadata` commits new labels and a new etag while the runtime epoch is unchanged.
- The running workload, the resolved Artifact policy, and the lifecycle lane are untouched by the update.
- `SetSandboxExpiration` behaves identically for the caller-managed schedule.

### `VAL-113` Exec admitted only while admission is accepting

- An Exec submitted while execution admission is durably `accepting` is accepted and belongs to the current epoch's Process set.
- An Exec submitted after a Stop closes admission receives the typed admission-closed reason naming the closing operation.
- An Exec submitted after an expiration instant is durably recorded as a system trigger receives the same typed refusal.

### `VAL-114` Exec against a Core-sequenced epoch

- A provider standby recovery is observed, sequenced by the Core as the next epoch, and its execution-admission record committed.
- Only then is an Exec bound to that epoch admitted.
- An Exec naming a runtime with no Core epoch record is refused with the typed unsequenced-runtime reason.

### `VAL-115` Fenced launch authority revalidated at dispatch

- An accepted Process revalidates its fenced launch-authority grant against the Core durable record immediately before its first external dispatch, and dispatches.
- A grant revoked by a concurrent Stop between acceptance and dispatch terminalizes the Process with the revocation reason and produces no external effect.
- A grant withheld by a Suspend leaves the Process accepted and undispatched until a successful same-epoch Resume.

### `VAL-116` Close, revoke, then capture

- A Stop commits the admission-closure record, then the launch-authority revocation record, then snapshots the Process set of the current epoch.
- Any Exec arriving after the closure record is refused on its own traversal and can never join the captured set.
- A Suspend follows the same ordering, withholding rather than revoking launch authority.

### `VAL-117` Regrant only after a succeeded same-epoch Resume

- A Process left accepted and undispatched by a Suspend regains launch authority once the same-epoch Resume Operation commits success.
- Its original deadline still applies, and an expired deadline terminalizes it instead of regranting.
- A termination request received while suspended terminalizes the Process and no regrant occurs.

### `VAL-118` Launch publishes accepting only for a proven epoch

- A Start publishes `running` with admission `accepting` only after the new epoch is observed present and executing under current fenced authority.
- A launch whose presence evidence is incomplete publishes `provisioning` or `unknown` with admission `closed`.
- Exec admission against the new epoch begins exactly when that status record commits.

### `VAL-119` Driver returns typed capability-unsupported

- A driver receiving a validated PreparedLaunch stage that requires same-epoch suspend compares it against its declared conformed capability set.
- An unsupported requirement produces the typed capability-unsupported result before any effect-producing work.
- No alternative native mechanism with a weaker guarantee is substituted.

### `VAL-120` Lowering that establishes exactly the requested postcondition

- Each native step in the lowering declares its own postcondition and effect class, and their composition equals the requested postcondition.
- A driver with no step sequence producing that postcondition returns unsupported before any effect.
- No colder, wider, or more destructive fallback is selected when the exact lowering is unavailable.

### `VAL-121` Exec advertised only with full execution conformance

- The driver declares evidence for a targetable containment unit covering the Process and its owned descendants, durable output spooling with stable byte cursors and explicit truncation, exact terminal evidence, stdin ownership and close semantics, provable termination, and post-failure adoption.
- A microVM target satisfies this with a Core-managed in-guest supervisor and a durable host-side spool.
- A target unable to prove adoption after control-plane failure advertises no Core Exec, and the Core admits no Exec against it.

### `VAL-122` Artifact limited to declarative static facts

- An Artifact declares required capabilities, hard ceilings, slot contracts, and supported target profiles, all frontend-independent and time-invariant.
- A workload needing a specific runtime epoch or free capacity expresses it as a runtime precondition on the Core operation instead.
- The built manifest carries no current Sandbox, Process, Operation, provider-availability, or evidence-freshness assertion.

### `VAL-123` Start against a proven stopped Sandbox

- A caller observes `StopSandbox` succeed and its epoch retire, then issues `StartSandbox`, which allocates the next epoch.
- A `StartSandbox` against a `running`, `suspended`, `provisioning`, or `unknown` Sandbox is refused with its typed reason.
- The stopped proof consulted is the Sandbox's current durable record, not a cached earlier observation.

### `VAL-124` Placement re-admitted for the current epoch

- Before dispatch, the operator admission plane re-admits the resolved placement, capacity, and tier against the current epoch and records that admission.
- A second Start of the same Sandbox re-admits rather than reusing the admission granted to the first launch.
- A placement whose capacity is no longer admissible fails the launch before any driver effect.

### `VAL-125` Explicit named target branch for an absent capability

- An Artifact enabling both a process target and a microVM target declares a named target branch for a capability only the microVM target provides.
- Each branch is inspectable in the expanded value and reflected in that target's member identity.
- Artifact validation fails when an enabled target lacks the capability and no branch names it, instead of deferring the discovery to launch.

### `VAL-126` Epoch-fenced provider event admitted as evidence

- A driver decodes a provider stop event carrying authority epoch 4 while the Sandbox's current authority epoch is 4, and the event is admitted as the transition it evidences.
- The same event redelivered after epoch 5 becomes current is retained as non-authoritative evidence and produces no state transition.
- The retained evidence stays readable for reconciliation and carries no secret or host-identity material.

### `VAL-127` Serialized lifecycle lane with a typed conflict

- A `SuspendSandbox` holding the lane causes a concurrent `StopSandbox` to receive a typed conflict naming the active Operation id.
- An ordered pair the compatibility ledger explicitly permits, such as a cancel request against the lane holder, is admitted.
- Exactly one nonterminal Operation is referenced by the Sandbox's lifecycle-operation field at any time.

### `VAL-128` Creation resolves an advertising profile

- A creation requiring same-epoch suspend and resume resolves a member and runtime profile advertising that exact conformed capability.
- A creation requiring a capability no enabled profile advertises is rejected at creation with the required and effective capability sets both named.
- No weaker mechanism, provider default, or approximate substitute is selected on the caller's behalf.

### `VAL-129` Expiration cleared without widening policy

- `SetSandboxExpiration` with an explicit removal clears the caller-managed schedule and returns the committed representation.
- The Artifact hard lifetime ceiling and the Managed-Sandbox lifecycle policy remain present and binding in that committed record.
- A later assigned instant is still validated against the unchanged ceiling.

### `VAL-130` Restore under the pinned Artifact policy

- A same-Sandbox `RestoreSandbox` selects retained state whose compatibility is proven against the Sandbox's pinned Artifact.
- Environment, filesystem, network, identity, device, secret, and target-profile policy are taken from that Artifact unchanged.
- Different policy requires creating a new Sandbox from a different Artifact rather than a restore.

### `VAL-131` Restore-as-create refining within pinned policy

- A restore-as-create selects an advertised target profile and narrows allocations within the pinned Artifact's bounds.
- It binds required slots with concrete values but replaces no immutable policy dimension.
- The source Sandbox's disposition is unchanged, and the new Sandbox begins at epoch 1 or, if stopped, with no epoch.

### `VAL-132` Explicit resolved initialRuntime in the canonical request

- A CLI invocation, an SDK call, and a managed-service reconciliation each resolve `running` or `stopped` in their own layer and submit that exact value.
- The accepted Operation record and the canonical request both carry the resolved value, so replaying the canonical request applies no further default.
- A named runtime profile preferring `stopped` records the selection and its source instead of applying it after acceptance.

### `VAL-133` Stopped creation commits without a launch effect

- A creation with resolved `initialRuntime = stopped` commits a durable Sandbox whose runtime state is `stopped` and whose execution admission is `closed`.
- No runtime epoch is allocated and no driver, host, or provider is invoked for the creation.
- A subsequent explicit `StartSandbox` allocates epoch 1 and performs the first launch.

### `VAL-134` Named commands with output-only status

- A caller issues `StopSandbox` and then reads `status.runtime.state`, `status.execution.state`, and `status.lifecycleOperation` as observations.
- No public request type offers a runtime state, desired state, or presentation-label field for a caller to populate.
- A Managed-Sandbox Service expresses stable desired state in its own definition while issuing only the same named Core operations.

### `VAL-135` Presentation labels derived at read time

- A Suspend in flight stores runtime state `running` plus the nonterminal Operation reference, and the word `suspending` is computed when the Sandbox is read.
- Serialization decisions consult the durable lane and the authoritative runtime state, never the derived word.
- Changing only the presentation vocabulary changes no durable record and no Artifact or Sandbox identity.

### `VAL-136` Admission closed for every non-running state

- A Sandbox whose current epoch is proven present and executing under current fenced authority commits `running` with execution admission `accepting`.
- The same Sandbox during a lifecycle mutation commits `closed` with the typed reason `lifecycle-mutation` while still `running`.
- `provisioning`, `suspended`, `stopped`, and `unknown` each commit `closed` with their own typed reason.

### `VAL-137` Evidenced suspend with retained continuity

- The driver returns quiescence evidence, the retained epoch identity, and the capability-required memory and Process continuity proofs.
- The Core commits `suspended` with execution admission `closed` and terminalizes the Suspend as succeeded.
- A target able only to stop and retain a filesystem never advertises the capability, so no Suspend is admitted against it.

### `VAL-138` Driver returns target-native continuity probes

- A microVM driver returns the VMM pause acknowledgement, the retained memory-region identity, and the unchanged guest Process table for the same epoch.
- A process-target driver unable to prove Process continuity reports the Suspend as failed rather than as succeeded.
- Every probe result is attached to the report as decoded evidence rather than summarized as a single boolean.

### `VAL-139` Cold fallback terminalized as a failed Resume

- A Resume whose post-effect evidence proves the retained epoch resumed under exclusive authority with control and conformance re-proven is terminalized as succeeded.
- A Resume that observes a replacement instance is terminalized as failed with the observation retained and the Sandbox left `unknown` or `stopped` as proven.
- Recovery from that failure is an explicitly authorized `StartSandbox` that consumes a new epoch.

### `VAL-140` Atomic in-place resize on a running Sandbox

- The complete requested allocation is applied in one step, the epoch observed after the effect equals the epoch observed before it, and the Process identity set is unchanged.
- The applied-resource evidence matches the request exactly, with no dimension left at its previous value.
- A target that can only resize by reboot terminalizes the Operation as failed and names the required Stop, stopped resize, and Start sequence.

### `VAL-141` Stopped resize records the next-Start allocation

- The validated allocation is committed as the Sandbox's next-runtime allocation while its runtime state stays `stopped`.
- No runtime epoch is allocated and no provider capacity is reserved or claimed by the resize.
- The following `StartSandbox` consumes that allocation and is the first point at which capacity is actually requested.

### `VAL-142` Stop lowered to close, revoke, drain, terminate, prove

- A process-target driver lowers Stop to admission close, launch-authority revocation, `cgroup.kill`, and a `populated=0` observation, leaving the logical Sandbox and its retained filesystem intact.
- A microVM driver lowers Stop to guest shutdown request, VMM termination, and host absence observation, without deleting the provider instance.
- A target profile whose only native stop is a destructive delete is rejected rather than used to serve Stop.

### `VAL-143` Unresolvable state committed as unknown

- A Stop whose containment proof is unavailable commits runtime state `unknown` with execution admission `closed` and a condition naming the missing predicate.
- The gathered evidence is retained for a system-originated reconciliation Operation that may later prove `running`, `suspended`, or `stopped`.
- The terminal result of the original Operation is never rewritten by that reconciliation.

### `VAL-144` Provider phase kept as decoded evidence

- A driver decodes a containerd task status of `RUNNING` and records it under `driver.providerStatus` without writing `sandbox.status.runtime.state`.
- Core runtime state is derived only from the postcondition proofs the Core contract names for that operation.
- A provider enum value the driver does not recognize is retained verbatim as evidence and never coerced onto a Core state.

### `VAL-145` Launch success gated on every declared probe

- A Create-running launch publishes success only after the new epoch is observed present and executing, control attachment is proven, the conformance suite passed, and admission is `accepting`.
- A launch whose conformance probe is unavailable is terminalized as failed or unresolved, with the epoch already consumed.
- The same gating applies unchanged to `StartSandbox` and same-Sandbox Restore.

### `VAL-146` Driver runs and returns its declared probe set

- The driver's declared probe set for the resolved runtime profile is executed against the exact new epoch and each result is returned with the report.
- An unavailable probe produces a failure report naming that probe, not a success report with the probe omitted.
- Probe results are attached as decoded evidence that the Core terminalization consumes directly.

### `VAL-147` Backend acknowledgements kept as evidence

- OCI `created`, containerd task registration, and VMM configuration acknowledgements are recorded as provider acknowledgements on the report.
- The `running` postcondition is proven by the evidence its own contract names, and the acknowledgements are reported alongside it rather than in place of it.
- A driver whose target offers only the acknowledgement reports the postcondition as unproven.

### `VAL-148` Provider loss recorded as its own event

- An observed provider idle-stop is written as an uncontrolled provider-loss event whose Operation origin is system.
- A reconciliation Operation obtains fenced evidence and commits the proven runtime state, or terminalizes as `unknown`.
- No Stop or Delete Operation is credited retrospectively and no caller-visible Operation changes its terminal result.

### `VAL-149` Auto-wake sequenced as a new epoch

- An observed provider-created replacement runtime is proven discontinuous from the prior epoch and durably sequenced as the next epoch.
- Execution admission is opened only after that epoch identity record commits.
- An Exec submitted between the observation and the sequencing receives the typed admission-closed reason.

### `VAL-150` Containment absence proven per target

- A process target proves absence with `cgroup.kill` followed by `cgroup.events` reporting `populated=0`, not with the initial child's exit status.
- A VM target proves absence by observing guest and VMM termination and host containment, not by the ACPI acknowledgement.
- Only after that proof does the driver publish `stopped`.

### `VAL-151` Grace expiry commits unknown with retained evidence

- A Stop whose driver returned a containment-absence proof before the grace deadline commits `stopped`.
- A Stop whose grace deadline elapses without that proof commits `unknown`, keeps admission `closed`, and retains the partial evidence.
- No successor authority is granted over the Sandbox while the state is `unknown`.

### `VAL-152` Delete succeeds on a durable cleanup proof

- Every Core-owned live resource covered by the Delete is proven absent and the cleanup proof is committed durably before success is published.
- The Sandbox leaves the live collection, a retained tombstone prevents ID reuse, and the Delete Operation stays readable for its own retention period.
- A Delete whose orphan disposition cannot be proven is terminalized as failed or unresolved with the cleanup obligation retained.

### `VAL-153` Manifest re-resolved at the launch stage

- A Start authorizes a launch that re-resolves the Sandbox's Artifact, member, and runtime-profile manifest before any driver preparation.
- The re-resolution reproduces the pinned semantic and built identities, so an unchanged Artifact yields an identical resolution.
- A launch whose resolution is absent or older than the Sandbox's current Artifact references is refused rather than served from the stale copy.

### `VAL-154` Suspend and Resume gated on the paired capability

- A conformed microVM profile advertising both same-epoch suspend and same-epoch resume admits both operations.
- A target advertising only one half admits neither, and the refusal names the missing half.
- A caller on such a target uses `StopSandbox` and `StartSandbox`, accepting the new epoch that implies.

### `VAL-155` Launch labels derived at read time

- A Create-running launch commits runtime state `provisioning` plus the nonterminal `CreateSandbox` Operation, and the word `creating` is computed on read.
- `starting` and `restoring` are computed the same way from the Operation kind and the authoritative status.
- The generated status type offers no field in which such a label could be stored.

### `VAL-156` Unresolvable launch committed as unknown

- A launch whose new epoch cannot be proven present or absent commits `unknown` with execution admission `closed` and a condition naming the missing predicate.
- The launch evidence is retained for a system-originated reconciliation Operation.
- A launch proven not to have established a live runtime, with cleanup complete, commits `stopped` instead.

### `VAL-157` Cursor advances strictly behind the persistence commit

- A Process writes 64 KiB to stdout during its execution.
- The spool durably persists the first 48 KiB and commits exactly that range.
- `process.status.output.cursor` advances only as far as `process.output.persistedThrough`.
- The remaining bytes become readable only after their own persistence commit.

### `VAL-158` Per-stream cursors, merged stream only under a merging terminal

- An ordinary Exec publishes independent monotonic cursors for stdout and stderr.
- Each cursor preserves ordering within its own stream and promises nothing across them.
- An Exec whose accepted contract selected a merging terminal additionally exposes one merged terminal stream.
- Callers that need interleaved ordering request that terminal at Exec time.

### `VAL-159` Reattachment from a cursor yields deduplicable chunks

- A reader disconnects and reattaches supplying its last known cursor.
- Every returned chunk carries the spool's stable sequence identity for its byte range.
- Chunks the reader already consumed are recognised by identity and discarded.
- The same identity is returned for the same byte range on every subsequent reattachment.

### `VAL-160` Lost response recovered by coordinate, not by replay

- A WriteProcessInput frame is accepted and receipted at lease A, sequence 7.
- The caller loses the response to a transport failure.
- It recovers by reading the retained receipt for lease A and sequence 7.
- The generated input path offers no operation that re-submits the accepted frame.

### `VAL-161` Exit committed, stream sealed separately after drain

- A Process commits `exited(0)` as its immutable terminal outcome.
- Bytes still buffered in the transport continue to be drained and appended to the spool.
- `process.status.output.sealedAt` is written only once backend exit and drain are both proven.
- A caller reading between the two events sees a terminated Process and an unsealed stream.

### `VAL-162` Driver proves exit and drain before the Core seals

- The bubblewrap driver observes process exit and reads its pipes to EOF.
- The microVM driver observes guest-agent exit and drains the vsock stream to its last byte.
- Each supplies `driver.outputDrainEvidence` naming the last byte drained for that spool.
- The Core seals the stream only on that evidence, never on a quiet read.

### `VAL-163` Explicit retention contract with a typed expiry result

- The spool declares its retention duration and byte limit as part of the output contract.
- A read from a still-retained cursor returns the full requested range.
- A read from an expired cursor returns the typed output-expired result naming the earliest retained cursor.
- Truncation is recorded at `process.output.truncatedAt` rather than silently shortening the stream.

### `VAL-164` Fully coordinated Process-control command

- A WriteProcessInput carries Process ID, Sandbox ID, runtime epoch, writer lease, and sequence 12.
- A ResizeProcessTerminal and a CloseProcessInput carry the same coordinate shape on the same lease.
- Every coordinate member is required by the generated `ProcessControlCommand` type.
- Acceptance commits a durable receipt keyed by that exact coordinate.

### `VAL-165` Retained receipt returned for an exact resubmission

- Sequence 12 on lease A is accepted, ordered, and receipted.
- The caller times out and resubmits sequence 12 with the identical canonical command.
- The retained receipt is returned and nothing is enqueued a second time.
- The same answer is returned even after the Process has terminated or the lease has expired.

### `VAL-166` One sequence, one canonical meaning

- Sequence 12 resubmitted with the exact retained canonical command recovers its receipt.
- Genuinely new content is submitted at sequence 13 and accepted on its own merits.
- A real digest mismatch returns the typed Process-control conflict carrying the original and submitted digests.
- No command is dispatched when that conflict result is returned.

### `VAL-167` Strictly next sequence per live lease

- The lease's last accepted sequence is 12.
- A genuinely new command is accepted only at sequence 13.
- A submission at sequence 15 returns the typed out-of-range result and is never ordered.
- Once 13 and 14 are accepted, 15 becomes acceptable in turn.

### `VAL-168` A new lease for each Process and runtime epoch

- A writer lease is issued bound to exactly one Process ID and one runtime epoch.
- After a runtime replacement the client acquires a new lease for the new epoch.
- An SDK Session rebinding acquires a new lease rather than retargeting the existing one.
- Commands bearing the stale lease are refused before they are ordered.

### `VAL-169` Receipt states ordering and delivery obligation only

- A stdin write receipt states that Core durably deduplicated, ordered, and owns delivery of the frame.
- It makes no claim that the process read the bytes.
- A terminal-resize receipt makes no claim that the application redrew or reacted.
- Callers observe the Process resource separately for evidence of application behaviour or liveness.

### `VAL-170` Resize on a live terminal-backed Process through the ordered stream

- The accepted Exec selected a terminal for the Process.
- The Process is nonterminal at the time the resize is submitted.
- The ResizeProcessTerminal travels the same ordered Process-control stream as input and close.
- Resizes submitted after the Process terminates are refused rather than ordered.

### `VAL-171` Close is final; further input requires a new Exec

- A CloseProcessInput commits an irreversible ordered close record at sequence 20.
- The Process observes EOF on stdin.
- Any later input write for that Process is refused before it is ordered.
- A caller needing further input starts a new Exec with its own control stream.

### `VAL-172` Every accepted command reaches one of four disjoint outcomes

- A delivered write terminalizes as delivered, citing its delivery evidence.
- A write still outstanding when the Process terminated is discarded with a never-delivered proof under the exact Process-terminal rule.
- A write whose delivery authority was quiesced fails with a never-delivered proof.
- A write with neither proof terminalizes `unknown` naming its missing proofs, and every receipt stays observable.

### `VAL-173` Teardown drains, seals, and resolves before completing

- Stop drains the retained output spool for each Process and seals it.
- Every accepted Process-control command is resolved with one of its four declared terminal outcomes.
- Receipts and sealed cursors remain readable through retained evidence after teardown.
- Only then does the teardown traversal complete.

### `VAL-174` Single live lease with explicit takeover

- Exactly one stdin writer lease is live for a Process at any moment.
- A second client takes the lease over explicitly, which ends the previous lease.
- Commands bearing the ended lease return the typed lease-conflict result.
- The surviving lease continues its sequence without a gap.

### `VAL-175` Portable Stop driver reaps, drains, then supplies evidence

- The Stop driver reaps each remaining Process and observes its backend exit.
- It drains every retained stream to its last byte across the target's transport.
- It supplies `driver.outputDrainEvidence` for each retained stream at the teardown station.
- The Core seals each stream only on that evidence, and withholds the seal otherwise.

### `VAL-176` Late reap evidence retained beside a committed outcome

- A Process commits `exited(0)` at the exec outcome station and the record becomes immutable.
- A reaper observation and a remote-provider event for the same Process arrive afterwards.
- Both are linked to the Process as retained evidence rather than applied as a write.
- Every later read of `process.status.termination` still returns `exited(0)`.

### `VAL-177` Nonterminal Process `unknown` beside a terminalized Operation

- An Exec dispatch returns inconclusive driver evidence for its launch.
- The Exec Operation terminalizes with the Operation-vocabulary `unknown` outcome naming its missing proofs.
- The Process stays in the Process-vocabulary `unknown` state and remains reconcilable against its own launch token.
- Neither value is treated as authorization to replay the command.

### `VAL-178` Terminate Operation succeeds while its target terminalizes on Process evidence

- A TerminateProcess Operation commits `succeeded` from its own dispatch and fencing proofs.
- The targeted Process record terminalizes only when Process-level termination evidence arrives.
- Both records name the same Process ID and runtime epoch.
- Reading the Process before that evidence still shows a nonterminal state.

### `VAL-179` Unresolved Process reconciled while a new command stays expressible

- An Exec dispatch loses its response and leaves the Process accepted with an unproven outcome.
- Core reconciles against the same durable launch token instead of dispatching a replacement.
- The caller may still submit a genuinely new Exec, which is accepted as its own Process with its own token.
- The unproven Process resolves only when evidence bearing its own launch token arrives.

### `VAL-180` Native wait status decoded to exactly its justified arm

- A bubblewrap wait status carrying exit code 3 decodes to the `exited` arm carrying 3.
- A supervisor execution record proving the command never became running decodes to `startFailed`.
- A lost control channel with no exit observation decodes to `runtimeLost`, never to an ordinary exit.
- Evidence that justifies no arm leaves the Process unproven rather than selecting a nearest arm.

### `VAL-181` Bare `runtimeLost` arm with native detail in the evidence record

- A driver loses its supervision channel and reports no exit status or signal.
- The Process terminalizes with the bare `runtimeLost` arm, which declares no payload field.
- The native transport error text is retained in the protected evidence record linked to the Process.
- Callers reading `process.status.termination` see the arm with no exit code or signal attached.

### `VAL-182` Every captured Process terminalized before `stopped` is published

- Stop captures the epoch's Process set, then reaps each Process for its outcome.
- Each remaining nonterminal Process is terminalized with its exact recorded reason.
- The driver's containment-absence proof is recorded at the same teardown station.
- Only then does `sandbox.status.runtime.state` publish `stopped`.

### `VAL-183` Reconciliation matched on launch token, execution identity, and epoch

- An unproven Process holds its durable launch token and its bound runtime reference.
- Driver evidence carrying the same backend execution identity in the same runtime epoch resolves it to `terminated`.
- Evidence from a replaced epoch is retained as evidence but does not resolve the Process.
- The committed resolution records which execution identity proved it.

### `VAL-184` Fenced successor handoff

- A successor advances the Sandbox authority epoch, so stale capabilities can no longer commit Core state.
- Processes of the prior epoch stay unproven while only the internal epoch has advanced.
- The driver returns target-side execution fencing or a verifiable drain boundary for each such Process.
- Each Process is then terminalized as `fenced`, citing that proof.

### `VAL-185` Demote on observer loss, restore only on fresh same-epoch evidence

- A Process is reported `running` from a live supervision channel with recorded observation freshness.
- The channel is lost and no other fresh observer for that Process exists.
- The Process is demoted to its reconcilable state and stops being reported as running.
- A reconnected same-epoch observer supplying fresh evidence restores `running`.

### `VAL-186` Replaced epoch drained before the new epoch publishes `running`

- A StartSandbox launch replaces an existing runtime epoch for the same Sandbox.
- Every nonterminal Process of the replaced epoch is terminalized as `runtimeReplaced`, `runtimeLost`, or `fenced`.
- Each reason is backed by the replacement's fencing or absence evidence.
- Only then is the new epoch published as `running`, leaving exactly one live lineage.

### `VAL-187` Suspend withholds launch authority and preserves continuity

- An Exec is accepted but its launch has not yet been externally dispatched.
- A SuspendSandbox operation withholds the launch-authority grant instead of terminalizing.
- The Process stays `accepted` with `process.launchAuthority` recorded as withheld.
- A successful same-epoch Resume regrants authority and the Process starts normally.

### `VAL-188` Full locked traversal including reconciliation

- A Process advances `accepted` to `starting` to `running` along locked edges.
- A lost observer moves it from `running` to the reconcilable `unknown`.
- Fresh same-epoch evidence moves it from `unknown` back to `running`, and later to `terminated`.
- No transition outside the locked edge set is constructible on the generated state machine.

### `VAL-189` Provider-specific detail carried as evidence beside a closed arm

- A remote provider returns its own vendor-specific termination code for a Process.
- The Process terminalizes with exactly one arm of the closed `ProcessTermination` union and that arm's declared payload.
- The vendor code is retained in the protected evidence record rather than in the outcome.
- No terminated Process is constructible with an absent, open, or provider-defined reason field.

### `VAL-190` `stoppedBySandbox` recorded only on proven causality

- A StopSandbox teardown obtains a target-side containment-absence proof from the driver.
- The Stop causality record links that deliberate teardown to each captured Process.
- Each such Process terminalizes as `stoppedBySandbox` citing both facts.
- A Process without such a proof stays unproven instead of taking the arm.

### `VAL-191` Wait deadline expires without touching its target

- A `WaitProcess` call with a five-second deadline expires while the Process is still `running`.
- The result returns the latest Process record with an explicit condition-met flag set false.
- `process.status.state` and `process.status.output.cursor` are byte-for-byte unchanged by the expiry.
- A second observation of the same Process sees exactly the same durable state.

### `VAL-192` Teardown-time late evidence linked, never applied

- A Process committed `exited(0)` before the Stop traversal began.
- A late signal acknowledgement and a provider event arrive during teardown.
- Both are linked to the Process through `driver.lateEvidence` as retained evidence.
- The committed terminal outcome and state are unchanged when teardown completes.

### `VAL-193` Signal chosen from the advertised closed set

- The Sandbox advertises a closed signal set for the resolved target, Process, and runtime epoch.
- A SignalProcess request selects exactly one member of that set.
- The request names the Process ID, Sandbox ID, and runtime epoch the set was advertised for.
- A caller needing an unsupported signal uses TerminateProcess or StopSandbox instead.

### `VAL-194` Resume before signalling, with Stop legal throughout

- A suspended Sandbox refuses a generic SignalProcess when the target advertises no suspended-delivery semantics.
- A Resume returns the Sandbox to running and the identical signal request is then admitted.
- StopSandbox remains admissible for the whole suspension.
- A target that does advertise deterministic delivery under suspension admits the generic signal directly.

### `VAL-195` Exact target-specific signal action with backend acceptance

- The bubblewrap driver signals the exact process in the sandbox PID namespace and records the kernel acceptance.
- The microVM driver invokes the guest agent's signal action rather than a VM power control.
- The remote-provider driver calls the provider's process-signal operation and retains its acceptance receipt.
- A target offering no such action leaves the Operation nonterminal instead of emulating one.

### `VAL-196` Dispatch success plus a separate Process observation

- A SignalProcess Operation commits `succeeded` against its dispatch postcondition alone.
- The declared success predicate names invocation and backend acceptance, never delivery or handling.
- The caller reads `process.status.state` separately to learn whether the Process exited.
- A Process that ignores the signal leaves the Operation successful and the Process running.

### `VAL-197` Coordinated dispatch identity where supported, at-least-once recorded otherwise

- A target that declares native dispatch-identity support receives a coordinated identity and the repeat is deduplicated by the backend.
- A target that declares no such support has the attempt durably recorded as possibly at-least-once.
- A retry re-reads the recorded attempt before repeating the native call.
- The caller can read `operation.effectAttempt` and see which guarantee actually applies.

### `VAL-198` Terminate succeeds on a proven terminal Process

- The driver completes the graceful stage and then the force stage of termination.
- The Process record holds an immutable terminal outcome together with its inability-to-act proof.
- Only then does the TerminateProcess Operation commit `succeeded`.
- A generic SignalProcess in the same Sandbox never silently acquires wait-for-exit semantics.

### `VAL-199` Three-part proof assembled before `succeeded`

- Sandbox ID, Process ID, runtime epoch, and authority are validated at admission.
- The exact target is selected and recorded on the Operation.
- The driver returns acceptance evidence for the target-specific dispatch.
- With all three present the Operation commits `succeeded`; with any missing it stays nonterminal or terminalizes `unknown` naming the missing proof.

### `VAL-200` Session identity kept adapter-local

- The adapter keeps a Session record holding its own conversation state plus a SandboxRuntimeRef it resolved from the Core.
- Every Core request it forms carries explicit Sandbox ID, runtime epoch, Operation ID, Process ID, etag, and idempotency key; none is replaced by or derived from the Session ID.
- The identical sequence of Core calls can be reproduced by a direct caller who never had a Session at all.

### `VAL-201` Explicit Session rebinding after a resume

- On resume the adapter first determines which of same-epoch attachment, proven same-epoch suspended Process continuity, or replacement from retained state holds.
- Attachment reattaches to the same epoch, proven continuity issues ResumeSandbox, and replacement issues CreateSandbox or RestoreSandbox and rebinds the Session to the new epoch explicitly.
- Every resulting Core request carries `expectedRuntimeEpoch`, so a stale handle is refused as a stale runtime rather than silently retargeted.

### `VAL-202` Core status union projected verbatim

- The adapter renders Sandbox and Process lifecycle state using the Core's closed status union exactly as returned in the Core response.
- An adapter-local label such as `connecting` is shown only alongside, and explicitly marked as, adapter-local presentation.
- Two different adapters over the same Sandbox display identical Core status values.

### `VAL-203` Original idempotency key reused for recovery

- After a transport failure the adapter resends the caller's byte-identical canonical request under its original idempotency key and receives the same logical result.
- A genuinely new intent derives a fresh key, and no key is ever reused across canonically different requests.
- The Core's stored key-to-digest-to-handle binding is unchanged by the recovery attempt.

### `VAL-204` Adapter documents only the Core concurrency contract

- The adapter's registered tools and client documentation state exactly the Core's published operation-pair compatibility and precondition contract, and nothing stronger.
- Ordering between concurrent mutations comes from etag and runtime-epoch preconditions carried on each Core request, not from an adapter-held lock.
- Two adapter instances racing on one Sandbox produce the Core's own conflict outcome, which the adapter surfaces unchanged.

### `VAL-205` Generated failure type over the closed Core union

- The adapter's caller-visible failure type is generated from the Core's closed public error, known-failure, and ambiguity union, projected into the host language.
- Adapter-specific context appears as non-semantic annotation on a generated variant, never as a new, merged, or renamed arm.
- Regenerating after a registry change adds exactly the registry's new variants and nothing else.

### `VAL-206` Transport condition reported as itself

- A client deadline on a live call is surfaced as a transport condition distinct from every Core result arm.
- The adapter then retrieves the Operation from the Core and reports its actual committed state.
- No Core Operation failure, proven Core cancellation, or Process outcome is synthesized from the transport event.

### `VAL-207` Exit codes surfaced as ordinary Process results

- A Process exiting with status 1 is returned as a normal Process result carrying the Core-published termination arm and exit code.
- Signal termination and deadline outcomes are surfaced as their own arms with the same fidelity.
- Adapter and infrastructure error types are reserved for adapter and transport conditions only.

### `VAL-208` Ambiguity resolved without a replacement effect

- When the Core returns an ambiguity arm for an Exec, the adapter surfaces that arm to the caller rather than re-running the command.
- Where recovery is wanted, the adapter resends the same canonical request under the original idempotency key or observes the Operation from the Core.
- No replacement effect is ever issued under a freshly minted coordinate.

### `VAL-209` Only Core-published proof is reported

- The adapter reports fencing, containment absence, and cleanup completion by quoting the Core Operation's published proof fields.
- Its own provider observations are displayed, if at all, explicitly labelled as non-authoritative.
- When the Core publishes no cleanup proof, the adapter reports the absence rather than inferring completion.

### `VAL-210` Composite surfaces every constituent Operation

- The adapter's `attach` helper issues the exact declared sequence of named Core operations and returns every constituent Operation handle.
- Its Stop-then-Delete helper does the same and is labelled an adapter helper rather than a Core verb.
- A partial failure leaves the caller holding the handles of the steps that ran plus a distinct result for the step that failed.

### `VAL-211` Precondition-guarded reconciliation

- The reconciler reaches the Core only through named Core operations, each carrying `expectedEtag` and `expectedRuntimeEpoch`.
- Its system-originated Operations are listed and observable through the same Operation surface as caller-originated ones, with origin recorded.
- A concurrent caller mutation causes the reconciler's next action to fail its precondition and re-plan rather than overwrite.

### `VAL-212` Desired state confined to the managed layer

- The Managed-Service Definition holds the desired-state revision and the restart/recreate policy in its own records.
- Core requests carry only Core fields: Artifact reference, target member, bindings, allocations, preconditions, and idempotency key.
- A revision bump causes the reconciler to issue ordinary named Core operations, and the Core stores no desired state and no restart policy of its own.

### `VAL-213` Correction appended as a linked successor Operation

- A reconciler that must undo a completed Stop appends a new Start Operation linked to the predecessor through `linkedOperationId`.
- The predecessor's committed terminal result stays byte-identical and stays readable for its full retention.
- The correction's own outcome is committed on the new Operation, so the audit chain shows both actions in order.

### `VAL-214` Sealed per-method creation rejection

- A creation naming an absent target member is rejected with exactly one variant drawn from the generated CreateSandbox subset of the sealed RequestError registry.
- The response carries no catch-all variant, no open reason string, no arbitrary metadata reason, and no provider-defined code.
- Adding a new condition requires extending the sealed registry and regenerating the method subset; the regenerated union still admits only registered variants.

### `VAL-215` Sealed per-method live rejection

- A port operation outside declared network authority is rejected with exactly one variant from that method's generated subset of the sealed registry.
- A Snapshot request against a missing capability and an Operation request against a stale etag each map to their own registered variants.
- No live method emits a catch-all variant, an open reason string, or a provider-defined code, whether reached directly or through an adapter.

### `VAL-216` Sealed Exec and Process-control rejection

- An Exec with empty argv and a Process-control call against an expired coordinate each return one variant of the generated Exec subset of the sealed registry.
- Process-control outcomes are drawn from the declared allowedProcessControlOutcomes set and never from an open reason string.
- The same conditions yield the same registered variants whether issued directly, through an adapter, or by a managed service.

### `VAL-217` Bounded creation rejection payload

- A creation rejected for an unbindable secret slot returns only the fields declared by that variant's payload schema.
- Protected context is reachable solely through a bounded opaque evidence identifier that carries no host path, provider payload, or credential value.
- The message contains no stack trace and no unredacted binding value, and the payload stays inside its declared size bound.

### `VAL-218` Bounded live rejection payload

- A live download naming a secret-slot destination is rejected with only the variant's declared fields plus a safe logical target reference.
- The payload discloses no secret content, no host backing path, and no raw provider payload.
- Operator-visible context is retrievable only through the opaque evidence identifier named in the response.

### `VAL-219` Bounded Exec rejection payload

- An Exec rejected for a capability outside the Sandbox bound returns only the variant's declared fields and the violated limit.
- Neither argv, the Process environment delta, nor native command output is echoed into the public payload.
- Any protected command context is reachable only through the bounded opaque evidence identifier.

### `VAL-220` Authorize-first creation admission

- The creation request is parsed only far enough to route and authenticate before authorization runs at the parent scope.
- An unauthorized caller naming an existing creation target and an authorized caller naming an absent one receive observationally equivalent public responses.
- Binding, target-selection, and allocation validation runs only after authorization succeeds, and its diagnostics never reach an unauthorized caller.

### `VAL-221` Authorize-first live admission

- A live request is authenticated and authorized at the operation and parent scope before any semantic validation of its body.
- `PermissionDenied` for an existing target and `TargetNotFound` for an absent one are observationally equivalent for an unauthorized caller: same variant, same payload, same timing class.
- An authorized caller still receives the precise distinguishing variant and its safe target reference.

### `VAL-222` Authorize-first Exec admission

- The Exec request is routed and authenticated, then authorized at the Sandbox and Process scope, before Process existence is resolved.
- An unauthorized caller naming a live Process and an authorized caller naming an absent Process receive the same public response.
- Only after authorization succeeds do argv, cwd, environment, and capability checks run and produce their diagnostics.

### `VAL-223` Registered creation recovery instruction

- Each creation rejection carries exactly one `CallerRecovery` registered for its emitted variant and consistent with that variant's semantic domain.
- A capacity rejection projects a wait-and-retry recovery whose `Retry-After` only times an action the recovery already permits.
- No creation response carries a boolean retryability flag, and no timing hint appears on a variant whose recovery forbids replay.

### `VAL-224` Registered live recovery instruction

- Each live rejection carries exactly one registered `CallerRecovery` consistent with its variant's semantic domain.
- A `RecoveryError` over a prior acceptance projects `ObserveHandle` or `OperatorAction` and never authorizes resubmission under a new key.
- A `Retry-After` hint appears only alongside a recovery that already permits the retry it times.

### `VAL-225` Registered Exec recovery instruction

- Each Exec or Process-control rejection carries exactly one registered `CallerRecovery` for its variant.
- An expired Process-control coordinate recovers by observation or operator action, never by a new sequence or a replacement execution.
- No Exec response pairs a wait hint with a recovery that forbids re-running the command.

### `VAL-226` Generated creation transport projection

- The HTTP and gRPC status for a creation response is looked up from the generated projection table keyed by the Core-authored variant.
- An accepted creation returns its durable Operation handle under a successful transport status even when the Operation's terminal outcome is `failed`.
- A transport-local failure between client and server produces no Core rejection variant and no Operation record.

### `VAL-227` Generated live transport projection

- Live responses derive their transport status from the Core-authored variant through the generated projection table, never the reverse.
- Retrieving an accepted Operation handle whose terminal outcome is `cancelled` is a successful observation returned under a successful transport status.
- Transport `UNKNOWN`, `CANCELLED`, `DEADLINE_EXCEEDED`, and `UNAVAILABLE` never appear as Operation outcomes.

### `VAL-228` Generated Exec transport projection

- An accepted Exec returns the durable Process record under a successful transport status regardless of the Process's embedded termination arm.
- A Process-control receipt is returned the same way, with its state embedded rather than projected onto the transport status.
- A closed connection or client deadline is reported as a transport condition and leaves the running Process and its durable record untouched.

### `VAL-229` Conservative mapping of an unrecognized native code

- A provider returns a status the driver's declared decoding version does not recognize.
- The driver maps it onto an already-registered conservative known-failure variant and records the exact native code only in the protected evidence record.
- The public union is unchanged: no variant is added, widened, parameterized, or passed through at runtime, and the response names only registered values.

### `VAL-230` Bounded, redacted provider evidence record

- A driver failure produces a large native payload containing host paths and a credential fragment.
- The protected evidence record stores the bounded, redacted payload and its digest, and the public response carries only the variant's declared fields plus the opaque evidence identifier.
- Operator retrieval of that identifier returns the redacted record, and the public response stays inside its declared size bound.

### `VAL-231` Restore into a stopped Sandbox from a matching Snapshot

- The Sandbox is stopped and carries a current durable stopped proof before RestoreSandbox is issued.
- The named Snapshot's manifest is complete and pins the same Artifact Set member, runtime profile, and immutable digests as the Sandbox.
- The restore is admitted, a new runtime epoch is allocated, and every prior epoch stays fenced.

### `VAL-232` Successor Process contract after restore or fork

- A Sandbox is captured with every Core Process terminal, then restored; the new epoch launches with no acting execution unit.
- Work resumes through a fresh Exec that allocates a durable Core Process carrying its own identity, provenance, deadline, termination-request handling, containment, stdin ownership, output cursors, and terminal-evidence contract.
- The post-launch probe finds every acting execution unit bound to a Core Process record in the new epoch before untrusted work is accepted.

### `VAL-233` Restored runtime acts only under its newly allocated epoch

- StartSandbox on a stopped Sandbox allocates an epoch above the monotonic high-water mark and grants mutation authority only to it.
- Same-Sandbox Restore and restore-as-create behave identically; no prior epoch regains the ability to mutate, exec, or terminate.
- Requests pinning `expectedRuntimeEpoch` equal to a superseded epoch are refused as stale rather than served.

### `VAL-234` Fork commits a sealed source and a distinct child

- The Fork acceptance commit durably seals the exact immutable source Sandbox ID and source runtime epoch before any capture or child-creation effect runs.
- The same commit publishes a newly preallocated child Sandbox ID whose epoch line begins at 1 under its own mutation authority.
- The child shares no Sandbox identity, Core Process identity, or authority coordinate with its source, and its complete Snapshot-equivalent provenance and ancestry are recorded in that commit.

### `VAL-235` Fenced migration handoff retains the source epoch

- The driver returns all six locked handoff proofs, and Core holds every one before deciding the epoch.
- Core commits a definite terminal outcome for the migration Operation and retains the source runtime epoch unchanged.
- A second relocation that cannot produce the source-fencing proof is represented as a cold relocation that allocates a new epoch instead.

### `VAL-236` Complete target-side handoff evidence

- The driver returns compatibility of source and destination, exclusive target-enforced authority transfer, a fenced or terminated source, uninterrupted Process authority, routing handoff, and explicit disposition of open attachments and external connections.
- Core reads all six proofs and only then retains the source runtime epoch.
- Where the target cannot enforce exclusive authority, the driver refuses the transfer and names the missing proof, and Core represents the relocation as one that allocates a new epoch.

### `VAL-237` Scoped teardown with independently retained records

- A successful DeleteSandbox removes the live Sandbox aggregate and only the live resources its own Operation covers.
- The Sandbox's Operation, Process, output, event, and evidence records stay readable afterwards until each record's own published retention contract expires.
- Snapshots already exported or mirrored into Core-controlled retention survive the deletion and remain resolvable by their own identities.

### `VAL-238` Delete issued after every dependent Snapshot is resolved

- Two Snapshots of the Sandbox are deleted and a third is mirrored into Core-controlled retention before DeleteSandbox is issued.
- Delete admission finds an empty dependency set and admits the request without entering the refusal path.
- The mirrored Snapshot stays readable after the Sandbox aggregate is gone, under its own retention contract.

### `VAL-239` Explicit absolute expiry paired with a named action

- One SetSandboxExpiration submits explicit `none`, and the Sandbox record afterwards carries no expiry schedule.
- A second call submits an absolute instant together with an explicit `stop` action; both members are present in the canonical request.
- No provider, target, or managed-service default fills either member, and the stored schedule reproduces exactly what the caller submitted.

### `VAL-240` Separately declared lifecycle and retention clock families

- The Artifact declares a maximum lifetime and an idle timeout under their own named clocks and subjects.
- SetSandboxExpiration sets only the absolute expiry instant and its action, leaving both Artifact ceilings untouched.
- Snapshot, Operation, Process, event, and output retention stay governed by their own published retention contracts and are unchanged by the call.

### `VAL-241` Named clock and subject for every Artifact time bound

- The Artifact declares maximum lifetime, idle timeout, maximum age from creation, maximum runtime duration, and record retention as five separately named bounds, each with its own clock and subject.
- A consuming profile narrows only the idle timeout and leaves the other four bounds intact and individually attributable.
- The canonical value carries all five under distinct field identities, and no single duration field stands in for another.

### `VAL-242` Operation retention observed, never deleted

- The closed public method surface over an Operation exposes get, list, and CancelOperation, and no delete, purge, or retention-override verb.
- After its target Sandbox is deleted, the Operation record stays readable until its published retention expires and then disappears on its own.
- A caller who wants nonterminal work stopped issues CancelOperation and observes the resulting terminal outcome on the same record.

### `VAL-243` Tombstoned deletion proof

- DeleteSandbox reports success only after the tombstone carrying the Sandbox ID, name, and audit coordinates is durably committed.
- Resolving the deleted Sandbox ID afterwards returns the tombstone rather than a reusable not-found.
- A later CreateSandbox proposing the same identity or an unreleased name is refused against that tombstone.

### `VAL-244` Expiry Stop elided against a proven stopped Sandbox

- A Sandbox with a `stop` expiration reaches its instant while a runtime is still extant; the trigger creates exactly one system-originated StopSandbox Operation with its origin recorded as system.
- A second Sandbox already carries a current durable stopped proof when its instant arrives, so no Stop Operation is created and the existing proof is linked instead.
- Neither Sandbox publishes a stopping projection it cannot substantiate, and the lifecycle lane is never seized for a no-op.

### `VAL-245` Every native expiry knob explicitly disabled or fenced

- The generated bubblewrap, Firecracker, and remote-provider configurations each emit explicit disabling values for native TTL, idle-sleep, auto-stop, and auto-delete.
- Where a target cannot disable a native timer, the generated configuration binds it to the Core durable expiry sequence and records the fence in the PreparedLaunch.
- Every runtime end therefore corresponds to a Core Operation, and the Sandbox's own expiration record remains the sole expiry authority.

### `VAL-246` DeleteSnapshot after references and holds are released

- The Snapshot carries no exact reference from any Sandbox, Operation, or ancestry record and no retention hold.
- DeleteSnapshot is admitted, the bytes are released, and the identity is tombstoned rather than freed for reuse.
- A sibling Snapshot that still carries a retention hold is refused, and the refusal names the exact protecting references.

### `VAL-247` Freshly allocated Snapshot identity with retained tombstone

- Two successive captures of the same Sandbox each receive a distinct Snapshot ID, and neither reuses an identity issued earlier.
- Deleting the first Snapshot releases its stored bytes but retains a tombstone that keeps its ID permanently unallocatable.
- A later capture succeeds under a new ID, and resolving the deleted ID returns its tombstone rather than the new Snapshot.

### `VAL-248` Explicit resolved Snapshot class and source disposition

- CreateSnapshot names one exact content-addressed Snapshot class identity together with its complete resolved class definition.
- The request states `sourceAfterCapture = runtimeStatePreserved` explicitly, with no provider-, target-, or service-selected default.
- A named SDK authoring profile may pick the class for convenience, and the canonical request still carries the exact resolved identity and definition it selected.

### `VAL-249` Runtime class chosen wherever continuity is required

- A capture that must preserve memory, open descriptors, and clock continuity names a runtime Snapshot class whose component set includes them.
- A separate capture that needs only file contents names a filesystem class and requests no continuity-dependent restore behaviour.
- Restore from the filesystem Snapshot starts a fresh runtime epoch with newly allocated Processes, and the request says so explicitly.

### `VAL-250` Complete runtime Snapshot terminalization

- A runtime-class capture terminalizes as succeeded only after durability evidence exists for every component the class marks required, including memory, device, and clock state.
- Compatibility metadata for the source Artifact member and runtime profile is committed with the manifest.
- The committed manifest's component set equals the class's declared required set, and the Snapshot is readable immediately afterwards.

### `VAL-251` Quiesced source before capture or Fork

- Every Core Process bound to the source Sandbox's current runtime epoch has reached a terminal state before CreateSnapshot is issued.
- The resolved class declares `coreProcessHandling = rejectNonterminal`, and admission finds no nonterminal Process bound to that epoch.
- A ForkSandbox against the same quiesced source is admitted under the identical rule and produces a child whose epoch line begins at 1.

### `VAL-252` Preserved source returned to its original epoch

- A capture declaring `runtimeStatePreserved` briefly quiesces the source and restores full runtime authority afterwards.
- The source finishes in its original runtime state under the same runtime epoch it held before the capture, with no new epoch allocated.
- Attachment and external-connection disruption caused by the quiescence is recorded as separate evidence rather than folded into the runtime state.

### `VAL-253` Snapshot inherits the source runtime's pinned identity

- The capture request carries no Artifact, member, profile, or digest field of its own.
- The committed manifest names the exact Artifact Set member, runtime-profile identity, and relevant immutable manifest digests already resolved for the source runtime.
- A later restore matches on those committed identities; using a different Artifact requires constructing a new Sandbox instead.

### `VAL-254` `stopped` published on the full Stop postcondition

- A capture declaring `sourceAfterCapture = stopped` publishes that disposition only after every Core Process in the source epoch is terminal.
- The driver's containment-absence proof for the source is held by Core before publication.
- The prior epoch is fenced and can no longer mutate, exec, or terminate, and the Sandbox's runtime state reads `stopped` with a current durable proof.

### `VAL-255` Self-consistent Snapshot class identity

- The named class identity resolves to a definition whose kind, captured component set, external-storage state, secret treatment, compatibility envelope, quiescence state, device state, portability, and Process handling all agree with what the request describes.
- Capture admission recomputes the class identity from the resolved definition and finds it identical to the one submitted.
- A second class in the same Artifact differs in kind and carries its own distinct content-addressed identity.

### `VAL-257` Signal and terminate against a proven live epoch

- A SignalProcess request names a Process whose Sandbox holds a proven running runtime state and a live runtime epoch, and is admitted.
- The same request against a stopped Sandbox is refused at admission with `SIG-008`, and the caller is directed to the retained Operation record rather than told the Process is gone.
- A Sandbox whose runtime state cannot be proven is refused with the same rule and a distinct remediation; it is never resolved to `stopped` in order to answer.

### `VAL-256` Per-component capture durability evidence

- For every component the resolved class marks required, the driver returns durability evidence together with that component's compatibility metadata.
- Core commits the Snapshot manifest only once all of it is present, and the Snapshot becomes readable immediately afterwards.
- When the target cannot durably flush one required component, the driver reports failure naming that exact component and no Snapshot is committed.

## Composition Authority Matrix

The prototypes must explicitly implement this matrix. Language-native operators
do not redefine it.

| Input kind | May supply default | May select | May narrow/refine | May replace | May widen hard policy |
|---|---:|---:|---:|---:|---:|
| Product library/profile | yes | no | yes | only fields declared replaceable defaults | no |
| Artifact author module | yes | yes | yes | only replaceable defaults | no |
| Target-native Artifact extension | no portable defaults | target-local only | target implementation only | target-local only | no |
| `CreateSandbox` | no Artifact defaults | permitted alternatives/profile | allocations/access only | concrete binding values | no |
| Operator Configuration | infrastructure defaults | driver/provider/placement | global constraints | operator-owned values | no |
| Framework adapter | invocation defaults | API operation/tool route | no Artifact policy | framework-owned lifecycle only | no |
| Managed service | request defaults | API operation | request within bounds | service-owned scheduling metadata | no |

The final validator checks the resulting authority relationship even when the
source language offers more powerful primitives.

## Candidate Harness Rules

Every candidate harness must:

1. pin the evaluator/compiler and standard/product libraries with Nix;
2. run in pure/offline mode after dependencies are prepared;
3. deny ambient environment variables except a documented allowlist;
4. deep-force the entire Artifact value;
5. prohibit source-language-specific values at the canonical boundary;
6. use the same product canonicalizer and semantic validator;
7. run all Artifact-only cases without `CreateSandbox`/operator/host inputs;
8. run non-Artifact cases through the shared harness rather than adding those
   values to the Artifact language;
9. preserve exact native diagnostics before mapping them to the product
   diagnostic structure;
10. build the same trivial real-Nix output for valid cases;
11. exercise the candidate's strongest ordinary and escape-hatch composition
    mechanisms;
12. execute every case twice with relevant import order reversed;
13. execute valid cases cold, warm, online-preparation, and offline;
14. record all rule implementations to detect semantic duplication.

## Pass, Fail, and Promotion Rules

A candidate **passes a case** only when:

- a valid case produces the expected canonical semantic value; or
- an invalid case is rejected no later than its deadline;
- the owner is correct;
- no forbidden input was pulled into an earlier owner;
- the diagnostic satisfies the required semantic fields;
- a corrupted value is also rejected at the downstream trust boundary.

A candidate **fails a case** when it:

- accepts an invalid value past the deadline;
- silently drops, widens, reinterprets, or falls back;
- rejects because it cannot represent a required valid case;
- blames the wrong owner or requires unavailable future information;
- exposes secret material;
- emits source-language-specific values to Nix construction or drivers;
- requires a separately maintained copy of the same semantic rule.

A source-level watch-list candidate is promoted to a complete slice only when it
passes the focused control and demonstrates a distinct advantage not already
covered by the serious set.

Passing all implemented cases does not close enforcement. Before blind review
or scoring, Gate 4B requires exact registry coverage and concrete traceability
from every in-scope invariant to its authoritative hook, defensive
trust-boundary checks, applicable target/bypass tests, and executable diagnostic
assertions.

## Corpus Lock

The following are locked for the comparison:

- owners and their information boundaries;
- product phases;
- invalid/valid case semantics;
- first-sound phase and rejection deadline;
- structured diagnostic requirements;
- canonical-output oracle;
- composition authority matrix;
- harness evidence and pass/fail rules.

Fixture spelling, internal test helper names, and candidate source syntax remain
implementation details. Changes to case semantics require updating this corpus
before rerunning candidates; they may not be made after seeing a preferred
candidate's score merely to accommodate it.

Adding or removing an invariant identifier must update
[`invariants/invariants.json`](./invariants/invariants.json) in the same change.
Inventory-mode validation requires the two identifier sets to match exactly.
