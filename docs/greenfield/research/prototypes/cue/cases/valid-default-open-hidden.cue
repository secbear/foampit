package prototype

import "strings"

_normalizedEditor: strings.ToLower("VI")

_compile: #Compile & {
	input: {
		environment: {
			packages: []
			variables: {
				"PLUGIN__DYNAMIC_KEY": "accepted"
				EDITOR:                _normalizedEditor
			}
			activation: ["bash"]
		}
		workspace: destination: "/workspace"
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
