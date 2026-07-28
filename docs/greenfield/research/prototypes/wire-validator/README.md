# Provisional Portable-Value Validator

Status: **Disposable comparison implementation; not a public schema or wire
standard**

This prototype implements the language-neutral `W0` boundary from the
configuration-language corpus. It exists to test a product invariant that no
authoring language can prove alone:

> Corrupted, hand-authored, or buggy frontend output cannot become Nix build
> input until one product-owned validator has accepted the complete portable
> Artifact value.

The field names, JSON shape, diagnostic serialization, comparison-encoding
identity, and Rust package name are intentionally provisional. They do not lock
public API names.

## Boundary Under Test

The implementation distinguishes three representations:

```text
Artifact Definition source
  -> frontend evaluation, profile expansion, and source-aware validation
  -> fully concrete portable Artifact value
  -> duplicate-safe decode + shared W0 semantic validation + comparison digest
  -> product-owned Nix construction with pinned Nix references/native handles
  -> built Sandbox Artifact Set and built manifest
```

The middle value is a compiler/trust-boundary representation. It is not the
deployable Artifact Set and it is not a generic `ResolvedPlan`.

- It contains only Artifact-owned, language-neutral semantics.
- It contains stable Nix input/attribute or registered native-handle
  references, not serialized derivations, Nix functions, or generated Nix
  source.
- It does not contain resolved store paths as if they were source identities.
- It contains no `CreateSandbox`, operator, host, provider, framework, or live
  process values.
- Nix construction resolves its typed references and emits target artifacts
  plus a built manifest containing the resulting store identities and
  construction evidence.

This separation lets a flake remain the deterministic producer of the
deployable Artifact Set while giving every possible authoring frontend the same
independent semantic gate before Nix construction.

The executable comparison schema now carries all semantics exercised by the
first common slice, including hard policy, allowed materializations, derived
required capabilities, runtime profiles, targets, packages, environment,
workspace, network, secret slots, and memory bounds. It still omits profile
origin/digest metadata, target-advertised capability records, native handles,
guest summaries, target-specific additions, the unimplemented resource kinds,
and the separate provenance record. Its shared digest proves equivalence for
the complete implemented slice, not the final Artifact identity.

## Implemented Checks

The current executable cases prove:

- object keys are checked for duplicates during recursive decoding, before a
  generic JSON map can discard one value;
- an unsupported schema major never falls back;
- records are closed at every implemented portable record;
- the extension object does not act as an untyped escape hatch: this comparison
  version registers no extensions and rejects every supplied identity;
- secret values are rejected and redacted where only slot descriptors belong;
- byte quantities reject non-integral numbers;
- workspace destinations are normalized absolute paths;
- disabled networking cannot carry egress rules;
- effective egress cannot widen the immutable hard-policy destinations;
- the selected materialization must be one of the Artifact-allowed
  alternatives;
- derived required capabilities must match normalized network/workspace
  semantics;
- every enabled target must implement every required capability;
- runtime profiles must reference enabled targets and allowed
  materializations;
- at least one target remains after normalization;
- key order and insignificant JSON formatting produce identical comparison
  bytes and SHA-256.

Every semantic rejection is serialized as a structured prototype diagnostic
with a stable invariant identity, one configuration owner, actual product
phase, primary and related paths, secret-safe actual values, constraint,
remediation, and a preserved cause chain.

## Comparison Encoding

`artifact-comparison-json-v0` is intentionally narrower than a standards claim:

- object keys are emitted in lexicographic UTF-8 string order;
- array order is preserved;
- no insignificant whitespace or trailing newline participates in the digest;
- JSON string escaping is deterministic;
- the typed comparison schema restricts quantities to unsigned integers;
- SHA-256 is computed over exactly those emitted Artifact bytes.

This is not claimed to implement RFC 8785 or any final public encoding. Unicode
normalization, the complete number domain, schema migration, extension
registration, and compatibility rules remain ADR work. The result envelope and
its newline are not part of the digest.

## Run

```sh
./test.sh

cargo run --quiet -- check fixtures/valid.json
```

Invalid input writes exactly one diagnostic JSON object to stderr, no Artifact
data to stdout, and exits nonzero. Valid input writes the validated Artifact
value, comparison-encoding identity, and digest.

The next integration step is to route every serious language prototype through
this implementation before the shared Nix bridge. Frontends may reject the
same state earlier and may attach better source spans, but they may not own a
second copy of the final semantic rules.
