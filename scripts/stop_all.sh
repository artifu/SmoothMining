#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUN_DIR="${ROOT_DIR}/tmp"

stop_pid_file() {
  local name="$1"
  local pid_file="$2"

  if [[ ! -f "${pid_file}" ]]; then
    echo "${name}: not running"
    return
  fi

  local pid
  pid="$(cat "${pid_file}")"

  if kill -0 "${pid}" >/dev/null 2>&1; then
    kill "${pid}" >/dev/null 2>&1 || true
    echo "${name}: stopped PID ${pid}"
  else
    echo "${name}: stale PID file removed"
  fi

  rm -f "${pid_file}"
}

stop_pid_file "dashboard" "${RUN_DIR}/dashboard.pid"
stop_pid_file "monitor" "${RUN_DIR}/monitor.pid"
stop_pid_file "xmrig" "${RUN_DIR}/xmrig.pid"

pkill -x xmrig >/dev/null 2>&1 || true
pkill -f monitor_xmrig.sh >/dev/null 2>&1 || true
pkill -f "node dashboard/server.js" >/dev/null 2>&1 || true

echo "Cleanup complete."
