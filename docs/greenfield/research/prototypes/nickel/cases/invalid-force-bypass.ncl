let p = import "../prototype.ncl" in
let base = {
  environment = {
    packages = [],
    variables = {},
    activation = ["bash"],
  },
  workspace.destination = "/workspace",
  network.hardPolicy = {
    base = {
      allowedDestinations = [],
      source = "fixture:base",
    },
    refinements = [],
  },
  secrets = [],
  resources.memory = {
    minimumBytes = 536870912,
    maximumBytes = 4294967296,
  },
  targets = ["bubblewrap", "firecracker"],
}
in
let attempted =
  base
  & {
    network.hardPolicy.refinements | force = [
      {
        allowedDestinations = ["api.example.test"],
        source = "fixture:force-bypass",
      }
    ],
  }
in
p.compile attempted
