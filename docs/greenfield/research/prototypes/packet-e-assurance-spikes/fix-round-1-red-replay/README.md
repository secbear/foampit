# Fix round 1 RED replay

This bundle supersedes the three `fix-round-1-red.json` claim-only records. It
contains the complete test-only patch, the exact base commit, every focused
command and exit status, and the normalized raw output for all 25 RED cases.

- Base commit: `6462aa751470cdd08d49f1792432871a17d35fb3`
- Test-only patch: `test-only.patch`
- Patch SHA-256:
  `12113c290d212c74b10ca0c8f20a3475837e8fbff631b62c572566b533fee107`
- Expected transcript: `raw-output.txt`

From any clone containing the base commit, run:

```bash
bash docs/greenfield/research/prototypes/packet-e-assurance-spikes/fix-round-1-red-replay/replay.sh
```

The wrapper verifies the patch hash, creates a detached temporary worktree at
the base commit, applies only the committed test patch, runs the driver through
the pinned spike development shell, checks every child exit is `1`, compares
the complete transcript byte-for-byte, and removes the temporary worktree.

`<SPIKE>` and `<WORKTREE>` are the only path normalizations in the transcript;
all command text, exit statuses, and process output remain otherwise unchanged.
