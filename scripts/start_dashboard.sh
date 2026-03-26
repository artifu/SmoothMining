#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUN_DIR="${ROOT_DIR}/tmp"
LOG_DIR="${ROOT_DIR}/logs"
PID_FILE="${RUN_DIR}/dashboard.pid"

mkdir -p "${RUN_DIR}" "${LOG_DIR}"

if [[ "${1:-}" == "--background" ]]; then
  if [[ -f "${PID_FILE}" ]]; then
    existing_pid="$(cat "${PID_FILE}")"
    if kill -0 "${existing_pid}" >/dev/null 2>&1; then
      echo "dashboard is already running with PID ${existing_pid}."
      exit 0
    fi
    rm -f "${PID_FILE}"
  fi

  cd "${ROOT_DIR}"
  nohup node dashboard/server.js > "${LOG_DIR}/dashboard.log" 2>&1 &
  echo $! > "${PID_FILE}"
  echo "Started dashboard in background with PID $(cat "${PID_FILE}"). Log: ${LOG_DIR}/dashboard.log"
  exit 0
fi

cd "${ROOT_DIR}"
exec node dashboard/server.js

