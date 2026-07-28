let p = import "../prototype.ncl" in
let imported = import "./import-dynamic-input.ncl" in
let selected =
  imported
  & { profile | default = "workspace-live-development" }
  & { profile = "workspace-edit-offline" }
in
p.compile selected
