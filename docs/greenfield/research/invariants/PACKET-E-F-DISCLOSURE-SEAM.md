# Packet E / Packet F Disclosure Seam

**Status:** ruling · **Recorded:** 2026-08-03 · **Owed by:** Packet E plan, Task 4 Step 3

Packet E registered invariants that constrain what a caller learns. Packet F
will register invariants that constrain what a *channel* carries. Without a
stated seam these produce the same sentence twice, and a reader cannot tell
whether a later contradiction is a real conflict or two rules about different
things. This record fixes the split before Packet F begins.

## The split

**Packet E owns the semantic rule.** It governs the *response to a request* —
what a caller may learn by making a call, and in what order the service is
allowed to learn it. Its questions are about ordering and closure:
authorization precedes existence disclosure; a rejection payload stays inside
its closed schema; provider evidence is protected, bounded, and never a public
union extension.

**Packet F owns the disclosure-channel rule.** It governs everything that is
*not* the response to the caller — logs, diagnostics, trajectories, provenance,
retained evidence, and evidence sinks. Its questions are about audience: who
can read this channel, and does the content it carries match that audience.

The dividing line is the **audience**, not the content. The same secret may be
lawful in one place and unlawful in another, and each packet answers for its own
places. Neither packet may relax the other's rule by pointing at it.

## Obligations named on one side

Each obligation below is named on exactly one side. An obligation named on both
sides is a defect in this ruling, not a redundancy.

### Packet E — registered, closed here

| Invariant | Phase | The semantic rule it fixes |
|---|---|---|
| `ERR-007` | C0 | Creation authorizes before it discloses existence or validates in detail. |
| `ERR-008` | L0 | Live authorizes at a disclosure-safe operation *and parent* scope. |
| `ERR-009` | E0 | Exec and Process-control authorize at a disclosure-safe operation and parent scope. |
| `ERR-004` | C0 | Creation rejection payloads stay inside their closed schema. |
| `ERR-005` | L0 | Live rejection payloads stay inside their closed schema. |
| `ERR-006` | E0 | Exec rejection payloads stay inside their closed schema. |
| `ERR-016` | D0 | An unrecognized native code never extends the public union. |
| `ERR-017` | D0 | Raw provider evidence is redacted and size-bounded before it reaches the caller. |
| `ADP-006` | F0 | An adapter never adds a public error variant. |

`ERR-007/008/009` are the observational-equivalence rules: an unauthorized
request naming an existing target and an authorized request naming an absent one
produce equivalent **public responses**. The scope of "public response" is the
caller-visible result of the call. It says nothing about what a log line
records, and Packet F must not read it as covering that.

`ERR-017` is the narrowest and most easily misread. It bounds provider evidence
*on the way to the caller*. Whether that same evidence may be **retained**, and
for how long, and readable by whom, is Packet F's, and is unregistered today.

### Packet F — deferred, not registered here

| Obligation | Why it is not Packet E's |
|---|---|
| What may appear in a **log line** or structured diagnostic. | Different audience: an operator, not the caller. |
| What a **trajectory** or execution trace may carry. | Trajectories outlive the response and have their own readers. |
| What **provenance** records assert and expose. | Provenance is an artifact fact, not a call result. |
| What an **evidence sink** accepts, retains, and re-reads. | `INVARIANT-ENFORCEMENT.md:127` names evidence ingestion as a boundary to walk; no `trustBoundaries` value covers it today. |
| **Retention** of evidence already bounded by `ERR-017`. | `RET-001` guarantees retained records stay readable and states no content rule. |
| Secrets in **success** payloads and output streams. | `ERR-005`/`ERR-006` bound *rejection* payloads only. This gap is real and is F's. |
| **Redaction** as a transform: what it must remove and what it must preserve. | Packet E requires that redaction happened; it does not define it. |

## The three known misreadings

1. **"`ERR-007` already covers existence leaks, so Packet F need not."** It
   covers them in the response. A log line that records the target name of a
   request rejected as unauthorized leaks exactly what `ERR-007` prevents,
   through a channel `ERR-007` does not reach.

2. **"`ERR-017` already bounds provider evidence, so retention is covered."**
   `ERR-017` acts once, on the path to the caller. Retention is a separate
   decision about a separate reader.

3. **"Packet F may narrow a Packet E rule to make a channel workable."** It may
   not. The packets are disjoint by audience; a channel that cannot satisfy its
   own rule is a channel that must change, or a Packet E rule that must be
   re-opened by an explicit decision — not silently narrowed.

## What this ruling does not settle

- The **classification and audience lattice** itself. This record says the
  dividing line is audience; it does not enumerate the audiences. That is
  Stage 1 lock 1 and is a genuine design decision.
- **Whether a redaction failure is fail-closed or fail-open.** Packet E's rules
  presume redaction succeeded. What happens when it cannot is unlocked.
- **Side channels.** Timing, size, and error-shape leakage satisfy every rule
  above and are still disclosure. `side.channel` has zero registry hits.
