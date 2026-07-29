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

The 2026-07-29 Stage 00 candidate run passed 41 focused tests:

| Group | Tests | Result |
| --- | ---: | --- |
| independent normalization | 14 | all passed |
| Lean kernel/interface audit | 19 | all passed |
| pure model/SQLite crash refinement | 8 | all passed |

The positive Lean build plus exact-byte, elaborated-interface, transitive
dependency, opaque-definition, and axiom-closure audit took 11,892.6 ms in the
recorded cumulative run. Six Lean declarations were kernel checked: the
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
semantic leaf mappings, compares the literal expected canonical model bytes,
and binds both byte sequences to their SHA-256 digests. The dependency audit
walks both module graphs and rejects cross-imports, shared semantic modules,
dynamic imports, and unpinned package imports.

The mutation matrix kills omitted reachability, selector/profile/reference/
import/order changes, constant output, normalizer/checker co-drift, forbidden
cross-import, source/model digest mismatch, and normalizer-issued verdict or
certificate output.

## Lean feasibility and audit boundary

`formal/proof-material.json` is canonical JSON containing the exact catalog
and model bytes as hexadecimal plus their literal digests, the complete
semantic carrier field list, symbolic shard count, and a kernel-checked solver
status. The external audit verifies those bytes against the normalization
fixtures, hashes the exact proof-material file, evaluates the bound Lean
translation constants, builds with the pinned kernel, and audits elaborated
interfaces rather than relying on source spelling.

The kernel checks:

- an unbounded population-abstraction theorem;
- an induction-backed population symmetry theorem;
- mixed-family increment commutation;
- a proof-independent symbolic `CoverageShardSpec` theorem with universal
  pairwise disjointness, exhaustiveness, and exact per-shard cardinality
  witnessed by bijections for every population; and
- contextual reduction quantified over a primary family, another family,
  interleavings, and the full seven-field `SemanticCarrier`.

The negative audit rejects `sorry`/`admit`, direct and transitive axioms, local
premises, conclusion-as-assumption, subtype/`Nonempty`/`Exists`/semantic
`Decidable`/typeclass/nested-`Type` smuggling, opaque semantic dependencies,
omitted source/model bytes, unknown procedures, unpinned dependencies, and
incomplete transitive dependency closure. The only imported libraries are
`Init` and `Std` from the same pinned Lean store derivation.

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
`run.sh`.

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
