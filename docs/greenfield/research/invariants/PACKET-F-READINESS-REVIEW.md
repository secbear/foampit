# Packet F Readiness Assessment

**Repository:** `/Users/bear/dev/foampit` · **Branch:** `main` @ `c6aded3` · **Assessed:** 2026-08-03
**Gate state at assessment time:** `check-inventory.sh` → `EXIT=0`, prints `Gate 2A remains open for Packets E-F`. `check-model-coherence.sh` → 34 checks passed, 0 failed. `check-enforcement-closure.sh` → exit 5 (correct; Gate 4B not closed).

**Filed 2026-08-03** on `packet-e-inventory-walk`. The assessment was taken
before Stage 0 began. Items **0a**, **0d**, **0e**, and **0f** have since been
executed in this branch and their findings below are marked accordingly in §8;
only **0g** remains open. The §1 verdict and the §2
coverage map are unaffected — nothing in Stage 0 locks a decision.

---

## 1. Verdict

**Packet F cannot proceed to an inventory walk. It needs a design phase — and that design phase itself has an unmet precondition.**

The work is three-stage, not two:

> **Stage 0 — scope reconciliation and defect repair** (small, mandatory, blocking)
> **Stage 1 — a Packet F design phase, four or five locked records** (large)
> **Stage 2 — the exhaustive inventory walk** (largest, but mechanical once Stage 1 lands)

This is decisive, and it follows from four verified facts rather than from a judgement call.

**First, there is nothing to operationalize.** `INVARIANT-ENFORCEMENT.md:152-156` states the ordering directly: *"Locked architectural decisions necessarily precede the exhaustive invariant walk that operationalizes them,"* and an obligation recorded by a decision *"does not satisfy Gate 2A, and cannot authorize implementation."* Packets A–E each walked a lock. `DESIGN.md` carries exactly nine `Locked:` headings (lines 24, 232, 316, 390, 499, 636, 982, 1146, 1195) — verified by `grep -n '^#\{2,3\} .*Locked'` — and **none is about security, disclosure, or evidence**. `find . -iname '*packet-f*'` returns nothing: no design record, no plan, no ledger, no review. Packet E's walk partitioned 178 numbered obligations drawn from four locked records; Packet F has an obligation universe of size zero.

**Second, the deepest gap is a decision gap, not a registration gap — and the repository says so in four places.** All four locked Packet E records list the dynamic reservation / TOCTOU protocol under an explicit *"does not yet lock"* heading (`PACKET-E-OPERATION-IDENTITY-DESIGN.md:666`, `PACKET-E-LIFECYCLE-STATE-DESIGN.md:932`, `PACKET-E-OPERATION-TAXONOMY-DESIGN.md:1085`, `PACKET-E-RESULT-ERROR-CONTRACT-DESIGN.md:1546`). A walk cannot register what four locked records agree is unlocked.

**Third, the emptiness is measurable.** Searching all of `id + title + statement + rationale + notes + diagnostic paths + remediation` across 354 invariants:

| Term | Hits | Term | Hits |
|---|---:|---|---:|
| `toctou` / `time-of-check` | **0** | `acquisit` | **0** |
| `side.channel` | **0** | `telemetr` | **0** |
| `tenan` | **0** | `imds` / `169.254` | **0** |
| `disclos` | **3** (ERR-007/008/009 only) | `reservation` | **2** (neither about host resources) |

`[.invariants[].notes]` attributes 24 to Packet A, 45 to B, 9 to C, 17 to D, 214 to E, 45 to the seeded corpus — **0 to Packet F**. The 31 distinct `trustBoundaries` values contain no disclosure channel, no evidence sink, and no guest-to-host boundary, despite `INVARIANT-ENFORCEMENT.md:127` naming *evidence ingestion* as a required boundary to walk.

**Fourth — and this is the "something between" qualifier — a large fraction of F's nominal scope is already settled.** 74 of 354 invariants match `secret|redact|disclos|provenance|evidence` in id/title/statement; broadening to sockets, protected paths, ambient, inherited, credential, host path, metadata reaches 115. Packet D's 54 composition paths *all* carry `delegatedPackets` containing `"F"`. So the design phase is not open-field invention across the whole scope: it is invention in four concentrated places, plus a careful partition against work Packets A–E already did. A design record that ignored the 115 would re-decide settled architecture; a walk that ignored them would double-register.

**Net:** the design phase is unavoidable, but it is narrower in *coverage* than Packet E's and harder in *kind*. Packet E's four records refined a locked model. Packet F's must invent one, and simultaneously partition against five other packets' registered output.

---

## 2. Coverage map

Legend: **[R]** already registered · **[L]** locked but unregistered (walkable now, no new decision) · **[N]** needs a new decision.

### 2.1 Secrets

| Sub-topic | State | Evidence |
|---|---|---|
| Secret-slot structure, delivery alternatives, destination conflict, secret/snapshot agreement | **[R]** | `SCT-001/002/003` (artifact, A0→A1, `invariants.json:10543/10648/10758`), `STR-004` (P1→W0, `:308`), `MAN-003` (N1→C0, `:5011`), `XRS-004` (C0→D0), `XRS-006` (C0→O0), `CMP-005` (A1→N0), `SNP-001`, `OUT-002`, `POL-004`, `HOST-003`. Locked at `DESIGN.md:50-53`, `:186`, `:455-456`. |
| Runtime delivery channel and forbidden sinks | **[L]** | `TARGET-IMPLEMENTATION-STRATEGY.md:389-391` — *"authenticated guest-runtime/vsock delivery into ephemeral guest surfaces and never enter images, the Nix store, MMDS, OEM strings, or VMM configuration."* Closed forbidden-sink list, exact phase. `MMDS`/`OEM` appear nowhere in the registry. |
| Secrets in **success** payloads, output streams, retained records | **[N]** | Only 7 of 28 secret-mentioning invariants are post-launch, and `ERR-005`/`ERR-006` bound **rejection** payloads only. `EXE-003` (E0) / `LIVE-003` (L0) are request validation. `RET-001` guarantees retained records stay readable with no content rule. |
| Secret lifetime, rotation, revocation, zeroization | **[N]** | `rotat|revoke|zeroiz|wipe|shred` → no secret-scoped hit anywhere in the registry. |

### 2.2 Ambient environment, inherited descriptors, process inheritance

| Sub-topic | State | Evidence |
|---|---|---|
| Declaration side — what an Artifact may inherit or default from | **[R]** | `XRS-012` (A0→A1, `:7995`) is canonical: *"build, caller, daemon, or host environment never supplies defaults."* Plus `SEC-001`, `IDN-001`, `XRS-009/011/014`, `PLT-001`, `MAN-004`. All pre-launch. |
| Observed exclusion after launch | **[N]** | Only `EXE-002`/`EXE-003` are post-launch and both are E0 request validation. `PACKET-C-TARGET-REALIZATION-REVIEW.md:381` delegates `artifact.environment.ambientExclusion` to F; that exact path appears in **zero** registry diagnostics. |
| Process-tree inheritance from the supervisor | **[N]** | Required by the dimension row `INVENTORY-REVIEW.md:98`; **absent from F's own nine-bullet walk list at `:368-379`**. Scope-statement defect. |

### 2.3 Host sockets, host channels, metadata endpoints

| Sub-topic | State | Evidence |
|---|---|---|
| Typed host-channel contracts | **[R]** | `NET-002` (A0→A1, `:9683`): Unix sockets, vsock, D-Bus, Wayland, PipeWire, brokers, **inherited descriptors** — individually typed, undeclared channels forbidden. `XRS-008` places driver sockets in Operator Configuration. `DEV-002` projects device→channel effects. |
| Observed channel absence at runtime | **[N]** | No invariant observes that only declared channels exist post-launch. |
| Supervisor / VMM process's own sockets and privileges | **[N]** | `jail|supervis|VMM process|daemon` matches only `XRS-012` and `FEN-006`. The daemon listener is uncovered. |
| Metadata endpoints / IMDS | **[N]** | `metadata endpoint`, `imds`, `169.254`, `link-local` → **0** hits. Named as required at `INVENTORY-REVIEW.md:98`. Mostly follows from `NET-001` under `access = none`; the carve-out (host-side IMDS reachable by the supervisor, not by the guest) does not. |

### 2.4 Protected paths and control-only content

| Sub-topic | State | Evidence |
|---|---|---|
| Static topology, normalization, shadowing | **[R]** | `XRS-020` (A0→A1, `:9465`), `XRS-019` (A0→A1, `:8940`), `SCT-002`, `OUT-002`. Live half: `LIVE-003` (L0→L0, `:6195`). |
| Runtime enforcement / post-start probe | **[L]** | `TARGET-IMPLEMENTATION-STRATEGY.md:628-634` locks the probe ("forbidden paths cannot be read or written"). Packet C's delegated paths `artifact.filesystem.topology` and `artifact.requirements.enforcement` return **NONE** against every registry diagnostic. |

### 2.5 Diagnostics, logs, trajectories, evidence sinks — **the largest hole**

| Sub-topic | State | Evidence |
|---|---|---|
| Rejection-payload redaction | **[R]** | `ERR-004` (C0), `ERR-005` (L0), `ERR-006` (E0) close the payload against stack trace, secret, host path, raw provider payload, unbounded native metadata, protected-resource existence, unredacted command environment. Locked at `PACKET-E-RESULT-ERROR-CONTRACT-DESIGN.md:690-699`. |
| Bounded/redacted/protected provider evidence | **[R]** | `ERR-016`/`ERR-017` (runtime, D0→D0, `:34285`/`:34393`); `IDE-016` (D0); `OPA-012` (L0). Locked at `DESIGN.md:579-581`. |
| Existence disclosure behind authorization | **[R]** | `ERR-007`/`008`/`009`, each requiring observationally equivalent public responses. |
| **Log, telemetry, trajectory, provenance-ledger, evidence-sink disclosure** | **[N]** | `logging` → 0. `telemetr` → 0. `trajector` → 1 (`XRS-007`, only to assign ownership to adapters). `audit` → 1 (`RET-007`, tombstone coordinates). `disclos` → 3, all ERR. The rule was *planned* at `plans/2026-07-31-packet-e-runtime-lifecycle-inventory-walk.md:209-210` — *"Packet F owns the disclosure-channel rule: what may appear in logs, diagnostics, trajectories, provenance, and evidence sinks"* — as an **unchecked `- [ ]` step**, and `rg 'disclosure-channel'` finds it in that plan and nowhere else. |
| `diagnostic.secretSafe` semantics | **[N]** | All 354 entries declare `secretSafe: true` (verified: `group_by` → one bucket of 354). `validate-registry.jq:360-362` only asserts *"must be boolean."* 354 secret-safety claims enforced by nothing. |
| `public disclosure class` domain | **[N]** | `PACKET-E-RESULT-ERROR-CONTRACT-DESIGN.md:684` requires every variant to own one but never enumerates the values; `:1414` lists "disclosure and redaction fixtures" with no fixture contract. A locked *slot* with an undecided *domain*. |
| `sandbox explain` output | **[N]** | `DESIGN.md:1240-1241` locks that explain displays every field and its origin. No invariant covers explain output; the surface appears once repo-wide with no owner. May a losing contributor carry a secret-bearing or host-bound value into it? Undecided. |

### 2.6 Identity vs. explanation records

| Sub-topic | State | Evidence |
|---|---|---|
| What the semantic digest excludes | **[R]** | `IDT-001` (artifact, W0→W0, `:11394`) — excludes selector explicitness, source spans, formatting, checkout path, timestamps, field-level explanation provenance. `IDT-002` (N1→C0), `CMP-010` (A1→W0, `:13047`), `PRV-001` (H0). |
| The explanation record's own contract — retention, read scope, secret content | **[N]** | `explanation record` and `non-hashed` → **NONE**. `artifact.provenance.requirements` and `artifact.provenance.builtIdentities` (delegated at `PACKET-C-TARGET-REALIZATION-REVIEW.md:384-386`) return NONE against every diagnostic path. |

### 2.7 Claimed vs. measured

| Sub-topic | State | Evidence |
|---|---|---|
| **Conformance** — the best-covered F topic | **[R]** | `TGT-003` (N1→C0, `:2351`), `PRV-002` (N0→N1), `HOST-004` (H0→H0), `CMP-006/011`, `ADM-013/014/015` (D0), `FEN-006`, `LIVE-002`, `EXE-006`, `FWK-002`/`ADP-010`. Plus the entire **35-member `observed-conformance` disposition set** (verified: `observed-conformance` = 35). |
| **Isolation** | **[N]** | No `sandbox.security.*` or `runtime.security.*` diagnostic path exists. `artifact.security.*` appears only at A0→A1 (`SEC-001`, `SEC-002`, `DEV-001`, `DEV-002`, `XRS-013`). `SBX-014`/`SBX-015` (R1) prove the *driver's declared probes*, not that seccomp/LSM/Landlock/capability/network policy is in force. `SBX-019` (T0) proves containment **absence** at teardown, never **presence** at launch. **Not one of the 35 `observed-conformance` entries proves an isolation property.** |
| The declared / lowered / observed / runtime fact taxonomy | **[L]** | `DESIGN.md:1116-1117` and `TARGET-IMPLEMENTATION-STRATEGY.md:636-637` both decide it. No invariant requires an evidence record to carry the classification. |
| Escape-hatch effective-configuration evidence | **[L]** | `DESIGN.md:1135-1137` requires it recorded; `effective.configuration` → 0 registry hits. |

### 2.8 Widened scope (2026-08-03)

| Sub-topic | State | Evidence |
|---|---|---|
| Host acquisition and reservation | **[N]** | `acquisit` → 0. `reservation` → 2, and neither is about host resources (`IDE-003` is Sandbox *name* reservation; `SBX-010` says a stopped resize claims *no* capacity). Locked material is one sentence — `DESIGN.md:1114-1115` — plus a nine-item inventory at `TARGET-IMPLEMENTATION-STRATEGY.md:603-616` naming ports, TAP names, CIDs, socket paths, instance IDs. `\bCID\b`, `\bTAP\b`, `exhaust` → 0 hits each. **No reservation protocol, no evidence-for-reservation rule, no reservation-leak rule.** |
| Time-of-check / time-of-use | **[N]** | `HOST-005` (H0→D0, `:12488`) is the only genuine instance, covers filesystem sources alone, and was *discovered* by Packet C rather than designed. `HOST-001/002/003/004` are `dynamic-preflight` facts decided at H0 with **no stated re-check obligation at their use point**. |
| Rollback claims vs. what a target performed | **[R]** for representation, **[N]** for evidence | `PRF-006` (T0→T0, `:20634`) and `PRF-012` (R1→R1, `:21258`) both lock compensation-is-not-rollback; `Rollback` is a rejected v1 verb (`DESIGN.md:487`); `ADP-010` forbids adapters asserting fencing or cleanup proof. Open: what evidence a driver must produce before Core records that an external actor undid an effect. Also, `compensat` matches only `PRF-006`/`PRF-010`/`PRF-012` — **the L1 live-mutation traversal has no counterpart** to the launch-branch and teardown-branch rules. |

### 2.9 Scope items F's own walk list omits

| Sub-topic | State | Evidence |
|---|---|---|
| Authentication, tenancy, authorization scope | **[N]** | `tenan` → 0. `authentic` → **6**: `OPA-010`, `OPA-011`, `OPA-023` presuppose *"one authenticated scope"*; `ERR-007/008/009` presuppose *"authorization at a disclosure-safe scope."* **Six registered invariants depend on a scope model that is defined nowhere.** `PACKET-A-RESOURCE-OPERATION-REVIEW.md:184-185` delegates authentication and tenancy to F; `INVENTORY-REVIEW.md:370-379` omits both. |
| Side channels | **[N]** | `side.channel` → 0 in the registry, 0 in `DESIGN.md`, 0 in `TARGET-IMPLEMENTATION-STRATEGY.md`. Named at `INVARIANT-ENFORCEMENT.md:134-136`, `INVENTORY-REVIEW.md:98`, `PACKET-D-COMPOSITION-REVIEW.md:266`; **absent from F's walk list.** |

### 2.10 Documents that are *not* locked authority

`CONFIGURATION-BOUNDARY-AUDIT.md:3` — *"Status: Research synthesis — not locked."* `OPTION-SURFACE-RESEARCH.md:3` — *"recommendations are not locked."* This matters because the strongest disclosure prose in the repository lives only there: `OPTION-SURFACE-RESEARCH.md:439` and `:743-745`, `CONFIGURATION-BOUNDARY-AUDIT.md:530` and `:1045`. They are **input to a Packet F decision, never a locked premise a walk may operationalize.**

---

## 3. What a Packet F design record would have to decide

Five genuine architectural decisions. Everything in §3.6 is a detail that follows once these are set.

### 3.1 The frame: disclosure is egress, the registry models ingress — **decide first**

`INVARIANT-ENFORCEMENT.md:339-378` defines `firstSoundPhase`/`rejectionDeadline` as a *decidability* relation over one traversal, and all four dispositions (`validate-registry.jq:64-71`) describe **refusing an input**. A disclosure rule does not reject; it filters an output. Packet E dodged this for API responses by phrasing `ERR-004`–`ERR-006` as *"payload outside its closed schema"* → `reject-at-boundary` at C0/L0/E0 — which works only because a response shares its request's phase. **A log line, an audit record, and an evidence sink have no request phase.** Every other F rule inherits whatever is decided here.

| Alternative | Cost |
|---|---|
| **(i) Generalize the ERR-\* trick** — each disclosure rule becomes rejection of a malformed *record* at its constructor's phase | No schema change, no new boundary. But the sink is never modeled, and a writer that bypasses the constructor is invisible to the model. |
| **(ii) Add a `disclosureSinks` field** parallel to `trustBoundaries` | Schema change touching all 354 entries, every validator, and the `CONTRIBUTING.md:45-53` lockstep table. |
| **(iii) Mint a closed sink universe + a Packet-D-style sinks × invariants matrix** | Matches precedent, buys machine totality, costs a second 19,116-scale artifact. |
| **(iv) Make it all `observed-conformance` with runtime probes** | Contradicts the "earliest sound boundary" principle. |

### 3.2 The classification and audience lattice

Nothing defines "secret" machine-readably, and no audience set exists. `SCT-001` requires each delivery alternative to name an **audience**; `PACKET-B-ARTIFACT-FIELDS.json:1562-1585` forbids *"model-visible audience data when classified"* — and the audience vocabulary is enumerated nowhere. `PACKET-A-SURFACE-COVERAGE.json:1041` assigns *"audience, redaction, retention, and model-visibility rules"* to F.

Alternatives: a flat secret/non-secret bit · an ordered lattice (`public → caller → operator → protected-evidence`) · an orthogonal `class × audience` product.

**Whether the in-sandbox agent is a distinct audience is a first-class product decision, not a detail** — it is what distinguishes this product from a generic sandbox API. Everything in §3.1's matrix references this lattice, so it should be locked in the same record or the one immediately before.

### 3.3 Host acquisition and reservation

Must sit **after** step 5 (idempotency) and at or after step 10 (quota/rate/capacity) in the admission order at `PACKET-E-RESULT-ERROR-CONTRACT-DESIGN.md:388-404`, and must fit the six-step External-Effect Protocol at `PACKET-E-LIFECYCLE-STATE-DESIGN.md:658-683`.

| Alternative | Consequence |
|---|---|
| **(i) Core-durable reservation** committed with the Operation before dispatch | Fits the External-Effect Protocol and `OPA-005`. But `ADM-016` forbids the Artifact asserting capacity and `ADM-018` requires the operator plane to re-admit per epoch — Core would be modelling host capacity it does not own. |
| **(ii) Non-durable host/driver lease**, reacquired on reentry | The current *implicit* position (`PACKET-D-RESOURCE-COMPOSITION-DRIVER-BOUNDARY-DESIGN.md:189-191`: H0 handles are non-serializable, reentry reacquires). But a crash between H0 and R0 leaks a reservation with no durable record, and Packet E's `cleanup` has no reservation semantics. |
| **(iii) Optimistic acquisition, fail at launch** | Contradicts `DESIGN.md:1114`. |
| **(iv) Provider-delegated quota** | Contradicts `SBX-010` and the whole "provider claim is evidence, not authority" posture. |

These are not equivalent — the choice is directly visible in crash behaviour.

### 3.4 The TOCTOU protocol

| Alternative | Where it fails |
|---|---|
| **(i) Universal handle-retention** — generalize `HOST-005`; every checked host fact becomes a retained kernel object the use site consumes (the bubblewrap `--ro-bind-fd` model, `PACKET-C-BUBBLEWRAP-RESEARCH.md:108,185,217`) | Impossible for capacity. |
| **(ii) Freshness witness re-checked at use** — reuses Packet E's freshness-precondition vocabulary | Unsound for filesystem paths. |
| **(iii) Fence at check time** — Packet E's `FEN-*` model | Impossible for host-global facts (KVM presence). |
| **(iv) Closed accepted-TOCTOU list**, disclosed as an unproven claim | Honest but must be bounded. |

None generalizes. **The ruling is necessarily a partition** of the nine item classes at `TARGET-IMPLEMENTATION-STRATEGY.md:606-616` across all four. `HOST-005` is the template; `ADM-018` (O0→D0) and `SBX-022` are the re-resolution precedents.

### 3.5 Authorization, authentication, tenancy

Six registered invariants presuppose a scope taxonomy that does not exist (§2.9). `DESIGN.md:194` provides one clause: *"Operator Configuration owns daemon listeners and authentication."* Whether a scope is per-Sandbox, per-tenant, per-Artifact, or capability-token-based is a real decision. **F must either define principals/scopes/tenancy or explicitly rule it out of v1 — leaving it unnamed makes `OPA-010`, `OPA-011`, `OPA-023`, `ERR-007`, `ERR-008`, `ERR-009` undecidable, untestable, and unimplementable.**

### 3.6 Details that follow, not decisions

Redaction spelling (omit vs. replace vs. digest) · retention *durations* once the contract shape is fixed · per-profile probe selection (Packet C's 324-cell machinery already exists) · metadata-endpoint blocking (mostly follows from `NET-001`/`NET-002` under `access = none`) · the meaning of `secretSafe` (follows from §3.2) · `sandbox explain` output rules (follows from §3.1 + §3.2).

### 3.7 Two structural rulings F must make up front, as Packet E did

Packet E recorded both explicitly (`PACKET-E-OPERATION-CONTRACT-REVIEW.md:31-41`): a ninth owner `core`, and *"no phase or edge added."* F owes the equivalents:

- **New trust boundary?** `INVARIANT-ENFORCEMENT.md:127` names *evidence ingestion* as a required boundary; it is absent from the 31 in use. `INVARIANT-ENFORCEMENT.md:141-143` makes adding one an explicit reopening event. Until this is ruled, **no invariant in §2.2, §2.3, §2.5, or §2.7 can be given a sound phase pair.**
- **New owner?** F's 16 delegated Packet A surfaces span operator, service, live, exec, and framework owners. A tenth owner is defensible only under Packet E's own test: *would an existing owner be made to mean two things at two phases?*

---

## 4. What Packet F must **not** decide

Re-deciding any of these violates `INVARIANT-ENFORCEMENT.md:152-156`; re-registering them corrupts the identifier space and the Packet D matrix.

| Settled fact | Authority | F's residual, if any |
|---|---|---|
| Artifacts never contain secret values or references | `DESIGN.md:50-53`; `STR-004`, `MAN-003`, `XRS-004`, `XRS-006`, `SCT-001/002/003`, `EXE-003`, `LIVE-003` | Runtime half only |
| Ambient/build/caller/daemon/host environment never supplies defaults | `XRS-012` (+ `XRS-011`, `XRS-014`) | Observed absence only |
| Host channels are individually typed; undeclared channels forbidden | `NET-002` | Observed absence only |
| Protected/masked subpaths normalize, cannot be shadowed or widened | `XRS-019`, `XRS-020`, `LIVE-003` | Post-start probe only |
| Rejection payloads are closed against 7 named leak classes | `ERR-004/005/006` | **Nothing — do not author a second payload rule** |
| Raw provider payloads stay in the protected evidence record; only a bounded opaque id escapes | `ERR-016`, `ERR-017`; `PACKET-E-RESULT-ERROR-CONTRACT-DESIGN.md:674-702` | Channel side only |
| Existence disclosure is ordered behind authorization | `ERR-007/008/009`; `DESIGN.md:572` | **Nothing** |
| The semantic digest excludes spans, formatting, timestamps, explanation provenance | `IDT-001`; `DESIGN.md:77-79`; `IDT-002`, `CMP-010` | Ledger readership only |
| Composition provenance must be complete | `CMP-010`, `CMP-007`, `NAT-003` | Disclosure of it only |
| Compensation is a new forward effect, never erasure | `DESIGN.md:546`; `PRF-006`, `PRF-012`; `Rollback` rejected at `DESIGN.md:487` | Evidence side + the missing L1 counterpart |
| Conformance evidence is builder-produced, member-bound, and cannot be minted by unsafe extension | `TGT-003`, `PRV-002`, `HOST-004`, `CMP-006/011`, `ADM-013/014/015` + the 35 `observed-conformance` entries | **Partition explicitly or double-register ~35** |
| Adapters may not assert fencing or cleanup proof | `ADP-010` (F0) | — |
| Approval UX, desired-state reconciliation, trajectory/session state stay above Core | `DESIGN.md:349-351`, `:1278-1281`; `ADP-002`, `FWK-001` | Out of scope entirely |

**Two traps worth naming.**

1. `DESIGN.md:1254` introduces the `workspace-edit-offline` behaviour table as *"Its **intended** complete expansion includes"*. The **bullets** at `:1233-1247` are locked; the **table rows** at `:1256-1272` (`Host sockets | None`, `.git/.agents/.codex read-only`) are not. F must not treat those rows as locked source material.
2. The unlocked research documents (§2.10) contain the most quotable disclosure prose in the repo. They are the strongest *input* available and the weakest possible *premise*.

---

## 5. Sizing

**Calibration (verified).** Packet E: four design records — 1,039 + 674 + 1,177 + 1,679 = **4,569 lines**; `PACKET-E-OBLIGATION-PARTITION.json .sourceObligationUniverse` = `{IDENTITY:30, LIFECYCLE:47, TAXONOMY:50, RESULT:51, total:178}`; **214** registered invariants. Yield **1.20×**.

**Delegated surface — F's is larger than E's on every axis measured:**

| Ledger | Packet E | Packet F |
|---|---:|---:|
| Packet A surfaces delegating | 20 | **16** (but attached to only 14 distinct invariants, none a disclosure rule) |
| Packet B fields delegating | 5 | **6** |
| Packet D composition paths delegating | 33 | **54 — all of them** |

**Records: four, plausibly five.** Packet E needed four because it had four state spaces to lock in dependency order. F has at least four mutually irreducible axes — they share almost no vocabulary, so they cannot be one document:

| Record | Est. lines | Note |
|---|---:|---|
| Classification & audience lattice | 700–900 | Everything else references it; must land first |
| Disclosure-channel / sink contract | 1,200–1,600 | A `class × sink × audience` matrix; the record most likely to reach result/error scale (1,679) |
| Evidence integrity, retention, decoding boundary | 900–1,200 | |
| Host acquisition / reservation / TOCTOU | 1,000–1,400 | Host state and sequencing; shares no vocabulary with the other three |
| Authorization / tenancy | 500–800 | Plausible fifth, or a section of the first |
| **Total** | **4,300–5,900** | |

**Estimate the high end.** Packet E's records *refined* a locked model; Packet F's must *invent* one while reconciling against 74–115 already-registered invariants across five packets.

**Obligations and invariants.** At E's 1.20× yield, a walk of **150–260 obligations** lands at **180–310 invariants**. That pushes the registry to roughly **534–664** entries and the Packet D matrix to **28,800–35,900 cells** (54 paths × registry length).

**Per-invariant cost is fixed and known** (`CONTRIBUTING.md:55-59`, verified against current artifacts: 354 registry entries = 354 corpus headings = 354-character vectors × 54 paths = 19,116 cells, 256 `VAL-` witnesses): a corpus `####` heading, a `VAL-` witness, a classification character appended to **all 54** Packet D vectors, matrix regeneration, re-pinned digests across the lockstep table.

**Honest caveat on the range.** The spread is wide because §3.1's frame decision moves it. Alternative (i) yields the low end; alternative (iii) — a second Packet-D-scale matrix — adds a generator, a validator, a harness, and a pinned generated document that no line estimate above includes.

---

## 6. Sequencing risk — fix before F, do not inherit into F

Packet F will register 180–310 invariants into machinery that has three *known-open* defects and four *stale claims*. Every one of them multiplies by F's registration count if inherited.

### 6.1 Known-open, blocking — fix first

**(a) The `unrepresentable` / `source-rejection` contradiction (FINDINGS F2).** `validate-registry.jq:294-299` requires a `source-rejection` test for `unrepresentable` — and **all 28 `unrepresentable` invariants declare one** (verified: 28 of 28). `source-rejection` presupposes a source that can express the invalid value and be refused; `unrepresentable` claims no such source exists. Both cannot hold. Commit `c6aded3` reclassified three (`SBX-004`, `SBX-024`, `PIO-004`), left three borderline (`ADM-002`, `PRC-013`, `PIO-002`), and **left the structural contradiction untouched**. `test_kinds` (`validate-registry.jq:78-87`) has eight members and **no compile-fail kind**, so the one genuinely unrepresentable case (`ERR-002`) has no correct test mechanism and the corpus has no place to record one. F's disclosure rules will produce more genuinely-unrepresentable entries (a closed audience vocabulary is exactly the shape that holds). **Add the test kind and relax the validator rule before F, not during.**

**(b) 87 residual `wire-corruption` declarations.** After `569bc08` made the obligation conditional on `decoding_trust_boundaries`, the current registry is: **required 107, declared 194, declared-but-not-required 87, required-but-not-declared 0.** The 87 split as 45 pre-existing (20 Packet A, 3 Packet C, 9 Packet D, 12 seeded corpus, 1 Packet C strengthening) and **42 Packet E** (ADP 11, OPA 7, ERR 5, FEN 5, IDE 5, ADM 4, POL 2, SBX 2, RET 1). `569bc08` deliberately left the 45 as a "Packets A-D question"; the 42 Packet E residuals are not accounted for anywhere. Every one is a planned test that the slice's own evidence says cannot be written. **Decide the disposition of all 87 before F adds its own.**

**(c) The admission-anchor gap (`54d21cc`).** A fifth semantic anchor — *"a J cell must cite an invariant decidable at an admission station"* — was designed, found three genuine defects, and **could not ship**: `SignalProcess` against `stopped/closed` and `unknown/closed`, and `TerminateProcess` against `unknown/closed`, all reject at admission while citing only invariants at L1, D0, T0, H0, E1. `SIG-001` covers arbitrary signals, `SIG-002` the suspended case; **neither covers stopped or unknown.** The commit records the fix as *"registering the missing admission-time invariant, which is a full batch cycle and should be a deliberate decision rather than a side effect."* It is still open. Consequence for F: **the strongest available oracle over cell semantics is switched off**, and F's own reject-at-admission cells will be validated by a weaker rule than the one that exists in draft.

### 6.2 Stale claims — cheap to repair, expensive to inherit

| Claim | Where | Truth |
|---|---|---|
| "1,453 tests are planned" | `INVENTORY-REVIEW.md:29` and `:329`; `PACKET-E-OPERATION-CONTRACT-REVIEW.md:83`; `PACKET-E-OBLIGATION-PARTITION-REVIEW.md` exit-record fragment | **1,293** (verified). `569bc08` moved it; the four review records were not updated. |
| "`PACKET-E-OPERATION-CONTRACT-REVIEW.md` does not exist" | `INVENTORY-REVIEW.md:306` | It exists — 93 lines, created 2026-08-03. |
| "Four of the eight digest pins have no second copy" | `INVENTORY-REVIEW.md:318` | Repaired by `068d0a9`, which extended the coherence check to compare **all six** pin copies and gave both Packet E pins second copies with an early abort. |
| "A token that is also a `trustBoundaries` value is discharged for free by the `wire-corruption` test and creates no real obligation" | `CONTRIBUTING.md`, composition-path token section | False since `569bc08`. Only the 13 `decoding_trust_boundaries` discharge for free now. **This is the exact composed-rule class of defect F1 identified**, still live in the contributor guidance F will follow. |
| "F2 remains open and would reclassify roughly 14 dispositions" | `FINDINGS.md:146` | Withdrawn at `FINDINGS.md:79-95` by `c6aded3`; the recommendation paragraph still carries the retracted number. |

### 6.3 Model-level risks F should rule on, not merely absorb

- **Test-kind vocabulary is branch-specific** (`FINDINGS.md:136-141`). It was designed against Packets A–D, which are almost entirely pre-launch. `wire-corruption` is vacuous post-launch; `source-rejection` contradicts genuine unrepresentability; `runtime-probe` needs a claimed/observed split the registry does not carry. **Packet F is the first packet whose subject matter is neither pre-launch validation nor lifecycle state**, so it will stress the vocabulary in a *third* direction. The recommendation at `FINDINGS.md:143` — *revisit the test-kind obligations per branch rather than per invariant* — should be executed before F, not after.
- **`observed-conformance` records the disposition but not which fact is claimed and which is observed** (`FINDINGS.md:120-128`). F's whole §2.7 isolation block is claimed-versus-measured. It will register into a disposition that structurally cannot express its own substance.
- **Hook placement between `firstSoundPhase` and `rejectionDeadline` is underdetermined** (`FINDINGS.md:112-118`). For F's egress rules (§3.1) the "where does the hook actually go" question is not a refinement — it is the rule.
- **Three machine or reviewed ledgers still contradict the 2026-08-03 widening.** `PACKET-D-CASE-CONTRACTS.json:58-69` freezes F's concerns at exactly `["disclosure","redaction","evidence-visibility"]` (verified, identical in `PACKET-D-COMPOSITION-COVERAGE.json`), hard-coded again at `validate-composition-coverage.jq:407-411` and asserted by 92 validator cases; `PACKET-D-COMPOSITION-REVIEW.md:263-265` assigns rollback and reservation to **Packet E**; `PACKET-A-SURFACE-COVERAGE.json:1452-1465` delegates `runtime.preflight` to **Packet C** and `:1480-1490` delegates `runtime.cleanup-errors` to **Packet E**; `PACKET-C-TARGET-REALIZATION-REVIEW.md:375-377` says Packet E must walk allocation/reservation and rollback. **The widening exists only as prose at `INVENTORY-REVIEW.md:332-358`.** Either rule that acquisition/reservation/rollback are `evidence-visibility` concerns, or widen the machine taxonomy — which changes the validator, the case catalog, the generated coverage document, and the digest pins, i.e. reopens Packet D.
- **F's own scope statement is internally inconsistent.** The dimension row (`INVENTORY-REVIEW.md:98`) requires walking *process inheritance*, *metadata services*, and *side-channel claims*; the nine-bullet walk list at `:368-379` names metadata endpoints but **omits process inheritance and side channels**. And `PACKET-A-RESOURCE-OPERATION-REVIEW.md:184-185` delegates *authentication and tenancy* to F, which the walk list also omits.
- **The E/F seam ruling was planned and never written.** `plans/2026-07-31-packet-e-runtime-lifecycle-inventory-walk.md:200-213` is an unchecked `- [ ]`; `PACKET-E-OBLIGATION-PARTITION-REVIEW.md:379-381` leaves the row `partial`. Packet D's `delegatedConcernTaxonomy.F` is declared with **zero cells assigned to it** (each of the three strings occurs exactly once in the 2.8 MB coverage file). Until the ruling is recorded, an obligation can sit on both sides — a defect by the plan's own terms.

### 6.4 Recommended order

```
Stage 0  (small, blocking)
  0a  Reconcile F's scope: dimension row vs. walk list vs. Packet A delegation
      (process inheritance, side channels, authentication, tenancy).
  0b  Amend Packet A / C / D ledgers to match the 2026-08-03 widening,
      or rule the widening into the existing three-concern taxonomy.
  0c  Write the E/F disclosure-channel seam ruling; assign every affected
      obligation to exactly one side.
  0d  Repair the five stale claims in §6.2.
  0e  Rule on the 87 residual wire-corruption declarations.
  0f  Fix the unrepresentable/source-rejection contradiction; add a
      compile-fail test kind or relax the validator rule.
  0g  Register the missing admission-time invariant and ship the fifth
      semantic anchor  (a full batch cycle -- deliberate, not a side effect).

Stage 1  Packet F design phase: 4-5 locked records, 4,300-5,900 lines.
         Lock order: classification/audience lattice -> disclosure frame
         (egress ruling + trust-boundary/owner rulings) -> evidence
         integrity/retention/decoding -> acquisition/reservation/TOCTOU
         -> authorization/tenancy.
         Each record must open by partitioning against the ~17
         disclosure-purpose invariants and the 35 observed-conformance
         entries that already occupy F's territory.

Stage 2  Exhaustive inventory walk: 150-260 obligations -> 180-310 invariants.
```

**Bottom line.** The next unit of work is **not** a walk. It is Stage 0 — small, mostly mechanical, and entirely blocking — followed by a design phase that is comparable in size to Packet E's and harder in kind. Attempting the walk now would register 180–310 invariants against no locked decision, into a test-kind vocabulary known to be branch-specific, with the strongest available cell-semantics oracle switched off, and against three machine ledgers that still deny F owns half its scope.

---

## 8. Stage 0 execution record

| Item | State | What changed |
|---|---|---|
| **0a** scope reconciliation | **done** | `INVENTORY-REVIEW.md` walk list now names process inheritance, side channels, authentication, tenancy, and the metadata-service host carve-out. The four omissions are recorded as omissions, not silently absorbed. |
| **0b** Packet A/C/D ledger amendment | **done — ruled, not amended** | `delegatedConcerns` is a per-path expansion; adding `authentication` would assert that `artifact-ordinary-authoring` delegates authentication to F, which is false. The taxonomy is correct about composition paths and was never a scope statement for F. Three independent delegations feed F — Packet D per composition path, Packet A per surface group, the dimension row per runtime boundary — and F's scope is their union. Recorded in `INVENTORY-REVIEW.md`. No ledger change, no digest cycle. |
| **0c** E/F disclosure-channel seam ruling | **done** | [`PACKET-E-F-DISCLOSURE-SEAM.md`](./PACKET-E-F-DISCLOSURE-SEAM.md). The line is **audience**, not content: Packet E owns the response to the caller, Packet F owns every other channel. Nine Packet E invariants named on the E side, seven obligation classes on the F side, none on both. Records three known misreadings, including that `ERR-007` does not reach a log line. |
| **0d** stale claims | **done** | Planned-test count corrected in four records; two `INVENTORY-REVIEW.md` open-work items closed; the `CONTRIBUTING.md` free-ride guidance corrected to the thirteen `decoding_trust_boundaries`; the retracted ~14-disposition estimate removed from `FINDINGS.md`. |
| **0e** residual `wire-corruption` declarations | **done** | All 87 removed. Declared and required counts are now equal at 107. See the follow-on section of `FINDINGS.md`. |
| **0f** `unrepresentable` / `source-rejection` contradiction | **done** | Ninth test kind `construction-exclusion` added. `unrepresentable` discharges with either kind; `reject-at-boundary` still requires `source-rejection`, because a boundary check presupposes something arrived to be checked. |
| **0g** missing admission-time invariant | **open** | Needs a full batch cycle: corpus heading, `VAL-` witness, 54 Packet D classification characters, matrix regeneration, digest re-pin. |

Gate state after 0a–0f: `check-inventory.sh` **EXIT=0**,
`check-model-coherence.sh` **34 passed / 0 failed**,
`check-enforcement-closure.sh` **exit 5** (correct — Gate 4B stays open).
