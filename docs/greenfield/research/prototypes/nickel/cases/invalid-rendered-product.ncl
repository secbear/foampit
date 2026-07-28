let p = import "../prototype.ncl" in
let imported = import "./import-dynamic-input.ncl" in
let validated = p.compile imported in
validated
& {
  workspace.destination | force = "workspace",
  corruptionMarker | not_exported = "frontend-output",
}
