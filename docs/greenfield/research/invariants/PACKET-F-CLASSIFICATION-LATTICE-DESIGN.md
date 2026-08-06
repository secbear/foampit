# Packet F: Classification and Audience Lattice

Status: **Proposed for lock — awaiting review. This is lock 1 of Packet F's
design phase; the disclosure frame, evidence integrity and retention, the
acquisition/reservation protocol, and authorization/tenancy are locked
separately and are not settled by this record.**

Proposed: 2026-08-04

Evidence reviewed: 2026-08-04. This date applies to every repository citation
below unless a row states otherwise.

This record fixes the structure every later Packet F rule is written against:
who can read a thing, where a thing may land, and what happens when two things
are combined. It locks no policy about any particular secret. It locks the
vocabulary in which such a policy can be stated at all, and the arithmetic that
makes a set of such statements checkable rather than merely plausible.

It is written after
[`PACKET-E-F-DISCLOSURE-SEAM.md`](./PACKET-E-F-DISCLOSURE-SEAM.md), which ruled
that the Packet E / Packet F dividing line is the **audience**, not the content.
That ruling named the line without enumerating what sits on either side of it.
This record enumerates it.

The research follows the locked
[Research and Evidence Standard](../RESEARCH-STANDARD.md).

---

## Question

Packet F must eventually state on the order of two hundred rules of the form
*"X may not appear in Y."* Written independently, such rules have three
failure modes that no amount of care prevents:

1. **They cannot be checked for totality.** Nothing distinguishes "we decided
   this content is fine here" from "nobody considered this pair." The
   repository already has 115 invariants touching Packet F territory and no way
   to say which channels they leave unconsidered.

2. **They do not compose.** If `sandbox-id` may appear in a log and `host-path`
   may not, no rule says what happens to a message containing both. Every real
   leak is a composition: the parts were each cleared, the whole was not.

3. **They drift toward a chain.** Prose reaches for "more sensitive" and
   "less sensitive," which presumes a total order. Foampit's principals are not
   totally ordered — a guest legitimately holds delivered secrets that an
   operator must never log, and an operator legitimately holds host paths that a
   guest must never learn. Neither is "more trusted." A chain forces one of
   those two facts to be expressed as an exception, and exceptions are where
   leaks live.

The question this record answers: **what is the smallest structure in which
every Packet F rule is an instance of one rule, combination is computed rather
than declared, and totality is a machine-checkable property?**

The answer is a lattice, in the specific sense used in the information-flow
literature since Denning: a partially ordered set of classifications in which
any two elements have a least upper bound, and in which the least upper bound
*is* the classification of their combination. Foampit's version is a product of
a role-subset lattice and a scope tree.

---

## Locked Principal Model

### Roles

A **role** is a kind of reader. The set is closed at six members. Growing it is
a design decision that reopens this record.

| Role | Who | Grounded in |
|---|---|---|
| `guest` | Code executing inside a Sandbox, including the entrypoint process and anything it spawns. | The runtime boundary at `DESIGN.md:24`. |
| `caller` | The principal invoking the Core Sandbox API against a Sandbox. Reads responses and retained Operation records. | `DESIGN.md` "caller" (8 occurrences); `ERR-007/008/009` "public responses". |
| `author` | The principal who wrote an Artifact Definition and reads its build output, manifest, and provenance. | Artifact Definition ownership, `DESIGN.md:44-52`. |
| `operator` | The principal who owns Operator Configuration and runs the daemon, drivers, and hosts. | `DESIGN.md` "Operator" (10 occurrences); Operator Configuration, `DESIGN.md:34-37`. |
| `target` | The backend receiving lowered configuration — driver, provider, VMM, or managed-service backend. A reader, because lowering discloses. | `TARGET-IMPLEMENTATION-STRATEGY.md`; the `provider-*` trust boundaries. |
| `host-local` | Any principal with read access to the host on which a Sandbox runs — the host filesystem, the Nix store, the process table, VMM configuration. | `TARGET-IMPLEMENTATION-STRATEGY.md:389-391`, which forbids secrets in images, the Nix store, MMDS, OEM strings, and VMM configuration. |

`host-local` is not a person. It is the role that makes "on the host" precise:
content that lands anywhere `host-local` can read is disclosed to every
principal with host access, whatever their intended role. Treating it as a role
is what lets one rule cover the five forbidden sinks named in
`TARGET-IMPLEMENTATION-STRATEGY.md` instead of five special cases.

`target` is a reader and not merely a destination. A provider that receives a
lowered configuration has read it; whether it retains it is the provider's
business and outside Foampit's control. This is why lowering is a disclosure
event and not a transport detail.

### Scopes

A **scope** is the resource a fact is about. Scopes form a tree rooted at
`deployment`, extended with a bottom element `unscoped`:

```text
unscoped                      ← below everything; the scope of content about no resource
  └── deployment
      ├── tenant
      │   └── sandbox
      │       └── process
      └── artifact
```

`unscoped` is not decoration and was not in the first draft of this record. The
executable check rejected that draft. The tree **branches** at `deployment`, so
`process` and `artifact` have no common descendant, and a join defined as least
common ancestor therefore has **no identity element** — `LCA(process, artifact)`
is `deployment`, not `process`. Without a bottom the structure is not a lattice,
and `public` is not expressible: content that is about no resource at all (an
error variant name, an API shape) is not "a fact about a process."

`ancestors-or-self(unscoped)` is every node. Unscoped content may be read by a
principal at any level, which is what "public" should mean and what anchoring it
at `process` failed to say.

A principal is a pair `(role, node)`: a role together with the node its
authority covers. `(operator, deployment)` is an operator over the whole
deployment; `(caller, sandbox:S)` is a caller authorized for exactly `S`.

**Authority is downward-closed.** A principal at node `N` is cleared for facts
about `N` and everything beneath it. A deployment operator is cleared for facts
about any sandbox in the deployment; a caller for sandbox `S` is not cleared for
facts about sandbox `T`.

`artifact` hangs directly off `deployment` because an Artifact is shareable
across tenants by construction — it is the immutable, reproducible half of the
model (`DESIGN.md:26-30`). **Whether an Artifact may instead be tenant-private
is not decided here**; it is a tenancy question and belongs to Packet F lock 5.
If that lock places `artifact` under `tenant`, the lattice arithmetic below is
unchanged — only the tree changes, and every derived classification is
recomputed rather than re-decided. That property is deliberate.

---

## Locked Classification Lattice

### A classification is a pair

A **classification** is written `(R, S)`:

- `R` — a subset of the six roles, the roles permitted to read.
- `S` — a scope node, the resource the content is about.

`(R, S)` denotes exactly this set of principals:

```text
{ (r, n) : r ∈ R, n ∈ ancestors-or-self(S) }
```

Read: *a principal may read this content when its role is permitted and its
authority covers `S`.*

### The order

`c₁ ⊑ c₂` — "`c₂` is at least as restrictive as `c₁`" — holds exactly when the
principal set of `c₂` is a subset of that of `c₁`. Concretely:

```text
(R₁, S₁) ⊑ (R₂, S₂)   iff   R₂ ⊆ R₁   and   S₂ ∈ ancestors-or-self(S₁)
```

Moving the anchor **up** the tree is more restrictive, which is the point most
worth stating plainly because it reads backwards at first. A fact anchored at
`process` may be read by process-, sandbox-, tenant-, and deployment-level
principals — four levels. A fact anchored at `deployment` may be read only by
deployment-level principals — one. The deeper the anchor, the wider the
readership.

### Join — the combination rule

```text
(R₁, S₁) ⊔ (R₂, S₂)  =  (R₁ ∩ R₂,  LCA(S₁, S₂))
```

This is **the** rule that makes the structure worth having. The classification
of a combination is never declared. It is computed, and it is computed the only
way that is sound: a reader of the combination must be cleared for both parts,
so the permitted roles are the intersection and the permitted authority is the
least common ancestor.

Two consequences are worth naming because both are real defects the model now
catches for free:

- **A log line combining a fact about sandbox A and a fact about sandbox B is
  tenant-scoped**, because `LCA(sandbox:A, sandbox:B) = tenant`. No caller for
  either sandbox may read it. Cross-sandbox correlation is a disclosure, and
  under this rule it is one automatically rather than by anyone remembering.
- **Combining any artifact fact with any sandbox fact yields deployment scope**,
  because those subtrees meet only at the root. A provenance line that names a
  running sandbox has left the author's reach.

### Meet

```text
(R₁, S₁) ⊓ (R₂, S₂)  =  (R₁ ∪ R₂,  the deeper of S₁, S₂ when comparable)
```

Meet is defined for completeness and is used in exactly one place: computing
what a channel with two independent reader groups may carry. It is **never**
used to classify content. A meet applied to content would be declassification
by arithmetic, which §"Declassification" forbids.

With `unscoped` present the meet of two incomparable scopes exists and is
`unscoped`. That is mathematically fine and semantically useless — it would say
a process fact combined with an artifact fact is about nothing — which is
exactly why meet is barred from classifying content. **Only join classifies.**

What is *verified* below is that join is a proper least-upper-bound operation
and that `⊑` is a partial order. Meet is defined but unverified and unused; a
Packet F rule that needs it is a rule that needs review first.

### Bottom and top

| | Value | Meaning |
|---|---|---|
| `⊥` | `(all six roles, unscoped)` | Public. Every principal at any level may read it. |
| `⊤` | `(∅, deployment)` | Nobody. |

**Normalization is locked:** any classification with `R = ∅` is `⊤`, regardless
of anchor. A validator comparing classifications must normalize first, or it
will report two spellings of "nobody" as distinct. This is a stated rule and not
an implementation note, because two independently written oracles must agree on
it for their comparison to mean anything.

---

## Locked Named Classifications

Registry entries and design records name classifications; they do not write set
literals. The names below are the closed vocabulary. Each is a definition, not
an abbreviation — the expansion is normative and the name is the convenience.

| Name | Expansion | Intended content |
|---|---|---|
| `public` | `(all, unscoped)` | Content with no reader restriction: API shape, error variant names, documentation. |
| `caller-visible` | `({caller, operator}, sandbox)` | Runtime state, Operation outcomes, rejection payloads for a Sandbox. |
| `author-visible` | `({author, operator}, artifact)` | Manifest contents, build provenance, construction evidence. |
| `operator-only` | `({operator}, deployment)` | Host paths, capacity, placement, driver internals, Operator Configuration. |
| `guest-only` | `({guest}, sandbox)` | Delivered secret material. Readable inside the Sandbox and nowhere else. |
| `target-only` | `({target}, deployment)` | Provider credentials in transit to the provider that needs them. |
| `host-exposed` | `({guest, operator, host-local, target}, deployment)` | Content that has reached the host and must be treated as readable by anything with host access. Not a permission — a *consequence*. |
| `secret` | `⊤` | Material with no lawful reader in any Foampit channel. Only reachable by an explicit delivery transform. |

Two of these deserve their reasoning stated, because both look wrong until the
expansion is read.

**`guest-only` excludes `operator`.** An operator runs the daemon that delivers
the secret and can, on a real host, obtain it anyway. The classification does
not claim otherwise. It says the secret may not be *placed into any channel an
operator reads* — logs, diagnostics, retained records, Operator Configuration.
That is a rule Foampit can actually enforce, and it is exactly the rule
`TARGET-IMPLEMENTATION-STRATEGY.md:389-391` states. A classification is a
constraint on Foampit's own channels, never a claim about what a determined
principal could reach by other means. Confusing the two produces rules that
cannot be enforced and a false sense of what enforcement bought.

**`host-exposed` is a consequence, not a grant.** Nothing is *authored* as
`host-exposed`. Content acquires it by landing in a host-readable channel. Its
role in the model is to make the resulting obligation computable: once content
is `host-exposed`, `⊑` tells you every channel it may still enter, and the join
rule propagates that to anything derived from it.

---

## Locked Channel Inventory

A **channel** is a place content lands. The set is closed at eighteen members.
Each channel's clearance is the set of principals that actually read it — a
statement of fact about the system, not a policy choice, which is why a channel
whose readers are wrong is a design defect rather than a lattice violation.

| # | Channel | Readers | Note |
|---|---|---|---|
| 1 | `api-response` | `({caller, operator}, sandbox)` | Successful Core Sandbox API results. |
| 2 | `api-rejection` | `({caller, operator}, sandbox)` | Rejection payloads. Bounded by `ERR-004/005/006`. |
| 3 | `operation-record` | `({caller, operator}, sandbox)` | Retained durable Operation records. Retention itself is lock 3. |
| 4 | `daemon-log` | `({operator}, deployment)` | The daemon's own log. |
| 5 | `invariant-diagnostic` | *varies — see below* | The diagnostic every registry entry declares. |
| 6 | `trajectory` | `({caller, operator}, sandbox)` | Execution trace for a Sandbox. |
| 7 | `provenance` | `({author, operator, host-local}, artifact)` | Build provenance. `host-local` because provenance is stored on the host. |
| 8 | `built-manifest` | `({author, operator, host-local}, artifact)` | The expanded manifest. |
| 9 | `nix-store` | `({guest, operator, host-local, target}, deployment)` | World-readable by construction. |
| 10 | `image-content` | `({guest, operator, host-local, target}, deployment)` | Anything baked into an image. |
| 11 | `guest-delivery` | `({guest}, sandbox)` | The authenticated guest-runtime/vsock channel. The **only** channel whose clearance admits `guest-only`. |
| 12 | `metadata-service` | `({guest, operator, host-local}, deployment)` | MMDS and equivalents. Guest-reachable *and* host-reachable. |
| 13 | `oem-strings` | `({guest, operator, host-local}, deployment)` | Firmware-surfaced strings. |
| 14 | `vmm-config` | `({operator, host-local}, deployment)` | VMM/hypervisor configuration and command line. |
| 15 | `provider-request` | `({target, operator}, deployment)` | Lowered configuration sent to a provider. |
| 16 | `snapshot` | `({operator, host-local}, deployment)` | Snapshot contents at rest. |
| 17 | `idempotency-store` | `({operator}, deployment)` | Idempotency keys and recorded outcomes. |
| 18 | `derived-observable` | `({caller, guest, operator, target, host-local}, deployment)` | Timing, size, ordering, error shape — anything inferable without being written. See §"Derived observables". |

Channels 9–14 are the five sinks `TARGET-IMPLEMENTATION-STRATEGY.md:389-391`
forbids secrets from entering, plus the store. **Under this model that
prohibition is not a separate rule.** `guest-only = ({guest}, sandbox)` and each
of those channels has a reader set containing `host-local` or `operator`, so
`{guest} ⊉ readers` and the admission rule refuses. One rule, six sinks, and the
sixth was found by the model rather than restated from the prose.

`invariant-diagnostic` carries no fixed clearance because a diagnostic's
audience depends on the invariant. **The clearance of an invariant's diagnostic
is the clearance of the channel on which the invariant's rejection is
delivered** — `api-rejection` for a boundary rejection, `daemon-log` for an
operator-facing preflight. That is a derivation, not a free choice, and it is
what §"`secretSafe` becomes derived" builds on.

---

## Locked Admission Rule

There is one rule. Every Packet F disclosure invariant is an instance of it.

> Content classified `c` may enter channel `ch` **iff** `c ⊑ clearance(ch)`.

Expanded: `roles(ch) ⊆ roles(c)` and `anchor(ch) ∈ ancestors-or-self(anchor(c))`.

Read as an obligation: *every principal who reads this channel must be a
principal this content permits.*

Three properties follow, and each is checkable by a validator rather than by
review:

1. **Totality is decidable.** The classification universe is finite and the
   channel set is closed, so "which (content-class, channel) pairs has nobody
   ruled on" is a set difference. This is what Gate 2A needs and what 115
   independently-written invariants cannot supply.
2. **Composition is not a special case.** A message built from parts is
   classified by the join of its parts, then admitted by the same rule. No rule
   anywhere says what to do about combinations, because the arithmetic already
   did.
3. **A leak is a proof obligation, not a judgement.** "Can this land here" has
   an answer that does not depend on who is asked.

---

## Locked Declassification

Lowering a classification is the only way content moves to a wider audience,
and it is the only operation in this model that is not arithmetic. It is
therefore constrained hard.

1. **Only a named transform declassifies.** A transform is a registered
   function with a declared input classification, output classification, and
   an argument for why the output is safe. There is no implicit lowering; in
   particular, *copying content into a differently-classified structure does not
   change its classification.*
2. **A transform is total or it is not a transform.** A redaction that fails on
   some inputs is not a declassifier. Its output on those inputs is `⊤`.
3. **Failure is `⊤`, never the input.** If a transform cannot compute its
   output, the result is "nobody" — not "unchanged," and not "best effort."
4. **A transform declassifies its output only, never its input.** Redacting a
   secret out of a message does not make the secret redactable elsewhere.
5. **Transforms do not compose implicitly.** Chaining two declassifiers is a
   third transform requiring its own justification, because the composition may
   be sound where neither part is, or unsound where both are.

Whether any specific transform exists — what redaction removes, what it must
preserve, what a redaction failure does to the operation carrying it — is **lock
2**. This record fixes only that declassification is explicit, named, total, and
fail-closed.

---

## Locked Derived Observables

The admission rule governs content that is *written*. It says nothing about
content that is *inferred*, and every rule above is satisfiable by a system that
leaks through timing.

> An observable derived from content `c` carries classification `c`.

An observable is anything a principal can measure without reading the channel:
elapsed time, response size, message count, ordering, retry behavior, and — the
one most often overlooked in this repository's own material — **which error
variant was returned.**

`ERR-007/008/009` already require that an unauthorized request against an
existing target and an authorized request against an absent one produce
observationally equivalent public responses. Under this rule that requirement
is not a property of those three invariants; it is the general rule applied at
three admission stations, and its scope extends to every channel where the two
cases could be distinguished.

The `derived-observable` channel has the widest reader set in the inventory,
which is the correct and uncomfortable consequence: **anything whose timing a
guest can measure is disclosed to the guest**, and if that timing depends on
`operator-only` content, the admission rule refuses it. Packet F will find real
violations here. Recording the rule now, before the walk, is the difference
between finding them and rationalizing them.

---

## Locked Fail-Closed Rule

> Content whose classification cannot be computed is `⊤`.

Not `public`, not "the classification of the nearest similar thing," and not
"unclassified." A model that resolves the unknown to anything but "nobody" has
made the unknown into a permission.

This is the same shape as `SIG-008`'s second half, registered in Stage 0g: an
unprovable runtime state is refused and is never approximated as `stopped`. That
rule and this one are the same discipline at different layers, and both exist
because *resolving "cannot prove" into a convenient answer in order to proceed*
is the failure this repository keeps finding.

---

## `secretSafe` Becomes Derived

Every one of the 355 registry entries declares `diagnostic.secretSafe`. Every
one declares `true`. `validate-registry.jq:370-372` checks that it is a boolean
and nothing else. **355 secret-safety claims are currently enforced by nothing**
— they are the largest unbacked assertion in the repository, and they sit in the
field a reader is most likely to trust.

This record makes the claim computable:

> `secretSafe` holds for an invariant **iff** the join of the classifications of
> every part of its diagnostic is `⊑` the clearance of the channel that
> diagnostic is delivered on.

The parts of a diagnostic are already enumerated per entry:
`diagnostic.identity`, `diagnostic.primaryPaths`, `diagnostic.relatedPaths`, and
`diagnostic.remediation`. Classifying those parts is mechanical for paths (a
path names a resource, and the resource determines the anchor) and requires
judgement only for remediation prose.

**This is not implemented by this record**, and deliberately so: shipping it
requires classifying 355 diagnostics, which is walk work, not design work. What
is locked is that `secretSafe` is a **derived** property. No entry may assert it
against a computation that disagrees, and the field stops being a self-report.
The check belongs in Stage 2 and is the single highest-value thing that stage
produces, because it converts the repository's largest unbacked claim into 355
individually failing or passing obligations.

---

## Executable Evidence

The algebra above is checked, not asserted, by
[`prototypes/classification-lattice/lattice.mjs`](../prototypes/classification-lattice/lattice.mjs)
— dependency-free, disposable research evidence in the sense of
`RESEARCH-STANDARD.md`. It encodes the six roles, the scope tree, the eight
named classifications, and the seventeen fixed-clearance channels **verbatim
from this record**, then checks:

| Property | How |
|---|---|
| Join is idempotent, commutative, associative | Exhaustive over all 379 elements for the first two; strided triples for the third |
| Join is a least upper bound | Exhaustive over all element pairs — for each pair, every common upper bound is confirmed above the join |
| `⊑` is reflexive and antisymmetric, and agrees with join | Exhaustive over all pairs |
| `⊥` is a join identity, `⊤` is absorbing | Exhaustive |
| Empty-role classifications all normalize to one element | Exhaustive over nodes |

**778,250 checks pass, 0 fail.**

It then checks that the model reproduces rules the repository states
independently of it — the part that would be circular to assert:

- `guest-only` is refused by all five sinks named at
  `TARGET-IMPLEMENTATION-STRATEGY.md:389-391`, and `guest-delivery` is the
  **only** one of the seventeen channels that admits it.
- `snapshot` also refuses `guest-only` — a sixth host-readable sink the prose
  does not name, located by the model rather than remembered.
- `secret` enters no channel; `public` enters every channel.
- `operator-only` is refused by all four caller-facing channels.
- Two sandbox facts join to `tenant`; an artifact fact joined with a sandbox
  fact reaches `deployment`.
- No join ever widens, and no combination involving `operator-only` is readable
  by `guest` — checked across every element.

The first draft of this record failed the check. It defined `⊥` as
`(all roles, process)`, which is not an identity once the scope tree branches.
The correction is `unscoped`, described above. Recording that here rather than
quietly fixing it is the point of writing the checker before the walk: this is
the class of error that survives review of prose and does not survive
arithmetic.

---

## Why This Model

### Why a lattice rather than a list of rules

A list cannot answer "what did we not consider." The repository has already paid
for this twice, in defects whose shape is identical: **F1**, where 247
invariants declared a `wire-corruption` test that could not be written because
two individually reasonable validator rules composed into an unconditional
obligation; and the **admission-anchor gap**, where three cells refused at
admission while citing only invariants sound afterward, and the existing rule
was satisfied because it asked a weaker question.

Both were composition failures found only by building a structure that could
express the stronger question. Packet F is larger than either and concerns
disclosure, where a composition failure is a leak.

### Why a product of roles and scopes rather than one dimension

Collapsing to a single "sensitivity level" forces a total order on principals
that are genuinely incomparable. `guest-only` and `operator-only` are the proof:
neither contains the other, and any chain must render one of them as an
exception. The product keeps both first-class, and it costs one extra component.

Separating scope from role is what makes cross-sandbox correlation fall out
automatically. In a role-only model, "a fact about sandbox A" and "a fact about
sandbox B" have identical classifications and combine to something equally
readable, which is wrong and is the kind of wrong that is invisible in prose.

### Why join is intersection

Because a reader of the whole must be a reader of every part. This is the only
sound definition, and the reason to state it as arithmetic rather than as
guidance is that guidance is applied by whoever is writing the rule, and
arithmetic is applied always.

### Why `host-local` is a role

`TARGET-IMPLEMENTATION-STRATEGY.md:389-391` names five forbidden sinks. As five
prohibitions they are five things to remember and an open-ended question about
the sixth. As one role they are one rule, and the model located a sixth channel
(`nix-store`, which the prose does name, alongside `snapshot`, which it does
not) by asking which channels `host-local` reads.

### Independent-oracle position

Consistent with `CONTRIBUTING.md:37-53`, this record is one of the copies that
must be kept in lockstep, not the single source. The lattice will be stated in:
the corpus, the registry validator, and the Packet F ledger validator — three
independently authored copies compared by `check-model-coherence.sh`, exactly as
the phase graph, owner set, and `placeholder_strings` are today. The comparison
is the control; consolidating the copies would remove it.

---

## What This Record Does Not Lock

Listed explicitly so a later reader can tell a gap from an omission.

- **What redaction removes and preserves**, and what a redaction failure does to
  the operation carrying it. Lock 2. This record fixes only that
  declassification is explicit, total, and fail-closed.
- **Retention.** How long content stays in a channel, and whether time changes
  its classification. Lock 3.
- **Evidence integrity and decoding.** Whether a channel's contents can be
  trusted on the way back in. Lock 3. Note that `evidence-sink` is *not* in the
  channel inventory above, because an evidence sink is a channel in both
  directions and its ingress half is lock 3's to define.
- **Acquisition, reservation, and TOCTOU.** Lock 4. `FEN-002` and the fencing
  model touch it; the protocol is unlocked and all four locked Packet E records
  say so.
- **Authorization and tenancy.** Lock 5, including whether `artifact` sits under
  `tenant` in the scope tree. This record is written so that answer changes the
  tree and nothing else.
- **The classification of any particular field.** That is the Stage 2 walk. No
  classification is assigned to any registry entry here.
- **Whether `derived-observable` can be enforced at all** for timing. The rule
  is stated; whether Foampit can make timing independent of `operator-only`
  content on every path is an open engineering question, and a rule that turns
  out to be unenforceable becomes a `dynamic-preflight` or an
  `observed-conformance` disposition, not a deleted rule.
