# Stage 00 round-five focused RED replay

This bundle pins the round-four candidate at commit
`7373f4d97dcdb30992875743484de6f0d5b9e51e`, applies only the round-five
tests, and reproduces four static-audit failures plus four exact runtime
omission outcomes. Four positive controls bind resolved computed access,
an allowed builtin named re-export, and both post-removal inventory-failure
cleanup status paths.

Run from the repository root:

```sh
bash docs/greenfield/research/prototypes/packet-e-assurance-spikes/fix-round-5-red-replay/replay.sh
```

The wrapper verifies the exact zero-context test-only patch, driver, raw
transcript, and status transcript by SHA-256; creates a detached temporary
worktree at the pinned base; applies only the test patch with Git's explicit
`--unidiff-zero` mode; runs the exact driver in the pinned Nix shell;
byte-compares normalized output and every child status; and uses the shared
exact-target cleanup implementation.

The two computed-member cases execute only in child processes and bind exact
evidence that the base audit accepted a source which had already demonstrated
prototype mutation. The four runtime cases call the base candidate's existing
`invoke` function directly and bind the exact status/output observed when one
hardening control is omitted. They do not call the absent helper that made the
round-four historical runtime RED claim invalid.
