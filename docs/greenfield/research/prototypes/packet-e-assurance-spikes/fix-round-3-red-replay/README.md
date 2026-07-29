# Stage 00 round-three focused RED replay

This bundle pins the round-two candidate at commit
`8389224046bd2c8c1c56f5e113bdae2aca2d68e9`, applies only the round-three
tests, and reproduces eight focused failures plus one positive compiler-recursor
control.

Run:

```sh
bash replay.sh
```

`replay.sh` verifies the patch digest, creates a detached worktree, confines the
child process's temporary directory beneath the wrapper-owned root, compares
the canonical transcript byte-for-byte, removes or prunes the exact worktree
registration, and verifies cleanup before returning.
