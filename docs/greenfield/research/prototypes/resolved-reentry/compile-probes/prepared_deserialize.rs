use resolved_reentry::PreparedLaunch;

fn main() {
    let _: PreparedLaunch = serde_json::from_str("{}").unwrap();
}
