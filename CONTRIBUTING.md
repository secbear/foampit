# Contributing to Foampit

Foampit is currently a design and executable-research repository. Changes must
preserve the distinction between normative product decisions, open research
questions, disposable prototypes, and future production implementation.

## Start here

Read these documents in order:

1. [`docs/greenfield/DESIGN.md`](docs/greenfield/DESIGN.md)
2. [`docs/greenfield/CONFIGURATION-BOUNDARY-AUDIT.md`](docs/greenfield/CONFIGURATION-BOUNDARY-AUDIT.md)
3. [`docs/greenfield/TARGET-IMPLEMENTATION-STRATEGY.md`](docs/greenfield/TARGET-IMPLEMENTATION-STRATEGY.md)
4. [`docs/greenfield/research/INVARIANT-ENFORCEMENT.md`](docs/greenfield/research/INVARIANT-ENFORCEMENT.md)
5. [`docs/greenfield/research/RESEARCH-STANDARD.md`](docs/greenfield/research/RESEARCH-STANDARD.md)

Sections marked **Locked** may change only through an explicit design decision
that updates the rationale, affected invariants, coverage registries, and
executable evidence.

## Repository rules

- Do not import architecture or terminology from the predecessor MCP project.
- Do not collapse Artifact Definition, CreateSandbox, Operator Configuration,
  Managed-Sandbox Service Definition, framework-adapter, or driver ownership.
- Do not expose arbitrary target arguments or upstream option trees as the
  portable Foampit contract.
- Add every new configuration, composition, transport, provider, or direct
  driver route to the closed invariant/path inventories before claiming it is
  supported.
- Generated files under the contract-compiler prototype are never edited by
  hand. Change their source generator, then regenerate and compare.
- Research claims must follow the locked research standard and clearly
  distinguish proven production practice, academic or novel work, prototype
  evidence, and open assumptions.

## Definitions are duplicated on purpose — keep the copies in lockstep

Several definitions are stated in more than one place so that no component
defines its own correctness. That duplication is deliberate and must not be
collapsed: it is what makes a coordinated mutation detectable rather than
merely inconsistent. What it needs is comparison, which
`check-model-coherence.sh` provides.

Before changing any of the following, change **every** copy in the same commit:

| Definition | Copies |
|---|---|
| Product-phase succession graph | `validate-registry.jq`, `validate-composition-coverage.jq`, `generate-composition-coverage.mjs`, the corpus phase table, the `INVARIANT-ENFORCEMENT.md` mermaid |
| Closed owner set | `validate-registry.jq`, `validate-surface-coverage.jq`, `validate-composition-coverage.jq`, `generate-composition-coverage.mjs`, the corpus owners table |
| `placeholder_strings` | every ledger validator — a validator that *omits* it is the failure mode a copy-versus-copy diff cannot see |
| Each digest pin | the validator's own `def`, and `check-inventory.sh` |
| Registry length and cell count | `test-registry.sh`, `check-inventory.sh`, `generate-composition-coverage.mjs`, `validate-composition-coverage.jq`, `test-composition-coverage.sh` |

Adding an invariant additionally requires a corpus `####` heading, a `VAL-`
witness, a classification character appended to all 54 Packet D vectors, matrix
regeneration, and re-pinned digests. `validate-registry.sh` alone cannot catch
an unaliased composition-path token — it checks `compositionPaths` only as a
non-empty string array.

### Composition-path tokens

The token vocabulary is **derived, not declared**: `registryPathAliases` keys
must equal the set of tokens the registry actually uses. It is not frozen, but
growing it is a considered act, and two conventions bind:

- **Identity form** — a newly minted token is always `key == value`. Unqualified
  keys are historical records of pre-rename usage; minting one would fabricate a
  legacy name.
- **Canonical declaration** — where several tokens alias one path, new
  declarations use the identity token. Historically a token that was also a
  `trustBoundaries` value was discharged for free by the `wire-corruption` test.
  Since 2026-08-03 that is true only for the thirteen `decoding_trust_boundaries`,
  because the `wire-corruption` obligation is now conditional on a boundary that
  actually decodes a representation.

Only **active** classification cells (`may-contribute`, `may-narrow`,
`may-select`) require a declaring `compositionPaths` entry. `boundary-input`
cells do not — 702 of 828 are undeclared matrix-wide and that is correct.

## Verification

For changes to the design corpus or configuration-language prototypes:

```sh
docs/greenfield/research/invariants/check-inventory.sh
docs/greenfield/research/prototypes/test-all.sh
```

`check-inventory.sh` runs `check-model-coherence.sh` first. A drifted
vocabulary makes every downstream result untrustworthy, so that check gates the
rest.

For changes to the Packet E contract compiler:

```sh
tests/standalone-contract-compiler.sh
docs/greenfield/research/prototypes/packet-e-contract-compiler/test.sh
```

`check-enforcement-closure.sh` is intentionally expected to fail while Gate 4B
remains open. Do not turn that failure into a passing placeholder.
