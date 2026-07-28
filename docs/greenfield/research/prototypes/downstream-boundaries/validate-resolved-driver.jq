def closed($allowed):
  (type == "object") and ((keys | sort) == ($allowed | sort));

def digest:
  type == "string" and test("^[0-9a-f]{64}$");

def positive_integer:
  type == "number" and floor == . and . > 0;

if (closed([
  "backendDefaults",
  "devices",
  "identity",
  "identitySecurity",
  "network",
  "output",
  "profile",
  "protocolVersions",
  "resolvedVersion",
  "resources",
  "retainedSource",
  "secrets",
  "snapshots",
  "workspace"
]) | not) then
  error("DRV-004: driver accepts only the exact total product-generated configuration")
elif (.identity | closed([
       "admissionDecisionId",
       "artifactSemanticDigest",
       "createRequestDigest",
       "memberContentDigest",
       "preparedSemanticIdentity"
     ]) | not) or
     (.profile | closed(["id", "targetId"]) | not) or
     (.retainedSource | closed([
       "acquisitionKind",
       "workspaceDescriptorDigest"
     ]) | not) or
     (.workspace | closed([
       "access",
       "destination",
       "materialization"
     ]) | not) or
     (.network | closed(["egressAllow", "mode", "ports"]) | not) or
     (.resources | closed(["cpuMillis", "diskBytes", "memoryBytes"]) | not) or
     (.identitySecurity | closed([
       "capabilities",
       "gid",
       "noNewPrivileges",
       "uid"
     ]) | not) or
     (.devices | closed(["allowed"]) | not) or
     (.secrets | closed(["bindings"]) | not) or
     (.snapshots | closed(["mode", "source"]) | not) or
     (.output | closed(["capture", "maxBytes"]) | not) or
     (.protocolVersions | closed([
       "driver",
       "generatedConfiguration",
       "guest",
       "resolvedReentry"
     ]) | not) or
     (.backendDefaults | closed([
       "devices",
       "environment",
       "hostname",
       "networkNamespace",
       "output",
       "resourceLimits",
       "rootFilesystem",
       "secrets",
       "security",
       "snapshots",
       "workingDirectory"
     ]) | not)
then
  error("DRV-004: generated configuration contains a foreign, raw, unknown, or omitted field")
elif .resolvedVersion != 1 then
  error("DRV-001: unsupported resolved-driver schema version")
elif (.identity.preparedSemanticIdentity | digest | not)
then
  error("DRV-001: prepared semantic identity violates DRV-003 private identity chain")
elif (.identity.artifactSemanticDigest | digest | not) or
     (.identity.memberContentDigest | digest | not) or
     (.identity.createRequestDigest | digest | not)
then
  error("DRV-001: generated driver identity fields are malformed")
elif .identity.artifactSemanticDigest != $expectedArtifactSemanticDigest or
     .identity.memberContentDigest != $expectedMemberContentDigest or
     .identity.createRequestDigest != $expectedCreateRequestDigest or
     .identity.admissionDecisionId != $expectedAdmissionDecisionId
then
  error("DRV-001: generated driver identity differs from the admitted creation")
elif .identity.preparedSemanticIdentity != $expectedPreparedSemanticIdentity
then
  error("DRV-001: prepared semantic identity violates DRV-003 private identity chain")
elif .profile.id != $expectedProfileId or
     .profile.targetId != $expectedTargetId
then
  error("DRV-001: generated profile identity differs from the admitted member")
elif (.retainedSource.workspaceDescriptorDigest | digest | not) or
     .retainedSource.workspaceDescriptorDigest != $expectedSourceDescriptorDigest or
     .retainedSource.acquisitionKind != "live-file-handle"
then
  error("DRV-001: generated retained-source identity differs from current H0 acquisition")
elif (.workspace.destination | type != "string") or
     (.workspace.destination | startswith("/") | not) or
     .workspace.access != "readWrite" or
     .workspace.materialization != "retained"
then
  error("DRV-001: generated workspace exceeds the admitted Artifact/Create contract")
elif .network.mode != "disabled" or
     .network.egressAllow != [] or
     .network.ports != []
then
  error("DRV-001: generated network configuration widens the admitted contract")
elif (.resources.cpuMillis | positive_integer | not) or
     (.resources.memoryBytes | positive_integer | not) or
     (.resources.diskBytes | positive_integer | not)
then
  error("DRV-001: generated resource configuration is incomplete or invalid")
elif (.identitySecurity.uid | type != "number") or
     (.identitySecurity.uid | floor != .) or
     (.identitySecurity.uid < 0) or
     (.identitySecurity.gid | type != "number") or
     (.identitySecurity.gid | floor != .) or
     (.identitySecurity.gid < 0) or
     .identitySecurity.noNewPrivileges != true or
     .identitySecurity.capabilities != []
then
  error("DRV-001: generated identity/security configuration weakens the admitted contract")
elif .devices.allowed != [] or
     .secrets.bindings != []
then
  error("DRV-001: generated devices or secrets violate explicit valid absence")
elif .snapshots.mode != "disabled" or
     .snapshots.source != null
then
  error("DRV-001: generated snapshot configuration violates explicit valid absence")
elif .output.capture != "structured" or
     (.output.maxBytes | positive_integer | not)
then
  error("DRV-001: generated output configuration is incomplete or invalid")
elif .protocolVersions.resolvedReentry != "resolved-reentry-v1" or
     .protocolVersions.generatedConfiguration != "generated-runtime-config-v1" or
     .protocolVersions.driver != $expectedDriverProtocolVersion or
     .protocolVersions.guest != $expectedGuestProtocolVersion
then
  error("DRV-001: generated protocol identity differs from the admitted profile")
elif ([.backendDefaults[]] |
      all(. == "suppressed-explicit") | not)
then
  error("DRV-004: backend behavior would depend on an implicit default")
elif ($expectedGeneratedConfiguration | type) != "array" or
     ($expectedGeneratedConfiguration | length) != 1
then
  error("DRV-004: product-owned expected generated configuration is unavailable")
elif . != $expectedGeneratedConfiguration[0]
then
  error("DRV-001: generated configuration differs from the admitted complete product-owned projection")
else .
end
