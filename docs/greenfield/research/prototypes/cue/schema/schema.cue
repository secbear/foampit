package prototype

import (
	"list"
	"strings"
)

#ProfileName:     "workspace-edit-offline" | "workspace-live-development"
#Materialization: "copy" | "live"
#Access:          "read-only" | "read-write"
#NetworkMode:     "none" | "egress"
#Target:          "bubblewrap" | "firecracker"

#Profiles: {
	"workspace-edit-offline": {
		workspace: {
			materialization: "copy"
			access:          "read-write"
		}
		network: mode: "none"
	}
	"workspace-live-development": {
		workspace: {
			materialization: "live"
			access:          "read-write"
		}
		network: mode: "egress"
	}
}

#TargetCapabilities: {
	bubblewrap: [
		"workspace.copy",
		"workspace.live",
		"network.none",
		"network.egress",
	]
	firecracker: [
		"workspace.copy",
		"network.none",
		"network.egress",
	]
}

#PackageReference: {
	input:     string
	attribute: string
}

#PolicyDefinition: {
	allowedDestinations: [...string]
	source: string
}

#SecretSlot: {
	name:     =~"^[a-z][a-z0-9-]*$"
	delivery: "environment" | "file"
}

#ArtifactInput: {
	profile: *"workspace-edit-offline" | #ProfileName
	environment: {
		packages: [...#PackageReference]
		variables: [string]: string
		activation: [...string]
	}
	workspace: {
		destination:     string
		materialization: *"inherit" | #Materialization
		allowedMaterializations: *["copy"] | [...#Materialization]
		access: *"inherit" | #Access
	}
	network: {
		mode: *"inherit" | #NetworkMode
		egressAllow: *[] | [...string]
		hardPolicy: {
			base: #PolicyDefinition
			refinements: *[] | [...#PolicyDefinition]
		}
	}
	secrets: [...#SecretSlot]
	resources: memory: {
		minimumBytes: int & >=0
		maximumBytes: int & >=0
	}
	targets: [...#Target]
}

#RuntimeProfile: {
	target: #Target
	materializations: [...#Materialization]
}

#Manifest: {
	schemaVersion: 1
	profile: {
		selected:           #ProfileName
		selectionIsVisible: true
	}
	environment: {
		packages: [...#PackageReference]
		variables: [string]: string
		activation: [...string]
	}
	workspace: {
		destination:     string
		materialization: #Materialization
		allowedMaterializations: [...#Materialization]
		access: #Access
	}
	network: {
		mode: #NetworkMode
		egressAllow: [...string]
		hardPolicy: allowedDestinations: [...string]
	}
	secrets: [...#SecretSlot]
	resources: memory: {
		minimumBytes: int & >=0
		maximumBytes: int & >=0
	}
	targets: [...#Target]
	requiredCapabilities: [...string]
	runtimeProfiles: [string]: #RuntimeProfile
}

#Compile: {
	input: #ArtifactInput

	_profile:         #Profiles[input.profile]
	_materialization: _profile.workspace.materialization
	_access:          _profile.workspace.access
	_networkMode:     _profile.network.mode

	if input.workspace.materialization != "inherit" &&
		input.workspace.materialization != _materialization {
		output: error("artifact.profile.explicit_conflict: workspace materialization contradicts selected profile")
	}
	if input.workspace.access != "inherit" &&
		input.workspace.access != _access {
		output: error("artifact.profile.explicit_conflict: workspace access contradicts selected profile")
	}
	if input.network.mode != "inherit" &&
		input.network.mode != _networkMode {
		output: error("artifact.profile.explicit_conflict: network mode contradicts selected profile")
	}

	if !strings.HasPrefix(input.workspace.destination, "/") {
		output: error("artifact.mount.destination_absolute: workspace destination must be absolute")
	}
	if len(input.environment.activation) == 0 {
		output: error("artifact.environment.activation_nonempty: activation argv must not be empty")
	}
	if _networkMode == "none" && len(input.network.egressAllow) > 0 {
		output: error("artifact.network.none_has_no_egress: disabled network cannot have egress destinations")
	}
	if input.resources.memory.minimumBytes > input.resources.memory.maximumBytes {
		output: error("artifact.resources.bounds_nonempty: minimum memory exceeds maximum memory")
	}
	if len(input.targets) == 0 {
		output: error("artifact.target.at_least_one: at least one target is required")
	}

	for refinement in input.network.hardPolicy.refinements {
		for destination in refinement.allowedDestinations {
			if !list.Contains(input.network.hardPolicy.base.allowedDestinations, destination) {
				output: error("artifact.policy.monotonic_refinement: refinement widens hard policy")
			}
		}
	}

	_requiredCapabilities: [
		"network.\(_networkMode)",
		"workspace.\(_materialization)",
	]
	for target in input.targets {
		for capability in _requiredCapabilities {
			if !list.Contains(#TargetCapabilities[target], capability) {
				output: error("artifact.target.required_capability_supported: target lacks a mandatory capability")
			}
		}
	}

	output: #Manifest & {
		schemaVersion: 1
		profile: {
			selected:           input.profile
			selectionIsVisible: true
		}
		environment: input.environment
		workspace: {
			destination:             input.workspace.destination
			materialization:         _materialization
			allowedMaterializations: input.workspace.allowedMaterializations
			access:                  _access
		}
		network: {
			mode:        _networkMode
			egressAllow: input.network.egressAllow
			hardPolicy: allowedDestinations: input.network.hardPolicy.base.allowedDestinations
		}
		secrets:   input.secrets
		resources: input.resources
		targets:   input.targets
		requiredCapabilities: _requiredCapabilities
		runtimeProfiles: {
			if list.Contains(input.targets, "bubblewrap") &&
				list.Contains(input.workspace.allowedMaterializations, "copy") {
				"bubblewrap-copy": {
					target: "bubblewrap"
					materializations: ["copy"]
				}
			}
			if list.Contains(input.targets, "bubblewrap") &&
				list.Contains(input.workspace.allowedMaterializations, "live") {
				"bubblewrap-live": {
					target: "bubblewrap"
					materializations: ["live"]
				}
			}
			if list.Contains(input.targets, "firecracker") &&
				list.Contains(input.workspace.allowedMaterializations, "copy") {
				"firecracker-copy": {
					target: "firecracker"
					materializations: ["copy"]
				}
			}
		}
	}
}

#CreateInput: {
	runtimeProfile: string
	workspace: materialization: #Materialization
	allocation: memoryBytes:    int & >=0
}

#Create: {
	artifact: #Manifest
	input:    #CreateInput

	_runtimeProfile: artifact.runtimeProfiles[input.runtimeProfile]

	if !list.Contains(_runtimeProfile.materializations, input.workspace.materialization) {
		output: error("create.runtime_profile_supports_binding: runtime profile does not support requested workspace materialization")
	}
	if input.allocation.memoryBytes < artifact.resources.memory.minimumBytes ||
		input.allocation.memoryBytes > artifact.resources.memory.maximumBytes {
		output: error("create.allocation.within_artifact_bounds: requested memory lies outside Artifact bounds")
	}

	output: {
		runtimeProfile: input.runtimeProfile
		workspace:      input.workspace
		allocation:     input.allocation
	}
}
