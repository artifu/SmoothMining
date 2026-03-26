#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUN_DIR="${ROOT_DIR}/tmp"
LOG_DIR="${ROOT_DIR}/logs"
PID_FILE="${RUN_DIR}/xmrig.pid"
LOG_FILE="${LOG_DIR}/xmrig.log"
ENV_FILE="${ROOT_DIR}/.env"

mkdir -p "${RUN_DIR}" "${LOG_DIR}"

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Missing .env file. Copy .env.example to .env first."
  exit 1
fi

set -a
source "${ENV_FILE}"
set +a

: "${XMRIG_BINARY:=xmrig}"

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
candidate_pid=$!

for _ in {1..20}; do
  actual_pid="$(pgrep -n -x "${XMRIG_BINARY}" || true)"

  if [[ -n "${actual_pid}" ]]; then
    echo "${actual_pid}" > "${PID_FILE}"
    echo "Started xmrig in background with PID ${actual_pid}. Log: ${LOG_FILE}"
    exit 0
  fi

  if ! kill -0 "${candidate_pid}" >/dev/null 2>&1; then
    break
  fi
  sleep 0.5
done

echo "xmrig did not stay up long enough to confirm startup. Check ${LOG_FILE}."
exit 1
