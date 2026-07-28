def closed($allowed):
  (type == "object") and ((keys | sort) == ($allowed | sort));

def digest:
  type == "string" and test("^[0-9a-f]{64}$");

if type != "object" then
  error("MAN-005: built manifest must be a closed product object")
elif has("builderEvidence") | not then
  error("TGT-003: built manifest lacks member-bound builder evidence")
elif has("providerObjectId") or has("providerCredential") or has("secretValue") then
  error("MAN-003: provider, credential, and secret values are forbidden in built manifests")
elif (closed([
       "artifactSemanticDigest",
       "builderEvidence",
       "memberContentDigest",
       "portableProjectionDigest",
       "protocols",
       "runtimeProfileIds",
       "schemaVersion",
       "targetId"
     ]) | not)
then
  error("MAN-005: built manifest must use the exact complete product schema")
elif .schemaVersion != 1 then
  error("STR-007: unsupported built-manifest envelope version")
elif (.protocols | closed([
       "driver",
       "evidence",
       "guest",
       "targetManifest"
     ]) | not) or
     .protocols != {
       targetManifest: "target-manifest-v1",
       driver: "bubblewrap-driver-v1",
       guest: "none-v1",
       evidence: "builder-evidence-v1"
     }
then
  error("MAN-002: built manifest names an unregistered target, driver, guest, or evidence protocol")
elif (.artifactSemanticDigest | digest | not) or
     (.memberContentDigest | digest | not) or
     (.portableProjectionDigest | digest | not)
then
  error("IDT-002: built manifest identity domains require typed SHA-256 values")
elif .artifactSemanticDigest != $expectedArtifactSemanticDigest or
     .memberContentDigest != $expectedMemberContentDigest
then
  error("MAN-001: built manifest content identity does not match the requested Artifact member")
elif .portableProjectionDigest != $expectedPortableProjectionDigest then
  error("MAN-005: built manifest portable projection does not match the reviewed lowering")
elif .targetId != $expectedTargetId or
     .runtimeProfileIds != [$expectedRuntimeProfileId]
then
  error("MAN-006: built manifest target/runtime-profile set does not match one compatible member")
elif (.builderEvidence | closed([
       "artifactSemanticDigest",
       "evidenceDigest",
       "memberContentDigest",
       "protocolVersion",
       "runtimeProfileId"
     ]) | not)
then
  error("TGT-003: builder evidence must use the exact member-binding schema")
elif (.builderEvidence.evidenceDigest | digest | not) or
     .builderEvidence.evidenceDigest != $expectedBuilderEvidenceDigest or
     .builderEvidence.artifactSemanticDigest != .artifactSemanticDigest or
     .builderEvidence.memberContentDigest != .memberContentDigest or
     .builderEvidence.runtimeProfileId != .runtimeProfileIds[0] or
     .builderEvidence.protocolVersion != .protocols.evidence
then
  error("TGT-003: builder evidence is missing, unverified, or bound to another member")
else .
end
