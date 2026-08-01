# Packet E Obligation Partition Review

Status: **Candidate — identifiers not allocated; 20 confirmed defects open**

Date: 2026-07-31

This records the Packet E obligation partition and its adversarial review. It is
the work product of Task 2 of the
[Packet E inventory walk plan](../../plans/2026-07-31-packet-e-runtime-lifecycle-inventory-walk.md).

**Nothing here has a registry identifier and nothing here provides Gate 2A
coverage.** Allocation is deliberately deferred: an identifier propagates into
the corpus, `invariants.json`, all 54 Packet D classification vectors, and the
generated rule selectors, so a defect found after allocation is a whole-tree
edit rather than a file edit.

## Provenance

| Stage | Result |
|---|---|
| Source obligations across the four locked records | 178 (IDENTITY 30, LIFECYCLE 47, TAXONOMY 50, RESULT 51) |
| Naive expansion of every composite | 267 candidates |
| After cross-document reconciliation | 201 + 6 ledger rules + 14 witness extensions |
| First draft, authored by five family clusters | 204 |
| First adversarial review | 73 defects, 21 blocking — **failed** |
| After consolidation (11 merges, 7 drops, 106 edits, 25 additions) | 209 |
| Second adversarial review, with independent refutation | 35 claimed, 15 refuted (43%), **20 confirmed** |

The first draft failed because the five family clusters authored in parallel
without visibility into each other, so adjacent families independently filed the
same rule — `SBX`/`ADM` both filed execution admission, `OPA`/`ERR` both filed
the recovery contract, `IDE`/`FRK` filed Fork identity three times. 45 of 178
obligations were cited three or more times and 6 were cited by nobody.

## Mechanically verified on the current set

- 0 unreachable `(firstSoundPhase, rejectionDeadline)` pairs;
- 0 uses of `C0 -> R1`, `L0 -> E0`, or `E0 -> L1`; `T0` is a sink in all 12 of
  its filings;
- all 178 source obligations cited at least once;
- 0 bare `unknown` values, which every ledger validator rejects as placeholder
  content;
- no exact-duplicate rule survives. The six entries sharing an
  owner/phase/obligation signature are distinct rules partitioned from one
  composite obligation, not duplicates.

## Why the count is not final

Three confirmed findings require *adding* entries, so 209 is not the number to
allocate against: 209 -> 211-214.

## Calibration of the review

15 of 35 claims were refuted. The refuted claims clustered on three recurring
false-positive shapes, all worth knowing before reading any future review of
this set:

1. legitimate per-station splits misread as duplication;
2. a Core record named as a *consulted fact* under a non-core owner misread as
   an owner error;
3. cross-owner citation of one obligation misread as duplication.

Six confirmed findings had their fix or severity amended during refutation, and
**five of the originally proposed fix texts would have introduced new defects**.
Apply the fixes as recorded below, not as first proposed.

---

## 1. Readiness verdict

**NOT READY for identifier allocation.** Do not allocate. The set requires a further edit round, and — decisively — **the entry count is not final**: three confirmed findings require *adding* entries (up to 5), so allocating against 209 now guarantees a renumber.

Three independent reasons, any one of which is sufficient:

1. **Two blocking defects are semantic, not cosmetic.** [8] makes four L0 entries jointly unsatisfiable; the teardown-residue cluster leaves four entries whose recorded justification argues a different phase pair than the one they declare, so their boundaries are unverifiable from the record.
2. **The count will change.** [51] needs two new per-station siblings (L1→L1, T0→T0); [86]/[94] need up to two R1 siblings if launch-branch coverage is intended; [152] needs a runtime T0→T0 sibling or an explicit statement that it stops at E1. 209 → 211–214.
3. **34 of 209 entries (16.3%) need edits**, including 5 owner/citation field changes that propagate into classification vectors and selector generation.

**Ready after the fixes below**, with no re-verification needed beyond a mechanical re-run of the coverage, duplicate-signature, and graph-reachability gates plus a targeted re-read of the ~15 rewritten rationales.

I confirmed the load-bearing evidence directly against `/private/tmp/claude-501/-Users-bear-dev-foampit/46f207af-9686-479d-9458-34bf8a1f48c7/scratchpad/entries-consolidated.json`: [8]'s clause 3 reads verbatim as reported; [126]/[151]/[152]/[162] all declare `E1 -> E1` with traversals ending `extended through Sandbox teardown` and Q3 clauses naming teardown as the last correct refusal station; [190]/[191] are the `T0 -> T0` halves; and [152]'s `TAXONOMY-12` appears in no T0 entry.

---

## 2. Blocking defects — exact edits

### B1. [8] — the merged statement forbids what [6], [11], [18] mandate

`entries-consolidated.json[8].statement`, clause 3, currently:

> `and an idempotency key, runtime epoch, Operation ID, or event cursor is accepted in no identity, target, precondition, or authority position.`

Replace clause 3 with:

> `an event or output cursor is an observation position only and is accepted in no identity, target, precondition, or authority position; an idempotency key is a recovery coordinate only; and a runtime epoch is expressible only as an expected-value precondition and never as an assignable field.`

Notes that must be honoured when applying:
- **Do not keep "Operation ID" inside the forbidden-position clause** (the reviewer's proposed fix did). [43] requires an accepted cancellation to target the existing Operation, and [63]/[28] read Operation records by `operation.id`. Narrow to cursors only, exactly as draft[11] had it.
- [8]'s own clause 2, remediation, and `diagnosticPaths` (`operation.target.expectedRuntimeEpoch`) already presuppose the epoch precondition, so this restores internal consistency as well.
- The consolidation introduced this: M8's members were draft [9] (name alias), [10] (etag vs epoch), [11] (cursors, subject = "Every event and output cursor"). No member supplied the widened subject list.

### B2. [126] — the E1 half was never narrowed out of [190]'s teardown window

Three field edits to `[126]`:
1. `statement`: delete `before or during teardown` → `...every later signal acknowledgement, reaper observation, or provider event arriving after the outcome commit is retained as evidence rather than applied as a rewrite.`
2. `traversal`: `one Exec dispatch and its outcome` (strike `, extended through Sandbox teardown`).
3. `rationale` Q3: replace `teardown is the last station on this traversal at which refusing is still correct...` with an E1 justification, e.g. `E1 is the exec outcome station and the last point on this traversal at which a late acknowledgement, reaper observation, or provider event can be refused as a rewrite; late evidence arriving during Stop or Delete is refused at [190].`

Narrowed [126] retains a non-empty distinct jurisdiction (late evidence on the exec traversal after outcome commit, before any teardown), so this is a genuine per-station partition and [190] must be kept. Do **not** take the alternative of deleting [190] — that reinstates the `E1 -> T0` cross-operation edge the consolidation removed.

### B3. [151], [152], [162] — same defect against [191]; and [152] has no T0 counterpart

Apply the identical three-field narrowing to all three:
- `traversal`: strike `, extended through Sandbox teardown` from each.
- `rationale` Q3: rewrite to name **E1** as the deadline, using the set's own convention already used by [127], [129], [131], [138], [139], [147], [148], [149], [153] — *"the exec outcome station is the last correct refusal point"* — and cross-reference [191] for the Stop/Delete window instead of reaching into it.

**[152] needs an additional decision.** It is `runtime` / `observed-conformance` and carries `TAXONOMY-12`; [191] is `core` / `reject-at-boundary` and carries `LIFECYCLE-40 + RESULT-40`. I confirmed `TAXONOMY-12` appears in no `T0` entry. Either:
- (a) add a runtime-owned `T0 -> T0` sibling for driver-supplied backend-exit and drain evidence during Stop (count +1), **or**
- (b) state explicitly in [152] that the driver obligation terminates at E1.

Pick (a) if teardown drain evidence is genuinely driver-supplied; (b) is only defensible if [191]'s Core seal needs no fresh driver evidence.

**Why this is blocking and not major:** `merge-plan.md:541` asserts as a headline invariant that the four `E1 -> T0` Exec entries reaching into Stop's traversal were removed. Prose in all four still makes exactly that claim, so the consolidation's own stated property is false as delivered, and each entry's recorded Q1–Q4 supports a phase pair it does not declare.

---

## 3. Major and minor defects

### Major

| Idx | Defect | Edit |
|---|---|---|
| **[116]** | Owner `core`, but the invalid state is an Exec admission precondition; its Q2 prints the fact-location test the plan *declined* at `merge-plan.md:360`. Omitted from the Criterion-O move list at `:517`. | `owner` → `exec`; Q2 → *"one Process request inside an existing Sandbox is the exec request surface; the Core sequencing record is the consulted fact."* Phases E0→E0 unchanged. Sibling [115] is the model. |
| **[160]** | Flipped exec→core at `merge-plan.md:358` on the exact inference declined at `:360`. Nothing in it protects an enumerated Core artefact; its surviving Q2 still says *"the Process request surface … is exec."* | `owner` → `exec`. **No rationale edit needed** — its Q1 "Core-held facts" language is Ruling-R2 *disposition* language, used verbatim by live-owned entries. |
| **[83]** | Owner `create`, but the invalid state is a durable commit plus an unauthorized launch dispatch. [87] and [120] place commits to the same `sandbox.status.runtime.*` path in `core` under the same obligation. | `owner` → `core`; Q2 → *"the durable creation commit and the dispatch of a launch effect are the control plane's own artefacts."* **Decline the reviewer's hedged D0 suggestion** — keep `C0 -> C0`. Also strike the stale *"the two fields are independently expressible"* clause ([84] falsifies it). Leave [82] at `create`. |
| **[150]** | Its narrowing to the replay clause touched only `statement`/`owner`/`sourceObligations`. Title, Q1, Q3, `diagnosticPaths`, and `remediation` are byte-identical to the composite draft and still state [198]'s lease-exclusivity rule — one fact now titled under two owners. | Retitle → *"Accepted Process input replayed"*; rewrite Q1 and Q3 around the accepted input-frame record with no lease vocabulary; drop `process.control.liveLeases` from `diagnosticPaths` (use `exec.control.sequence` / `process.control.receipt`, cf. [155]/[157]); cut the lease clause from `remediation`. Also drop the *"generated input path admits only a single live lease"* claim, which contradicts [198]. **Do not "fix" [198]'s split note** — "non-replay clause" is correct as written and the proposed edit would invert it. |
| **[183]** | Narrowed only in `statement`/`sourceObligations`; title, Q3, Q4 first sentence, `diagnosticPaths`, and `remediation` still assert the clauses split out to [195] and [196]. Shares owner/phase/deadline/disposition/traversal with [196] — the tightest surviving collision. | Retitle to the surviving clause **including its second half** (etag/epoch-precondition reach *and* exposure of system-originated Operations for observation); strip the rewritten-result justification from Q3 **and from Q4's first sentence**; replace `operation.result` with `operation.target.expectedEtag` / `operation.target.expectedRuntimeEpoch`; cut the desired-state and successor-Operation clauses from `remediation`. Keep `rejectionDeadline` at L0. |
| **[196]/[183]** | [196] cites `TAXONOMY-48` (a *visibility* obligation) but states terminal-result immutability; [183] states TAXONOMY-48's content and no longer cites it. The 178/178 coverage gate passes on a citation whose entry does not state the rule. | [196] `sourceObligations` → `TAXONOMY-49`, `LIFECYCLE-19`, `RESULT-24`. Restore `TAXONOMY-48` to [183]. **Decline adding `TAXONOMY-45` to [196]** — it would create a 7th shared `service/S0→L0/TAXONOMY-45` signature with [183]. Re-run the coverage check. |
| **[206]** | `statement` says validation fails **with** an explicit named target branch; the locked rule makes the explicit branch the *escape hatch*. Title and remediation confirm the statement is the defective field. | `statement` → *"...is rejected during Artifact validation unless the Artifact declares an explicit named target branch for it, and is never deferred to workload launch or runtime discovery."* Severity raised from the reviewer's `minor`: as written it mandates rejecting exactly the case the locked rule permits. |
| **[51]** | `R1 -> R1` with an unrestricted Operation-immutability statement whose traversal covers reconciliations entering at L0/E0 that never reach R1. Q3 overstates the binding ruling. | Narrow `traversal` to the launch-branch reconciliation/adoption traversal; **add `L1 -> L1` and `T0 -> T0` siblings** (count +2); rewrite Q3 to stop citing the ruling as fixing reconciliation at R1. No E1 sibling — the ruling states system origin can never originate an Exec. ([126] protects *Process* records, not Operation records; the reviewer's aside there was imprecise but correctly hedged.) |
| **[86], [94]** | Both declare `L1 -> L1` over *"any lifecycle-mutation traversal"*; [86] enumerates `creating`/`provisioning` (launch-only labels) and [94]'s predicate is the launch-failure case. Neither can bind launch-branch status commits. | Change both traversals to *"any **live** lifecycle-mutation traversal, at … commit"*, matching [87]. If launch coverage is intended (and the statements say it is), **add R1 siblings** (count +2) alongside [120]. For [86]'s label sibling, C0 is arguably as apt as R1 — decide at placement. |
| **16 stale Q2s**<br>[2],[6],[7],[9],[10],[33],[39],[63],[85],[109],[110],[111],[145],[150],[158],[160] | 17 owner flips; 16 kept the pre-flip Q2 verbatim. Q2 is structurally the owner question across all 209. Three are outright contradictions: [109] and [85] (owner `live`, Q2 says core owns it), [145] (owner `core`, Q2 = the runtime criterion verbatim). [150]/[158] sit on one traversal each carrying the other's justification — reads as a field swap. | Rewrite each Q2 to the Criterion-O ground for the owner now carried, using [108] as the template (the one flip that *was* rewritten). Where the Q2 is right and the field is wrong, flip the field — see [116]/[160]. For [158], keep `core` and re-justify as a lane grant. **Treat the [63] sub-note as optional** — dropping *"Operation retention is service-enforced…"* is defensible but Q4 currently leans on it. |

### Minor

- **[145]** — statement rewritten to a Core subject, rationale untouched; Q1/Q2 and the disposition clause still argue `runtime`, which `CONFIGURATION-LANGUAGE-CORPUS.md:56` bars for core. Rewrite Q1/Q2 to name Core's durable dispatch record. **Correction to the proposed fix:** the runtime home for declared dispatch-identity support is **[25]** (FEN, D0→D0), which [145]'s own Q4 already names — *not* [143]. Q3 and Q4 are owner-neutral and stay. Subsumed by the 16-Q2 sweep.
- **[36]** — Q4 delegates the create half of the idempotency-rebinding rule to a "creation-scope entry … filed as a witness extension" that does not exist; [199] is now that entry and its rationale records the dangling reference. Rewrite Q4 to cite [199], matching the [37]/[40]/[41] phrasing.
- **[199]** — *"One caller-and-idempotency-key coordinate binds permanently"* drops `method` from the locked three-part coordinate and asserts permanence the records window-scope. Restate using the [36]/[37] wording: *"One authenticated scope, method, and idempotency key binds exactly one canonical CreateSandbox request digest for its published recovery window…"* **Keep [199]'s existing tail** ("refused as a conflict and dispatches no effect") rather than importing [36]'s return-the-original-Operation clause. Fold the [36]/[37]/[39] lifetime reconciliation in here.
- **[146]** — cites `TAXONOMY-05` (a Create-running obligation) on a TerminateProcess postcondition. Replace with `TAXONOMY-11`; `LIFECYCLE-36` is correct. Coverage holds (TAXONOMY-05 4→3 citers, TAXONOMY-11 1→2).
- **[52], [208]** — both assert compensation gets *"its own Operation"*; the locked records grant a recorded forward effect but omit compensation from both closed enumerations of system-originated work that may surface as an Operation. Soften both to *"its own durable record, evidence, and outcome"*. Also apply to **[208]'s remediation** (which repeats the over-claim; [52]'s is already soft), and note the `operation.compensates` diagnostic path is undefined anywhere in the packet.

---

## 4. What the refutation pass rejected — calibration

**15 of 35 claims (43%) were refuted.** That rejection rate is high enough to take seriously as a signal that the confirmed set is *not* inflated, and the pattern of what was rejected tells you what to trust.

The refuted claims clustered on three recurring false-positive shapes:

1. **Legitimate per-station splits misread as duplication.** The set deliberately files one obligation at several stations (`[47]/[48]/[49]/[50]` = R1/L1/E1/T0; `[55]/[56]/[57]`; `[36]/[37]/[199]`). Claims proposing merges of these were rejected. Notably, the *surviving* duplication findings all go the other direction — they propose completing a split, not undoing one.
2. **Fact-location confused with ownership.** Rationales legitimately name a Core record as a *consulted fact* under a non-core owner ([6], [9], [63], [85], [109], [110], [111] all do this). Claims treating any Core-record mention as an owner error were rejected — which is exactly the `L1.D11` inference the plan itself declined.
3. **Shared obligation citations across owners.** Cross-owner citation of one obligation is standard here (TAXONOMY-05 spans core/live/create; TAXONOMY-12 spans core/runtime/exec), so co-citation alone is not evidence of duplication.

**Verifiers also corrected the surviving claims rather than rubber-stamping them.** Six confirmed findings had their fix or severity amended: severity raised on [206] (minor→major) and lowered on TAXONOMY-48 (blocking→major); the [198] split-note "fix" was refuted outright as an inversion of correct text; [83]'s D0 suggestion was declined; [196]'s optional TAXONOMY-45 was declined; [145]'s sibling cross-reference was corrected from [143] to [25]; and the [8] fix was flagged for retaining "Operation IDs" over-breadth. Two findings had their scope *expanded* by verification ([126] → 3 more siblings; the Q2 sweep → [160] included).

**Net calibration:** the confirmed 20 are well-grounded — each was reproduced independently against the file and the locked sources, with named refutation attempts that failed. Apply the fixes as written above, not as originally proposed, since five of the original fix texts would have introduced new defects.

---

## 5. Residual risk to probe hardest after allocation

Ranked by (probability the class has more instances) × (cost of a post-allocation whole-tree edit):

1. **Incomplete narrowings — the dominant failure mode of this consolidation.** Four confirmed instances ([126]/[151]/[152]/[162], [150], [183], [86]/[94]) all share one signature: `statement` was edited, and `title` / `traversal` / `rationale` / `diagnosticPaths` / `remediation` were not. **Run a mechanical sweep before allocating:** for every entry whose `statement` or `owner` differs from its `entries.json` ancestor, diff the *other* fields and flag any that are byte-identical. That single check would have caught nearly every major finding here, and I would not assume the 20 confirmed are exhaustive.
2. **Q3-versus-`rejectionDeadline` disagreement stated in prose.** The `[126]` cluster escaped every mechanical gate precisely because Q3 names the station in prose ("teardown") rather than by phase code. Verification found Q3 names its own deadline by code in 208/209 entries — but a prose-named station is invisible to that check. Add a lexical check mapping station *names* to phase codes.
3. **Traversal-versus-station reachability.** [51], [86], [94] each declare a station their described traversal cannot reach — a *false coverage claim generated silently in the artifact the gates treat as reviewed coverage*. This is invisible to graph-legality checks (each phase pair is individually legal). Probe every entry whose `traversal` uses a universal quantifier ("any …") or an "extended/through …" endpoint.
4. **Owner correctness at the E0 and C0 stations.** Criterion O was applied by a re-pass that demonstrably had gaps ([116] escaped it; [160] was moved the wrong way; [83] was never re-examined). Re-audit the 16 `core`-owned E0→E0 entries and the create/core boundary specifically, asking in each case whether the protected artefact is on core's enumerated list or merely consulted.
5. **Coverage-gate integrity.** The TAXONOMY-48 finding shows the 178/178 gate can pass on a citation whose entry does not state the rule. After fixing, spot-check that each obligation's citing entries actually *state* it — the gate checks citation presence, not statement fidelity. Note the residual gap the verifier flagged even post-fix: no entry states the Core-side rule that `origin=system` expiry/cleanup/adopt/fence/quarantine work surfaces as a wire-visible Operation kind.
6. **Statement fidelity to locked sources.** [206] (inverted escape hatch), [199] (dropped tuple member, over-strong permanence), [52]/[208] (unsourced "Operation") are three independent instances of statement text drifting from the locked records. These are the hardest to find mechanically and the most damaging downstream, since `statement` is the field the ~1,000 generated selectors are derived from.

**Sequencing recommendation:** apply B1–B3 and all majors, resolve the five conditional additions ([51]×2, [86]/[94]×2, [152]×1) so the final count is fixed, run the sweep in item 1 above, then allocate. Do not allocate against 209.