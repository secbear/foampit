package prototype

_compile: input: {
	environment: variables: ORDER_CONTROL: "unified"
	network: hardPolicy: refinements: [{
		allowedDestinations: ["api.example.test"]
		source: "fixture:refinement"
	}]
}
