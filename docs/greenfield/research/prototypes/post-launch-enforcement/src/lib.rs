//! Minimal model of the post-launch product phases, sufficient to place authoritative
//! enforcement hooks and run the test kinds the invariant registry declares.
//!
//! Deliberately dependency-free. The question this slice answers is whether an invariant
//! declared with one owner, one first-sound phase, one rejection deadline, one disposition
//! and three-to-five planned test kinds can actually be implemented that way.

use std::collections::BTreeMap;
use std::fmt;

// ---------------------------------------------------------------------------------------
// Phases, owners, dispositions -- mirroring the registry vocabularies.
// ---------------------------------------------------------------------------------------

#[derive(Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Debug)]
pub enum Phase {
    F0,
    S0,
    C0,
    O0,
    H0,
    D0,
    R0,
    R1,
    L0,
    L1,
    E0,
    E1,
    T0,
}

impl fmt::Display for Phase {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{:?}", self)
    }
}

#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum Owner {
    Live,
    Exec,
    Core,
    Runtime,
    Framework,
    Service,
}

#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum Disposition {
    Unrepresentable,
    RejectAtBoundary,
    ObservedConformance,
}

// ---------------------------------------------------------------------------------------
// The sealed rejection registry.
//
// ERR-002 and ERR-003 say a rejection outside the sealed registry is UNREPRESENTABLE. That
// is a type-level claim, so the reason is a closed enum with no free-text arm and no
// `Other(String)`. There is deliberately no constructor from a string.
// ---------------------------------------------------------------------------------------

#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum RequestError {
    InvalidState,
    AdmissionClosed,
    ConcurrentOperation,
    StaleRuntime,
    PreconditionRequired,
    CapabilityUnsupported,
    SequenceConflict,
}

#[derive(Clone, Debug)]
pub struct Rejection {
    pub invariant: &'static str,
    pub error: RequestError,
    pub subject: String,
}

impl Rejection {
    /// Diagnostics identify the invariant and name the offending coordinate. They never
    /// carry a caller-supplied value, so a secret cannot reach a diagnostic by construction.
    pub fn diagnostic(&self) -> String {
        format!("{}: {:?} at {}", self.invariant, self.error, self.subject)
    }
}

pub type Decision = Result<(), Rejection>;

// ---------------------------------------------------------------------------------------
// The world the hooks read. Minimal, but real enough that a check can be wrong.
// ---------------------------------------------------------------------------------------

#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum SandboxStatus {
    Provisioning,
    Running,
    Suspended,
    Stopped,
    StateUnknown,
}

#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum Admission {
    Accepting,
    Closed,
}

#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum ProcessState {
    Accepted,
    Starting,
    Running,
    StateUnknown,
    Terminated,
}

#[derive(Clone, Debug)]
pub struct Process {
    pub id: String,
    pub epoch: u64,
    pub state: ProcessState,
    /// Sequence numbers already accepted on this Process's control coordinate.
    pub accepted_sequences: Vec<u64>,
    pub launch_authority_granted: bool,
}

#[derive(Clone, Debug)]
pub struct World {
    pub status: SandboxStatus,
    pub admission: Admission,
    pub epoch: u64,
    /// Proof that no Process-bearing runtime from the prior epoch can still act.
    pub stopped_proof: bool,
    /// Set once an expiry instant is durably recorded as a system trigger.
    pub expiry_trigger_recorded: bool,
    pub processes: Vec<Process>,
    pub retained_output_sealed: bool,
    pub pending_control_commands: usize,
    /// What the driver CLAIMS. Separate from what a probe OBSERVES -- the split the
    /// observed-conformance disposition exists to police.
    pub driver_claims_running: bool,
    pub probe_observes_running: bool,
    pub probe_observes_all_processes_terminal: bool,
    /// Presentation labels a caller or reconciler tried to store as state.
    pub stored_presentation_label: Option<String>,
    /// Preconditions a desired-state reconciler supplied.
    pub reconciler_supplied_etag: bool,
    pub reconciler_supplied_epoch: bool,
}

impl Default for World {
    fn default() -> Self {
        World {
            status: SandboxStatus::Running,
            admission: Admission::Accepting,
            epoch: 1,
            stopped_proof: false,
            expiry_trigger_recorded: false,
            processes: Vec::new(),
            retained_output_sealed: false,
            pending_control_commands: 0,
            driver_claims_running: true,
            probe_observes_running: true,
            probe_observes_all_processes_terminal: true,
            stored_presentation_label: None,
            reconciler_supplied_etag: true,
            reconciler_supplied_epoch: true,
        }
    }
}

// ---------------------------------------------------------------------------------------
// The request surface. A request is what a caller can express.
// ---------------------------------------------------------------------------------------

#[derive(Clone, Debug)]
pub enum Request {
    DeleteSandbox,
    Exec { launch_authority_revoked: bool },
    WriteProcessInput { process: String, sequence: u64 },
    ReconcilerLiveMutation,
    CommitStatus { label: Option<String> },
    Teardown,
    ProbeLaunch,
}

// ---------------------------------------------------------------------------------------
// Hook registry. Exactly one authoritative hook per invariant, as the registry declares.
// ---------------------------------------------------------------------------------------

pub struct Hook {
    pub invariant: &'static str,
    pub owner: Owner,
    pub first_sound: Phase,
    pub deadline: Phase,
    pub disposition: Disposition,
    pub check: fn(&World, &Request) -> Decision,
}

pub fn hooks() -> Vec<Hook> {
    vec![
        Hook {
            invariant: "ADM-005",
            owner: Owner::Live,
            first_sound: Phase::L0,
            deadline: Phase::L0,
            disposition: Disposition::RejectAtBoundary,
            check: |w, r| match r {
                Request::DeleteSandbox if !(w.status == SandboxStatus::Stopped && w.stopped_proof) => {
                    Err(Rejection {
                        invariant: "ADM-005",
                        error: RequestError::InvalidState,
                        subject: "sandbox.status.runtime".into(),
                    })
                }
                _ => Ok(()),
            },
        },
        Hook {
            invariant: "ADM-007",
            owner: Owner::Exec,
            first_sound: Phase::E0,
            deadline: Phase::E0,
            disposition: Disposition::RejectAtBoundary,
            check: |w, r| match r {
                Request::Exec { .. }
                    if w.admission == Admission::Closed || w.expiry_trigger_recorded =>
                {
                    Err(Rejection {
                        invariant: "ADM-007",
                        error: RequestError::AdmissionClosed,
                        subject: "sandbox.status.execution".into(),
                    })
                }
                _ => Ok(()),
            },
        },
        Hook {
            invariant: "ADM-009",
            owner: Owner::Core,
            first_sound: Phase::E0,
            deadline: Phase::E1,
            disposition: Disposition::RejectAtBoundary,
            check: |_, r| match r {
                Request::Exec {
                    launch_authority_revoked: true,
                } => Err(Rejection {
                    invariant: "ADM-009",
                    error: RequestError::StaleRuntime,
                    subject: "process.launchAuthority".into(),
                }),
                _ => Ok(()),
            },
        },
        Hook {
            invariant: "ADM-012",
            owner: Owner::Core,
            first_sound: Phase::R1,
            deadline: Phase::R1,
            disposition: Disposition::ObservedConformance,
            check: |w, r| match r {
                Request::ProbeLaunch
                    if w.admission == Admission::Accepting && !w.probe_observes_running =>
                {
                    Err(Rejection {
                        invariant: "ADM-012",
                        error: RequestError::InvalidState,
                        subject: "sandbox.status.execution".into(),
                    })
                }
                _ => Ok(()),
            },
        },
        Hook {
            invariant: "ADP-012",
            owner: Owner::Service,
            first_sound: Phase::S0,
            deadline: Phase::L0,
            disposition: Disposition::RejectAtBoundary,
            check: |w, r| match r {
                Request::ReconcilerLiveMutation
                    if !(w.reconciler_supplied_etag && w.reconciler_supplied_epoch) =>
                {
                    Err(Rejection {
                        invariant: "ADP-012",
                        error: RequestError::PreconditionRequired,
                        subject: "request.preconditions".into(),
                    })
                }
                _ => Ok(()),
            },
        },
        Hook {
            invariant: "PIO-004",
            owner: Owner::Exec,
            first_sound: Phase::E0,
            deadline: Phase::E0,
            disposition: Disposition::Unrepresentable,
            check: |w, r| match r {
                Request::WriteProcessInput { process, sequence } => {
                    let replayed = w
                        .processes
                        .iter()
                        .find(|p| &p.id == process)
                        .map(|p| p.accepted_sequences.contains(sequence))
                        .unwrap_or(false);
                    if replayed {
                        Err(Rejection {
                            invariant: "PIO-004",
                            error: RequestError::SequenceConflict,
                            subject: "process.control.sequence".into(),
                        })
                    } else {
                        Ok(())
                    }
                }
                _ => Ok(()),
            },
        },
        Hook {
            invariant: "SBX-004",
            owner: Owner::Core,
            first_sound: Phase::L1,
            deadline: Phase::L1,
            disposition: Disposition::Unrepresentable,
            check: |_, r| match r {
                Request::CommitStatus { label: Some(l) } => Err(Rejection {
                    invariant: "SBX-004",
                    error: RequestError::InvalidState,
                    subject: format!("sandbox.status.lifecycleOperation<{}>", l.len()),
                }),
                _ => Ok(()),
            },
        },
        Hook {
            invariant: "PRC-007",
            owner: Owner::Core,
            first_sound: Phase::T0,
            deadline: Phase::T0,
            disposition: Disposition::ObservedConformance,
            check: |w, r| match r {
                Request::Teardown
                    if w.processes.iter().any(|p| p.state != ProcessState::Terminated) =>
                {
                    Err(Rejection {
                        invariant: "PRC-007",
                        error: RequestError::InvalidState,
                        subject: "process.state".into(),
                    })
                }
                _ => Ok(()),
            },
        },
        Hook {
            invariant: "PIO-017",
            owner: Owner::Core,
            first_sound: Phase::T0,
            deadline: Phase::T0,
            disposition: Disposition::RejectAtBoundary,
            check: |w, r| match r {
                Request::Teardown if w.pending_control_commands > 0 && !w.retained_output_sealed => {
                    Err(Rejection {
                        invariant: "PIO-017",
                        error: RequestError::InvalidState,
                        subject: "process.output.retained".into(),
                    })
                }
                _ => Ok(()),
            },
        },
    ]
}

/// Runs every hook whose deadline is the given phase. This is the model of "the
/// authoritative boundary with complete information rejects it".
pub fn evaluate(phase: Phase, world: &World, request: &Request) -> Vec<Rejection> {
    hooks()
        .into_iter()
        .filter(|h| h.deadline == phase)
        .filter_map(|h| (h.check)(world, request).err())
        .collect()
}

/// Which invariants have an authoritative hook at each phase.
pub fn hooks_by_phase() -> BTreeMap<String, Vec<&'static str>> {
    let mut m: BTreeMap<String, Vec<&'static str>> = BTreeMap::new();
    for h in hooks() {
        m.entry(h.deadline.to_string()).or_default().push(h.invariant);
    }
    m
}
