let p = import "../prototype.ncl" in
let imported = import "./import-dynamic-input.ncl" in
p.compile imported
