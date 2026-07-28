# Foampit repository provenance

Foampit begins with fresh Git history. Its initial contents were assembled on
2026-07-28 from two preserved inputs in the predecessor workspace:

- the complete greenfield design, research, invariant, and prototype corpus
  rooted at `docs/greenfield/`; and
- the verified Packet E contract-compiler prototype from commit
  `0561e4acaeccb7b16426f9fdd78234ee74fe396d` on
  `codex/contract-compiler-prototype`.

Before extraction, the preserved prototype branch completed its original
22-stage harness with:

- 14 test files and 163 passing compiler/generator/formal tests;
- 20 independently assigned CUE structural mutations;
- 11 independently assigned Quint temporal mutants;
- 16 deterministic generated artifacts; and
- the predecessor daemon's 28-test baseline as an external regression
  sentinel.

The daemon sentinel was intentionally removed during standalone extraction.
It proved that prototype development had not damaged unrelated predecessor
code, but it was not part of Foampit's compiler semantics. The current harness
has 21 product-owned stages, manifests only its own inputs, and can run when
copied without an ancestor repository.

No predecessor daemon, MCP transport, agent shim, Nix implementation, root
flake, configuration file, README, or Git history was imported into Foampit.
Historical references inside completed research plans remain evidence about
the work as it was executed; they are not product dependencies.
