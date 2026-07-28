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
  snakeCase,
  type GeneratedFile,
  type GeneratedSymbol,
} from "./common.js";

export function generateRust(
  model: Readonly<ContractModel>,
): readonly GeneratedFile[] {
  assertNames(model);
  const operations = [...model.operations].sort((left, right) =>
    compareStrings(left.operationId, right.operationId),
  );
  return Object.freeze([
    generatedFile("rust/lib.rs", rustLibrary(model, operations)),
    generatedFile("rust/validate.rs", rustValidator()),
  ]);
}

function rustLibrary(
  model: Readonly<ContractModel>,
  operations: readonly OperationContract[],
): string {
  const sections = [
    `use std::collections::BTreeMap;
use std::fmt;

pub const INVALID_OUTCOME: &str = "contract/invalid-outcome";

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct ContractDiagnostic {
    category: &'static str,
}

impl ContractDiagnostic {
    pub fn category(&self) -> &'static str {
        self.category
    }
}

impl fmt::Display for ContractDiagnostic {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        formatter.write_str(self.category)
    }
}

impl std::error::Error for ContractDiagnostic {}

fn invalid() -> ContractDiagnostic {
    ContractDiagnostic { category: INVALID_OUTCOME }
}
`,
    closedSums(model),
    wireIdentities(model),
    operations.map(operationTypes).join("\n"),
    anyOutcome(operations),
    serviceTrait(operations),
    operations.map(operationDecoder).join("\n"),
    dispatchDecoder(operations),
    parserSource,
  ];
  return `${sections.join("\n")}\n`;
}

function closedSums(model: Readonly<ContractModel>): string {
  return [...model.closedSums]
    .sort((left, right) => compareStrings(left.id, right.id))
    .map((sum) => {
      const variants = [...sum.variants]
        .sort((left, right) => compareStrings(left.id, right.id))
        .map((variant) => {
          if (variant.wireTag === undefined || !/^[1-9][0-9]*$/.test(variant.wireTag)) {
            throw new Error("contract/generated-wire-tag-invalid");
          }
          return `    ${generatedName(variant.id)} = ${variant.wireTag},`;
        })
        .join("\n");
      return `#[derive(Clone, Copy, Debug, PartialEq, Eq)]
#[repr(u32)]
pub enum ${generatedName(sum.id)} {
${variants}
}
`;
    })
    .join("\n");
}

function wireIdentities(model: Readonly<ContractModel>): string {
  const identities = [...deriveWireIdentities(model)]
    .sort(
      (left, right) =>
        compareStrings(left.containerId, right.containerId) ||
        compareStrings(left.variantId, right.variantId),
    )
    .map(
      (identity) =>
        `    (${literal(identity.containerId)}, ${literal(identity.variantId)}, ${identity.wireTag}),`,
    )
    .join("\n");
  return `pub const WIRE_IDENTITIES: &[(&str, &str, u32)] = &[
${identities}
];
`;
}

function operationTypes(operation: OperationContract): string {
  const name = operationName(operation);
  const carrier = `${name}Carrier`;
  const outcomes = operation.resultBranches
    .map((branch) => {
      switch (branch) {
        case "accepted":
          return `    Accepted(${carrier}),`;
        case "observed":
          return `    Observed(${carrier}),`;
        case "rejected":
          return `    Rejected(${name}RequestError),`;
        case "recovery":
          return `    Recovery(${name}RecoveryError),`;
      }
    })
    .join("\n");
  return `#[derive(Clone, Debug, PartialEq, Eq)]
pub enum ${name}RequestError {
${enumVariants(operation.allowedRequestErrors)}
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum ${name}RecoveryError {
${enumVariants(operation.allowedRecoveryErrors)}
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum ${name}KnownFailure {
${enumVariants(operation.allowedKnownFailures)}
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum ${name}Ambiguity {
${enumVariants(operation.allowedAmbiguities)}
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct ${carrier} {
    private: (),
}

impl ${carrier} {
    fn new() -> Self {
        Self { private: () }
    }

    pub fn carrier_kind(&self) -> &'static str {
        ${literal(operation.result.carrierKind)}
    }

    pub fn schema_stable_id(&self) -> &'static str {
        ${literal(operation.result.schemaStableId)}
    }
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum ${name}Outcome {
${outcomes}
}
`;
}

function enumVariants(stableIds: readonly string[]): string {
  return [...stableIds]
    .sort(compareStrings)
    .map((stableId) => `    ${generatedName(stableId)},`)
    .join("\n");
}

function anyOutcome(operations: readonly OperationContract[]): string {
  return `#[derive(Clone, Debug, PartialEq, Eq)]
pub enum AnyOutcome {
${operations
  .map(
    (operation) =>
      `    ${operationName(operation)}(${operationName(operation)}Outcome),`,
  )
  .join("\n")}
}
`;
}

function serviceTrait(operations: readonly OperationContract[]): string {
  return `pub trait PacketEService {
${operations
  .map(
    (operation) =>
      `    fn ${snakeCase(operationName(operation))}(&self) -> ${operationName(operation)}Outcome;`,
  )
  .join("\n")}
}
`;
}

function operationDecoder(operation: OperationContract): string {
  const name = operationName(operation);
  const functionName = `decode_${snakeCase(name)}_outcome`;
  const branches = operation.resultBranches
    .map((branch) => decoderBranch(operation, branch))
    .join("\n");
  return `pub fn ${functionName}(input: &[u8]) -> Result<${name}Outcome, ContractDiagnostic> {
    let fields = parse_flat_object(input)?;
    expect_value(&fields, "operationId", ${literal(operation.operationId)})?;
    match required(&fields, "branch")? {
${branches}
        _ => Err(invalid()),
    }
}
`;
}

function decoderBranch(
  operation: OperationContract,
  branch: OperationContract["resultBranches"][number],
): string {
  const name = operationName(operation);
  if (branch === "accepted" || branch === "observed") {
    const variant = branch === "accepted" ? "Accepted" : "Observed";
    return `        ${literal(branch)} => {
            expect_keys(&fields, &["operationId", "branch", "carrierKind", "schemaStableId"])?;
            expect_value(&fields, "carrierKind", ${literal(operation.result.carrierKind)})?;
            expect_value(&fields, "schemaStableId", ${literal(operation.result.schemaStableId)})?;
            Ok(${name}Outcome::${variant}(${name}Carrier::new()))
        }`;
  }
  const ids =
    branch === "rejected"
      ? operation.allowedRequestErrors
      : operation.allowedRecoveryErrors;
  const field = branch === "rejected" ? "requestErrorId" : "recoveryErrorId";
  const type = branch === "rejected" ? "RequestError" : "RecoveryError";
  const variant = branch === "rejected" ? "Rejected" : "Recovery";
  const matches = ids
    .map(
      (stableId) =>
        `                ${literal(stableId)} => ${name}${type}::${generatedName(stableId)},`,
    )
    .join("\n");
  return `        ${literal(branch)} => {
            expect_keys(&fields, &["operationId", "branch", "${field}"])?;
            let reason = match required(&fields, "${field}")? {
${matches}
                _ => return Err(invalid()),
            };
            Ok(${name}Outcome::${variant}(reason))
        }`;
}

function dispatchDecoder(operations: readonly OperationContract[]): string {
  return `pub fn decode_outcome(input: &[u8]) -> Result<AnyOutcome, ContractDiagnostic> {
    let fields = parse_flat_object(input)?;
    match required(&fields, "operationId")? {
${operations
  .map(
    (operation) =>
      `        ${literal(operation.operationId)} => decode_${snakeCase(operationName(operation))}_outcome(input).map(AnyOutcome::${operationName(operation)}),`,
  )
  .join("\n")}
        _ => Err(invalid()),
    }
}
`;
}

const parserSource = `struct Parser<'a> {
    input: &'a [u8],
    offset: usize,
}

impl<'a> Parser<'a> {
    fn new(input: &'a [u8]) -> Self {
        Self { input, offset: 0 }
    }

    fn whitespace(&mut self) {
        while matches!(self.input.get(self.offset), Some(b' ' | b'\\n' | b'\\r' | b'\\t')) {
            self.offset += 1;
        }
    }

    fn byte(&mut self, expected: u8) -> Result<(), ContractDiagnostic> {
        if self.input.get(self.offset) == Some(&expected) {
            self.offset += 1;
            Ok(())
        } else {
            Err(invalid())
        }
    }

    fn string(&mut self) -> Result<String, ContractDiagnostic> {
        self.byte(b'"')?;
        let mut output = String::new();
        loop {
            let byte = *self.input.get(self.offset).ok_or_else(invalid)?;
            self.offset += 1;
            match byte {
                b'"' => return Ok(output),
                b'\\\\' => {
                    let escaped = *self.input.get(self.offset).ok_or_else(invalid)?;
                    self.offset += 1;
                    match escaped {
                        b'"' => output.push('"'),
                        b'\\\\' => output.push('\\\\'),
                        b'/' => output.push('/'),
                        b'b' => output.push('\\u{0008}'),
                        b'f' => output.push('\\u{000c}'),
                        b'n' => output.push('\\n'),
                        b'r' => output.push('\\r'),
                        b't' => output.push('\\t'),
                        b'u' => {
                            let mut value = 0_u32;
                            for _ in 0..4 {
                                let digit = *self.input.get(self.offset).ok_or_else(invalid)?;
                                self.offset += 1;
                                value = value * 16 + match digit {
                                    b'0'..=b'9' => u32::from(digit - b'0'),
                                    b'a'..=b'f' => u32::from(digit - b'a' + 10),
                                    b'A'..=b'F' => u32::from(digit - b'A' + 10),
                                    _ => return Err(invalid()),
                                };
                            }
                            output.push(char::from_u32(value).ok_or_else(invalid)?);
                        }
                        _ => return Err(invalid()),
                    }
                }
                0x00..=0x1f | 0x80..=0xff => return Err(invalid()),
                _ => output.push(char::from(byte)),
            }
        }
    }
}

fn parse_flat_object(input: &[u8]) -> Result<BTreeMap<String, String>, ContractDiagnostic> {
    let mut parser = Parser::new(input);
    let mut fields = BTreeMap::new();
    parser.whitespace();
    parser.byte(b'{')?;
    parser.whitespace();
    if parser.input.get(parser.offset) == Some(&b'}') {
        parser.offset += 1;
    } else {
        loop {
            let key = parser.string()?;
            parser.whitespace();
            parser.byte(b':')?;
            parser.whitespace();
            let value = parser.string()?;
            if fields.insert(key, value).is_some() {
                return Err(invalid());
            }
            parser.whitespace();
            match parser.input.get(parser.offset) {
                Some(b',') => {
                    parser.offset += 1;
                    parser.whitespace();
                }
                Some(b'}') => {
                    parser.offset += 1;
                    break;
                }
                _ => return Err(invalid()),
            }
        }
    }
    parser.whitespace();
    if parser.offset != parser.input.len() {
        return Err(invalid());
    }
    Ok(fields)
}

fn required<'a>(
    fields: &'a BTreeMap<String, String>,
    name: &str,
) -> Result<&'a str, ContractDiagnostic> {
    fields.get(name).map(String::as_str).ok_or_else(invalid)
}

fn expect_value(
    fields: &BTreeMap<String, String>,
    name: &str,
    expected: &str,
) -> Result<(), ContractDiagnostic> {
    if required(fields, name)? == expected {
        Ok(())
    } else {
        Err(invalid())
    }
}

fn expect_keys(
    fields: &BTreeMap<String, String>,
    expected: &[&str],
) -> Result<(), ContractDiagnostic> {
    if fields.len() == expected.len() && expected.iter().all(|key| fields.contains_key(*key)) {
        Ok(())
    } else {
        Err(invalid())
    }
}`;

function rustValidator(): string {
  return `#[path = "lib.rs"]
mod contract;

fn main() {
    let path = std::env::args().nth(1).expect("fixture path");
    let bytes = std::fs::read(path).expect("read fixture");
    match contract::decode_outcome(&bytes) {
        Ok(_) => println!("ok"),
        Err(diagnostic) => println!("{}", diagnostic.category()),
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
  const topLevelTypes: GeneratedSymbol[] = [
    rustSymbol("fixed:type:BTreeMap", "BTreeMap"),
    rustSymbol("fixed:type:ContractDiagnostic", "ContractDiagnostic"),
    rustSymbol("fixed:type:AnyOutcome", "AnyOutcome"),
    rustSymbol("fixed:type:PacketEService", "PacketEService"),
    rustSymbol("fixed:type:Parser", "Parser"),
    rustSymbol("prelude:type:Result", "Result"),
    rustSymbol("prelude:type:String", "String"),
  ];
  const topLevelValues: GeneratedSymbol[] = [
    rustSymbol("fixed:value:INVALID_OUTCOME", "INVALID_OUTCOME"),
    rustSymbol("fixed:value:WIRE_IDENTITIES", "WIRE_IDENTITIES"),
    rustSymbol("fixed:value:invalid", "invalid"),
    rustSymbol("fixed:value:decode_outcome", "decode_outcome"),
    rustSymbol("fixed:value:expect_keys", "expect_keys"),
    rustSymbol("fixed:value:expect_value", "expect_value"),
    rustSymbol("fixed:value:parse_flat_object", "parse_flat_object"),
    rustSymbol("fixed:value:required", "required"),
  ];
  const anyOutcomeVariants: GeneratedSymbol[] = [];
  const serviceMethods: GeneratedSymbol[] = [];

  for (const sum of model.closedSums) {
    topLevelTypes.push(
      rustSymbol(`closed-sum:${sum.id}`, generatedName(sum.id)),
    );
    generatedSymbolTable(
      sum.variants.map((variant) =>
        rustSymbol(`variant:${variant.id}`, generatedName(variant.id)),
      ),
    );
  }

  for (const operation of model.operations) {
    const name = operationName(operation);
    const source = `operation:${operation.operationId}`;
    for (const suffix of [
      "RequestError",
      "RecoveryError",
      "KnownFailure",
      "Ambiguity",
      "Carrier",
      "Outcome",
    ]) {
      topLevelTypes.push(
        rustSymbol(`${source}:type:${suffix}`, `${name}${suffix}`),
      );
    }
    topLevelValues.push(
      rustSymbol(
        `${source}:decoder`,
        `decode_${snakeCase(name)}_outcome`,
      ),
    );
    anyOutcomeVariants.push(rustSymbol(source, name));
    serviceMethods.push(rustSymbol(source, snakeCase(name)));

    for (const [scope, stableIds] of [
      ["request-error", operation.allowedRequestErrors],
      ["recovery-error", operation.allowedRecoveryErrors],
      ["known-failure", operation.allowedKnownFailures],
      ["ambiguity", operation.allowedAmbiguities],
    ] as const) {
      generatedSymbolTable(
        stableIds.map((stableId) =>
          rustSymbol(`${source}:${scope}:${stableId}`, generatedName(stableId)),
        ),
      );
    }
    generatedSymbolTable(
      operation.resultBranches.map((branch) =>
        rustSymbol(`${source}:outcome:${branch}`, generatedName(branch)),
      ),
    );
    generatedSymbolTable([
      rustSymbol(`${source}:carrier:new`, "new"),
      rustSymbol(`${source}:carrier:kind`, "carrier_kind"),
      rustSymbol(`${source}:carrier:schema`, "schema_stable_id"),
    ]);
  }

  generatedSymbolTable(topLevelTypes);
  generatedSymbolTable(topLevelValues);
  generatedSymbolTable(anyOutcomeVariants);
  generatedSymbolTable(serviceMethods);
}

const rustKeywords = new Set([
  "Self",
  "abstract",
  "as",
  "async",
  "await",
  "become",
  "box",
  "break",
  "const",
  "continue",
  "crate",
  "do",
  "dyn",
  "else",
  "enum",
  "extern",
  "false",
  "final",
  "fn",
  "for",
  "gen",
  "if",
  "impl",
  "in",
  "let",
  "loop",
  "macro",
  "match",
  "mod",
  "move",
  "mut",
  "override",
  "priv",
  "pub",
  "ref",
  "return",
  "self",
  "static",
  "struct",
  "super",
  "trait",
  "true",
  "try",
  "type",
  "typeof",
  "unsafe",
  "unsized",
  "use",
  "virtual",
  "where",
  "while",
  "yield",
]);

function rustSymbol(source: string, name: string): GeneratedSymbol {
  if (!/^[A-Za-z_][A-Za-z0-9_]*$/.test(name) || rustKeywords.has(name)) {
    throw new Error("contract/generated-name-invalid");
  }
  return Object.freeze({ source, name });
}

function literal(value: string): string {
  return JSON.stringify(value);
}
