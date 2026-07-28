let p = import "../prototype.ncl" in
p.compile {
  profile = "workspace-edit-offline",
  environment = {
    packages = [],
    variables = {},
    activation = ["bash"],
  },
  workspace = {
    destination = "/workspace",
    materialization = "live",
  },
  network.hardPolicy.base = {
    allowedDestinations = [],
    source = "fixture:base",
  },
  secrets = [],
  resources.memory = {
    minimumBytes = 536870912,
    maximumBytes = 4294967296,
  },
  targets = ["bubblewrap", "firecracker"],
}
