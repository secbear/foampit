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

## Verification

For changes to the design corpus or configuration-language prototypes:

```sh
docs/greenfield/research/invariants/check-inventory.sh
docs/greenfield/research/prototypes/test-all.sh
```

For changes to the Packet E contract compiler:

```sh
tests/standalone-contract-compiler.sh
docs/greenfield/research/prototypes/packet-e-contract-compiler/test.sh
```

`check-enforcement-closure.sh` is intentionally expected to fail while Gate 4B
remains open. Do not turn that failure into a passing placeholder.
