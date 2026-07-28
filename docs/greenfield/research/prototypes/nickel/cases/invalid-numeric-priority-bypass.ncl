let p = import "../prototype.ncl" in
let imported = import "./import-dynamic-input.ncl" in
let attempted =
  imported
  & { network.hardPolicy.refinements | priority 10 = [] }
  & {
    network.hardPolicy.refinements | priority 20 = [
      {
        allowedDestinations = ["api.example.test"],
        source = "fixture:numeric-priority-bypass",
      }
    ],
  }
in
p.compile attempted
