use serde::de::{DeserializeSeed, Error as DeError, MapAccess, SeqAccess, Visitor};
use serde::{Deserialize, Serialize};
use serde_json::{json, Value};
use sha2::{Digest, Sha256};
use std::collections::{BTreeMap, BTreeSet};
use std::fmt;
use std::fs::File;
use std::io::{Read, Seek, SeekFrom};
use std::path::{Path, PathBuf};
use std::sync::atomic::{AtomicUsize, Ordering};

const MAX_ENVELOPE_BYTES: usize = 65_536;
const MAX_ENVELOPE_DEPTH: usize = 32;
const DUPLICATE_MARKER: &str = "__REENTRY_DUPLICATE__:";
const DEPTH_MARKER: &str = "__REENTRY_DEPTH__:";

pub const BUILT_MEMBER_LOAD_INVARIANT_IDS: [&str; 89] = [
    "CAP-001", "CMP-002", "CMP-003", "CMP-004", "CMP-005", "CMP-006", "CMP-007", "CMP-008",
    "CRT-001", "CRT-003", "DEV-001", "DEV-002", "DRV-001", "EXE-007", "HOST-004", "HOST-005",
    "IDN-001", "IDT-001", "IDT-002", "LIF-001", "LIVE-002", "LIVE-003", "LIVE-004", "MAN-001",
    "MAN-002", "MAN-004", "MAN-005", "MAN-006", "NAT-001", "NAT-002", "NET-001", "NET-002",
    "OUT-001", "OUT-002", "PLT-001", "RES-001", "RES-002", "SCT-001", "SCT-002", "SCT-003",
    "SEC-001", "SEC-002", "SNP-001", "SNP-002", "STR-001", "STR-002", "STR-003", "STR-004",
    "STR-005", "STR-006", "STR-008", "STR-009", "STR-010", "STR-011", "SUM-001", "SUM-002",
    "SUM-003", "SUM-004", "SUM-005", "SUM-006", "SUM-007", "SUM-008", "SUM-009", "SUM-010",
    "TGT-001", "TGT-002", "TGT-003", "TGT-004", "TGT-005", "TGT-006", "TGT-007", "TGT-008",
    "TGT-009", "TGT-010", "WIRE-002", "XRS-003", "XRS-004", "XRS-009", "XRS-010", "XRS-011",
    "XRS-012", "XRS-013", "XRS-014", "XRS-015", "XRS-016", "XRS-017", "XRS-018", "XRS-019",
    "XRS-020",
];

pub const RESOLVED_STAGE_INVARIANT_IDS: [&str; 30] = [
    "XRS-001", "XRS-002", "TGT-002", "TGT-003", "CRT-001", "CRT-002", "CRT-003", "CRT-004",
    "CRT-005", "CRT-006", "IDT-002", "MAN-001", "MAN-002", "MAN-003", "MAN-004", "MAN-005",
    "MAN-006", "XRS-006", "OPS-001", "OPS-002", "HOST-001", "HOST-002", "HOST-003", "HOST-004",
    "PRV-001", "XRS-003", "XRS-004", "HOST-005", "WIRE-004", "DRV-001",
];

static EXTERNAL_MUTATION_COUNT: AtomicUsize = AtomicUsize::new(0);

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct Diagnostic {
    invariant: &'static str,
    category: &'static str,
    owner: &'static str,
    phase: &'static str,
    primary_path: &'static str,
    related_paths: Vec<&'static str>,
    constraint: &'static str,
    message: &'static str,
    remediation: &'static str,
    actual_values: Value,
}

impl Diagnostic {
    fn wire(category: &'static str, message: &'static str, actual_values: Value) -> Self {
        Self {
            invariant: "WIRE-007",
            category,
            owner: "runtime",
            phase: "RW0",
            primary_path: "resolvedReentry.envelope",
            related_paths: vec!["resolvedReentry.version"],
            constraint: "closed, duplicate-free, bounded resolved-reentry-v1 envelope",
            message,
            remediation: "Send the exact supported envelope and retry full semantic replay.",
            actual_values,
        }
    }

    fn driver(category: &'static str, message: &'static str, actual_values: Value) -> Self {
        Self {
            invariant: "DRV-001",
            category,
            owner: "runtime",
            phase: "C0",
            primary_path: "resolvedReentry.candidate",
            related_paths: vec!["preparedLaunch.identity"],
            constraint: "candidate must equal current product-owned semantic authority",
            message,
            remediation: "Rebuild the candidate from current Artifact, Create, admission, and source identities.",
            actual_values,
        }
    }

    fn handle(category: &'static str, message: &'static str) -> Self {
        Self {
            invariant: "HOST-005",
            category,
            owner: "runtime",
            phase: "H0",
            primary_path: "retainedSourceReferences.workspace",
            related_paths: vec!["preparedLaunch.retainedWorkspace"],
            constraint: "current H0 acquisition must produce a live owned handle",
            message,
            remediation:
                "Reacquire the retained source through the current product-owned acquisition path.",
            actual_values: json!({"status": "rejected"}),
        }
    }

    pub fn invariant(&self) -> &str {
        self.invariant
    }

    pub fn prototype_cli() -> Self {
        Self {
            invariant: "DRV-001",
            category: "driver.cli-contract",
            owner: "runtime",
            phase: "D0",
            primary_path: "resolvedReentry.cli",
            related_paths: Vec::new(),
            constraint: "prototype CLI command must be valid",
            message: "prototype CLI contract rejected the operation",
            remediation: "Use a documented prototype command.",
            actual_values: json!({"status": "rejected"}),
        }
    }

    pub fn prototype_io() -> Self {
        Self::wire(
            "wire.input-io",
            "resolved-reentry input could not be read",
            json!({"status": "rejected"}),
        )
    }
}

impl fmt::Display for Diagnostic {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(formatter, "{}: {}", self.invariant, self.message)
    }
}

impl std::error::Error for Diagnostic {}

#[derive(Debug)]
enum StrictNode {
    Null,
    Bool(bool),
    Number(serde_json::Number),
    String(String),
    Array(Vec<StrictNode>),
    Object(BTreeMap<String, StrictNode>),
}

impl StrictNode {
    fn into_value(self) -> Value {
        match self {
            Self::Null => Value::Null,
            Self::Bool(value) => Value::Bool(value),
            Self::Number(value) => Value::Number(value),
            Self::String(value) => Value::String(value),
            Self::Array(values) => {
                Value::Array(values.into_iter().map(StrictNode::into_value).collect())
            }
            Self::Object(values) => Value::Object(
                values
                    .into_iter()
                    .map(|(key, value)| (key, value.into_value()))
                    .collect(),
            ),
        }
    }
}

struct StrictSeed {
    depth: usize,
    path: String,
}

impl<'de> DeserializeSeed<'de> for StrictSeed {
    type Value = StrictNode;

    fn deserialize<D>(self, deserializer: D) -> Result<Self::Value, D::Error>
    where
        D: serde::Deserializer<'de>,
    {
        deserializer.deserialize_any(StrictVisitor {
            depth: self.depth,
            path: self.path,
        })
    }
}

struct StrictVisitor {
    depth: usize,
    path: String,
}

impl<'de> Visitor<'de> for StrictVisitor {
    type Value = StrictNode;

    fn expecting(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        formatter.write_str("a JSON value")
    }

    fn visit_bool<E>(self, value: bool) -> Result<Self::Value, E> {
        Ok(StrictNode::Bool(value))
    }

    fn visit_i64<E>(self, value: i64) -> Result<Self::Value, E> {
        Ok(StrictNode::Number(value.into()))
    }

    fn visit_u64<E>(self, value: u64) -> Result<Self::Value, E> {
        Ok(StrictNode::Number(value.into()))
    }

    fn visit_f64<E>(self, value: f64) -> Result<Self::Value, E>
    where
        E: DeError,
    {
        serde_json::Number::from_f64(value)
            .map(StrictNode::Number)
            .ok_or_else(|| E::custom("non-finite JSON number"))
    }

    fn visit_str<E>(self, value: &str) -> Result<Self::Value, E> {
        Ok(StrictNode::String(value.to_owned()))
    }

    fn visit_string<E>(self, value: String) -> Result<Self::Value, E> {
        Ok(StrictNode::String(value))
    }

    fn visit_none<E>(self) -> Result<Self::Value, E> {
        Ok(StrictNode::Null)
    }

    fn visit_unit<E>(self) -> Result<Self::Value, E> {
        Ok(StrictNode::Null)
    }

    fn visit_seq<A>(self, mut sequence: A) -> Result<Self::Value, A::Error>
    where
        A: SeqAccess<'de>,
    {
        if self.depth >= MAX_ENVELOPE_DEPTH {
            return Err(A::Error::custom(format!("{DEPTH_MARKER}{}", self.path)));
        }
        let mut values = Vec::new();
        while let Some(value) = sequence.next_element_seed(StrictSeed {
            depth: self.depth + 1,
            path: format!("{}[{}]", self.path, values.len()),
        })? {
            values.push(value);
        }
        Ok(StrictNode::Array(values))
    }

    fn visit_map<A>(self, mut map: A) -> Result<Self::Value, A::Error>
    where
        A: MapAccess<'de>,
    {
        if self.depth >= MAX_ENVELOPE_DEPTH {
            return Err(A::Error::custom(format!("{DEPTH_MARKER}{}", self.path)));
        }
        let mut values = BTreeMap::new();
        while let Some(key) = map.next_key::<String>()? {
            let path = format!("{}.{}", self.path, key);
            if values.contains_key(&key) {
                return Err(A::Error::custom(format!("{DUPLICATE_MARKER}{path}")));
            }
            let value = map.next_value_seed(StrictSeed {
                depth: self.depth + 1,
                path,
            })?;
            values.insert(key, value);
        }
        Ok(StrictNode::Object(values))
    }
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct ResolvedReentryEnvelope {
    schema_version: u32,
    artifact: ArtifactCandidate,
    create: CreateCandidate,
    admission_context: AdmissionContextCandidate,
    retained_source_references: RetainedSourceReferences,
    integrity: IntegrityContext,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
struct ArtifactCandidate {
    semantic_digest: String,
    member_content_digest: String,
    runtime_profile_id: String,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
struct CreateCandidate {
    request_digest: String,
    idempotency_scope: String,
    workspace_destination: String,
    workspace_access: String,
    network_mode: String,
    egress_allow: Vec<String>,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
struct AdmissionContextCandidate {
    decision_id: String,
    policy_digest: String,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
struct RetainedSourceReferences {
    workspace: SerializedWorkspaceReference,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
struct SerializedWorkspaceReference {
    descriptor_digest: String,
    #[serde(rename = "pathHint")]
    _path_hint: String,
    #[serde(rename = "serializedToken")]
    _serialized_token: String,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
struct IntegrityContext {
    principal: String,
    authenticated_context_digest: String,
}

#[derive(Debug)]
pub struct DecodedResolvedCandidate {
    envelope: ResolvedReentryEnvelope,
}

pub fn decode_reentry(bytes: &[u8]) -> Result<DecodedResolvedCandidate, Diagnostic> {
    if bytes.len() > MAX_ENVELOPE_BYTES {
        return Err(Diagnostic::wire(
            "wire.input-too-large",
            "resolved-reentry input exceeds the byte limit",
            json!({
                "limitBytes": MAX_ENVELOPE_BYTES,
                "observedBytes": bytes.len()
            }),
        ));
    }
    let mut deserializer = serde_json::Deserializer::from_slice(bytes);
    let node = StrictSeed {
        depth: 0,
        path: "resolvedReentry".to_owned(),
    }
    .deserialize(&mut deserializer)
    .map_err(|error| strict_decode_diagnostic(&error))?;
    deserializer.end().map_err(|_| {
        Diagnostic::wire(
            "wire.trailing-input",
            "resolved-reentry input contains trailing data",
            json!({"status": "rejected"}),
        )
    })?;
    let envelope: ResolvedReentryEnvelope =
        serde_json::from_value(node.into_value()).map_err(|_| {
            Diagnostic::wire(
                "wire.closed-schema",
                "resolved-reentry input does not match the closed schema",
                json!({"status": "rejected"}),
            )
        })?;
    if envelope.schema_version != 1 {
        return Err(Diagnostic::wire(
            "wire.unsupported-version",
            "unsupported resolved-reentry schema version",
            json!({"status": "rejected"}),
        ));
    }
    validate_integrity_shape(&envelope.integrity)?;
    Ok(DecodedResolvedCandidate { envelope })
}

fn strict_decode_diagnostic(error: &serde_json::Error) -> Diagnostic {
    let parser_message = error.to_string();
    if parser_message.contains(DUPLICATE_MARKER) {
        Diagnostic::wire(
            "wire.duplicate-key",
            "resolved-reentry input contains a duplicate object key",
            json!({"status": "rejected"}),
        )
    } else if parser_message.contains(DEPTH_MARKER) {
        Diagnostic::wire(
            "wire.depth-limit",
            "resolved-reentry input exceeds the nesting-depth limit",
            json!({"limitDepth": MAX_ENVELOPE_DEPTH}),
        )
    } else {
        Diagnostic::wire(
            "wire.invalid-json",
            "resolved-reentry input is not valid supported JSON",
            json!({"status": "rejected"}),
        )
    }
}

fn validate_integrity_shape(integrity: &IntegrityContext) -> Result<(), Diagnostic> {
    if integrity.principal.is_empty() || !is_digest(&integrity.authenticated_context_digest) {
        return Err(Diagnostic::wire(
            "wire.integrity-shape",
            "authenticated context identity is absent or malformed",
            json!({"status": "rejected"}),
        ));
    }
    Ok(())
}

fn is_digest(value: &str) -> bool {
    value.len() == 64 && value.bytes().all(|byte| byte.is_ascii_hexdigit())
}

#[derive(Debug)]
pub struct ReplayAuthority {
    built_member_load: Vec<String>,
    resolved_stage: Vec<String>,
}

pub fn load_reviewed_replay_sets(bytes: &[u8]) -> Result<ReplayAuthority, Diagnostic> {
    let document: Value = serde_json::from_slice(bytes).map_err(|_| {
        Diagnostic::driver(
            "replay.invalid-json",
            "reviewed replay catalog is not valid JSON",
            json!({"status": "rejected"}),
        )
    })?;
    let replay = document
        .get("serializedResolvedReentryReplaySets")
        .and_then(Value::as_object)
        .ok_or_else(|| {
            Diagnostic::driver(
                "replay.missing-sets",
                "reviewed replay catalog omits the required replay sets",
                json!({"status": "rejected"}),
            )
        })?;
    let built = read_id_array(replay.get("builtMemberLoadInvariantIds"))?;
    let resolved = read_id_array(replay.get("resolvedStageInvariantIds"))?;
    validate_exact_ids(&built, &BUILT_MEMBER_LOAD_INVARIANT_IDS)?;
    validate_exact_ids(&resolved, &RESOLVED_STAGE_INVARIANT_IDS)?;
    Ok(ReplayAuthority {
        built_member_load: built,
        resolved_stage: resolved,
    })
}

fn read_id_array(value: Option<&Value>) -> Result<Vec<String>, Diagnostic> {
    value
        .and_then(Value::as_array)
        .ok_or_else(|| {
            Diagnostic::driver(
                "replay.invalid-set-shape",
                "a reviewed replay set is not an array",
                json!({"status": "rejected"}),
            )
        })?
        .iter()
        .enumerate()
        .map(|(index, value)| {
            value.as_str().map(ToOwned::to_owned).ok_or_else(|| {
                Diagnostic::driver(
                    "replay.invalid-id-type",
                    "a reviewed replay ID is not a string",
                    json!({"index": index}),
                )
            })
        })
        .collect()
}

fn validate_exact_ids(actual: &[String], expected: &[&str]) -> Result<(), Diagnostic> {
    let actual_set: BTreeSet<&str> = actual.iter().map(String::as_str).collect();
    let expected_set: BTreeSet<&str> = expected.iter().copied().collect();
    if actual_set.len() != actual.len() {
        return Err(Diagnostic::driver(
            "replay.duplicate-id",
            "a reviewed replay set contains a duplicate ID",
            json!({
                "actualCount": actual.len(),
                "uniqueCount": actual_set.len()
            }),
        ));
    }
    if actual_set != expected_set {
        return Err(Diagnostic::driver(
            "replay.set-membership",
            "a reviewed replay set has missing or extra IDs",
            json!({
                "actualCount": actual.len(),
                "expectedCount": expected.len(),
                "extraCount": actual_set.difference(&expected_set).count(),
                "missingCount": expected_set.difference(&actual_set).count()
            }),
        ));
    }
    if let Some(index) = actual
        .iter()
        .map(String::as_str)
        .zip(expected.iter().copied())
        .position(|(actual_id, expected_id)| actual_id != expected_id)
    {
        return Err(Diagnostic::driver(
            "replay.order",
            "a reviewed replay set order differs from the authority",
            json!({"firstDifferentIndex": index}),
        ));
    }
    Ok(())
}

impl ReplayAuthority {
    pub fn built_count(&self) -> usize {
        self.built_member_load.len()
    }

    pub fn resolved_count(&self) -> usize {
        self.resolved_stage.len()
    }
}

#[derive(Debug)]
pub struct CurrentAdmission {
    artifact_semantic_digest: String,
    member_content_digest: String,
    runtime_profile_id: String,
    create_request_digest: String,
    admission_decision_id: String,
    admission_policy_digest: String,
    source_descriptor_digest: String,
}

impl CurrentAdmission {
    pub fn for_witness(profile: impl Into<String>, decision: impl Into<String>) -> Self {
        Self {
            artifact_semantic_digest: "a".repeat(64),
            member_content_digest: "b".repeat(64),
            runtime_profile_id: profile.into(),
            create_request_digest: "c".repeat(64),
            admission_decision_id: decision.into(),
            admission_policy_digest: "d".repeat(64),
            source_descriptor_digest: "e".repeat(64),
        }
    }
}

#[derive(Debug)]
pub struct AcquisitionInputs {
    retained_workspace_path: PathBuf,
}

impl AcquisitionInputs {
    pub fn new(path: impl AsRef<Path>) -> Self {
        Self {
            retained_workspace_path: path.as_ref().to_owned(),
        }
    }
}

struct ResolvedCreation {
    semantic_identity: String,
    generated: GeneratedRuntimeConfiguration,
}

struct AdmittedCreation {
    semantic_identity: String,
    generated: GeneratedRuntimeConfiguration,
}

pub struct PreparedLaunch {
    semantic_identity: String,
    generated: GeneratedRuntimeConfiguration,
    retained_workspace: File,
}

pub fn revalidate_reentry(
    candidate: DecodedResolvedCandidate,
    current: &CurrentAdmission,
    acquisition: &AcquisitionInputs,
    replay: &ReplayAuthority,
) -> Result<PreparedLaunch, Diagnostic> {
    if replay.built_count() != 89 || replay.resolved_count() != 30 {
        return Err(Diagnostic::driver(
            "driver.incomplete-replay",
            "complete 89+30 semantic replay authority is required",
            json!({
                "builtCount": replay.built_count(),
                "resolvedCount": replay.resolved_count()
            }),
        ));
    }
    let envelope = candidate.envelope;
    let artifact = &envelope.artifact;
    let create = &envelope.create;
    let admission = &envelope.admission_context;
    let workspace_reference = &envelope.retained_source_references.workspace;

    let all_digests = [
        &artifact.semantic_digest,
        &artifact.member_content_digest,
        &create.request_digest,
        &admission.policy_digest,
        &workspace_reference.descriptor_digest,
    ];
    if all_digests.into_iter().any(|value| !is_digest(value)) {
        return Err(Diagnostic::driver(
            "driver.malformed-identity",
            "candidate contains a malformed semantic identity digest",
            json!({"status": "rejected"}),
        ));
    }
    if artifact.semantic_digest != current.artifact_semantic_digest
        || artifact.member_content_digest != current.member_content_digest
        || artifact.runtime_profile_id != current.runtime_profile_id
        || create.request_digest != current.create_request_digest
        || admission.decision_id != current.admission_decision_id
        || admission.policy_digest != current.admission_policy_digest
        || workspace_reference.descriptor_digest != current.source_descriptor_digest
    {
        return Err(Diagnostic::driver(
            "driver.semantic-mismatch",
            "authenticated bytes differ from current semantic authority",
            json!({"status": "rejected"}),
        ));
    }
    if create.idempotency_scope != "sandbox-create-v1"
        || create.workspace_destination != "/workspace"
        || create.workspace_access != "readWrite"
        || create.network_mode != "disabled"
        || !create.egress_allow.is_empty()
    {
        return Err(Diagnostic::driver(
            "driver.create-contract",
            "Create candidate violates the admitted closed witness contract",
            json!({"status": "rejected"}),
        ));
    }
    let profile = profile_contract(&artifact.runtime_profile_id)?;

    let semantic_identity = digest_join(&[
        &artifact.semantic_digest,
        &artifact.member_content_digest,
        &artifact.runtime_profile_id,
        &create.request_digest,
        &create.idempotency_scope,
        &admission.decision_id,
        &admission.policy_digest,
        &workspace_reference.descriptor_digest,
        profile.target_id,
        profile.driver_protocol,
        profile.guest_protocol,
    ]);
    let generated = generated_configuration(&envelope, profile, semantic_identity.clone());
    let resolved = ResolvedCreation {
        semantic_identity,
        generated,
    };
    let admitted = AdmittedCreation {
        semantic_identity: resolved.semantic_identity,
        generated: resolved.generated,
    };

    // Serialized path hints and tokens are deliberately never consulted.
    let retained_workspace = File::open(&acquisition.retained_workspace_path).map_err(|_| {
        Diagnostic::handle(
            "handle.acquisition",
            "current retained-source acquisition failed",
        )
    })?;
    Ok(PreparedLaunch {
        semantic_identity: admitted.semantic_identity,
        generated: admitted.generated,
        retained_workspace,
    })
}

fn digest_join(values: &[&str]) -> String {
    let mut hasher = Sha256::new();
    for value in values {
        hasher.update((value.len() as u64).to_be_bytes());
        hasher.update(value.as_bytes());
    }
    format!("{:x}", hasher.finalize())
}

struct ProfileContract {
    target_id: &'static str,
    driver_protocol: &'static str,
    guest_protocol: &'static str,
}

fn profile_contract(profile: &str) -> Result<ProfileContract, Diagnostic> {
    match profile {
        "bubblewrap-linux-v1" => Ok(ProfileContract {
            target_id: "bubblewrap",
            driver_protocol: "bubblewrap-driver-v1",
            guest_protocol: "none-v1",
        }),
        "microvm-firecracker-linux-v1" => Ok(ProfileContract {
            target_id: "firecracker",
            driver_protocol: "firecracker-driver-v1",
            guest_protocol: "sandbox-agent-v1",
        }),
        "microvm-cloud-hypervisor-linux-v1" => Ok(ProfileContract {
            target_id: "cloud-hypervisor",
            driver_protocol: "cloud-hypervisor-driver-v1",
            guest_protocol: "sandbox-agent-v1",
        }),
        "oci-linux-v1" => Ok(ProfileContract {
            target_id: "oci",
            driver_protocol: "oci-driver-v1",
            guest_protocol: "oci-runtime-v1",
        }),
        _ => Err(Diagnostic::driver(
            "driver.unsupported-profile",
            "runtime profile has no reviewed driver projection",
            json!({"status": "rejected"}),
        )),
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct GeneratedRuntimeConfiguration {
    resolved_version: u32,
    identity: GeneratedIdentity,
    profile: GeneratedProfile,
    retained_source: GeneratedRetainedSource,
    workspace: GeneratedWorkspace,
    network: GeneratedNetwork,
    resources: GeneratedResources,
    identity_security: GeneratedIdentitySecurity,
    devices: GeneratedDevices,
    secrets: GeneratedSecrets,
    snapshots: GeneratedSnapshots,
    output: GeneratedOutput,
    protocol_versions: GeneratedProtocolVersions,
    backend_defaults: BackendDefaultSuppression,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
#[serde(rename_all = "camelCase")]
struct GeneratedIdentity {
    artifact_semantic_digest: String,
    member_content_digest: String,
    create_request_digest: String,
    admission_decision_id: String,
    prepared_semantic_identity: String,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
#[serde(rename_all = "camelCase")]
struct GeneratedProfile {
    id: String,
    target_id: String,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
#[serde(rename_all = "camelCase")]
struct GeneratedRetainedSource {
    workspace_descriptor_digest: String,
    acquisition_kind: &'static str,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
#[serde(rename_all = "camelCase")]
struct GeneratedWorkspace {
    destination: String,
    access: String,
    materialization: &'static str,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
#[serde(rename_all = "camelCase")]
struct GeneratedNetwork {
    mode: String,
    egress_allow: Vec<String>,
    ports: Vec<String>,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
#[serde(rename_all = "camelCase")]
struct GeneratedResources {
    cpu_millis: u64,
    memory_bytes: u64,
    disk_bytes: u64,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
#[serde(rename_all = "camelCase")]
struct GeneratedIdentitySecurity {
    uid: u32,
    gid: u32,
    no_new_privileges: bool,
    capabilities: Vec<String>,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
struct GeneratedDevices {
    allowed: Vec<String>,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
struct GeneratedSecrets {
    bindings: Vec<String>,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
struct GeneratedSnapshots {
    mode: &'static str,
    source: Option<String>,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
#[serde(rename_all = "camelCase")]
struct GeneratedOutput {
    capture: &'static str,
    max_bytes: u64,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
#[serde(rename_all = "camelCase")]
struct GeneratedProtocolVersions {
    resolved_reentry: &'static str,
    driver: &'static str,
    generated_configuration: &'static str,
    guest: &'static str,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
#[serde(rename_all = "camelCase")]
struct BackendDefaultSuppression {
    root_filesystem: &'static str,
    network_namespace: &'static str,
    hostname: &'static str,
    environment: &'static str,
    working_directory: &'static str,
    resource_limits: &'static str,
    security: &'static str,
    devices: &'static str,
    secrets: &'static str,
    snapshots: &'static str,
    output: &'static str,
}

fn generated_configuration(
    envelope: &ResolvedReentryEnvelope,
    profile: ProfileContract,
    semantic_identity: String,
) -> GeneratedRuntimeConfiguration {
    GeneratedRuntimeConfiguration {
        resolved_version: 1,
        identity: GeneratedIdentity {
            artifact_semantic_digest: envelope.artifact.semantic_digest.clone(),
            member_content_digest: envelope.artifact.member_content_digest.clone(),
            create_request_digest: envelope.create.request_digest.clone(),
            admission_decision_id: envelope.admission_context.decision_id.clone(),
            prepared_semantic_identity: semantic_identity,
        },
        profile: GeneratedProfile {
            id: envelope.artifact.runtime_profile_id.clone(),
            target_id: profile.target_id.to_owned(),
        },
        retained_source: GeneratedRetainedSource {
            workspace_descriptor_digest: envelope
                .retained_source_references
                .workspace
                .descriptor_digest
                .clone(),
            acquisition_kind: "live-file-handle",
        },
        workspace: GeneratedWorkspace {
            destination: envelope.create.workspace_destination.clone(),
            access: envelope.create.workspace_access.clone(),
            materialization: "retained",
        },
        network: GeneratedNetwork {
            mode: envelope.create.network_mode.clone(),
            egress_allow: envelope.create.egress_allow.clone(),
            ports: Vec::new(),
        },
        resources: GeneratedResources {
            cpu_millis: 1000,
            memory_bytes: 536_870_912,
            disk_bytes: 2_147_483_648,
        },
        identity_security: GeneratedIdentitySecurity {
            uid: 1000,
            gid: 1000,
            no_new_privileges: true,
            capabilities: Vec::new(),
        },
        devices: GeneratedDevices {
            allowed: Vec::new(),
        },
        secrets: GeneratedSecrets {
            bindings: Vec::new(),
        },
        snapshots: GeneratedSnapshots {
            mode: "disabled",
            source: None,
        },
        output: GeneratedOutput {
            capture: "structured",
            max_bytes: 1_048_576,
        },
        protocol_versions: GeneratedProtocolVersions {
            resolved_reentry: "resolved-reentry-v1",
            driver: profile.driver_protocol,
            generated_configuration: "generated-runtime-config-v1",
            guest: profile.guest_protocol,
        },
        backend_defaults: BackendDefaultSuppression {
            root_filesystem: "suppressed-explicit",
            network_namespace: "suppressed-explicit",
            hostname: "suppressed-explicit",
            environment: "suppressed-explicit",
            working_directory: "suppressed-explicit",
            resource_limits: "suppressed-explicit",
            security: "suppressed-explicit",
            devices: "suppressed-explicit",
            secrets: "suppressed-explicit",
            snapshots: "suppressed-explicit",
            output: "suppressed-explicit",
        },
    }
}

impl PreparedLaunch {
    pub fn semantic_identity(&self) -> &str {
        &self.semantic_identity
    }

    pub fn generated_configuration(&self) -> &GeneratedRuntimeConfiguration {
        &self.generated
    }

    #[cfg(unix)]
    pub fn live_handle_id(&self) -> i64 {
        use std::os::fd::AsRawFd;
        i64::from(self.retained_workspace.as_raw_fd())
    }

    pub fn read_retained_source(&mut self) -> Result<String, std::io::Error> {
        self.retained_workspace.seek(SeekFrom::Start(0))?;
        let mut value = String::new();
        self.retained_workspace.read_to_string(&mut value)?;
        Ok(value)
    }
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct DriverReceipt {
    prepared_semantic_identity: String,
    mutation_sequence: usize,
}

pub fn invoke_driver(prepared: PreparedLaunch) -> Result<DriverReceipt, Diagnostic> {
    prepared.retained_workspace.metadata().map_err(|_| {
        Diagnostic::handle(
            "handle.not-live",
            "retained source handle is not live at driver entry",
        )
    })?;
    let mutation_sequence = EXTERNAL_MUTATION_COUNT.fetch_add(1, Ordering::SeqCst) + 1;
    Ok(DriverReceipt {
        prepared_semantic_identity: prepared.semantic_identity,
        mutation_sequence,
    })
}

pub fn external_mutation_count() -> usize {
    EXTERNAL_MUTATION_COUNT.load(Ordering::SeqCst)
}
