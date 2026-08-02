#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const directory = path.dirname(fileURLToPath(import.meta.url));
const coveragePath = path.join(directory, "PACKET-D-COMPOSITION-COVERAGE.json");

const readJson = (name) =>
  JSON.parse(fs.readFileSync(path.join(directory, name), "utf8"));

const pathsDocument = readJson("PACKET-D-COMPOSITION-PATHS.json");
const registryDocument = readJson("invariants.json");
const contractsDocument = readJson("PACKET-D-CASE-CONTRACTS.json");
const targetRealizationDocument = readJson("PACKET-C-TARGET-REALIZATION.json");

const owners = [
  "artifact",
  "create",
  "operator",
  "service",
  "live",
  "exec",
  "framework",
  "runtime",
  "core",
];
const effects = [
  "may-contribute",
  "may-narrow",
  "may-select",
  "no-authority",
  "boundary-input",
];

const pathIds = pathsDocument.paths.map(({ id }) => id);
const invariantIds = registryDocument.invariants.map(({ id }) => id);
const invariantById = new Map(
  registryDocument.invariants.map((invariant) => [invariant.id, invariant]),
);
const registryCompositionPathIds = [
  ...new Set(
    registryDocument.invariants.flatMap(
      (invariant) => invariant.compositionPaths,
    ),
  ),
].sort();
const pathById = new Map(pathsDocument.paths.map((entry) => [entry.id, entry]));
const entryByPath = new Map(
  contractsDocument.entries.map((entry) => [entry.pathId, entry]),
);
const contractEntryPathIds = contractsDocument.entries.map(
  ({ pathId }) => pathId,
);

const duplicates = (values) =>
  [...new Set(values.filter((value, index) => values.indexOf(value) !== index))];

const assert = (condition, message) => {
  if (!condition) {
    throw new Error(message);
  }
};

assert(
  pathIds.length === pathsDocument.reviewedPathCount &&
    pathsDocument.reviewedPathCount === 54,
  "Packet D path count must equal the approved 54-path registry",
);
assert(
  invariantIds.length === 254,
  "Packet D invariant order must contain the exact 254 registry IDs",
);
assert(
  duplicates(pathIds).length === 0,
  `duplicate composition path IDs: ${duplicates(pathIds).join(", ")}`,
);
assert(
  duplicates(invariantIds).length === 0,
  `duplicate invariant IDs: ${duplicates(invariantIds).join(", ")}`,
);
assert(
  contractsDocument.entries.length === pathIds.length,
  "Packet D requires one case-contract entry per path",
);
assert(
  duplicates(contractEntryPathIds).length === 0,
  `duplicate case-contract path IDs: ${duplicates(contractEntryPathIds).join(", ")}`,
);
assert(
  JSON.stringify(contractEntryPathIds) === JSON.stringify(pathIds),
  "case-contract path order must equal the exact registry path order",
);
assert(
  registryDocument.invariants.every((invariant) =>
    owners.includes(invariant.owner),
  ),
  "every invariant owner must be in the closed Packet D owner universe",
);
assert(
  JSON.stringify(Object.keys(pathsDocument.registryPathAliases).sort()) ===
    JSON.stringify(registryCompositionPathIds),
  "registryPathAliases must cover the exact historical invariant composition-path vocabulary",
);
assert(
  Object.values(pathsDocument.registryPathAliases).every((id) =>
    pathById.has(id),
  ),
  "every historical registry composition path must map to one locked Packet D path",
);
assert(
  JSON.stringify(contractsDocument.reviewedInvariantIds) ===
    JSON.stringify(invariantIds),
  "case catalog reviewedInvariantIds must equal the exact current registry in order",
);
const portableArtifactInvariantIds = registryDocument.invariants
  .filter(
    (invariant) =>
      invariant.owner === "artifact" &&
      ["P0", "P1", "A0", "A1", "W0"].includes(invariant.firstSoundPhase),
  )
  .map(({ id }) => id);
assert(
  JSON.stringify(contractsDocument.portableArtifactInvariantIds) ===
    JSON.stringify(portableArtifactInvariantIds),
  "portableArtifactInvariantIds must equal the exact reviewed pre-N0 Artifact semantic set",
);
const packetCTargetRealizationInvariantIds = [
  ...new Set(
    targetRealizationDocument.rules.flatMap((rule) => [
      ...Object.values(rule.fieldTraceability ?? {}).flatMap(
        (trace) => trace.invariants ?? [],
      ),
      ...rule.cases.flatMap((valueCase) => valueCase.invariants ?? []),
    ]),
  ),
].sort();
assert(
  JSON.stringify(contractsDocument.packetCTargetRealizationInvariantIds) ===
    JSON.stringify(packetCTargetRealizationInvariantIds),
  "packetCTargetRealizationInvariantIds must equal Packet C field traceability and case invariants",
);
assert(
  JSON.stringify(Object.keys(contractsDocument.classificationVectorsByPath)) ===
    JSON.stringify(pathIds),
  "case catalog must pin one classification vector per locked path in registry order",
);
const closedContractEntryKeys = [
  "pathId",
  "contractTemplate",
  "sourceOwner",
  "reachableOwners",
  "targetProfileIds",
  "nativeHandleContract",
  "evidenceObligationIds",
  "testObligationIds",
  "delegatedPackets",
  "delegatedConcerns",
].sort();
for (const entry of contractsDocument.entries) {
  assert(
    JSON.stringify(Object.keys(entry).sort()) ===
      JSON.stringify(closedContractEntryKeys),
    `${entry.pathId}: case-contract entry must use the exact closed field set`,
  );
}

const slug = (value) => value.toUpperCase().replaceAll("-", "_");
const rules = [];

const edges = new Map(
  [
    ["P0", ["P1"]],
    ["P1", ["A0", "OC0", "MS0"]],
    ["A0", ["A1"]],
    ["A1", ["W0"]],
    ["W0", ["N0"]],
    ["N0", ["N1"]],
    ["N1", ["C0"]],
    ["F0", ["C0", "L0", "E0", "T0"]],
    ["OC0", ["O0"]],
    ["MS0", ["S0"]],
    ["S0", ["C0", "L0", "E0", "T0"]],
    ["RW0", ["C0"]],
    ["C0", ["O0"]],
    ["O0", ["H0"]],
    ["H0", ["D0"]],
    ["D0", ["R0"]],
    ["R0", ["R1"]],
    ["R1", ["L0", "E0", "T0"]],
    ["L0", ["L1"]],
    ["L1", ["T0"]],
    ["E0", ["E1"]],
    ["E1", ["T0"]],
  ],
);
const phaseIds = new Set([
  ...edges.keys(),
  ...[...edges.values()].flat(),
]);

const reachable = (from, to) => {
  if (!phaseIds.has(from) || !phaseIds.has(to)) return false;
  if (from === to) return true;
  const pending = [...(edges.get(from) ?? [])];
  const seen = new Set();
  while (pending.length > 0) {
    const phase = pending.shift();
    if (phase === to) return true;
    if (seen.has(phase)) continue;
    seen.add(phase);
    pending.push(...(edges.get(phase) ?? []));
  }
  return false;
};

const orderBoundaryStepsByReachability = (steps) =>
  steps
    .map((step, inputIndex) => ({ step, inputIndex }))
    .sort((left, right) => {
      const leftBeforeRight = reachable(left.step.phase, right.step.phase);
      const rightBeforeLeft = reachable(right.step.phase, left.step.phase);
      if (leftBeforeRight && !rightBeforeLeft) return -1;
      if (rightBeforeLeft && !leftBeforeRight) return 1;
      return left.inputIndex - right.inputIndex;
    })
    .map(({ step }) => step);

const authoritativeHook = (invariant) => {
  const hook = invariant.enforcementHooks.find(
    (candidate) => candidate.role === "authoritative",
  );
  assert(hook, `${invariant.id}: missing authoritative enforcement hook`);
  return { phase: hook.phase, component: hook.component };
};

const authorityStep = (authority) => {
  const componentSlug = authority.component
    .toLowerCase()
    .replaceAll(/[^a-z0-9]+/g, "-")
    .replaceAll(/^-|-$/g, "");
  return {
    id: `invariant-authority-${authority.phase.toLowerCase()}-${componentSlug}`,
    phase: authority.phase,
    component: authority.component,
  };
};

const withAuthority = (steps, authority) => {
  const retained = [...steps];
  if (
    !retained.some(
      (step) =>
        step.phase === authority.phase &&
        step.component === authority.component,
    )
  ) {
    retained.push(authorityStep(authority));
  }
  return orderBoundaryStepsByReachability(retained);
};

const activeBoundaryChain = (template, invariant, authority) => {
  const retained = template.boundaryChain.filter(
    (step) =>
      reachable(invariant.firstSoundPhase, step.phase) &&
      reachable(step.phase, invariant.rejectionDeadline),
  );
  return withAuthority(retained, authority);
};

const continuationBoundaryChain = (template, deadline, authority) =>
  withAuthority(
    template.boundaryChain.filter((step) => reachable(step.phase, deadline)),
    authority,
  );

const registryPhaseContract = (template, invariant) => {
  const authority = authoritativeHook(invariant);
  return {
    firstSoundPhase: invariant.firstSoundPhase,
    rejectionDeadline: invariant.rejectionDeadline,
    authority,
    boundaryChain: activeBoundaryChain(template, invariant, authority),
  };
};

const ingressPhaseContract = (template, ingressAuthority) => ({
  firstSoundPhase: ingressAuthority.phase,
  rejectionDeadline: ingressAuthority.phase,
  authority: ingressAuthority,
  boundaryChain: withAuthority(
    template.boundaryChain.filter((step) =>
      reachable(step.phase, ingressAuthority.phase),
    ),
    ingressAuthority,
  ),
});

const rejectingBoundaryAuthority = (template) => {
  const authority = template.boundaryChain.find(
    (step) => step.id === template.rejectedForeignOwnerAt,
  );
  assert(
    authority,
    `${template.rejectedForeignOwnerAt}: rejecting boundary must identify an exact template step`,
  );
  return { phase: authority.phase, component: authority.component };
};

const boundaryInputPhaseContract = (template, ingressAuthority, invariant) => {
  const completedStrictlyBeforeIngress =
    invariant.rejectionDeadline !== template.firstSoundPhase &&
    reachable(invariant.rejectionDeadline, template.firstSoundPhase);
  if (completedStrictlyBeforeIngress) {
    return ingressPhaseContract(template, ingressAuthority);
  }
  const authority = authoritativeHook(invariant);
  return {
    firstSoundPhase: reachable(
      invariant.firstSoundPhase,
      template.firstSoundPhase,
    )
      ? template.firstSoundPhase
      : invariant.firstSoundPhase,
    rejectionDeadline: invariant.rejectionDeadline,
    authority,
    boundaryChain: continuationBoundaryChain(
      template,
      invariant.rejectionDeadline,
      authority,
    ),
  };
};

const noAuthorityPhaseContract = (
  template,
  ingressAuthority,
  invariant,
  classificationCode,
) => {
  if (classificationCode === "H") {
    return registryPhaseContract(template, invariant);
  }
  return ingressPhaseContract(template, rejectingBoundaryAuthority(template));
};

const classification = (pathId, invariantId) => {
  const vector = contractsDocument.classificationVectorsByPath[pathId];
  assert(
    typeof vector === "string" && vector.length === invariantIds.length,
    `${pathId}: classification vector length must equal the reviewed invariant count`,
  );
  const code = vector[invariantIds.indexOf(invariantId)];
  const contract = contractsDocument.classificationCodeContract[code];
  assert(contract, `${pathId}/${invariantId}: unknown classification code ${code}`);
  const [effect, exclusionClassName] = contract.split(":");
  return {
    code,
    effect,
    exclusionClass:
      effect === "no-authority"
        ? exclusionClassName
        : "active-path-contract",
  };
};

const expandedCellKeys = [];
for (const pathId of pathIds) {
  const pathEntry = pathById.get(pathId);
  const contractEntry = entryByPath.get(pathId);
  const template = contractsDocument.contractTemplates[contractEntry.contractTemplate];
  const ingressAuthority =
    contractsDocument.boundaryIngressCompleteAuthoritiesByTemplate[
      contractEntry.contractTemplate
    ] ?? template.authority;
  const vector = contractsDocument.classificationVectorsByPath[pathId];

  assert(template, `${pathId}: unknown contract template`);
  assert(contractEntry, `${pathId}: missing closed case-contract entry`);
  assert(
    typeof vector === "string" &&
      vector.length === invariantIds.length &&
      [...vector].every(
        (code) => contractsDocument.classificationCodeContract[code],
      ),
    `${pathId}: classification vector must classify every reviewed invariant exactly once`,
  );
  for (const invariant of registryDocument.invariants) {
    invariant.compositionPaths.forEach((historicalPath) =>
      assert(
        pathsDocument.registryPathAliases[historicalPath],
        `${invariant.id}: historical path ${historicalPath} lacks a locked alias`,
      ),
    );
  }
  assert(
    pathEntry.sourceOwner === contractEntry.sourceOwner &&
      JSON.stringify(pathEntry.reachableOwners) ===
        JSON.stringify(contractEntry.reachableOwners),
    `${pathId}: path ownership differs from the case contract`,
  );
  const classifiedEffects = [
    ...new Set(
      [...vector].map((code) => {
        const [effect] =
          contractsDocument.classificationCodeContract[code].split(":");
        return effect;
      }),
    ),
  ];
  assert(
    classifiedEffects.every((effect) =>
      pathEntry.allowedEffects.includes(effect),
    ),
    `${pathId}: classification effect is not allowed by the path contract`,
  );

  const groups = new Map();
  for (const invariant of registryDocument.invariants) {
    const classificationResult = classification(pathId, invariant.id);
    expandedCellKeys.push(`${pathId}\u0000${invariant.id}`);
    const active = classificationResult.effect !== "no-authority";
    const phaseContract =
      classificationResult.effect === "boundary-input"
        ? boundaryInputPhaseContract(template, ingressAuthority, invariant)
        : active
          ? registryPhaseContract(template, invariant)
          : noAuthorityPhaseContract(
              template,
              ingressAuthority,
              invariant,
              classificationResult.code,
            );
    const structuralExclusionClass = classificationResult.exclusionClass;
    const requiresConditionalNativeHandle =
      contractsDocument.conditionalNativeHandleContract.invariantIds.includes(
        invariant.id,
      ) &&
      contractsDocument.conditionalNativeHandleContract.allowedEffects.includes(
        classificationResult.effect,
      );
    const caseContract = {
          condition: requiresConditionalNativeHandle
            ? contractsDocument.conditionalNativeHandleContract.condition
            : { kind: "all-values" },
          allowedEffect: classificationResult.effect,
          firstSoundPhase: phaseContract.firstSoundPhase,
          rejectionDeadline: phaseContract.rejectionDeadline,
          authority: phaseContract.authority,
          boundaryChain: phaseContract.boundaryChain,
          structuralExclusionClass,
          structuralExclusion: active
            ? template.structuralExclusion
            : contractsDocument.structuralExclusionClasses[
                structuralExclusionClass
              ],
          rejectedForeignOwnerAt: template.rejectedForeignOwnerAt,
          fullRevalidation:
            classificationResult.effect === "boundary-input"
              ? true
              : template.fullRevalidation,
          identityAuthority: template.identityAuthority,
          ownershipExclusions: template.ownershipExclusions,
          targetProfileIds: contractEntry.targetProfileIds,
          nativeHandleContract: requiresConditionalNativeHandle
            ? contractsDocument.nativeHandleContract
            : contractEntry.nativeHandleContract,
          evidenceObligationIds: contractEntry.evidenceObligationIds,
          testObligationIds: contractEntry.testObligationIds,
          delegatedPackets: contractEntry.delegatedPackets,
          fallbackPolicy: "forbidden",
          warningPolicy: "never-sufficient",
          implementationStatus: "planned",
    };
    assert(
      !requiresConditionalNativeHandle ||
        JSON.stringify(caseContract.nativeHandleContract) ===
          JSON.stringify(contractsDocument.conditionalNativeHandleContract.contract),
      `${pathId}/${invariant.id}: conditional native cell must use the exact canonical native-handle tuple`,
    );
    const groupKey = JSON.stringify({
      invariantOwner: invariant.owner,
      classificationCode: classificationResult.code,
      caseContract,
    });
    const group = groups.get(groupKey) ?? {
      owner: invariant.owner,
      classificationCode: classificationResult.code,
      invariantIds: [],
      caseContract,
    };
    group.invariantIds.push(invariant.id);
    groups.set(groupKey, group);
  }

  let groupIndex = 0;
  for (const group of groups.values()) {
    groupIndex += 1;
    const identity = `${slug(pathId)}_${String(groupIndex).padStart(3, "0")}`;
    const valueCaseSuffix =
      group.caseContract.condition.kind === "when-native-handle-present"
        ? "NATIVE_HANDLE_PRESENT"
        : "ALL_VALUES";
    rules.push({
      id: `DCR_${identity}`,
      selector: {
        invariantIds: group.invariantIds,
        pathIds: [pathId],
        invariantOwner: group.owner,
        classificationCode: group.classificationCode,
      },
      valueCases: [
        {
          id: `DCASE_${identity}_${valueCaseSuffix}`,
          ...group.caseContract,
          diagnosticIdentity: `PACKET-D/${pathId}/${group.classificationCode}/${group.owner}/${String(groupIndex).padStart(3, "0")}`,
        },
      ],
    });
  }
}

const expectedCellCount = pathIds.length * invariantIds.length;
assert(
  expectedCellCount === 13716,
  "Packet D dimensions must expand to exactly 13,716 cells",
);
assert(
  expandedCellKeys.length === expectedCellCount &&
    new Set(expandedCellKeys).size === expectedCellCount,
  "Packet D generation must produce exactly 13,716 unique path/invariant cells",
);

const coverage = {
  reviewVersion: 1,
  packet: "D",
  status: "candidate",
  textAuthority:
    "Only closed selector, effect, phase, authority, boundary, exclusion, identity, obligation, and delegation fields are normative. Explanations cannot authorize a bypass or alter a generated cell.",
  invariantIds,
  pathIds,
  expectedCellCount,
  delegatedConcernTaxonomy: contractsDocument.delegatedConcernTaxonomy,
  resolvedReentryReplay:
    contractsDocument.serializedResolvedReentryReplaySets,
  crossPathHandoffs: contractsDocument.crossPathHandoffs,
  targetApplicabilityProjection:
    contractsDocument.targetApplicabilityProjection,
  rules,
};

const rendered = `${JSON.stringify(coverage, null, 2)}\n`;
if (process.argv.includes("--check")) {
  const existing = fs.readFileSync(coveragePath, "utf8");
  if (existing !== rendered) {
    console.error(
      "PACKET-D-COMPOSITION-COVERAGE.json is stale; run generate-composition-coverage.mjs",
    );
    process.exit(1);
  }
} else {
  fs.writeFileSync(coveragePath, rendered);
}
