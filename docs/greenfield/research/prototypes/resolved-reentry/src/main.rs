use resolved_reentry::{
    decode_reentry, external_mutation_count, load_reviewed_replay_sets, revalidate_reentry,
    AcquisitionInputs, CurrentAdmission, Diagnostic,
};
use std::fs;

fn read(path: &str) -> Result<Vec<u8>, Diagnostic> {
    fs::read(path).map_err(|_| Diagnostic::prototype_io())
}

fn context(profile: &str, decision: &str, retained: &str) -> (CurrentAdmission, AcquisitionInputs) {
    (
        CurrentAdmission::for_witness(profile, decision),
        AcquisitionInputs::new(retained),
    )
}

fn execute(args: &[String]) -> Result<(), Diagnostic> {
    match args.get(1).map(String::as_str) {
        Some("decode") if args.len() == 3 => {
            decode_reentry(&read(&args[2])?)?;
            println!("{{\"decoded\":\"untrusted-candidate\"}}");
            Ok(())
        }
        Some("replay-check") if args.len() == 4 => {
            let replay = load_reviewed_replay_sets(&read(&args[2])?)?;
            match args[3].as_str() {
                "built" => println!("{}", replay.built_count()),
                "resolved" => println!("{}", replay.resolved_count()),
                _ => return Err(cli_diagnostic()),
            }
            Ok(())
        }
        Some("revalidate") if args.len() == 7 => {
            let candidate = decode_reentry(&read(&args[2])?)?;
            let replay = load_reviewed_replay_sets(&read(&args[3])?)?;
            let (current, acquisition) = context(&args[6], &args[5], &args[4]);
            let prepared = revalidate_reentry(candidate, &current, &acquisition, &replay)?;
            println!(
                "{}",
                serde_json::to_string(prepared.generated_configuration())
                    .expect("generated configuration is serializable")
            );
            Ok(())
        }
        Some("reject-no-mutation") if args.len() == 8 => {
            let candidate = decode_reentry(&read(&args[2])?)?;
            let replay = load_reviewed_replay_sets(&read(&args[3])?)?;
            let (current, acquisition) = context(&args[6], &args[5], &args[4]);
            match revalidate_reentry(candidate, &current, &acquisition, &replay) {
                Ok(_) => Err(cli_diagnostic()),
                Err(error) if error.invariant() == args[7] && external_mutation_count() == 0 => {
                    println!(
                        "{}",
                        serde_json::to_string(&error).expect("diagnostic is serializable")
                    );
                    Ok(())
                }
                Err(error) => Err(error),
            }
        }
        Some("probe-retained") if args.len() == 8 => {
            let candidate = decode_reentry(&read(&args[2])?)?;
            let replay = load_reviewed_replay_sets(&read(&args[3])?)?;
            let (current, acquisition) = context(&args[6], &args[5], &args[4]);
            let mut prepared = revalidate_reentry(candidate, &current, &acquisition, &replay)?;
            let value = prepared
                .read_retained_source()
                .map_err(|_| cli_diagnostic())?;
            if value.trim_end() != args[7] {
                return Err(cli_diagnostic());
            }
            println!("{{\"retained\":\"current-live-handle\"}}");
            Ok(())
        }
        Some("probe-determinism") if args.len() == 7 => {
            let bytes = read(&args[2])?;
            let replay_bytes = read(&args[3])?;
            let replay = load_reviewed_replay_sets(&replay_bytes)?;
            let (current, acquisition) = context(&args[6], &args[5], &args[4]);
            let first =
                revalidate_reentry(decode_reentry(&bytes)?, &current, &acquisition, &replay)?;
            let second =
                revalidate_reentry(decode_reentry(&bytes)?, &current, &acquisition, &replay)?;
            if first.semantic_identity() != second.semantic_identity()
                || first.generated_configuration() != second.generated_configuration()
                || first.live_handle_id() == second.live_handle_id()
            {
                return Err(cli_diagnostic());
            }
            println!(
                "{{\"semanticIdentityEqual\":true,\"generatedConfigurationEqual\":true,\"liveHandlesDistinct\":true}}"
            );
            Ok(())
        }
        _ => Err(cli_diagnostic()),
    }
}

fn cli_diagnostic() -> Diagnostic {
    Diagnostic::prototype_cli()
}

fn main() {
    let args: Vec<String> = std::env::args().collect();
    if let Err(error) = execute(&args) {
        eprintln!(
            "{}",
            serde_json::to_string(&error).expect("diagnostic is serializable")
        );
        std::process::exit(1);
    }
}
