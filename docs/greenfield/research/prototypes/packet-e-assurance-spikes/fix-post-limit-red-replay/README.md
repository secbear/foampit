# Stage 00 post-limit focused RED replay

This bundle pins the round-five candidate at commit
`94aa7a0a2a1476f451b99bd167523361e435a774`, applies only the post-limit
tests, and reproduces four noncomputed-property static-audit failures. One
positive control binds ordinary noncomputed identifier and string keys in both
destructuring and object literals; the fourth negative binds fail-closed
handling for an unsupported key form.

Run from the repository root:

```sh
bash docs/greenfield/research/prototypes/packet-e-assurance-spikes/fix-post-limit-red-replay/replay.sh
```

The wrapper verifies the exact zero-context test-only patch, driver, raw
transcript, and status transcript by SHA-256; creates a detached temporary
worktree at the pinned base; applies only the test patch with Git's explicit
`--unidiff-zero` mode; runs the exact driver in the pinned Nix shell;
byte-compares normalized output and every child status; and uses the shared
exact-target cleanup implementation.

Each negative case executes first in its own hardened child process and binds
exact evidence that the base audit accepted a source which demonstrated its
property-state effect. The parent process is not altered.
