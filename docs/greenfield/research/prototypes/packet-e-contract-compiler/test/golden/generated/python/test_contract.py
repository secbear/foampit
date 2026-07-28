from __future__ import annotations

import json
import os
from pathlib import Path
import unittest

from contract import (
    ContractDiagnostic,
    decode_outcome,
    CancelOperationAccepted,
    StartSandboxAccepted,
    WaitOperationObserved,
    WriteProcessInputAccepted,
)


EXPECTED_FIXTURES: dict[str, tuple[bytes, bool]] = {
    "cancel-operation-valid.json": (b"{\"operationId\":\"operation.cancel.operation\",\"branch\":\"accepted\",\"carrierKind\":\"existingOperationObservation\",\"schemaStableId\":\"result.existing.operation.observation\"}\n", True),
    "cancel-operation-invalid.json": (b"{\"operationId\":\"operation.cancel.operation\",\"branch\":\"observed\",\"carrierKind\":\"existingOperationObservation\",\"schemaStableId\":\"result.existing.operation.observation\"}\n", False),
    "start-sandbox-valid.json": (b"{\"operationId\":\"operation.start.sandbox\",\"branch\":\"accepted\",\"carrierKind\":\"newDurableOperation\",\"schemaStableId\":\"result.operation.start.sandbox\"}\n", True),
    "start-sandbox-invalid.json": (b"{\"operationId\":\"operation.start.sandbox\",\"branch\":\"rejected\",\"requestErrorId\":\"request.sequence.out.of.range\"}\n", False),
    "wait-operation-valid.json": (b"{\"operationId\":\"operation.wait.operation\",\"branch\":\"observed\",\"carrierKind\":\"observation\",\"schemaStableId\":\"result.operation.wait.observation\"}\n", True),
    "wait-operation-invalid.json": (b"{\"operationId\":\"operation.wait.operation\",\"branch\":\"accepted\",\"carrierKind\":\"observation\",\"schemaStableId\":\"result.operation.wait.observation\"}\n", False),
    "write-process-input-valid.json": (b"{\"operationId\":\"operation.write.process.input\",\"branch\":\"accepted\",\"carrierKind\":\"processControlReceipt\",\"schemaStableId\":\"result.process.control.receipt\"}\n", True),
    "write-process-input-invalid.json": (b"{\"operationId\":\"operation.write.process.input\",\"branch\":\"accepted\",\"carrierKind\":\"newDurableOperation\",\"schemaStableId\":\"result.process.control.receipt\"}\n", False),
}


class ContractTests(unittest.TestCase):
    def test_exact_shared_fixture_bytes_and_decoding(self) -> None:
        fixture_root = Path(os.environ["PACKET_E_OUTCOME_FIXTURES"])
        seen: set[bytes] = set()
        for filename, (expected_bytes, valid) in EXPECTED_FIXTURES.items():
            raw = (fixture_root / filename).read_bytes()
            self.assertEqual(raw, expected_bytes, filename)
            self.assertNotIn(raw, seen, filename)
            seen.add(raw)
            value = json.loads(raw)
            if valid:
                outcome = decode_outcome(value)
                self.assertEqual(
                    f"{outcome.operation_id}:{outcome.branch}",
                    f"{value['operationId']}:{value['branch']}",
                )
            else:
                with self.assertRaises(ContractDiagnostic):
                    decode_outcome(value)
        self.assertEqual(len(seen), 8)

    def test_invalid_direct_construction_is_rejected(self) -> None:
        with self.assertRaises(ContractDiagnostic):
            CancelOperationAccepted(
                operation_id="operation.cancel.operation",
                branch="accepted",
                carrier=object(),
            )
        with self.assertRaises(ContractDiagnostic):
            StartSandboxAccepted(
                operation_id="operation.start.sandbox",
                branch="accepted",
                carrier=object(),
            )
        with self.assertRaises(ContractDiagnostic):
            WaitOperationObserved(
                operation_id="operation.wait.operation",
                branch="observed",
                carrier=object(),
            )
        with self.assertRaises(ContractDiagnostic):
            WriteProcessInputAccepted(
                operation_id="operation.write.process.input",
                branch="accepted",
                carrier=object(),
            )

    def test_nonplain_extra_and_mismatched_values_are_rejected(self) -> None:
        probes: tuple[object, ...] = (
            [],
            {"operationId": "operation.unknown", "branch": "accepted"},
            {
                "operationId": "operation.start.sandbox",
                "branch": "accepted",
                "carrierKind": "newDurableOperation",
                "schemaStableId": "result.operation.start.sandbox",
                "extra": "forbidden",
            },
            {
                "operationId": "operation.start.sandbox",
                "branch": "recovery",
                "recoveryErrorId": "request.invalid.state",
            },
            {
                "operationId": "operation.start.sandbox",
                "branch": "accepted",
                "carrierKind": "newDurableOperation",
                "schemaStableId": "result.process.control.receipt",
            },
        )
        for probe in probes:
            with self.subTest(probe=probe):
                with self.assertRaises(ContractDiagnostic):
                    decode_outcome(probe)


if __name__ == "__main__":
    unittest.main()
