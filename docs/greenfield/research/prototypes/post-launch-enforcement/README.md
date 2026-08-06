# Post-launch enforcement slice

Status: **Disposable research slice — measures whether the Packet E invariant
model survives implementation**

Every product phase from `R0` onward had **zero** implementation surface before
this directory existed, while Packet E registers 164 invariants whose rejection
deadline falls there. This slice implements the authoritative hook and the
declared test kinds for nine of them, chosen to span five owners, six rejection
deadlines, and all three dispositions present in the region.

It is not a runtime, a driver, or a product. It is the smallest model of the
post-launch pipeline that can actually reject, so that the registry's claims
about enforceability can be checked rather than assumed.

The nine:

| Invariant | Owner | Phases | Disposition |
|---|---|---|---|
| `ADM-005` | live | `L0 -> L0` | reject-at-boundary |
| `ADM-007` | exec | `E0 -> E0` | reject-at-boundary |
| `ADM-009` | core | `E0 -> E1` | reject-at-boundary |
| `ADM-012` | core | `R1 -> R1` | observed-conformance |
| `ADP-012` | service | `S0 -> L0` | reject-at-boundary |
| `ERR-002` | core | `L0 -> L0` | unrepresentable |
| `PIO-004` | exec | `E0 -> E0` | unrepresentable |
| `PRC-007` | core | `T0 -> T0` | observed-conformance |
| `SBX-004` | core | `L1 -> L1` | unrepresentable |

Findings are recorded in [`FINDINGS.md`](./FINDINGS.md). The findings are the
deliverable; the code is the instrument.

```sh
./test.sh
```
