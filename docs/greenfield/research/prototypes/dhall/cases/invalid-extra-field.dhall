let p = ../prototype.dhall

let attempted =
      { profile = p.Profile.WorkspaceEditOffline
      , workspace = p.Workspace.Copy
      , baseAllowsExternal = False
      , refinementAllowsExternal = False
      , undeclaredAuthority = True
      }

in  p.analyze attempted
