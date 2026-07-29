"""SQLite WAL refinement used only by the Packet E Stage 00 crash spike."""

from __future__ import annotations

import argparse
import json
import os
import sqlite3
import sys
import time
from pathlib import Path
from typing import Any


SCHEMA_REVISION = "packet-e-durability-spike-v1"
PINNED_SETTINGS = {
    "journal_mode": "wal",
    "synchronous": 2,
    "foreign_keys": 1,
    "wal_autocheckpoint": 0,
}
EXPECTED_TABLES = {
    "metadata": [
        ("key", "TEXT", 1, None, 1),
        ("value", "TEXT", 1, None, 0),
    ],
    "log_entries": [
        ("sequence", "INTEGER", 0, None, 1),
        ("payload", "TEXT", 1, None, 0),
    ],
    "attempts": [
        ("attempt_id", "TEXT", 1, None, 1),
        ("state", "TEXT", 1, None, 0),
        ("version", "INTEGER", 1, None, 0),
    ],
    "slots": [
        ("slot_id", "TEXT", 1, None, 1),
        ("head", "TEXT", 1, None, 0),
        ("version", "INTEGER", 1, None, 0),
    ],
}
EXPECTED_WITHOUT_ROWID = {
    "metadata": 1,
    "log_entries": 0,
    "attempts": 1,
    "slots": 1,
}


class StoreError(Exception):
    pass


class FaultController:
    def __init__(self, requested: str | None):
        self.requested = requested
        self.reached: list[str] = []

    def reach(self, name: str) -> None:
        self.reached.append(name)
        if self.requested == name:
            print(f"FAULT:{name}", flush=True)
            while True:
                time.sleep(3600)

    def assert_reached(self) -> None:
        if self.requested is not None and self.requested not in self.reached:
            raise StoreError(f"fault-point/not-reached:{self.requested}")


def connect(database: Path) -> sqlite3.Connection:
    connection = sqlite3.connect(database, isolation_level=None, timeout=30.0)
    connection.execute("PRAGMA journal_mode=WAL")
    connection.execute("PRAGMA synchronous=FULL")
    connection.execute("PRAGMA foreign_keys=ON")
    connection.execute("PRAGMA wal_autocheckpoint=0")
    connection.execute("PRAGMA busy_timeout=30000")
    assert_effective_settings(connection)
    return connection


def effective_settings(connection: sqlite3.Connection) -> dict[str, Any]:
    return {
        "journal_mode": str(connection.execute("PRAGMA journal_mode").fetchone()[0]).lower(),
        "synchronous": int(connection.execute("PRAGMA synchronous").fetchone()[0]),
        "foreign_keys": int(connection.execute("PRAGMA foreign_keys").fetchone()[0]),
        "wal_autocheckpoint": int(
            connection.execute("PRAGMA wal_autocheckpoint").fetchone()[0]
        ),
    }


def assert_effective_settings(connection: sqlite3.Connection) -> None:
    observed = effective_settings(connection)
    if os.environ.get("PACKET_E_SQLITE_MUTATION") == "weak-settings":
        observed["synchronous"] = 1
    if observed != PINNED_SETTINGS:
        raise StoreError(f"sqlite/settings-mismatch:{observed}")


def initialize_schema(connection: sqlite3.Connection) -> None:
    connection.executescript(
        """
        CREATE TABLE IF NOT EXISTS metadata (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        ) WITHOUT ROWID;
        CREATE TABLE IF NOT EXISTS log_entries (
          sequence INTEGER PRIMARY KEY,
          payload TEXT NOT NULL
        );
        CREATE TABLE IF NOT EXISTS attempts (
          attempt_id TEXT PRIMARY KEY,
          state TEXT NOT NULL,
          version INTEGER NOT NULL CHECK (version >= 0)
        ) WITHOUT ROWID;
        CREATE TABLE IF NOT EXISTS slots (
          slot_id TEXT PRIMARY KEY,
          head TEXT NOT NULL,
          version INTEGER NOT NULL CHECK (version >= 0)
        ) WITHOUT ROWID;
        """
    )


def seed_database(database: Path, state: dict[str, Any]) -> None:
    connection = connect(database)
    try:
        initialize_schema(connection)
        connection.execute("BEGIN IMMEDIATE")
        connection.execute("DELETE FROM log_entries")
        connection.execute("DELETE FROM attempts")
        connection.execute("DELETE FROM slots")
        connection.execute("DELETE FROM metadata")
        for key, value in sorted(state["metadata"].items()):
            connection.execute(
                "INSERT INTO metadata(key, value) VALUES (?, ?)", (key, value)
            )
        for entry in state["logs"]:
            connection.execute(
                "INSERT INTO log_entries(sequence, payload) VALUES (?, ?)",
                (
                    entry["sequence"],
                    json.dumps(entry["payload"], sort_keys=True, separators=(",", ":")),
                ),
            )
        for attempt_id, attempt in sorted(state["attempts"].items()):
            connection.execute(
                "INSERT INTO attempts(attempt_id, state, version) VALUES (?, ?, ?)",
                (attempt_id, attempt["state"], attempt["version"]),
            )
        for slot_id, slot in sorted(state["slots"].items()):
            connection.execute(
                "INSERT INTO slots(slot_id, head, version) VALUES (?, ?, ?)",
                (slot_id, slot["head"], slot["version"]),
            )
        connection.execute("COMMIT")
    finally:
        connection.close()


def observable_state(database: Path) -> dict[str, Any]:
    if not database.is_file():
        raise StoreError("observation/schema-mismatch:database-absent")
    try:
        connection = sqlite3.connect(
            f"{database.resolve().as_uri()}?mode=ro",
            uri=True,
            isolation_level=None,
            timeout=30.0,
        )
    except sqlite3.Error as error:
        raise StoreError(f"observation/schema-mismatch:{error}") from error
    try:
        table_rows = connection.execute("PRAGMA table_list").fetchall()
        observed_tables = {
            name: (columns, without_rowid, strict)
            for schema, name, kind, columns, without_rowid, strict in table_rows
            if schema == "main" and kind == "table" and not name.startswith("sqlite_")
        }
        expected_inventory = {
            name: (len(columns), EXPECTED_WITHOUT_ROWID[name], 0)
            for name, columns in EXPECTED_TABLES.items()
        }
        if observed_tables != expected_inventory:
            raise StoreError(
                f"observation/schema-mismatch:tables={sorted(observed_tables)}"
            )
        for table, expected_columns in EXPECTED_TABLES.items():
            observed_columns = [
                (name, column_type.upper(), not_null, default, primary_key)
                for _, name, column_type, not_null, default, primary_key
                in connection.execute(f"PRAGMA table_info({table})")
            ]
            if observed_columns != expected_columns:
                raise StoreError(
                    f"observation/schema-mismatch:columns={table}"
                )
        metadata = {
            key: value
            for key, value in connection.execute(
                "SELECT key, value FROM metadata ORDER BY key"
            )
        }
        logs = [
            {"sequence": sequence, "payload": json.loads(payload)}
            for sequence, payload in connection.execute(
                "SELECT sequence, payload FROM log_entries ORDER BY sequence"
            )
        ]
        attempts = {
            attempt_id: {"state": state, "version": version}
            for attempt_id, state, version in connection.execute(
                "SELECT attempt_id, state, version FROM attempts ORDER BY attempt_id"
            )
        }
        slots = {
            slot_id: {"head": head, "version": version}
            for slot_id, head, version in connection.execute(
                "SELECT slot_id, head, version FROM slots ORDER BY slot_id"
            )
        }
        state = {
            "metadata": metadata,
            "logs": logs,
            "attempts": attempts,
            "slots": slots,
        }
        if state["metadata"].get("schema_revision") != SCHEMA_REVISION:
            raise StoreError("observation/schema-mismatch:revision")
        return state
    except sqlite3.Error as error:
        raise StoreError(f"observation/schema-mismatch:{error}") from error
    finally:
        connection.close()


def mutation_commit_boundary(connection: sqlite3.Connection) -> None:
    if os.environ.get("PACKET_E_SQLITE_MUTATION") == "commit-each":
        connection.execute("COMMIT")
        connection.execute("BEGIN IMMEDIATE")


def require_one_row(cursor: sqlite3.Cursor, code: str) -> None:
    if cursor.rowcount != 1:
        raise StoreError(code)


def apply_operation(
    database: Path, operation: dict[str, Any], requested_fault: str | None = None
) -> None:
    fault = FaultController(requested_fault)
    connection = connect(database)
    try:
        fault.reach("before-begin")
        connection.execute("BEGIN IMMEDIATE")
        fault.reach("after-begin")
        kind = operation["kind"]
        if kind == "log-append":
            cursor = connection.execute(
                """
                INSERT INTO log_entries(sequence, payload)
                SELECT ?, ?
                 WHERE ? = (SELECT COUNT(*) FROM log_entries)
                   AND NOT EXISTS (
                     SELECT 1 FROM log_entries WHERE sequence = ?
                   )
                """,
                (
                    operation["expectedSequence"],
                    json.dumps(operation["payload"], sort_keys=True, separators=(",", ":")),
                    operation["expectedSequence"],
                    operation["expectedSequence"],
                ),
            )
            require_one_row(cursor, "log/predecessor-mismatch")
            mutation_commit_boundary(connection)
            fault.reach("after-log-insert")
        elif kind == "attempt-cas":
            successor_state = operation["successorState"]
            if os.environ.get("PACKET_E_SQLITE_MUTATION") == "store-model-drift":
                successor_state = "mutated-successor"
            cursor = connection.execute(
                """
                UPDATE attempts
                   SET state = ?, version = version + 1
                 WHERE attempt_id = ? AND state = ? AND version = ?
                """,
                (
                    successor_state,
                    operation["attemptId"],
                    operation["expectedState"],
                    operation["expectedVersion"],
                ),
            )
            require_one_row(cursor, "attempt/predecessor-mismatch")
            mutation_commit_boundary(connection)
            fault.reach("after-attempt-cas")
        elif kind == "slot-head-cas":
            cursor = connection.execute(
                """
                UPDATE slots
                   SET head = ?, version = version + 1
                 WHERE slot_id = ? AND head = ? AND version = ?
                """,
                (
                    operation["successorHead"],
                    operation["slotId"],
                    operation["expectedHead"],
                    operation["expectedVersion"],
                ),
            )
            require_one_row(cursor, "slot/predecessor-mismatch")
            mutation_commit_boundary(connection)
            fault.reach("after-slot-head-cas")
        elif kind == "conflict-resolution":
            for index, transition in enumerate(operation["attempts"], start=1):
                cursor = connection.execute(
                    """
                    UPDATE attempts
                       SET state = ?, version = version + 1
                     WHERE attempt_id = ? AND state = ? AND version = ?
                    """,
                    (
                        transition["successorState"],
                        transition["attemptId"],
                        transition["expectedState"],
                        transition["expectedVersion"],
                    ),
                )
                require_one_row(cursor, "conflict/attempt-predecessor-mismatch")
                mutation_commit_boundary(connection)
                fault.reach(f"after-each-conflict-attempt-cas:{index}")
            slot = operation["slot"]
            cursor = connection.execute(
                """
                UPDATE slots
                   SET head = ?, version = version + 1
                 WHERE slot_id = ? AND head = ? AND version = ?
                """,
                (
                    slot["successorHead"],
                    slot["slotId"],
                    slot["expectedHead"],
                    slot["expectedVersion"],
                ),
            )
            require_one_row(cursor, "conflict/slot-predecessor-mismatch")
            mutation_commit_boundary(connection)
            fault.reach("after-slot-head-cas")
        else:
            raise StoreError("operation/unknown-kind")
        fault.reach("before-commit")
        connection.execute("COMMIT")
        fault.reach("after-commit-before-reply")
        fault.assert_reached()
    except BaseException:
        if connection.in_transaction:
            connection.execute("ROLLBACK")
        raise
    finally:
        connection.close()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--db", required=True)
    parser.add_argument("--operation-json", required=True)
    parser.add_argument("--fault-point")
    args = parser.parse_args()
    try:
        apply_operation(
            Path(args.db), json.loads(args.operation_json), args.fault_point
        )
    except (StoreError, sqlite3.Error, KeyError, ValueError) as error:
        print(f"sqlite store: {error}", file=sys.stderr)
        return 2
    print("REPLY:committed", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
