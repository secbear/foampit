# Research and Evidence Standard

Status: **Locked research protocol**

Locked: 2026-07-25

This protocol applies to every research-dependent greenfield design decision.
It exists to prevent the design from following only familiar production
patterns, only current vendor ergonomics, or only novel research. Each of
those evidence classes answers a different question.

## Required Evidence Classes

Every material research decision must investigate all applicable classes:

1. **Current primary contracts** — normative specifications, official API
   references, source repositories, and current provider documentation. These
   establish what an integration can rely on now.
2. **Proven production patterns** — architectures with material operational
   history. These establish failure modes, recovery techniques, and concepts
   that survived real use.
3. **Recent academic and novel work** — normally a rolling five-year search
   plus relevant newer preprints, prototypes, and standards proposals. Older
   foundational work remains in scope. This class exposes designs that may
   outperform established practice or reveal future requirements.
4. **Adversarial counterexamples** — systems whose semantics conflict with the
   emerging recommendation. A decision is incomplete until it explains those
   cases rather than averaging them away.

One class cannot stand in for another. A provider API does not establish a
portable semantic law. A production precedent does not prove that a newer
architecture is irrelevant. A paper or prototype does not establish production
availability, compatibility, or an operational guarantee.

## Source and Maturity Rules

- Prefer primary sources. Secondary analysis may locate evidence but must not
  be the sole authority for a normative claim when a primary source exists.
- Record the source URL, the fact it supports, the date reviewed, and its
  maturity class.
- Label peer-reviewed work, preprints, experimental implementations,
  standards proposals, and production contracts distinctly.
- Verify temporally unstable facts against current sources at decision time.
- Separate documented guarantees from observed behavior and from design
  inference.
- Cite negative and contradictory evidence, not only supporting evidence.
- When documentation is ambiguous and the behavior is decision-critical, plan
  or perform a minimal reproducer against the real system. Passing unit tests or
  a compatible mock is not a substitute.
- Do not promote an implementation detail shared by several providers into the
  portable contract unless the product actually requires that semantic.

## Required Decision Record

Each locked research decision must contain:

- the exact question and scope;
- the alternatives seriously considered;
- the selected semantics and their normative consequences;
- an evidence matrix covering the applicable classes above;
- provider or target counterexamples;
- safety, correctness, portability, and feasibility rationale;
- limitations and intentionally deferred behavior;
- invalid states or invariant families introduced by the decision;
- experiments or conformance tests needed before implementation closure; and
- unresolved questions that keep the containing design packet open.

The record must make it possible for a later reviewer to distinguish:

```text
source fact
  -> design inference
  -> locked product rule
  -> planned enforcement
  -> verified implementation evidence
```

These stages may never be collapsed into “researched” or “supported.”

## Review Discipline

For questions with independent evidence streams, research should proceed in
parallel and be reconciled only after each stream records its own conclusion.
At least one review pass must attempt to falsify the preferred design using:

- a provider with different lifecycle semantics;
- a target with weaker capabilities;
- retry, timeout, disconnection, and partial-failure scenarios;
- stale actors and ownership handoff;
- snapshot, restore, clone, or migration where relevant; and
- a recent architecture that challenges the assumed resource boundary.

Research completeness is not measured by citation count. It is measured by
whether the decision survives the declared state space and whether every
material conclusion can be traced to evidence of the appropriate maturity.

## Relationship to Implementation Gates

This protocol governs design evidence. It does not close the invariant or
implementation gates defined in
[Invariant Inventory and Enforcement Protocol](./INVARIANT-ENFORCEMENT.md).

A research-backed rule still needs:

- a stable invariant identifier;
- an authoritative enforcement boundary;
- valid and invalid witnesses;
- target and trust-boundary applicability;
- executable diagnostics and tests; and
- real conformance evidence before the implementation can claim support.

Adding materially different provider behavior or relevant new research may
reopen a decision. Reopening requires a recorded contradiction or changed
assumption; it does not permit silently weakening a locked contract.
