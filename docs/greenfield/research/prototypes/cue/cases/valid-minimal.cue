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
		workspace: destination: "/workspace"
		network: {
			hardPolicy: {
				base: {
					allowedDestinations: []
					source: "fixture:base"
				}
			}
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

output: _compile.output
