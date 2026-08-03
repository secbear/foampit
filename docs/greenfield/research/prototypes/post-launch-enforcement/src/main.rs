//! Runs the declared test kinds for each of the nine invariants and reports what the
//! registry's model does and does not support.

use post_launch_enforcement::*;

fn main() {
    let mut pass = 0usize;
    let mut findings: Vec<String> = Vec::new();

    macro_rules! check {
        ($name:expr, $cond:expr) => {
            if $cond {
                pass += 1;
            } else {
                findings.push(format!("FAILED: {}", $name));
            }
        };
    }

    // -----------------------------------------------------------------------------------
    // source-rejection: the ordinary authoring path rejects the invalid witness.
    // -----------------------------------------------------------------------------------
    let running = World::default();
    check!(
        "ADM-005 source-rejection: Delete against a running Sandbox",
        evaluate(Phase::L0, &running, &Request::DeleteSandbox)
            .iter()
            .any(|r| r.invariant == "ADM-005")
    );

    let closed = World {
        admission: Admission::Closed,
        ..World::default()
    };
    check!(
        "ADM-007 source-rejection: Exec while admission is closed",
        evaluate(
            Phase::E0,
            &closed,
            &Request::Exec {
                launch_authority_revoked: false
            }
        )
        .iter()
        .any(|r| r.invariant == "ADM-007")
    );

    check!(
        "ADM-009 source-rejection: launch under revoked authority",
        evaluate(
            Phase::E1,
            &running,
            &Request::Exec {
                launch_authority_revoked: true
            }
        )
        .iter()
        .any(|r| r.invariant == "ADM-009")
    );

    let no_preconditions = World {
        reconciler_supplied_etag: false,
        ..World::default()
    };
    check!(
        "ADP-012 source-rejection: reconciler without preconditions",
        evaluate(Phase::L0, &no_preconditions, &Request::ReconcilerLiveMutation)
            .iter()
            .any(|r| r.invariant == "ADP-012")
    );

    let replayed = World {
        processes: vec![Process {
            id: "p1".into(),
            epoch: 1,
            state: ProcessState::Running,
            accepted_sequences: vec![7],
            launch_authority_granted: true,
        }],
        ..World::default()
    };
    check!(
        "PIO-004 source-rejection: replayed input frame",
        evaluate(
            Phase::E0,
            &replayed,
            &Request::WriteProcessInput {
                process: "p1".into(),
                sequence: 7
            }
        )
        .iter()
        .any(|r| r.invariant == "PIO-004")
    );

    check!(
        "SBX-004 source-rejection: presentation label stored as state",
        evaluate(
            Phase::L1,
            &running,
            &Request::CommitStatus {
                label: Some("stopping".into())
            }
        )
        .iter()
        .any(|r| r.invariant == "SBX-004")
    );

    let nonterminal = World {
        processes: vec![Process {
            id: "p1".into(),
            epoch: 1,
            state: ProcessState::Running,
            accepted_sequences: vec![],
            launch_authority_granted: true,
        }],
        ..World::default()
    };
    check!(
        "PRC-007 source-rejection: teardown with a nonterminal Process",
        evaluate(Phase::T0, &nonterminal, &Request::Teardown)
            .iter()
            .any(|r| r.invariant == "PRC-007")
    );

    let unsealed = World {
        pending_control_commands: 2,
        retained_output_sealed: false,
        ..World::default()
    };
    check!(
        "PIO-017 source-rejection: teardown discarding a pending command",
        evaluate(Phase::T0, &unsealed, &Request::Teardown)
            .iter()
            .any(|r| r.invariant == "PIO-017")
    );

    // -----------------------------------------------------------------------------------
    // positive-boundary: the nearby valid witness stays expressible.
    // -----------------------------------------------------------------------------------
    let stopped = World {
        status: SandboxStatus::Stopped,
        stopped_proof: true,
        admission: Admission::Closed,
        ..World::default()
    };
    check!(
        "ADM-005 positive-boundary: Delete against a proven-stopped Sandbox",
        evaluate(Phase::L0, &stopped, &Request::DeleteSandbox).is_empty()
    );
    check!(
        "ADM-007 positive-boundary: Exec while accepting",
        evaluate(
            Phase::E0,
            &running,
            &Request::Exec {
                launch_authority_revoked: false
            }
        )
        .is_empty()
    );
    check!(
        "PIO-004 positive-boundary: a fresh sequence is admitted",
        evaluate(
            Phase::E0,
            &replayed,
            &Request::WriteProcessInput {
                process: "p1".into(),
                sequence: 8
            }
        )
        .is_empty()
    );
    check!(
        "SBX-004 positive-boundary: status commit with no label",
        evaluate(Phase::L1, &running, &Request::CommitStatus { label: None }).is_empty()
    );
    let all_terminal = World {
        processes: vec![Process {
            id: "p1".into(),
            epoch: 1,
            state: ProcessState::Terminated,
            accepted_sequences: vec![],
            launch_authority_granted: false,
        }],
        ..World::default()
    };
    check!(
        "PRC-007 positive-boundary: teardown with every Process terminal",
        evaluate(Phase::T0, &all_terminal, &Request::Teardown).is_empty()
    );

    // -----------------------------------------------------------------------------------
    // runtime-probe: declared and observed facts compared. Only meaningful for
    // observed-conformance.
    // -----------------------------------------------------------------------------------
    let lying_driver = World {
        driver_claims_running: true,
        probe_observes_running: false,
        admission: Admission::Accepting,
        ..World::default()
    };
    check!(
        "ADM-012 runtime-probe: accepting published without an observed running epoch",
        evaluate(Phase::R1, &lying_driver, &Request::ProbeLaunch)
            .iter()
            .any(|r| r.invariant == "ADM-012")
    );
    check!(
        "ADM-012 positive-boundary: accepting with an observed running epoch",
        evaluate(Phase::R1, &running, &Request::ProbeLaunch).is_empty()
    );

    // -----------------------------------------------------------------------------------
    // diagnostic: identifies the invariant, names the coordinate, leaks no caller value.
    // -----------------------------------------------------------------------------------
    let d = evaluate(
        Phase::L1,
        &running,
        &Request::CommitStatus {
            label: Some("s3cr3t-token".into()),
        },
    );
    let text = d[0].diagnostic();
    check!(
        "SBX-004 diagnostic: identifies the invariant",
        text.contains("SBX-004")
    );
    check!(
        "SBX-004 diagnostic: names the offending coordinate",
        text.contains("sandbox.status.lifecycleOperation")
    );
    check!(
        "SBX-004 diagnostic: does not echo the caller-supplied value",
        !text.contains("s3cr3t-token")
    );

    // -----------------------------------------------------------------------------------
    // Structural claims the registry makes about itself.
    // -----------------------------------------------------------------------------------
    let hs = hooks();
    let mut ids: Vec<&str> = hs.iter().map(|h| h.invariant).collect();
    ids.sort();
    let mut deduped = ids.clone();
    deduped.dedup();
    check!(
        "exactly one authoritative hook per invariant",
        ids.len() == deduped.len()
    );

    println!("post-launch enforcement slice: {} checks passed", pass);
    if !findings.is_empty() {
        eprintln!();
        for f in &findings {
            eprintln!("{}", f);
        }
        std::process::exit(1);
    }

    println!();
    println!("hooks by rejection deadline:");
    for (phase, invariants) in hooks_by_phase() {
        println!("  {}: {}", phase, invariants.join(", "));
    }
}
