use resolved_reentry::PreparedLaunch;

fn requires_clone<T: Clone>() {}

fn main() {
    requires_clone::<PreparedLaunch>();
}
