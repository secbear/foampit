from __future__ import annotations

import json
from pathlib import Path
import sys

from contract import ContractDiagnostic, INVALID_OUTCOME, decode_outcome


def _object(pairs: list[tuple[str, object]]) -> dict[str, object]:
    value: dict[str, object] = {}
    for key, item in pairs:
        if key in value:
            raise ContractDiagnostic()
        value[key] = item
    return value


def main() -> None:
    if len(sys.argv) != 2:
        raise ValueError("fixture path required")
    try:
        raw = Path(sys.argv[1]).read_bytes()
        value = json.loads(raw, object_pairs_hook=_object)
        outcome = decode_outcome(value)
        print(f"{outcome.operation_id}:{outcome.branch}")
    except ContractDiagnostic:
        print(INVALID_OUTCOME)


if __name__ == "__main__":
    main()
