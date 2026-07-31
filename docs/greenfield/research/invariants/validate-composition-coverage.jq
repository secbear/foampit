def locked_path_ids:
  [
    "artifact-ordinary-authoring",
    "artifact-imports",
    "artifact-import-order",
    "artifact-profile-expansion",
    "artifact-explicit-override",
    "artifact-semantic-refinement",
    "artifact-strongest-override",
    "artifact-native-language-escape",
    "operator-configuration-authoring",
    "operator-configuration-imports",
    "operator-configuration-precedence",
    "operator-configuration-refinement",
    "operator-configuration-native-escape",
    "managed-service-definition-authoring",
    "managed-service-definition-imports",
    "managed-service-definition-precedence",
    "managed-service-definition-refinement",
    "managed-service-definition-native-escape",
    "resolved-driver-handoff",
    "serialized-resolved-reentry",
    "generated-runtime-configuration",
    "direct-driver-invocation",
    "raw-runtime-config-input",
    "frontend-output",
    "raw-wire-input",
    "schema-migration",
    "namespaced-extension",
    "typed-nix-handle",
    "native-guest-module",
    "target-native-extension",
    "create-native-extension",
    "operator-native-extension",
    "service-native-extension",
    "live-native-extension",
    "exec-native-extension",
    "adapter-native-extension",
    "provider-native-adapter",
    "provider-native-operation",
    "corrupted-manifest",
    "target-lowering",
    "built-artifact-load",
    "direct-api",
    "framework-adapter",
    "cli-adapter",
    "managed-service",
    "direct-native-nix-value",
    "frontend-adaptation",
    "unsafe-opaque-extension",
    "provider-side-construction",
    "provider-build-cache",
    "prebuilt-member-transfer",
    "oci-descriptor-transfer",
    "provider-cache-hit",
    "corrupted-provider-build-result"
  ];

def owners:
  ["artifact", "create", "operator", "service", "live", "exec", "framework", "runtime", "core"];

def effects:
  ["may-contribute", "may-narrow", "may-select", "no-authority", "boundary-input"];

def categories:
  [
    "authoring",
    "frontend-boundary",
    "artifact-native",
    "lifecycle-native",
    "provider-native",
    "downstream-boundary",
    "caller"
  ];

def path_registry_statuses:
  ["candidate", "reviewed"];

def resource_source_path_ids:
  [
    "operator-configuration-authoring",
    "operator-configuration-imports",
    "operator-configuration-precedence",
    "operator-configuration-refinement",
    "operator-configuration-native-escape",
    "managed-service-definition-authoring",
    "managed-service-definition-imports",
    "managed-service-definition-precedence",
    "managed-service-definition-refinement",
    "managed-service-definition-native-escape"
  ];

def driver_path_ids:
  [
    "resolved-driver-handoff",
    "serialized-resolved-reentry",
    "generated-runtime-configuration",
    "direct-driver-invocation",
    "raw-runtime-config-input"
  ];

def forbidden_driver_path_ids:
  ["direct-driver-invocation", "raw-runtime-config-input"];

def exact_path_contract_tuples:
  [
    ["artifact-ordinary-authoring","artifact",["artifact"],"authoring"],
    ["artifact-imports","artifact",["artifact"],"authoring"],
    ["artifact-import-order","artifact",["artifact"],"authoring"],
    ["artifact-profile-expansion","artifact",["artifact"],"artifact-normalization"],
    ["artifact-explicit-override","artifact",["artifact"],"authoring"],
    ["artifact-semantic-refinement","artifact",["artifact"],"authoring"],
    ["artifact-strongest-override","artifact",["artifact"],"authoring"],
    ["artifact-native-language-escape","artifact",["artifact"],"authoring"],
    ["operator-configuration-authoring","operator",["operator"],"operator-source"],
    ["operator-configuration-imports","operator",["operator"],"operator-source"],
    ["operator-configuration-precedence","operator",["operator"],"operator-source"],
    ["operator-configuration-refinement","operator",["operator"],"operator-source"],
    ["operator-configuration-native-escape","operator",["operator"],"operator-source"],
    ["managed-service-definition-authoring","service",["service"],"managed-service-source"],
    ["managed-service-definition-imports","service",["service"],"managed-service-source"],
    ["managed-service-definition-precedence","service",["service"],"managed-service-source"],
    ["managed-service-definition-refinement","service",["service"],"managed-service-source"],
    ["managed-service-definition-native-escape","service",["service"],"managed-service-source"],
    ["resolved-driver-handoff","runtime",["create","operator","runtime"],"resolved-driver-handoff"],
    ["serialized-resolved-reentry","runtime",["create","operator","runtime"],"serialized-resolved-reentry"],
    ["generated-runtime-configuration","runtime",["runtime"],"generated-runtime-configuration"],
    ["direct-driver-invocation","runtime",[],"direct-driver-invocation"],
    ["raw-runtime-config-input","runtime",[],"raw-runtime-config-input"],
    ["frontend-output","artifact",["artifact"],"frontend-boundary"],
    ["raw-wire-input","runtime",["artifact"],"raw-wire"],
    ["schema-migration","runtime",["artifact"],"schema-migration"],
    ["namespaced-extension","artifact",["artifact"],"artifact-native"],
    ["typed-nix-handle","artifact",["artifact"],"typed-handle"],
    ["native-guest-module","artifact",["artifact"],"target-native"],
    ["target-native-extension","artifact",["artifact"],"target-native"],
    ["create-native-extension","create",["create"],"create"],
    ["operator-native-extension","operator",["operator"],"operator"],
    ["service-native-extension","service",["service"],"service"],
    ["live-native-extension","live",["live"],"live"],
    ["exec-native-extension","exec",["exec"],"exec"],
    ["adapter-native-extension","framework",["framework"],"framework"],
    ["provider-native-adapter","operator",["operator","runtime"],"provider-admission"],
    ["provider-native-operation","runtime",["runtime"],"provider-operation"],
    ["corrupted-manifest","runtime",["artifact","create"],"manifest-load"],
    ["target-lowering","runtime",["artifact","runtime"],"target-lowering"],
    ["built-artifact-load","runtime",["artifact","create"],"manifest-load"],
    ["direct-api","create",["create"],"create"],
    ["framework-adapter","framework",["framework"],"framework"],
    ["cli-adapter","framework",["framework"],"framework"],
    ["managed-service","service",["service"],"service"],
    ["direct-native-nix-value","artifact",["artifact"],"typed-handle"],
    ["frontend-adaptation","artifact",["artifact"],"frontend-boundary"],
    ["unsafe-opaque-extension","artifact",["artifact"],"unsafe-opaque"],
    ["provider-side-construction","runtime",["artifact","runtime"],"provider-build"],
    ["provider-build-cache","runtime",["artifact","runtime"],"provider-result"],
    ["prebuilt-member-transfer","runtime",["artifact","runtime"],"provider-admission"],
    ["oci-descriptor-transfer","runtime",["artifact","runtime"],"provider-admission"],
    ["provider-cache-hit","runtime",["artifact","runtime"],"provider-operation"],
    ["corrupted-provider-build-result","runtime",["artifact","runtime"],"provider-result"]
  ];

def exact_path_contract($id):
  first(
    exact_path_contract_tuples[] |
    select(.[0] == $id) |
    {
      "sourceOwner": .[1],
      "reachableOwners": .[2],
      "contractTemplate": .[3]
    }
  ) // null;

def exact_path_semantic_tuples:
  [
    ["artifact-ordinary-authoring","authoring",["may-contribute","no-authority"],"source-semantics","canonical-wire","ordinary-composition",["portable"],["F"],"authoring",[["nix","supported","NIX-MODULE-SYSTEM-2026-07-24","planned/packet-d/ordinary-authoring/nix-module-definition"],["cue","supported","CUE-SPEC-2026-07-24","planned/packet-d/ordinary-authoring/cue-definition"],["nickel","supported","NICKEL-MERGE-CONTRACTS-2026-07-24","planned/packet-d/ordinary-authoring/nickel-contract"],["pkl","supported","PKL-LANGUAGE-EXTERNAL-READERS-2026-07-24","planned/packet-d/ordinary-authoring/pkl-module"],["dhall","research-control-only","DHALL-STANDARD-2026-07-24","planned/packet-d/ordinary-authoring/dhall-record"]]],
    ["artifact-imports","authoring",["may-contribute","no-authority"],"source-semantics","canonical-wire","import-composition",["portable"],["F"],"authoring",[["nix","supported","NIX-MODULE-SYSTEM-2026-07-24","planned/packet-d/imports/nix-modules"],["cue","supported","CUE-SPEC-2026-07-24","planned/packet-d/imports/cue-import"],["nickel","supported","NICKEL-MERGE-CONTRACTS-2026-07-24","planned/packet-d/imports/nickel-import"],["pkl","supported","PKL-LANGUAGE-EXTERNAL-READERS-2026-07-24","planned/packet-d/imports/pkl-import"],["dhall","research-control-only","DHALL-STANDARD-2026-07-24","planned/packet-d/imports/dhall-import"]]],
    ["artifact-import-order","authoring",["may-contribute","no-authority"],"source-semantics","canonical-wire","composition-precedence",["portable"],["F"],"authoring",[["nix","supported","NIX-MODULE-SYSTEM-2026-07-24","planned/packet-d/import-order/nix-mkorder"]]],
    ["artifact-profile-expansion","authoring",["may-select","no-authority"],"artifact-normalization","canonical-wire","profile-expansion",["portable"],["F"],"artifact-normalization",[["nix","supported","NIX-MODULE-SYSTEM-2026-07-24","planned/packet-d/profile-expansion/nix-profile"]]],
    ["artifact-explicit-override","authoring",["may-contribute","may-narrow","may-select","no-authority"],"source-semantics","canonical-wire","composition-precedence",["portable"],["F"],"authoring",[["nix","supported","NIX-MODULE-SYSTEM-2026-07-24","planned/packet-d/explicit-override/nix-mkoverride"]]],
    ["artifact-semantic-refinement","authoring",["may-contribute","may-narrow","may-select","no-authority"],"source-semantics","canonical-wire","semantic-widening",["portable"],["F"],"authoring",[["cue","supported","CUE-SPEC-2026-07-24","planned/packet-d/semantic-refinement/cue-unification"],["nickel","supported","NICKEL-MERGE-CONTRACTS-2026-07-24","planned/packet-d/semantic-refinement/nickel-merge"]]],
    ["artifact-strongest-override","authoring",["may-contribute","may-select","no-authority"],"source-semantics","canonical-wire","composition-precedence",["portable"],["F"],"authoring",[["nix","supported","NIX-MODULE-SYSTEM-2026-07-24","planned/packet-d/strongest-override/nix-mkforce"],["nickel","supported","NICKEL-MERGE-CONTRACTS-2026-07-24","planned/packet-d/strongest-override/nickel-force"],["pkl","supported","PKL-LANGUAGE-EXTERNAL-READERS-2026-07-24","planned/packet-d/strongest-override/pkl-amend"]]],
    ["artifact-native-language-escape","authoring",["no-authority"],"source-semantics","canonical-wire","native-language-escape",["portable"],["F"],"authoring",[["nix","supported","NIX-MODULE-SYSTEM-2026-07-24","planned/packet-d/native-language-escape/nix-freeform"],["cue","unsupported","CUE-SPEC-2026-07-24","planned/packet-d/native-language-escape/cue-closed-definition"],["nickel","supported","NICKEL-MERGE-CONTRACTS-2026-07-24","planned/packet-d/native-language-escape/nickel-foreign"],["pkl","supported","PKL-LANGUAGE-EXTERNAL-READERS-2026-07-24","planned/packet-d/native-language-escape/pkl-dynamic"]]],
    ["operator-configuration-authoring","authoring",["may-contribute","no-authority"],"operator-configuration-source-completion","operator-configuration-validation","operator-configuration-composition",["portable"],["E","F"],"operator-source",[["nix","supported","NIX-MODULE-SYSTEM-2026-07-24","planned/packet-d/operator-configuration-authoring/nix-module-definition"]]],
    ["operator-configuration-imports","authoring",["may-contribute","no-authority"],"operator-configuration-source-completion","operator-configuration-validation","operator-configuration-import-composition",["portable"],["E","F"],"operator-source",[["nix","supported","NIX-MODULE-SYSTEM-2026-07-24","planned/packet-d/operator-configuration-imports/nix-module-imports"]]],
    ["operator-configuration-precedence","authoring",["may-contribute","may-select","may-narrow","no-authority"],"operator-configuration-source-completion","operator-configuration-validation","operator-configuration-precedence",["portable"],["E","F"],"operator-source",[["nix","supported","NIX-MODULE-SYSTEM-2026-07-24","planned/packet-d/operator-configuration-precedence/nix-definition-priority"]]],
    ["operator-configuration-refinement","authoring",["may-select","may-narrow","no-authority"],"operator-configuration-source-completion","operator-configuration-validation","operator-configuration-refinement",["portable"],["E","F"],"operator-source",[["nix","supported","NIX-MODULE-SYSTEM-2026-07-24","planned/packet-d/operator-configuration-refinement/nix-selection-narrowing"]]],
    ["operator-configuration-native-escape","authoring",["no-authority"],"operator-configuration-source-completion","operator-configuration-validation","operator-configuration-native-escape",["portable"],["E","F"],"operator-source",[["nix","supported","NIX-MODULE-SYSTEM-2026-07-24","planned/packet-d/operator-configuration-native-escape/nix-freeform"]]],
    ["managed-service-definition-authoring","authoring",["may-contribute","no-authority"],"managed-service-definition-source-completion","managed-service-definition-validation","managed-service-definition-composition",["portable"],["E","F"],"managed-service-source",[["nix","supported","NIX-MODULE-SYSTEM-2026-07-24","planned/packet-d/managed-service-definition-authoring/nix-module-definition"]]],
    ["managed-service-definition-imports","authoring",["may-contribute","no-authority"],"managed-service-definition-source-completion","managed-service-definition-validation","managed-service-definition-import-composition",["portable"],["E","F"],"managed-service-source",[["nix","supported","NIX-MODULE-SYSTEM-2026-07-24","planned/packet-d/managed-service-definition-imports/nix-module-imports"]]],
    ["managed-service-definition-precedence","authoring",["may-contribute","may-select","may-narrow","no-authority"],"managed-service-definition-source-completion","managed-service-definition-validation","managed-service-definition-precedence",["portable"],["E","F"],"managed-service-source",[["nix","supported","NIX-MODULE-SYSTEM-2026-07-24","planned/packet-d/managed-service-definition-precedence/nix-definition-priority"]]],
    ["managed-service-definition-refinement","authoring",["may-select","may-narrow","no-authority"],"managed-service-definition-source-completion","managed-service-definition-validation","managed-service-definition-refinement",["portable"],["E","F"],"managed-service-source",[["nix","supported","NIX-MODULE-SYSTEM-2026-07-24","planned/packet-d/managed-service-definition-refinement/nix-selection-narrowing"]]],
    ["managed-service-definition-native-escape","authoring",["no-authority"],"managed-service-definition-source-completion","managed-service-definition-validation","managed-service-definition-native-escape",["portable"],["E","F"],"managed-service-source",[["nix","supported","NIX-MODULE-SYSTEM-2026-07-24","planned/packet-d/managed-service-definition-native-escape/nix-freeform"]]],
    ["resolved-driver-handoff","downstream-boundary",["may-contribute","may-narrow","no-authority"],"creation-resolution","driver-entry-validation","private-stage-identity",["all-packet-c-profiles"],["E","F"],"resolved-driver-handoff",[["shared-product-boundary","supported","PACKET-C-TARGET-CONTRACTS-2026-07-24","planned/packet-d/resolved-driver-handoff/private-stage"]]],
    ["serialized-resolved-reentry","downstream-boundary",["boundary-input","no-authority"],"resolved-reentry-wire-validation","driver-entry-validation","serialized-stage-forgery",["all-packet-c-profiles"],["E","F"],"serialized-resolved-reentry",[["shared-product-boundary","supported","PACKET-C-TARGET-CONTRACTS-2026-07-24","planned/packet-d/serialized-resolved-reentry/strict-replay"]]],
    ["generated-runtime-configuration","downstream-boundary",["boundary-input","no-authority"],"driver-entry-validation","driver-entry-validation","generated-runtime-configuration",["all-packet-c-profiles"],["E","F"],"generated-runtime-configuration",[["shared-product-boundary","supported","PACKET-C-TARGET-CONTRACTS-2026-07-24","planned/packet-d/generated-runtime-configuration/closed-validation"]]],
    ["direct-driver-invocation","downstream-boundary",["no-authority"],"driver-entry-validation","driver-entry-validation","direct-driver-invocation",["all-packet-c-profiles"],["E","F"],"direct-driver-invocation",[]],
    ["raw-runtime-config-input","downstream-boundary",["no-authority"],"driver-entry-validation","driver-entry-validation","raw-runtime-config-input",["all-packet-c-profiles"],["E","F"],"raw-runtime-config-input",[]],
    ["frontend-output","frontend-boundary",["boundary-input","no-authority"],"frontend-output-validation","canonical-wire","frontend-output-corruption",["portable"],["F"],"frontend-boundary",[["nix","supported","NIX-MODULE-SYSTEM-2026-07-24","planned/packet-d/frontend-output/nix-projection"],["cue","supported","CUE-SPEC-2026-07-24","planned/packet-d/frontend-output/cue-export"],["nickel","supported","NICKEL-MERGE-CONTRACTS-2026-07-24","planned/packet-d/frontend-output/nickel-export"],["pkl","supported","PKL-LANGUAGE-EXTERNAL-READERS-2026-07-24","planned/packet-d/frontend-output/pkl-render"],["dhall","research-control-only","DHALL-STANDARD-2026-07-24","planned/packet-d/frontend-output/dhall-json"]]],
    ["raw-wire-input","downstream-boundary",["boundary-input","no-authority"],"strict-wire-decode","canonical-wire","wire-corruption",["portable"],["F"],"raw-wire",[["shared-product-boundary","supported","JSON-RFC-IJSON-JCS-2026-07-24","planned/packet-d/raw-wire-input/json-decoder"]]],
    ["schema-migration","downstream-boundary",["boundary-input","no-authority"],"strict-wire-decode","canonical-wire","migration-corruption",["portable"],["F"],"schema-migration",[["shared-product-boundary","supported","JSON-RFC-IJSON-JCS-2026-07-24","planned/packet-d/schema-migration/versioned-migration"]]],
    ["namespaced-extension","artifact-native",["may-contribute","no-authority"],"artifact-final-validation","canonical-wire","extension-namespace",["all-packet-c-profiles"],["F"],"artifact-native",[["shared-product-boundary","supported","PACKET-C-TARGET-CONTRACTS-2026-07-24","planned/packet-d/namespaced-extension/registered-extension"]]],
    ["typed-nix-handle","artifact-native",["may-contribute","no-authority"],"artifact-final-validation","nix-handle-registry","native-handle-forgery",["all-packet-c-profiles"],["F"],"typed-handle",[["nix","supported","NIX-MODULE-SYSTEM-2026-07-24","planned/packet-d/typed-nix-handle/registry-digest"]]],
    ["native-guest-module","artifact-native",["may-contribute","no-authority"],"artifact-final-validation","packet-c-realization","guest-host-ownership",["microvm-firecracker-linux-v1","microvm-cloud-hypervisor-linux-v1"],["F"],"target-native",[["nix","supported","NIX-MODULE-SYSTEM-2026-07-24","planned/packet-d/native-guest-module/guest-ownership"]]],
    ["target-native-extension","artifact-native",["may-contribute","no-authority"],"artifact-final-validation","packet-c-realization","target-native-widening",["all-packet-c-profiles"],["F"],"target-native",[["nix","supported","PACKET-C-TARGET-CONTRACTS-2026-07-24","planned/packet-d/target-native-extension/packet-c-reentry"]]],
    ["create-native-extension","lifecycle-native",["may-narrow","no-authority"],"creation-resolution","driver-preparation","lifecycle-ownership",["all-packet-c-profiles"],["E","F"],"create",[["shared-product-boundary","supported","PACKET-C-TARGET-CONTRACTS-2026-07-24","planned/packet-d/create-native-extension/create-owner"]]],
    ["operator-native-extension","lifecycle-native",["may-select","no-authority"],"operator-admission","driver-preparation","lifecycle-ownership",["all-packet-c-profiles"],["E","F"],"operator",[["shared-product-boundary","supported","PACKET-C-TARGET-CONTRACTS-2026-07-24","planned/packet-d/operator-native-extension/operator-owner"]]],
    ["service-native-extension","lifecycle-native",["may-select","no-authority"],"service-reconciliation","core-api","lifecycle-ownership",["all-packet-c-profiles"],["E","F"],"service",[["nix","supported","NIX-MODULE-SYSTEM-2026-07-24","planned/packet-d/service-native-extension/service-owner"]]],
    ["live-native-extension","lifecycle-native",["may-narrow","no-authority"],"live-operation-validation","live-operation-validation","lifecycle-ownership",["all-packet-c-profiles"],["E","F"],"live",[["shared-product-boundary","supported","PACKET-C-TARGET-CONTRACTS-2026-07-24","planned/packet-d/live-native-extension/live-owner"]]],
    ["exec-native-extension","lifecycle-native",["may-narrow","no-authority"],"exec-validation","exec-validation","lifecycle-ownership",["all-packet-c-profiles"],["E","F"],"exec",[["shared-product-boundary","supported","PACKET-C-TARGET-CONTRACTS-2026-07-24","planned/packet-d/exec-native-extension/exec-owner"]]],
    ["adapter-native-extension","lifecycle-native",["may-select","no-authority"],"framework-translation","core-api","adapter-ownership",["portable"],["E","F"],"framework",[["shared-product-boundary","supported","PACKET-C-TARGET-CONTRACTS-2026-07-24","planned/packet-d/adapter-native-extension/framework-owner"]]],
    ["provider-native-adapter","provider-native",["boundary-input","no-authority"],"operator-admission","host-provider-preflight","provider-default",["remote-provider"],["E","F"],"provider-admission",[["shared-product-boundary","supported","PACKET-C-TARGET-CONTRACTS-2026-07-24","planned/packet-d/provider-native-adapter/provider-admission"]]],
    ["provider-native-operation","provider-native",["boundary-input","no-authority"],"host-provider-preflight","driver-preparation","provider-operation",["remote-provider"],["E","F"],"provider-operation",[["shared-product-boundary","supported","PACKET-C-TARGET-CONTRACTS-2026-07-24","planned/packet-d/provider-native-operation/provider-operation"]]],
    ["corrupted-manifest","downstream-boundary",["boundary-input","no-authority"],"manifest-load","creation-resolution","manifest-corruption",["all-packet-c-profiles"],["F"],"manifest-load",[["shared-product-boundary","supported","PACKET-C-TARGET-CONTRACTS-2026-07-24","planned/packet-d/corrupted-manifest/manifest-loader"]]],
    ["target-lowering","downstream-boundary",["boundary-input","no-authority"],"packet-c-contract-rederivation","manifest-load","target-lowering-corruption",["all-packet-c-profiles"],["F"],"target-lowering",[["nix","supported","PACKET-C-TARGET-CONTRACTS-2026-07-24","planned/packet-d/target-lowering/packet-c-realization"]]],
    ["built-artifact-load","downstream-boundary",["boundary-input","no-authority"],"manifest-load","creation-resolution","built-artifact-corruption",["all-packet-c-profiles"],["F"],"manifest-load",[["shared-product-boundary","supported","PACKET-C-TARGET-CONTRACTS-2026-07-24","planned/packet-d/built-artifact-load/member-verification"]]],
    ["direct-api","caller",["boundary-input","no-authority"],"creation-resolution","core-api","caller-widening",["all-packet-c-profiles"],["E","F"],"create",[["shared-product-boundary","supported","PACKET-C-TARGET-CONTRACTS-2026-07-24","planned/packet-d/direct-api/create-request"]]],
    ["framework-adapter","caller",["boundary-input","no-authority"],"framework-translation","core-api","adapter-widening",["portable"],["E","F"],"framework",[["shared-product-boundary","supported","PACKET-C-TARGET-CONTRACTS-2026-07-24","planned/packet-d/framework-adapter/core-api-translation"]]],
    ["cli-adapter","caller",["boundary-input","no-authority"],"framework-translation","core-api","adapter-widening",["portable"],["E","F"],"framework",[["shared-product-boundary","supported","PACKET-C-TARGET-CONTRACTS-2026-07-24","planned/packet-d/cli-adapter/core-api-translation"]]],
    ["managed-service","caller",["boundary-input","no-authority"],"service-reconciliation","core-api","service-widening",["portable"],["E","F"],"service",[["nix","supported","NIX-MODULE-SYSTEM-2026-07-24","planned/packet-d/managed-service/core-api-translation"]]],
    ["direct-native-nix-value","artifact-native",["may-contribute","no-authority"],"artifact-final-validation","nix-handle-registry","arbitrary-nix-value",["all-packet-c-profiles"],["F"],"typed-handle",[["nix","supported","NIX-MODULE-SYSTEM-2026-07-24","planned/packet-d/direct-native-nix-value/semantic-projection"]]],
    ["frontend-adaptation","frontend-boundary",["boundary-input","no-authority"],"frontend-output-validation","canonical-wire","frontend-claim",["portable"],["F"],"frontend-boundary",[["cue","supported","CUE-SPEC-2026-07-24","planned/packet-d/frontend-adaptation/cue-adapter"],["nickel","supported","NICKEL-MERGE-CONTRACTS-2026-07-24","planned/packet-d/frontend-adaptation/nickel-adapter"],["pkl","supported","PKL-LANGUAGE-EXTERNAL-READERS-2026-07-24","planned/packet-d/frontend-adaptation/pkl-adapter"],["dhall","research-control-only","DHALL-STANDARD-2026-07-24","planned/packet-d/frontend-adaptation/dhall-adapter"]]],
    ["unsafe-opaque-extension","artifact-native",["no-authority"],"artifact-final-validation","artifact-final-validation","opaque-extension",["all-packet-c-profiles"],["F"],"unsafe-opaque",[["cue","unsupported","CUE-SPEC-2026-07-24","planned/packet-d/unsafe-opaque-extension/cue-reject"],["nix","unsupported","NIX-MODULE-SYSTEM-2026-07-24","planned/packet-d/unsafe-opaque-extension/nix-reject"]]],
    ["provider-side-construction","provider-native",["boundary-input","no-authority"],"nix-construction","provider-build-result","provider-build",["remote-provider"],["E","F"],"provider-build",[["shared-product-boundary","supported","PACKET-C-TARGET-CONTRACTS-2026-07-24","planned/packet-d/provider-side-construction/output-equivalence"]]],
    ["provider-build-cache","provider-native",["boundary-input","no-authority"],"provider-build-result","provider-build-result","provider-cache",["remote-provider"],["E","F"],"provider-result",[["shared-product-boundary","supported","PACKET-C-TARGET-CONTRACTS-2026-07-24","planned/packet-d/provider-build-cache/reverify-cache"]]],
    ["prebuilt-member-transfer","provider-native",["boundary-input","no-authority"],"operator-admission","host-provider-preflight","member-transfer",["remote-provider"],["E","F"],"provider-admission",[["shared-product-boundary","supported","PACKET-C-TARGET-CONTRACTS-2026-07-24","planned/packet-d/prebuilt-member-transfer/member-digest"]]],
    ["oci-descriptor-transfer","provider-native",["boundary-input","no-authority"],"operator-admission","host-provider-preflight","descriptor-transfer",["oci-linux-v1","remote-provider"],["E","F"],"provider-admission",[["shared-product-boundary","supported","PACKET-C-TARGET-CONTRACTS-2026-07-24","planned/packet-d/oci-descriptor-transfer/descriptor-graph"]]],
    ["provider-cache-hit","provider-native",["boundary-input","no-authority"],"host-provider-preflight","driver-preparation","provider-cache",["remote-provider"],["E","F"],"provider-operation",[["shared-product-boundary","supported","PACKET-C-TARGET-CONTRACTS-2026-07-24","planned/packet-d/provider-cache-hit/reverify-identity"]]],
    ["corrupted-provider-build-result","downstream-boundary",["boundary-input","no-authority"],"provider-build-result","provider-build-result","provider-result-corruption",["remote-provider"],["E","F"],"provider-result",[["shared-product-boundary","supported","PACKET-C-TARGET-CONTRACTS-2026-07-24","planned/packet-d/corrupted-provider-build-result/output-verifier"]]]
  ];

def exact_path_semantics($id):
  first(
    exact_path_semantic_tuples[] |
    select(.[0] == $id) |
    . as $tuple |
    {
      "category": $tuple[1],
      "allowedEffects": $tuple[2],
      "firstBoundary": $tuple[3],
      "finalBoundary": $tuple[4],
      "strongestBypassClass": $tuple[5],
      "targetApplicability": $tuple[6],
      "delegatedPackets": $tuple[7],
      "contractTemplate": $tuple[8],
      "frontendMappings": [
        $tuple[9][] |
        {
          "candidate": .[0],
          "result": .[1],
          "researchPin": .[2],
          "witness": .[3]
        }
      ]
    }
  ) // null;

# PACKET-D-COMPOSITION-PATHS.json textAuthority makes only `.mechanism`
# explanatory; normative identity excludes it, while structural validation
# below still requires the field to be present and non-empty.
def frontend_mapping_projection($mapping):
  {
    "candidate": $mapping.candidate,
    "result": $mapping.result,
    "researchPin": $mapping.researchPin,
    "witness": $mapping.witness
  };

def complete_path_projection($path; $entry):
  {
    "category": $path.category,
    "sourceOwner": $path.sourceOwner,
    "reachableOwners": $path.reachableOwners,
    "allowedEffects": $path.allowedEffects,
    "firstBoundary": $path.firstBoundary,
    "finalBoundary": $path.finalBoundary,
    "strongestBypassClass": $path.strongestBypassClass,
    "targetApplicability": $path.targetApplicability,
    "delegatedPackets": $path.delegatedPackets,
    "contractTemplate": $entry.contractTemplate,
    "frontendMappings": [
      $path.frontendMappings[] |
      frontend_mapping_projection(.)
    ]
  };

def exact_registry_path_aliases:
  {
    "adapter-native-extension": "adapter-native-extension",
    "artifact-semantic-refinement": "artifact-semantic-refinement",
    "binding-resolution": "direct-api",
    "built-artifact-load": "built-artifact-load",
    "canonical-wire-corruption": "raw-wire-input",
    "cli-adapter": "cli-adapter",
    "core-api": "direct-api",
    "corrupted-manifest": "corrupted-manifest",
    "corrupted-provider-build-result": "corrupted-provider-build-result",
    "corrupted-resolved-input": "serialized-resolved-reentry",
    "create-native-extension": "create-native-extension",
    "direct-api": "direct-api",
    "direct-driver-invocation": "direct-driver-invocation",
    "direct-native-nix-value": "direct-native-nix-value",
    "driver-preparation": "resolved-driver-handoff",
    "driver-selection": "operator-native-extension",
    "exec-native-extension": "exec-native-extension",
    "explicit-override": "artifact-explicit-override",
    "framework-adapter": "framework-adapter",
    "frontend-adaptation": "frontend-adaptation",
    "frontend-output": "frontend-output",
    "generated-runtime-configuration": "generated-runtime-configuration",
    "generated-unit-inspection": "managed-service",
    "host-path-resolution": "resolved-driver-handoff",
    "host-preflight": "provider-native-operation",
    "idempotent-retry": "direct-api",
    "import-order": "artifact-import-order",
    "imports": "artifact-imports",
    "initial-process": "direct-api",
    "live-native-extension": "live-native-extension",
    "live-operation": "live-native-extension",
    "managed-service": "managed-service",
    "managed-service-definition-authoring": "managed-service-definition-authoring",
    "managed-service-definition-imports": "managed-service-definition-imports",
    "managed-service-definition-native-escape": "managed-service-definition-native-escape",
    "managed-service-definition-precedence": "managed-service-definition-precedence",
    "managed-service-definition-refinement": "managed-service-definition-refinement",
    "managed-service-reconciliation": "managed-service",
    "member-deduplication": "built-artifact-load",
    "namespaced-extension": "namespaced-extension",
    "native-guest-module": "native-guest-module",
    "native-language-escape": "artifact-native-language-escape",
    "oci-descriptor-transfer": "oci-descriptor-transfer",
    "operator-configuration-authoring": "operator-configuration-authoring",
    "operator-configuration-imports": "operator-configuration-imports",
    "operator-configuration-native-escape": "operator-configuration-native-escape",
    "operator-configuration-precedence": "operator-configuration-precedence",
    "operator-configuration-refinement": "operator-configuration-refinement",
    "operator-policy": "operator-native-extension",
    "operator-registration": "operator-native-extension",
    "ordinary-authoring": "artifact-ordinary-authoring",
    "placement": "direct-api",
    "prebuilt-member-transfer": "prebuilt-member-transfer",
    "profile-expansion": "artifact-profile-expansion",
    "provider-build-cache": "provider-build-cache",
    "provider-cache-hit": "provider-cache-hit",
    "provider-native-adapter": "provider-native-adapter",
    "provider-native-operation": "provider-native-operation",
    "provider-selection": "direct-api",
    "provider-side-construction": "provider-side-construction",
    "raw-runtime-config-input": "raw-runtime-config-input",
    "raw-wire-input": "raw-wire-input",
    "resolved-driver-handoff": "resolved-driver-handoff",
    "schema-migration": "schema-migration",
    "secret-delivery": "direct-api",
    "serialized-resolved-reentry": "serialized-resolved-reentry",
    "service-native-extension": "service-native-extension",
    "snapshot-capture": "live-native-extension",
    "snapshot-restore": "direct-api",
    "strongest-override": "artifact-strongest-override",
    "target-lowering": "target-lowering",
    "target-native-extension": "target-native-extension",
    "target-selection": "direct-api",
    "tool-registration": "framework-adapter",
    "typed-nix-handle": "typed-nix-handle",
    "unsafe-opaque-extension": "unsafe-opaque-extension"
  };

def required_profile_ids:
  [
    "bubblewrap-linux-v1",
    "microvm-firecracker-linux-v1",
    "microvm-cloud-hypervisor-linux-v1",
    "oci-linux-v1"
  ];

def active_effect:
  . == "may-contribute" or . == "may-narrow" or . == "may-select";

def projected_profiles($applicability; $all):
  if ($applicability | index("portable")) != null then []
  elif ($applicability | index("all-packet-c-profiles")) != null then $all
  else
    [$applicability[] | select(. != "remote-provider")] as $explicit |
    if ($explicit | length) == 0 and
       ($applicability | index("remote-provider")) != null
    then $all
    else $explicit
    end
  end;

def resolved_stage_replay_invariant_ids:
  [
    "XRS-001","XRS-002","TGT-002","TGT-003",
    "CRT-001","CRT-002","CRT-003","CRT-004","CRT-005","CRT-006",
    "IDT-002","MAN-001","MAN-002","MAN-003","MAN-004","MAN-005","MAN-006",
    "XRS-006","OPS-001","OPS-002",
    "HOST-001","HOST-002","HOST-003","HOST-004","PRV-001",
    "XRS-003","XRS-004","HOST-005","WIRE-004","DRV-001"
  ];

def serialized_reentry_boundary_input_ids:
  (
    $caseContracts[0].packetCTargetRealizationInvariantIds +
    resolved_stage_replay_invariant_ids +
    ["WIRE-007","DRV-002","DRV-003"]
  ) | unique;

def exact_delegated_concern_taxonomy:
  {
    "E":["operation-transition","retry","cancellation","cleanup"],
    "F":["disclosure","redaction","evidence-visibility"]
  };

def exact_cross_path_handoffs:
  [
    {
      "fromPathId":"prebuilt-member-transfer",
      "afterBoundary":{"id":"host-provider-preflight","phase":"H0","component":"remote-provider-adapter"},
      "toPathId":"built-artifact-load",
      "resumeBoundary":{"id":"manifest-load","phase":"C0","component":"artifact-manifest-loader"},
      "ordering":"separate-path-handoff"
    },
    {
      "fromPathId":"oci-descriptor-transfer",
      "afterBoundary":{"id":"host-provider-preflight","phase":"H0","component":"remote-provider-adapter"},
      "toPathId":"built-artifact-load",
      "resumeBoundary":{"id":"manifest-load","phase":"C0","component":"artifact-manifest-loader"},
      "ordering":"separate-path-handoff"
    },
    {
      "fromPathId":"provider-cache-hit",
      "afterBoundary":{"id":"driver-preparation","phase":"D0","component":"driver-preparation"},
      "toPathId":"built-artifact-load",
      "resumeBoundary":{"id":"manifest-load","phase":"C0","component":"artifact-manifest-loader"},
      "ordering":"separate-path-handoff"
    },
    {
      "fromPathId":"provider-side-construction",
      "afterBoundary":{"id":"packet-c-realization","phase":"N1","component":"target-member-verifier"},
      "toPathId":"built-artifact-load",
      "resumeBoundary":{"id":"manifest-load","phase":"C0","component":"artifact-manifest-loader"},
      "ordering":"separate-path-handoff"
    },
    {
      "fromPathId":"provider-build-cache",
      "afterBoundary":{"id":"packet-c-realization","phase":"N1","component":"target-member-verifier"},
      "toPathId":"built-artifact-load",
      "resumeBoundary":{"id":"manifest-load","phase":"C0","component":"artifact-manifest-loader"},
      "ordering":"separate-path-handoff"
    },
    {
      "fromPathId":"corrupted-provider-build-result",
      "afterBoundary":{"id":"packet-c-realization","phase":"N1","component":"target-member-verifier"},
      "toPathId":"built-artifact-load",
      "resumeBoundary":{"id":"manifest-load","phase":"C0","component":"artifact-manifest-loader"},
      "ordering":"separate-path-handoff"
    }
  ];

def exact_driver_trust_state_contracts:
  {
    "resolved-driver-handoff":{
      "inputTrust":"private-product-owned",
      "admittedValue":"PreparedLaunch",
      "phaseSequence":["C0","O0","H0","D0"],
      "fullReplay":false,
      "totalGenerator":false,
      "backendDefaultSuppression":false
    },
    "serialized-resolved-reentry":{
      "inputTrust":"untrusted-serialized",
      "admittedValue":"PreparedLaunch-after-full-replay",
      "phaseSequence":["RW0","C0","O0","H0","D0"],
      "fullReplay":true,
      "totalGenerator":false,
      "backendDefaultSuppression":false
    },
    "generated-runtime-configuration":{
      "inputTrust":"product-generated",
      "admittedValue":"GeneratedRuntimeConfiguration",
      "phaseSequence":["D0","D0"],
      "fullReplay":true,
      "totalGenerator":true,
      "backendDefaultSuppression":true
    },
    "direct-driver-invocation":{
      "inputTrust":"forbidden-external",
      "admittedValue":null,
      "phaseSequence":["D0"],
      "fullReplay":false,
      "totalGenerator":false,
      "backendDefaultSuppression":false
    },
    "raw-runtime-config-input":{
      "inputTrust":"forbidden-external",
      "admittedValue":null,
      "phaseSequence":["D0"],
      "fullReplay":false,
      "totalGenerator":false,
      "backendDefaultSuppression":false
    }
  };

def exact_source_template_boundary_chains:
  {
    "operator-source":[
      {"id":"operator-source-semantics","phase":"P1","component":"nix-source-semantics"},
      {"id":"operator-dependency-closure","phase":"OC0","component":"operator-configuration-dependency-resolver"},
      {"id":"operator-precedence-and-provenance","phase":"OC0","component":"operator-configuration-composer"},
      {"id":"operator-configuration-validation","phase":"OC0","component":"operator-configuration-validator"}
    ],
    "managed-service-source":[
      {"id":"managed-service-source-semantics","phase":"P1","component":"nix-source-semantics"},
      {"id":"managed-service-dependency-closure","phase":"MS0","component":"managed-service-definition-dependency-resolver"},
      {"id":"managed-service-precedence-and-provenance","phase":"MS0","component":"managed-service-definition-composer"},
      {"id":"managed-service-definition-validation","phase":"MS0","component":"managed-service-definition-validator"}
    ]
  };

def exact_driver_template_boundary_chains:
  {
    "resolved-driver-handoff":[
      {"id":"private-resolved-creation","phase":"C0","component":"creation-resolver"},
      {"id":"private-operator-admission","phase":"O0","component":"operator-admission"},
      {"id":"private-host-provider-preflight","phase":"H0","component":"host-provider-preflight"},
      {"id":"driver-entry-validation","phase":"D0","component":"driver-entry-validator"}
    ],
    "serialized-resolved-reentry":[
      {"id":"resolved-reentry-wire-validation","phase":"RW0","component":"resolved-reentry-wire-validator"},
      {"id":"fresh-private-stage-construction","phase":"C0","component":"resolved-reentry-stage-constructor"},
      {"id":"current-operator-admission","phase":"O0","component":"operator-admission"},
      {"id":"current-host-provider-reacquisition","phase":"H0","component":"host-provider-preflight"},
      {"id":"driver-entry-validation","phase":"D0","component":"driver-entry-validator"}
    ],
    "generated-runtime-configuration":[
      {"id":"total-runtime-configuration-generation","phase":"D0","component":"runtime-config-generator"},
      {"id":"generated-runtime-configuration-validation","phase":"D0","component":"runtime-config-validator"}
    ],
    "direct-driver-invocation":[
      {"id":"driver-entry-rejection","phase":"D0","component":"driver-entry-validator"}
    ],
    "raw-runtime-config-input":[
      {"id":"driver-entry-rejection","phase":"D0","component":"driver-entry-validator"}
    ]
  };

def exact_source_contract_templates:
  {
    "operator-source":{
      "firstSoundPhase":"P1",
      "rejectionDeadline":"OC0",
      "authority":{"phase":"OC0","component":"operator-configuration-validator"},
      "boundaryChain":exact_source_template_boundary_chains["operator-source"],
      "structuralExclusion":"Operator Configuration source semantics can author only operator-owned configuration and cannot author Artifact, Create, Service, live, Exec, framework, or runtime facts.",
      "rejectedForeignOwnerAt":"operator-configuration-validation",
      "fullRevalidation":false,
      "identityAuthority":"preserve-only",
      "ownershipExclusions":[
        "artifact-facts",
        "create-facts",
        "service-facts",
        "live-facts",
        "exec-facts",
        "framework-facts",
        "runtime-facts",
        "artifact-identity-minting",
        "conformance-identity-minting"
      ]
    },
    "managed-service-source":{
      "firstSoundPhase":"P1",
      "rejectionDeadline":"MS0",
      "authority":{"phase":"MS0","component":"managed-service-definition-validator"},
      "boundaryChain":exact_source_template_boundary_chains["managed-service-source"],
      "structuralExclusion":"Managed-Service Definition source semantics can author only service-owned desired state and cannot author Artifact, Create, Operator, live, Exec, framework, or runtime facts.",
      "rejectedForeignOwnerAt":"managed-service-definition-validation",
      "fullRevalidation":false,
      "identityAuthority":"preserve-only",
      "ownershipExclusions":[
        "artifact-facts",
        "create-facts",
        "operator-facts",
        "live-facts",
        "exec-facts",
        "framework-facts",
        "runtime-facts",
        "artifact-identity-minting",
        "conformance-identity-minting"
      ]
    }
  };

def exact_driver_contract_templates:
  {
    "resolved-driver-handoff":{
      "firstSoundPhase":"C0",
      "rejectionDeadline":"D0",
      "authority":{"phase":"D0","component":"driver-entry-validator"},
      "boundaryChain":exact_driver_template_boundary_chains["resolved-driver-handoff"],
      "structuralExclusion":"Only product-owned private resolved stages advance to PreparedLaunch; copied or foreign record shapes cannot enter the chain.",
      "rejectedForeignOwnerAt":"private-resolved-creation",
      "fullRevalidation":false,
      "identityAuthority":"extend-private-identity",
      "ownershipExclusions":[
        "forgeable-validated-record",
        "earlier-identity-rewrite",
        "backend-default-authority",
        "conformance-identity-minting"
      ]
    },
    "serialized-resolved-reentry":{
      "firstSoundPhase":"RW0",
      "rejectionDeadline":"D0",
      "authority":{"phase":"D0","component":"driver-entry-validator"},
      "boundaryChain":exact_driver_template_boundary_chains["serialized-resolved-reentry"],
      "structuralExclusion":"Serialized resolved state is wholly untrusted and cannot mint a private stage without strict decoding, exact replay, and current H0 reacquisition.",
      "rejectedForeignOwnerAt":"resolved-reentry-wire-validation",
      "fullRevalidation":true,
      "identityAuthority":"rederive-private-identity",
      "ownershipExclusions":[
        "authenticated-bytes-as-semantic-authority",
        "serialized-handle-authority",
        "private-stage-minting",
        "backend-default-authority"
      ]
    },
    "generated-runtime-configuration":{
      "firstSoundPhase":"D0",
      "rejectionDeadline":"D0",
      "authority":{"phase":"D0","component":"runtime-config-validator"},
      "boundaryChain":exact_driver_template_boundary_chains["generated-runtime-configuration"],
      "structuralExclusion":"Backend configuration is total D0 output from PreparedLaunch, suppresses undeclared defaults, and is validated as a closed generated value.",
      "rejectedForeignOwnerAt":"generated-runtime-configuration-validation",
      "fullRevalidation":true,
      "identityAuthority":"preserve-only",
      "ownershipExclusions":[
        "external-runtime-config-input",
        "backend-default-authority",
        "unchecked-raw-arguments",
        "conformance-identity-minting"
      ]
    },
    "direct-driver-invocation":{
      "firstSoundPhase":"D0",
      "rejectionDeadline":"D0",
      "authority":{"phase":"D0","component":"driver-entry-validator"},
      "boundaryChain":exact_driver_template_boundary_chains["direct-driver-invocation"],
      "structuralExclusion":"Direct driver invocation has no admitted value and is rejected before external mutation.",
      "rejectedForeignOwnerAt":"driver-entry-rejection",
      "fullRevalidation":false,
      "identityAuthority":"no-admitted-value",
      "ownershipExclusions":[
        "all-caller-values",
        "forgeable-prepared-launch",
        "external-mutation",
        "backend-default-authority"
      ]
    },
    "raw-runtime-config-input":{
      "firstSoundPhase":"D0",
      "rejectionDeadline":"D0",
      "authority":{"phase":"D0","component":"driver-entry-validator"},
      "boundaryChain":exact_driver_template_boundary_chains["raw-runtime-config-input"],
      "structuralExclusion":"Raw runtime configuration has no admitted value and is rejected before external mutation.",
      "rejectedForeignOwnerAt":"driver-entry-rejection",
      "fullRevalidation":false,
      "identityAuthority":"no-admitted-value",
      "ownershipExclusions":[
        "all-raw-values",
        "forgeable-generated-configuration",
        "external-mutation",
        "backend-default-authority"
      ]
    }
  };

def exact_template_contract_tuples:
  [
    [
      "authoring","P1","W0","W0","canonical-wire-validator",
      "artifact-final-validation",
      [
        ["source-semantics","P1","frontend-semantics"],
        ["artifact-normalization","A0","artifact-normalizer"],
        ["artifact-final-validation","A1","artifact-final-validator"],
        ["canonical-wire","W0","canonical-wire-validator"],
        ["nix-construction","N0","nix-construction-validator"]
      ]
    ],
    [
      "artifact-normalization","A0","W0","W0","canonical-wire-validator",
      "artifact-final-validation",
      [
        ["artifact-normalization","A0","artifact-normalizer"],
        ["artifact-final-validation","A1","artifact-final-validator"],
        ["canonical-wire","W0","canonical-wire-validator"],
        ["nix-construction","N0","nix-construction-validator"]
      ]
    ],
    [
      "frontend-boundary","W0","W0","W0","canonical-wire-validator",
      "strict-wire-decode",
      [
        ["frontend-output-validation","W0","frontend-wire-adapter"],
        ["strict-wire-decode","W0","canonical-wire-decoder"],
        ["artifact-semantic-replay","W0","artifact-semantic-validator"],
        ["semantic-identity-comparison","W0","artifact-identity-validator"],
        ["canonical-wire","W0","canonical-wire-validator"],
        ["nix-handle-validation","N0","nix-construction-validator"]
      ]
    ],
    [
      "raw-wire","W0","W0","W0","canonical-wire-validator",
      "strict-wire-decode",
      [
        ["strict-wire-decode","W0","canonical-wire-decoder"],
        ["artifact-semantic-replay","W0","artifact-semantic-validator"],
        ["semantic-identity-comparison","W0","artifact-identity-validator"],
        ["canonical-wire","W0","canonical-wire-validator"],
        ["nix-handle-validation","N0","nix-construction-validator"]
      ]
    ],
    [
      "schema-migration","W0","W0","W0","schema-migration-validator",
      "strict-wire-decode",
      [
        ["strict-wire-decode","W0","canonical-wire-decoder"],
        ["schema-migration","W0","schema-migration-validator"],
        ["artifact-semantic-replay","W0","artifact-semantic-validator"],
        ["semantic-identity-comparison","W0","artifact-identity-validator"],
        ["canonical-wire","W0","canonical-wire-validator"],
        ["nix-handle-validation","N0","nix-construction-validator"]
      ]
    ],
    [
      "artifact-native","A1","N0","N0","nix-construction-validator",
      "artifact-final-validation",
      [
        ["artifact-final-validation","A1","artifact-final-validator"],
        ["canonical-wire","W0","canonical-wire-validator"],
        ["nix-construction","N0","nix-construction-validator"]
      ]
    ],
    [
      "typed-handle","A1","N0","N0","nix-handle-registry-resolver",
      "artifact-final-validation",
      [
        ["artifact-final-validation","A1","artifact-final-validator"],
        ["canonical-wire","W0","canonical-wire-validator"],
        ["nix-handle-registry","N0","nix-handle-registry-resolver"]
      ]
    ],
    [
      "target-native","A1","N1","N1","target-member-builder",
      "artifact-final-validation",
      [
        ["artifact-final-validation","A1","artifact-final-validator"],
        ["canonical-wire","W0","canonical-wire-validator"],
        ["packet-c-profile-contract","N0","nix-construction-validator"],
        ["packet-c-realization","N1","target-member-builder"]
      ]
    ],
    [
      "unsafe-opaque","A1","A1","A1","artifact-final-validator",
      "artifact-final-validation",
      [
        ["artifact-final-validation","A1","artifact-final-validator"]
      ]
    ],
    [
      "create","C0","D0","C0","creation-resolver",
      "creation-resolution",
      [
        ["creation-resolution","C0","creation-resolver"],
        ["core-api","C0","core-api-request-validator"],
        ["operator-admission","O0","operator-admission"],
        ["host-provider-preflight","H0","host-provider-preflight"],
        ["driver-preparation","D0","driver-preparation"]
      ]
    ],
    [
      "operator","O0","D0","O0","operator-admission",
      "operator-admission",
      [
        ["operator-admission","O0","operator-admission"],
        ["host-provider-preflight","H0","host-provider-preflight"],
        ["driver-preparation","D0","driver-preparation"]
      ]
    ],
    [
      "service","S0","S0","S0","managed-service-compiler",
      "service-reconciliation",
      [
        ["service-reconciliation","S0","managed-service-compiler"],
        ["core-api","S0","core-api-request-builder"]
      ]
    ],
    [
      "live","L0","L0","L0","live-operation-validator",
      "live-operation-validation",
      [
        ["live-operation-validation","L0","live-operation-validator"]
      ]
    ],
    [
      "exec","E0","E0","E0","exec-validator",
      "exec-validation",
      [
        ["exec-validation","E0","exec-validator"]
      ]
    ],
    [
      "framework","F0","F0","F0","framework-adapter-validator",
      "framework-translation",
      [
        ["framework-translation","F0","framework-adapter-validator"],
        ["core-api","F0","core-api-request-builder"]
      ]
    ],
    [
      "provider-admission","O0","H0","H0","remote-provider-adapter",
      "operator-admission",
      [
        ["operator-admission","O0","operator-admission"],
        ["host-provider-preflight","H0","remote-provider-adapter"]
      ]
    ],
    [
      "provider-operation","H0","D0","D0","driver-preparation",
      "host-provider-preflight",
      [
        ["host-provider-preflight","H0","remote-provider-adapter"],
        ["driver-preparation","D0","driver-preparation"]
      ]
    ],
    [
      "manifest-load","C0","C0","C0","artifact-manifest-loader",
      "manifest-load",
      [
        ["manifest-load","C0","artifact-manifest-loader"],
        ["creation-resolution","C0","creation-resolver"]
      ]
    ],
    [
      "target-lowering","N0","N1","N0","nix-construction-validator",
      "packet-c-contract-rederivation",
      [
        ["packet-c-contract-rederivation","N0","nix-construction-validator"],
        ["packet-c-target-build","N1","target-member-builder"],
        ["packet-c-member-manifest-verification","N1","target-member-verifier"],
        ["manifest-load","C0","artifact-manifest-loader"]
      ]
    ],
    [
      "provider-build","N0","N1","N1","target-member-verifier",
      "provider-build-result",
      [
        ["nix-construction","N0","nix-construction-validator"],
        ["provider-build-result","N1","provider-build-adapter"],
        ["packet-c-realization","N1","target-member-verifier"]
      ]
    ],
    [
      "provider-result","N1","N1","N1","target-member-verifier",
      "provider-build-result",
      [
        ["provider-build-result","N1","provider-build-adapter"],
        ["packet-c-realization","N1","target-member-verifier"]
      ]
    ],
    [
      "operator-source","P1","OC0","OC0","operator-configuration-validator",
      "operator-configuration-validation",
      [
        ["operator-source-semantics","P1","nix-source-semantics"],
        ["operator-dependency-closure","OC0","operator-configuration-dependency-resolver"],
        ["operator-precedence-and-provenance","OC0","operator-configuration-composer"],
        ["operator-configuration-validation","OC0","operator-configuration-validator"]
      ]
    ],
    [
      "managed-service-source","P1","MS0","MS0","managed-service-definition-validator",
      "managed-service-definition-validation",
      [
        ["managed-service-source-semantics","P1","nix-source-semantics"],
        ["managed-service-dependency-closure","MS0","managed-service-definition-dependency-resolver"],
        ["managed-service-precedence-and-provenance","MS0","managed-service-definition-composer"],
        ["managed-service-definition-validation","MS0","managed-service-definition-validator"]
      ]
    ],
    [
      "resolved-driver-handoff","C0","D0","D0","driver-entry-validator",
      "private-resolved-creation",
      [
        ["private-resolved-creation","C0","creation-resolver"],
        ["private-operator-admission","O0","operator-admission"],
        ["private-host-provider-preflight","H0","host-provider-preflight"],
        ["driver-entry-validation","D0","driver-entry-validator"]
      ]
    ],
    [
      "serialized-resolved-reentry","RW0","D0","D0","driver-entry-validator",
      "resolved-reentry-wire-validation",
      [
        ["resolved-reentry-wire-validation","RW0","resolved-reentry-wire-validator"],
        ["fresh-private-stage-construction","C0","resolved-reentry-stage-constructor"],
        ["current-operator-admission","O0","operator-admission"],
        ["current-host-provider-reacquisition","H0","host-provider-preflight"],
        ["driver-entry-validation","D0","driver-entry-validator"]
      ]
    ],
    [
      "generated-runtime-configuration","D0","D0","D0","runtime-config-validator",
      "generated-runtime-configuration-validation",
      [
        ["total-runtime-configuration-generation","D0","runtime-config-generator"],
        ["generated-runtime-configuration-validation","D0","runtime-config-validator"]
      ]
    ],
    [
      "direct-driver-invocation","D0","D0","D0","driver-entry-validator",
      "driver-entry-rejection",
      [
        ["driver-entry-rejection","D0","driver-entry-validator"]
      ]
    ],
    [
      "raw-runtime-config-input","D0","D0","D0","driver-entry-validator",
      "driver-entry-rejection",
      [
        ["driver-entry-rejection","D0","driver-entry-validator"]
      ]
    ]
  ];

def exact_template_contract($name):
  first(
    exact_template_contract_tuples[] |
    select(.[0] == $name) |
    . as $tuple |
    {
      "firstSoundPhase": $tuple[1],
      "rejectionDeadline": $tuple[2],
      "authority": {
        "phase": $tuple[3],
        "component": $tuple[4]
      },
      "rejectedForeignOwnerAt": $tuple[5],
      "boundaryChain": [
        $tuple[6][] |
        {
          "id": .[0],
          "phase": .[1],
          "component": .[2]
        }
      ]
    }
  ) // null;

def template_contract_projection($template):
  {
    "firstSoundPhase": $template.firstSoundPhase,
    "rejectionDeadline": $template.rejectionDeadline,
    "authority": $template.authority,
    "rejectedForeignOwnerAt": $template.rejectedForeignOwnerAt,
    "boundaryChain": $template.boundaryChain
  };

def exact_template_semantic_tuples:
  [
    ["authoring","Foreign-owned resource fields are absent from the Artifact authoring contract.",false,"preserve-only",["foreign-owned-fields","artifact-identity-minting","conformance-identity-minting"]],
    ["artifact-normalization","Profile expansion cannot author a foreign-owned resource.",false,"preserve-only",["foreign-owned-fields","support-claim-minting","conformance-identity-minting"]],
    ["frontend-boundary","Frontend claims are untrusted and cannot bypass strict decoding, complete Artifact semantic replay, identity comparison, or Nix-handle validation.",true,"preserve-only",["frontend-claim-authority","artifact-identity-minting","conformance-identity-minting"]],
    ["raw-wire","Raw wire values have no source-level authority and are accepted only after strict decoding, complete Artifact semantic replay, identity comparison, and Nix-handle validation.",true,"preserve-only",["source-claim-trust","artifact-identity-minting","conformance-identity-minting"]],
    ["schema-migration","Migration cannot invent fields or authority absent from the source schema and must replay the complete Artifact semantic validator before construction.",true,"preserve-only",["unknown-schema-authority","artifact-identity-minting","conformance-identity-minting"]],
    ["artifact-native","A scoped Artifact-native extension cannot author lifecycle, host, provider, support, or conformance state.",false,"preserve-only",["host-bindings","runtime-allocations","secrets","provider-objects","runtime-profile-selection","support-claims","conformance-claims"]],
    ["typed-handle","Only a typed registry reference crosses the portable boundary; arbitrary evaluator values do not.",false,"preserve-only",["arbitrary-evaluator-values","store-path-as-portable-identity","artifact-identity-minting","conformance-identity-minting"]],
    ["target-native","Target-native content is confined to a registered construction contract and re-enters every Packet C profile, identity, manifest, and realization check.",false,"preserve-only",["host-bindings","runtime-allocations","secrets","provider-objects","runtime-profile-selection","support-claims","conformance-claims"]],
    ["unsafe-opaque","Unregistered or semantically opaque extensions are rejected rather than weakening conformance.",true,"preserve-only",["opaque-authority","artifact-identity-minting","support-claim-minting","conformance-identity-minting"]],
    ["create","Create-owned values may select or narrow only within the immutable Artifact contract.",false,"preserve-only",["artifact-widening","built-content-identity","support-claim-minting","conformance-identity-minting"]],
    ["operator","Operator configuration binds implementation and placement without reinterpreting Artifact policy.",false,"preserve-only",["artifact-widening","built-content-identity","artifact-identity-minting","conformance-identity-minting"]],
    ["service","Managed-service configuration compiles to the Core API and never creates second lifecycle or Artifact semantics.",false,"preserve-only",["artifact-widening","core-api-bypass","artifact-identity-minting","conformance-identity-minting"]],
    ["live","A live operation acts only on an existing Sandbox within immutable bounds.",false,"preserve-only",["artifact-widening","creation-state-authority","artifact-identity-minting","conformance-identity-minting"]],
    ["exec","Exec input owns one Process and can only narrow the existing Sandbox boundary.",false,"preserve-only",["artifact-widening","sandbox-boundary-widening","artifact-identity-minting","conformance-identity-minting"]],
    ["framework","Framework and CLI adapters translate lifecycle requests and cannot author Artifact or runtime policy.",false,"preserve-only",["artifact-widening","runtime-policy-authority","artifact-identity-minting","conformance-identity-minting"]],
    ["provider-admission","Provider inputs are untrusted transport or construction data and cannot redefine portable semantics.",true,"preserve-only",["provider-default-authority","provider-reference-as-identity","artifact-identity-minting","conformance-identity-minting"]],
    ["provider-operation","Provider operations and cache results are untrusted and revalidated before driver mutation.",true,"preserve-only",["provider-claim-trust","backend-default-authority","artifact-identity-minting","conformance-identity-minting"]],
    ["manifest-load","Built manifests and members are untrusted until identity, profile, and construction evidence are verified.",true,"preserve-only",["manifest-claim-trust","provider-reference-as-identity","artifact-identity-minting","conformance-identity-minting"]],
    ["target-lowering","Target lowering re-derives Packet C from the validated Artifact, builds the member, independently verifies member and manifest identity, then revalidates at load.",true,"preserve-only",["target-default-authority","semantic-weakening","artifact-identity-minting","conformance-identity-minting"]],
    ["provider-build","Provider construction and caches are untrusted optimizations whose output identity and equivalence evidence are independently verified by the product.",true,"preserve-only",["provider-default-authority","provider-reference-as-identity","artifact-identity-minting","conformance-identity-minting"]],
    ["provider-result","A provider result has no authority until the product verifier independently checks output identity, provenance, and equivalence evidence.",true,"preserve-only",["provider-claim-trust","provider-reference-as-identity","artifact-identity-minting","conformance-identity-minting"]],
    ["operator-source","Operator Configuration source semantics can author only operator-owned configuration and cannot author Artifact, Create, Service, live, Exec, framework, or runtime facts.",false,"preserve-only",["artifact-facts","create-facts","service-facts","live-facts","exec-facts","framework-facts","runtime-facts","artifact-identity-minting","conformance-identity-minting"]],
    ["managed-service-source","Managed-Service Definition source semantics can author only service-owned desired state and cannot author Artifact, Create, Operator, live, Exec, framework, or runtime facts.",false,"preserve-only",["artifact-facts","create-facts","operator-facts","live-facts","exec-facts","framework-facts","runtime-facts","artifact-identity-minting","conformance-identity-minting"]],
    ["resolved-driver-handoff","Only product-owned private resolved stages advance to PreparedLaunch; copied or foreign record shapes cannot enter the chain.",false,"extend-private-identity",["forgeable-validated-record","earlier-identity-rewrite","backend-default-authority","conformance-identity-minting"]],
    ["serialized-resolved-reentry","Serialized resolved state is wholly untrusted and cannot mint a private stage without strict decoding, exact replay, and current H0 reacquisition.",true,"rederive-private-identity",["authenticated-bytes-as-semantic-authority","serialized-handle-authority","private-stage-minting","backend-default-authority"]],
    ["generated-runtime-configuration","Backend configuration is total D0 output from PreparedLaunch, suppresses undeclared defaults, and is validated as a closed generated value.",true,"preserve-only",["external-runtime-config-input","backend-default-authority","unchecked-raw-arguments","conformance-identity-minting"]],
    ["direct-driver-invocation","Direct driver invocation has no admitted value and is rejected before external mutation.",false,"no-admitted-value",["all-caller-values","forgeable-prepared-launch","external-mutation","backend-default-authority"]],
    ["raw-runtime-config-input","Raw runtime configuration has no admitted value and is rejected before external mutation.",false,"no-admitted-value",["all-raw-values","forgeable-generated-configuration","external-mutation","backend-default-authority"]]
  ];

def exact_template_semantics($name):
  first(
    exact_template_semantic_tuples[] |
    select(.[0] == $name) |
    {
      "structuralExclusion": .[1],
      "fullRevalidation": .[2],
      "identityAuthority": .[3],
      "ownershipExclusions": .[4]
    }
  ) // null;

def complete_template_contract($name):
  exact_template_contract($name) + exact_template_semantics($name);

def complete_template_projection($template):
  template_contract_projection($template) + {
    "structuralExclusion": $template.structuralExclusion,
    "fullRevalidation": $template.fullRevalidation,
    "identityAuthority": $template.identityAuthority,
    "ownershipExclusions": $template.ownershipExclusions
  };

def expected_paths_registry_sha256:
  "65322c7c30f4c75222a36793b8d1b877fa5813df4d1c83f236bb18884c364a65";

def expected_case_contracts_sha256:
  "955c3dd8c03927be6876c58b2c3c67210f1fc0710ecf5f5ea2a4a2c59bc3f5b0";

# Digest pins detect accidental drift and impose review friction. They do not
# authorize inputs that fail the semantic relationship checks below.
def expected_invariant_registry_sha256:
  "9109aff5f44aeebe9be5cd9c967f06d42cad6f766b6acb89d9510f22c2656917";

def nonempty_string:
  type == "string" and (gsub("^\\s+|\\s+$"; "") | length > 0);

def nonempty_string_array:
  type == "array" and length > 0 and all(.[]; nonempty_string);

def string_array:
  type == "array" and all(.[]; nonempty_string);

def unknown_keys($object; $allowed):
  if ($object | type) == "object"
  then [
    ($object | keys[]) as $key |
    select(($allowed | index($key)) == null) |
    $key
  ]
  else ["<not-an-object>"]
  end;

def duplicate_values($values):
  [
    ($values // []) |
    sort |
    group_by(.)[] |
    select(length > 1) |
    .[0]
  ];

def same_set($left; $right):
  ($left | sort) == ($right | sort);

def path_entry($id):
  first($paths[0].paths[]? | select(.id == $id)) // null;

def contract_entry($id):
  first($caseContracts[0].entries[]? | select(.pathId == $id)) // null;

def contract_template($entry):
  $caseContracts[0].contractTemplates[($entry.contractTemplate // "")] // null;

def registry_ids:
  [$registry[0].invariants[].id];

def registry_composition_path_ids:
  [$registry[0].invariants[].compositionPaths[]] | unique;

def portable_artifact_invariant_ids:
  [
    $registry[0].invariants[] |
    select(
      .owner == "artifact" and
      (.firstSoundPhase as $phase |
       (["P0","P1","A0","A1","W0"] | index($phase)) != null)
    ) |
    .id
  ];

def packet_c_target_realization_invariant_ids:
  [
    $targetRealization[0].rules[] |
    (
      .fieldTraceability[]?.invariants[]?,
      .cases[]?.invariants[]?
    )
  ] | unique;

def registry_owner($id):
  first($registry[0].invariants[] | select(.id == $id) | .owner) // null;

def registry_invariant($id):
  first($registry[0].invariants[] | select(.id == $id)) // null;

def registry_authority($id):
  first(
    registry_invariant($id).enforcementHooks[] |
    select(.role == "authoritative") |
    {phase, component}
  ) // null;

def classification_code($path; $id):
  ($caseContracts[0].reviewedInvariantIds | index($id)) as $index |
  $caseContracts[0].classificationVectorsByPath[$path][$index:$index + 1];

def classification_contract($code):
  $caseContracts[0].classificationCodeContract[$code] // null;

def classification_effect($code):
  classification_contract($code) as $contract |
  if ($contract | type) == "string"
  then $contract | split(":")[0]
  else null
  end;

def classification_exclusion($code):
  classification_contract($code) as $contract |
  if classification_effect($code) == "no-authority" and
     ($contract | type) == "string"
  then $contract | split(":")[1]
  else "active-path-contract"
  end;

def requires_conditional_native_handle($id; $code):
  ($caseContracts[0].conditionalNativeHandleContract.invariantIds | index($id)) != null and
  (
    $caseContracts[0].conditionalNativeHandleContract.allowedEffects |
    index(classification_effect($code))
  ) != null;

def legacy_case_path_id($id):
  $id;

def classified_invariant_ids($path; $code):
  [
    range(0; ($caseContracts[0].reviewedInvariantIds | length)) as $index |
    select(
      ($caseContracts[0].classificationVectorsByPath[$path] // "")[$index:$index + 1] ==
        $code
    ) |
    $caseContracts[0].reviewedInvariantIds[$index]
  ];

def phase_edges:
  {
    "P0": ["P1"],
    "P1": ["A0", "OC0", "MS0"],
    "A0": ["A1"],
    "A1": ["W0"],
    "W0": ["N0"],
    "N0": ["N1"],
    "N1": ["C0"],
    "F0": ["C0", "L0", "E0", "T0"],
    "OC0": ["O0"],
    "MS0": ["S0"],
    "S0": ["C0", "L0", "E0", "T0"],
    "RW0": ["C0"],
    "C0": ["O0"],
    "O0": ["H0"],
    "H0": ["D0"],
    "D0": ["R0"],
    "R0": ["R1"],
    "R1": ["L0", "E0", "T0"],
    "L0": ["L1"],
    "L1": ["T0"],
    "E0": ["E1"],
    "E1": ["T0"]
  };

def phase_ids:
  [
    (phase_edges | keys[]),
    phase_edges[][]
  ] | unique;

# Visited-set-guarded transitive closure. The guard is load-bearing, not an
# optimization. This was previously unguarded recursion, which meant the
# acyclicity assertion below could never fire as a diagnostic: because jq's
# `and` short-circuits, a single-copy edit to phase_edges was caught by the
# literal comparison, while a coordinated two-copy edit passed that comparison
# and then exhausted memory inside the acyclicity check itself (verified under
# jq 1.8.1: a graph containing L1 -> D0 aborts with "cannot allocate memory").
# It was a true statement structurally incapable of diagnosing its own subject.
# $seen grows monotonically and is bounded by the node count, so the traversal
# is total on any graph, and a node reachable from itself now appears in its own
# descendant set — which is exactly what the acyclicity assertion tests for.
def phase_closure($frontier; $seen):
  if ($frontier | length) == 0
  then $seen
  else
    ($frontier[0]) as $node |
    ($frontier[1:]) as $rest |
    if ($seen | index($node)) != null
    then phase_closure($rest; $seen)
    else phase_closure(($rest + (phase_edges[$node] // [])); ($seen + [$node]))
    end
  end;

def descendants($phase):
  phase_closure((phase_edges[$phase] // []); []) | unique;

def reachable($from; $to):
  (phase_ids | index($from)) != null and
  (phase_ids | index($to)) != null and
  (
    $from == $to or
    (descendants($from) | index($to)) != null
  );

def authority_step_id($authority):
  (
    $authority.component |
    ascii_downcase |
    gsub("[^a-z0-9]+"; "-") |
    gsub("^-|-$"; "")
  ) as $component |
  "invariant-authority-\($authority.phase | ascii_downcase)-\($component)";

def with_authority_by_reachability($chain; $authority):
  if any($chain[];
    .phase == $authority.phase and .component == $authority.component)
  then $chain
  else
    {
      "id": authority_step_id($authority),
      "phase": $authority.phase,
      "component": $authority.component
    } as $authority_step |
    (
      [
        $chain | to_entries[] |
        select(
          .value.phase != $authority.phase and
          reachable($authority.phase; .value.phase)
        ) |
        .key
      ] | min
    ) as $first_descendant |
    if $first_descendant == null
    then $chain + [$authority_step]
    else
      $chain[0:$first_descendant] +
      [$authority_step] +
      $chain[$first_descendant:]
    end
  end;

def expected_active_chain($template; $first; $deadline; $authority):
  (
    [
      $template.boundaryChain[] |
      select(reachable($first; .phase) and reachable(.phase; $deadline))
    ]
  ) as $retained |
  with_authority_by_reachability($retained; $authority);

def with_authority($chain; $authority):
  with_authority_by_reachability($chain; $authority);

def boundary_chain_is_reachable($chain):
  ($chain | type) == "array" and
  all(
    range(0; (($chain | length) - 1));
    . as $index |
    reachable($chain[$index].phase; $chain[$index + 1].phase)
  );

def ingress_authority($entry; $template):
  $caseContracts[0].boundaryIngressCompleteAuthoritiesByTemplate[
    $entry.contractTemplate
  ] // $template.authority;

def expected_ingress_chain($template; $authority):
  with_authority(
    [
      $template.boundaryChain[] |
      select(reachable(.phase; $authority.phase))
    ];
    $authority
  );

def expected_continuation_chain($template; $deadline; $authority):
  with_authority(
    [
      $template.boundaryChain[] |
      select(reachable(.phase; $deadline))
    ];
    $authority
  );

def expected_registry_phase_contract($template; $invariant):
  registry_authority($invariant.id) as $authority |
  {
    "firstSoundPhase": $invariant.firstSoundPhase,
    "rejectionDeadline": $invariant.rejectionDeadline,
    "authority": $authority,
    "boundaryChain": expected_active_chain(
      $template;
      $invariant.firstSoundPhase;
      $invariant.rejectionDeadline;
      $authority
    )
  };

def expected_ingress_phase_contract($template; $authority):
  {
    "firstSoundPhase": $authority.phase,
    "rejectionDeadline": $authority.phase,
    "authority": $authority,
    "boundaryChain": expected_ingress_chain($template; $authority)
  };

def rejecting_boundary_authority($template):
  first(
    $template.boundaryChain[]? |
    select(.id == $template.rejectedForeignOwnerAt) |
    {phase, component}
  ) // $template.authority;

def expected_boundary_input_phase_contract($template; $entry; $invariant):
  ingress_authority($entry; $template) as $ingress_authority |
  (
    $invariant.rejectionDeadline != $template.firstSoundPhase and
    reachable($invariant.rejectionDeadline; $template.firstSoundPhase)
  ) as $completed_strictly_before_ingress |
  if $completed_strictly_before_ingress
  then expected_ingress_phase_contract($template; $ingress_authority)
  else
    registry_authority($invariant.id) as $authority |
    {
      "firstSoundPhase":
        (if reachable($invariant.firstSoundPhase; $template.firstSoundPhase)
         then $template.firstSoundPhase
         else $invariant.firstSoundPhase
         end),
      "rejectionDeadline": $invariant.rejectionDeadline,
      "authority": $authority,
      "boundaryChain": expected_continuation_chain(
        $template;
        $invariant.rejectionDeadline;
        $authority
      )
    }
  end;

def expected_no_authority_phase_contract($template; $entry; $invariant; $code):
  if $code == "H"
  then expected_registry_phase_contract($template; $invariant)
  else expected_ingress_phase_contract(
    $template;
    rejecting_boundary_authority($template)
  )
  end;

def expected_cell_phase_contract($template; $entry; $invariant; $code):
  classification_effect($code) as $effect |
  if $effect == "boundary-input"
  then expected_boundary_input_phase_contract($template; $entry; $invariant)
  elif $effect == "no-authority"
  then expected_no_authority_phase_contract($template; $entry; $invariant; $code)
  else expected_registry_phase_contract($template; $invariant)
  end;

def expected_resource_source_contract($id):
  (
    if $id | startswith("operator-configuration-")
    then {
      "sourceOwner": "operator",
      "reachableOwners": ["operator"],
      "firstBoundary": "operator-configuration-source-completion",
      "finalBoundary": "operator-configuration-validation"
    }
    else {
      "sourceOwner": "service",
      "reachableOwners": ["service"],
      "firstBoundary": "managed-service-definition-source-completion",
      "finalBoundary": "managed-service-definition-validation"
    }
    end
  ) +
  {
    "allowedEffects": (
      if $id | endswith("-authoring") or endswith("-imports")
      then ["may-contribute", "no-authority"]
      elif $id | endswith("-precedence")
      then ["may-contribute", "may-select", "may-narrow", "no-authority"]
      elif $id | endswith("-refinement")
      then ["may-select", "may-narrow", "no-authority"]
      else ["no-authority"]
      end
    ),
    "targetApplicability": ["portable"],
    "delegatedPackets": ["E", "F"]
  };

def expected_driver_contract($id):
  {
    "resolved-driver-handoff": {
      "sourceOwner": "runtime",
      "reachableOwners": ["create", "operator", "runtime"],
      "allowedEffects": ["may-contribute", "may-narrow", "no-authority"],
      "firstBoundary": "creation-resolution",
      "finalBoundary": "driver-entry-validation"
    },
    "serialized-resolved-reentry": {
      "sourceOwner": "runtime",
      "reachableOwners": ["create", "operator", "runtime"],
      "allowedEffects": ["boundary-input", "no-authority"],
      "firstBoundary": "resolved-reentry-wire-validation",
      "finalBoundary": "driver-entry-validation"
    },
    "generated-runtime-configuration": {
      "sourceOwner": "runtime",
      "reachableOwners": ["runtime"],
      "allowedEffects": ["boundary-input", "no-authority"],
      "firstBoundary": "driver-entry-validation",
      "finalBoundary": "driver-entry-validation"
    },
    "direct-driver-invocation": {
      "sourceOwner": "runtime",
      "reachableOwners": [],
      "allowedEffects": ["no-authority"],
      "firstBoundary": "driver-entry-validation",
      "finalBoundary": "driver-entry-validation"
    },
    "raw-runtime-config-input": {
      "sourceOwner": "runtime",
      "reachableOwners": [],
      "allowedEffects": ["no-authority"],
      "firstBoundary": "driver-entry-validation",
      "finalBoundary": "driver-entry-validation"
    }
  }[$id] +
  {
    "targetApplicability": ["all-packet-c-profiles"],
    "delegatedPackets": ["E", "F"]
  };

# Byte-identical to the definition carried by every other ledger validator
# (validate-registry.jq, validate-surface-coverage.jq,
# validate-artifact-field-review.jq, validate-target-realization.jq,
# validate-provider-contracts.jq). This validator was the only one without it,
# which no comparison of the copies that existed could detect.
#
# Note for Packet E authors: this matches ^UNKNOWN$ case-insensitively, so the
# bare token "unknown" is rejected as placeholder content. Packet E's locked
# vocabulary namespaces it (state-unknown, outcome-unknown) rather than
# weakening this rule in one validator.
def placeholder_strings:
  [
    .. |
    strings |
    select(test("^(TBD|TODO|FIXME)(:|\\b|$)|^UNKNOWN$"; "i"))
  ];

def path_errors:
  [
    if ($paths[0] | placeholder_strings | length) == 0
    then empty
    else "composition path registry contains placeholder content"
    end,

    if ($caseContracts[0] | placeholder_strings | length) == 0
    then empty
    else "composition case contracts contain placeholder content"
    end,

    if $pathsRegistrySha256 == expected_paths_registry_sha256
    then empty
    else "path registry SHA-256 must equal the independently reviewed validator pin"
    end,
    (
      unknown_keys(
        $paths[0];
        [
          "reviewVersion",
          "packet",
          "status",
          "reviewedPathCount",
          "definition",
          "textAuthority",
          "frontendSyntaxContract",
          "reopenPolicy",
          "registryPathAliases",
          "paths"
        ]
      )[] as $key |
      "unknown composition path registry key: \($key)"
    ),
    if $paths[0].reviewVersion == 1 and
       $paths[0].packet == "D" and
       (path_registry_statuses | index($paths[0].status)) != null
    then empty
    else "composition path registry header must identify candidate or reviewed Packet D version 1"
    end,
    if $paths[0].reviewedPathCount == 54 and
       $paths[0].reviewedPathCount == ($paths[0].paths | length)
    then empty
    else "reviewedPathCount must equal the exact 54-path registry length"
    end,
    if phase_edges == {
         "P0": ["P1"],
         "P1": ["A0", "OC0", "MS0"],
         "A0": ["A1"],
         "A1": ["W0"],
         "W0": ["N0"],
         "N0": ["N1"],
         "N1": ["C0"],
         "F0": ["C0", "L0", "E0", "T0"],
         "OC0": ["O0"],
         "MS0": ["S0"],
         "S0": ["C0", "L0", "E0", "T0"],
         "RW0": ["C0"],
         "C0": ["O0"],
         "O0": ["H0"],
         "H0": ["D0"],
         "D0": ["R0"],
         "R0": ["R1"],
         "R1": ["L0", "E0", "T0"],
         "L0": ["L1"],
         "L1": ["T0"],
         "E0": ["E1"],
         "E1": ["T0"]
       } and
       all(phase_edges | keys[];
         . as $phase |
         (descendants($phase) | index($phase)) == null
       ) and
       (reachable("ZZ"; "ZZ") | not)
    then empty
    else "phase graph must equal the approved acyclic OC0/MS0/RW0 reachability graph"
    end,
    if [$paths[0].paths[].id] | same_set(.; locked_path_ids)
    then empty
    else "path IDs must equal the locked 54-path universe"
    end,
    (
      duplicate_values([$paths[0].paths[].id])[] |
      "duplicate composition path id: \(.)"
    ),
    if [exact_path_contract_tuples[][0]] == locked_path_ids and
       all($paths[0].paths[];
         . as $path |
         exact_path_contract($path.id) as $expected |
         contract_entry($path.id) as $entry |
         $expected != null and
         $path.sourceOwner == $expected.sourceOwner and
         $path.reachableOwners == $expected.reachableOwners and
         $entry != null and
         $entry.sourceOwner == $expected.sourceOwner and
         $entry.reachableOwners == $expected.reachableOwners and
         $entry.contractTemplate == $expected.contractTemplate
       )
    then empty
    else "path ownership and contract template must equal the exact validator-owned path contract"
    end,
    if [exact_path_semantic_tuples[][0]] == locked_path_ids and
       all($paths[0].paths[];
         . as $path |
         contract_entry($path.id) as $entry |
         (exact_path_contract($path.id) +
          exact_path_semantics($path.id)) as $expected |
         $entry != null and
         $expected != null and
         complete_path_projection($path; $entry) == $expected
       )
    then empty
    else "path semantics and attached contract template must equal the exact validator-owned path contract"
    end,
    if ([exact_path_semantic_tuples[][9][]] | length) == 74 and
       ([exact_path_semantic_tuples[][0]] | unique | length) == 54 and
       all($paths[0].paths[];
         . as $path |
         exact_path_semantics($path.id) as $expected |
         $expected != null and
         [
           $path.frontendMappings[] |
           frontend_mapping_projection(.)
         ] == $expected.frontendMappings
       ) and
       ([ $paths[0].paths[].frontendMappings[] ] | length) == 74
    then empty
    else "frontend mappings must equal the exact validator-owned candidate, result, research-pin, and witness projection"
    end,
    if ($paths[0].registryPathAliases | type) == "object" and
       (($paths[0].registryPathAliases | keys) == registry_composition_path_ids)
    then empty
    else "registryPathAliases keys must equal the exact historical invariant composition-path vocabulary"
    end,
    (
      $paths[0].registryPathAliases | to_entries[] as $alias |
      if locked_path_ids | index($alias.value)
      then empty
      else "registryPathAliases has unknown generic path target: \($alias.key) -> \($alias.value)"
      end
    ),
    if (exact_registry_path_aliases | length) == 76 and
       $paths[0].registryPathAliases == exact_registry_path_aliases
    then empty
    else "registryPathAliases must equal the exact validator-owned 76-alias mapping"
    end,
    (
      $paths[0].paths[] as $path |
      (
        unknown_keys(
          $path;
          [
            "id",
            "category",
            "sourceOwner",
            "reachableOwners",
            "allowedEffects",
            "firstBoundary",
            "finalBoundary",
            "strongestBypassClass",
            "frontendMappings",
            "targetApplicability",
            "delegatedPackets"
          ]
        )[] as $key |
        "\($path.id // "<missing-path>"): unknown composition path key: \($key)"
      ),
      if categories | index($path.category)
      then empty
      else "\($path.id // "<missing-path>"): unknown path category"
      end,
      if owners | index($path.sourceOwner)
      then empty
      else "\($path.id // "<missing-path>"): unknown sourceOwner"
      end,
      if ($path.reachableOwners | string_array) and
         (
           ($path.reachableOwners | length) > 0 or
           (forbidden_driver_path_ids | index($path.id)) != null
         ) and
         all($path.reachableOwners[]; . as $owner | owners | index($owner))
      then empty
      else "\($path.id // "<missing-path>"): reachableOwners must use the closed owner universe"
      end,
      if ($path.allowedEffects | nonempty_string_array) and
         all($path.allowedEffects[]; . as $effect | effects | index($effect))
      then empty
      else "\($path.id // "<missing-path>"): allowedEffects must use the closed effect universe"
      end,
      if ($path.firstBoundary | nonempty_string) and
         ($path.finalBoundary | nonempty_string) and
         ($path.strongestBypassClass | nonempty_string)
      then empty
      else "\($path.id // "<missing-path>"): boundary and strongest-bypass fields must be non-empty"
      end,
      if ($path.targetApplicability | nonempty_string_array) and
         ($path.delegatedPackets | string_array)
      then empty
      else "\($path.id // "<missing-path>"): applicability and delegation must be structured"
      end,
      if (forbidden_driver_path_ids | index($path.id)) != null and
         $path.frontendMappings == []
      then empty
      elif ($path.frontendMappings | nonempty_string_array)
      then "\($path.id // "<missing-path>"): frontendMappings must be structured objects"
      elif ($path.frontendMappings | type) == "array" and
           ($path.frontendMappings | length > 0) and
           all($path.frontendMappings[];
             type == "object" and
             (keys | sort) == ["candidate","mechanism","researchPin","result","witness"] and
             (.candidate | nonempty_string) and
             (.mechanism | nonempty_string) and
             (.researchPin | nonempty_string) and
             (.witness | nonempty_string) and
             (.result as $result |
               ["supported","research-control-only","unsupported"] | index($result))
           )
      then empty
      else "\($path.id // "<missing-path>"): frontendMappings require exact candidate, mechanism, research pin, result, and witness"
      end,
      if (resource_source_path_ids | index($path.id)) != null
      then (
        expected_resource_source_contract($path.id) as $expected |
        if $path.category == "authoring" and
           $path.sourceOwner == $expected.sourceOwner and
           $path.reachableOwners == $expected.reachableOwners and
           $path.allowedEffects == $expected.allowedEffects and
           $path.firstBoundary == $expected.firstBoundary and
           $path.finalBoundary == $expected.finalBoundary and
           $path.targetApplicability == $expected.targetApplicability and
           $path.delegatedPackets == $expected.delegatedPackets and
           ($path.frontendMappings | length) == 1 and
           $path.frontendMappings[0].candidate == "nix" and
           $path.frontendMappings[0].researchPin ==
             "NIX-MODULE-SYSTEM-2026-07-24"
        then empty
        else "\($path.id): resource source path must equal the approved closed owner/effect/boundary/applicability contract"
        end
      )
      else empty
      end,
      if (driver_path_ids | index($path.id)) != null
      then (
        expected_driver_contract($path.id) as $expected |
        if $path.category == "downstream-boundary" and
           $path.sourceOwner == $expected.sourceOwner and
           $path.reachableOwners == $expected.reachableOwners and
           $path.allowedEffects == $expected.allowedEffects and
           $path.firstBoundary == $expected.firstBoundary and
           $path.finalBoundary == $expected.finalBoundary and
           $path.targetApplicability == $expected.targetApplicability and
           $path.delegatedPackets == $expected.delegatedPackets and
           (
             if (forbidden_driver_path_ids | index($path.id)) != null
             then $path.frontendMappings == []
             else ($path.frontendMappings | length) > 0
             end
           )
        then empty
        else "\($path.id): driver path must equal the approved closed owner/effect/boundary/applicability contract"
        end
      )
      else empty
      end,
      (
        legacy_case_path_id($path.id) as $case_path_id |
        contract_entry($case_path_id) as $entry |
        contract_template($entry) as $template |
        $caseContracts[0].classificationVectorsByPath[$case_path_id] as $vector |
        (
          if ($vector | type) != "string"
          then []
          else [
            range(0; ($vector | length)) as $index |
            classification_effect($vector[$index:$index + 1])
          ] | unique
          end
        ) as $classified_effects |
        if (
             (resource_source_path_ids | index($path.id)) != null or
             (driver_path_ids | index($path.id)) != null
           )
        then empty
        elif $entry != null and $template != null and $vector != null and
           $path.sourceOwner == $entry.sourceOwner and
           $path.reachableOwners == $entry.reachableOwners and
           same_set($path.allowedEffects; $classified_effects) and
           $path.firstBoundary == $template.boundaryChain[0].id and
           any($template.boundaryChain[]; .id == $path.finalBoundary) and
           $path.delegatedPackets == $entry.delegatedPackets
        then empty
        else "\($path.id // "<missing-path>"): path semantics must equal the independently pinned case contract"
        end
      )
    )
  ];

def case_contract_errors:
  [
    if $invariantRegistrySha256 == expected_invariant_registry_sha256
    then empty
    else "invariant registry SHA-256 must equal the independently reviewed validator pin"
    end,
    if $caseContractsSha256 == expected_case_contracts_sha256
    then empty
    else "case-contract catalog SHA-256 must equal the independently reviewed validator pin"
    end,
    (
      unknown_keys(
        $caseContracts[0];
        [
          "reviewVersion",
          "packet",
          "status",
          "authority",
          "structuralExclusionClasses",
          "requiredProfileIds",
          "nativeHandleContract",
          "conditionalNativeHandleContract",
          "delegatedConcernTaxonomy",
          "crossPathHandoffs",
          "targetApplicabilityProjection",
          "serializedResolvedReentryReplaySets",
          "driverTrustStateContracts",
          "classificationCodeContract",
          "phaseAuthorityPolicy",
          "boundaryIngressCompleteAuthoritiesByTemplate",
          "reviewedInvariantIds",
          "portableArtifactInvariantIds",
          "packetCTargetRealizationInvariantIds",
          "classificationVectorsByPath",
          "contractTemplates",
          "entries"
        ]
      )[] as $key |
      "unknown case-contract catalog key: \($key)"
    ),
    if $caseContracts[0].reviewVersion == 1 and
       $caseContracts[0].packet == "D" and
       $caseContracts[0].status == "candidate" and
       ($caseContracts[0].authority | nonempty_string) and
       ($caseContracts[0].authority | test("candidate")) and
       ($caseContracts[0].authority | test("reviewed") | not)
    then empty
    else "case-contract catalog must identify candidate-only Packet D version 1 authority"
    end,
    if $caseContracts[0].requiredProfileIds == required_profile_ids
    then empty
    else "case-contract Packet C profile IDs must equal the locked initial profiles"
    end,
    if ($caseContracts[0].structuralExclusionClasses | keys | sort) == [
         "active-path-contract",
         "foreign-owner",
         "hard-contract-nonwidening",
         "immutable-artifact-fact",
         "same-owner-stage-or-fact-class"
       ] and
       all($caseContracts[0].structuralExclusionClasses[];
         nonempty_string)
    then empty
    else "structuralExclusionClasses must pin active and all four no-authority exclusion classes"
    end,
    if $caseContracts[0].classificationCodeContract == {
         "C":"may-contribute",
         "N":"may-narrow",
         "S":"may-select",
         "B":"boundary-input",
         "F":"no-authority:foreign-owner",
         "L":"no-authority:same-owner-stage-or-fact-class",
         "I":"no-authority:immutable-artifact-fact",
         "H":"no-authority:hard-contract-nonwidening"
       }
    then empty
    else "classificationCodeContract must equal the closed reviewed code legend"
    end,
    if $caseContracts[0].phaseAuthorityPolicy == {
         "activeContributionSelectionRefinement":"registry-exact",
         "boundaryInput":"shift only invariants complete before ingress to the pinned ingress-complete authority; otherwise preserve the invariant first-sound phase, deadline, and authoritative hook while retaining the ingress continuation chain",
         "hardContractNoAuthority":"registry-exact",
         "otherNoAuthority":"use the exact phase and component of the contract template rejectedForeignOwnerAt boundary; this is the path-relative complete structural exclusion authority"
       }
    then empty
    else "phaseAuthorityPolicy must pin invariant-specific registry, ingress-shift, and no-authority timing"
    end,
    if $caseContracts[0].boundaryIngressCompleteAuthoritiesByTemplate == {
         "authoring":{"phase":"A1","component":"artifact-final-validator"},
         "frontend-boundary":{"phase":"W0","component":"canonical-wire-validator"},
         "raw-wire":{"phase":"W0","component":"canonical-wire-validator"},
         "schema-migration":{"phase":"W0","component":"canonical-wire-validator"},
         "create":{"phase":"C0","component":"creation-resolver"},
         "service":{"phase":"S0","component":"managed-service-compiler"},
         "framework":{"phase":"F0","component":"framework-adapter-validator"},
         "provider-admission":{"phase":"H0","component":"remote-provider-adapter"},
         "provider-operation":{"phase":"D0","component":"driver-preparation"},
         "manifest-load":{"phase":"C0","component":"artifact-manifest-loader"},
         "target-lowering":{"phase":"N0","component":"nix-construction-validator"},
         "provider-build":{"phase":"N0","component":"nix-construction-validator"},
         "provider-result":{"phase":"N1","component":"target-member-verifier"},
         "operator-source":{"phase":"OC0","component":"operator-configuration-validator"},
         "managed-service-source":{"phase":"MS0","component":"managed-service-definition-validator"},
         "resolved-driver-handoff":{"phase":"C0","component":"creation-resolver"},
         "serialized-resolved-reentry":{"phase":"RW0","component":"resolved-reentry-wire-validator"},
         "generated-runtime-configuration":{"phase":"D0","component":"runtime-config-validator"},
         "direct-driver-invocation":{"phase":"D0","component":"driver-entry-validator"},
         "raw-runtime-config-input":{"phase":"D0","component":"driver-entry-validator"}
       }
    then empty
    else "boundaryIngressCompleteAuthoritiesByTemplate must equal the independently reviewed ingress-complete validators"
    end,
    if $caseContracts[0].reviewedInvariantIds == registry_ids
    then empty
    else "reviewedInvariantIds must equal the exact current registry in order"
    end,
    if $caseContracts[0].portableArtifactInvariantIds ==
         portable_artifact_invariant_ids
    then empty
    else "portableArtifactInvariantIds must equal the exact pre-N0 Artifact semantic set"
    end,
    if $caseContracts[0].packetCTargetRealizationInvariantIds ==
         packet_c_target_realization_invariant_ids
    then empty
    else "packetCTargetRealizationInvariantIds must equal Packet C traceability and case invariants"
    end,
    if $caseContracts[0].nativeHandleContract == {
         "sourceGraphClosureDigest":"required-complete-pinned-transitive-closure",
         "registryNamespace":"required",
         "registryVersion":"required",
         "registryDigest":"required",
         "exportAttribute":"required",
         "nativeInterfaceVersion":"required",
         "targetSystem":"required",
         "affectedMember":"required",
         "expectedSemanticProjection":"required",
         "semanticIdentityComparison":"required-before-construction"
       } and
       $caseContracts[0].conditionalNativeHandleContract == {
         "invariantIds":["NAT-002","NAT-003"],
         "allowedEffects":["may-contribute","may-narrow","may-select","boundary-input"],
         "condition":{"kind":"when-native-handle-present"},
         "contract":$caseContracts[0].nativeHandleContract
       }
    then empty
    else "native handle contracts must preserve the canonical tuple and exact active-or-boundary conditional rule"
    end,
    if $caseContracts[0].delegatedConcernTaxonomy ==
         exact_delegated_concern_taxonomy
    then empty
    else "delegatedConcernTaxonomy must equal the exact Packet E/F concern expansion"
    end,
    if $caseContracts[0].crossPathHandoffs == exact_cross_path_handoffs and
       all($caseContracts[0].crossPathHandoffs[];
         . as $handoff |
         (locked_path_ids | index($handoff.fromPathId)) != null and
         (locked_path_ids | index($handoff.toPathId)) != null
       )
    then empty
    else "crossPathHandoffs must equal the six exact source/target path and boundary contracts"
    end,
    if $caseContracts[0].serializedResolvedReentryReplaySets ==
         {
           "builtMemberLoadInvariantIds":
             $caseContracts[0].packetCTargetRealizationInvariantIds,
           "resolvedStageInvariantIds":resolved_stage_replay_invariant_ids
         } and
       ($caseContracts[0].serializedResolvedReentryReplaySets.builtMemberLoadInvariantIds | length) == 89 and
       ($caseContracts[0].serializedResolvedReentryReplaySets.resolvedStageInvariantIds | length) == 30
    then empty
    else "serialized resolved reentry must preserve the exact independent 89 built/load and 30 resolved-stage replay sets"
    end,
    (
      serialized_reentry_boundary_input_ids as $expected |
      classified_invariant_ids("serialized-resolved-reentry"; "B") as $actual |
      if ($expected | length) == 107 and
         ($actual | length) == 107 and
         (duplicate_values($expected) | length) == 0 and
         (duplicate_values($actual) | length) == 0 and
         ($expected - $actual) == [] and
         ($actual - $expected) == [] and
         same_set($actual; $expected)
      then empty
      else "serialized resolved reentry boundary-input vector must equal the exact unique 89 + 30 + 3 replay set"
      end
    ),
    if $caseContracts[0].driverTrustStateContracts ==
         exact_driver_trust_state_contracts
    then empty
    else "driverTrustStateContracts must equal the five exact private, replayed, generated, and forbidden trust states"
    end,
    if ($caseContracts[0].targetApplicabilityProjection | keys) ==
         (locked_path_ids | sort) and
       all($paths[0].paths[];
         . as $path |
         $caseContracts[0].targetApplicabilityProjection[$path.id] ==
           projected_profiles($path.targetApplicability; required_profile_ids) and
         contract_entry($path.id).targetProfileIds ==
           projected_profiles($path.targetApplicability; required_profile_ids)
       ) and
       $caseContracts[0].targetApplicabilityProjection["native-guest-module"] ==
         ["microvm-firecracker-linux-v1","microvm-cloud-hypervisor-linux-v1"] and
       $caseContracts[0].targetApplicabilityProjection["oci-descriptor-transfer"] ==
         ["oci-linux-v1"]
    then empty
    else "target applicability must project semantically to the exact per-path Packet C profile IDs"
    end,
    if ($caseContracts[0].classificationVectorsByPath | keys) ==
         (locked_path_ids | sort)
    then empty
    else "classificationVectorsByPath must pin every locked path"
    end,
    (
      $caseContracts[0].classificationVectorsByPath | to_entries[] as $vector |
      if ($vector.value | type) == "string" and
         ($vector.value | length) == (registry_ids | length) and
         ($vector.value | test("^[CNSBFLIH]+$"))
      then empty
      else "\($vector.key): classification vector must classify every reviewed invariant exactly once"
      end
    ),
    if all($paths[0].paths[] as $path |
         $registry[0].invariants[] as $invariant |
         classification_effect(classification_code($path.id; $invariant.id)) as $effect |
         ($path.allowedEffects | index($effect)) != null and
         (
           if ($effect | active_effect)
           then ($path.reachableOwners | index($invariant.owner)) != null
           else true
           end
         )
       )
    then empty
    else "classification effects must be allowed by the path and active effects require a reachable invariant owner"
    end,
    (
      [
        "CRT-001","CRT-002","CRT-003","CRT-004","CRT-005","CRT-006",
        "LIVE-001","LIVE-002","LIVE-003","LIVE-004",
        "EXE-001","EXE-002","EXE-003","EXE-004","EXE-005","EXE-006","EXE-007"
      ] as $typed |
      if all($typed[];
           classification_code("direct-api"; .) == "B" and
           classification_code("framework-adapter"; .) == "B" and
           classification_code("cli-adapter"; .) == "B"
         )
      then empty
      else "direct API, framework, and CLI typed-request classifications must remain exact boundary-input peers"
      end
    ),
    if classification_code("artifact-ordinary-authoring"; "XRS-007") == "F" and
       classification_code("artifact-ordinary-authoring"; "XRS-008") == "F"
    then empty
    else "artifact ordinary authoring must forbid XRS-007 and XRS-008 foreign-owner authority"
    end,
    (
      {
        "operator-configuration-authoring":{"C":["XRS-006","XRS-008"],"N":[],"S":[]},
        "operator-configuration-imports":{"C":["XRS-006","XRS-008","OPS-003"],"N":[],"S":[]},
        "operator-configuration-precedence":{"C":["OPS-004"],"N":["OPS-002"],"S":["OPS-001","HOST-004"]},
        "operator-configuration-refinement":{"C":[],"N":["OPS-002"],"S":["OPS-001","HOST-004"]},
        "managed-service-definition-authoring":{"C":["SVC-001"],"N":[],"S":[]},
        "managed-service-definition-imports":{"C":["SVC-001","SVC-003"],"N":[],"S":[]},
        "managed-service-definition-precedence":{"C":["SVC-004"],"N":["SVC-001"],"S":[]},
        "managed-service-definition-refinement":{"C":[],"N":["SVC-001"],"S":[]}
      } as $active_by_source |
      if all($active_by_source | to_entries[];
           . as $source |
           all(["C","N","S"][];
             classified_invariant_ids($source.key; .) == $source.value[.]
           )
         ) and
         all([
           "operator-configuration-native-escape",
           "managed-service-definition-native-escape"
         ][];
           (. as $path |
            $caseContracts[0].classificationVectorsByPath[$path] |
            test("^[FLIH]{140}$"))
         )
      then empty
      else "resource source classifications must apply ownership before exact mechanism refinement and native escapes must have no authority"
      end
    ),
    if all(forbidden_driver_path_ids[];
         (. as $path |
          $caseContracts[0].classificationVectorsByPath[$path] |
          test("^[FLIH]{140}$"))
       )
    then empty
    else "forbidden direct/raw driver paths must classify all 140 invariants no-authority"
    end,
    (
      ($caseContracts[0].portableArtifactInvariantIds + ["NAT-002","NAT-003"] | unique) as $expected |
      [
        "frontend-output",
        "frontend-adaptation",
        "raw-wire-input",
        "schema-migration"
      ][] as $path |
      if same_set(classified_invariant_ids($path; "B"); $expected)
      then empty
      else "\($path): boundary-input set must equal the complete portable Artifact set plus typed-handle identity"
      end
    ),
    if same_set(
         classified_invariant_ids("target-lowering"; "B");
         $caseContracts[0].packetCTargetRealizationInvariantIds
       )
    then empty
    else "target-lowering boundary-input set must equal the exact Packet C realization union"
    end,
    (
      (
        $caseContracts[0].portableArtifactInvariantIds +
        ["IDT-002","MAN-001","MAN-002","MAN-003","MAN-004","MAN-005","MAN-006","TGT-003","NAT-002","NAT-003"] |
        unique
      ) as $expected |
      if same_set(classified_invariant_ids("built-artifact-load"; "B"); $expected) and
         $caseContracts[0].classificationVectorsByPath["built-artifact-load"] ==
           $caseContracts[0].classificationVectorsByPath["corrupted-manifest"]
      then empty
      else "built-artifact-load and corrupted-manifest must share the exact complete manifest/load boundary set"
      end
    ),
    (
      ["PRV-002","IDT-002","MAN-001","MAN-002","MAN-003","MAN-004","MAN-005","MAN-006","TGT-003"] as $expected |
      if same_set(classified_invariant_ids("provider-side-construction"; "B"); $expected) and
         $caseContracts[0].classificationVectorsByPath["provider-side-construction"] ==
           $caseContracts[0].classificationVectorsByPath["provider-build-cache"] and
         $caseContracts[0].classificationVectorsByPath["provider-side-construction"] ==
           $caseContracts[0].classificationVectorsByPath["corrupted-provider-build-result"]
      then empty
      else "provider construction, cache, and corrupted result must share the exact product-verifier boundary set"
      end
    ),
    if classification_code("artifact-native-language-escape"; "CMP-008") == "H" and
       classification_code("artifact-native-language-escape"; "STR-010") == "H" and
       classification_code("artifact-native-language-escape"; "CMP-009") == "H"
    then empty
    else "artifact-native-language-escape must remain reject-only for bypass and raw-value attempts"
    end,
    if classified_invariant_ids("artifact-strongest-override"; "S") == ["CMP-003"] and
       classified_invariant_ids("artifact-strongest-override"; "C") == ["CMP-010"] and
       all(["CMP-002","CMP-008","RES-002","LIF-001","XRS-019","XRS-020"][];
         classification_code("artifact-strongest-override"; .) == "H")
    then empty
    else "artifact-strongest-override may select only CMP-003, contribute only CMP-010 provenance, and cannot widen hard policy"
    end,
    if classification_code("native-guest-module"; "NAT-002") == "C" and
       classification_code("native-guest-module"; "NAT-003") == "C" and
       classification_code("native-guest-module"; "CMP-011") == "C"
    then empty
    else "native-guest-module must preserve complete registered handle identity and effect projection"
    end,
    if all(["native-guest-module","target-native-extension"][];
         contract_entry(.) as $entry |
         $entry.nativeHandleContract == $caseContracts[0].nativeHandleContract and
         ($entry.evidenceObligationIds | index("complete-native-handle-identity")) != null and
         ($entry.evidenceObligationIds | index("total-native-effect-projection")) != null and
         ($entry.testObligationIds | index("native-handle-completeness-invalid")) != null and
         ($entry.testObligationIds | index("native-effect-projection-incomplete-invalid")) != null
       )
    then empty
    else "native guest and target contracts must carry canonical identity and total-effect obligations"
    end,
    if classified_invariant_ids("direct-native-nix-value"; "C") |
         same_set(.; ["CMP-009","CMP-011","NAT-002","NAT-003"])
    then empty
    else "direct-native-nix-value contribution must equal the full native identity, dependency, and effect contract"
    end,
    if [$caseContracts[0].entries[].pathId] == locked_path_ids
    then empty
    else "case-contract path IDs must equal the exact ordered locked 54-path universe"
    end,
    (
      duplicate_values([$caseContracts[0].entries[].pathId])[] |
      "duplicate case-contract pathId: \(.)"
    ),
    (
      $caseContracts[0].contractTemplates | to_entries[] as $template |
      (
        unknown_keys(
          $template.value;
          [
            "firstSoundPhase",
            "rejectionDeadline",
            "authority",
            "boundaryChain",
            "structuralExclusion",
            "rejectedForeignOwnerAt",
            "fullRevalidation",
            "identityAuthority",
            "ownershipExclusions"
          ]
        )[] as $key |
        "\($template.key): unknown contract template key: \($key)"
      ),
      if all(
           [
             $template.value.firstSoundPhase,
             $template.value.rejectionDeadline,
             $template.value.authority.phase,
             $template.value.boundaryChain[]?.phase
           ][];
           . as $phase |
           (phase_ids | index($phase)) != null
         )
      then empty
      else "\($template.key): contract template phases must use the closed phase vocabulary"
      end,
      if ($template.value.firstSoundPhase | nonempty_string) and
         ($template.value.rejectionDeadline | nonempty_string) and
         reachable($template.value.firstSoundPhase; $template.value.rejectionDeadline)
      then empty
      else "\($template.key): rejectionDeadline must be reachable from firstSoundPhase"
      end,
      if ($template.value.boundaryChain | type) == "array" and
         ($template.value.boundaryChain | length > 0) and
         all($template.value.boundaryChain[];
           type == "object" and
           (keys | sort) == ["component","id","phase"] and
           (.id | nonempty_string) and
           (.phase | nonempty_string) and
           (.component | nonempty_string)
         )
      then empty
      else "\($template.key): boundaryChain must be non-empty and structured"
      end,
      if any($template.value.boundaryChain[];
        .phase == $template.value.authority.phase and
        .component == $template.value.authority.component)
      then empty
      else "\($template.key): authority must identify an exact boundaryChain step"
      end,
      if any($template.value.boundaryChain[];
        .id == $template.value.rejectedForeignOwnerAt)
      then empty
      else "\($template.key): rejectedForeignOwnerAt must identify an exact boundaryChain step"
      end
    ),
    if ([exact_template_contract_tuples[][0]] | sort) ==
         ($caseContracts[0].contractTemplates | keys) and
       all(exact_template_contract_tuples[];
         .[0] as $name |
         template_contract_projection(
           $caseContracts[0].contractTemplates[$name]
         ) == exact_template_contract($name)
       )
    then empty
    else "contract templates must equal the exact validator-owned phase, boundary, and rejecting-boundary contracts"
    end,
    if ([exact_template_semantic_tuples[][0]] | sort) ==
         ($caseContracts[0].contractTemplates | keys) and
       ([exact_template_semantic_tuples[][0]] | unique | length) == 28 and
       all(exact_template_semantic_tuples[];
         .[0] as $name |
         complete_template_projection(
           $caseContracts[0].contractTemplates[$name]
         ) == complete_template_contract($name)
       )
    then empty
    else "contract templates must equal the exact validator-owned complete semantic contracts"
    end,
    if all(exact_source_contract_templates | to_entries[];
         . as $source |
         $caseContracts[0].contractTemplates[$source.key] == $source.value
       )
    then empty
    else "source templates must equal the complete approved structured contracts"
    end,
    if all(exact_source_template_boundary_chains | to_entries[];
         . as $source |
         $caseContracts[0].contractTemplates[$source.key].boundaryChain ==
           $source.value
       )
    then empty
    else "source templates must equal the complete approved ordered boundary-step tuples"
    end,
    (
      {
        "operator-source":{
          "firstSoundPhase":"P1",
          "rejectionDeadline":"OC0",
          "authority":{"phase":"OC0","component":"operator-configuration-validator"},
          "phases":["P1","OC0","OC0","OC0"]
        },
        "managed-service-source":{
          "firstSoundPhase":"P1",
          "rejectionDeadline":"MS0",
          "authority":{"phase":"MS0","component":"managed-service-definition-validator"},
          "phases":["P1","MS0","MS0","MS0"]
        }
      } as $sources |
      if all($sources | to_entries[];
           . as $source |
           $caseContracts[0].contractTemplates[$source.key] as $template |
           $template.firstSoundPhase == $source.value.firstSoundPhase and
           $template.rejectionDeadline == $source.value.rejectionDeadline and
           $template.authority == $source.value.authority and
           [$template.boundaryChain[].phase] == $source.value.phases and
           ($template.boundaryChain[0].id | endswith("source-semantics")) and
           all($template.boundaryChain[];
             . as $step |
             (["A0","A1","W0","N0","N1"] | index($step.phase)) == null
           )
         ) and
         all(resource_source_path_ids[];
           contract_entry(.) as $entry |
           if startswith("operator-configuration-")
           then $entry.contractTemplate == "operator-source"
           else $entry.contractTemplate == "managed-service-source"
           end
         )
      then empty
      else "Operator and Managed-Service source templates must begin at P1 source semantics, end at their exact validator, and never traverse Artifact phases"
      end
    ),
    if all(exact_driver_contract_templates | to_entries[];
         . as $driver |
         $caseContracts[0].contractTemplates[$driver.key] == $driver.value
       )
    then empty
    else "driver templates must equal the complete approved structured contracts"
    end,
    if all(exact_driver_template_boundary_chains | to_entries[];
         . as $driver |
         $caseContracts[0].contractTemplates[$driver.key].boundaryChain ==
           $driver.value
       )
    then empty
    else "driver templates must equal the complete approved ordered boundary-step tuples"
    end,
    (
      {
        "resolved-driver-handoff":{"phases":["C0","O0","H0","D0"],"full":false,"identity":"extend-private-identity"},
        "serialized-resolved-reentry":{"phases":["RW0","C0","O0","H0","D0"],"full":true,"identity":"rederive-private-identity"},
        "generated-runtime-configuration":{"phases":["D0","D0"],"full":true,"identity":"preserve-only"},
        "direct-driver-invocation":{"phases":["D0"],"full":false,"identity":"no-admitted-value"},
        "raw-runtime-config-input":{"phases":["D0"],"full":false,"identity":"no-admitted-value"}
      } as $drivers |
      if all($drivers | to_entries[];
           . as $driver |
           $caseContracts[0].contractTemplates[$driver.key] as $template |
           [$template.boundaryChain[].phase] == $driver.value.phases and
           $template.fullRevalidation == $driver.value.full and
           $template.identityAuthority == $driver.value.identity and
           contract_entry($driver.key).contractTemplate == $driver.key
         ) and
         $caseContracts[0].contractTemplates["generated-runtime-configuration"].boundaryChain[0] == {
           "id":"total-runtime-configuration-generation",
           "phase":"D0",
           "component":"runtime-config-generator"
         } and
         $caseContracts[0].contractTemplates["generated-runtime-configuration"].boundaryChain[1] == {
           "id":"generated-runtime-configuration-validation",
           "phase":"D0",
           "component":"runtime-config-validator"
         } and
         all(forbidden_driver_path_ids[];
           $caseContracts[0].driverTrustStateContracts[.].admittedValue == null
         )
      then empty
      else "driver templates must equal the exact private handoff, full replay, total generator, and rejection-only chains"
      end
    ),
    (
      $caseContracts[0].entries[] as $entry |
      (
        unknown_keys(
          $entry;
          [
            "pathId",
            "contractTemplate",
            "sourceOwner",
            "reachableOwners",
            "targetProfileIds",
            "nativeHandleContract",
            "evidenceObligationIds",
            "testObligationIds",
            "delegatedPackets",
            "delegatedConcerns"
          ]
        )[] as $key |
        "\($entry.pathId // "<missing-path>"): unknown case-contract entry key: \($key)"
      ),
      if $caseContracts[0].contractTemplates[$entry.contractTemplate] != null
      then empty
      else "\($entry.pathId // "<missing-path>"): case contract must reference a known template"
      end,
      if (owners | index($entry.sourceOwner)) and
         ($entry.reachableOwners | string_array) and
         (
           ($entry.reachableOwners | length) > 0 or
           (forbidden_driver_path_ids | index($entry.pathId)) != null
         ) and
         ($entry.targetProfileIds | string_array) and
         ($entry.evidenceObligationIds | nonempty_string_array) and
         ($entry.testObligationIds | nonempty_string_array) and
         ($entry.delegatedPackets | string_array) and
         ($entry.delegatedConcerns | string_array)
      then empty
      else "\($entry.pathId // "<missing-path>"): case-contract ownership, profiles, obligations, and delegation must be complete"
      end,
      if path_entry($entry.pathId) as $path |
         $path != null and
         $entry.sourceOwner == $path.sourceOwner and
         $entry.reachableOwners == $path.reachableOwners and
         $entry.delegatedPackets == $path.delegatedPackets and
         $entry.delegatedConcerns ==
           [$entry.delegatedPackets[] as $packet |
            exact_delegated_concern_taxonomy[$packet][]]
      then empty
      else "\($entry.pathId // "<missing-path>"): delegatedPackets must expand to the exact ordered delegated concern taxonomy"
      end
    )
  ];

def coverage_schema_errors:
  [
    (
      unknown_keys(
        .;
        [
          "reviewVersion",
          "packet",
          "status",
          "textAuthority",
          "invariantIds",
          "pathIds",
          "expectedCellCount",
          "delegatedConcernTaxonomy",
          "resolvedReentryReplay",
          "crossPathHandoffs",
          "targetApplicabilityProjection",
          "rules"
        ]
      )[] as $key |
      "unknown composition coverage key: \($key)"
    ),
    if (.reviewVersion == 1 and .packet == "D" and .status == "candidate")
    then empty
    else "composition coverage header must identify candidate-only Packet D version 1"
    end,
    if (.textAuthority | nonempty_string)
    then empty
    else "composition coverage textAuthority must be non-empty"
    end,
    if .invariantIds == registry_ids and
       (.invariantIds | length) == 140
    then empty
    else "coverage invariant IDs must equal the exact 140-ID registry order"
    end,
    if .pathIds == locked_path_ids
    then empty
    else "coverage path IDs must equal the locked 54-path universe"
    end,
    if .expectedCellCount ==
         ($paths[0].reviewedPathCount * (registry_ids | length))
    then empty
    else "expectedCellCount must equal reviewedPathCount × the current invariant count"
    end,
    if .delegatedConcernTaxonomy ==
         $caseContracts[0].delegatedConcernTaxonomy
    then empty
    else "coverage delegatedConcernTaxonomy must exactly copy the reviewed candidate catalog"
    end,
    if .resolvedReentryReplay ==
         $caseContracts[0].serializedResolvedReentryReplaySets
    then empty
    else "coverage resolvedReentryReplay must exactly copy the reviewed candidate catalog"
    end,
    if .crossPathHandoffs == $caseContracts[0].crossPathHandoffs
    then empty
    else "coverage crossPathHandoffs must exactly copy the reviewed candidate catalog"
    end,
    if .targetApplicabilityProjection ==
         $caseContracts[0].targetApplicabilityProjection
    then empty
    else "coverage targetApplicabilityProjection must exactly copy the reviewed candidate catalog"
    end,
    (
      duplicate_values([.rules[].id])[] |
      "duplicate rule id: \(.)"
    ),
    (
      duplicate_values([.rules[].valueCases[]?.id])[] |
      "duplicate value case id: \(.)"
    )
  ];

def rule_errors($rule):
  [
    (
      unknown_keys($rule; ["id","selector","valueCases"])[] as $key |
      "\($rule.id // "<missing-rule>"): unknown composition rule key: \($key)"
    ),
    (
      unknown_keys($rule.selector; ["invariantIds","pathIds","invariantOwner","classificationCode"])[] as $key |
      "\($rule.id // "<missing-rule>"): unknown selector key: \($key)"
    ),
    if ($rule.id | nonempty_string)
    then empty
    else "composition rule id must be non-empty"
    end,
    if $rule.selector.invariantIds | nonempty_string_array
    then empty
    else "\($rule.id // "<missing-rule>"): invariantIds must be non-empty"
    end,
    if ($rule.selector.pathIds | type) == "array" and
       ($rule.selector.pathIds | length) == 1 and
       ($rule.selector.pathIds[0] | nonempty_string)
    then empty
    else "\($rule.id // "<missing-rule>"): pathIds must contain exactly one path"
    end,
    (
      $rule.selector.invariantIds[]? as $id |
      if registry_ids | index($id)
      then empty
      else "\($rule.id // "<missing-rule>"): unknown invariant selector: \($id)"
      end
    ),
    (
      $rule.selector.pathIds[]? as $id |
      if locked_path_ids | index($id)
      then empty
      else "\($rule.id // "<missing-rule>"): unknown path selector: \($id)"
      end
    ),
    if owners | index($rule.selector.invariantOwner)
    then empty
    else "\($rule.id // "<missing-rule>"): unknown invariantOwner"
    end,
    if ($rule.selector.classificationCode | type) == "string" and
       ($caseContracts[0].classificationCodeContract[$rule.selector.classificationCode] != null)
    then empty
    else "\($rule.id // "<missing-rule>"): selector classificationCode must use the closed reviewed code legend"
    end,
    (
      $rule.selector.invariantIds[]? as $id |
      if registry_owner($id) == $rule.selector.invariantOwner
      then empty
      else "\($rule.id // "<missing-rule>"): selector invariant owner mismatch: \($id)"
      end
    ),
    (
      $rule.selector.invariantIds[]? as $id |
      ($rule.selector.pathIds[0] // "") as $path_id |
      classification_code($path_id; $id) as $expected_code |
      if $expected_code == $rule.selector.classificationCode
      then empty
      else "\($rule.id // "<missing-rule>"): selector classificationCode must equal the independently pinned path/invariant vector"
      end
    ),
    if ($rule.valueCases | type) == "array" and ($rule.valueCases | length) > 0
    then empty
    else "\($rule.id // "<missing-rule>"): valueCases must be non-empty"
    end
  ];

def case_errors($rule; $case):
  ($rule.selector.pathIds[0] // "") as $path_id |
  contract_entry($path_id) as $entry |
  contract_template($entry) as $template |
  path_entry($path_id) as $path |
  ($rule.selector.classificationCode // "") as $classification_code |
  classification_effect($classification_code) as $classified_effect |
  classification_exclusion($classification_code) as $exclusion_class |
  ($classified_effect != "no-authority") as $active |
  [
    (
      unknown_keys(
        $case;
        [
          "id",
          "condition",
          "allowedEffect",
          "firstSoundPhase",
          "rejectionDeadline",
          "authority",
          "boundaryChain",
          "diagnosticIdentity",
          "structuralExclusionClass",
          "structuralExclusion",
          "rejectedForeignOwnerAt",
          "fullRevalidation",
          "identityAuthority",
          "ownershipExclusions",
          "targetProfileIds",
          "nativeHandleContract",
          "evidenceObligationIds",
          "testObligationIds",
          "delegatedPackets",
          "fallbackPolicy",
          "warningPolicy",
          "implementationStatus"
        ]
      )[] as $key |
      "\($case.id // "<missing-case>"): unknown composition case key: \($key)"
    ),
    if ($case.id | nonempty_string)
    then empty
    else "\($rule.id // "<missing-rule>"): value case id must be non-empty"
    end,
    if all($rule.selector.invariantIds[];
         requires_conditional_native_handle(.; $classification_code)
       )
    then (
      if $case.condition ==
           $caseContracts[0].conditionalNativeHandleContract.condition
      then empty
      else "\($case.id // "<missing-case>"): active or boundary NAT-002/NAT-003 requires the exact conditional native-handle condition"
      end
    )
    elif all($rule.selector.invariantIds[];
           (requires_conditional_native_handle(.; $classification_code) | not)
         )
    then (
      if $case.condition == {"kind":"all-values"}
      then empty
      else "\($case.id // "<missing-case>"): non-native value case must use the closed all-values condition"
      end
    )
    else "\($case.id // "<missing-case>"): native-handle conditional cells cannot share a rule with unconditional cells"
    end,
    if effects | index($case.allowedEffect)
    then empty
    else "\($case.id // "<missing-case>"): unknown allowedEffect: \($case.allowedEffect // "<missing>")"
    end,
    if reachable($case.firstSoundPhase; $case.rejectionDeadline)
    then empty
    else "\($case.id // "<missing-case>"): rejectionDeadline must be reachable from firstSoundPhase"
    end,
    if ($case.boundaryChain | type) == "array" and ($case.boundaryChain | length) > 0
    then empty
    else "\($case.id // "<missing-case>"): boundaryChain must be non-empty"
    end,
    if boundary_chain_is_reachable($case.boundaryChain)
    then empty
    else "\($case.id // "<missing-case>"): boundaryChain must be ordered by authoritative graph reachability"
    end,
    if any($case.boundaryChain[]?;
      .phase == $case.authority.phase and
      .component == $case.authority.component)
    then empty
    else "\($case.id // "<missing-case>"): authority must identify an exact boundaryChain step"
    end,
    if $entry != null and $template != null and
       $case.allowedEffect == $classified_effect and
       all($rule.selector.invariantIds[];
         registry_invariant(.) as $invariant |
         if $invariant == null
         then true
         else
           expected_cell_phase_contract(
             $template;
             $entry;
             $invariant;
             $classification_code
           ) as $expected |
           $case.firstSoundPhase == $expected.firstSoundPhase and
           $case.rejectionDeadline == $expected.rejectionDeadline and
           $case.authority == $expected.authority and
           $case.boundaryChain == $expected.boundaryChain
         end
       ) and
       $case.structuralExclusionClass == $exclusion_class and
       $case.structuralExclusion ==
         (if $active
          then $template.structuralExclusion
          else $caseContracts[0].structuralExclusionClasses[$exclusion_class]
          end) and
       $case.rejectedForeignOwnerAt == $template.rejectedForeignOwnerAt and
       $case.fullRevalidation ==
         (if $classified_effect == "boundary-input"
          then true
          else $template.fullRevalidation
          end) and
       $case.identityAuthority == $template.identityAuthority and
       $case.ownershipExclusions == $template.ownershipExclusions and
       $case.targetProfileIds == $entry.targetProfileIds and
       all($rule.selector.invariantIds[];
         if requires_conditional_native_handle(.; $classification_code)
         then $case.nativeHandleContract ==
           $caseContracts[0].nativeHandleContract
         else $case.nativeHandleContract == $entry.nativeHandleContract
         end
       ) and
       $case.evidenceObligationIds == $entry.evidenceObligationIds and
       $case.testObligationIds == $entry.testObligationIds and
       $case.delegatedPackets == $entry.delegatedPackets
    then empty
    else "\($case.id // "<missing-case>"): structured controls must equal the independently pinned invariant/path contract"
    end,
    if (["F","L","I"] | index($classification_code)) != null
    then (
      rejecting_boundary_authority($template) as $rejecting_authority |
      if $case.authority == $rejecting_authority and
         $case.firstSoundPhase == $rejecting_authority.phase and
         $case.rejectionDeadline == $rejecting_authority.phase
      then empty
      else "\($case.id // "<missing-case>"): non-H no-authority must reject at the exact named structural boundary authority"
      end
    )
    else empty
    end,
    if $case.fallbackPolicy == "forbidden" and
       $case.warningPolicy == "never-sufficient" and
       $case.implementationStatus == "planned"
    then empty
    else "\($case.id // "<missing-case>"): fallback, warning, and implementation status must remain fail-closed and planned"
    end,
    if $case.allowedEffect == "no-authority"
    then (
      if ($case.structuralExclusion | nonempty_string) and
         ($case.rejectedForeignOwnerAt | nonempty_string)
      then empty
      else "\($case.id // "<missing-case>"): no-authority requires structural exclusion and exact rejecting boundary"
      end
    )
    else empty
    end,
    if $case.allowedEffect == "boundary-input"
    then (
      if $case.fullRevalidation == true
      then empty
      else "\($case.id // "<missing-case>"): boundary-input requires full revalidation"
      end
    )
    else empty
    end,
    if $path_id == "target-native-extension"
    then (
      if $case.targetProfileIds == required_profile_ids
      then empty
      else "\($case.id // "<missing-case>"): target-native coverage must include every Packet C profile"
      end
    )
    else empty
    end,
    if $path_id == "typed-nix-handle" or $path_id == "direct-native-nix-value"
    then (
      if $case.nativeHandleContract == {
        "sourceGraphClosureDigest":"required-complete-pinned-transitive-closure",
        "registryNamespace":"required",
        "registryVersion":"required",
        "registryDigest":"required",
        "exportAttribute":"required",
        "nativeInterfaceVersion":"required",
        "targetSystem":"required",
        "affectedMember":"required",
        "expectedSemanticProjection":"required",
        "semanticIdentityComparison":"required-before-construction"
      }
      then empty
      else "\($case.id // "<missing-case>"): native Nix value must require the complete pinned transitive source-closure digest, registry namespace/version/digest, export attribute, interface version, target system, affected member, expected semantic projection, and pre-construction semantic identity comparison"
      end
    )
    else empty
    end,
    if $path_id == "native-guest-module"
    then (
      if $case.ownershipExclusions == [
        "host-bindings",
        "runtime-allocations",
        "secrets",
        "provider-objects",
        "runtime-profile-selection",
        "support-claims",
        "conformance-claims"
      ]
      then empty
      else "\($case.id // "<missing-case>"): native guest module must exclude host/runtime/profile/support/conformance authority"
      end
    )
    else empty
    end,
    if (
      (["caller","artifact-native","lifecycle-native","provider-native"] |
       index((path_entry($path_id).category // ""))) != null
    )
    then (
      if $case.identityAuthority == "preserve-only"
      then empty
      else "\($case.id // "<missing-case>"): caller/native paths cannot mint Artifact or conformance identity"
      end
    )
    else empty
    end,
    if (
      [
        "artifact-ordinary-authoring",
        "artifact-imports",
        "artifact-import-order",
        "artifact-profile-expansion",
        "artifact-explicit-override",
        "artifact-semantic-refinement",
        "artifact-strongest-override",
        "artifact-native-language-escape"
      ] | index($path_id)
    )
    then (
      [$template.boundaryChain[].id] as $chain_ids |
      if ($chain_ids | index("artifact-final-validation")) != null and
         ($chain_ids | index("canonical-wire")) != null and
         ($chain_ids | index("nix-construction")) != null and
         ($chain_ids | index("artifact-final-validation")) <
           ($chain_ids | index("canonical-wire")) and
         ($chain_ids | index("canonical-wire")) <
           ($chain_ids | index("nix-construction"))
      then empty
      else "\($case.id // "<missing-case>"): authoring paths must reach final Artifact and canonical-wire validation before Nix construction"
      end
    )
    else empty
    end
  ];

def cell_key($invariant; $path):
  "\($invariant) × \($path)";

def expansion_errors:
  [
    (
      [
        .rules[] as $rule |
        $rule.selector.invariantIds[]? as $invariant |
        $rule.selector.pathIds[]? as $path |
        cell_key($invariant; $path)
      ]
    ) as $cells |
    (
      duplicate_values($cells)[] |
      "overlapping composition cell: \(.)"
    ),
    (
      [
        registry_ids[] as $invariant |
        locked_path_ids[] as $path |
        cell_key($invariant; $path)
      ] -
      $cells
    )[] as $missing |
    "uncovered composition cell: \($missing)",
    if ($cells | length) == .expectedCellCount
    then empty
    else "expanded composition cell count must equal expectedCellCount"
    end
  ];

(
  if $validationScope == "catalog"
  then path_errors + case_contract_errors
  else
    path_errors +
    case_contract_errors +
    coverage_schema_errors +
    [.rules[] as $rule | rule_errors($rule)[]] +
    [.rules[] as $rule | $rule.valueCases[]? as $case | case_errors($rule; $case)[]] +
    expansion_errors
  end
) as $errors |
if ($errors | length) == 0
then true
else error($errors | unique | join("\n"))
end
