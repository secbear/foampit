{
  environment = {
    packages = [],
    variables = {
      "PLUGIN__DYNAMIC_KEY" = "accepted",
    },
    activation = ["bash"],
  },
  workspace.destination = "/workspace",
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
