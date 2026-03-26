#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUN_DIR="${ROOT_DIR}/tmp"
LOG_DIR="${ROOT_DIR}/logs"
PID_FILE="${RUN_DIR}/xmrig.pid"
LOG_FILE="${LOG_DIR}/xmrig.log"

mkdir -p "${RUN_DIR}" "${LOG_DIR}"

if [[ -f "${PID_FILE}" ]]; then
  existing_pid="$(cat "${PID_FILE}")"
  if kill -0 "${existing_pid}" >/dev/null 2>&1; then
    echo "xmrig is already running with PID ${existing_pid}."
    exit 0
  fi
  rm -f "${PID_FILE}"
fi

cd "${ROOT_DIR}"
nohup bash scripts/run_xmrig.sh > "${LOG_FILE}" 2>&1 &
echo $! > "${PID_FILE}"
echo "Started xmrig in background with PID $(cat "${PID_FILE}"). Log: ${LOG_FILE}"

