# Packet E blocker-first assurance spikes

Status: feasibility evidence only. Nothing in this directory is a production
catalog, semantic authority, normalization certificate, baseline, Gate 2A or
Gate 4B claim, or backend-support claim. The spike semantic code is not
promoted.

Run the complete suite from the repository root:

```sh
nix develop ./docs/greenfield/research/prototypes/packet-e-assurance-spikes \
  --command ./docs/greenfield/research/prototypes/packet-e-assurance-spikes/run.sh
```

The runner fails if the pinned toolchain drifts, any positive behavior fails,
any normalization/formal/durability mutation survives, or any killed SQLite
process recovers to a partial state.

## Measured result

The final 2026-07-29 Stage 00 round-four candidate run passed 85 focused
semantic/crash tests, six toolchain-provenance mutation tests, and twelve replay
cleanup wrapper-scenario checks:

| Group | Tests | Result |
| --- | ---: | --- |
| independent normalization | 33 | all passed |
| Lean kernel/interface audit | 38 | all passed |
| pure model/SQLite crash refinement | 14 | all passed |
| toolchain-provenance mutations | 6 | all killed |
| replay cleanup/TMPDIR confinement | 12 | all passed |

The positive Lean build plus exact-byte, elaborated-interface, transitive
dependency-identity, opaque-definition, and axiom-closure audit took 13,530.5
ms in the fresh full run. Six Lean declarations were kernel checked: the
proof-material translation binding and the five required theorem families.
Every required theorem reported an empty transitive axiom set.

## Independent normalization replay

`normalization/fixtures/catalog.json` and `foreign.json` are the exact closed
two-file source set. They exercise profile expansion, selectors, one local
reference, pinned foreign references/import bytes, and authored order that is
intentionally different from identifier order. The normalizer reads only
source fixtures and emits exact source bytes/digests, canonical model
bytes/digest, and per-source-leaf reachability proof material. It emits no
verdict, acceptance bit, certificate, or baseline.

The checker is separately implemented and imports no normalizer code. It
re-parses exact source bytes, verifies the pinned foreign digest, independently
replays selector/profile/reference/import/order semantics, reconstructs all 33
semantic leaf mappings, and unconditionally binds the exact source set and
literal expected canonical model bytes/digests. The dependency audit parses
ECMAScript syntax, resolves canonical real paths, walks static imports and
re-exports, and rejects cross-imports, shared semantic modules, symlink aliases,
dynamic or indirect loaders, and unpinned packages. It also builds lexical
program/block/function/loop scopes and rejects every unresolved identifier
except the closed ambient set actually used by the two modules. `Array`,
`Object`, and `JSON` admit only their exact direct data-operation members;
`Number`, `Error`, `Set`, and `Map` admit only their exact call/construction
shapes. The prior exact direct `process.argv`, named mutation-environment,
stdout/stderr, and exit operations remain the only admitted `process` uses.
The builtin import members are likewise closed to the exact read/crypto/path/
URL functions in the audited source.

The mutation matrix kills omitted reachability, selector/profile/reference/
import/order changes, constant output, normalizer/checker co-drift, forbidden
cross-import, source/model digest mismatch, and normalizer-issued verdict or
certificate output. It also kills coordinated source/model replacement and
comment-obfuscated/re-exported/symlinked/indirect dependency edges.
The capability-origin cases include the exact array storage/index recovery,
string-concatenated `getBuiltinModule`/`createRequire`, and multi-hop renamed
loader attack, plus object/destructuring and sequence-expression variants.
Round four adds exact AsyncFunction and function-prototype constructor escapes,
ambient `fetch` and `WebSocket`, a disallowed safe-global member, and a positive
lexical-shadowing control. Literal/template/concatenated constant property
names are resolved to reject `constructor`, `prototype`, and `__proto__`.

Pinned Node child invocations add defense in depth with exact read permissions,
string-code generation disabled, and Fetch/WebSocket globals disabled. The
suite proves that omitting any one of those four runtime controls exposes its
focused probe. A computed constructor key that the static constant evaluator
cannot resolve relies on the no-string-code-generation runtime backstop; this
is closed-source feasibility evidence, not a claim of complete constant
evaluation, general ECMAScript analysis, or arbitrary-input sandbox soundness.

## Replay cleanup boundary

All three retained RED replay wrappers use one shared cleanup implementation.
Initialization explicitly checks repository resolution, `mktemp`,
canonicalization, and child-directory creation before deriving a checkout
path. Each cleanup decision captures `git worktree list --porcelain` once and
treats query failure as cleanup failure. A registered target is removed only
with `git worktree remove --force` against its exact canonical path, with one
exact retry. The wrappers never invoke repository-wide prune or manually
delete a failed checkout.

Normal, fail-first removal, inventory-query failure, exact-removal failure,
child-status preservation after successful cleanup, and nonzero-child status
preservation during query failure are exercised against both wrappers in
disposable local repositories. Successful cleanup removes the exact
registration and wrapper root. An unresolved query/removal failure preserves
that exact registration/root for recovery; cleanup failure changes child
status zero to one, while a nonzero child status remains authoritative.

## Lean feasibility and audit boundary

`formal/proof-material.json` is canonical JSON containing the exact catalog
and model bytes as hexadecimal plus their literal digests, the complete
semantic carrier field list, symbolic shard count, and a kernel-checked solver
status. Lean embeds the exact canonical proof-material, catalog, and model bytes
with `include_str` into a typed `ProofMaterialTranslation`; every required
theorem returns a proposition containing `ProofMaterialBound`. The external
audit verifies every translated field against the fixtures, builds with the
pinned kernel, and uses Lean `Environment`, `Expr`, and `MetaM` inspection
rather than accepting pretty-printed text.

The kernel checks:

- an unbounded population-abstraction theorem;
- an induction-backed population symmetry theorem;
- mixed-family increment commutation;
- a proof-independent symbolic `CoverageShardSpec` theorem with universal
  pairwise disjointness, exhaustiveness, and exact per-shard cardinality
  witnessed by bijections for every population, with the returned spec's
  per-shard counts and total `2 * population` linked by proof; and
- contextual reduction quantified over an arbitrary full seven-field
  `SemanticCarrier`, another family, and interleavings, with a field-by-field
  relation over all seven fields.

The negative audit rejects `sorry`/`admit`, direct and transitive axioms, local
premises, conclusion-as-assumption, subtype/`Nonempty`/`Exists`/semantic
`Decidable`/typeclass/nested-`Type` smuggling, opaque semantic dependencies,
omitted source/model bytes, unknown procedures, unpinned/wrongly pinned
dependencies, and incomplete transitive dependency closure. Alias, arbitrary
proposition, implicit, private, and multi-hop transparent premise wrappers are
negative fixtures. Authored definitions are always checked strictly, including
adversarial `match_*`, `rec`, `casesOn`, and `noConfusion` spellings.
Compiler status is accepted only from Lean's non-forgeable `inductInfo`,
`ctorInfo`, and `recInfo` variants after exact family, parent, constructor,
rule, field-count, and binder-count checks; only the exact recursor
motive/minor positions are mechanical. The actual compiler recursor is a
positive fixture. The only imported libraries are exact
SHA-256-pinned `Init` and `Std` objects from the same pinned Lean store
derivation.

## SQLite process-crash refinement

The pure Python model and SQLite implementation cover atomic log append,
attempt-state CAS, slot-head CAS, and conflict-resolution multi-CAS. The store
uses effective `journal_mode=WAL`, `synchronous=FULL`, `foreign_keys=ON`, and
`wal_autocheckpoint=0`; the suite asserts those values after connection.

Every operation runs in a separate subprocess. The driver waits for the exact
fault marker, sends `SIGKILL`, waits for process termination, reopens the
database, reads every row of every semantic table, and compares the complete
observable state with independently computed pure predecessor and successor
values.

| Operation | Fault-point schedule | Kills | Recovered predecessor / successor |
| --- | --- | ---: | ---: |
| log append | `before-begin`, `after-begin`, `after-log-insert`, `before-commit`, `after-commit-before-reply` | 5 | 4 / 1 |
| attempt CAS | `before-begin`, `after-begin`, `after-attempt-cas`, `before-commit`, `after-commit-before-reply` | 5 | 4 / 1 |
| slot-head CAS | `before-begin`, `after-begin`, `after-slot-head-cas`, `before-commit`, `after-commit-before-reply` | 5 | 4 / 1 |
| conflict multi-CAS | `before-begin`, `after-begin`, `after-each-conflict-attempt-cas:1`, `after-each-conflict-attempt-cas:2`, `after-slot-head-cas`, `before-commit`, `after-commit-before-reply` | 7 | 6 / 1 |
| **Total** | every transaction statement boundary | **22** | **18 / 4** |

Normal, non-killed execution also equals the pure successor for all four
operations. A mutation that commits each conflict update separately is
detected as partial recovery, and a store/model drift mutation is rejected.
Future, stale, and duplicate log sequences are rejected with the pure model's
`log/predecessor-mismatch` while leaving complete state unchanged. Recovery
observation opens the database read-only, requires the exact table/column
schema, and then reads all semantic tables; missing, extra, and altered schemas
are rejected without repair.

This result assumes one local filesystem, normal OS process termination
semantics, SQLite 3.53.3's documented WAL transaction behavior, successful
system calls, and enough storage. It claims process-crash transaction
atomicity only. It does **not** claim behavior under power loss, kernel crash,
filesystem or device failure, short write, `ENOSPC`, I/O error, device-cache
loss, hardware failure, or hostile concurrent database modification.

## Pinned toolchain

The flake locks Nixpkgs revision
`624af665418d3c65d544145b4d34ad696439570e`. The executable manifest
`toolchain.json` records every exact output/store derivation and is checked by
`run.sh`. The audit resolves each tool output's actual Nix deriver, requires
`lake` and bundled library objects under the Lean output, hashes the
`Init`/`Std` objects, and confirms the archived flake's Nixpkgs source identity.
Six coordinated manifest/PATH mutations exercise those checks.

| Tool | Version |
| --- | --- |
| Nix | 2.34.7 |
| Node.js | 22.23.1 |
| jq | 1.8.2 |
| CUE package | 0.17.1 (`cue version (devel)` from the pinned derivation) |
| Lean / bundled `Init` and `Std` | 4.30.0 |
| Lake | 5.0.0-src+v4.30.0 |
| check-jsonschema | 0.37.4 |
| Python | 3.13.14 |
| SQLite CLI and Python module | 3.53.3 |

## Stop conditions and limitations

Dependent Packet E stages must stop if productionization would require shared
normalizer/checker semantic code or expected output, any unclassified or
project semantic axiom, a hidden proof premise, bounded-only reasoning where
the design requires universality, an unpinned dependency, or a recovery
assumption that permits partial transaction state.

These deliberately small fixtures prove implementation feasibility, not full
production-domain completeness, performance at production catalog size,
portable behavior on another operating system/filesystem, or storage
durability beyond process termination. Later production tooling must reproduce
the committed toolchain identities and re-establish all authority, coverage,
governance, and review gates independently.
