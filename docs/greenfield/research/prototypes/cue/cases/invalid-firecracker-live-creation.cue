package prototype

_compile: #Compile & {
	input: {
		environment: {
			packages: []
			variables: {}
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
		secrets: []
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
		workspace: materialization: "live"
		allocation: memoryBytes:    1073741824
	}
}

output: _create.output
