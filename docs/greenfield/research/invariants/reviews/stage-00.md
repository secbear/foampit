# Stage 00 review — Packet E assurance feasibility

Disposition: **accepted**

This record accepts only the blocker-first feasibility spike required by
Stage 00 of the Packet E operation-contract inventory plan. It does not promote
spike semantic code, close Gate 2A or Gate 4B, select a production runtime
language/store, or claim backend, hostile-input, cross-platform, power-loss, or
storage-device correctness.

## Reviewed subject

- Plan:
  `docs/greenfield/plans/2026-07-28-packet-e-operation-contract-inventory.md`
- Plan SHA-256:
  `74b47b0fc518e23f554c95d9b39a702db29db6f87ba1e08511c2811ec7e08835`
- Execution base:
  `75e20ea96309a2328561bbc3e4b004aae6d724c6`
- Execution-base tree:
  `2bdb0f9b8bfa85124218990d0f618d4ff6a188d7`
- Final reviewed subject commit:
  `34b86f69946965ed095523c93ac56e89b463e452`
- Final reviewed subject tree:
  `be0b7d1f9cb54b96660eeb9f7ba902c0b9f37dd5`

The review record is an evidence-only successor. It is not part of the reviewed
subject and must not be substituted for the subject identity above.

## Feasibility claims accepted

1. Two deliberately small, closed catalog documents can be normalized to exact
   canonical bytes while an independently implemented checker detects omitted
   semantic fields, changed selector/profile/reference/import/order semantics,
   constant output, normalizer/checker co-drift, forbidden dependency paths,
   source/model digest drift, and the exercised ambient-authority attacks.
2. Lean can consume byte-bound proof material and kernel-check the six required
   feasibility declarations without `sorry`, `admit`, project semantic axioms,
   hidden semantic premises, unclassified transitive axioms, or unpinned Lean
   libraries.
3. The SQLite WAL reference can model and exercise process-crash atomicity for
   atomic log append, attempt-state compare-and-swap, slot-head
   compare-and-swap, and conflict-resolution multi-CAS. Every exercised kill
   point reopens to exactly the predecessor or complete successor state.
4. The assurance toolchain can be pinned through Nix to exact revisions,
   derivations, library bytes, and command versions on `aarch64-darwin`.

These are feasibility claims. Later stages must independently implement the
production catalogs, authorities, inventories, proofs, trust envelopes, and
durable state.

## Exact toolchain

The complete authoritative version, derivation, store-path, library, and source
inventory is:

`docs/greenfield/research/prototypes/packet-e-assurance-spikes/toolchain.json`

Its SHA-256 is
`3d779bcf70af6807c594131b2fa964c6e449c1a14cca77cc0feb1dc93ee7adce`.
The flake lock SHA-256 is
`7cda4dfb09a5c041b5cb1fb1f3ef70aa1592b85ca23d93c639a0e4976b6adcd9`.

Pinned command versions:

- Nix `2.34.7`;
- Nixpkgs revision
  `624af665418d3c65d544145b4d34ad696439570e`;
- Node.js `22.23.1`;
- jq `1.8.2`;
- CUE `0.17.1`;
- Lean `4.30.0` and Lake `5.0.0-src+v4.30.0`;
- `check-jsonschema` `0.37.4`;
- Python `3.13.14`; and
- SQLite/Python SQLite module `3.53.3`.

The manifest additionally pins the `Init` and `Std` `4.30.0` `.olean` bytes and
every relevant Nix output and derivation path. Later tooling must reproduce the
manifest rather than copying this prose.

## RED evidence

The initial candidate was developed test-first. Subsequent adversarial findings
also received pinned test-only RED replays before their fixes. All five replay
bundles were freshly exercised against their exact historical bases and exited
zero:

- round one patch:
  `12113c290d212c74b10ca0c8f20a3475837e8fbff631b62c572566b533fee107`;
- round three patch:
  `61a1e213e7c9a192bcc3c58be07a3de101f3e0a7e858e99c50ac88f895926445`;
- round four patch:
  `8e45e296292a5a47d3e541c49b6b6731a85c49aeb0248851ff172dbc2b0263b5`;
- round five patch:
  `a98cf9ff5985d653e706dfd7a568c5bfa992eb34467c259c9362a794362feb5e`;
  and
- post-limit patch:
  `322db8f641d273d33c32e30d67d2a984d90bec2598b300a8bb598dabc7026635`.

The post-limit bundle distinguishes its evidence honestly: three
sensitive-property failures bind isolated-child property-state observations;
the unsupported-key failure is static-only evidence that the historical audit
did not fail closed outside its accepted syntax subset.

## Final verification

The following commands were run from the clean reviewed subject:

```sh
nix develop ./docs/greenfield/research/prototypes/packet-e-assurance-spikes \
  --command ./docs/greenfield/research/prototypes/packet-e-assurance-spikes/run.sh

bash docs/greenfield/research/prototypes/packet-e-assurance-spikes/fix-post-limit-red-replay/replay.sh

./tests/standalone-contract-compiler.sh

nix flake check --print-build-logs \
  ./docs/greenfield/research/prototypes/packet-e-assurance-spikes
```

Observed results:

- toolchain: 7 tools attested; all 6 provenance mutations killed;
- normalization: 49/49;
- formal: 38/38, six declarations, zero axioms,
  `proofElapsedMs=15549.4`;
- durability: 14/14;
- process-kill schedule: 5 atomic-log-append kills, 5 attempt-state-CAS kills,
  5 slot-head-CAS kills, and 7 conflict-resolution multi-CAS kills;
- replay cleanup: 8 cases across both wrappers, 16/16;
- focused semantic/formal/durability total: 101/101;
- total explicit spike checks including toolchain mutations and replay cleanup:
  123/123;
- artifact hygiene: passed;
- post-limit pinned replay: passed with its exact base and patch identity;
- standalone contract-compiler preflight: passed; and
- Nix flake evaluation/check: `all checks passed!`.

The reviewed tree also passed `git diff --check`, language syntax/parse checks,
generated-artifact absence checks, exact review-package comparisons, candidate
scope checks, clean tracked status, and exact one-worktree inventory.

## Adversarial finding and resolution chain

The initial Stage 00 candidate was
`6462aa751470cdd08d49f1792432871a17d35fb3`. Adversarial review forced five
candidate hardening rounds plus one explicitly recorded post-limit correction:

1. `2fdf5fb6d2e711040503132fa937d6d0cdc08049` bound exact proof material,
   arbitrary carriers, symbolic coverage, SQLite sequences, read-only
   observation, and literal evidence.
2. `8389224046bd2c8c1c56f5e113bdae2aca2d68e9` added missing-pin mutations,
   exact Lean-library provenance, historical RED replay, artifact hygiene, and
   direct loader cases.
3. `2eb96731e6d4ea4f143cd607fbaa2f92ad34da69` closed forged Lean-declaration
   exemptions, transitive metadata gaps, container/alias capability attacks,
   and replay temporary-path confinement.
4. `7373f4d97dcdb30992875743484de6f0d5b9e51e` closed ambient
   Function/AsyncFunction and network authority, added layered Node hardening,
   and made exact cleanup fail closed without repository-wide pruning.
5. `94aa7a0a2a1476f451b99bd167523361e435a774` closed unresolved computed
   properties, builtin re-export authority, runtime-omission replay fidelity,
   and cleanup-contract overstatement.
6. `cbed8f70fd4e66a0f92ff797d1c8b8dbadedbf2d` unified semantic
   classification for computed and noncomputed object properties and rejected
   sensitive `__proto__`, `constructor`, and `prototype` paths.
7. `34b86f69946965ed095523c93ac56e89b463e452` corrected the final replay
   README so dynamic and static evidence are not conflated.

Every blocker or major finding was reproduced or directly verified before
being fixed. No blocker or major remains open.

## Final independent verdicts

Three read-only adversarial reviewers inspected the exact correction range
`cbed8f70fd4e66a0f92ff797d1c8b8dbadedbf2d..34b86f69946965ed095523c93ac56e89b463e452`
through an immutable diff package with SHA-256
`ffe402ef145d9553297681abf974d4c332afd27c913379bde382e9d441c5a7d6`.
Each independently verified that package against `git diff --binary`.

- semantic evidence / Goodhart / omission: `clean`;
- security assurance / regression: `clean`; and
- formal / reproducibility / evidence identity: `clean`.

The final verdicts specifically confirmed the corrected child-backed versus
static-only distinction, current commit/tree/artifact hashes, unchanged replay
identity, documentation-only correction scope, and absence of evidence
weakening.

## Blast radius

Checked:

- both audited one-module JavaScript graphs and all 49 normalization cases;
- sensitive computed and noncomputed property/member paths, builtin re-exports,
  ambient constructors/network globals, lexical shadowing controls, and
  fail-closed unsupported property forms in the deliberately closed subset;
- all six Lean declarations, their elaborated signatures, transitive
  dependency/axiom closure, tool/library provenance, and 38 formal mutations;
- all four SQLite transitions, 22 process kills, sequence rejection, exact
  schema observation, and model/store drift mutations;
- all five historical replay bundles and all sixteen cleanup-wrapper
  scenarios;
- the Nix flake, standalone compiler regression, artifact hygiene, exact
  candidate/review identities, and current repository cleanliness.

Not checked and not claimed:

- arbitrary ECMAScript or future parser node forms outside the closed spike
  subset;
- arbitrary future Lean declarations or any other Lean/Node/toolchain version;
- non-Darwin execution, concurrent external Git metadata mutation, resource
  exhaustion, or uncatchable machine/process termination;
- power loss, kernel panic, filesystem corruption, short writes, `ENOSPC`,
  device caches, storage hardware, load, or concurrency;
- production catalog/tooling integration, foreign trust material, actual
  backend measurements/conformance, or later-stage artifacts; and
- Gate 2A, Gate 4B, backend-support, or general sandbox-soundness claims.

## Residual risks

- The Node-internal Acorn parser is pinned feasibility-only tooling. It requires
  a separate dependency decision before any production use.
- The JavaScript audit intentionally fails closed. Benign syntax outside the
  accepted identifier/string/computed-string subset must be rewritten or
  explicitly reviewed.
- Runtime, cleanup, and durability evidence is local to Node `22.23.1`,
  Lean `4.30.0`, Git/Nix behavior, and `aarch64-darwin`.
- Process-crash SQLite atomicity is narrower than persistent-storage
  durability.
- Stage 00 proves that the assurance approach is feasible; it does not prove
  the future production implementation correct.

## Acceptance

Stage 00 is **accepted**. Its feasibility stop conditions did not trigger:
the final evidence does not require shared semantic code, unchecked axioms,
bounded substitutes for the required universal statements, or non-atomic
recovery assumptions.

Stage 01 may begin from the separate evidence-only commit containing this
record.
