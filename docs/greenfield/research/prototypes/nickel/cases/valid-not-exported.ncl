let lexical_local = "available-during-evaluation" in
{
  visible = lexical_local,
  hidden | not_exported = "absent-from-serialization",
  nested = {
    kept = true,
    hidden | not_exported = true,
  },
}
