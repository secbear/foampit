let p = ../prototype.dhall

let result =
      p.analyze
        { profile = p.Profile.WorkspaceEditOffline
        , workspace = p.Workspace.Copy
        , baseAllowsExternal = False
        , refinementAllowsExternal = True
        }

let profileCheck = assert : result.profileConsistent === True

let policyCheck = assert : result.policyMonotonic === True

in  result.manifest
