use serde::de::{
    DeserializeSeed, Error as DeError, IntoDeserializer, MapAccess, SeqAccess, Visitor,
};
use serde::{Deserialize, Serialize};
use serde_json::{json, Number, Value};
use sha2::{Digest, Sha256};
use std::collections::{BTreeMap, BTreeSet};
use std::fmt;
use std::fs;
use std::io::{self, Write};
use std::path::Path;

const DUPLICATE_MARKER: &str = "__WIRE_DUPLICATE__:";
const DEPTH_MARKER: &str = "__WIRE_DEPTH__:";
const NUMBER_DOMAIN_MARKER: &str = "__WIRE_NUMBER_DOMAIN__:";
const COMPARISON_ENCODING: &str = "artifact-comparison-json-v0";
const MAX_INPUT_BYTES: usize = 1_048_576;
const MAX_NESTING_DEPTH: usize = 64;
const MAX_SAFE_JSON_INTEGER: u64 = 9_007_199_254_740_991;

#[derive(Clone, Debug)]
enum Node {
    Null,
    Bool(bool),
    Number(Number),
    String(String),
    Array(Vec<Node>),
    Object(BTreeMap<String, Node>),
}

impl Node {
    fn as_object(&self) -> Option<&BTreeMap<String, Node>> {
        match self {
            Self::Object(value) => Some(value),
            _ => None,
        }
    }

    fn to_json_value(&self) -> Value {
        match self {
            Self::Null => Value::Null,
            Self::Bool(value) => Value::Bool(*value),
            Self::Number(value) => Value::Number(value.clone()),
            Self::String(value) => Value::String(value.clone()),
            Self::Array(values) => Value::Array(values.iter().map(Self::to_json_value).collect()),
            Self::Object(values) => Value::Object(
                values
                    .iter()
                    .map(|(key, value)| (key.clone(), value.to_json_value()))
                    .collect(),
            ),
        }
    }

    fn write_comparison_json(&self, output: &mut Vec<u8>) {
        match self {
            Self::Null => output.extend_from_slice(b"null"),
            Self::Bool(false) => output.extend_from_slice(b"false"),
            Self::Bool(true) => output.extend_from_slice(b"true"),
            Self::Number(value) => output.extend_from_slice(value.to_string().as_bytes()),
            Self::String(value) => {
                output.extend_from_slice(
                    serde_json::to_string(value)
                        .expect("serializing a JSON string cannot fail")
                        .as_bytes(),
                );
            }
            Self::Array(values) => {
                output.push(b'[');
                for (index, value) in values.iter().enumerate() {
                    if index != 0 {
                        output.push(b',');
                    }
                    value.write_comparison_json(output);
                }
                output.push(b']');
            }
            Self::Object(values) => {
                output.push(b'{');
                for (index, (key, value)) in values.iter().enumerate() {
                    if index != 0 {
                        output.push(b',');
                    }
                    output.extend_from_slice(
                        serde_json::to_string(key)
                            .expect("serializing a JSON object key cannot fail")
                            .as_bytes(),
                    );
                    output.push(b':');
                    value.write_comparison_json(output);
                }
                output.push(b'}');
            }
        }
    }
}

struct NodeSeed {
    path: String,
    depth: usize,
}

impl<'de> DeserializeSeed<'de> for NodeSeed {
    type Value = Node;

    fn deserialize<D>(self, deserializer: D) -> Result<Self::Value, D::Error>
    where
        D: serde::Deserializer<'de>,
    {
        deserializer.deserialize_any(NodeVisitor {
            path: self.path,
            depth: self.depth,
        })
    }
}

struct NodeVisitor {
    path: String,
    depth: usize,
}

impl<'de> Visitor<'de> for NodeVisitor {
    type Value = Node;

    fn expecting(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        formatter.write_str("a JSON value")
    }

    fn visit_bool<E>(self, value: bool) -> Result<Self::Value, E> {
        Ok(Node::Bool(value))
    }

    fn visit_i64<E>(self, value: i64) -> Result<Self::Value, E>
    where
        E: DeError,
    {
        if value.unsigned_abs() > MAX_SAFE_JSON_INTEGER {
            Err(E::custom(format!("{NUMBER_DOMAIN_MARKER}{}", self.path)))
        } else {
            Ok(Node::Number(Number::from(value)))
        }
    }

    fn visit_u64<E>(self, value: u64) -> Result<Self::Value, E>
    where
        E: DeError,
    {
        if value > MAX_SAFE_JSON_INTEGER {
            Err(E::custom(format!("{NUMBER_DOMAIN_MARKER}{}", self.path)))
        } else {
            Ok(Node::Number(Number::from(value)))
        }
    }

    fn visit_f64<E>(self, value: f64) -> Result<Self::Value, E>
    where
        E: DeError,
    {
        Number::from_f64(value)
            .map(Node::Number)
            .ok_or_else(|| E::custom("JSON number is not finite"))
    }

    fn visit_str<E>(self, value: &str) -> Result<Self::Value, E> {
        Ok(Node::String(value.to_owned()))
    }

    fn visit_string<E>(self, value: String) -> Result<Self::Value, E> {
        Ok(Node::String(value))
    }

    fn visit_none<E>(self) -> Result<Self::Value, E> {
        Ok(Node::Null)
    }

    fn visit_unit<E>(self) -> Result<Self::Value, E> {
        Ok(Node::Null)
    }

    fn visit_seq<A>(self, mut sequence: A) -> Result<Self::Value, A::Error>
    where
        A: SeqAccess<'de>,
    {
        if self.depth >= MAX_NESTING_DEPTH {
            return Err(A::Error::custom(format!("{DEPTH_MARKER}{}", self.path)));
        }
        let mut values = Vec::new();
        while let Some(value) = sequence.next_element_seed(NodeSeed {
            path: format!("{}[{}]", self.path, values.len()),
            depth: self.depth + 1,
        })? {
            values.push(value);
        }
        Ok(Node::Array(values))
    }

    fn visit_map<A>(self, mut map: A) -> Result<Self::Value, A::Error>
    where
        A: MapAccess<'de>,
    {
        if self.depth >= MAX_NESTING_DEPTH {
            return Err(A::Error::custom(format!("{DEPTH_MARKER}{}", self.path)));
        }
        let mut values = BTreeMap::new();
        while let Some(key) = map.next_key::<String>()? {
            let child_path = child_path(&self.path, &key);
            if values.contains_key(&key) {
                return Err(A::Error::custom(format!("{DUPLICATE_MARKER}{child_path}")));
            }
            let value = map.next_value_seed(NodeSeed {
                path: child_path,
                depth: self.depth + 1,
            })?;
            values.insert(key, value);
        }
        Ok(Node::Object(values))
    }
}

fn child_path(parent: &str, key: &str) -> String {
    let is_identifier = key.chars().enumerate().all(|(index, character)| {
        if index == 0 {
            character == '_' || character.is_ascii_alphabetic()
        } else {
            character == '_' || character.is_ascii_alphanumeric()
        }
    });

    if is_identifier {
        format!("{parent}.{key}")
    } else {
        format!(
            "{parent}[{}]",
            serde_json::to_string(key).expect("serializing a path key cannot fail")
        )
    }
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
struct Diagnostic {
    invariant: String,
    owner: &'static str,
    phase: &'static str,
    severity: &'static str,
    primary_path: String,
    primary_source_span: Option<SourceSpan>,
    related_paths: Vec<String>,
    related_definitions: Vec<Value>,
    actual_values: Value,
    constraint: String,
    message: String,
    remediation: String,
    cause_chain: Vec<Cause>,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
struct SourceSpan {
    file: String,
    line: usize,
    column: usize,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
struct Cause {
    layer: &'static str,
    summary: String,
}

type ValidationResult<T> = Result<T, Box<Diagnostic>>;

#[allow(clippy::too_many_arguments)]
fn diagnostic(
    invariant: &str,
    primary_path: impl Into<String>,
    related_paths: Vec<String>,
    actual_values: Value,
    constraint: impl Into<String>,
    message: impl Into<String>,
    remediation: impl Into<String>,
    cause: impl Into<String>,
) -> Box<Diagnostic> {
    Box::new(Diagnostic {
        invariant: invariant.to_owned(),
        owner: "artifact",
        phase: "W0",
        severity: "error",
        primary_path: primary_path.into(),
        primary_source_span: None,
        related_paths,
        related_definitions: Vec::new(),
        actual_values,
        constraint: constraint.into(),
        message: message.into(),
        remediation: remediation.into(),
        cause_chain: vec![Cause {
            layer: "wire-validator-prototype",
            summary: cause.into(),
        }],
    })
}

fn parse_unique_json(input: &[u8]) -> ValidationResult<Node> {
    if input.len() > MAX_INPUT_BYTES {
        return Err(diagnostic(
            "wire.input_size_bounded",
            "$",
            vec![],
            json!({"actualBytes": input.len(), "maximumBytes": MAX_INPUT_BYTES}),
            format!("Canonical input is at most {MAX_INPUT_BYTES} bytes."),
            "The portable Artifact input exceeds the decoder byte limit.",
            "Reduce the document size or move immutable content behind typed content references.",
            "The bounded decoder rejected the input before parsing.",
        ));
    }

    let mut deserializer = serde_json::Deserializer::from_slice(input);
    let parsed = NodeSeed {
        path: "$".to_owned(),
        depth: 0,
    }
    .deserialize(&mut deserializer);

    let node = match parsed {
        Ok(node) => node,
        Err(error) => {
            let native = error.to_string();
            if let Some(marker_index) = native.find(DUPLICATE_MARKER) {
                let after_marker = &native[marker_index + DUPLICATE_MARKER.len()..];
                let path = after_marker
                    .split(" at line ")
                    .next()
                    .unwrap_or(after_marker)
                    .to_owned();
                return Err(diagnostic(
                    "wire.object_keys_unique",
                    path.clone(),
                    vec![],
                    json!({"duplicateKeyPath": path}),
                    "Each object key occurs exactly once before semantic decoding.",
                    "The portable Artifact value contains a duplicate object key.",
                    "Remove one definition or compose the values before crossing the canonical boundary.",
                    "The duplicate-safe JSON decoder rejected the second key.",
                ));
            }
            if let Some(marker_index) = native.find(DEPTH_MARKER) {
                let after_marker = &native[marker_index + DEPTH_MARKER.len()..];
                let path = after_marker
                    .split(" at line ")
                    .next()
                    .unwrap_or(after_marker)
                    .to_owned();
                return Err(diagnostic(
                    "wire.nesting_depth_bounded",
                    path,
                    vec![],
                    json!({"maximumDepth": MAX_NESTING_DEPTH}),
                    format!("Canonical input nesting is at most {MAX_NESTING_DEPTH} levels."),
                    "The portable Artifact input exceeds the decoder nesting limit.",
                    "Flatten the document or move repeated content behind typed references.",
                    "The bounded decoder rejected excessive nesting before semantic interpretation.",
                ));
            }
            if let Some(marker_index) = native.find(NUMBER_DOMAIN_MARKER) {
                let after_marker = &native[marker_index + NUMBER_DOMAIN_MARKER.len()..];
                let path = after_marker
                    .split(" at line ")
                    .next()
                    .unwrap_or(after_marker)
                    .to_owned();
                return Err(diagnostic(
                    "wire.number_interoperable",
                    path,
                    vec![],
                    json!({"maximumSafeInteger": MAX_SAFE_JSON_INTEGER}),
                    "JSON integer values remain within the exact interoperable binary64 range.",
                    "The portable Artifact contains a JSON integer outside the interoperable domain.",
                    "Encode exact large quantities through the schema's string-based quantity representation.",
                    "The decoder rejected a non-interoperable number before schema decoding.",
                ));
            }

            return Err(diagnostic(
                "wire.json_valid",
                "$",
                vec![],
                json!({}),
                "The comparison input must be syntactically valid JSON.",
                "The portable Artifact value could not be decoded.",
                "Correct the JSON syntax before canonical-wire validation.",
                native,
            ));
        }
    };

    if let Err(error) = deserializer.end() {
        return Err(diagnostic(
            "wire.json_single_value",
            "$",
            vec![],
            json!({}),
            "Exactly one JSON value is accepted.",
            "Trailing data followed the portable Artifact value.",
            "Remove the trailing data before canonical-wire validation.",
            error.to_string(),
        ));
    }

    Ok(node)
}

fn unknown_field_diagnostic(path: &str, field: &str) -> Box<Diagnostic> {
    let field_path = child_path(path, field);
    diagnostic(
        "artifact.records.closed",
        field_path,
        vec![path.to_owned()],
        json!({"unknownField": field}),
        "Portable Artifact records are closed except at the explicit extensions object.",
        format!("Field `{field}` is not declared at `{path}`."),
        "Remove the field, correct its spelling, or place a namespaced value in the explicit extensions object.",
        "Closed-record validation found an undeclared field.",
    )
}

fn ensure_known_fields(
    object: &BTreeMap<String, Node>,
    path: &str,
    allowed: &[&str],
) -> ValidationResult<()> {
    for field in object.keys() {
        if !allowed.contains(&field.as_str()) {
            return Err(unknown_field_diagnostic(path, field));
        }
    }
    Ok(())
}

fn validate_closed_records(root: &Node) -> ValidationResult<()> {
    let Some(root) = root.as_object() else {
        return Ok(());
    };

    ensure_known_fields(
        root,
        "$",
        &[
            "schemaVersion",
            "profile",
            "environment",
            "workspace",
            "network",
            "secrets",
            "resources",
            "targets",
            "requiredCapabilities",
            "runtimeProfiles",
            "extensions",
        ],
    )?;

    if let Some(value) = root.get("schemaVersion").and_then(Node::as_object) {
        ensure_known_fields(value, "$.schemaVersion", &["major", "minor"])?;
    }
    if let Some(value) = root.get("profile").and_then(Node::as_object) {
        ensure_known_fields(value, "$.profile", &["selected", "selectionIsVisible"])?;
    }
    if let Some(value) = root.get("environment").and_then(Node::as_object) {
        ensure_known_fields(
            value,
            "$.environment",
            &["packages", "variables", "activation"],
        )?;
        if let Some(Node::Array(packages)) = value.get("packages") {
            for (index, package) in packages.iter().enumerate() {
                if let Some(package) = package.as_object() {
                    let package_path = format!("$.environment.packages[{index}]");
                    ensure_known_fields(package, &package_path, &["source"])?;
                    if let Some(source) = package.get("source").and_then(Node::as_object) {
                        ensure_known_fields(
                            source,
                            &format!("{package_path}.source"),
                            &["kind", "input", "attribute"],
                        )?;
                    }
                }
            }
        }
    }
    if let Some(value) = root.get("workspace").and_then(Node::as_object) {
        ensure_known_fields(
            value,
            "$.workspace",
            &[
                "destination",
                "materialization",
                "allowedMaterializations",
                "access",
            ],
        )?;
    }
    if let Some(value) = root.get("network").and_then(Node::as_object) {
        ensure_known_fields(value, "$.network", &["mode", "egressAllow", "hardPolicy"])?;
        if let Some(hard_policy) = value.get("hardPolicy").and_then(Node::as_object) {
            ensure_known_fields(
                hard_policy,
                "$.network.hardPolicy",
                &["allowedDestinations"],
            )?;
        }
    }
    if let Some(Node::Array(secrets)) = root.get("secrets") {
        for (index, secret) in secrets.iter().enumerate() {
            if let Some(secret) = secret.as_object() {
                let secret_path = format!("$.secrets[{index}]");
                if secret.contains_key("value") {
                    return Err(diagnostic(
                        "artifact.secrets.descriptors_only",
                        format!("{secret_path}.value"),
                        vec![secret_path],
                        json!({"summary": "[redacted]"}),
                        "Immutable Artifact input may contain secret-slot descriptors, never secret values or value-derived hashes.",
                        "A secret value was supplied where only a slot contract is permitted.",
                        "Remove the value and bind the declared slot through CreateSandbox or operator-controlled delivery.",
                        "Secret-safe closed-record validation rejected a prohibited value field.",
                    ));
                }
                ensure_known_fields(secret, &secret_path, &["name", "delivery"])?;
            }
        }
    }
    if let Some(value) = root.get("resources").and_then(Node::as_object) {
        ensure_known_fields(value, "$.resources", &["memory"])?;
        if let Some(memory) = value.get("memory").and_then(Node::as_object) {
            ensure_known_fields(
                memory,
                "$.resources.memory",
                &["minimumBytes", "maximumBytes"],
            )?;
        }
    }
    if let Some(extensions) = root.get("extensions").and_then(Node::as_object) {
        if let Some(extension) = extensions.keys().next() {
            return Err(diagnostic(
                "artifact.extensions.registered",
                child_path("$.extensions", extension),
                vec!["$.extensions".to_owned()],
                json!({"extensionIdentity": extension}),
                "Every extension identity is namespaced, registered for this schema version, and validated by its closed contract.",
                "The comparison schema does not register this extension identity.",
                "Remove the extension or use a version that explicitly registers and validates its contract.",
                "Extension admission rejected an unregistered value before canonicalization.",
            ));
        }
    }
    if let Some(Node::Object(runtime_profiles)) = root.get("runtimeProfiles") {
        for (profile_name, profile) in runtime_profiles {
            if let Some(profile) = profile.as_object() {
                ensure_known_fields(
                    profile,
                    &child_path("$.runtimeProfiles", profile_name),
                    &["target", "materializations"],
                )?;
            }
        }
    }

    Ok(())
}

#[allow(dead_code)]
#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
struct Artifact {
    schema_version: SchemaVersion,
    profile: Profile,
    environment: Environment,
    workspace: Workspace,
    network: Network,
    secrets: Vec<SecretSlot>,
    resources: Resources,
    targets: Vec<String>,
    required_capabilities: Vec<String>,
    runtime_profiles: BTreeMap<String, RuntimeProfile>,
    extensions: BTreeMap<String, Value>,
}

#[allow(dead_code)]
#[derive(Debug, Deserialize)]
#[serde(deny_unknown_fields)]
struct SchemaVersion {
    major: u64,
    minor: u64,
}

#[allow(dead_code)]
#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
struct Profile {
    selected: String,
    selection_is_visible: bool,
}

#[allow(dead_code)]
#[derive(Debug, Deserialize)]
#[serde(deny_unknown_fields)]
struct Environment {
    packages: Vec<Package>,
    variables: BTreeMap<String, String>,
    activation: Vec<Vec<String>>,
}

#[allow(dead_code)]
#[derive(Debug, Deserialize)]
#[serde(deny_unknown_fields)]
struct Package {
    source: PackageSource,
}

#[allow(dead_code)]
#[derive(Debug, Deserialize)]
#[serde(deny_unknown_fields)]
struct PackageSource {
    kind: String,
    input: String,
    attribute: String,
}

#[allow(dead_code)]
#[derive(Debug, Deserialize)]
#[serde(deny_unknown_fields)]
struct Workspace {
    destination: String,
    materialization: String,
    #[serde(rename = "allowedMaterializations")]
    allowed_materializations: Vec<String>,
    access: String,
}

#[allow(dead_code)]
#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
struct Network {
    mode: String,
    egress_allow: Vec<String>,
    hard_policy: HardPolicy,
}

#[allow(dead_code)]
#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
struct HardPolicy {
    allowed_destinations: Vec<String>,
}

#[allow(dead_code)]
#[derive(Debug, Deserialize)]
#[serde(deny_unknown_fields)]
struct SecretSlot {
    name: String,
    delivery: Vec<String>,
}

#[allow(dead_code)]
#[derive(Debug, Deserialize)]
#[serde(deny_unknown_fields)]
struct Resources {
    memory: Memory,
}

#[allow(dead_code)]
#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
struct Memory {
    minimum_bytes: u64,
    maximum_bytes: u64,
}

#[allow(dead_code)]
#[derive(Debug, Deserialize)]
#[serde(deny_unknown_fields)]
struct RuntimeProfile {
    target: String,
    materializations: Vec<String>,
}

fn serde_path(path: &str) -> String {
    if path.is_empty() {
        "$".to_owned()
    } else {
        format!("$.{path}")
    }
}

fn decode_artifact(node: &Node) -> ValidationResult<Artifact> {
    let deserializer = node.to_json_value().into_deserializer();
    match serde_path_to_error::deserialize(deserializer) {
        Ok(artifact) => Ok(artifact),
        Err(error) => {
            let path = serde_path(&error.path().to_string());
            let native = error.inner().to_string();
            let is_byte_quantity = matches!(
                path.as_str(),
                "$.resources.memory.minimumBytes" | "$.resources.memory.maximumBytes"
            );

            if is_byte_quantity && native.contains("floating point") {
                return Err(diagnostic(
                    "artifact.resources.byte_quantity_integer",
                    path,
                    vec![],
                    json!({"kind": "nonIntegralNumber"}),
                    "Byte quantities are non-negative integers in the portable Artifact value.",
                    "A resource byte quantity is not an integer.",
                    "Express the normalized quantity as an integer number of bytes.",
                    native,
                ));
            }

            Err(diagnostic(
                "artifact.schema_shape",
                path,
                vec![],
                json!({}),
                "The portable Artifact value must match the closed comparison schema.",
                "The portable Artifact value has an invalid or missing field.",
                "Correct the field type or supply the required field before canonical-wire validation.",
                native,
            ))
        }
    }
}

fn validate_semantics(artifact: &Artifact) -> ValidationResult<()> {
    if artifact.schema_version.major != 0 {
        return Err(diagnostic(
            "artifact.schema_version_supported",
            "$.schemaVersion.major",
            vec![],
            json!({
                "actualMajor": artifact.schema_version.major,
                "supportedMajors": [0]
            }),
            "This prototype accepts comparison schema major 0 only and never falls back across majors.",
            "The portable Artifact value uses an unsupported schema major.",
            "Migrate the value with an explicitly supported migration before validation.",
            "Schema-version admission rejected the major version.",
        ));
    }

    if !is_normalized_absolute_path(&artifact.workspace.destination) {
        return Err(diagnostic(
            "artifact.workspace.destination_absolute",
            "$.workspace.destination",
            vec![],
            json!({"kind": "nonAbsoluteOrNonNormalizedPath"}),
            "Every in-sandbox destination is normalized and absolute.",
            "The workspace destination is not a normalized absolute path.",
            "Use an absolute in-sandbox path without `.` or `..` components.",
            "Artifact semantic validation rejected the workspace destination.",
        ));
    }

    if artifact.network.mode == "disabled" && !artifact.network.egress_allow.is_empty() {
        return Err(diagnostic(
            "artifact.network.disabled_has_no_egress",
            "$.network.egressAllow",
            vec!["$.network.mode".to_owned()],
            json!({
                "mode": "disabled",
                "egressRuleCount": artifact.network.egress_allow.len()
            }),
            "Disabled networking has no egress allowlist or other subordinate network policy.",
            "The disabled network mode conflicts with a non-empty egress allowlist.",
            "Remove the egress rules or explicitly select a network mode that permits them.",
            "Cross-field Artifact semantic validation found contradictory network settings.",
        ));
    }

    if !artifact
        .workspace
        .allowed_materializations
        .contains(&artifact.workspace.materialization)
    {
        return Err(diagnostic(
            "artifact.workspace.selected_materialization_allowed",
            "$.workspace.materialization",
            vec!["$.workspace.allowedMaterializations".to_owned()],
            json!({
                "selected": artifact.workspace.materialization,
                "allowed": artifact.workspace.allowed_materializations
            }),
            "The selected workspace materialization is one of the Artifact-declared alternatives.",
            "The selected workspace materialization is absent from the allowed alternatives.",
            "Add the selected materialization to the allowed set or select an allowed alternative.",
            "Cross-field Artifact semantic validation found an inconsistent workspace contract.",
        ));
    }

    let hard_destinations: BTreeSet<_> = artifact
        .network
        .hard_policy
        .allowed_destinations
        .iter()
        .collect();
    if let Some(destination) = artifact
        .network
        .egress_allow
        .iter()
        .find(|destination| !hard_destinations.contains(destination))
    {
        return Err(diagnostic(
            "artifact.network.egress_refines_hard_policy",
            "$.network.egressAllow",
            vec!["$.network.hardPolicy.allowedDestinations".to_owned()],
            json!({"outsideHardPolicy": destination}),
            "Effective egress destinations are a subset of the immutable hard-policy destinations.",
            "An effective egress destination widens the Artifact hard policy.",
            "Remove the destination or change the Artifact-owned hard-policy base at its definition source.",
            "Cross-field Artifact semantic validation rejected policy widening.",
        ));
    }

    let expected_capabilities = [
        format!("network.{}", artifact.network.mode),
        format!("workspace.{}", artifact.workspace.materialization),
    ];
    if artifact.required_capabilities != expected_capabilities {
        return Err(diagnostic(
            "artifact.required_capabilities.match_semantics",
            "$.requiredCapabilities",
            vec![
                "$.network.mode".to_owned(),
                "$.workspace.materialization".to_owned(),
            ],
            json!({
                "declared": artifact.required_capabilities,
                "expected": expected_capabilities
            }),
            "Normalized required capabilities exactly describe the selected common Artifact semantics.",
            "The required-capability list is inconsistent with the workspace or network semantics.",
            "Regenerate required capabilities from the normalized Artifact rather than editing derived fields.",
            "Artifact semantic validation rejected inconsistent derived capabilities.",
        ));
    }

    if artifact.targets.is_empty() {
        return Err(diagnostic(
            "artifact.targets.non_empty",
            "$.targets",
            vec![],
            json!({"targetCount": 0}),
            "A normalized Artifact produces at least one explicitly named target.",
            "The portable Artifact value declares no targets.",
            "Declare at least one target whose capabilities satisfy the Artifact requirements.",
            "Artifact semantic validation found an empty target set.",
        ));
    }

    if artifact.resources.memory.minimum_bytes > artifact.resources.memory.maximum_bytes {
        return Err(diagnostic(
            "artifact.resources.memory_bounds_ordered",
            "$.resources.memory.minimumBytes",
            vec!["$.resources.memory.maximumBytes".to_owned()],
            json!({
                "minimumBytes": artifact.resources.memory.minimum_bytes,
                "maximumBytes": artifact.resources.memory.maximum_bytes
            }),
            "The memory minimum is less than or equal to the memory maximum.",
            "The Artifact memory bounds form an empty interval.",
            "Lower the minimum or raise the maximum without exceeding an enclosing hard policy.",
            "Artifact semantic validation rejected inconsistent memory bounds.",
        ));
    }

    let unique_targets: BTreeSet<_> = artifact.targets.iter().collect();
    if unique_targets.len() != artifact.targets.len() {
        return Err(diagnostic(
            "artifact.targets.unique",
            "$.targets",
            vec![],
            json!({"targetCount": artifact.targets.len()}),
            "Each target identity occurs at most once.",
            "The portable Artifact value repeats a target identity.",
            "Remove the duplicate target entry.",
            "Artifact semantic validation rejected a duplicate logical target.",
        ));
    }

    for (target_index, target) in artifact.targets.iter().enumerate() {
        for capability in &artifact.required_capabilities {
            if !target_supports(target, capability) {
                return Err(diagnostic(
                    "artifact.target.required_capability_supported",
                    format!("$.targets[{target_index}]"),
                    vec!["$.requiredCapabilities".to_owned()],
                    json!({
                        "target": target,
                        "unsupportedCapability": capability
                    }),
                    "Every enabled target satisfies every normalized required capability.",
                    "An enabled target cannot implement a mandatory Artifact capability.",
                    "Remove the target, change the Artifact requirement, or split divergent targets into separate Artifacts.",
                    "Target-capability validation rejected an impossible Artifact target set.",
                ));
            }
        }
    }

    for (profile_name, runtime_profile) in &artifact.runtime_profiles {
        let profile_path = child_path("$.runtimeProfiles", profile_name);
        if !artifact.targets.contains(&runtime_profile.target) {
            return Err(diagnostic(
                "artifact.runtime_profile.target_enabled",
                format!("{profile_path}.target"),
                vec!["$.targets".to_owned()],
                json!({"target": runtime_profile.target}),
                "Every runtime profile references a target enabled by the Artifact.",
                "A runtime profile references a target absent from the Artifact target set.",
                "Enable the target or remove the runtime profile.",
                "Artifact semantic validation rejected an orphan runtime profile.",
            ));
        }
        if runtime_profile.materializations.is_empty()
            || runtime_profile.materializations.iter().any(|candidate| {
                !artifact
                    .workspace
                    .allowed_materializations
                    .contains(candidate)
            })
        {
            return Err(diagnostic(
                "artifact.runtime_profile.materializations_allowed",
                format!("{profile_path}.materializations"),
                vec!["$.workspace.allowedMaterializations".to_owned()],
                json!({"profile": profile_name}),
                "Every runtime profile has at least one workspace materialization and all are Artifact-allowed.",
                "A runtime profile has no usable workspace materialization.",
                "Declare a non-empty subset of the Artifact-allowed materializations.",
                "Artifact semantic validation rejected an unusable runtime profile.",
            ));
        }
    }

    for (index, argv) in artifact.environment.activation.iter().enumerate() {
        if argv.is_empty() {
            return Err(diagnostic(
                "artifact.environment.activation_argv_non_empty",
                format!("$.environment.activation[{index}]"),
                vec![],
                json!({"argumentCount": 0}),
                "Every activation command is represented by a non-empty argv.",
                "An activation command has no executable.",
                "Supply the executable as the first argv element.",
                "Artifact semantic validation rejected an empty activation command.",
            ));
        }
    }

    Ok(())
}

fn target_supports(target: &str, capability: &str) -> bool {
    match target {
        "bubblewrap" => matches!(
            capability,
            "network.disabled" | "network.egress" | "workspace.copy" | "workspace.live"
        ),
        "firecracker" => matches!(
            capability,
            "network.disabled" | "network.egress" | "workspace.copy"
        ),
        _ => false,
    }
}

fn is_normalized_absolute_path(path: &str) -> bool {
    path.starts_with('/')
        && path != "/"
        && !path.ends_with('/')
        && !path
            .split('/')
            .any(|component| component == "." || component == "..")
        && !path.contains("//")
}

fn validate(input: &[u8]) -> ValidationResult<(Node, Vec<u8>, String)> {
    let node = parse_unique_json(input)?;
    validate_closed_records(&node)?;
    let artifact = decode_artifact(&node)?;
    validate_semantics(&artifact)?;

    let mut canonical = Vec::new();
    node.write_comparison_json(&mut canonical);
    let digest = Sha256::digest(&canonical);
    let sha256 = digest
        .iter()
        .map(|byte| format!("{byte:02x}"))
        .collect::<String>();

    Ok((node, canonical, sha256))
}

fn write_success(node: &Node, canonical: &[u8], sha256: &str) -> io::Result<()> {
    let mut stdout = io::stdout().lock();
    stdout.write_all(b"{\"artifact\":")?;
    stdout.write_all(canonical)?;
    stdout.write_all(b",\"comparisonEncoding\":")?;
    stdout.write_all(
        serde_json::to_string(COMPARISON_ENCODING)
            .expect("serializing an encoding identity cannot fail")
            .as_bytes(),
    )?;
    stdout.write_all(b",\"sha256\":")?;
    stdout.write_all(
        serde_json::to_string(sha256)
            .expect("serializing a digest cannot fail")
            .as_bytes(),
    )?;
    stdout.write_all(b"}\n")?;

    debug_assert_eq!(
        node.to_json_value(),
        serde_json::from_slice::<Value>(canonical).unwrap()
    );
    Ok(())
}

fn write_diagnostic(diagnostic: &Diagnostic) -> io::Result<()> {
    let mut stderr = io::stderr().lock();
    serde_json::to_writer(&mut stderr, diagnostic)?;
    stderr.write_all(b"\n")
}

fn usage() {
    eprintln!("usage: wire-validator-prototype check <portable-artifact.json>");
}

fn main() {
    let mut arguments = std::env::args_os();
    let _program = arguments.next();
    let command = arguments.next();
    let path = arguments.next();

    if command.as_deref() != Some(std::ffi::OsStr::new("check"))
        || path.is_none()
        || arguments.next().is_some()
    {
        usage();
        std::process::exit(64);
    }

    let path = path.expect("checked above");
    let input = match fs::read(Path::new(&path)) {
        Ok(input) => input,
        Err(error) => {
            eprintln!("failed to read {}: {error}", Path::new(&path).display());
            std::process::exit(66);
        }
    };

    match validate(&input) {
        Ok((node, canonical, sha256)) => {
            if let Err(error) = write_success(&node, &canonical, &sha256) {
                eprintln!("failed to write validation result: {error}");
                std::process::exit(74);
            }
        }
        Err(diagnostic) => {
            if let Err(error) = write_diagnostic(&diagnostic) {
                eprintln!("failed to write diagnostic: {error}");
                std::process::exit(74);
            }
            std::process::exit(2);
        }
    }
}
