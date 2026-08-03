# Findings: post-launch enforcement slice

Date: 2026-08-03

Nine invariants implemented with their authoritative hooks and declared test kinds, spanning
five owners, six rejection deadlines, and all three post-launch dispositions. 19 checks pass.
The code is the instrument; these findings are the deliverable.

## F1. 176 invariants declare a test that cannot be written — `wire-corruption`

**Every one of the 176 invariants whose rejection deadline is post-launch declares a
`wire-corruption` test. Not one of them declares a trust boundary that crosses a wire.**

```
post-launch invariants declaring a wire-crossing trust boundary:  0 of 176
post-launch invariants declaring a wire-corruption TEST:        176 of 176
```

Their declared boundaries are `core-api`, `live-operation-dispatch`, `process-launch`,
`idempotency-store`, `managed-service-core-api` — all in-process Core boundaries. After `C0`
and `RW0`, the value never crosses a serialization boundary again. There is nothing to
corrupt.

**Root cause is a validator rule, not authoring sloppiness.** `validate-registry.jq` requires
a `wire-corruption` test *whenever `trustBoundaries` is non-empty*, and separately requires
`trustBoundaries` to be non-empty. The two rules compose into "every invariant must declare a
wire-corruption test", universally, by construction. The rule was written when every invariant
was on the artifact branch, where it is correct.

I could not write this test for `SBX-004`, `PRC-007`, or `PIO-017`. There is no wire.

**Consequence for Gate 4B: 176 of the 1,453 planned tests (12%) are currently unwritable as
specified.** The fix is to make the `wire-corruption` obligation conditional on a boundary
that actually decodes an external representation, rather than on `trustBoundaries` being
non-empty. That is a change to a shared validator rule and would reopen the obligation
counts for every packet.

## F2. `unrepresentable` means two different things, and only one is a type claim

Twenty-one post-launch invariants are declared `unrepresentable` — "supported APIs cannot
construct the invalid value" — and **all 21 also declare a `source-rejection` test**, which
presupposes a source that can express the invalid value and be refused. Both cannot hold.

Implementing three of them separated the cases:

| Invariant | Genuinely unrepresentable? | How it had to be implemented |
|---|---|---|
| `ERR-002` sealed error registry | **Yes** | A closed Rust enum with no free-text arm and no `Other(String)`. The invalid value has no constructor. |
| `PIO-004` accepted input replayed | **No** | Replay is detected by comparing a sequence against accepted state. That is runtime data, not a type. |
| `SBX-004` presentation label stored as state | **No** | The status type must carry a label field for the legitimate derivation; forbidding the *stored* case is a runtime check. |

So `unrepresentable` holds where the invalid state is a **closed vocabulary** (a variant that
does not exist), and fails where it is a **relation between a request and current state** —
which is most of Packet E.

Two of three are `reject-at-boundary` in any honest implementation. If that ratio holds, ~14
of the 21 post-launch `unrepresentable` dispositions are misclassified.

**Also**: for the one genuinely unrepresentable case, `source-rejection` is the wrong test
mechanism. Proving `ERR-002` means proving code *does not compile*, which is a compile-fail
test. The registry has no such test kind, and the corpus has no place to record one.

## F3. "Exactly one authoritative hook per invariant" holds — but hooks are not separable code

Nine invariants, nine hooks, no collisions. The rule is satisfiable.

But at `T0`, both `PRC-007` and `PIO-017` fire on the same `Teardown` request, reading
overlapping state. A real implementation has one teardown routine serving both. The registry's
model — one hook per invariant — is a *traceability* claim, not a modularity claim, and
nothing in the model says so. An implementer reading "exactly one authoritative hook" may
reasonably expect one function per invariant, which does not survive contact with a phase
where a dozen invariants share a transition.

## F4. The phase for a spanning invariant is underdetermined

`ADM-009` is declared `E0 -> E1`. Its check reads only the request, so it can sit at either
end. I placed it at `E1` because that is the deadline; `E0` would have been equally valid and
would have rejected earlier, which the protocol prefers. The registry records first-sound and
deadline but not *where the hook should actually go* between them, and the two choices have
different behaviour — an earlier hook refuses before dispatch.

## F5. `observed-conformance` needs a claimed-versus-observed split the registry does not record

To implement `ADM-012` and `PRC-007` I had to give the world model two separate fields:
`driver_claims_running` and `probe_observes_running`. The whole content of an
observed-conformance invariant is that these may disagree and only the probe is authoritative.

The registry records the disposition but not *which fact is claimed and which is observed*.
That distinction is the invariant's substance, and it currently lives only in prose. A
generator producing conformance-probe skeletons could not derive it.

## What this says about the model overall

The core structure survived: phases are real, hooks land at them, rejections carry their
invariant identity, and diagnostics can name a coordinate without echoing a caller value
(`SBX-004`'s diagnostic reports a length, never the string).

What did not survive is the assumption that **one test-kind vocabulary fits every branch of
the phase graph**. `wire-corruption` is meaningful on the artifact branch and vacuous
post-launch; `source-rejection` presupposes an expressible source and so contradicts genuine
unrepresentability; `runtime-probe` needs a claimed/observed split the registry does not
carry. The vocabulary was designed against Packets A-D, which are almost entirely pre-launch,
and Packet E is the first packet to live somewhere else.

**Recommendation before Gate 4B is costed**: revisit the test-kind obligations per branch
rather than per invariant. The current model over-counts the test obligation by at least 176
and misclassifies roughly 14 dispositions, and both errors point the same way — the estimate
of 1,453 tests is high, and the shape of the remaining work is different from what the
registry implies.
