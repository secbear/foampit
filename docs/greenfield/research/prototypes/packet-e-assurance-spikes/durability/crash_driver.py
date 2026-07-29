"""Subprocess crash matrix comparing SQLite recovery with the pure model."""

from __future__ import annotations

import argparse
import json
import os
import selectors
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Any

from model import (
    TransitionError,
    apply_transition,
    conflict_state,
    initial_state,
)
from sqlite_store import (
    PINNED_SETTINGS,
    StoreError,
    connect,
    effective_settings,
    observable_state,
    seed_database,
)


HERE = Path(__file__).resolve().parent
STORE = HERE / "sqlite_store.py"

SCENARIOS: dict[str, dict[str, Any]] = {
    "atomic-log-append": {
        "predecessor": initial_state,
        "operation": {
            "kind": "log-append",
            "expectedSequence": 0,
            "payload": {"event": "attempt-created", "slot": "slot-1"},
        },
        "faults": [
            "before-begin",
            "after-begin",
            "after-log-insert",
            "before-commit",
            "after-commit-before-reply",
        ],
    },
    "attempt-state-cas": {
        "predecessor": initial_state,
        "operation": {
            "kind": "attempt-cas",
            "attemptId": "attempt-a",
            "expectedState": "reserved",
            "expectedVersion": 0,
            "successorState": "completed",
        },
        "faults": [
            "before-begin",
            "after-begin",
            "after-attempt-cas",
            "before-commit",
            "after-commit-before-reply",
        ],
    },
    "slot-head-cas": {
        "predecessor": initial_state,
        "operation": {
            "kind": "slot-head-cas",
            "slotId": "slot-1",
            "expectedHead": "attempt-a",
            "expectedVersion": 0,
            "successorHead": "attempt-b",
        },
        "faults": [
            "before-begin",
            "after-begin",
            "after-slot-head-cas",
            "before-commit",
            "after-commit-before-reply",
        ],
    },
    "conflict-resolution-multi-cas": {
        "predecessor": conflict_state,
        "operation": {
            "kind": "conflict-resolution",
            "attempts": [
                {
                    "attemptId": "attempt-a",
                    "expectedState": "conflicted",
                    "expectedVersion": 3,
                    "successorState": "superseded",
                },
                {
                    "attemptId": "attempt-b",
                    "expectedState": "conflicted",
                    "expectedVersion": 5,
                    "successorState": "completed",
                },
            ],
            "slot": {
                "slotId": "slot-1",
                "expectedHead": "conflict:attempt-a+attempt-b",
                "expectedVersion": 2,
                "successorHead": "attempt-b",
            },
        },
        "faults": [
            "before-begin",
            "after-begin",
            "after-each-conflict-attempt-cas:1",
            "after-each-conflict-attempt-cas:2",
            "after-slot-head-cas",
            "before-commit",
            "after-commit-before-reply",
        ],
    },
}


def run_store(
    database: Path,
    operation: dict[str, Any],
    fault: str | None = None,
    mutation: str | None = None,
) -> subprocess.Popen[str]:
    environment = dict(os.environ)
    if mutation is not None:
        environment["PACKET_E_SQLITE_MUTATION"] = mutation
    return subprocess.Popen(
        [
            sys.executable,
            str(STORE),
            "--db",
            str(database),
            "--operation-json",
            json.dumps(operation, sort_keys=True, separators=(",", ":")),
            *(["--fault-point", fault] if fault is not None else []),
        ],
        cwd=HERE,
        env=environment,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )


def wait_for_fault(process: subprocess.Popen[str], fault: str) -> None:
    assert process.stdout is not None
    selector = selectors.DefaultSelector()
    selector.register(process.stdout, selectors.EVENT_READ)
    events = selector.select(timeout=10.0)
    selector.close()
    if not events:
        process.kill()
        _, stderr = process.communicate(timeout=5)
        raise AssertionError(f"fault marker timeout at {fault}: {stderr}")
    line = process.stdout.readline().strip()
    if line != f"FAULT:{fault}":
        process.kill()
        stdout, stderr = process.communicate(timeout=5)
        raise AssertionError(
            f"fault marker mismatch at {fault}: line={line!r} stdout={stdout!r} stderr={stderr!r}"
        )


def exercise_crash(
    scenario_name: str, fault: str, mutation: str | None = None
) -> str:
    scenario = SCENARIOS[scenario_name]
    predecessor = scenario["predecessor"]()
    successor = apply_transition(predecessor, scenario["operation"])
    with tempfile.TemporaryDirectory(prefix="packet-e-crash-") as temporary:
        database = Path(temporary) / "evidence.sqlite"
        seed_database(database, predecessor)
        if observable_state(database) != predecessor:
            raise AssertionError("seeded SQLite state differs from pure predecessor")
        process = run_store(database, scenario["operation"], fault, mutation)
        wait_for_fault(process, fault)
        process.kill()
        process.wait(timeout=10)
        recovered = observable_state(database)
    if recovered not in (predecessor, successor):
        raise AssertionError(
            f"partial state after {scenario_name}/{fault}: "
            f"{json.dumps(recovered, sort_keys=True)}"
        )
    expected = successor if fault == "after-commit-before-reply" else predecessor
    if recovered != expected:
        raise AssertionError(
            f"wrong transaction boundary after {scenario_name}/{fault}: "
            f"expected={'successor' if expected is successor else 'predecessor'}"
        )
    return "successor" if recovered == successor else "predecessor"


def exercise_success(
    scenario_name: str, mutation: str | None = None
) -> tuple[dict[str, Any], dict[str, Any]]:
    scenario = SCENARIOS[scenario_name]
    predecessor = scenario["predecessor"]()
    successor = apply_transition(predecessor, scenario["operation"])
    with tempfile.TemporaryDirectory(prefix="packet-e-success-") as temporary:
        database = Path(temporary) / "evidence.sqlite"
        seed_database(database, predecessor)
        process = run_store(database, scenario["operation"], mutation=mutation)
        stdout, stderr = process.communicate(timeout=10)
        if process.returncode != 0:
            raise AssertionError(f"store failed: {stdout}{stderr}")
        recovered = observable_state(database)
    return recovered, successor


def pure_model_test() -> None:
    for name, scenario in SCENARIOS.items():
        predecessor = scenario["predecessor"]()
        successor = apply_transition(predecessor, scenario["operation"])
        if successor == predecessor:
            raise AssertionError(f"pure transition is constant: {name}")
    stale = dict(SCENARIOS["attempt-state-cas"]["operation"])
    stale["expectedVersion"] = 9
    try:
        apply_transition(initial_state(), stale)
    except TransitionError as error:
        if str(error) != "attempt/predecessor-mismatch":
            raise
    else:
        raise AssertionError("pure model accepted a stale CAS")
    print("pure model: PASS transitions=4 staleCAS=1")


def settings_test() -> None:
    with tempfile.TemporaryDirectory(prefix="packet-e-settings-") as temporary:
        database = Path(temporary) / "evidence.sqlite"
        seed_database(database, initial_state())
        connection = connect(database)
        try:
            observed = effective_settings(connection)
        finally:
            connection.close()
        if observed != PINNED_SETTINGS:
            raise AssertionError(f"effective SQLite settings differ: {observed}")
        environment = dict(os.environ)
        environment["PACKET_E_SQLITE_MUTATION"] = "weak-settings"
        result = subprocess.run(
            [
                sys.executable,
                str(STORE),
                "--db",
                str(database),
                "--operation-json",
                json.dumps(SCENARIOS["atomic-log-append"]["operation"]),
            ],
            cwd=HERE,
            env=environment,
            capture_output=True,
            text=True,
        )
    if result.returncode == 0 or "sqlite/settings-mismatch" not in result.stderr:
        raise AssertionError("weak SQLite settings mutation survived")
    print(
        "sqlite settings: PASS "
        "journal_mode=wal synchronous=FULL foreign_keys=ON wal_autocheckpoint=0"
    )


def crash_matrix_test(scenario_name: str) -> None:
    recovered, successor = exercise_success(scenario_name)
    if recovered != successor:
        raise AssertionError(f"normal SQLite transition differs from pure model: {scenario_name}")
    outcomes = {"predecessor": 0, "successor": 0}
    for fault in SCENARIOS[scenario_name]["faults"]:
        outcomes[exercise_crash(scenario_name, fault)] += 1
    print(
        f"crash matrix: PASS scenario={scenario_name} "
        f"kills={sum(outcomes.values())} predecessor={outcomes['predecessor']} "
        f"successor={outcomes['successor']}"
    )


def partial_commit_mutation_test() -> None:
    try:
        exercise_crash(
            "conflict-resolution-multi-cas",
            "after-each-conflict-attempt-cas:1",
            mutation="commit-each",
        )
    except AssertionError as error:
        if "partial state" not in str(error):
            raise
    else:
        raise AssertionError("partial commit mutation survived")
    print("partial commit mutation: KILLED")


def store_model_drift_test() -> None:
    recovered, successor = exercise_success(
        "attempt-state-cas", mutation="store-model-drift"
    )
    if recovered == successor:
        raise AssertionError("store/model drift mutation survived")
    print("store/model drift mutation: KILLED")

def invalid_log_sequence_test(kind: str) -> None:
    predecessor = initial_state()
    if kind in ("stale", "duplicate"):
        predecessor["logs"] = [
            {"sequence": 0, "payload": {"event": "existing-0"}},
            {"sequence": 1, "payload": {"event": "existing-1"}},
        ]
    expected_sequence = {
        "future": 2,
        "stale": 0,
        "duplicate": 1,
    }[kind]
    operation = {
        "kind": "log-append",
        "expectedSequence": expected_sequence,
        "payload": {"event": f"invalid-{kind}"},
    }
    try:
        apply_transition(predecessor, operation)
    except TransitionError as error:
        if str(error) != "log/predecessor-mismatch":
            raise
    else:
        raise AssertionError(f"pure model accepted {kind} log sequence")

    with tempfile.TemporaryDirectory(prefix=f"packet-e-log-{kind}-") as temporary:
        database = Path(temporary) / "evidence.sqlite"
        seed_database(database, predecessor)
        before = observable_state(database)
        process = run_store(database, operation)
        stdout, stderr = process.communicate(timeout=10)
        after = observable_state(database)
    if process.returncode == 0:
        raise AssertionError(f"SQLite store accepted {kind} log sequence")
    if "log/predecessor-mismatch" not in stderr:
        raise AssertionError(
            f"SQLite store/model error mismatch for {kind}: {stdout}{stderr}"
        )
    if before != predecessor or after != predecessor:
        raise AssertionError(f"SQLite state changed after rejected {kind} log append")
    print(f"log sequence rejection: PASS kind={kind} state=unchanged")


def expect_observation_rejected(database: Path) -> None:
    try:
        observable_state(database)
    except StoreError as error:
        if "observation/schema-mismatch" not in str(error):
            raise
    else:
        raise AssertionError("malformed observation schema was accepted")


def observer_missing_database_test() -> None:
    with tempfile.TemporaryDirectory(prefix="packet-e-observer-missing-") as temporary:
        database = Path(temporary) / "absent.sqlite"
        expect_observation_rejected(database)
        if database.exists():
            raise AssertionError("observable_state created the missing database")
    print("read-only observer: PASS missing database rejected without creation")


def observer_extra_table_test() -> None:
    with tempfile.TemporaryDirectory(prefix="packet-e-observer-extra-") as temporary:
        database = Path(temporary) / "evidence.sqlite"
        seed_database(database, initial_state())
        connection = connect(database)
        try:
            connection.execute("CREATE TABLE shadow_semantics(value TEXT)")
        finally:
            connection.close()
        expect_observation_rejected(database)
        connection = connect(database)
        try:
            names = {
                row[0]
                for row in connection.execute(
                    "SELECT name FROM sqlite_master WHERE type = 'table'"
                )
            }
        finally:
            connection.close()
        if "shadow_semantics" not in names:
            raise AssertionError("observable_state mutated the extra-table schema")
    print("read-only observer: PASS exact table inventory enforced")


def observer_schema_shape_test() -> None:
    with tempfile.TemporaryDirectory(prefix="packet-e-observer-shape-") as temporary:
        database = Path(temporary) / "evidence.sqlite"
        seed_database(database, initial_state())
        connection = connect(database)
        try:
            connection.execute("ALTER TABLE metadata ADD COLUMN hidden_semantics TEXT")
        finally:
            connection.close()
        expect_observation_rejected(database)
        connection = connect(database)
        try:
            columns = [
                row[1] for row in connection.execute("PRAGMA table_info(metadata)")
            ]
        finally:
            connection.close()
        if columns != ["key", "value", "hidden_semantics"]:
            raise AssertionError("observable_state mutated the table shape")
    print("read-only observer: PASS exact schema shape enforced")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--case",
        required=True,
        choices=[
            "pure-model-transitions",
            "sqlite-settings",
            "atomic-log-append",
            "attempt-state-cas",
            "slot-head-cas",
            "conflict-resolution-multi-cas",
            "partial-commit-mutation",
            "store-model-drift",
            "log-sequence-future",
            "log-sequence-stale",
            "log-sequence-duplicate",
            "observer-missing-database",
            "observer-extra-table",
            "observer-schema-shape",
        ],
    )
    args = parser.parse_args()
    if args.case == "pure-model-transitions":
        pure_model_test()
    elif args.case == "sqlite-settings":
        settings_test()
    elif args.case in SCENARIOS:
        crash_matrix_test(args.case)
    elif args.case == "partial-commit-mutation":
        partial_commit_mutation_test()
    elif args.case == "store-model-drift":
        store_model_drift_test()
    elif args.case.startswith("log-sequence-"):
        invalid_log_sequence_test(args.case.removeprefix("log-sequence-"))
    elif args.case == "observer-missing-database":
        observer_missing_database_test()
    elif args.case == "observer-extra-table":
        observer_extra_table_test()
    elif args.case == "observer-schema-shape":
        observer_schema_shape_test()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
