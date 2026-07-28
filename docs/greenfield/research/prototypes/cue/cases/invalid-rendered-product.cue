package prototype

// This fixture intentionally reconstructs an exported candidate after the
// source-level compiler. CUE accepts and serializes it; W0 must still reject
// the relative destination at the product boundary.
output: {
	schemaVersion: 1
	profile: {
		selected:           "workspace-edit-offline"
		selectionIsVisible: true
	}
	environment: {
		packages: [{
			input:     "nixpkgs"
			attribute: "hello"
		}]
		variables: EDITOR: "vi"
		activation: ["bash"]
	}
	workspace: {
		destination:             "workspace"
		materialization:         "copy"
		allowedMaterializations: ["copy"]
		access:                  "read-write"
	}
	network: {
		mode:        "none"
		egressAllow: []
		hardPolicy: allowedDestinations: []
	}
	secrets: [{
		name:     "agent-api-token"
		delivery: "environment"
	}]
	resources: memory: {
		minimumBytes: 536870912
		maximumBytes: 4294967296
	}
	targets: ["bubblewrap", "firecracker"]
	requiredCapabilities: ["network.none", "workspace.copy"]
	runtimeProfiles: {
		"bubblewrap-copy": {
			target:           "bubblewrap"
			materializations: ["copy"]
		}
		"firecracker-copy": {
			target:           "firecracker"
			materializations: ["copy"]
		}
	}
}
