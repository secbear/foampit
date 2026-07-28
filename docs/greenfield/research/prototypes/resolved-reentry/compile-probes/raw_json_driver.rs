use resolved_reentry::invoke_driver;

fn main() {
    invoke_driver(serde_json::json!({"backend": "raw"})).unwrap();
}
