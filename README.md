# Foampit

Foampit is a greenfield design for declarative, reproducible agent sandboxes.
It uses Nix to define and build immutable sandbox artifact sets while keeping
live runtime bindings, operator policy, and framework lifecycle outside the
artifact identity.

The intended product supports several isolation shapes behind one owned
semantic contract:

- bubblewrap sandboxes for lightweight host-kernel isolation;
- microVM sandboxes for stronger kernel boundaries;
- OCI artifacts and runtimes where container interoperability is required; and
- later local or remote drivers only when their real capabilities can satisfy
  the same conformance model.

Foampit is not an MCP server and does not require agents to adopt one protocol.
CLIs, SDK integrations, managed services, and future framework adapters all
translate into the same Core Sandbox API.

## Status

**Design and executable research; not a production sandbox runtime.**

The repository currently contains:

- the [normative design and product specification](docs/greenfield/DESIGN.md);
- the
  [configuration-boundary audit](docs/greenfield/CONFIGURATION-BOUNDARY-AUDIT.md);
- the
  [target implementation strategy](docs/greenfield/TARGET-IMPLEMENTATION-STRATEGY.md);
- a machine-readable
  [invariant inventory](docs/greenfield/research/invariants/invariants.json)
  with coverage and enforcement protocols;
- configuration-language and trust-boundary research prototypes; and
- an executable
  [Packet E contract-compiler vertical slice](docs/greenfield/research/prototypes/packet-e-contract-compiler/README.md).

The prototype demonstrates one canonical product-owned contract model
generating closed Rust, Go, TypeScript, Python, Protobuf, OpenAPI, CUE, and
Quint boundaries. Its recommendation remains **revise**, not productionize.

## Architectural boundary

Foampit deliberately separates four resources:

1. **Artifact Definition** builds immutable content, hard policy, capability
   requirements, and target artifacts.
2. **CreateSandbox input** binds one live sandbox to concrete workspace paths,
   resources, secrets, placement, and provider selections.
3. **Operator Configuration** owns hosts, drivers, credentials, capacity,
   admission, global ceilings, and evidence sinks.
4. **Managed-Sandbox Service Definition** optionally lets NixOS declaratively
   manage live sandboxes through the same runtime API.

Changing something declaratively does not automatically make it part of an
artifact. Identity and lifecycle determine ownership.

## Reproduce the current evidence

Run the configuration-language and boundary prototypes:

```sh
docs/greenfield/research/prototypes/test-all.sh
```

Run the standalone contract-compiler preflight:

```sh
tests/standalone-contract-compiler.sh
```

Run the complete pinned contract-compiler harness:

```sh
docs/greenfield/research/prototypes/packet-e-contract-compiler/test.sh
```

The full compiler harness creates an isolated temporary work tree, installs
only frozen dependencies through its pinned Nix shell, executes 163 tests and
the generated-language/formal oracles, verifies two independent generations
byte-for-byte, and checks its source manifest before and after execution.

See [CONTRIBUTING.md](CONTRIBUTING.md) before changing a locked design decision,
invariant, generated artifact, or prototype measurement.
