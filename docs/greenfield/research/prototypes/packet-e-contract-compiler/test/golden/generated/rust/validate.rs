#[path = "lib.rs"]
mod contract;

fn main() {
    let path = std::env::args().nth(1).expect("fixture path");
    let bytes = std::fs::read(path).expect("read fixture");
    match contract::decode_outcome(&bytes) {
        Ok(_) => println!("ok"),
        Err(diagnostic) => println!("{}", diagnostic.category()),
    }
}
