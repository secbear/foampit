def closed($allowed):
  (type == "object") and ((keys | sort) == ($allowed | sort));

if type != "object" then
  error("MIG-001: migration input must be an object")
elif .schemaVersion == 0 then
  if closed(["artifact", "schemaVersion"]) and
     (.artifact | type == "object")
  then
    {
      schemaVersion: 1,
      artifact: .artifact
    }
  else
    error("MIG-001: schema version 0 must match its exact closed input schema")
  end
elif .schemaVersion == 1 then
  if closed(["artifact", "schemaVersion"]) and
     (.artifact | type == "object")
  then .
  else
    error("MIG-001: schema version 1 must match its exact closed input schema")
  end
else
  error("MIG-001: unsupported migration source version")
end
