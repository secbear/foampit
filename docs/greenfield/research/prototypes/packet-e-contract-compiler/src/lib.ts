import { createTypeSpecLibrary } from "@typespec/compiler";

export const $lib = createTypeSpecLibrary({
  name: "contract",
  diagnostics: {
    "invalid-stable-id": {
      severity: "error",
      messages: {
        default: "Stable IDs must be lowercase dot-separated identifiers.",
      },
    },
    "conflicting-stable-id": {
      severity: "error",
      messages: {
        default: "A target can have only one stable ID.",
      },
    },
    "duplicate-stable-id": {
      severity: "error",
      messages: {
        default: "Stable IDs must be unique in the contract graph.",
      },
    },
    "invalid-wire-tag": {
      severity: "error",
      messages: {
        default: "Wire tags must be portable protobuf field numbers: canonical decimal 1..536870911 excluding 19000..19999.",
      },
    },
    "missing-wire-tag": {
      severity: "error",
      messages: {
        default: "Every stable union variant or model property must declare exactly one wire tag.",
      },
    },
    "conflicting-wire-tag": {
      severity: "error",
      messages: {
        default: "A target can have only one wire tag.",
      },
    },
    "duplicate-wire-tag": {
      severity: "error",
      messages: {
        default: "Wire tags must be unique within a union or model.",
      },
    },
    "multiple-contract-roots": {
      severity: "error",
      messages: {
        default: "A contract graph can have only one contract root.",
      },
    },
    "missing-contract-root": {
      severity: "error",
      messages: {
        default: "A contract graph must declare a contract root.",
      },
    },
    "conflicting-operation-contract": {
      severity: "error",
      messages: {
        default: "An operation can have only one operation contract definition.",
      },
    },
    "wildcard-cell-forbidden": {
      severity: "error",
      messages: {
        default: "Contract matrix state coordinates cannot use wildcards.",
      },
    },
    "conflicting-contract-profile": {
      severity: "error",
      messages: {
        default: "A contract root can have only one semantic profile definition.",
      },
    },
    "missing-error-result-branch": { severity: "error", messages: { default: "Declared errors require their result branch." } },
    "error-result-branch-mismatch": { severity: "error", messages: { default: "Error subsets and result carrier branches must agree." } },
  },
  state: {
    contractRoots: {
      description: "Namespaces explicitly designated as contract roots.",
    },
    stableIds: {
      description: "Validated stable contract IDs by TypeSpec target.",
    },
    pendingStableIds: {
      description: "Stable IDs awaiting target-finish validation.",
    },
    wireTags: {
      description: "Validated wire tags by union variant or model property.",
    },
    pendingWireTags: {
      description: "Wire tags awaiting target-finish validation.",
    },
    operationDefinitions: {
      description: "Validated operation-contract values by operation target.",
    },
    pendingOperationDefinitions: {
      description: "Operation-contract values awaiting target-finish validation.",
    },
    matrixDefinitions: {
      description: "Explicit matrix definitions by contract root namespace.",
    },
    contractProfiles: {
      description: "Explicit semantic profile values by contract root namespace.",
    },
    pendingContractProfiles: {
      description: "Semantic profile values awaiting target-finish validation.",
    },
    targetValidation: {
      description: "Targets whose decorators have completed validation.",
    },
    graphValidation: {
      description: "Programs whose graph-wide identity checks completed.",
    },
  },
} as const);
