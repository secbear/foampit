use resolved_reentry::invoke_driver;
use std::collections::BTreeMap;

fn main() {
    invoke_driver(BTreeMap::<String, String>::new()).unwrap();
}
