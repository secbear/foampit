let p = import "../prototype.ncl" in
let artifact =
  p.compile {
    environment = {
      packages = [],
      variables = {},
      activation = ["bash"],
    },
    workspace = {
      destination = "/workspace",
      allowedMaterializations = ["copy", "live"],
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
in
p.create
  artifact
  {
    runtimeProfile = "firecracker-copy",
    workspace.materialization = "live",
    allocation.memoryBytes = 1073741824,
  }
