let p = ../prototype.dhall

in  { profile = p.Profile.WorkspaceEditOffline
    , workspace = p.Workspace.Copy
    , baseAllowsExternal = False
    , refinementAllowsExternal = False
    }
