let p = ../prototype.dhall

let base =
      { profile = p.Profile.WorkspaceEditOffline
      , workspace = p.Workspace.Copy
      , baseAllowsExternal = False
      , refinementAllowsExternal = False
      }

let weakened = base // { refinementAllowsExternal = True }

let result = p.analyze weakened

let profileCheck = assert : result.profileConsistent === True

let policyCheck = assert : result.policyMonotonic === True

in  result.manifest
