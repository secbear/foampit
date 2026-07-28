let Profile = < WorkspaceEditOffline | WorkspaceLiveDevelopment >

let chooseProfile =
      \(candidate : Optional Profile) ->
        merge
          { Some = \(profile : Profile) -> profile
          , None = Profile.WorkspaceEditOffline
          }
          candidate

let profileName =
      \(profile : Profile) ->
        merge
          { WorkspaceEditOffline = "workspace-edit-offline"
          , WorkspaceLiveDevelopment = "workspace-live-development"
          }
          profile

in  { defaulted = profileName (chooseProfile (None Profile))
    , selected =
        profileName
          (chooseProfile (Some Profile.WorkspaceLiveDevelopment))
    }
