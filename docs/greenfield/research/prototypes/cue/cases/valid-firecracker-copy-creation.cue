package prototype

_compile: #Compile & {
	input: {
		profile: "workspace-edit-offline"
		environment: {
			packages: [{
				input:     "nixpkgs"
				attribute: "hello"
			}]
			variables: EDITOR: "vi"
			activation: ["bash"]
		}
		workspace: {
			destination: "/workspace"
			allowedMaterializations: ["copy", "live"]
		}
		network: hardPolicy: base: {
			allowedDestinations: []
			source: "fixture:base"
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
	}
}

_create: #Create & {
	artifact: _compile.output
	input: {
		runtimeProfile: "firecracker-copy"
		workspace: materialization: "copy"
		allocation: memoryBytes:    1073741824
	}
}

output: _create.output
