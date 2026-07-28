import {
  closedSum,
  type ContractModel,
  type OperationContract,
} from "../model.js";
import {
  compareStrings,
  generatedFile,
  generatedName,
  generatedNames,
  generatedSymbolTable,
  operationNames,
  snakeCase,
  type GeneratedFile,
  type GeneratedSymbol,
} from "./common.js";

export function generatePython(
  model: Readonly<ContractModel>,
): readonly GeneratedFile[] {
  assertNames(model);
  const operations = [...model.operations].sort((left, right) =>
    compareStrings(left.operationId, right.operationId),
  );
  return Object.freeze([
    generatedFile("python/contract.py", contractSource(model, operations)),
    generatedFile("python/run.py", runtimeRunner),
    generatedFile(
      "python/test_contract.py",
      generatedTests(model, operations),
    ),
  ]);
}

function contractSource(
  model: Readonly<ContractModel>,
  operations: readonly OperationContract[],
): string {
  return `from __future__ import annotations

from dataclasses import dataclass
from enum import Enum
from typing import Final, Literal, Never, Protocol, TypeAlias, cast

INVALID_OUTCOME: Final = "contract/invalid-outcome"
_CONSTRUCTION_TOKEN: Final = object()


class ContractDiagnostic(ValueError):
    category: Final = INVALID_OUTCOME

    def __init__(self) -> None:
        super().__init__(INVALID_OUTCOME)


def _invalid() -> ContractDiagnostic:
    return ContractDiagnostic()


def _require(condition: bool) -> None:
    if not condition:
        raise _invalid()


${closedSums(model)}
OperationId: TypeAlias = Literal[${operations
    .map((operation) => literal(operation.operationId))
    .join(", ")}]

${operations.map((operation) => operationTypes(model, operation)).join("\n")}
InvocationOutcome: TypeAlias = ${operations
    .map((operation) => `${operationName(operation)}Outcome`)
    .join(" | ")}


class PacketEService(Protocol):
${operations
  .map(
    (operation) =>
      `    def ${snakeCase(operationName(operation))}(self) -> ${operationName(operation)}Outcome:
        ...`,
  )
  .join("\n\n")}


${operations.map(operationDecoder).join("\n")}
def decode_outcome(value: object) -> InvocationOutcome:
    dict_value = _plain_dict(value)
    operation_id = _string_field(dict_value, "operationId")
${operations
  .map(
    (operation, index) =>
      `    ${index === 0 ? "if" : "elif"} operation_id == ${literal(operation.operationId)}:
        return decode_${snakeCase(operationName(operation))}_outcome(value)`,
  )
  .join("\n")}
    raise _invalid()


def _plain_dict(value: object) -> dict[str, object]:
    if type(value) is not dict:
        raise _invalid()
    return cast(dict[str, object], value)


def _exact_keys(value: dict[str, object], expected: frozenset[str]) -> None:
    if any(type(key) is not str for key in value) or frozenset(value.keys()) != expected:
        raise _invalid()


def _string_field(value: dict[str, object], key: str) -> str:
    field = value.get(key)
    if type(field) is not str:
        raise _invalid()
    return field


def _exact_value(value: dict[str, object], key: str, expected: str) -> None:
    if _string_field(value, key) != expected:
        raise _invalid()
`;
}

function closedSums(model: Readonly<ContractModel>): string {
  return [...model.closedSums]
    .sort((left, right) => compareStrings(left.id, right.id))
    .map((sum) => {
      const variants = [...sum.variants]
        .sort((left, right) => compareStrings(left.id, right.id))
        .map((variant) => {
          if (variant.wireTag === undefined) {
            throw new Error("contract/generated-wire-tag-invalid");
          }
          return `    ${enumMember(variant.id)} = (${literal(variant.id)}, ${literal(variant.wireTag)})`;
        })
        .join("\n");
      return `class ${generatedName(sum.id)}(Enum):
${variants}

    def __init__(self, stable_id: str, wire_tag: str) -> None:
        self._stable_id = stable_id
        self._wire_tag = wire_tag

    @property
    def stable_id(self) -> str:
        return self._stable_id

    @property
    def wire_tag(self) -> str:
        return self._wire_tag
`;
    })
    .join("\n\n");
}

function operationTypes(
  model: Readonly<ContractModel>,
  operation: OperationContract,
): string {
  const name = operationName(operation);
  const branches = operation.resultBranches.map((branch) =>
    branchClass(operation, branch),
  );
  return `${subsetType(
    model,
    `${name}RequestError`,
    closedSum(model, "registry.request.error").id,
    operation.allowedRequestErrors,
  )}
${subsetType(
  model,
  `${name}RecoveryError`,
  closedSum(model, "registry.recovery.error").id,
  operation.allowedRecoveryErrors,
)}
${subsetType(
  model,
  `${name}KnownFailure`,
  closedSum(model, "registry.known.failure").id,
  operation.allowedKnownFailures,
)}
${subsetType(
  model,
  `${name}Ambiguity`,
  closedSum(model, "registry.ambiguity").id,
  operation.allowedAmbiguities,
)}
@dataclass(frozen=True, slots=True, init=False)
class ${name}Carrier:
    def __init__(self, token: object) -> None:
        _require(token is _CONSTRUCTION_TOKEN)

    @classmethod
    def _create(cls) -> ${name}Carrier:
        return cls(_CONSTRUCTION_TOKEN)

    @property
    def carrier_kind(self) -> str:
        return ${literal(operation.result.carrierKind)}

    @property
    def schema_stable_id(self) -> str:
        return ${literal(operation.result.schemaStableId)}


${branches.join("\n\n")}
${name}Outcome: TypeAlias = ${operation.resultBranches
    .map((branch) => `${name}${generatedName(branch)}`)
    .join(" | ")}
`;
}

function subsetType(
  model: Readonly<ContractModel>,
  name: string,
  registryId: string,
  stableIds: readonly string[],
): string {
  if (stableIds.length === 0) {
    return `${name}: TypeAlias = Never\n`;
  }
  const registry = model.closedSums.find((sum) => sum.id === registryId);
  if (registry === undefined) {
    throw new Error("contract/generated-registry-missing");
  }
  const variants = [...stableIds].sort(compareStrings).map((stableId) => {
    const variant = registry.variants.find(
      (candidate) => candidate.id === stableId,
    );
    if (variant === undefined || variant.wireTag === undefined) {
      throw new Error("contract/generated-subset-invalid");
    }
    return `    ${enumMember(stableId)} = ${literal(stableId)}`;
  });
  return `class ${name}(Enum):
${variants.join("\n")}
`;
}

function branchClass(
  operation: OperationContract,
  branch: OperationContract["resultBranches"][number],
): string {
  const name = operationName(operation);
  const className = `${name}${generatedName(branch)}`;
  if (branch === "accepted" || branch === "observed") {
    return `@dataclass(frozen=True, slots=True)
class ${className}:
    operation_id: str
    branch: str
    carrier: ${name}Carrier

    def __init_subclass__(cls, **kwargs: object) -> None:
        raise TypeError("contract branch classes are sealed")

    def __post_init__(self) -> None:
        _require(type(self.operation_id) is str and self.operation_id == ${literal(operation.operationId)})
        _require(type(self.branch) is str and self.branch == ${literal(branch)})
        _require(type(self.carrier) is ${name}Carrier)

    @property
    def carrier_kind(self) -> str:
        return self.carrier.carrier_kind

    @property
    def schema_stable_id(self) -> str:
        return self.carrier.schema_stable_id
`;
  }
  const field =
    branch === "rejected" ? "request_error_id" : "recovery_error_id";
  const fieldType =
    branch === "rejected" ? `${name}RequestError` : `${name}RecoveryError`;
  return `@dataclass(frozen=True, slots=True)
class ${className}:
    operation_id: str
    branch: str
    ${field}: ${fieldType}

    def __init_subclass__(cls, **kwargs: object) -> None:
        raise TypeError("contract branch classes are sealed")

    def __post_init__(self) -> None:
        _require(type(self.operation_id) is str and self.operation_id == ${literal(operation.operationId)})
        _require(type(self.branch) is str and self.branch == ${literal(branch)})
        _require(type(self.${field}) is ${fieldType})
`;
}

function operationDecoder(operation: OperationContract): string {
  const name = operationName(operation);
  const functionName = snakeCase(name);
  return `def decode_${functionName}_outcome(value: object) -> ${name}Outcome:
    dict_value = _plain_dict(value)
    _exact_value(dict_value, "operationId", ${literal(operation.operationId)})
    branch = _string_field(dict_value, "branch")
${operation.resultBranches
  .map((branch, index) => decoderBranch(operation, branch, index))
  .join("\n")}
    raise _invalid()
`;
}

function decoderBranch(
  operation: OperationContract,
  branch: OperationContract["resultBranches"][number],
  index: number,
): string {
  const name = operationName(operation);
  const className = `${name}${generatedName(branch)}`;
  const prefix = `    ${index === 0 ? "if" : "elif"} branch == ${literal(branch)}:`;
  if (branch === "accepted" || branch === "observed") {
    return `${prefix}
        _exact_keys(dict_value, frozenset(("operationId", "branch", "carrierKind", "schemaStableId")))
        _exact_value(dict_value, "carrierKind", ${literal(operation.result.carrierKind)})
        _exact_value(dict_value, "schemaStableId", ${literal(operation.result.schemaStableId)})
        return ${className}(
            operation_id=_string_field(dict_value, "operationId"),
            branch=branch,
            carrier=${name}Carrier._create(),
        )`;
  }
  const jsonField =
    branch === "rejected" ? "requestErrorId" : "recoveryErrorId";
  const pythonField =
    branch === "rejected" ? "request_error_id" : "recovery_error_id";
  const errorType =
    branch === "rejected" ? `${name}RequestError` : `${name}RecoveryError`;
  return `${prefix}
        _exact_keys(dict_value, frozenset(("operationId", "branch", "${jsonField}")))
        try:
            reason = ${errorType}(_string_field(dict_value, "${jsonField}"))
        except ValueError:
            raise _invalid() from None
        return ${className}(
            operation_id=_string_field(dict_value, "operationId"),
            branch=branch,
            ${pythonField}=reason,
        )`;
}

function generatedTests(
  model: Readonly<ContractModel>,
  operations: readonly OperationContract[],
): string {
  const fixtures = operations.flatMap((operation) => [
    fixtureCase(model, operation, true),
    fixtureCase(model, operation, false),
  ]);
  const fixtureRows = fixtures
    .map(
      ({ name, value, valid }) =>
        `    ${literal(name)}: (${pythonBytes(`${JSON.stringify(value)}\n`)}, ${valid ? "True" : "False"}),`,
    )
    .join("\n");
  return `from __future__ import annotations

import json
import os
from pathlib import Path
import unittest

from contract import (
    ContractDiagnostic,
    decode_outcome,
${operations
  .map((operation) => {
    const branch = successBranch(operation);
    return `    ${operationName(operation)}${generatedName(branch)},`;
  })
  .join("\n")}
)


EXPECTED_FIXTURES: dict[str, tuple[bytes, bool]] = {
${fixtureRows}
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
${operations
  .map((operation) => {
    const branch = successBranch(operation);
    const className = `${operationName(operation)}${generatedName(branch)}`;
    return `        with self.assertRaises(ContractDiagnostic):
            ${className}(
                operation_id=${literal(operation.operationId)},
                branch=${literal(branch)},
                carrier=object(),
            )`;
  })
  .join("\n")}

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
`;
}

function fixtureCase(
  model: Readonly<ContractModel>,
  operation: OperationContract,
  valid: boolean,
): Readonly<{ name: string; value: Readonly<Record<string, string>>; valid: boolean }> {
  const name = snakeCase(operationName(operation)).replaceAll("_", "-");
  if (valid) {
    const branch = successBranch(operation);
    return {
      name: `${name}-valid.json`,
      value: carrierValue(operation, branch),
      valid,
    };
  }
  switch (operation.callClass) {
    case "durableOperationMutation": {
      const disallowed = closedSum(model, "registry.request.error").variants.find(
        (variant) => !operation.allowedRequestErrors.includes(variant.id),
      );
      if (disallowed === undefined) {
        throw new Error("contract/generated-fixture-case-unavailable");
      }
      return {
        name: `${name}-invalid.json`,
        value: {
          operationId: operation.operationId,
          branch: "rejected",
          requestErrorId: disallowed.id,
        },
        valid,
      };
    }
    case "existingHandleIntent":
      return {
        name: `${name}-invalid.json`,
        value: carrierValue(operation, "observed"),
        valid,
      };
    case "observation":
      return {
        name: `${name}-invalid.json`,
        value: carrierValue(operation, "accepted"),
        valid,
      };
    case "sequencedProcessControl": {
      const other =
        model.operations.find(
          (candidate) =>
            candidate.callClass === "durableOperationMutation" &&
            candidate.result.carrierKind !== operation.result.carrierKind,
        ) ??
        model.operations.find(
          (candidate) =>
            candidate.result.carrierKind !== operation.result.carrierKind,
        );
      if (other === undefined) {
        throw new Error("contract/generated-fixture-case-unavailable");
      }
      return {
        name: `${name}-invalid.json`,
        value: {
          operationId: operation.operationId,
          branch: "accepted",
          carrierKind: other.result.carrierKind,
          schemaStableId: operation.result.schemaStableId,
        },
        valid,
      };
    }
  }
}

function successBranch(
  operation: OperationContract,
): "accepted" | "observed" {
  if (operation.resultBranches.includes("accepted")) {
    return "accepted";
  }
  if (operation.resultBranches.includes("observed")) {
    return "observed";
  }
  throw new Error("contract/generated-success-branch-missing");
}

function carrierValue(
  operation: OperationContract,
  branch: "accepted" | "observed",
): Readonly<Record<string, string>> {
  return {
    operationId: operation.operationId,
    branch,
    carrierKind: operation.result.carrierKind,
    schemaStableId: operation.result.schemaStableId,
  };
}

const runtimeRunner = `from __future__ import annotations

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
`;

function operationName(operation: OperationContract): string {
  const prefix = "operation.";
  if (!operation.operationId.startsWith(prefix)) {
    throw new Error("contract/generated-name-invalid");
  }
  return generatedName(operation.operationId.slice(prefix.length));
}

function assertNames(model: Readonly<ContractModel>): void {
  generatedNames([
    ...new Set([
      ...model.closedSums.map((sum) => sum.id),
      ...model.closedSums.flatMap((sum) =>
        sum.variants.map((variant) => variant.id),
      ),
      ...model.operations.map((operation) => operation.operationId),
      ...model.operations.flatMap((operation) => [
        ...operation.allowedRequestErrors,
        ...operation.allowedRecoveryErrors,
        ...operation.allowedKnownFailures,
        ...operation.allowedAmbiguities,
      ]),
    ]),
  ]);
  operationNames(model);
  assertPythonScopes(model);
}

function assertPythonScopes(model: Readonly<ContractModel>): void {
  const moduleSymbols: GeneratedSymbol[] = [
    ...[
      "dataclass",
      "Enum",
      "Final",
      "Literal",
      "Never",
      "Protocol",
      "TypeAlias",
      "cast",
      "INVALID_OUTCOME",
      "_CONSTRUCTION_TOKEN",
      "ContractDiagnostic",
      "_invalid",
      "_require",
      "OperationId",
      "InvocationOutcome",
      "PacketEService",
      "decode_outcome",
      "_plain_dict",
      "_exact_keys",
      "_string_field",
      "_exact_value",
    ].map((name) => ({ source: `module:${name}`, name })),
  ];

  for (const [sumIndex, sum] of model.closedSums.entries()) {
    moduleSymbols.push({
      source: `closed-sum:${sumIndex}:${sum.id}`,
      name: generatedName(sum.id),
    });
    pythonSymbolTable([
      ...[
        "__init__",
        "_stable_id",
        "_wire_tag",
        "stable_id",
        "wire_tag",
      ].map((name) => ({
        source: `closed-sum:${sumIndex}:member:${name}`,
        name,
      })),
      ...sum.variants.map((variant, variantIndex) => ({
        source: `closed-sum:${sumIndex}:variant:${variantIndex}:${variant.id}`,
        name: enumMember(variant.id),
      })),
    ]);
  }

  const serviceSymbols: GeneratedSymbol[] = [];
  for (const [operationIndex, operation] of model.operations.entries()) {
    const name = operationName(operation);
    for (const suffix of [
      "RequestError",
      "RecoveryError",
      "KnownFailure",
      "Ambiguity",
      "Carrier",
      "Outcome",
    ]) {
      moduleSymbols.push({
        source: `operation:${operationIndex}:${operation.operationId}:${suffix}`,
        name: `${name}${suffix}`,
      });
    }
    for (const [branchIndex, branch] of operation.resultBranches.entries()) {
      moduleSymbols.push({
        source: `operation:${operationIndex}:${operation.operationId}:branch:${branchIndex}:${branch}`,
        name: `${name}${generatedName(branch)}`,
      });
    }
    moduleSymbols.push({
      source: `operation:${operationIndex}:${operation.operationId}:decoder`,
      name: `decode_${snakeCase(name)}_outcome`,
    });
    serviceSymbols.push({
      source: `operation:${operationIndex}:${operation.operationId}:service`,
      name: snakeCase(name),
    });

    for (const [subset, stableIds] of [
      ["request-error", operation.allowedRequestErrors],
      ["recovery-error", operation.allowedRecoveryErrors],
      ["known-failure", operation.allowedKnownFailures],
      ["ambiguity", operation.allowedAmbiguities],
    ] as const) {
      if (stableIds.length > 0) {
        pythonSymbolTable(
          stableIds.map((stableId, stableIdIndex) => ({
            source: `operation:${operationIndex}:${subset}:${stableIdIndex}:${stableId}`,
            name: enumMember(stableId),
          })),
        );
      }
    }
  }

  pythonSymbolTable(moduleSymbols);
  pythonSymbolTable(serviceSymbols);
}

const pythonIdentifierPattern = /^[A-Za-z_][A-Za-z0-9_]*$/;
// Python 3.13 hard keywords. Soft keywords remain valid in these declaration
// positions.
const pythonKeywords: ReadonlySet<string> = new Set([
  "False",
  "None",
  "True",
  "and",
  "as",
  "assert",
  "async",
  "await",
  "break",
  "class",
  "continue",
  "def",
  "del",
  "elif",
  "else",
  "except",
  "finally",
  "for",
  "from",
  "global",
  "if",
  "import",
  "in",
  "is",
  "lambda",
  "nonlocal",
  "not",
  "or",
  "pass",
  "raise",
  "return",
  "try",
  "while",
  "with",
  "yield",
]);

function pythonSymbolTable(
  symbols: readonly GeneratedSymbol[],
): ReadonlyMap<string, string> {
  const table = generatedSymbolTable(symbols);
  for (const name of table.values()) {
    if (!pythonIdentifierPattern.test(name) || pythonKeywords.has(name)) {
      throw new Error("contract/generated-name-invalid");
    }
  }
  return table;
}

function enumMember(stableId: string): string {
  return snakeCase(generatedName(stableId)).toUpperCase();
}

function pythonBytes(value: string): string {
  return `b${literal(value)}`;
}

function literal(value: string): string {
  return JSON.stringify(value);
}
