let p = import "../prototype.ncl" in
p.compile {
  environment = {
    packages = [],
    variables = {},
    activation = ["bash"],
  },
  workspace.destination = "/workspace",
  network = {
    egressAllow = ["api.example.test"],
    hardPolicy.base = {
      allowedDestinations = [],
      source = "fixture:base",
    },
  },
  secrets = [],
  resources.memory = {
    minimumBytes = 536870912,
    maximumBytes = 4294967296,
  },
  targets = ["bubblewrap", "firecracker"],
}
