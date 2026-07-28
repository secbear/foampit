import type {
  DecoratorContext,
  Model,
  ModelProperty,
  Namespace,
  Operation,
  Program,
  Type,
  Union,
  UnionVariant,
} from "@typespec/compiler";

import { $lib } from "./lib.js";
import {
  hasWildcardStateCoordinate,
  parseMatrixDefinition,
  parseOperationDefinition,
  parseContractProfile,
} from "./definition.js";
import { isPortableWireTag } from "./wire-tag.js";

const stableIdPattern = /^[a-z][a-z0-9]*(?:\.[a-z][a-z0-9]*)*$/;

export function $contractRoot(
  context: DecoratorContext,
  target: Namespace,
) {
  context.program.stateSet($lib.stateKeys.contractRoots).add(target);
  return finishTarget(context.program, target);
}

export function $stableId(
  context: DecoratorContext,
  target: Type,
  id: unknown,
) {
  const value = stringValue(id);
  if (value === undefined || !stableIdPattern.test(value)) {
    context.program.reportDiagnostic(
      diagnostic(context.program, "invalid-stable-id", target),
    );
    return;
  }

  const pending = context.program.stateMap($lib.stateKeys.pendingStableIds);
  const values = pending.get(target) ?? [];
  values.push(value);
  pending.set(target, values);
  return finishTarget(context.program, target);
}

export function $wireTag(
  context: DecoratorContext,
  target: UnionVariant | ModelProperty,
  tag: unknown,
) {
  const value = stringValue(tag);
  if (value === undefined || !isPortableWireTag(value)) {
    context.program.reportDiagnostic(
      diagnostic(context.program, "invalid-wire-tag", target),
    );
    return;
  }

  const pending = context.program.stateMap($lib.stateKeys.pendingWireTags);
  const values = pending.get(target) ?? [];
  values.push(value);
  pending.set(target, values);
  return finishTarget(context.program, target);
}

export function $operationContract(
  context: DecoratorContext,
  target: Operation,
  definition: unknown,
) {
  const pending = context.program.stateMap(
    $lib.stateKeys.pendingOperationDefinitions,
  );
  const values = pending.get(target) ?? [];
  values.push(parseOperationDefinition(definition));
  pending.set(target, values);
  return finishTarget(context.program, target);
}

export function $contractMatrix(
  context: DecoratorContext,
  target: Namespace,
  definition: unknown,
) {
  const matrix = parseMatrixDefinition(definition);
  if (matrix === undefined) {
    return;
  }
  if (hasWildcardStateCoordinate(matrix)) {
    context.program.reportDiagnostic(
      diagnostic(context.program, "wildcard-cell-forbidden", target),
    );
    return;
  }
  const matrices = context.program.stateMap($lib.stateKeys.matrixDefinitions);
  const values = matrices.get(target) ?? [];
  values.push(matrix);
  matrices.set(target, values);
}

export function $contractProfile(context: DecoratorContext, target: Namespace, definition: unknown) {
  const profile = parseContractProfile(definition);
  if (profile === undefined) return;
  const pending = context.program.stateMap($lib.stateKeys.pendingContractProfiles);
  const values = pending.get(target) ?? [];
  values.push(profile);
  pending.set(target, values);
  return finishTarget(context.program, target);
}

export function $onValidate(program: Program): void {
  program.reportDiagnostics(validateGraph(program));
}

function finishTarget(program: Program, target: Type) {
  return {
    onTargetFinish: () => {
      const validated = program.stateSet($lib.stateKeys.targetValidation);
      if (validated.has(target)) {
        return [];
      }
      validated.add(target);

      const diagnostics = [];
      const stableIds = program.stateMap($lib.stateKeys.pendingStableIds).get(target) ?? [];
      const wireTags = program.stateMap($lib.stateKeys.pendingWireTags).get(target) ?? [];
      const operationDefinitions = program
        .stateMap($lib.stateKeys.pendingOperationDefinitions)
        .get(target) ?? [];
      const contractProfiles = target.kind === "Namespace"
        ? program.stateMap($lib.stateKeys.pendingContractProfiles).get(target) ?? []
        : [];

      if (stableIds.length > 1) {
        diagnostics.push(diagnostic(program, "conflicting-stable-id", target));
      } else if (stableIds.length === 1) {
        program.stateMap($lib.stateKeys.stableIds).set(target, stableIds[0]);
      }

      if (wireTags.length > 1) {
        diagnostics.push(diagnostic(program, "conflicting-wire-tag", target));
      } else if (wireTags.length === 1) {
        program.stateMap($lib.stateKeys.wireTags).set(target, wireTags[0]);
      }

      if (operationDefinitions.length > 1) {
        diagnostics.push(
          diagnostic(program, "conflicting-operation-contract", target),
        );
      } else if (operationDefinitions.length === 1) {
        const definition = operationDefinitions[0];
        if (definition !== undefined) {
          program
            .stateMap($lib.stateKeys.operationDefinitions)
            .set(target, definition);
        }
      }

      if (contractProfiles.length > 1) {
        diagnostics.push(diagnostic(program, "conflicting-contract-profile", target));
      } else if (contractProfiles.length === 1 && target.kind === "Namespace") {
        const profile = contractProfiles[0];
        if (profile !== undefined) {
          program.stateMap($lib.stateKeys.contractProfiles).set(target, profile);
        }
      }

      return diagnostics;
    },
    onGraphFinish: () => validateGraph(program),
  };
}

function validateGraph(program: Program) {
  const root = program.getGlobalNamespaceType();
  const complete = program.stateSet($lib.stateKeys.graphValidation);
  if (complete.has(root)) {
    return [];
  }
  complete.add(root);

  return [
    ...contractRootDiagnostics(program),
    ...duplicateDiagnostics(program, $lib.stateKeys.stableIds, "duplicate-stable-id"),
    ...missingWireTagDiagnostics(program),
    ...duplicateWireTagDiagnostics(program),
  ];
}

function missingWireTagDiagnostics(program: Program) {
  const wireTags = program.stateMap($lib.stateKeys.wireTags);
  return [...program.stateMap($lib.stateKeys.stableIds).keys()]
    .filter((target) => (target.kind === "UnionVariant" || target.kind === "ModelProperty") && !wireTags.has(target))
    .map((target) => diagnostic(program, "missing-wire-tag", target));
}

function contractRootDiagnostics(program: Program) {
  const roots = [...program.stateSet($lib.stateKeys.contractRoots)];
  if (roots.length === 0) {
    return [
      diagnostic(
        program,
        "missing-contract-root",
        program.getGlobalNamespaceType(),
      ),
    ];
  }
  return roots.length > 1
    ? roots
        .slice(1)
        .map((target) => diagnostic(program, "multiple-contract-roots", target))
    : [];
}

function duplicateDiagnostics(
  program: Program,
  stateKey: symbol,
  code: "duplicate-stable-id",
) {
  const seen = new Map<string, Type>();
  const diagnostics = [];
  for (const [target, value] of program.stateMap(stateKey)) {
    if (seen.has(value)) {
      diagnostics.push(diagnostic(program, code, target));
    } else {
      seen.set(value, target);
    }
  }
  return diagnostics;
}

function duplicateWireTagDiagnostics(program: Program) {
  const byContainer = new Map<Union | Model, Map<string, Type>>();
  const diagnostics = [];
  for (const [target, tag] of program.stateMap($lib.stateKeys.wireTags)) {
    const container =
      target.kind === "UnionVariant"
        ? target.union
        : target.kind === "ModelProperty"
          ? target.model
          : undefined;
    if (container === undefined) {
      continue;
    }
    const seen = byContainer.get(container) ?? new Map<string, Type>();
    byContainer.set(container, seen);
    if (seen.has(tag)) {
      diagnostics.push(diagnostic(program, "duplicate-wire-tag", target));
    } else {
      seen.set(tag, target);
    }
  }
  return diagnostics;
}

function diagnostic(
  program: Program,
  code:
    | "invalid-stable-id"
    | "conflicting-stable-id"
    | "duplicate-stable-id"
    | "invalid-wire-tag"
    | "missing-wire-tag"
    | "conflicting-wire-tag"
    | "duplicate-wire-tag"
    | "multiple-contract-roots"
    | "missing-contract-root"
    | "conflicting-operation-contract"
    | "conflicting-contract-profile"
    | "wildcard-cell-forbidden",
  target: Type,
) {
  return $lib.createDiagnostic({ code, target });
}

function stringValue(value: unknown): string | undefined {
  if (typeof value === "string") {
    return value;
  }
  if (
    typeof value === "object" &&
    value !== null &&
    "value" in value &&
    typeof value.value === "string"
  ) {
    return value.value;
  }
  return undefined;
}
