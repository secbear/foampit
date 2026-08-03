# Packet E Operation Contract Review

Status: **Reviewed — Packet E inventory walk complete; Gate 4B not closed**

Date: 2026-08-03

This is the Packet E decision record. The obligation partition and its
adversarial history are in
[`PACKET-E-OBLIGATION-PARTITION-REVIEW.md`](./PACKET-E-OBLIGATION-PARTITION-REVIEW.md);
this document records the rulings, the machine records, and what Packet E does
and does not close.

## Normative machine records

| Record | SHA-256 |
|---|---|
| [`PACKET-E-OPERATION-REGISTRY.json`](./PACKET-E-OPERATION-REGISTRY.json) | `7612e8d346072e217b7a9107fea17d9ce79e60559d09db36f6de77ccad5a7ce5` |
| [`PACKET-E-CASE-CONTRACTS.json`](./PACKET-E-CASE-CONTRACTS.json) | `e9dde541702c02370b37e6dc844a58fd79acca5edd4faa4966241e00885e0ba9` |
| [`PACKET-E-OPERATION-CONTRACTS.json`](./PACKET-E-OPERATION-CONTRACTS.json) | `f06954ab1d9b28aca8d2fa06ef4b18744faa5b090ba85374f62923470083933f` |
| [`PACKET-E-CONCURRENCY-MATRIX.json`](./PACKET-E-CONCURRENCY-MATRIX.json) | `dc1a17677fe3a7105811fc6928852ef5b98ff0b4fd5ae33922e4b04a15cdffd9` |
| [`PACKET-E-OBLIGATION-PARTITION.json`](./PACKET-E-OBLIGATION-PARTITION.json) | `b5946aacc93563461b59b60dc19a7601a36e28a96a56960e4afaee1dbd238f3f` |
| [`validate-operation-contracts.jq`](./validate-operation-contracts.jq) | `fd6915526b632bb7ea0722496a19a93c31af2e569d326b23d41965e87d07545f` |
| [`test-operation-contracts.sh`](./test-operation-contracts.sh) | `0fee8d36bf7f7f0b70f303177d84dc193e8ddd8398d9b7b89d100b35534a6520` |

Explanatory prose may not override their closed control fields. The machine
records carry `status: "candidate"`; `Reviewed` is the decision recorded here,
not a claim that Gate 4B is closed.

## Rulings

1. **A ninth owner, `core`,** for the Core Sandbox API control plane: durable
   Operation acceptance and records, identity and coordinate allocation,
   authority fencing, idempotency binding, terminal-outcome commitment,
   retention, reconciliation. Every existing `runtime` entry is `DRV-*`/`WIRE-*`
   at the driver boundary, so overloading it would have made that family mean
   two things at two phases.
2. **No phase or edge added.** The product-phase graph is a validation-order
   model over a single traversal, not runtime history. Every candidate restart
   edge creates a cycle *and* makes `L0 -> E0` reachable, contradicting the
   protocol. An operation that authorizes another begins a new traversal linked
   by a handoff record.
3. **Specification-totality meta-rules became validator rules** over the ledger
   rather than registry entries, following Packet C and D precedent.
4. **The locked token `unknown` is namespaced** in ledger encodings as
   `state-unknown` and `outcome-unknown`, because every ledger validator rejects
   `^UNKNOWN$` case-insensitively as placeholder content. Vocabulary entries
   carry a `lockedSourceRef` document anchor so the correspondence is checkable
   rather than implicit.
5. **The ledger has two axes** — operations × lifecycle states — with every
   other locked dimension factored into ordered value cases. Both prior packets
   pick exactly two axes.
6. **Task 7A declined.** No composition path has a boundary step at `R0`, `R1`,
   `L1`, `E1`, or `T0`, so extending the templates there would assert paths
   reach stations they do not.

## Scope

37 operations plus 4 deferral markers, 6 composite lifecycle states, 222
contract cells, 625 operation-pair concurrency cells, 214 registered invariants.

Invariant coverage: 201 governed by a generated operation contract, 1
(`FRK-005`) covered only by a stated absence, 12 assigned to the driver,
adapter, artifact, and service ledgers.

Delegations discharged: all 20 Packet A surfaces marked `delegatedPacket: "E"`,
all 5 Packet B fields delegating `"E"`, and Packet D's `operation-transition`,
`retry`, `cancellation`, and `cleanup` concerns.

## Evidence

`check-inventory.sh` exits 0 and reports the Packet E counters. The
operation-contract harness passes 64 mutation cases against the real shipped
ledgers, including coordinated regeneration. The generator asserts before its
single write, so a stale input makes generation impossible rather than merely
wrong.

Four cell-semantics anchors derive their expectation from separately authored,
separately pinned artifacts rather than comparing two copies of one fact, so a
coordinated catalog-plus-matrix rewrite does not satisfy them.

## What Packet E does not close

**Gate 4B.** All 354 authoritative hooks and 1,453 tests remain `planned`.
`check-enforcement-closure.sh` exits 5 and must.

**Gate 2A.** Packet F is unwalked, and the dynamic-state dimension row carries
an undischarged Packet E remainder — see the ruling below.

Known open work is enumerated in the `INVENTORY-REVIEW.md` Packet E section and
the exit-record fragment. The most significant is that one further semantic
anchor was designed, found three genuine defects, and could not ship: three
`SignalProcess`/`TerminateProcess` reject cells cite no invariant decidable at
an admission station, because no such invariant is registered.
