#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
SCRIPT_PATH="${SCRIPT_DIR}/$(basename -- "${BASH_SOURCE[0]}")"
CALLER_CWD="$(pwd -P)"
INNER_SENTINEL="__packet_e_contract_harness_nix_inner__"
HARNESS_MODE="full"

if (($# == 1)) && [[ "$1" == "--preflight" ]]; then
  HARNESS_MODE="preflight"
  shift
else
  if (($# == 0)); then
    exec nix develop "${SCRIPT_DIR}" \
      --command bash "${SCRIPT_PATH}" "${INNER_SENTINEL}"
  fi
  if (($# != 1)) || [[ "$1" != "${INNER_SENTINEL}" ]]; then
    printf \
      'HARNESS_ARGUMENT_INVALID: expected no arguments or --preflight\n' >&2
    exit 64
  fi
  shift
  if [[ -z "${IN_NIX_SHELL:-}" ]]; then
    printf 'HARNESS_NIX_SHELL_REQUIRED\n' >&2
    exit 69
  fi
  for bootstrap_tool in node python3; do
    bootstrap_path="$(command -v "${bootstrap_tool}" || true)"
    if [[ "${bootstrap_path}" != /nix/store/* ]]; then
      printf 'HARNESS_BOOTSTRAP_PROVENANCE_MISMATCH: %s: %s\n' \
        "${bootstrap_tool}" "${bootstrap_path:-missing}" >&2
      exit 69
    fi
  done
  unset bootstrap_path bootstrap_tool
fi

SOURCE_PROJECT="${SCRIPT_DIR}"
DARWIN_USER_TEMP_DIR="$(/usr/bin/getconf DARWIN_USER_TEMP_DIR)"
if [[
  "${DARWIN_USER_TEMP_DIR}" != /* ||
  ! -d "${DARWIN_USER_TEMP_DIR}" ||
  -L "${DARWIN_USER_TEMP_DIR}" ||
  ! -O "${DARWIN_USER_TEMP_DIR}" ||
  "$(/usr/bin/stat -f '%Lp' "${DARWIN_USER_TEMP_DIR}")" != "700"
]]; then
  printf 'HARNESS_TEMP_PARENT_INVALID: %s\n' \
    "${DARWIN_USER_TEMP_DIR}" >&2
  exit 70
fi
TEMP_PARENT="$(CDPATH= cd -- "${DARWIN_USER_TEMP_DIR}" && pwd -P)"
EXPECTED_NIXPKGS_REVISION="624af665418d3c65d544145b4d34ad696439570e"
EXPECTED_NIXPKGS_NAR_HASH="sha256-m0pDuRJG7EDo9ri+4Ksu83VsI+PlxNC9lNBfydejce4="
EXPECTED_STAGE_COUNT=21
EXPECTED_COMPILER_TEST_FILES=14
EXPECTED_COMPILER_TESTS=163
EXPECTED_SEMANTIC_DIGEST="a923de9df33371ac97b77afe63566eba0e75a0bdf82778608c33f4fd6c6cd7f4"
REQUIRED_STAGES=(
  dependencies-frozen
  format-typecheck
  compiler-tests
  typespec-valid
  typespec-reordered
  invalid-fixture-diagnostics
  regeneration-first
  regeneration-second
  regeneration-byte-compare
  rust-execution
  go-execution
  typescript-execution
  python-execution
  protobuf-compile
  openapi-parse
  cue-validation
  quint-typecheck
  quint-run
  quint-verify-8
  structural-mutations
  temporal-mutations
)
COMPILER_INPUTS=(
  package.json
  pnpm-lock.yaml
  tsconfig.build.json
  tsconfig.json
  tspconfig.yaml
  vitest.config.ts
  flake.nix
  flake.lock
  test.sh
  scripts
  src
  lib
  fixtures
  test
)
declare -A COMPLETED_STAGES=()
WORK_ROOT=""
LOCK_PATH="${TEMP_PARENT}/packet-e-contract-harness.${UID}.lock"
LOCK_HELD=0
ACTIVE_SUPERVISOR_PID=""
SUPERVISOR_STATE="idle"
PENDING_SIGNAL_NAME=""
PENDING_SIGNAL_CODE=""
SOURCE_MANIFEST_BEFORE=""
SOURCE_MANIFEST_BASELINE_READY=0
SOURCE_MANIFEST_FINAL_VERIFIED=0

is_known_stage() {
  case "$1" in
    dependencies-frozen | \
      format-typecheck | \
      compiler-tests | \
      typespec-valid | \
      typespec-reordered | \
      invalid-fixture-diagnostics | \
      regeneration-first | \
      regeneration-second | \
      regeneration-byte-compare | \
      rust-execution | \
      go-execution | \
      typescript-execution | \
      python-execution | \
      protobuf-compile | \
      openapi-parse | \
      cue-validation | \
      quint-typecheck | \
      quint-run | \
      quint-verify-8 | \
      structural-mutations | \
      temporal-mutations)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

verify_required_stage_definition() {
  local stage
  declare -A seen=()

  if ((${#REQUIRED_STAGES[@]} != EXPECTED_STAGE_COUNT)); then
    printf 'HARNESS_STAGE_SPEC_COUNT: expected %d, received %d\n' \
      "${EXPECTED_STAGE_COUNT}" "${#REQUIRED_STAGES[@]}" >&2
    return 1
  fi
  for stage in "${REQUIRED_STAGES[@]}"; do
    if ! is_known_stage "${stage}"; then
      printf 'HARNESS_STAGE_SPEC_UNKNOWN: %s\n' "${stage}" >&2
      return 1
    fi
    if [[ "${seen[${stage}]:-0}" == "1" ]]; then
      printf 'HARNESS_STAGE_SPEC_DUPLICATE: %s\n' "${stage}" >&2
      return 1
    fi
    seen["${stage}"]=1
  done
}

verify_stage_ledger() {
  local stage
  local missing=0

  for stage in "${REQUIRED_STAGES[@]}"; do
    if [[ "${COMPLETED_STAGES[${stage}]:-0}" != "1" ]]; then
      printf 'HARNESS_LEDGER_MISSING: %s\n' "${stage}" >&2
      missing=1
    fi
  done

  if ((${#COMPLETED_STAGES[@]} != EXPECTED_STAGE_COUNT)); then
    printf 'HARNESS_LEDGER_COUNT: expected %d, received %d\n' \
      "${EXPECTED_STAGE_COUNT}" "${#COMPLETED_STAGES[@]}" >&2
    missing=1
  fi
  if ((missing != 0)); then
    printf 'HARNESS_LEDGER_INCOMPLETE\n' >&2
    return 1
  fi
}

cleanup() {
  local status=$?
  trap - EXIT
  trap '' HUP INT TERM
  if [[
    "${SOURCE_MANIFEST_BASELINE_READY:-0}" == "1" &&
    "${SOURCE_MANIFEST_FINAL_VERIFIED:-0}" == "0" &&
    -n "${SOURCE_MANIFEST_BEFORE_FILE:-}" &&
    -f "${SOURCE_MANIFEST_BEFORE_FILE}" &&
    -n "${SOURCE_MANIFEST_AFTER_FILE:-}"
  ]]; then
    PENDING_SIGNAL_NAME=""
    PENDING_SIGNAL_CODE=""
    ACTIVE_SUPERVISOR_PID=""
    SUPERVISOR_STATE="idle"
    if ! verify_source_manifest && ((status == 0)); then
      status=1
    fi
  fi
  cd "${CALLER_CWD}" 2>/dev/null || true
  if [[ -n "${WORK_ROOT}" ]]; then
    case "${WORK_ROOT}" in
      "${TEMP_PARENT}"/packet-e-contract-harness.*)
        if ! rm -rf -- "${WORK_ROOT}"; then
          printf 'HARNESS_CLEANUP_FAILED: %s\n' "${WORK_ROOT}" >&2
          status=1
        fi
        ;;
      *)
        printf 'HARNESS_CLEANUP_REFUSED: %s\n' "${WORK_ROOT}" >&2
        status=1
        ;;
    esac
  fi
  if ((LOCK_HELD == 1)); then
    exec 9>&-
    LOCK_HELD=0
  fi
  exit "${status}"
}

lock_fd_matches_path() {
  python3 -c '
import os
import stat
import sys

descriptor = os.fstat(9)
path = os.stat(sys.argv[1], follow_symlinks=False)
valid = (
    descriptor.st_dev == path.st_dev
    and descriptor.st_ino == path.st_ino
    and stat.S_ISREG(path.st_mode)
    and path.st_uid == os.getuid()
    and stat.S_IMODE(path.st_mode) == 0o600
)
raise SystemExit(0 if valid else 1)
' "${LOCK_PATH}"
}

acquire_lock() {
  local lock_mode=""

  if [[ ! "${UID}" =~ ^[0-9]+$ ]] ||
    [[ "${LOCK_PATH}" != "${TEMP_PARENT}/packet-e-contract-harness.${UID}.lock" ]]; then
    printf 'HARNESS_LOCK_PATH_INVALID: %s\n' "${LOCK_PATH}" >&2
    return 1
  fi

  if [[ ! -e "${LOCK_PATH}" ]]; then
    if ! (umask 077; set -o noclobber; : >"${LOCK_PATH}") 2>/dev/null &&
      [[ ! -e "${LOCK_PATH}" ]]; then
      printf 'HARNESS_LOCK_CREATE_FAILED: %s\n' "${LOCK_PATH}" >&2
      return 73
    fi
  fi
  if [[
    ! -f "${LOCK_PATH}" ||
    -L "${LOCK_PATH}" ||
    ! -O "${LOCK_PATH}"
  ]]; then
    printf 'HARNESS_LOCK_SHAPE_INVALID: %s\n' "${LOCK_PATH}" >&2
    return 73
  fi
  lock_mode="$(/usr/bin/stat -f '%Lp' "${LOCK_PATH}")"
  if [[ "${lock_mode}" != "600" ]]; then
    printf 'HARNESS_LOCK_MODE_INVALID: %s has mode %s\n' \
      "${LOCK_PATH}" "${lock_mode}" >&2
    return 73
  fi

  exec 9>>"${LOCK_PATH}"
  if ! lock_fd_matches_path; then
    exec 9>&-
    printf 'HARNESS_LOCK_OPEN_RACE: %s\n' "${LOCK_PATH}" >&2
    return 73
  fi
  if ! /usr/bin/lockf -s -t 0 9; then
    exec 9>&-
    printf 'HARNESS_LOCK_HELD: %s\n' "${LOCK_PATH}" >&2
    return 73
  fi
  if ! lock_fd_matches_path; then
    exec 9>&-
    printf 'HARNESS_LOCK_PATH_REPLACED: %s\n' "${LOCK_PATH}" >&2
    return 73
  fi
  LOCK_HELD=1
}

on_signal() {
  local signal_name=$1
  local exit_code=$2

  if [[ -n "${PENDING_SIGNAL_NAME}" ]]; then
    return
  fi
  PENDING_SIGNAL_NAME="${signal_name}"
  PENDING_SIGNAL_CODE="${exit_code}"
  trap '' HUP INT TERM

  case "${SUPERVISOR_STATE}" in
    idle)
      printf 'HARNESS_INTERRUPTED: %s\n' "${signal_name}" >&2
      exit "${exit_code}"
      ;;
    launching)
      return
      ;;
    running)
      if [[ "${ACTIVE_SUPERVISOR_PID}" =~ ^[1-9][0-9]*$ ]]; then
        kill -"${signal_name}" "${ACTIVE_SUPERVISOR_PID}" 2>/dev/null || true
      fi
      return
      ;;
    *)
      printf 'HARNESS_SUPERVISOR_STATE_INVALID: %s\n' \
        "${SUPERVISOR_STATE}" >&2
      exit 70
      ;;
  esac
}

run_bounded() {
  local timeout_seconds=$1
  local status=0
  local supervisor_pid=""
  local supervisor_ready_file=""
  shift
  supervisor_ready_file="$(
    mktemp "${WORK_ROOT}/tmp/supervisor-ready.XXXXXX"
  )"
  rm -f -- "${supervisor_ready_file}"
  SUPERVISOR_STATE="launching"
  exec 8<&0
  python3 -c '
import os
import signal
import subprocess
import sys
import time

timeout_seconds = float(sys.argv[1])
ready_file = sys.argv[2]
command = sys.argv[3:]
handled_signals = {signal.SIGINT, signal.SIGTERM, signal.SIGHUP}
child = None
child_pgid = None

def signal_group(signum):
    if child_pgid is None:
        return False
    try:
        os.killpg(child_pgid, signum)
        return True
    except ProcessLookupError:
        return False

def group_exists():
    if child_pgid is None:
        return False
    try:
        os.killpg(child_pgid, 0)
        return True
    except ProcessLookupError:
        return False
    except PermissionError:
        return True

def wait_for_group(timeout):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        if child is not None:
            child.poll()
        if not group_exists():
            return True
        time.sleep(0.05)
    return not group_exists()

def terminate_child():
    if child_pgid is None:
        return True
    cleanup_ok = True
    signal_group(signal.SIGTERM)
    if not wait_for_group(5):
        signal_group(signal.SIGKILL)
        if not wait_for_group(5):
            print(
                f"HARNESS_PROCESS_GROUP_STUCK: {child_pgid}",
                file=sys.stderr,
            )
            cleanup_ok = False
    if child is not None and child.poll() is None:
        try:
            child.wait(timeout=1)
        except subprocess.TimeoutExpired:
            signal_group(signal.SIGKILL)
            try:
                child.wait(timeout=5)
            except subprocess.TimeoutExpired:
                print(
                    f"HARNESS_PROCESS_LEADER_STUCK: {child.pid}",
                    file=sys.stderr,
                )
                cleanup_ok = False
    return cleanup_ok

def handle_signal(signum, _frame):
    signal.signal(signal.SIGINT, signal.SIG_IGN)
    signal.signal(signal.SIGTERM, signal.SIG_IGN)
    signal.signal(signal.SIGHUP, signal.SIG_IGN)
    if not terminate_child():
        raise SystemExit(70)
    raise SystemExit(128 + signum)

signal.signal(signal.SIGINT, handle_signal)
signal.signal(signal.SIGTERM, handle_signal)
signal.signal(signal.SIGHUP, handle_signal)

previous_mask = signal.pthread_sigmask(signal.SIG_BLOCK, handled_signals)

def restore_child_mask():
    signal.pthread_sigmask(signal.SIG_SETMASK, previous_mask)

try:
    child = subprocess.Popen(
        command,
        start_new_session=True,
        preexec_fn=restore_child_mask,
    )
    child_pgid = child.pid
except FileNotFoundError:
    print(f"HARNESS_TOOL_MISSING: {command[0]}", file=sys.stderr)
    raise SystemExit(127)
else:
    try:
        descriptor = os.open(
            ready_file,
            os.O_CREAT | os.O_EXCL | os.O_WRONLY,
            0o600,
        )
        os.close(descriptor)
    except BaseException:
        terminate_child()
        raise
finally:
    signal.pthread_sigmask(signal.SIG_SETMASK, previous_mask)

try:
    return_code = child.wait(timeout=timeout_seconds)
except subprocess.TimeoutExpired:
    print(
        f"HARNESS_TIMEOUT: {timeout_seconds:g}s: {command[0]}",
        file=sys.stderr,
    )
    if not terminate_child():
        raise SystemExit(70)
    raise SystemExit(124)
except KeyboardInterrupt:
    if not terminate_child():
        raise SystemExit(70)
    raise SystemExit(130)
finally:
    if not terminate_child():
        raise SystemExit(70)

if return_code < 0:
    raise SystemExit(128 - return_code)
raise SystemExit(return_code)
' "${timeout_seconds}" "${supervisor_ready_file}" "$@" <&8 8<&- 9>&- &
  supervisor_pid=$!
  exec 8<&-
  ACTIVE_SUPERVISOR_PID="${supervisor_pid}"
  while [[ ! -f "${supervisor_ready_file}" ]] &&
    kill -0 "${supervisor_pid}" 2>/dev/null; do
    /bin/sleep 0.01
  done
  SUPERVISOR_STATE="running"
  if [[ -n "${PENDING_SIGNAL_NAME}" ]]; then
    kill -"${PENDING_SIGNAL_NAME}" "${supervisor_pid}" 2>/dev/null || true
  fi
  while true; do
    if wait "${supervisor_pid}"; then
      status=0
    else
      status=$?
    fi
    if ! kill -0 "${supervisor_pid}" 2>/dev/null; then
      break
    fi
  done
  rm -f -- "${supervisor_ready_file}"
  ACTIVE_SUPERVISOR_PID=""
  SUPERVISOR_STATE="idle"
  if [[ -n "${PENDING_SIGNAL_NAME}" ]]; then
    printf 'HARNESS_INTERRUPTED: %s\n' "${PENDING_SIGNAL_NAME}" >&2
    return "${PENDING_SIGNAL_CODE}"
  fi
  return "${status}"
}

verify_supervisor_descendant_cleanup() {
  local descendant_pid=""
  local pid_file="${WORK_ROOT}/tmp/orphan-descendant.pid"

  run_bounded 15 bash -c '
(
  trap "" TERM
  printf "%s\n" "${BASHPID}" >"$1"
  while true; do
    /bin/sleep 1
  done
) &
while [[ ! -s "$1" ]]; do
  :
done
exit 0
' packet-e-orphan-regression "${pid_file}"
  IFS= read -r descendant_pid <"${pid_file}" || true
  if [[ ! "${descendant_pid}" =~ ^[1-9][0-9]*$ ]]; then
    printf 'HARNESS_ORPHAN_REGRESSION_PID_INVALID: %s\n' \
      "${descendant_pid}" >&2
    return 1
  fi
  if kill -0 "${descendant_pid}" 2>/dev/null; then
    kill -KILL "${descendant_pid}" 2>/dev/null || true
    printf 'HARNESS_ORPHAN_DESCENDANT_ESCAPED: %s\n' \
      "${descendant_pid}" >&2
    return 1
  fi
  printf 'supervisor orphan cleanup: exited leader and TERM-ignoring descendant reaped\n'
}

write_source_manifest() {
  local destination=$1
  local compiler_root=${2:-"${SOURCE_PROJECT}"}

  run_bounded 30 node --input-type=module - \
    "${compiler_root}" \
    "${COMPILER_INPUTS[@]}" >"${destination}" <<'NODE'
import { createHash } from "node:crypto";
import { lstat, readFile, readdir } from "node:fs/promises";
import { join, relative } from "node:path";

const compilerRoot = process.argv[2];
const compilerInputs = process.argv.slice(3);
const records = [];

function checkedPath(scope, root, path) {
  const relativePath = relative(root, path).replaceAll("\\", "/");
  const recordPath = `${scope}/${relativePath}`;
  if (
    relativePath.length === 0 ||
    relativePath === ".." ||
    relativePath.startsWith("../") ||
    recordPath.normalize("NFC") !== recordPath ||
    /[\u0000-\u001f\u007f]/u.test(recordPath)
  ) {
    throw new Error(`HARNESS_SOURCE_PATH_INVALID: ${recordPath}`);
  }
  return recordPath;
}

async function visit(scope, root, path) {
  const metadata = await lstat(path);
  if (metadata.isSymbolicLink()) {
    throw new Error(`HARNESS_SOURCE_SYMLINK_FORBIDDEN: ${path}`);
  }
  if (metadata.isDirectory()) {
    records.push({
      path: checkedPath(scope, root, path),
      type: "directory",
      mode: metadata.mode & 0o7777,
      bytes: Buffer.alloc(0),
    });
    const entries = await readdir(path);
    entries.sort((left, right) =>
      Buffer.compare(Buffer.from(left), Buffer.from(right))
    );
    for (const entry of entries) {
      await visit(scope, root, join(path, entry));
    }
    return;
  }
  if (!metadata.isFile()) {
    throw new Error(`HARNESS_SOURCE_ENTRY_INVALID: ${path}`);
  }
  records.push({
    path: checkedPath(scope, root, path),
    type: "file",
    mode: metadata.mode & 0o7777,
    bytes: await readFile(path),
  });
}

for (const entry of compilerInputs) {
  await visit("compiler", compilerRoot, join(compilerRoot, entry));
}
records.sort((left, right) =>
  Buffer.compare(Buffer.from(left.path), Buffer.from(right.path))
);

const aggregate = createHash("sha256");
for (const record of records) {
  const pathBytes = Buffer.from(record.path);
  const fileHash =
    record.type === "file"
      ? createHash("sha256").update(record.bytes).digest("hex")
      : "-";
  const header = Buffer.alloc(21);
  header.writeUInt8(record.type === "file" ? 1 : 2, 0);
  header.writeUInt32BE(record.mode, 1);
  header.writeBigUInt64BE(BigInt(pathBytes.length), 5);
  header.writeBigUInt64BE(BigInt(record.bytes.length), 13);
  aggregate.update(header);
  aggregate.update(pathBytes);
  aggregate.update(record.bytes);
  console.log(
    `${record.type}\t${record.mode.toString(8).padStart(4, "0")}\t${fileHash}\t${record.path}`,
  );
}
console.log(`MANIFEST_SHA256\t${aggregate.digest("hex")}`);
NODE
}

verify_manifest_pair() {
  local expected=$1
  local actual=$2
  local diagnostic=$3

  if ! run_bounded 30 cmp -s "${expected}" "${actual}"; then
    printf '%s\n' "${diagnostic}" >&2
    run_bounded 30 diff -u \
      "${expected}" "${actual}" >&2 ||
      true
    return 1
  fi
}

verify_copied_snapshot() {
  write_source_manifest \
    "${SOURCE_MANIFEST_SNAPSHOT_FILE}" "${WORK_PROJECT}"
  verify_manifest_pair \
    "${SOURCE_MANIFEST_BEFORE_FILE}" \
    "${SOURCE_MANIFEST_SNAPSHOT_FILE}" \
    "HARNESS_SNAPSHOT_MISMATCH: copied compiler input differs from source"
}

verify_source_manifest() {
  write_source_manifest "${SOURCE_MANIFEST_AFTER_FILE}"
  verify_manifest_pair \
    "${SOURCE_MANIFEST_BEFORE_FILE}" \
    "${SOURCE_MANIFEST_AFTER_FILE}" \
    "HARNESS_SOURCE_CHANGED: compiler input changed during the run"
}

verify_pinned_toolchain() {
  local phase=$1

  run_bounded 60 node --input-type=module - \
    "${SOURCE_PROJECT}/flake.lock" \
    "${EXPECTED_NIXPKGS_REVISION}" \
    "${EXPECTED_NIXPKGS_NAR_HASH}" \
    "${phase}" <<'NODE'
import { constants } from "node:fs";
import { access, readFile, realpath } from "node:fs/promises";
import { delimiter, join } from "node:path";
import { spawnSync } from "node:child_process";

const lockPath = process.argv[2];
const expectedRevision = process.argv[3];
const expectedNarHash = process.argv[4];
const phase = process.argv[5];
const expected = [
  ["node", ["node", "--version"], "v22.23.1"],
  ["pnpm", ["pnpm", "--version"], "10.34.5"],
  ["cue", ["cue", "version"], "cue version (devel)"],
  ["quint", ["quint", "--version"], "0.32.0"],
  ["protoc", ["protoc", "--version"], "libprotoc 35.1"],
  [
    "rustc",
    ["rustc", "--version"],
    "rustc 1.97.0 (2d8144b78 2026-07-07) (built from a source tarball)",
  ],
  [
    "cargo",
    ["cargo", "--version"],
    "cargo 1.97.0 (c980f4866 2026-06-30)",
  ],
  ["go", ["go", "version"], "go version go1.26.5 darwin/arm64"],
  ["python3", ["python3", "--version"], "Python 3.13.14"],
];
const packageTools = [
  ["TypeSpec", ["pnpm", "exec", "tsp", "--version"], "1.14.0"],
  ["TypeScript", ["pnpm", "exec", "tsc", "--version"], "Version 6.0.3"],
  [
    "Vitest",
    ["pnpm", "exec", "vitest", "--version"],
    "vitest/4.1.9 darwin-arm64 node-v22.23.1",
  ],
];

async function resolveExecutable(name) {
  for (const directory of (process.env.PATH ?? "").split(delimiter)) {
    if (directory.length === 0) continue;
    const candidate = join(directory, name);
    try {
      await access(candidate, constants.X_OK);
      return await realpath(candidate);
    } catch {
      // Continue searching PATH.
    }
  }
  throw new Error(`HARNESS_TOOL_MISSING: ${name}`);
}

function outputOf(command) {
  const result = spawnSync(command[0], command.slice(1), {
    encoding: "utf8",
    timeout: 30_000,
  });
  if (result.error || result.status !== 0 || result.signal !== null) {
    throw new Error(
      `HARNESS_TOOL_VERSION_FAILED: ${command.join(" ")}: ${String(result.error ?? result.stderr)}`,
    );
  }
  return `${result.stdout}${result.stderr}`.trim();
}

if (!process.env.IN_NIX_SHELL) {
  throw new Error("HARNESS_NIX_SHELL_REQUIRED");
}
const lock = JSON.parse(await readFile(lockPath, "utf8"));
const actualRevision = lock?.nodes?.nixpkgs?.locked?.rev;
const actualNarHash = lock?.nodes?.nixpkgs?.locked?.narHash;
if (
  actualRevision !== expectedRevision ||
  actualNarHash !== expectedNarHash
) {
  throw new Error(
    `HARNESS_NIXPKGS_LOCK_MISMATCH: expected ${expectedRevision}/${expectedNarHash}, received ${String(actualRevision)}/${String(actualNarHash)}`,
  );
}

for (const [name, command, wanted] of expected) {
  const executable = await resolveExecutable(name);
  if (!executable.startsWith("/nix/store/")) {
    throw new Error(
      `HARNESS_TOOL_PROVENANCE_MISMATCH: ${name}: ${executable}`,
    );
  }
  const fullOutput = outputOf(command);
  const actual = fullOutput.split(/\r?\n/u)[0];
  if (
    actual !== wanted ||
    (name === "cue" &&
      !fullOutput.split(/\r?\n/u).includes("CUE language version v0.17.1"))
  ) {
    throw new Error(
      `HARNESS_TOOL_VERSION_MISMATCH: ${name}: expected ${wanted}, received ${fullOutput}`,
    );
  }
}
if (phase === "complete") {
  for (const [name, command, wanted] of packageTools) {
    const actual = outputOf(command).split(/\r?\n/u)[0];
    if (actual !== wanted) {
      throw new Error(
        `HARNESS_TOOL_VERSION_MISMATCH: ${name}: expected ${wanted}, received ${actual}`,
      );
    }
  }
} else if (phase !== "bootstrap") {
  throw new Error(`HARNESS_TOOLCHAIN_PHASE_INVALID: ${phase}`);
}
console.log(
  `pinned toolchain (${phase}): nixpkgs ${expectedRevision}; Node 22.23.1; pnpm 10.34.5; TypeSpec ${phase === "complete" ? "1.14.0; TypeScript 6.0.3; Vitest 4.1.9; " : ""}CUE 0.17.1; Quint 0.32.0; protoc 35.1; rustc/cargo 1.97.0; Go 1.26.5; Python 3.13.14`,
);
NODE
}

record_stage() {
  local stage=$1
  local owner=$2
  local description=$3

  if ! is_known_stage "${stage}"; then
    printf 'HARNESS_LEDGER_UNKNOWN: %s\n' "${stage}" >&2
    return 1
  fi
  if [[ "${COMPLETED_STAGES[${stage}]:-0}" == "1" ]]; then
    printf 'HARNESS_LEDGER_DUPLICATE: %s\n' "${stage}" >&2
    return 1
  fi
  COMPLETED_STAGES["${stage}"]=1
  printf '%s|%s|%s\n' "${stage}" "${owner}" "${description}" \
    >>"${STAGE_LEDGER}"
}

run_stage() {
  local stage=$1
  local description=$2
  local implementation=$3

  printf '\n==> %s: %s\n' "${stage}" "${description}"
  "${implementation}"
  record_stage "${stage}" "${stage}" "${description}"
}

attest_stage() {
  local stage=$1
  local owner=$2
  local description=$3
  local attestation=$4

  printf '\n==> %s: %s [owned by %s]\n' \
    "${stage}" "${description}" "${owner}"
  if [[ "${COMPLETED_STAGES[${owner}]:-0}" != "1" ]]; then
    printf 'HARNESS_LEDGER_OWNER_INCOMPLETE: %s -> %s\n' \
      "${stage}" "${owner}" >&2
    return 1
  fi
  "${attestation}"
  record_stage "${stage}" "${owner}" "${description}"
}

copy_project_source() {
  local entry

  mkdir -p "${WORK_PROJECT}"
  for entry in "${COMPILER_INPUTS[@]}"; do
    if [[ ! -e "${SOURCE_PROJECT}/${entry}" ]]; then
      printf 'HARNESS_SOURCE_MISSING: %s\n' "${entry}" >&2
      return 1
    fi
    run_bounded 60 cp -R -- \
      "${SOURCE_PROJECT}/${entry}" "${WORK_PROJECT}/${entry}"
  done
}

install_frozen_dependencies() {
  run_bounded 600 pnpm install \
    --frozen-lockfile \
    --store-dir "${PNPM_STORE_DIR}"
  verify_pinned_toolchain complete
}

check_format_and_types() {
  run_bounded 180 pnpm format:check
  run_bounded 180 pnpm typecheck
}

run_compiler_tests() {
  run_bounded 2400 bash -o pipefail -c \
    'pnpm test --run --reporter=verbose --reporter=json --outputFile.json="$2" 2>&1 | tee "$1"' \
    packet-e-compiler-tests "${COMPILER_TEST_LOG}" "${COMPILER_TEST_REPORT}"
  run_bounded 30 node --input-type=module - \
    "${COMPILER_TEST_REPORT}" \
    "${EXPECTED_COMPILER_TEST_FILES}" \
    "${EXPECTED_COMPILER_TESTS}" <<'NODE'
import { readFile } from "node:fs/promises";

const report = JSON.parse(await readFile(process.argv[2], "utf8"));
const expectedFiles = Number(process.argv[3]);
const expectedTests = Number(process.argv[4]);
const actualFiles = new Set(
  report.testResults.map((result) => result.name),
).size;
const assertions = report.testResults.flatMap(
  (result) => result.assertionResults,
);
const unexpectedStatuses = [
  ...new Set(
    assertions
      .map((assertion) => assertion.status)
      .filter((status) => status !== "passed"),
  ),
];

if (
  report.success !== true ||
  report.numTotalTestSuites !== expectedFiles ||
  report.numPassedTestSuites !== expectedFiles ||
  report.numFailedTestSuites !== 0 ||
  report.numPendingTestSuites !== 0 ||
  actualFiles !== expectedFiles ||
  report.numTotalTests !== expectedTests ||
  report.numPassedTests !== expectedTests ||
  report.numFailedTests !== 0 ||
  report.numPendingTests !== 0 ||
  report.numTodoTests !== 0 ||
  assertions.length !== expectedTests ||
  unexpectedStatuses.length !== 0
) {
  throw new Error(
    `HARNESS_COMPILER_REPORT_MISMATCH: ${JSON.stringify({
      success: report.success,
      totalFiles: report.numTotalTestSuites,
      passedFiles: report.numPassedTestSuites,
      failedFiles: report.numFailedTestSuites,
      pendingFiles: report.numPendingTestSuites,
      resultFiles: actualFiles,
      totalTests: report.numTotalTests,
      passedTests: report.numPassedTests,
      failedTests: report.numFailedTests,
      pendingTests: report.numPendingTests,
      todoTests: report.numTodoTests,
      assertions: assertions.length,
      unexpectedStatuses,
    })}`,
  );
}
console.log(
  `compiler report: ${expectedFiles}/${expectedFiles} files, ${expectedTests}/${expectedTests} tests`,
);
NODE
}

compile_valid_typespec() {
  run_bounded 120 pnpm exec tsp compile \
    fixtures/valid/packet-e-slice/main.tsp \
    --no-emit \
    --warn-as-error \
    --pretty=false
}

compile_reordered_typespec() {
  run_bounded 120 pnpm exec tsp compile \
    fixtures/valid/packet-e-slice-reordered/main.tsp \
    --no-emit \
    --warn-as-error \
    --pretty=false
}

check_invalid_fixture_diagnostics() {
  run_bounded 180 node --input-type=module - "${WORK_PROJECT}" <<'NODE'
import { readFile } from "node:fs/promises";
import { join } from "node:path";

import { createTester } from "@typespec/compiler/testing";

import { lowerContract } from "./dist/src/lower.js";
import { validateContract } from "./dist/src/validate.js";

const packageRoot = process.argv[2];
const fixtures = [
  ["missing-matrix-cell", "contract/incomplete-matrix"],
  ["extra-error-variant", "contract/inadmissible-error"],
  ["contradictory-outcome", "contract/contradictory-outcome"],
  ["missing-recovery-coordinate", "contract/missing-recovery-coordinate"],
  ["observed-and-accepted", "contract/conflicting-result-branch"],
  ["missing-error-result-branch", "contract/error-result-branch-mismatch"],
  ["wildcard-matrix-cell", "contract/wildcard-cell-forbidden"],
];
const { compileAndDiagnose } = createTester(packageRoot, {
  libraries: ["contract"],
});

for (const [fixture, expected] of fixtures) {
  const source = await readFile(
    join(packageRoot, "fixtures", "invalid", fixture, "main.tsp"),
    "utf8",
  );
  const [result, compilerDiagnostics] = await compileAndDiagnose(source);
  const diagnosticCodes = new Set(
    compilerDiagnostics.map((diagnostic) => diagnostic.code),
  );
  if (diagnosticCodes.size === 0) {
    for (const diagnostic of validateContract(lowerContract(result.program))) {
      diagnosticCodes.add(diagnostic.code);
    }
  }
  const actual = [...diagnosticCodes].sort();
  if (actual.length !== 1 || actual[0] !== expected) {
    throw new Error(
      `HARNESS_INVALID_DIAGNOSTIC_MISMATCH: ${fixture}: expected ${expected}, received ${JSON.stringify(actual)}`,
    );
  }
  console.log(`invalid fixture ${fixture}: ${expected}`);
}
NODE
}

regenerate_into() {
  local output_root=$1

  run_bounded 180 node --input-type=module - \
    "${WORK_PROJECT}" "${output_root}" <<'NODE'
import { mkdir, readFile, readdir, writeFile } from "node:fs/promises";
import { join, relative } from "node:path";

import { createTester } from "@typespec/compiler/testing";

import { generateAll } from "./dist/src/generate/index.js";
import { lowerContract } from "./dist/src/lower.js";

const packageRoot = process.argv[2];
const outputRoot = process.argv[3];
const expectedPaths = [
  "cue/contract.cue",
  "go/contract.go",
  "go/contract_test.go",
  "go/go.mod",
  "openapi/contract.json",
  "protobuf/contract.proto",
  "python/contract.py",
  "python/run.py",
  "python/test_contract.py",
  "quint/contract.qnt",
  "rust/lib.rs",
  "rust/validate.rs",
  "typescript/contract.ts",
  "typescript/run.mjs",
  "typescript/static-construction.test.ts",
  "typescript/tsconfig.json",
];
const source = await readFile(
  join(packageRoot, "fixtures", "valid", "packet-e-slice", "main.tsp"),
  "utf8",
);
const { compile } = createTester(packageRoot, { libraries: ["contract"] });
const generated = generateAll(lowerContract((await compile(source)).program));
const generatedPaths = generated.map((file) => file.relativePath);
if (JSON.stringify(generatedPaths) !== JSON.stringify(expectedPaths)) {
  throw new Error(
    `HARNESS_REGENERATION_TARGET_MISMATCH: expected ${JSON.stringify(expectedPaths)}, received ${JSON.stringify(generatedPaths)}`,
  );
}

for (const file of generated) {
  const destination = join(outputRoot, ...file.relativePath.split("/"));
  await mkdir(join(destination, ".."), { recursive: true });
  await writeFile(destination, file.bytes);
}

const writtenPaths = [];
async function visit(directory) {
  const entries = await readdir(directory, { withFileTypes: true });
  entries.sort((left, right) =>
    left.name < right.name ? -1 : left.name > right.name ? 1 : 0
  );
  for (const entry of entries) {
    const path = join(directory, entry.name);
    if (entry.isDirectory()) {
      await visit(path);
    } else if (entry.isFile()) {
      writtenPaths.push(relative(outputRoot, path).replaceAll("\\", "/"));
    } else {
      throw new Error(`HARNESS_REGENERATION_ENTRY_INVALID: ${path}`);
    }
  }
}
await visit(outputRoot);
if (JSON.stringify(writtenPaths) !== JSON.stringify(expectedPaths)) {
  throw new Error(
    `HARNESS_REGENERATION_FILE_MISMATCH: expected ${JSON.stringify(expectedPaths)}, received ${JSON.stringify(writtenPaths)}`,
  );
}
console.log(`regenerated exactly ${writtenPaths.length} artifacts into ${outputRoot}`);
NODE
}

regenerate_first() {
  regenerate_into "${REGENERATION_FIRST}"
}

regenerate_second() {
  regenerate_into "${REGENERATION_SECOND}"
}

compare_regenerations() {
  run_bounded 120 diff -ru \
    "${REGENERATION_FIRST}" "${REGENERATION_SECOND}"
}

assert_compiler_test() {
  local pattern=$1
  if ! run_bounded 30 grep -Fq -- "${pattern}" "${COMPILER_TEST_LOG}"; then
    printf 'HARNESS_COMPILER_TEST_EVIDENCE_MISSING: %s\n' \
      "${pattern}" >&2
    return 1
  fi
}

attest_rust_execution() {
  assert_compiler_test \
    "compiles and executes Rust and Go validators over the exact shared bytes"
}

attest_go_execution() {
  assert_compiler_test \
    "compiles and executes Rust and Go validators over the exact shared bytes"
}

attest_typescript_execution() {
  assert_compiler_test \
    "typechecks construction exclusions and executes strict decoders over exact fixtures"
}

attest_python_execution() {
  assert_compiler_test \
    "runs pinned unittest decoders over the exact shared eight fixture bytes"
}

attest_protobuf_compile() {
  assert_compiler_test \
    "emits compilable closed Protobuf projections with exact tags and current exclusions"
}

attest_openapi_parse() {
  assert_compiler_test \
    "emits downstream-only closed OpenAPI 3.1 schemas with exact discriminators"
}

attest_cue_validation() {
  assert_compiler_test \
    "uses the selected #ContractBundle as a real CUE structural and relational oracle"
  assert_compiler_test \
    "executes the committed CUE boundary and typechecks the composed Quint model"
}

attest_quint_typecheck() {
  assert_compiler_test \
    "typechecks the generated vocabulary with handwritten machine and invariants"
}

attest_quint_run() {
  assert_compiler_test \
    "runs deterministic reference traces and checks every invariant"
}

attest_quint_verify() {
  assert_compiler_test \
    "finds no invariant violation through eight reference transitions"
}

attest_structural_mutations() {
  assert_compiler_test \
    "assigns every formal mutant to exactly one independently owned check"
  assert_compiler_test \
    "uses the selected #ContractBundle as a real CUE structural and relational oracle"
  run_bounded 30 node --input-type=module - \
    "${WORK_PROJECT}/test/handwritten/adversarial-outcomes.json" <<'NODE'
import { readFile } from "node:fs/promises";

const ledger = JSON.parse(await readFile(process.argv[2], "utf8"));
if (
  !Array.isArray(ledger.cue) ||
  ledger.cue.length !== 20 ||
  new Set(ledger.cue.map((entry) => entry.mutation)).size !== 20 ||
  ledger.cue.some(
    (entry) =>
      typeof entry.constraint !== "string" ||
      entry.constraint.length === 0 ||
      typeof entry.property !== "string" ||
      entry.property.length === 0
  )
) {
  throw new Error("HARNESS_STRUCTURAL_MUTATION_LEDGER_INVALID");
}
console.log("structural mutation ownership: 20/20");
NODE
}

attest_temporal_mutations() {
  assert_compiler_test \
    "assigns every formal mutant to exactly one independently owned check"
  run_bounded 30 node --input-type=module - \
    "${WORK_PROJECT}/test/handwritten/adversarial-outcomes.json" \
    "${COMPILER_TEST_REPORT}" <<'NODE'
import { readFile } from "node:fs/promises";

const ledger = JSON.parse(await readFile(process.argv[2], "utf8"));
const compilerReport = JSON.parse(await readFile(process.argv[3], "utf8"));
const passedTestNames = compilerReport.testResults.flatMap((result) =>
  result.assertionResults
    .filter((assertion) => assertion.status === "passed")
    .map((assertion) => assertion.fullName)
);
const ownershipTest =
  "assigns every formal mutant to exactly one independently owned check";
const executedMutantTests = passedTestNames.filter((name) =>
  name.startsWith("typechecks and kills ")
);
if (
  !Array.isArray(ledger.quint) ||
  ledger.quint.length !== 11 ||
  new Set(ledger.quint.map((entry) => entry.action)).size !== 11 ||
  new Set(ledger.quint.map((entry) => entry.invariant)).size !== 11 ||
  !passedTestNames.includes(ownershipTest) ||
  executedMutantTests.length !== ledger.quint.length
) {
  throw new Error("HARNESS_TEMPORAL_MUTATION_LEDGER_INVALID");
}
console.log("temporal mutation ownership: 11/11");
NODE
}

semantic_digest() {
  run_bounded 30 node --input-type=module - \
    "${WORK_PROJECT}" "${EXPECTED_SEMANTIC_DIGEST}" <<'NODE'
import { readFile } from "node:fs/promises";
import { join } from "node:path";

import { createTester } from "@typespec/compiler/testing";

import {
  canonicalizeSemanticJson,
  semanticDigest,
} from "./dist/src/canonical.js";
import { lowerContract } from "./dist/src/lower.js";

const packageRoot = process.argv[2];
const expectedDigest = process.argv[3];
const source = await readFile(
  join(packageRoot, "fixtures", "valid", "packet-e-slice", "main.tsp"),
  "utf8",
);
const committedBundle = JSON.parse(
  await readFile(
    join(packageRoot, "test", "golden", "contract-bundle.json"),
    "utf8",
  ),
);
const { compile } = createTester(packageRoot, { libraries: ["contract"] });
const model = lowerContract((await compile(source)).program);
const digest = semanticDigest(model);
const committedModelBytes = Buffer.from(
  canonicalizeSemanticJson(committedBundle.model),
);
const compiledModelBytes = Buffer.from(canonicalizeSemanticJson(model));

if (
  digest !== expectedDigest ||
  committedBundle.semanticDigest !== expectedDigest ||
  !committedModelBytes.equals(compiledModelBytes)
) {
  throw new Error(
    `HARNESS_SEMANTIC_DIGEST_MISMATCH: expected ${expectedDigest}, compiled ${digest}, committed ${String(committedBundle.semanticDigest)}`,
  );
}
console.log(digest);
NODE
}

verify_required_stage_definition

run_preflight() {
  local preflight_root
  local manifest_file
  local manifest=""

  preflight_root="$(
    mktemp -d "${TEMP_PARENT}/packet-e-contract-preflight.XXXXXX"
  )"
  case "${preflight_root}" in
    "${TEMP_PARENT}"/packet-e-contract-preflight.*) ;;
    *)
      printf 'HARNESS_PREFLIGHT_ROOT_INVALID: %s\n' \
        "${preflight_root}" >&2
      return 1
      ;;
  esac
  manifest_file="${preflight_root}/source-manifest.txt"

  if ! write_source_manifest "${manifest_file}"; then
    rm -rf -- "${preflight_root}"
    return 1
  fi
  while IFS=$'\t' read -r manifest_label manifest_value; do
    if [[ "${manifest_label}" == "MANIFEST_SHA256" ]]; then
      manifest="${manifest_value}"
    fi
  done <"${manifest_file}"
  if [[ ! "${manifest}" =~ ^[0-9a-f]{64}$ ]]; then
    tail -n 3 "${manifest_file}" >&2 || true
    rm -rf -- "${preflight_root}"
    printf 'HARNESS_PREFLIGHT_MANIFEST_INVALID: %s\n' "${manifest}" >&2
    return 1
  fi
  rm -rf -- "${preflight_root}"

  printf 'HARNESS_PREFLIGHT_SOURCE_MANIFEST: %s\n' "${manifest}"
  printf 'HARNESS_PREFLIGHT_OK: %d/%d product-owned stages\n' \
    "${#REQUIRED_STAGES[@]}" "${EXPECTED_STAGE_COUNT}"
}

if [[ "${HARNESS_MODE}" == "preflight" ]]; then
  run_preflight
  exit 0
fi

trap cleanup EXIT
trap 'on_signal HUP 129' HUP
trap 'on_signal INT 130' INT
trap 'on_signal TERM 143' TERM
acquire_lock
WORK_ROOT="$(mktemp -d "${TEMP_PARENT}/packet-e-contract-harness.XXXXXX")"
case "${WORK_ROOT}" in
  "${TEMP_PARENT}"/packet-e-contract-harness.*) ;;
  *)
    printf 'HARNESS_WORK_ROOT_INVALID: %s\n' "${WORK_ROOT}" >&2
    exit 1
    ;;
esac

WORK_PROJECT="${WORK_ROOT}/project"
CACHE_ROOT="${WORK_ROOT}/cache"
OUTPUT_ROOT="${WORK_ROOT}/output"
STAGE_LEDGER="${OUTPUT_ROOT}/stage-ownership.log"
COMPILER_TEST_LOG="${OUTPUT_ROOT}/compiler-tests.log"
COMPILER_TEST_REPORT="${OUTPUT_ROOT}/compiler-tests.json"
SOURCE_MANIFEST_BEFORE_FILE="${OUTPUT_ROOT}/source-manifest-before.txt"
SOURCE_MANIFEST_SNAPSHOT_FILE="${OUTPUT_ROOT}/source-manifest-snapshot.txt"
SOURCE_MANIFEST_AFTER_FILE="${OUTPUT_ROOT}/source-manifest-after.txt"
REGENERATION_FIRST="${OUTPUT_ROOT}/regeneration-first"
REGENERATION_SECOND="${OUTPUT_ROOT}/regeneration-second"

mkdir -p \
  "${CACHE_ROOT}/cargo-home" \
  "${CACHE_ROOT}/cargo-target" \
  "${CACHE_ROOT}/go-build" \
  "${CACHE_ROOT}/go-mod" \
  "${CACHE_ROOT}/go-path" \
  "${CACHE_ROOT}/npm" \
  "${CACHE_ROOT}/pnpm-home" \
  "${CACHE_ROOT}/pnpm-store" \
  "${CACHE_ROOT}/python" \
  "${CACHE_ROOT}/xdg" \
  "${OUTPUT_ROOT}" \
  "${WORK_ROOT}/tmp"
: >"${STAGE_LEDGER}"

export TMPDIR="${WORK_ROOT}/tmp"
export XDG_CACHE_HOME="${CACHE_ROOT}/xdg"
export PNPM_HOME="${CACHE_ROOT}/pnpm-home"
export PNPM_STORE_DIR="${CACHE_ROOT}/pnpm-store"
export npm_config_cache="${CACHE_ROOT}/npm"
export npm_config_update_notifier=false
export CARGO_HOME="${CACHE_ROOT}/cargo-home"
export CARGO_TARGET_DIR="${CACHE_ROOT}/cargo-target"
export GOCACHE="${CACHE_ROOT}/go-build"
export GOMODCACHE="${CACHE_ROOT}/go-mod"
export GOPATH="${CACHE_ROOT}/go-path"
export PYTHONPYCACHEPREFIX="${CACHE_ROOT}/python"
export CI=1
export NO_UPDATE_NOTIFIER=1

verify_pinned_toolchain bootstrap
verify_supervisor_descendant_cleanup
write_source_manifest "${SOURCE_MANIFEST_BEFORE_FILE}"
while IFS=$'\t' read -r manifest_label manifest_value; do
  if [[ "${manifest_label}" == "MANIFEST_SHA256" ]]; then
    SOURCE_MANIFEST_BEFORE="${manifest_value}"
  fi
done <"${SOURCE_MANIFEST_BEFORE_FILE}"
if [[ ! "${SOURCE_MANIFEST_BEFORE}" =~ ^[0-9a-f]{64}$ ]]; then
  printf 'HARNESS_SOURCE_MANIFEST_INVALID: %q\n' \
    "${SOURCE_MANIFEST_BEFORE}" >&2
  tail -n 3 "${SOURCE_MANIFEST_BEFORE_FILE}" >&2 || true
  exit 1
fi
SOURCE_MANIFEST_BASELINE_READY=1
unset manifest_label manifest_value
copy_project_source
verify_copied_snapshot
cd "${WORK_PROJECT}"

run_stage \
  dependencies-frozen \
  "install exactly pnpm-lock.yaml and verify every pinned tool and provenance" \
  install_frozen_dependencies
run_stage \
  format-typecheck \
  "check TypeSpec formatting and TypeScript types" \
  check_format_and_types
run_stage \
  compiler-tests \
  "run the complete compiler and executable-oracle Vitest suite once" \
  run_compiler_tests
run_stage \
  typespec-valid \
  "compile the canonical valid TypeSpec source with warnings denied" \
  compile_valid_typespec
run_stage \
  typespec-reordered \
  "compile the declaration-reordered TypeSpec source with warnings denied" \
  compile_reordered_typespec
run_stage \
  invalid-fixture-diagnostics \
  "check all seven invalid fixtures against their stable diagnostic codes" \
  check_invalid_fixture_diagnostics
run_stage \
  regeneration-first \
  "generate the complete artifact set in the first clean output root" \
  regenerate_first
run_stage \
  regeneration-second \
  "generate the complete artifact set independently in a second output root" \
  regenerate_second
run_stage \
  regeneration-byte-compare \
  "compare independent artifact trees path-for-path and byte-for-byte" \
  compare_regenerations

attest_stage \
  rust-execution \
  compiler-tests \
  "compile and execute the Rust validator over exact shared fixtures" \
  attest_rust_execution
attest_stage \
  go-execution \
  compiler-tests \
  "compile and execute the Go validator over exact shared fixtures" \
  attest_go_execution
attest_stage \
  typescript-execution \
  compiler-tests \
  "typecheck and execute the TypeScript validator" \
  attest_typescript_execution
attest_stage \
  python-execution \
  compiler-tests \
  "execute pinned Python unittests and decoders" \
  attest_python_execution
attest_stage \
  protobuf-compile \
  compiler-tests \
  "compile the generated Protobuf projection with protoc" \
  attest_protobuf_compile
attest_stage \
  openapi-parse \
  compiler-tests \
  "parse and validate the generated OpenAPI 3.1 projection" \
  attest_openapi_parse
attest_stage \
  cue-validation \
  compiler-tests \
  "execute generated and committed CUE structural/relational validation" \
  attest_cue_validation
attest_stage \
  quint-typecheck \
  compiler-tests \
  "typecheck generated Quint vocabulary with the handwritten model" \
  attest_quint_typecheck
attest_stage \
  quint-run \
  compiler-tests \
  "run deterministic 10,000-sample Quint reference traces" \
  attest_quint_run
attest_stage \
  quint-verify-8 \
  compiler-tests \
  "verify every Quint invariant through eight reference transitions" \
  attest_quint_verify
attest_stage \
  structural-mutations \
  compiler-tests \
  "kill all 20 independently owned structural mutations" \
  attest_structural_mutations
attest_stage \
  temporal-mutations \
  compiler-tests \
  "kill all 11 independently owned temporal mutations" \
  attest_temporal_mutations

verify_stage_ledger
digest="$(semantic_digest)"
verify_source_manifest
SOURCE_MANIFEST_FINAL_VERIFIED=1
printf '\nHARNESS_STAGE_OWNERSHIP\n'
while IFS= read -r ledger_entry; do
  printf '  %s\n' "${ledger_entry}"
done <"${STAGE_LEDGER}"
printf 'HARNESS_SEMANTIC_DIGEST: %s\n' "${digest}"
printf 'HARNESS_SOURCE_MANIFEST: %s\n' "${SOURCE_MANIFEST_BEFORE}"
printf 'HARNESS_GREEN: %d/%d required stages completed\n' \
  "${#COMPLETED_STAGES[@]}" "${EXPECTED_STAGE_COUNT}"
