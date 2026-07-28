import {
  closedSum,
  type ClosedSum,
  type ClosedVariant,
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
import { assertPortableWireTags } from "../wire-tag.js";

export function generateProtobuf(
  model: Readonly<ContractModel>,
): readonly GeneratedFile[] {
  assertPortableWireTags(model);
  assertNames(model);
  const operations = [...model.operations].sort((left, right) =>
    compareStrings(left.operationId, right.operationId),
  );
  return Object.freeze([
    generatedFile(
      "protobuf/contract.proto",
      `${header}
${variantMarkers(model)}
${globalSums(model)}
${operations.map((operation) => operationMessages(model, operation)).join("\n")}
`,
    ),
  ]);
}

const header = `syntax = "proto3";

package packet_e.contract.v1;

import "google/protobuf/descriptor.proto";

extend google.protobuf.MessageOptions {
  string stable_id = 50001;
  string operation_id = 50002;
  string carrier_kind = 50003;
  string schema_stable_id = 50004;
}

extend google.protobuf.FieldOptions {
  string variant_stable_id = 50001;
  string variant_wire_tag = 50002;
}
`;

function variantMarkers(model: Readonly<ContractModel>): string {
  return [...model.closedSums]
    .flatMap((sum) => sum.variants)
    .sort((left, right) => compareStrings(left.id, right.id))
    .map(
      (variant) => `message ${generatedName(variant.id)} {
  option (stable_id) = ${literal(variant.id)};
}
`,
    )
    .join("\n");
}

function globalSums(model: Readonly<ContractModel>): string {
  return [...model.closedSums]
    .sort((left, right) => compareStrings(left.id, right.id))
    .map((sum) => closedSumMessage(sum))
    .join("\n");
}

function closedSumMessage(sum: ClosedSum): string {
  const fields = sortedVariants(sum.variants)
    .map((variant) => variantField(variant, generatedName(variant.id)))
    .join("\n");
  return `message ${generatedName(sum.id)} {
  option (stable_id) = ${literal(sum.id)};

  oneof variant {
${fields}
  }
}
`;
}

function operationMessages(
  model: Readonly<ContractModel>,
  operation: OperationContract,
): string {
  const name = operationName(operation);
  return `${projectionMessage(
    `${name}RequestError`,
    operation,
    closedSum(model, "registry.request.error"),
    operation.allowedRequestErrors,
  )}
${projectionMessage(
  `${name}RecoveryError`,
  operation,
  closedSum(model, "registry.recovery.error"),
  operation.allowedRecoveryErrors,
)}
${projectionMessage(
  `${name}KnownFailure`,
  operation,
  closedSum(model, "registry.known.failure"),
  operation.allowedKnownFailures,
)}
${projectionMessage(
  `${name}Ambiguity`,
  operation,
  closedSum(model, "registry.ambiguity"),
  operation.allowedAmbiguities,
)}
message ${name}Carrier {
  option (operation_id) = ${literal(operation.operationId)};
  option (stable_id) = ${literal(operation.result.schemaStableId)};
  option (carrier_kind) = ${literal(operation.result.carrierKind)};
  option (schema_stable_id) = ${literal(operation.result.schemaStableId)};
}

${outcomeMessage(model, operation)}
`;
}

function projectionMessage(
  name: string,
  operation: OperationContract,
  registry: ClosedSum,
  allowedStableIds: readonly string[],
): string {
  const allowed = new Set(allowedStableIds);
  const admitted = sortedVariants(
    registry.variants.filter((variant) => allowed.has(variant.id)),
  );
  const excluded = sortedVariants(
    registry.variants.filter((variant) => !allowed.has(variant.id)),
  );
  if (admitted.length !== allowed.size) {
    throw new Error("contract/generated-subset-invalid");
  }
  const oneof =
    admitted.length === 0
      ? ""
      : `
  oneof variant {
${admitted
  .map((variant) => variantField(variant, generatedName(variant.id)))
  .join("\n")}
  }
`;
  return `message ${name} {
  option (operation_id) = ${literal(operation.operationId)};
  // Current-contract exclusions only; reservations do not prove historical removal.
${oneof}${reservations(excluded, (variant) => variantFieldName(variant.id))}
}
`;
}

function outcomeMessage(
  model: Readonly<ContractModel>,
  operation: OperationContract,
): string {
  const name = operationName(operation);
  const registry =
    operation.callClass === "sequencedProcessControl"
      ? closedSum(model, "registry.process.control.outcome")
      : closedSum(model, "registry.operation.outcome");
  const byBranch = new Map(
    registry.variants.map((variant) => [outcomeBranch(variant.id), variant]),
  );
  const admitted = operation.resultBranches.map((branch) => {
    const variant = byBranch.get(branch);
    if (variant === undefined) {
      throw new Error("contract/generated-outcome-variant-missing");
    }
    return Object.freeze({ branch, variant });
  });
  const admittedBranches = new Set(operation.resultBranches);
  const excluded = sortedVariants(
    registry.variants.filter(
      (variant) => !admittedBranches.has(outcomeBranch(variant.id)),
    ),
  );
  const fields = [...admitted]
    .sort(
      (left, right) =>
        wireNumber(left.variant) - wireNumber(right.variant) ||
        compareStrings(left.branch, right.branch),
    )
    .map(({ branch, variant }) => {
      const fieldType =
        branch === "accepted" || branch === "observed"
          ? `${name}Carrier`
          : branch === "rejected"
            ? `${name}RequestError`
            : `${name}RecoveryError`;
      return `    ${fieldType} ${branch} = ${wireNumber(variant)} ${fieldOptions(variant)};`;
    })
    .join("\n");
  return `message ${name}Outcome {
  option (operation_id) = ${literal(operation.operationId)};
  // Current-contract exclusions only; reservations do not prove historical removal.

  oneof variant {
${fields}
  }
${reservations(excluded, (variant) => outcomeBranch(variant.id))}
}
`;
}

function variantField(variant: ClosedVariant, typeName: string): string {
  return `    ${typeName} ${variantFieldName(variant.id)} = ${wireNumber(variant)} ${fieldOptions(variant)};`;
}

function fieldOptions(variant: ClosedVariant): string {
  const wireTag = requiredWireTag(variant);
  return `[(variant_stable_id) = ${literal(variant.id)}, (variant_wire_tag) = ${literal(wireTag)}]`;
}

function reservations(
  excluded: readonly ClosedVariant[],
  fieldName: (variant: ClosedVariant) => string,
): string {
  if (excluded.length === 0) {
    return "";
  }
  const tags = excluded.map((variant) => wireNumber(variant)).join(", ");
  const names = excluded.map((variant) => literal(fieldName(variant))).join(", ");
  return `  reserved ${tags};
  reserved ${names};
`;
}

function sortedVariants(
  variants: readonly ClosedVariant[],
): readonly ClosedVariant[] {
  return [...variants].sort(
    (left, right) =>
      wireNumber(left) - wireNumber(right) ||
      compareStrings(left.id, right.id),
  );
}

function requiredWireTag(variant: ClosedVariant): string {
  if (variant.wireTag === undefined) {
    throw new Error("contract/generated-wire-tag-invalid");
  }
  return variant.wireTag;
}

function wireNumber(variant: ClosedVariant): number {
  const wireTag = requiredWireTag(variant);
  if (!/^[1-9][0-9]*$/.test(wireTag)) {
    throw new Error("contract/generated-wire-tag-invalid");
  }
  const value = Number(wireTag);
  if (
    !Number.isSafeInteger(value) ||
    value > 536_870_911 ||
    (value >= 19_000 && value <= 19_999)
  ) {
    throw new Error("contract/generated-wire-tag-invalid");
  }
  return value;
}

function outcomeBranch(
  stableId: string,
): OperationContract["resultBranches"][number] {
  for (const prefix of ["outcome.process.", "outcome."]) {
    if (stableId.startsWith(prefix)) {
      const branch = stableId.slice(prefix.length);
      if (
        branch === "accepted" ||
        branch === "observed" ||
        branch === "recovery" ||
        branch === "rejected"
      ) {
        return branch;
      }
    }
  }
  throw new Error("contract/generated-outcome-variant-invalid");
}

function variantFieldName(stableId: string): string {
  return snakeCase(generatedName(stableId));
}

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
    ]),
  ]);
  operationNames(model);
  assertProtobufScopes(model);
}

function assertProtobufScopes(model: Readonly<ContractModel>): void {
  const messageSymbols: GeneratedSymbol[] = [];
  for (const [sumIndex, sum] of model.closedSums.entries()) {
    messageSymbols.push({
      source: `closed-sum:${sumIndex}:${sum.id}`,
      name: generatedName(sum.id),
    });
    generatedSymbolTable([
      { source: `closed-sum:${sumIndex}:oneof`, name: "variant" },
      ...sum.variants.map((variant, variantIndex) => ({
        source: `closed-sum:${sumIndex}:variant:${variantIndex}:${variant.id}`,
        name: variantFieldName(variant.id),
      })),
    ]);
    for (const [variantIndex, variant] of sum.variants.entries()) {
      messageSymbols.push({
        source: `variant-marker:${sumIndex}:${variantIndex}:${variant.id}`,
        name: generatedName(variant.id),
      });
    }
  }

  for (const [operationIndex, operation] of model.operations.entries()) {
    const name = operationName(operation);
    const projections = [
      [
        `${name}RequestError`,
        closedSum(model, "registry.request.error"),
        operation.allowedRequestErrors,
      ],
      [
        `${name}RecoveryError`,
        closedSum(model, "registry.recovery.error"),
        operation.allowedRecoveryErrors,
      ],
      [
        `${name}KnownFailure`,
        closedSum(model, "registry.known.failure"),
        operation.allowedKnownFailures,
      ],
      [
        `${name}Ambiguity`,
        closedSum(model, "registry.ambiguity"),
        operation.allowedAmbiguities,
      ],
    ] as const;
    for (const [
      projectionIndex,
      [projectionName, registry, allowedIds],
    ] of projections.entries()) {
      messageSymbols.push({
        source: `operation:${operationIndex}:projection:${projectionIndex}`,
        name: projectionName,
      });
      const allowed = new Set(allowedIds);
      const admitted = registry.variants.filter((variant) =>
        allowed.has(variant.id),
      );
      generatedSymbolTable([
        ...(admitted.length > 0
          ? [
              {
                source: `operation:${operationIndex}:projection:${projectionIndex}:oneof`,
                name: "variant",
              },
            ]
          : []),
        ...registry.variants.map((variant, variantIndex) => ({
          source: `operation:${operationIndex}:projection:${projectionIndex}:variant:${variantIndex}:${variant.id}`,
          name: variantFieldName(variant.id),
        })),
      ]);
    }

    messageSymbols.push(
      {
        source: `operation:${operationIndex}:carrier`,
        name: `${name}Carrier`,
      },
      {
        source: `operation:${operationIndex}:outcome`,
        name: `${name}Outcome`,
      },
    );
    const outcomeRegistry =
      operation.callClass === "sequencedProcessControl"
        ? closedSum(model, "registry.process.control.outcome")
        : closedSum(model, "registry.operation.outcome");
    generatedSymbolTable([
      { source: `operation:${operationIndex}:outcome:oneof`, name: "variant" },
      ...outcomeRegistry.variants.map((variant, variantIndex) => ({
        source: `operation:${operationIndex}:outcome:${variantIndex}:${variant.id}`,
        name: outcomeBranch(variant.id),
      })),
    ]);
  }

  generatedSymbolTable(messageSymbols);
}

function literal(value: string): string {
  return JSON.stringify(value);
}
