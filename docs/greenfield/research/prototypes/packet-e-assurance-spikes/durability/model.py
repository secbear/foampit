"""Pure Packet E assurance-spike transition model.

This is feasibility evidence only.  It owns no production semantics and has no
SQLite dependency.
"""

from __future__ import annotations

from copy import deepcopy
from dataclasses import dataclass
from typing import Any


@dataclass(frozen=True)
class TransitionError(Exception):
    code: str

    def __str__(self) -> str:
        return self.code


def initial_state() -> dict[str, Any]:
    return {
        "metadata": {"schema_revision": "packet-e-durability-spike-v1"},
        "logs": [],
        "attempts": {
            "attempt-a": {"state": "reserved", "version": 0},
            "attempt-b": {"state": "reserved", "version": 0},
        },
        "slots": {
            "slot-1": {"head": "attempt-a", "version": 0},
        },
    }


def conflict_state() -> dict[str, Any]:
    state = initial_state()
    state["attempts"]["attempt-a"] = {"state": "conflicted", "version": 3}
    state["attempts"]["attempt-b"] = {"state": "conflicted", "version": 5}
    state["slots"]["slot-1"] = {"head": "conflict:attempt-a+attempt-b", "version": 2}
    return state


def atomic_log_append(
    predecessor: dict[str, Any], expected_sequence: int, payload: dict[str, Any]
) -> dict[str, Any]:
    if expected_sequence != len(predecessor["logs"]):
        raise TransitionError("log/predecessor-mismatch")
    successor = deepcopy(predecessor)
    successor["logs"].append({"sequence": expected_sequence, "payload": deepcopy(payload)})
    return successor


def attempt_state_cas(
    predecessor: dict[str, Any],
    attempt_id: str,
    expected_state: str,
    expected_version: int,
    successor_state: str,
) -> dict[str, Any]:
    attempt = predecessor["attempts"].get(attempt_id)
    if attempt is None:
        raise TransitionError("attempt/not-found")
    if attempt != {"state": expected_state, "version": expected_version}:
        raise TransitionError("attempt/predecessor-mismatch")
    successor = deepcopy(predecessor)
    successor["attempts"][attempt_id] = {
        "state": successor_state,
        "version": expected_version + 1,
    }
    return successor


def slot_head_cas(
    predecessor: dict[str, Any],
    slot_id: str,
    expected_head: str,
    expected_version: int,
    successor_head: str,
) -> dict[str, Any]:
    slot = predecessor["slots"].get(slot_id)
    if slot is None:
        raise TransitionError("slot/not-found")
    if slot != {"head": expected_head, "version": expected_version}:
        raise TransitionError("slot/predecessor-mismatch")
    successor = deepcopy(predecessor)
    successor["slots"][slot_id] = {
        "head": successor_head,
        "version": expected_version + 1,
    }
    return successor


def conflict_resolution_multi_cas(
    predecessor: dict[str, Any],
    attempts: list[dict[str, Any]],
    slot: dict[str, Any],
) -> dict[str, Any]:
    successor = deepcopy(predecessor)
    seen: set[str] = set()
    for transition in attempts:
        attempt_id = transition["attemptId"]
        if attempt_id in seen:
            raise TransitionError("conflict/duplicate-attempt")
        seen.add(attempt_id)
        observed = predecessor["attempts"].get(attempt_id)
        expected = {
            "state": transition["expectedState"],
            "version": transition["expectedVersion"],
        }
        if observed != expected:
            raise TransitionError("conflict/attempt-predecessor-mismatch")
        successor["attempts"][attempt_id] = {
            "state": transition["successorState"],
            "version": transition["expectedVersion"] + 1,
        }
    observed_slot = predecessor["slots"].get(slot["slotId"])
    expected_slot = {
        "head": slot["expectedHead"],
        "version": slot["expectedVersion"],
    }
    if observed_slot != expected_slot:
        raise TransitionError("conflict/slot-predecessor-mismatch")
    successor["slots"][slot["slotId"]] = {
        "head": slot["successorHead"],
        "version": slot["expectedVersion"] + 1,
    }
    return successor


def apply_transition(predecessor: dict[str, Any], operation: dict[str, Any]) -> dict[str, Any]:
    kind = operation["kind"]
    if kind == "log-append":
        return atomic_log_append(
            predecessor, operation["expectedSequence"], operation["payload"]
        )
    if kind == "attempt-cas":
        return attempt_state_cas(
            predecessor,
            operation["attemptId"],
            operation["expectedState"],
            operation["expectedVersion"],
            operation["successorState"],
        )
    if kind == "slot-head-cas":
        return slot_head_cas(
            predecessor,
            operation["slotId"],
            operation["expectedHead"],
            operation["expectedVersion"],
            operation["successorHead"],
        )
    if kind == "conflict-resolution":
        return conflict_resolution_multi_cas(
            predecessor, operation["attempts"], operation["slot"]
        )
    raise TransitionError("operation/unknown-kind")
