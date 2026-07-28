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
  generatedSymbolTable,
  type GeneratedFile,
  type GeneratedSymbol,
} from "./common.js";
import { assertPortableWireTags } from "../wire-tag.js";

type Schema = Record<string, unknown>;
type Schemas = Record<string, Schema>;

export function generateOpenApi(
  model: Readonly<ContractModel>,
): readonly GeneratedFile[] {
  assertPortableWireTags(model);
  assertNames(model);
  const schemas: Schemas = {};
  for (const sum of [...model.closedSums].sort((left, right) =>
    compareStrings(left.id, right.id),
  )) {
    addGlobalSum(schemas, sum);
  }
  for (const operation of [...model.operations].sort((left, right) =>
    compareStrings(left.operationId, right.operationId),
  )) {
    addOperation(schemas, model, operation);
  }
  const document = {
    openapi: "3.1.0",
    info: {
      title: model.contractId,
      version: model.contractModelVersion,
    },
    paths: {},
    components: { schemas },
  };
  return Object.freeze([
    generatedFile(
      "openapi/contract.json",
      `${JSON.stringify(document, undefined, 2)}\n`,
    ),
  ]);
}

function addGlobalSum(schemas: Schemas, sum: ClosedSum): void {
  const alternatives = sortedVariants(sum.variants).map((variant) => {
    const name = globalVariantName(sum, variant);
    schemas[name] = closedObject(
      { stableId: { const: variant.id } },
      variant.id,
      requiredWireTag(variant),
    );
    return Object.freeze({ key: variant.id, schemaName: name });
  });
  schemas[generatedName(sum.id)] = discriminatedUnion(
    "stableId",
    alternatives,
    { "x-stable-id": sum.id },
  );
}

function addOperation(
  schemas: Schemas,
  model: Readonly<ContractModel>,
  operation: OperationContract,
): void {
  const name = operationName(operation);
  schemas[`${name}RequestError`] = subsetSchema(
    closedSum(model, "registry.request.error"),
    operation.allowedRequestErrors,
  );
  schemas[`${name}RecoveryError`] = subsetSchema(
    closedSum(model, "registry.recovery.error"),
    operation.allowedRecoveryErrors,
  );
  schemas[`${name}KnownFailure`] = subsetSchema(
    closedSum(model, "registry.known.failure"),
    operation.allowedKnownFailures,
  );
  schemas[`${name}Ambiguity`] = subsetSchema(
    closedSum(model, "registry.ambiguity"),
    operation.allowedAmbiguities,
  );

  const outcomeRegistry =
    operation.callClass === "sequencedProcessControl"
      ? closedSum(model, "registry.process.control.outcome")
      : closedSum(model, "registry.operation.outcome");
  const alternatives = operation.resultBranches.map((branch) => {
    const variant = outcomeVariant(outcomeRegistry, branch);
    const schemaName = `${name}${generatedName(branch)}`;
    if (branch === "accepted" || branch === "observed") {
      schemas[schemaName] = successSchema(operation, branch, variant);
    } else {
      addErrorBranch(schemas, model, operation, branch, variant);
    }
    return Object.freeze({ key: branch, schemaName });
  });
  schemas[`${name}Outcome`] = discriminatedUnion("branch", alternatives, {
    "x-operation-id": operation.operationId,
  });
}

function subsetSchema(
  registry: ClosedSum,
  allowedStableIds: readonly string[],
): Schema {
  if (allowedStableIds.length === 0) {
    return { not: {} };
  }
  const allowed = new Set(allowedStableIds);
  const variants = sortedVariants(
    registry.variants.filter((variant) => allowed.has(variant.id)),
  );
  if (variants.length !== allowed.size) {
    throw new Error("contract/generated-subset-invalid");
  }
  return discriminatedUnion(
    "stableId",
    variants.map((variant) =>
      Object.freeze({
        key: variant.id,
        schemaName: globalVariantName(registry, variant),
      }),
    ),
  );
}

function successSchema(
  operation: OperationContract,
  branch: "accepted" | "observed",
  variant: ClosedVariant,
): Schema {
  return closedObject(
    {
      operationId: { const: operation.operationId },
      branch: { const: branch },
      carrierKind: { const: operation.result.carrierKind },
      schemaStableId: { const: operation.result.schemaStableId },
    },
    variant.id,
    requiredWireTag(variant),
  );
}

function addErrorBranch(
  schemas: Schemas,
  model: Readonly<ContractModel>,
  operation: OperationContract,
  branch: "recovery" | "rejected",
  outcome: ClosedVariant,
): void {
  const name = operationName(operation);
  const branchName = `${name}${generatedName(branch)}`;
  const registry =
    branch === "rejected"
      ? closedSum(model, "registry.request.error")
      : closedSum(model, "registry.recovery.error");
  const allowedStableIds =
    branch === "rejected"
      ? operation.allowedRequestErrors
      : operation.allowedRecoveryErrors;
  const allowed = new Set(allowedStableIds);
  const errors = sortedVariants(
    registry.variants.filter((variant) => allowed.has(variant.id)),
  );
  if (errors.length === 0 || errors.length !== allowed.size) {
    throw new Error("contract/generated-error-branch-invalid");
  }
  const propertyName =
    branch === "rejected" ? "requestErrorId" : "recoveryErrorId";
  const alternatives = errors.map((error) => {
    const schemaName = `${branchName}${generatedName(error.id)}`;
    schemas[schemaName] = closedObject(
      {
        operationId: { const: operation.operationId },
        branch: { const: branch },
        [propertyName]: { const: error.id },
      },
      outcome.id,
      requiredWireTag(outcome),
      {
        "x-error-stable-id": error.id,
        "x-error-wire-tag": requiredWireTag(error),
      },
    );
    return Object.freeze({ key: error.id, schemaName });
  });
  schemas[branchName] = discriminatedUnion(propertyName, alternatives);
}

function closedObject(
  properties: Readonly<Record<string, Readonly<{ const: string }>>>,
  stableId: string,
  wireTag: string,
  extensions: Readonly<Record<string, string>> = {},
): Schema {
  return {
    type: "object",
    additionalProperties: false,
    required: Object.keys(properties),
    properties,
    "x-stable-id": stableId,
    "x-wire-tag": wireTag,
    ...extensions,
  };
}

function discriminatedUnion(
  propertyName: string,
  alternatives: readonly Readonly<{ key: string; schemaName: string }>[],
  extensions: Readonly<Record<string, string>> = {},
): Schema {
  if (alternatives.length === 0) {
    throw new Error("contract/generated-empty-union-invalid");
  }
  return {
    oneOf: alternatives.map(({ schemaName }) => reference(schemaName)),
    discriminator: {
      propertyName,
      mapping: Object.fromEntries(
        alternatives.map(({ key, schemaName }) => [
          key,
          componentReference(schemaName),
        ]),
      ),
    },
    ...extensions,
  };
}

function reference(schemaName: string): Readonly<{ $ref: string }> {
  return Object.freeze({ $ref: componentReference(schemaName) });
}

function componentReference(schemaName: string): string {
  return `#/components/schemas/${schemaName}`;
}

function globalVariantName(sum: ClosedSum, variant: ClosedVariant): string {
  return `${generatedName(sum.id)}${generatedName(variant.id)}`;
}

function outcomeVariant(
  registry: ClosedSum,
  branch: OperationContract["resultBranches"][number],
): ClosedVariant {
  const prefix =
    registry.id === "registry.process.control.outcome"
      ? "outcome.process."
      : "outcome.";
  const stableId = `${prefix}${branch}`;
  const variant = registry.variants.find(
    (candidate) => candidate.id === stableId,
  );
  if (variant === undefined) {
    throw new Error("contract/generated-outcome-variant-missing");
  }
  return variant;
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
  wireNumber(variant);
  return variant.wireTag;
}

function wireNumber(variant: ClosedVariant): number {
  if (
    variant.wireTag === undefined ||
    !/^[1-9][0-9]*$/.test(variant.wireTag)
  ) {
    throw new Error("contract/generated-wire-tag-invalid");
  }
  const value = Number(variant.wireTag);
  if (
    !Number.isSafeInteger(value) ||
    value > 536_870_911 ||
    (value >= 19_000 && value <= 19_999)
  ) {
    throw new Error("contract/generated-wire-tag-invalid");
  }
  return value;
}

function operationName(operation: OperationContract): string {
  const prefix = "operation.";
  if (!operation.operationId.startsWith(prefix)) {
    throw new Error("contract/generated-name-invalid");
  }
  return generatedName(operation.operationId.slice(prefix.length));
}

function assertNames(model: Readonly<ContractModel>): void {
  const componentSchemas: GeneratedSymbol[] = [];

  for (const sum of model.closedSums) {
    componentSchemas.push(
      openApiComponent(`closed-sum:${sum.id}`, generatedName(sum.id)),
    );
    for (const variant of sum.variants) {
      componentSchemas.push(
        openApiComponent(
          `closed-sum:${sum.id}:variant:${variant.id}`,
          globalVariantName(sum, variant),
        ),
      );
    }
  }

  for (const operation of model.operations) {
    const name = operationName(operation);
    const source = `operation:${operation.operationId}`;
    for (const suffix of [
      "RequestError",
      "RecoveryError",
      "KnownFailure",
      "Ambiguity",
    ]) {
      componentSchemas.push(
        openApiComponent(`${source}:subset:${suffix}`, `${name}${suffix}`),
      );
    }
    for (const branch of operation.resultBranches) {
      const branchName = `${name}${generatedName(branch)}`;
      componentSchemas.push(
        openApiComponent(`${source}:branch:${branch}`, branchName),
      );
      if (branch === "rejected" || branch === "recovery") {
        const stableIds =
          branch === "rejected"
            ? operation.allowedRequestErrors
            : operation.allowedRecoveryErrors;
        for (const stableId of stableIds) {
          componentSchemas.push(
            openApiComponent(
              `${source}:branch:${branch}:error:${stableId}`,
              `${branchName}${generatedName(stableId)}`,
            ),
          );
        }
      }
    }
    componentSchemas.push(
      openApiComponent(`${source}:outcome`, `${name}Outcome`),
    );
  }

  generatedSymbolTable(componentSchemas);
}

function openApiComponent(source: string, name: string): GeneratedSymbol {
  if (!/^[A-Za-z_][A-Za-z0-9_]*$/.test(name)) {
    throw new Error("contract/generated-name-invalid");
  }
  return Object.freeze({ source, name });
}
