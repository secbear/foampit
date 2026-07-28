package prototype

_compile: #Compile & {
	input: {
		profile: "workspace-live-development"
		environment: {
			packages: []
			variables: {}
			activation: ["bash"]
		}
		workspace: {
			destination: "/workspace"
			allowedMaterializations: ["live"]
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
		targets: ["firecracker"]
	}
}

output: _compile.output
