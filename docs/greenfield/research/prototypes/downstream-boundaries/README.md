# Packet D downstream-boundary witnesses

These are disposable research validators for composition-bypass review. They
prove that three downstream inputs are treated as untrusted product data:

- `migrate.sh` validates the exact source-version envelope, validates the old
  semantic payload, performs the one prototype migration, validates the
  migrated payload with the same W0 implementation, and emits one deterministic
  current envelope;
- `validate-built-manifest.jq` rejects open manifest data, unregistered
  protocol tuples, incompatible profile sets, and mismatched semantic, member,
  projection, or member-bound evidence identity; and
- `validate-resolved-driver.jq` accepts only the generated driver-input shape
  and rechecks admitted identity, retained source, filesystem, and network
  bounds before launch.

`test.sh` includes nearby valid controls and corrupts each boundary only after
the preceding representation is valid. It separately demonstrates that an
already-open retained source descriptor continues to identify the admitted
object after its pathname is replaced. These validators establish Packet D
bypass obligations; they are not the production migration system, full target
manifest schema, or driver implementation, and they do not close Gate 4B.
