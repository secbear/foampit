package prototype

_compile: #Compile & {
	input: {
		profile: "workspace-edit-offline"
		environment: {
			packages: []
			variables: {}
			activation: ["bash"]
		}
		workspace: {
			destination:     "/workspace"
			materialization: "live"
		}
		network: hardPolicy: base: {
			allowedDestinations: []
			source: "fixture:base"
		}
		secrets: []
		resources: memory: {
			minimumBytes: 536870912
			maximumBytes: 4294967296
		}
		targets: ["bubblewrap", "firecracker"]
	}
}

output: _compile.output
