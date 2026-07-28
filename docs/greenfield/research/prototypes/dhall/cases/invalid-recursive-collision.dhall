let p = ../prototype.dhall

let base =
      { profile = p.Profile.WorkspaceEditOffline
      , workspace = p.Workspace.Copy
      , baseAllowsExternal = False
      , refinementAllowsExternal = False
      }

let collision = base /\ { workspace = p.Workspace.Live }

in  p.analyze collision
