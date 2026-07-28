let Profile = < WorkspaceEditOffline | WorkspaceLiveDevelopment >

let Workspace = < Copy | Live >

let Input =
      { profile : Profile
      , workspace : Workspace
      , baseAllowsExternal : Bool
      , refinementAllowsExternal : Bool
      }

let analyze =
      \(input : Input) ->
        let profileIsLive =
              merge
                { WorkspaceEditOffline = False
                , WorkspaceLiveDevelopment = True
                }
                input.profile

        let workspaceIsLive =
              merge { Copy = False, Live = True } input.workspace

        let policyIsMonotonic =
                  input.refinementAllowsExternal == False
              ||  input.baseAllowsExternal

        let profileName =
              merge
                { WorkspaceEditOffline = "workspace-edit-offline"
                , WorkspaceLiveDevelopment = "workspace-live-development"
                }
                input.profile

        let workspaceName =
              merge { Copy = "copy", Live = "live" } input.workspace

        in  { profileConsistent = profileIsLive == workspaceIsLive
            , policyMonotonic = policyIsMonotonic
            , manifest =
              { profile.selected = profileName
              , workspace.materialization = workspaceName
              , network.mode
                = if input.baseAllowsExternal then "egress" else "none"
              }
            }

in  { Profile, Workspace, Input, analyze }
