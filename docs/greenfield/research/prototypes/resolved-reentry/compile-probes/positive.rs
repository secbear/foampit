use resolved_reentry::{
    decode_reentry, invoke_driver, load_reviewed_replay_sets, revalidate_reentry,
    AcquisitionInputs, CurrentAdmission,
};

fn main() {
    let args: Vec<String> = std::env::args().collect();
    if args.len() == 4 {
        let bytes = std::fs::read(&args[1]).unwrap();
        let catalog = std::fs::read(&args[2]).unwrap();
        let candidate = decode_reentry(&bytes).unwrap();
        let replay = load_reviewed_replay_sets(&catalog).unwrap();
        let current = CurrentAdmission::for_witness("bubblewrap-linux-v1", "admission-v1");
        let acquisition = AcquisitionInputs::new(&args[3]);
        let prepared = revalidate_reentry(candidate, &current, &acquisition, &replay).unwrap();
        let _receipt = invoke_driver(prepared).unwrap();
    }
}
