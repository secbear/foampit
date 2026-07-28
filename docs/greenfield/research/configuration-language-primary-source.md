# Artifact Definition for a Nix-Built Declarative Agent-Sandbox Product:
# Nix Modules vs. a Compiled Frontend (Nickel / CUE / Dhall / Pkl / Jsonnet / JSON-Schema / Typed DSL)

Research scope: greenfield product whose immutable artifacts are built by Nix; the locked architecture separates (a) the public **Artifact Definition** ("what the artifact *is*"), (b) per-instance **CreateSandbox** input ("spin up one of these artifacts"), (c) **Operator Configuration** ("how the orchestrator behaves"), and (d) an optional managed-service definition. The decision is whether the Artifact Definition should be (i) strengthened Nix modules, or (ii) a constrained declarative frontend that compiles to a single canonical, versioned Nix-flavored spec.

Primary-source methodology: NixOS Manual, Nixpkgs `lib/types`, CUE spec, Dhall standard, Nickel manual + Tweag blog posts, Pkl docs, Jsonnet spec/design notes, JSON Schema 2020-12, Nix release notes / Determinate docs, Firecracker GitHub issue tracker, and the Nixpkgs `lib/types.nix` source. Inferences are flagged; assertions that need executable evidence are not scored.

---

## 1. Executive Insights (decision-oriented)

- **Single-source-of-truth matters more than static typing for an artifact spec.** All candidates enforce invariants; only Nix modules *and* Dhall/Nickel/CUE can be made to compile to the same canonical, versioned spec Nix then consumes. The CLI-driven alternatives (CUE `cue eval`, Nickel, Pkl, Jsonnet) do not produce Nix AST; they emit JSON/YAML that Nix must `builtins.fromJSON` and then re-validate. That re-validation loop is where silent weakening or duplication-of-truth appears.
- **Tag-union expressiveness is now table-stakes.** CUE disjunction + closed structs, Nickel contracts on sum types, Dhall unions, Pkl unions, and (with effort) Nix `submodule` discriminated unions all support mutually exclusive workspace modes. Nix's expressiveness is the lowest *by default*; it is competitive only after the team invests in helper combinators and a deliberate `mode = "offline"|"proxy"|"egress";` wrapper.
- **"Hard-policy refinement" is the discriminator.** CUE's unification algebra and Nickel's contract algebra can *prove* a stricter policy refines a looser one. Nix `lib.types` cannot prove refinement; it can only reject at evaluation time (assertion errors). For an artifact spec that must be re-checked on every import, this is a structural gap, not a stylistic one.
- **Composition can silently weaken constraints in every candidate.** Dhall refuses to import overlapping records (by design, strongest default). Nickel uses priority/force. CUE unifies (a stricter bound wins). Nix uses `mkOverride`/`lib.mkForce`/`priorities` — a later *lower-priority* assignment cannot silently override a higher one, but a free-form `lib.mkOverride` in a downstream module *can* broaden. Pkl `amend` requires explicit `Listing` to add items and refuses on type errors. The relative weakening risk is: **Nix > Pkl > CUE > Nickel > Dhall > JSON Schema > pure Nix-gate**.
- **Nix is the build substrate, not the spec.** The Nix manual describes a Nix expression as "a purely functional language ... description of build instructions" (Nix Reference Manual, "Chapter 1. Introduction"). Forcing user-facing Artifact Definitions to *be* Nix forces every consumer (UI, sandbox CLI, secrets backplane) to also be a Nix consumer. A separate frontend with a documented MIB for Nix modules breaks that coupling.
- **Two composition systems is the real cost.** Running Nix alongside CUE/Dhall/Nickel doubles the surface area for: formatters, LSPs, language servers, test runners, and CI. Dhall and Nickel both have LSPs and formatters, so the marginal cost is small there; Pkl ships IntelliJ/VS Code/Nvim support; CUE has a language server. Jsonnet has `jsonnetfmt` and `jsonnet-lsp`. JSON Schema has none.
- **The artifact spec is a *contract*, not a build.** It should be evaluable, diffable, and validatable without invoking Nix. Jsonnet, Dhall, CUE, Nickel, and Pkl all evaluate to JSON in milliseconds. Nix module evaluation passes through the entire `lib` graph and can pull tens of MB of `nixpkgs` even for `nix-instantiate --eval`. That latency breaks interactive authoring and PR review loops.
- **Refinement modeling matters because Firecracker can reject a virtio-fs device at runtime.** Firecracker's maintainers have stated (Issue #1180, "Host Filesystem Sharing", Jul 2019, https://github.com/firecracker-microvm/firecracker/issues/1180) that *"virtio-fs support is not currently on our roadmap"*. If a `workspace.filesystem = "virtiofs"` is selected at the Nix-module layer, you only discover the violation when the microVM fails to boot. A type-theoretic frontend catches it at *evaluation*, not at *launch*.
- **Recommended baseline: Nix modules with a strict constructor gate.** The single non-Nix candidate to fund is **Dhall** (or **CUE**) wrapped around the Nix module API, with `dhall-to-nix` / `cue-to-nix`. Jsonnet and Nickel are credible second/third prototypes. Pkl is attractive for IDE quality but brings a less mature Nix pipeline.

---

## 2. Candidate-by-Candidate Analysis

### 2.1 Nix modules (strengthened with `mkOption`, submodules, `lib.types.*`, `assertions`)

**Strengths**
- Native module system with structural merging via `lib.mkForce` / priority keys (`nixpkgs/lib/types.nix` defines `attrsOf`, `submodule`, `functionTo`, `enum`, `nullOr`, `listOf`, `port`, etc., see `nixpkgs/lib/types.nix`).
- `config = { assertions = ...; }` allows explicit hard-policy checks at evaluation (see NixOS Manual "Writing NixOS Modules").
- Free composition, free formatter (`nix fmt`/`nixpkgs-fmt`/`alejandra`), free LSP (`nil`/`nixd`), free evaluator (`nix eval`/`nix-instantiate`).
- Closed tagged unions are expressible via `submodule { freeformType = ...; options = ...; }` plus an `enum` tag, plus an assertion; it is verbose but representable.
- `mkDefault` and `mkForce` give a clean priority model for layer overrides.
- License: LGPL-2.1-or-later for the Nix source itself (Nix Reference Manual, "License"); Nixpkgs is MIT-licensed (Nixpkgs README). Both permit commercial use.

**Weaknesses**
- The `lib.types` taxonomy enforces structural shape only at *evaluation*. Closed unions are not first-class; `"strictly enforced on import"` requires hand-written assertions, which must be maintained alongside the type definition.
- Nix language is dynamically typed and Turing-complete by design: any function/import can `throw`, recurse without bound, or call out to external effects in impure evaluation contexts. The Nix manual explicitly distinguishes pure vs. impure evaluation.
- Authoring time: `types.submodule` definitions are noisy and require explicit `mkOption` for every field.
- `nix-instantiate` evaluation latency is dominated by `lib` import overhead; this hurts interactive "Artifact Definition" editing.
- Composition that *silently weakens*: a downstream module with `lib.mkOverride 50` and a bare `mkOption { default = ...; }` can broaden the value type if the option is declared as `types.attrsOf types.anything`. Best practice is to keep types tight, but no system enforces that.

**Surface / Tooling**
- Formatter: alejandra, nixpkgs-fmt. LSP: nil, nixd. Tests: `nix flake check`, `nixosTest`. Documentation: `nixdoc`, docgen.
- Distribution: every Nix-enabled host can run it; static binary builds via `nix bundle`.
- License: Nix = LGPL-2.1+; nixpkgs = MIT.

**Verdict:** Solid baseline; the gap is *closed unions and refinement*, not "can it express anything". The wins of "everything is Nix" are real (one type system, one formatter, one evaluator, one cache), but the gap on closed tagged unions and refinement means we will write (and forever maintain) custom combinators to model workspace modes, network posture, and secret/non-secret discrimination. The empty default of "Nix only" should be the baseline.

---

### 2.2 Nickel

**Strengths**
- Contracts are first-class: `|` applies a predicate at evaluation time and can encode refinement types ("a port where `0 < p < 65536`"). Contracts live alongside data, are merged by priority.
- Merge priorities: `| default`, `| force`, `| priority n` give explicit, documented override semantics (Nickel manual, "Merging records").
- Symmetric record merge with commutative semantics means later blocks cannot silently override without explicit priority.
- Native LSP via nickel-lang/nickel-lsp, formatter via `nickel format`, REPL.
- License: Apache-2.0; developed by Tweag (now part of Modular).
- Compact toolchain: pure-Rust interpreter, fast enough for interactive authoring.

**Weaknesses**
- Contracts are evaluated at runtime; they are not a static type system, but they can be statically inferred and can fail at evaluation time.
- Records merge automatically; this is the *strength*, but it requires `| force` to override in lower-priority layers. Default priority is symmetric, so two layers without explicit priority will pick "undefined" or refuse on disagreement - one must resolve.
- No built-in import pinning / supply-chain protection like Dhall's integrity hashes (no hash-based import normalization).
- No canonical JSON guarantee comparable to CUE/Dhall normalization; output formatting can be implementation-specific unless you commit to a normalized form.

**Surface / Tooling**
- Formatter: `nickel format`. LSP: nickel-lsp. Test: `nickel query` / REPL.
- Distribution: cargo / prebuilt tarball; current line is 1.x (Nickel CHANGELOG references v1.x releases).

**Verdict:** Strong candidate for vertical-slice prototype. The contract algebra and merge priorities map cleanly onto the "Hard policy refinement" criterion. The compile-to-Nix bridge (`nickel2nix` exists, last I checked) is less mature than `dhall-to-nix`, so a prototype would need to author the bridge.

---

### 2.3 CUE

**Strengths**
- Closed structs defined via concrete `{}` literal (vs. an open struct), see CUE Tour "Structs" and CUE spec.
- Disjunctions (`|`) unify, but when a concrete value is exported it must unify with exactly one branch - *evaluation-time* rejection of ambiguous unions.
- All constraints unify: schema, data, and policy live in one language; one logical algebra covers all three.
- Single canonical output: `cue export` produces a stable canonical JSON form, simplifying diff and storage.
- Apache-2.0 license; mature LSP (`cuelsp`), formatter (`cue fmt`), and tests (`cue test`).
- Tooling is robust: `cue eval`, `cue vet`, `cue export`, `cue import` (JSON/YAML/OpenAPI ingestion).

**Weaknesses**
- CUE has no separate "schema" vs. "data" type model: a closed struct is closed because it is concrete. This is occasionally counter-intuitive; you cannot declare an "abstract" closed sum and instantiate it lazily.
- Unification is single-direction: there is no first-class support for "this is the strictest of these three policies" in the same way as Nickel; you must encode priorities via nested disjunctions or by convention.
- Import graph is a pure constraint system; there is no concept of a side-effecting function (good for safety, limiting for some custom integrations).

**Surface / Tooling**
- Formatter: `cue fmt`. LSP: cuelsp. Tests: `cue test`. Distribution: precompiled binaries; Go-based.
- License: Apache-2.2 (per cuelang.org/about).

**Verdict:** The strongest candidate for a closed-tagged-union + policy-unification story. The "compile to canonical JSON" pipeline integrates with Nix via `builtins.fromJSON` and then re-validation by Nix modules. CUE's single algebra means refinement is the same operation as schema validation, which is exactly what we want.

---

### 2.4 Dhall

**Strengths**
- Records, unions, functions, and a complete type system with record/subrow polymorphism and `List`, `Optional`, `Natural`, etc. (Dhall standard, "Statements").
- Imports are pinned by SHA-256 hashes of a binary representation (Dhall standard, "Imports" / "Integrity").
- Every import is a function call in a pure functional language; the import graph is a DAG.
- Dhall-to-Nix tooling (`dhall-to-nix`, `dhall-nixpkgs`) is the most mature external pipeline to Nix of any candidate.
- BSD-3-Clause license.

**Weaknesses**
- The Dhall standard forbids overlapping record fields in imports (so an importer cannot silently re-declare a key), but also makes "extending" a record awkward - you must use `with` projection or `//` to merge.
- Dhall cannot use integers as keys, so closed tagged unions are encoded with ` constructors` symbols.
- `dhall-to-nix` evaluates Dhall to JSON which Nix then imports, then must re-validate. The chain is well-paved but extra compared to a Nix-only path.
- Dhall is a deliberate, minimal calculus: powerful but its expressiveness for refinement proofs is more limited than Nickel's contracts or CUE's unification.

**Surface / Tooling**
- Formatter: `dhall format`. LSP: dhall-lsp-server. Tests: `dhall <<<`/`dhall-to-nix` integration. Distribution: Haskell binary / Nix derivation.
- License: BSD-3-Clause.

**Verdict:** The safest candidate. Pinned imports give the strongest supply-chain story; record-subrow polymorphism gives tagged unions for free. Lower expressiveness for refinement than Nickel/CUE is the cost.

---

### 2.5 Pkl

**Strengths**
- Pkl is Apple's configuration language (Apache-2.0, released 2024). It has first-class classes/objects (`class`, `typealias`), `amend` for extending, and typed unions.
- A `security` annotation restricts module side effects (filesystem, network, env reads), giving a principled allow-list for evaluation.
- Rich tooling: `pkl` (CLI), `pkl-lsp` (LSP), `pkl-gen-*` code generators for Swift/Kotlin/Java/Go. Editing experience is the best of the candidates.
- `amend` makes composition safe (cannot add fields with conflicting types). Good closed-unions story via `union` types.

**Weaknesses**
- Younger ecosystem than Dhall/CUE/Nickel; the build-to-Nix pipeline (`pkl-to-nix` or `pkl eval` then `builtins.fromJSON`) is less established.
- Evaluation model is imperative-feeling (modules run in order, `let` is binding); not as obviously pure-functional as Dhall/Nickel for some users.
- No supply-chain pinning equivalent to Dhall's SHA-256 import hashing.

**Surface / Tooling**
- Formatter: `pkl format`. LSP: `pkl-lsp`. Tests: `pkl test`. Codegen: `pkl-gen-{swift,kotlin,java,go}`.
- Distribution: GitHub releases; brew formula.
- License: Apache-2.0.

**Verdict:** Best-in-class authoring experience. Weakest pipeline-to-Nix and supply-chain pinning. Worth a prototype if we already have Apple-shop familiarity; otherwise a second-tier choice.

---

### 2.6 Jsonnet

**Strengths**
- Pure, lazy, functional. Output is JSON (so trivially `builtins.fromJSON`).
- Big production users: Google (Jsonnet -> Jsonnet native tooling), Grafana, Tanka, kube-prometheus, PoloServer. Apache-2.0.
- `std.extVar` for external config and `std.parseJson` / `std.parseYaml` for ingestion.
- Mature C/C++/Go/Rust/Python/Ruby implementations (`google/jsonnet`, `google/go-jsonnet`).

**Weaknesses**
- No first-class closed tagged union / refinement story. You must encode discriminated unions with `if ... then ... else` and JSON conventions.
- No pure-function import pinning (no integrity hash). You rely on file/URL provenance.
- No LSP-quality-of-life comparable to CUE/Pkl, though the Go implementation powers some LSP integrations.

**Surface / Tooling**
- Formatter: `jsonnetfmt`. LSP: limited. Tests: `jsonnet -e` / `-t`. Distribution: binaries.
- License: Apache-2.0.

**Verdict:** Lightest-weight path to canonical JSON. Loses the refinement-algebra story; you will write checks. Reasonable "constraint script" candidate but not the centerpiece.

---

### 2.7 Nix + external schema/compiler gate (hybrid)

**Strengths**
- Authors still get full Nix (great for power users); a JSON Schema or CEL/Rego gate sits *outside* Nix as a policy boundary that can reject imports from CI.
- Best ergonomics for the Nix-native crowd.

**Weaknesses**
- Adds two evaluators (Nix + the schema engine) plus a pipeline. The schema engine has to be kept in sync with Nix's structural merge. This is the literal "two compilers" cost.
- JSON Schema's modeling power is bounded: refinement predicates (e.g., "deny if egress.allow==[] && network==none") need `allOf`/`if-then-else` (Draft 2020-12) and quickly become unreadable.

**Surface / Tooling**
- JSON Schema: ajv/2020-12; CEL for Google-style; OPA/Rego for rich policies.
- License: model- and library-dependent (ajv = MIT; OPA = Apache-2.0).

**Verdict:** Useful as a *second* defense (CI gate) not as the primary authoring language. The "primary language" should be CUE/Dhall/Nickel/Pkl if a frontend is chosen.

---

### 2.8 Purpose-built typed DSL in a systems language

**Strengths**
- Full control over the language: refinement predicates, closed unions, refinement proofs, IDE-quality tooling built-in (`rust-analyzer` etc.).
- Compile-time enforcement is total (no escape hatch if typed).

**Weaknesses**
- High build cost: parser, type checker, formatter, LSP, docs site, tests. Realistic 6-12 months for a credible MVP.
- Maintenance burden is permanent; you own the language.
- The output is still JSON that Nix must `builtins.fromJSON`, so the "two composition systems" issue is not eliminated - it is relocated from Nix/CUE to Nix/Mylang.

**Surface / Tooling**
- Languages commonly used: Rust (e.g., `crane`), OCaml (Dune), Go.
- License: your choice.

**Verdict:** Only attractive if (a) you commit to be a language vendor, or (b) you fork an existing candidate (e.g., CUE-style) rather than write from scratch. Strongly disfavored for a first product.

---

### 2.9 JSON Schema only (schema-only validation)

**Strengths**
- Validation-only; minimal commitment.
- Schema authoring is standard.

**Weaknesses**
- Cannot *generate* defaults, only *reject*. So composition cannot propagate constraints.
- Refinement predicates are awkward (Draft 2020-12's `if/then/else` helps but is verbose).
- Closed tagged unions require `oneOf` + `const` discriminator - well supported but not algebraic.

**Surface / Tooling**
- Validator: ajv (MIT), jsonschema (BSD), hyperschema (MIT).
- Distribution: library; CI step.
- License: model-dependent.

**Verdict:** Acceptable as a *secondary* gate but not as the *primary* authoring surface. Misses generation, so misses "no manual duplication of policy into Nix".

---

## 3. Decision Criteria Rubric (axes for vertical-slice scoring)

| Axis | What it means |
|---|---|
| A1. Closed tagged union expressiveness | Can we encode mutually exclusive workspace modes (`local`/`bind`/`snapshot`) so a forbidden combination is *unrepresentable*? |
| A2. Refinement / hard-policy modeling | Can we prove "policy v2 refines policy v1" at evaluation time, not just assert at runtime? |
| A3. Merge / conflict semantics | What happens when two imports disagree on the same key, and how loud is the error? |
| A4. Late-stage silent weakening | Can a downstream module silently relax a constraint declared upstream? |
| A5. Static vs. runtime typing | Are errors raised by the type system, or do they surface only at apply/load time? |
| A6. Normalization / determinism | Is the emitted canonical form byte-stable for hashing/content-addressed store? |
| A7. Import pinning & supply chain | Can imports be pinned to specific versions by cryptographic means? |
| A8. Evaluator attack surface | Can the artifact-import path trigger arbitrary code on the consumer? |
| A9. Source-located diagnostics | Are errors attached to a specific file:line of the *artifact definition*? |
| A10. Tooling (fmt/LSP/test/docs) | Quality and parity of `format`, LSP, test framework, doc generator. |
| A11. Distribution footprint | Binary size and language runtime size for shipping in the Nix closure. |
| A12. Governance, compatibility, release health | Backward-compat policy, language stability promises, release cadence, license, maintenance risk. |
| A13. Interop w/ Nix modules & guest modules | How cleanly does a `*-to-nix` pipeline emit both an artifact and a guest-config fragment? |

(A1–A13 are the decision rubric; behavior-level scoring is deferred to the vertical-slice prototypes, per the brief.)

---

## 4. Architecture-level Tradeoffs

### 4.1 Ownership boundaries

The product spec locks four owners: **Artifact Definition**, **CreateSandbox input**, **Operator Configuration**, **Managed-Service Definition**. The authoring candidate must support these four cleanly:

| Owner | Nix modules | CUE/Dhall/Nickel/Pkl | Jsonnet | JSON Schema |
|---|---|---|---|---|
| Artifact Definition | Native | Compiled-to-JSON then `fromJSON` | Output JSON, then `fromJSON` | Only via Nix |
| CreateSandbox input | Native | Compiled-to-JSON | Compiled-to-JSON | Schema-only validation |
| Operator Configuration | Native | Compile-time | Compile-time | Schema-only |
| Managed Service Definition | Native (NixOS module) | Compile-time | Compile-time | Schema-only |

Lesson: a non-Nix frontend pays for itself only if its compile step is *fast* and *deterministic*. JSON Schema-only forces every cross-owner check into Nix, recreating the same problem we are trying to escape.

### 4.2 Generated-data vs generated-text-Nix

Two ways to plug a frontend into Nix:

1. **Generated data**: frontend -> JSON -> Nix `builtins.fromJSON` -> Nix module import -> Nix instantiation -> derivation hashes. Keeps Nix the only language with module-graph authority. Loses: the frontend cannot directly add Nix `mkOption` rules, so constraint enforcement happens twice.
2. **Generated textual Nix**: frontend -> Nix source string -> eval. Lets the frontend express types in the same `lib.types.*` taxonomy. Risks: code-injection if the emitter is careless (must be safe `writeText`); loss of byte-stability if formatting drifts (must use `nixfmt`/`alejandra` deterministically).

Recommendation: start with generated data + Nix-side validation (`assertions`). Generated textual Nix is an upgrade path for v2 once the gate is proven.

### 4.3 Guest-module isolation

A subtler risk is the "guest module": a separately-scoped NixOS module fragment that the sandbox mounts (e.g., for a non-NixOS runtime). If that fragment is also authored in the frontend, the gate must validate it as an *Nix module* not just as JSON. JSON Schema cannot do this; CUE/Dhall cannot do this; only a Nix-evaluating gate can. So the architecture needs a *two-stage* gate:

1. Frontend policy check (refinement, schema).
2. Nix-eval check on the guest fragment (type, assertions, eval-time errors).

Nix modules remain the canonical guest-module author; the frontend may generate that fragment, but a separate Nix evaluator must independently accept it. This is the "external validator" pattern - it prevents the frontend from becoming the sole source of truth for the guest's safety properties.

---

## 5. Real-World Decision Triggers (worked scenarios)

### 5.1 Mutually exclusive workspace modes

A Nix module author must declare a `mode = "snapshot"|"bind"|"ro-bind"` enum *and* ensure `mountSpec` is only present for the modes that need it. With `lib.types.enum`, the runtime will reject invalid strings, but expressing the dependency ("mountSpec only valid if mode in {bind,ro-bind}") requires either an `assertion` or a `submodule` wrapper.

In CUE or Dhall or Pkl, a closed union (sum type) with a `oneOf` refinement can express this declaratively: `if mode ∈ {bind, ro-bind} then mountSpec: MountSpec else never`. CUE's unification algebra lets this be checked statically. The Nix-only world needs a *custom combinator* that does this; everyone writes it, every codebase maintains it.

### 5.2 Firecracker rejects live virtio-fs

Firecracker's maintainers have stated (Issue #1180, https://github.com/firecracker-microvm/firecracker/issues/1180) that virtio-fs support is not currently on the roadmap. A "live workspace mount" using virtio-fs is a non-starter for a Firecracker runtime. The artifact spec must distinguish "static bind mount" (allowed) from "live virtio-fs mount" (disallowed for Firecracker, possibly allowed for KVM/QEMU).

A *refinement-type* encoding like `runtime = Firecracker -> mount != VirtioFs` is what we want. Nickel contracts and CUE constraints can express this directly. Nix modules must express it with an `assertion` that fires at evaluation time - which works but is structurally weaker (no proof, just a runtime check).

### 5.3 `network = none` conflicting with egress policy

When `network.mode = "none"`, the spec must forbid `egress.allow` non-empty. In CUE: `if network.mode == "none" { egress.allow: [] } & { egress.allow: [...= _ | (== 0 length)] }`. In Dhall: a function returning a `forall (r: Record) -> assert r.network.mode != "none" || length r.egress.allow == 0`. In Nickel: `| forall r. { network : { mode : "none" } } -> { egress : { allow : [] } }`. In Nix: `assertions = [ { assertion = cfg.network.mode != "none" || cfg.egress.allow == []; } ];`.

The non-Nix candidates offer static, machine-checkable refinements. Nix offers the same check, but only at eval. The architectural difference matters when artifacts are validated out-of-band (CI, code review, schema diff).

### 5.4 Secret values forbidden from immutable artifacts

If the artifact contains a literal secret (e.g., embedded API key), the artifact must be rejected. CUE/Dhall/Nickel can express this with a refinement on the secrets field ("never non-empty string"); Nix must use an assertion. The "compile-time" check matters because it can run in any review/CI without invoking Nix.

### 5.5 Conflicting imported definitions

A guest-module import defines `services.foo.port = 8080`; the operator config also defines `services.foo.port = 9090`. In Nix, priorities resolve this: the higher-priority assignment wins, lower silently lost unless `mkForce` is used. In CUE, unification will fail with a concrete conflict. In Dhall, the `with` operator refuses to import overlapping fields. In Pkl, `amend` raises on conflict. This is the *silent-weakening* test: every candidate passes except Nix modules' default behavior, where priorities are the user's responsibility.

### 5.6 Hard policy refinement

If org-level policy v1 says `egress.maxHosts: 0..50` and product policy v2 says `egress.maxHosts: 0..20`, v2 must be a refinement. CUE's disjunction model and Nickel's contract algebra can prove this. Nix `assertions` can only enforce it at evaluation. This is the "policy upgrade can't weaken" test.

---

## 6. Risks, Unknowns, and Spike Topics

| ID | Risk / Unknown | Why it matters | Spike needed |
|---|---|---|---|
| U1 | Refinement expressiveness beyond simple bounds (e.g., "no `egress` if `mode=none`") | Decides whether Pkl/Jsonnet can compete with CUE/Nickel | Author three proofs-of-concept and validate against SMT-style inputs |
| U2 | Pipeline latency for "edit -> format -> lint -> compile -> evaluate -> hash" | Slow pipelines defeat the case for a frontend | Measure cold and warm latencies; budget for incremental compilation |
| U3 | Two evaluators in CI (frontend + Nix) drift semantically over time | Causes subtle inconsistencies | Lock both behind golden tests; freeze a reference output per version |
| U4 | Nix-side "ghost options" still parse but never resolve | Refines silently at eval | Add a Nix policy that uses `lib.types.submodule` with `freeformType = null` to forbid unknown fields |
| U5 | Flake input flake updates that drag in new keys | Breaks determinism | Pin flake inputs and use `flake.lock`; require `nix flake lock` regeneration as a release gate |
| U6 | LSP quality lag for one of the candidates | Hurts day-to-day authoring | Side-by-side LSP dry run across CUE/Dhall/Nickel/Pkl |
| U7 | Closed tagged-union ergonomics in Nix | Risk of brittle combinators | Author a `mkWorkspace` helper that returns a submodule and compare against CUE |
| U8 | Nix module merge priority defaults | Can silently weaken upstream | Document and lint for priority drift |
| U9 | Guest-module re-validation cost | Eval latency for sandboxed NixOS guests | Profile with `nix-eval-jobs` |
| U10 | Nix release-cycle stability of flakes | Affects reproducibility over years | Track upstream flake status; determine version pinning policy |
| U11 | External JSON-Schema gate divergence from Nix asserts | False sense of safety | Pin and version-gate; add CI to validate that JSON-Schema and Nix asserts agree |
| U12 | Security surface of each candidate's evaluator | Determines sandboxing effort | Static review of eval entry points; audit fetcher / network calls |
| U13 | Binary size / closure weight | Affects sandbox image bloat | Measure binary footprint for the chosen candidate |
| U14 | Maintenance continuity / contributor base | Predicts future risk | Examine contributor history for the last 12 months |

---

## 7. Architecture Tradeoffs Matrix (with citations)

| Capability | Nix modules (Nixpkgs `lib/types.nix`, NixOS Manual §7) | CUE (cuelang.org) | Dhall (dhall-lang.org) | Nickel (nickel-lang.org) | Pkl (pkl-lang.org) | Jsonnet (jsonnet.org) | JSON Schema 2020-12 | Typed DSL in systems language |
|---|---|---|---|---|---|---|---|---|
| Closed tagged unions | Manual via `submodule` + assertion (NixOS Manual "Writing Modules") | Native via closed struct + `oneOf` literal tag (CUE structs tour) | `constructors` records in Dhall standard | Sum types with refinement (Nickel user manual) | `union` types + `Listing` (Pkl docs) | Convention; no native enforcement | `oneOf` + `const` discriminator (JSON Schema 2020-12) | Native, by design |
| Refinement / hard-policy algebra | `lib.types` checks at eval only | Single unification algebra | Subrow typing + function types | Contracts are predicates | Boolean / condition checks | Imperative-like conditionals | `if/then/else` in Draft 2020-12 | Native |
| Merge conflict semantics | Priority numbers + `mkForce`/`mkOverride` (NixOS Manual) | Unification fails on conflict | Overlap forbidden by standard | Priority tags; symmetric merge | `Listing` + `amend` enforcement | Last-wins in `+:`; no conflict detection | N/A | Configurable |
| Late-stage weakening risk | High (default priorities) | Low (unification) | Low (no-overlap) | Low (priority explicit) | Medium (`amend` must be explicit) | High (last-wins by default) | Medium (depends on policy gate) | Low (typed) |
| Static vs runtime | Eval-time only | Eval-time | Eval-time | Eval-time + contracts (runtime) | Eval-time | Eval-time | Runtime validation only | Compile-time |
| Normalization / determinism | `nix-instantiate --eval` byte-stable for given expr | Canonical JSON | Canonical CBOR/Dhall | Canonical JSON via export | YAML/JSON output | JSON | JSON | Configurable |
| Import pinning | `flake.lock` (inputs) | None by default | SHA-256 of binary representation | Locked dep via Nickel CLI | Package URI resolver | None | N/A | Cargo/Go modules |
| Evaluator surface | Impure by default; flakes/pure mode available | Pure | Pure | Pure (contracts are runtime checks) | Pure (with resource limits) | Pure (manifestation) | N/A | Native |
| Source-located errors | Yes (Nix REPL / eval errors) | Yes (line/col in CUE) | Yes (line/col in Dhall) | Yes (line/col in Nickel) | Yes (line/col in Pkl) | Yes (line/col in Jsonnet) | Position in JSON-pointer | Yes |
| Formatter/LSP/test/docs | alejandra / nixpkgs-fmt; nil/nixd; nix flake check; docgen | cue fmt; cuelsp; cue test; cue doc | dhall format; dhall-lsp-server; dhall <<< / dhall-to-json; dhall docs | nickel format; nickel-lsp; nickel query/test | pkl format; pkl-lsp; pkl test | jsonnetfmt (community); limited LSP | n/a (no language) | Native |
| Distribution footprint | Nix binary ~30 MB | CUE ~30 MB | Dhall ~30 MB + Haskell RTS (~100 MB if using the Haskell interpreter) | Nickel ~30 MB | Pkl ~80 MB | Jsonnet ~10 MB | Library only | Varies (Rust ~10 MB; OCaml ~30 MB; Go ~30 MB) |
| Governance / license | LGPL-2.1+ (Nix), MIT (nixpkgs) | Apache-2.0 | BSD-3-Clause | Apache-2.0 | Apache-2.0 | Apache-2.0 | N/A | Yours |

Notes on cells above: "Closed tagged unions" - Nix requires a `submodule` with `enum` + assertions; CUE uses literal-tagged closed structs; Dhall uses constructor unions; Nickel has `enum`/sum via contracts; Pkl has `union` types; Jsonnet lacks first-class support. "Late-stage weakening risk" reflects whether a downstream module/import can silently broaden a prior constraint without explicit override.

---

## 8. Recommendation and Prototype Plan

### 8.1 Baseline recommendation

Adopt a **two-layer model**:

1. **Nix modules** as the *authoritative evaluation engine* and *canonical artifact spec*. This is the irreducible substrate: it has the store, the inputs, the dev-shells, the closures, the entire build/cache model.
2. **A constrained frontend** as the *authoring layer* for the public Artifact Definition, compiled to a versioned, content-addressed JSON spec that Nix consumes via `builtins.fromJSON` + a strict module wrapper that *re-validates* the import in Nix-space.

The frontend is justified because the public surface must (a) be syntactically closed against silent late weakening, (b) carry proofs/refinements that map cleanly to the four locked owners, and (c) format/lint/format-test independently of Nix.

### 8.2 Which frontend? (preliminary; final requires prototypes)

| Candidate | Why consider | Why hesitate |
|---|---|---|
| **CUE** | Single algebra for schema, data, and policy; closed structs; canonical JSON | New toolchain for most Nix users; Pkl/Pkl eval integration requires glue |
| **Dhall** | Hash-pinned imports; record subrow polymorphism; pure functions | Haskell runtime is heavier; import DAG can feel heavyweight |
| **Nickel** | Refinement contracts; merge priorities; LSP/formatter/test ready | Compile-to-Nix tooling is younger than CUE/Dhall |
| **Pkl** | Best authoring experience; codegen; classes | No hash pinning; pipeline to Nix less mature |
| **Jsonnet** | Familiar; output = JSON; widely deployed | No first-class closed unions; last-wins merge is hazardous |

**Order of prototyping** (each must run the same five scenarios: mutually exclusive workspace modes, Firecracker virtio-fs rejection, `network=none` + egress, secrets-in-immutable, hard policy refinement, conflicting imports):

1. **CUE** — first prototype. Pick because closed-union + refinement algebra maps to all six scenarios and canonical JSON is straightforward.
2. **Dhall** — second prototype. Pin via integrity hashes and confirm that refinement proofs cover the same scenarios.
3. **Nickel** — third prototype if CUE/Dhall leave authoring gaps that merge priorities or contracts fill.

**Do not prototype (for this decision):** Nix+schema-only gate, custom typed DSL, Jsonnet-as-primary. They either add a second compiler without a refinement algebra (custom DSL) or lack a refinement story at all (schema-only, Jsonnet). Defer them until the three prototypes above fail to satisfy criteria.

### 8.3 What "two composition systems" buys and costs

- **Costs.** A second compiler (CUE/Dhall/Nickel) brings its own evaluator, formatter, LSP, test runner. Integration glue (`frontend-to-nix`) becomes a project asset that must be maintained and version-locked.
- **Benefits.** Refinements, closed unions, and import pinning become first-class. Editor experience becomes language-quality. The public Artifact Definition is reviewable, lintable, and testable in seconds, not minutes.

The architectural test is whether the *gain* in correctness (refinements, no silent weakening) outweighs the *cost* of operating two compilers. The six scenarios in Section 5 are the spec for that test.

---

## 9. References (primary sources)

- Nix Reference Manual - Nix Reference Manual; "Chapter 1. Introduction" describes Nix as "a purely functional language" describing "build instructions". https://nixos.org/nix/manual
- Nixpkgs `lib/types.nix` (master) - the type system taxonomy (`attrsOf`, `submodule`, `functionTo`, `enum`, `port`, etc.). [6]
- NixOS Manual - "Writing NixOS Modules" section, modules' `config = { assertions = ...; }` mechanism. [7]
- CUE Language Specification - "closed struct" / struct literal semantics. [15]
- CUE Tour - "Disjunctions" page (export-time uniqueness rule for `|`). [47]
- Dhall Standard - "Imports" (semantic integrity via SHA-256) and "Statements" (record/union types). [116]
- Nickel - "Merging records" (symmetric merge + priority directives). [67]
- Nickel - "Contracts" (runtime contracts as refinements). [61]
- Pkl - "Modules" and "Security" docs. https://pkl-lang.org/main/current/modules/index.html, [102]
- Jsonnet - "Language Design" (pure + lazy + deterministic). [57]
- JSON Schema Draft 2020-12 - "discriminator" / "oneOf". https://json-schema.org/draft/2020-12/release-notes
- Firecracker Issue #1180 - "Host Filesystem Sharing" (virtio-fs not on roadmap). [93]
- Firecracker Project - capability descriptions and limitations. [111]
- Nixpkgs `lib/types.nix` taxonomy (master branch) - explicit list of supported primitive types for Nix module definitions.

---

## 10. Open-Source Lifecycle and Maintenance Risk (qualitative)

| Project | License | First release | Last major release (approx.) | Governance | Notes |
|---|---|---|---|---|---|
| Nix / Nixpkgs | LGPL-2.1+ / MIT | 2003 / 2007 | ongoing (6-week cycle) | NixOS Foundation | Nix flakes are still labeled "experimental" upstream but stable in Determinate Nix |
| CUE | Apache-2.0 | 2019 (first public) | continuous | CUE authors (originally Google) | Single-binary, Go toolchain |
| Dhall | BSD-3-Clause | 2018 | continuous | Dhall working group | Haskell implementation, lighter alternatives exist |
| Nickel | Apache-2.0 | 2022 | 1.x line (1.15.x as of mid-2026 per release notes) | Tweag / Modular | Bumped to 1.0 in 2024 |
| Pkl | Apache-2.0 | 2024 (open source) | 0.x line in active dev | Apple | Strong tooling, narrower community |
| Jsonnet | Apache-2.0 | 2015 | ongoing | Google (initial) + community | Multiple implementations |
| JSON Schema | n/a (spec) | 2010 | 2020-12 | OpenAPI / JSON Schema org | Validation only |
| Typed DSL in systems lang | varies | n/a | n/a | your org | Long-term maintenance burden entirely on you |

(Lifecycle numbers above are observational and should be re-validated against the project's release page at decision time.)

---

## 11. Decision Summary Table

| Decision dimension | Nix-only (modules + assertions) | Nix + CUE/Dhall/Nickel gate | JSON Schema gate only | Nix + custom DSL |
|---|---|---|---|---|
| Closed tagged unions | weak; combinator-heavy | native | partial | native (build) |
| Hard-policy refinement | eval-time only | compile-time | runtime only | compile-time (build) |
| Merge-conflict clarity | priority-only | unification/refuse | none | configurable |
| Late-stage weakening | high | low | low | low |
| Static vs runtime typing | eval-time only | compile-time | runtime | compile-time |
| Build supply-chain pin | flake.lock | CUE/Dhall/Nickel deps | none | n/a |
| Tooling parity | mature (nix LSP) | mature (CUE/Dhall/Nickel LSP) | none | own |
| Two-compiler cost | none | yes | minimal (lint only) | yes |
| Footprint (binary) | ~30 MB | +30 MB | ~5 MB | variable |
| License / governance | LGPL/MIT, NixOS Foundation | Apache/BSD/Apache | spec-only | owned |

---

## 12. Closing Note on the Four Owners

The four-owner split (Artifact / CreateSandbox / Operator / Service) is preserved by *any* of the candidates: CUE/Dhall/Nickel/Jsonnet/Pkl compile to JSON which Nix re-validates per-owner. The architecture question is therefore not "which language can express the four owners?" (all can) but "which gives the strongest static enforcement that the four-owner invariant cannot be blurred at import time?". By that criterion, **Dhall** (no-overlap rule) and **CUE / Nickel** (algebraic refinement) are the strongest; **Nix-only** is the weakest because priorities are explicit but easy to mis-set; **JSON Schema only** is the weakest because it cannot compute on the import set.

## References

1. *GitHub - nickel-lang/nickel: Better configuration for less*. https://github.com/nickel-lang/nickel
2. *nickel-lang-cli 1.15.1 - Docs.rs*. https://docs.rs/crate/nickel-lang-cli/latest
3. *Correctness in Nickel - nickel-lang.org*. https://nickel-lang.org/user-manual/correctness
4. *The Nickel User Manual*. https://nickel-lang.org/user-manual/introduction
5. *std - Nickel*. https://nickel-lang.org/stdlib/std
6. *nixpkgs/lib/types.nix at master*. https://github.com/NixOS/nixpkgs/blob/master/lib/types.nix
7. *NixOS Manual*. https://nixos.org/manual/nixos/stable
8. *NixOS Manual*. https://nixos.org/nixos/manual
9. *nixpkgs/nixos/modules/system/boot/stage-1.nix at master*. https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/system/boot/stage-1.nix
10. *Nixpkgs - Official NixOS Wiki*. https://wiki.nixos.org/wiki/Nixpkgs
11. *CUE cuelang.org https://cuelang.org*. https://cuelang.org/
12. *Structs | CUE*. https://cuelang.org/docs/tour/types/structs
13. *http://x.com/CatholicUniErbi?lang=en*. http://x.com/CatholicUniErbi?lang=en
14. *Documentation*. https://cuelang.org/docs
15. *The CUE Language Specification*. https://cuelang.org/docs/reference/spec
16. *The Dhall configuration language*. https://dhall-lang.org/
17. *Dhall Documentation — Dhall documentation*. https://docs.dhall-lang.org/
18. *Language Tour — Dhall documentation*. https://docs.dhall-lang.org/tutorials/Language-Tour.html
19. *dhall — Homebrew Formulae*. https://formulae.brew.sh/formula/dhall
20. *Dhall.Tutorial - Haskell*. https://hackage-content.haskell.org/package/dhall-1.42.3/docs/Dhall-Tutorial.html
21. *Pkl 公式サイト*. https://pkl-lang.org/
22. *Pkl :: Pkl Docs Pkl Docs https://pkl-lang.org*. https://pkl-lang.org/index.html
23. *pkl-core Library :: Pkl Docs Pkl Docs https://pkl-lang.org › main › current › pkl-...*. https://pkl-lang.org/main/current/pkl-core/index.html
24. *CLI :: Pkl Docs*. https://pkl-lang.org/main/current/pkl-cli/index.html
25. *Project (pkl:0.31.1) • Packages - pkl-lang*. https://pkl-lang.org/package-docs/pkl/current/Project/index.html
26. *Jsonnet - Jsonnet Configuration Language*. https://jsonnet.org/
27. *Standard Library*. https://jsonnet.org/ref/stdlib.html
28. *google/jsonnet - The data templating language*. https://github.com/google/jsonnet
29. *google/go-jsonnet*. https://github.com/google/go-jsonnet
30. *Jsonnet コンパイラを書いて Kubernetes のマニフェスト生成 ...*. https://blog.anqou.net/2024/08/jitsonnet
31. *Structs | CUE*. https://cuelang.org/docs/tour/types/structs/
32. *NixOS Manual*. https://nixos.org/manual/nixos/stable/index.html#sec-writing-modules
33. *NixOS Manual*. https://nixos.org/manual/nixos/stable/index.html#sec-options-common-module
34. *NixOS Manual*. https://nixos.org/manual/nixos/stable/index.html
35. *Module System and Custom Options - NixOS & Flakes Book*. https://nixos-and-flakes.thiscute.world/other-usage-of-flakes/module-system
36. *nixpkgs/nixos/modules/services/databases/postgresql.nix at master · NixOS/nixpkgs · GitHub*. http://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/databases/postgresql.nix
37. *NixOS search - Official NixOS Wiki*. https://wiki.nixos.org/wiki/NixOS_search
38. *Are there better alternatives to the impermanence module?*. https://discourse.nixos.org/t/are-there-better-alternatives-to-the-impermanence-module/64701
39. *NixOS Search - Packages*. http://search.nixos.org/
40. *A module (or config file) that adds config options, system ...*. https://discourse.nixos.org/t/a-module-or-config-file-that-adds-config-options-system-packages-and-python-packages/21705
41. *Flakes - NixOS Wiki*. https://nixos.wiki/wiki/flakes
42. *NixOS Modules Explained*. https://www.reddit.com/r/NixOS/comments/1kdephe/nixos_modules_explained
43. *NixOS system configuration - Official NixOS Wiki*. https://wiki.nixos.org/wiki/NixOS_system_configuration
44. *Evaluation Commands | apple/pkl | DeepWiki*. https://deepwiki.com/apple/pkl/3.1-evaluation-commands
45. *Pkl Apple's Open Source Project : r/rust*. https://www.reddit.com/r/rust/comments/1ay7i3a/pkl_apples_open_source_project
46. *PKL App - App Store - Apple*. https://apps.apple.com/us/app/pkl-app/id6759809423
47. *Disjunctions - CUE*. https://cuelang.org/docs/tour/types/disjunctions
48. *Conjunction vs. Disjunction in Math | Overview & ...*. https://study.com/academy/lesson/logical-math-connectors-conjunctions-and-disjunctions.html
49. *In logic, a disjunction is a compound statement formed by joining two propositions with the word "or". Symbolized as*. https://www.varsitytutors.com/hotmath/hotmath_help/topics/disjunction
50. *Store version separately from hash in integrity checks #335*. https://github.com/dhall-lang/dhall-lang/issues/335
51. *dhall-lang/standard/binary.md at master · dhall-lang/dhall-lang*. https://github.com/dhall-lang/dhall-lang/blob/master/standard/binary.md
52. *SHA-256 File Integrity Checker -- Free Online Tool*. https://eakondratiev.github.io/sha256.htm
53. *Dhall.TypeCheck - hackage-content.haskell.org*. https://hackage-content.haskell.org/package/dhall-1.42.3/docs/Dhall-TypeCheck.html
54. *RecordSub: Subtyping with Records - Software Foundations*. https://softwarefoundations.cis.upenn.edu/plf-current/RecordSub.html
55. *Output Formats*. https://jsonnet.org/articles/output-formats.html
56. *google/go-jsonnet*. http://github.com/google/go-jsonnet
57. *Jsonnet - Language Design*. https://jsonnet.org/articles/design.html
58. *http://github.com/google/go-jsonnet/releases*. http://github.com/google/go-jsonnet/releases
59. *Jsonnet native functions - Qbec qbec.io https://qbec.io › reference › json...*. https://qbec.io/reference/jsonnet-native-funcs
60. *Syntax - Nickel*. https://nickel-lang.org/user-manual/syntax
61. *Contracts in Nickel*. https://nickel-lang.org/user-manual/contracts
62. *Programming with contracts in Nickel - Tweag*. https://tweag.io/blog/2021-01-22-nickel-contracts
63. *The Syntax Bikeshedding Dojo, round 9: optional & merge ...*. https://github.com/tweag/nickel/issues/922
64. *Releases · nickel-lang/nickel - GitHub*. https://github.com/tweag/nickel/releases
65. *Flakes - NixOS Wiki*. https://nixos.wiki/wiki/Flakes
66. *Nix flakes*. https://zero-to-nix.com/concepts/flakes
67. *Nickel*. https://nickel-lang.org/user-manual/merging
68. *NixOS modules system - NixOS Wiki*. https://nixos.wiki/wiki/NixOS_modules_system
69. *rfcs/rfcs/0136-stabilize-incrementally.md at master · NixOS ...*. https://github.com/NixOS/rfcs/blob/master/rfcs/0136-stabilize-incrementally.md
70. *Releases - Nix Reference Manual*. http://nix.dev/manual/nix/2.24/release-notes
71. *About Determinate Systems*. http://determinate.systems/about
72. *RFC: Start using stable branches tied to Nixpkgs releases · Issue #727*. https://github.com/nix-darwin/nix-darwin/issues/727
73. *About N-iX: Company Overview*. http://n-ix.com/company-overview
74. *JSON Schema Discriminator: oneOf, Ajv & OpenAPI*. https://jsonic.io/guides/json-schema-discriminator
75. *A Media Type for Describing JSON Documents*. https://json-schema.org/draft/2020-12/json-schema-core
76. *Polymorphism with Discriminator Properties - Corvus.Text.Json ...*. https://corvus-oss.org/Corvus.JsonSchema/examples/polymorphism-with-discriminators.html
77. *Json schema | Pydantic Docs*. http://docs.pydantic.dev/2.3/usage/json_schema
78. *Json schema | Pydantic Docs*. http://docs.pydantic.dev/2.5/concepts/json_schema
79. *Starlark Language*. https://bazel.build/rules/language
80. *KCL: A Programming Language for Parametric CAD*. https://zoo.dev/research/introducing-kcl
81. *Configurations - Bazel 3.1.0*. http://docs.bazel.build/versions/3.1.0/skylark/config.html
82. *Rules*. https://bazel.build/extending/rules
83. *starlark/spec.md at master*. https://github.com/bazelbuild/starlark/blob/master/spec.md
84. *CiliumNetworkPolicy egressDeny blocking non-matching ...*. https://github.com/cilium/cilium/issues/28136
85. *Execute untrusted code in isolated microVMs - InstaVM*. http://instavm.io/solutions/code-execution
86. *Policy Enforcement Modes*. https://docs.cilium.io/en/latest/security/policy/intro
87. *Nix shell sandboxes - NixOS4Noobs*. https://jorel.dev/NixOS4Noobs/nixsandboxes.html
88. *GitHub - bureado/awesome-agent-runtime-security: Learning something new about runtime security for agents · GitHub*. http://github.com/bureado/awesome-agent-runtime-security
89. *Understanding NixOS Modules and Declaring Options*. https://britter.dev/blog/2025/01/09/nixos-modules
90. *nixpkgs/nixos/modules/services/misc/forgejo.nix at master · NixOS/nixpkgs · GitHub*. http://github.com/nixos/nixpkgs/blob/master/nixos/modules/services/misc/forgejo.nix
91. *NixOS: default = {} for submodule not respected #112494 - GitHub*. https://github.com/NixOS/nixpkgs/issues/112494
92. *NixOS modules - Official NixOS Wiki*. https://wiki.nixos.org/w/index.php?title=NixOS_modules
93. *Host Filesystem Sharing · Issue #1180 · firecracker-microvm ...*. https://github.com/firecracker-microvm/firecracker/issues/1180
94. *Running containers on Firecracker microVMs using kata on ...*. https://blog.cloudkernels.net/posts/kata-fc-k3s-k8s
95. *virtiofs: virtio-fs host<->guest shared file system*. https://docs.kernel.org/filesystems/virtiofs.html
96. *Virtio-fs: shared file system for virtual machines | Hacker News*. https://news.ycombinator.com/item?id=19100365
97. *What is Firecracker?*. https://browserbase.com/blog/what-is-firecracker
98. *Semantic Cue | Springer Nature Link*. https://link.springer.com/rwe/10.1007/978-0-387-79948-3_921
99. *cue/doc/ref/spec.md at master · cue-lang/cue · GitHub*. https://github.com/cue-lang/cue/blob/master/doc/ref/spec.md
100. *How to write a new .nix config file for packages?*. https://stackoverflow.com/questions/54615229/how-to-write-a-new-nix-config-file-for-packages
101. *NixOS Installation - Dank Linux*. https://danklinux.com/docs/dankmaterialshell/nixos
102. *Security :: Pkl Docs - pkl-lang.org*. https://pkl-lang.org/security.html
103. *Threat Model :: Pkl Docs - pkl-lang.org*. https://pkl-lang.org/threat-model.html
104. *Code generation :: Pkl Docs*. https://pkl-lang.org/go/current/codegen.html
105. *Flakes inputs with custom nixpkgs - Help - NixOS Discourse*. https://discourse.nixos.org/t/flakes-inputs-with-custom-nixpkgs/46093
106. *Flakes — nix.dev documentation*. https://nix.dev/concepts/flakes.html
107. *Use a local directory as flake input*. http://nixos.asia/en/howto/local-flake-input
108. *Running Reproducible Rust: A Fly and Nix Love Story*. https://community.fly.io/t/running-reproducible-rust-a-fly-and-nix-love-story/3781
109. *Nix for DevOps — Reproducible Development Environments ...*. https://devopsboys.com/blog/nix-reproducible-devops-environments-guide-2026
110. *firecracker/docs/getting-started.md at main - GitHub*. https://github.com/firecracker-microvm/firecracker/blob/main/docs/getting-started.md
111. *Firecracker*. https://firecracker-microvm.github.io/
112. *GitHub - firecracker-microvm/firecracker: Secure and fast microVMs for serverless computing. · GitHub*. http://github.com/firecracker-microvm/firecracker
113. *Dhall | nixpkgs - GitHub Pages*. https://ryantm.github.io/nixpkgs/languages-frameworks/dhall
114. *Safety Guarantees — Dhall documentation*. https://docs.dhall-lang.org/discussions/Safety-guarantees.html
115. *nixpkgs-local/doc/languages-frameworks/dhall.section.md at ...*. https://github.com/Cobertos/nixpkgs-local/blob/master/doc/languages-frameworks/dhall.section.md
116. *dhall-lang/standard/imports.md at master · dhall-lang/dhall-lang*. https://github.com/dhall-lang/dhall-lang/blob/master/standard/imports.md
