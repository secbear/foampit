#!/usr/bin/env bash
# Packet F classification lattice: algebraic properties, and reproduction of disclosure
# rules the repository states independently of the model.
set -euo pipefail
exec node "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lattice.mjs"
