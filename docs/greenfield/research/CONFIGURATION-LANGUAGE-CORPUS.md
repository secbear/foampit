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
