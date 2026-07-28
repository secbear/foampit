import {
  wireIdentities as deriveWireIdentities,
  type ContractModel,
  type OperationContract,
} from "../model.js";
import {
  compareStrings,
  generatedFile,
  generatedName,
  generatedSymbolTable,
  lowerCamel,
  type GeneratedFile,
  type GeneratedSymbol,
} from "./common.js";

export function generateGo(
  model: Readonly<ContractModel>,
): readonly GeneratedFile[] {
  assertNames(model);
  const operations = [...model.operations].sort((left, right) =>
    compareStrings(left.operationId, right.operationId),
  );
  return Object.freeze([
    generatedFile("go/go.mod", "module packet_e_contract\n\ngo 1.26\n"),
    generatedFile("go/contract.go", goLibrary(model, operations)),
    generatedFile("go/contract_test.go", goTests()),
  ]);
}

function goLibrary(
  model: Readonly<ContractModel>,
  operations: readonly OperationContract[],
): string {
  return `package contract

import (
	"bytes"
	"encoding/json"
	"io"
)

const InvalidOutcome = "contract/invalid-outcome"

type ContractDiagnostic struct {
	Category string
}

func (diagnostic *ContractDiagnostic) Error() string {
	return diagnostic.Category
}

func invalid() error {
	return &ContractDiagnostic{Category: InvalidOutcome}
}

${wireIdentities(model)}

${closedSumTypes(model)}

${operations.map(operationTypes).join("\n")}

${anyOutcome(operations)}

${serviceInterface(operations)}

${operations.map(operationDecoder).join("\n")}

${dispatchDecoder(operations)}

${parserSource}
`;
}

function wireIdentities(model: Readonly<ContractModel>): string {
  const values = [...deriveWireIdentities(model)]
    .sort(
      (left, right) =>
        compareStrings(left.containerId, right.containerId) ||
        compareStrings(left.variantId, right.variantId),
    )
    .map(
      (identity) =>
        `	{ContainerID: ${literal(identity.containerId)}, VariantID: ${literal(identity.variantId)}, WireTag: ${literal(identity.wireTag)}},`,
    )
    .join("\n");
  return `type WireIdentity struct {
	ContainerID string
	VariantID   string
	WireTag     string
}

var wireIdentities = [...]WireIdentity{
${values}
}

func ContractWireIdentities() []WireIdentity {
	identities := make([]WireIdentity, len(wireIdentities))
	copy(identities, wireIdentities[:])
	return identities
}`;
}

function closedSumTypes(model: Readonly<ContractModel>): string {
  return [...model.closedSums]
    .sort((left, right) => compareStrings(left.id, right.id))
    .map((sum) => {
      const sumName = generatedName(sum.id);
      const privateName = lowerCamel(sumName);
      const implementations = [...sum.variants]
        .sort((left, right) => compareStrings(left.id, right.id))
        .map((variant) => {
          if (
            variant.wireTag === undefined ||
            !/^[1-9][0-9]*$/.test(variant.wireTag)
          ) {
            throw new Error("contract/generated-wire-tag-invalid");
          }
          const implementation = `${privateName}${generatedName(variant.id)}`;
          return `type ${implementation} struct{}

func (${implementation}) is${sumName}() {}
func (${implementation}) StableID() string { return ${literal(variant.id)} }
func (${implementation}) WireTag() string { return ${literal(variant.wireTag)} }`;
        })
        .join("\n\n");
      return `type ${sumName} interface {
	is${sumName}()
	StableID() string
	WireTag() string
}

${implementations}`;
    })
    .join("\n\n");
}

function operationTypes(operation: OperationContract): string {
  const name = operationName(operation);
  const privateName = lowerCamel(name);
  const outcomeImplementations = operation.resultBranches
    .map((branch) => {
      if (branch === "accepted" || branch === "observed") {
        const branchName = capitalize(branch);
        const interfaceName = `${name}${branchName}`;
        const implementationName = `${privateName}${branchName}`;
        return `type ${interfaceName} interface {
	${name}Outcome
	is${interfaceName}()
}

type ${implementationName} struct {
	carrier ${privateName}Carrier
}

func (${implementationName}) is${name}Outcome() {}
func (${implementationName}) isAnyOutcome() {}
func (${implementationName}) is${interfaceName}() {}
func (${implementationName}) Branch() string { return ${literal(branch)} }
func (${implementationName}) OperationID() string { return ${literal(operation.operationId)} }`;
      }
      const branchName = branch === "rejected" ? "Rejected" : "Recovery";
      const reasonType =
        branch === "rejected"
          ? `${name}RequestError`
          : `${name}RecoveryError`;
      const interfaceName = `${name}${branchName}`;
      const implementationName = `${privateName}${branchName}`;
      return `type ${interfaceName} interface {
	${name}Outcome
	is${interfaceName}()
}

type ${implementationName} struct {
	reason ${reasonType}
}

func (${implementationName}) is${name}Outcome() {}
func (${implementationName}) isAnyOutcome() {}
func (${implementationName}) is${interfaceName}() {}
func (${implementationName}) Branch() string { return ${literal(branch)} }
func (${implementationName}) OperationID() string { return ${literal(operation.operationId)} }`;
    })
    .join("\n\n");
  return `${packageMarkedSum(
    `${name}RequestError`,
    operation.allowedRequestErrors,
    "StableID",
  )}

${packageMarkedSum(
  `${name}RecoveryError`,
  operation.allowedRecoveryErrors,
  "StableID",
)}

${packageMarkedSum(
  `${name}KnownFailure`,
  operation.allowedKnownFailures,
  "StableID",
)}

${packageMarkedSum(
  `${name}Ambiguity`,
  operation.allowedAmbiguities,
  "StableID",
)}

type ${privateName}Carrier struct {
	private struct{}
}

func (${privateName}Carrier) CarrierKind() string {
	return ${literal(operation.result.carrierKind)}
}

func (${privateName}Carrier) SchemaStableID() string {
	return ${literal(operation.result.schemaStableId)}
}

// ${name}Outcome is package-marked, not statically sealed. Go interface
// embedding can satisfy private marker methods. Inspect or validate values
// received across a trust boundary before using their semantics.
type ${name}Outcome interface {
	is${name}Outcome()
	isAnyOutcome()
}

${outcomeImplementations}

${operationInspection(operation)}
`;
}

function operationInspection(operation: OperationContract): string {
  const name = operationName(operation);
  const branches = operation.resultBranches
    .map((branch) => inspectionBranch(operation, branch))
    .join("\n");
  return `type ${name}OutcomeView struct {
	operationID    string
	branch         string
	carrierKind    string
	schemaStableID string
	requestError   ${name}RequestError
	recoveryError  ${name}RecoveryError
}

func (${name}OutcomeView) isAnyOutcomeView() {}

func (view ${name}OutcomeView) OperationID() string {
	return view.operationID
}

func (view ${name}OutcomeView) Branch() string {
	return view.branch
}

func (view ${name}OutcomeView) CarrierKind() (string, bool) {
	return view.carrierKind, view.carrierKind != ""
}

func (view ${name}OutcomeView) SchemaStableID() (string, bool) {
	return view.schemaStableID, view.schemaStableID != ""
}

func (view ${name}OutcomeView) RequestError() (${name}RequestError, bool) {
	return view.requestError, view.requestError != nil
}

func (view ${name}OutcomeView) RecoveryError() (${name}RecoveryError, bool) {
	return view.recoveryError, view.recoveryError != nil
}

// Inspect${name}Outcome validates an interface value by exact generated
// concrete type before exposing a semantic view.
func Inspect${name}Outcome(outcome ${name}Outcome) (${name}OutcomeView, error) {
	switch value := outcome.(type) {
${branches}
	default:
		return ${name}OutcomeView{}, invalid()
	}
}

func Validate${name}Outcome(outcome ${name}Outcome) error {
	_, err := Inspect${name}Outcome(outcome)
	return err
}

${reasonInspector(
  `${name}RequestError`,
  operation.allowedRequestErrors,
)}

${reasonInspector(
  `${name}RecoveryError`,
  operation.allowedRecoveryErrors,
)}`;
}

function inspectionBranch(
  operation: OperationContract,
  branch: OperationContract["resultBranches"][number],
): string {
  const name = operationName(operation);
  const privateName = lowerCamel(name);
  const branchName = branch === "rejected" ? "Rejected" : capitalize(branch);
  const implementationName = `${privateName}${branchName}`;
  const commonChecks = `value.OperationID() != ${literal(operation.operationId)} ||
			value.Branch() != ${literal(branch)}`;
  if (branch === "accepted" || branch === "observed") {
    return `	case ${implementationName}:
		if ${commonChecks} ||
			value.carrier.CarrierKind() != ${literal(operation.result.carrierKind)} ||
			value.carrier.SchemaStableID() != ${literal(operation.result.schemaStableId)} {
			return ${name}OutcomeView{}, invalid()
		}
		return ${name}OutcomeView{
			operationID:    value.OperationID(),
			branch:         value.Branch(),
			carrierKind:    value.carrier.CarrierKind(),
			schemaStableID: value.carrier.SchemaStableID(),
		}, nil`;
  }
  const reasonKind = branch === "rejected" ? "RequestError" : "RecoveryError";
  const viewFields =
    branch === "rejected"
      ? `operationID:  value.OperationID(),
			branch:       value.Branch(),
			requestError: reason`
      : `operationID:   value.OperationID(),
			branch:        value.Branch(),
			recoveryError: reason`;
  return `	case ${implementationName}:
		if ${commonChecks} {
			return ${name}OutcomeView{}, invalid()
		}
		reason, ok := inspect${name}${reasonKind}(value.reason)
		if !ok {
			return ${name}OutcomeView{}, invalid()
		}
		return ${name}OutcomeView{
			${viewFields},
		}, nil`;
}

function reasonInspector(
  typeName: string,
  stableIds: readonly string[],
): string {
  if (stableIds.length === 0) {
    return `func inspect${typeName}(${typeName}) (${typeName}, bool) {
	return nil, false
}`;
  }
  const cases = [...stableIds]
    .sort(compareStrings)
    .map((stableId) => {
      const implementation = `${lowerCamel(typeName)}${generatedName(stableId)}`;
      return `	case ${implementation}:
		if value.StableID() != ${literal(stableId)} {
			return nil, false
		}
		return value, true`;
    })
    .join("\n");
  return `func inspect${typeName}(reason ${typeName}) (${typeName}, bool) {
	switch value := reason.(type) {
${cases}
	default:
		return nil, false
	}
}`;
}

function packageMarkedSum(
  typeName: string,
  stableIds: readonly string[],
  accessor: string,
): string {
  const privateType = lowerCamel(typeName);
  const implementations = [...stableIds]
    .sort(compareStrings)
    .map((stableId) => {
      const variant = generatedName(stableId);
      const implementation = `${privateType}${variant}`;
      return `type ${implementation} struct{}

func (${implementation}) is${typeName}() {}
func (${implementation}) ${accessor}() string { return ${literal(stableId)} }`;
    })
    .join("\n\n");
  return `type ${typeName} interface {
	is${typeName}()
	${accessor}() string
}

${implementations}`;
}

function anyOutcome(operations: readonly OperationContract[]): string {
  const inspectionCases = operations
    .flatMap((operation) => {
      const name = operationName(operation);
      const privateName = lowerCamel(name);
      return operation.resultBranches.map((branch) => {
        const branchName =
          branch === "rejected" ? "Rejected" : capitalize(branch);
        return `	case ${privateName}${branchName}:
		view, err := Inspect${name}Outcome(value)
		if err != nil {
			return nil, err
		}
		return view, nil`;
      });
    })
    .join("\n");
  return `// AnyOutcome is package-marked, not statically sealed. Go interface
// embedding can satisfy private marker methods. Inspect or validate values
// received across a trust boundary before using their semantics.
type AnyOutcome interface {
	isAnyOutcome()
}

type AnyOutcomeView interface {
	isAnyOutcomeView()
	Branch() string
	OperationID() string
}

var (
${operations
  .map(
    (operation) =>
      `	_ AnyOutcome = (${operationName(operation)}Outcome)(nil)`,
  )
  .join("\n")}
)

// InspectOutcome accepts only exact generated private concrete outcome types.
func InspectOutcome(outcome AnyOutcome) (AnyOutcomeView, error) {
	switch value := outcome.(type) {
${inspectionCases}
	default:
		return nil, invalid()
	}
}

func ValidateOutcome(outcome AnyOutcome) error {
	_, err := InspectOutcome(outcome)
	return err
}`;
}

function serviceInterface(operations: readonly OperationContract[]): string {
  return `type PacketEService interface {
${operations
  .map(
    (operation) =>
      `	${operationName(operation)}() ${operationName(operation)}Outcome`,
  )
  .join("\n")}
}`;
}

function operationDecoder(operation: OperationContract): string {
  const name = operationName(operation);
  const privateName = lowerCamel(name);
  const branches = operation.resultBranches
    .map((branch) => decoderBranch(operation, branch))
    .join("\n");
  return `func Decode${name}Outcome(data []byte) (${name}Outcome, error) {
	fields, err := parseFlatObject(data)
	if err != nil {
		return nil, err
	}
	if err := expectValue(fields, "operationId", ${literal(operation.operationId)}); err != nil {
		return nil, err
	}
	switch fields["branch"] {
${branches}
	default:
		return nil, invalid()
	}
}

func new${name}Carrier() ${privateName}Carrier {
	return ${privateName}Carrier{}
}`;
}

function decoderBranch(
  operation: OperationContract,
  branch: OperationContract["resultBranches"][number],
): string {
  const name = operationName(operation);
  const privateName = lowerCamel(name);
  if (branch === "accepted" || branch === "observed") {
    return `	case ${literal(branch)}:
		if err := expectKeys(fields, "operationId", "branch", "carrierKind", "schemaStableId"); err != nil {
			return nil, err
		}
		if err := expectValue(fields, "carrierKind", ${literal(operation.result.carrierKind)}); err != nil {
			return nil, err
		}
		if err := expectValue(fields, "schemaStableId", ${literal(operation.result.schemaStableId)}); err != nil {
			return nil, err
		}
		return ${privateName}${capitalize(branch)}{carrier: new${name}Carrier()}, nil`;
  }
  const stableIds =
    branch === "rejected"
      ? operation.allowedRequestErrors
      : operation.allowedRecoveryErrors;
  const field = branch === "rejected" ? "requestErrorId" : "recoveryErrorId";
  const typeName =
    branch === "rejected"
      ? `${name}RequestError`
      : `${name}RecoveryError`;
  const branchName = branch === "rejected" ? "Rejected" : "Recovery";
  const cases = stableIds
    .map(
      (stableId) =>
        `		case ${literal(stableId)}:
			reason = ${lowerCamel(typeName)}${generatedName(stableId)}{}`,
    )
    .join("\n");
  return `	case ${literal(branch)}:
		if err := expectKeys(fields, "operationId", "branch", "${field}"); err != nil {
			return nil, err
		}
		var reason ${typeName}
		switch fields["${field}"] {
${cases}
		default:
			return nil, invalid()
		}
		return ${privateName}${branchName}{reason: reason}, nil`;
}

function dispatchDecoder(operations: readonly OperationContract[]): string {
  return `func DecodeOutcome(data []byte) (AnyOutcome, error) {
	fields, err := parseFlatObject(data)
	if err != nil {
		return nil, err
	}
	switch fields["operationId"] {
${operations
  .map(
    (operation) =>
      `	case ${literal(operation.operationId)}:
		return Decode${operationName(operation)}Outcome(data)`,
  )
  .join("\n")}
	default:
		return nil, invalid()
	}
}`;
}

const parserSource = `func parseFlatObject(data []byte) (map[string]string, error) {
	decoder := json.NewDecoder(bytes.NewReader(data))
	token, err := decoder.Token()
	if err != nil || token != json.Delim('{') {
		return nil, invalid()
	}
	fields := make(map[string]string)
	for decoder.More() {
		token, err = decoder.Token()
		if err != nil {
			return nil, invalid()
		}
		key, ok := token.(string)
		if !ok {
			return nil, invalid()
		}
		if _, exists := fields[key]; exists {
			return nil, invalid()
		}
		var value string
		if err := decoder.Decode(&value); err != nil {
			return nil, invalid()
		}
		fields[key] = value
	}
	token, err = decoder.Token()
	if err != nil || token != json.Delim('}') {
		return nil, invalid()
	}
	if token, err = decoder.Token(); err != io.EOF || token != nil {
		return nil, invalid()
	}
	return fields, nil
}

func expectKeys(fields map[string]string, expected ...string) error {
	if len(fields) != len(expected) {
		return invalid()
	}
	for _, key := range expected {
		if _, ok := fields[key]; !ok {
			return invalid()
		}
	}
	return nil
}

func expectValue(fields map[string]string, key string, expected string) error {
	if fields[key] != expected {
		return invalid()
	}
	return nil
}`;

function goTests(): string {
  return `package contract

import (
	"errors"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestSharedOutcomeFixtures(t *testing.T) {
	directory := os.Getenv("PACKET_E_OUTCOME_FIXTURES")
	if directory == "" {
		t.Fatal("PACKET_E_OUTCOME_FIXTURES is required")
	}
	fixtures := []string{
		"start-sandbox-valid.json",
		"start-sandbox-invalid.json",
		"cancel-operation-valid.json",
		"cancel-operation-invalid.json",
		"write-process-input-valid.json",
		"write-process-input-invalid.json",
		"wait-operation-valid.json",
		"wait-operation-invalid.json",
	}
	for _, fixture := range fixtures {
		fixture := fixture
		t.Run(fixture, func(t *testing.T) {
			data, err := os.ReadFile(filepath.Join(directory, fixture))
			if err != nil {
				t.Fatal(err)
			}
			_, err = DecodeOutcome(data)
			if strings.Contains(fixture, "-valid.") {
				if err != nil {
					t.Fatalf("valid fixture rejected: %v", err)
				}
				return
			}
			var diagnostic *ContractDiagnostic
			if !errors.As(err, &diagnostic) || diagnostic.Category != InvalidOutcome {
				t.Fatalf("invalid fixture diagnostic = %v", err)
			}
		})
	}
}
`;
}

function operationName(operation: OperationContract): string {
  const prefix = "operation.";
  if (!operation.operationId.startsWith(prefix)) {
    throw new Error("contract/generated-name-invalid");
  }
  return generatedName(operation.operationId.slice(prefix.length));
}

function assertNames(model: Readonly<ContractModel>): void {
  const packageSymbols: GeneratedSymbol[] = [
    goSymbol("fixed:constant:InvalidOutcome", "InvalidOutcome"),
    goSymbol("fixed:type:ContractDiagnostic", "ContractDiagnostic"),
    goSymbol("fixed:function:invalid", "invalid"),
    goSymbol("fixed:type:WireIdentity", "WireIdentity"),
    goSymbol("fixed:variable:wireIdentities", "wireIdentities"),
    goSymbol("fixed:function:ContractWireIdentities", "ContractWireIdentities"),
    goSymbol("fixed:type:AnyOutcome", "AnyOutcome"),
    goSymbol("fixed:type:AnyOutcomeView", "AnyOutcomeView"),
    goSymbol("fixed:function:InspectOutcome", "InspectOutcome"),
    goSymbol("fixed:function:ValidateOutcome", "ValidateOutcome"),
    goSymbol("fixed:type:PacketEService", "PacketEService"),
    goSymbol("fixed:function:DecodeOutcome", "DecodeOutcome"),
    goSymbol("fixed:function:parseFlatObject", "parseFlatObject"),
    goSymbol("fixed:function:expectKeys", "expectKeys"),
    goSymbol("fixed:function:expectValue", "expectValue"),
    goSymbol(
      "fixed:test:function:TestSharedOutcomeFixtures",
      "TestSharedOutcomeFixtures",
    ),
  ];
  const serviceMethods: GeneratedSymbol[] = [];

  for (const sum of model.closedSums) {
    const sumName = generatedName(sum.id);
    const privateName = lowerCamel(sumName);
    packageSymbols.push(goSymbol(`closed-sum:${sum.id}`, sumName));
    for (const variant of sum.variants) {
      packageSymbols.push(
        goSymbol(
          `closed-sum:${sum.id}:variant:${variant.id}`,
          `${privateName}${generatedName(variant.id)}`,
        ),
      );
    }
    generatedSymbolTable([
      goSymbol(`closed-sum:${sum.id}:marker`, `is${sumName}`),
      goSymbol(`closed-sum:${sum.id}:stable-id`, "StableID"),
      goSymbol(`closed-sum:${sum.id}:wire-tag`, "WireTag"),
    ]);
  }

  for (const operation of model.operations) {
    const name = operationName(operation);
    const privateName = lowerCamel(name);
    const source = `operation:${operation.operationId}`;
    serviceMethods.push(goSymbol(source, name));

    for (const suffix of [
      "RequestError",
      "RecoveryError",
      "KnownFailure",
      "Ambiguity",
    ]) {
      const typeName = `${name}${suffix}`;
      packageSymbols.push(goSymbol(`${source}:type:${suffix}`, typeName));
      for (const stableId of operation[
        suffix === "RequestError"
          ? "allowedRequestErrors"
          : suffix === "RecoveryError"
            ? "allowedRecoveryErrors"
            : suffix === "KnownFailure"
              ? "allowedKnownFailures"
              : "allowedAmbiguities"
      ]) {
        packageSymbols.push(
          goSymbol(
            `${source}:${suffix}:variant:${stableId}`,
            `${lowerCamel(typeName)}${generatedName(stableId)}`,
          ),
        );
      }
      generatedSymbolTable([
        goSymbol(`${source}:${suffix}:marker`, `is${typeName}`),
        goSymbol(`${source}:${suffix}:stable-id`, "StableID"),
      ]);
    }

    packageSymbols.push(
      goSymbol(`${source}:carrier`, `${privateName}Carrier`),
      goSymbol(`${source}:outcome`, `${name}Outcome`),
      goSymbol(`${source}:outcome-view`, `${name}OutcomeView`),
      goSymbol(`${source}:inspect`, `Inspect${name}Outcome`),
      goSymbol(`${source}:validate`, `Validate${name}Outcome`),
      goSymbol(`${source}:inspect-request`, `inspect${name}RequestError`),
      goSymbol(`${source}:inspect-recovery`, `inspect${name}RecoveryError`),
      goSymbol(`${source}:decode`, `Decode${name}Outcome`),
      goSymbol(`${source}:new-carrier`, `new${name}Carrier`),
    );
    for (const branch of operation.resultBranches) {
      const branchName =
        branch === "rejected" ? "Rejected" : capitalize(branch);
      packageSymbols.push(
        goSymbol(`${source}:branch:${branch}:interface`, `${name}${branchName}`),
        goSymbol(
          `${source}:branch:${branch}:implementation`,
          `${privateName}${branchName}`,
        ),
      );
      generatedSymbolTable([
        goSymbol(
          `${source}:branch:${branch}:outcome-marker`,
          `is${name}Outcome`,
        ),
        goSymbol(
          `${source}:branch:${branch}:branch-marker`,
          `is${name}${branchName}`,
        ),
      ]);
    }
    generatedSymbolTable([
      goSymbol(`${source}:outcome:marker`, `is${name}Outcome`),
      goSymbol(`${source}:outcome:any-marker`, "isAnyOutcome"),
    ]);
    generatedSymbolTable([
      goSymbol(`${source}:view:any-marker`, "isAnyOutcomeView"),
      goSymbol(`${source}:view:operation-id`, "OperationID"),
      goSymbol(`${source}:view:branch`, "Branch"),
      goSymbol(`${source}:view:carrier-kind`, "CarrierKind"),
      goSymbol(`${source}:view:schema-stable-id`, "SchemaStableID"),
      goSymbol(`${source}:view:request-error`, "RequestError"),
      goSymbol(`${source}:view:recovery-error`, "RecoveryError"),
    ]);
  }

  generatedSymbolTable(packageSymbols);
  generatedSymbolTable(serviceMethods);
}

const goKeywords = new Set([
  "break",
  "case",
  "chan",
  "const",
  "continue",
  "default",
  "defer",
  "else",
  "fallthrough",
  "for",
  "func",
  "go",
  "goto",
  "if",
  "import",
  "interface",
  "map",
  "package",
  "range",
  "return",
  "select",
  "struct",
  "switch",
  "type",
  "var",
]);

function goSymbol(source: string, name: string): GeneratedSymbol {
  if (!/^[A-Za-z_][A-Za-z0-9_]*$/.test(name) || goKeywords.has(name)) {
    throw new Error("contract/generated-name-invalid");
  }
  return Object.freeze({ source, name });
}

function capitalize(value: string): string {
  return value.slice(0, 1).toUpperCase() + value.slice(1);
}

function literal(value: string): string {
  return JSON.stringify(value);
}
