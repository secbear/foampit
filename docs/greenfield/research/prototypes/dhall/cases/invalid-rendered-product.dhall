-- This candidate is valid Dhall and renders successfully.  The relative
-- workspace destination is intentionally left for the product-owned W0
-- semantic validator to reject.
{ schemaVersion = 1
, profile =
  { selected = "workspace-edit-offline", selectionIsVisible = True }
, environment =
  { packages = [ { input = "nixpkgs", attribute = "hello" } ]
  , variables = { EDITOR = "vi" }
  , activation = [ "bash" ]
  }
, workspace =
  { destination = "workspace"
  , materialization = "copy"
  , allowedMaterializations = [ "copy" ]
  , access = "read-write"
  }
, network =
  { mode = "none"
  , egressAllow = [] : List Text
  , hardPolicy = { allowedDestinations = [] : List Text }
  }
, secrets = [ { name = "agent-api-token", delivery = "environment" } ]
, resources =
  { memory = { minimumBytes = 536870912, maximumBytes = 4294967296 } }
, targets = [ "bubblewrap", "firecracker" ]
, requiredCapabilities = [ "network.none", "workspace.copy" ]
, runtimeProfiles =
  { `bubblewrap-copy` =
    { target = "bubblewrap", materializations = [ "copy" ] }
  , `firecracker-copy` =
    { target = "firecracker", materializations = [ "copy" ] }
  }
}
