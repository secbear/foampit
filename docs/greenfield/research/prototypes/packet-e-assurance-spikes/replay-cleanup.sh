#!/usr/bin/env bash

packet_e_replay_initialize() {
  local wrapper_directory="$1"
  local template_name="$2"
  local repository_candidate temporary_candidate canonical_candidate

  if ! repository_candidate="$(git -C "$wrapper_directory" rev-parse --show-toplevel)"; then
    echo "RED replay initialization could not resolve the repository" >&2
    return 1
  fi
  if [[ -z "$repository_candidate" ]]; then
    echo "RED replay initialization resolved an empty repository" >&2
    return 1
  fi
  if ! repository="$(realpath "$repository_candidate")"; then
    echo "RED replay initialization could not canonicalize the repository" >&2
    return 1
  fi
  if [[ -z "$repository" || "$repository" != /* || ! -d "$repository" ]]; then
    echo "RED replay initialization resolved an invalid repository" >&2
    return 1
  fi

  if ! temporary_candidate="$(
    mktemp -d "${TMPDIR:-/tmp}/$template_name"
  )"; then
    echo "RED replay initialization could not create its temporary root" >&2
    return 1
  fi
  if [[ -z "$temporary_candidate" || ! -d "$temporary_candidate" ||
    -L "$temporary_candidate" ]]; then
    echo "RED replay initialization created an invalid temporary root" >&2
    return 1
  fi
  if ! canonical_candidate="$(realpath "$temporary_candidate")"; then
    echo "RED replay initialization could not canonicalize its temporary root" >&2
    return 1
  fi
  if [[ -z "$canonical_candidate" || "$canonical_candidate" != /* ||
    "$canonical_candidate" == "/" || ! -d "$canonical_candidate" ||
    -L "$canonical_candidate" ]]; then
    echo "RED replay initialization resolved an invalid temporary root" >&2
    return 1
  fi

  temporary="$canonical_candidate"
  checkout="$temporary/base"
  child_tmp="$temporary/child-tmp"
  if [[ "$checkout" != "$temporary/base" || "$child_tmp" != "$temporary/child-tmp" ]]; then
    echo "RED replay initialization derived an invalid child path" >&2
    return 1
  fi
  if ! mkdir -p -- "$child_tmp"; then
    echo "RED replay initialization could not create its child TMPDIR" >&2
    return 1
  fi
  if [[ ! -d "$child_tmp" || -L "$child_tmp" ]]; then
    echo "RED replay initialization created an invalid child TMPDIR" >&2
    return 1
  fi
  packet_e_replay_cleanup_done=0
}

packet_e_replay_capture_inventory() {
  local captured
  if ! captured="$(git -C "$repository" worktree list --porcelain)"; then
    echo "RED replay cleanup could not query worktree inventory" >&2
    return 1
  fi
  packet_e_replay_inventory="$captured"
}

packet_e_replay_inventory_contains_target() {
  local line
  while IFS= read -r line; do
    if [[ "$line" == "worktree $checkout" ]]; then
      return 0
    fi
  done <<<"$packet_e_replay_inventory"
  return 1
}

packet_e_replay_validate_deletion_root() {
  local canonical
  if [[ -z "${temporary:-}" || "$temporary" != /* || "$temporary" == "/" ||
    -L "$temporary" || ! -d "$temporary" ]]; then
    echo "RED replay cleanup refused an invalid temporary root" >&2
    return 1
  fi
  if ! canonical="$(realpath "$temporary")"; then
    echo "RED replay cleanup could not canonicalize its deletion root" >&2
    return 1
  fi
  if [[ "$canonical" != "$temporary" || "$checkout" != "$temporary/base" ||
    "$child_tmp" != "$temporary/child-tmp" ]]; then
    echo "RED replay cleanup refused a non-exact deletion root" >&2
    return 1
  fi
}

packet_e_replay_cleanup() {
  local child_status="$1"
  local cleanup_failure=0
  local target_absent=0
  local final_status="$child_status"

  if ! packet_e_replay_capture_inventory; then
    cleanup_failure=1
  elif packet_e_replay_inventory_contains_target; then
    if git -C "$repository" worktree remove --force "$checkout" >/dev/null 2>&1; then
      :
    elif git -C "$repository" worktree remove --force "$checkout" >/dev/null 2>&1; then
      :
    else
      echo "RED replay cleanup could not remove exact target after retry: $checkout" >&2
      cleanup_failure=1
    fi
    if (( cleanup_failure == 0 )); then
      if ! packet_e_replay_capture_inventory; then
        cleanup_failure=1
      elif packet_e_replay_inventory_contains_target; then
        echo "RED replay cleanup left exact worktree registration: $checkout" >&2
        cleanup_failure=1
      else
        target_absent=1
      fi
    fi
  elif [[ -e "$checkout" || -L "$checkout" ]]; then
    echo "RED replay cleanup found an unregistered checkout and preserved it: $checkout" >&2
    cleanup_failure=1
  else
    target_absent=1
  fi

  if (( cleanup_failure == 0 && target_absent == 1 )) &&
    [[ -e "$checkout" || -L "$checkout" ]]; then
    echo "RED replay cleanup preserved an exact checkout left after removal: $checkout" >&2
    cleanup_failure=1
  fi

  if (( cleanup_failure == 0 && target_absent == 1 )); then
    if packet_e_replay_validate_deletion_root; then
      if ! find "$temporary" -depth -delete; then
        echo "RED replay cleanup could not delete its exact temporary root" >&2
        cleanup_failure=1
      elif [[ -e "$temporary" || -L "$temporary" ]]; then
        echo "RED replay cleanup left its exact temporary root: $temporary" >&2
        cleanup_failure=1
      fi
    else
      cleanup_failure=1
    fi
  fi

  if (( cleanup_failure != 0 )); then
    echo "RED replay cleanup failed; recovery root preserved: $temporary" >&2
    if (( final_status == 0 )); then
      final_status=1
    fi
  fi
  packet_e_replay_cleanup_done=1
  return "$final_status"
}

packet_e_replay_on_exit() {
  local child_status="$?"
  local final_status
  if (( ${packet_e_replay_cleanup_done:-0} == 1 )); then
    return
  fi
  trap - EXIT
  set +e
  packet_e_replay_cleanup "$child_status"
  final_status="$?"
  exit "$final_status"
}
