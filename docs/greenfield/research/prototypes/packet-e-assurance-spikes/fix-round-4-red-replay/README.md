# Stage 00 round-four focused RED replay

This bundle pins the round-three candidate at commit
`2eb96731e6d4ea4f143cd607fbaa2f92ad34da69`, applies only the round-four
tests, and reproduces nine focused JavaScript/runtime/cleanup failures plus
three positive controls.

Run from the repository root:

```sh
bash docs/greenfield/research/prototypes/packet-e-assurance-spikes/fix-round-4-red-replay/replay.sh
```

The wrapper verifies the exact zero-context test-only patch, driver,
raw-transcript, and status-transcript digests; creates a detached worktree at
the pinned base; applies the patch explicitly with Git's `--unidiff-zero`
format option; confines the child temporary directory beneath a wrapper-owned
canonical root; runs the driver in the pinned Nix shell; compares both the
normalized transcript and every child exit status byte-for-byte; and uses only
exact-target worktree removal during cleanup.
