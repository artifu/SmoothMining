#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUN_DIR="${ROOT_DIR}/tmp"
LOG_DIR="${ROOT_DIR}/logs"
MONITOR_PID_FILE="${RUN_DIR}/monitor.pid"
MONITOR_INTERVAL="${1:-15}"

mkdir -p "${RUN_DIR}" "${LOG_DIR}"

cd "${ROOT_DIR}"

bash scripts/start_xmrig_background.sh

if [[ -f "${MONITOR_PID_FILE}" ]]; then
  existing_pid="$(cat "${MONITOR_PID_FILE}")"
  if kill -0 "${existing_pid}" >/dev/null 2>&1; then
    echo "monitor is already running with PID ${existing_pid}."
  else
    rm -f "${MONITOR_PID_FILE}"
  fi
fi

if [[ ! -f "${MONITOR_PID_FILE}" ]]; then
  nohup bash scripts/monitor_xmrig.sh "${MONITOR_INTERVAL}" > "${LOG_DIR}/monitor.log" 2>&1 &
  echo $! > "${MONITOR_PID_FILE}"
  echo "Started monitor in background with PID $(cat "${MONITOR_PID_FILE}"). Log: ${LOG_DIR}/monitor.log"
fi

bash scripts/start_dashboard.sh --background

echo "All services started."
echo "Dashboard: http://127.0.0.1:4173"

