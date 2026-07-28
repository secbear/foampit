use resolved_reentry::invoke_driver;

fn main() {
    invoke_driver(vec!["--bind".to_owned(), "/".to_owned()]).unwrap();
}
