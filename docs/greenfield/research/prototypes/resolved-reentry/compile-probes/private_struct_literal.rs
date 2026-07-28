use resolved_reentry::PreparedLaunch;

fn main() {
    let _forged = PreparedLaunch {
        semantic_identity: String::new(),
        generated: panic!("unreachable"),
        retained_workspace: std::fs::File::open("/dev/null").unwrap(),
    };
}
