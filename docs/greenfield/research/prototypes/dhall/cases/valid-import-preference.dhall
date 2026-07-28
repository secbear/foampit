let p = ../prototype.dhall

let imported = ./import-default-input.dhall

let selected =
      imported
    //  { profile = p.Profile.WorkspaceLiveDevelopment
        , workspace = p.Workspace.Live
        }

let result = p.analyze selected

let profileCheck = assert : result.profileConsistent === True

let policyCheck = assert : result.policyMonotonic === True

in  result.manifest
