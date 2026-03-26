#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT_DIR}/.env"
RUN_DIR="${ROOT_DIR}/tmp"
LOG_DIR="${ROOT_DIR}/logs"
PID_FILE="${RUN_DIR}/xmrig.pid"

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Missing .env file. Copy .env.example to .env and fill in your wallet address first."
  exit 1
fi

set -a
source "${ENV_FILE}"
set +a

mkdir -p "${RUN_DIR}" "${LOG_DIR}"

: "${WALLET_ADDRESS:?WALLET_ADDRESS is required}"
: "${POOL_URL:?POOL_URL is required}"
: "${WORKER_NAME:=smoothmining}"
: "${THREADS:=2}"
: "${CPU_LIMIT:=50}"
: "${CPU_PRIORITY:=1}"
: "${NICE_LEVEL:=10}"
: "${XMRIG_BINARY:=xmrig}"
: "${XMRIG_HTTP_HOST:=127.0.0.1}"
: "${XMRIG_HTTP_PORT:=18080}"
: "${XMRIG_HTTP_TOKEN:=smoothmining-local}"

if [[ "${WALLET_ADDRESS}" == "YOUR_MONERO_SUBADDRESS_HERE" ]]; then
  echo "Replace WALLET_ADDRESS in .env with your real Monero receive subaddress."
  exit 1
fi

if ! command -v "${XMRIG_BINARY}" >/dev/null 2>&1; then
  echo "XMRig binary not found: ${XMRIG_BINARY}"
  echo "Install it first, or set XMRIG_BINARY to the correct path in .env."
  exit 1
fi

if [[ -f "${PID_FILE}" ]]; then
  existing_pid="$(cat "${PID_FILE}")"
  if kill -0 "${existing_pid}" >/dev/null 2>&1; then
    echo "xmrig is already running with PID ${existing_pid}."
    exit 0
  fi
  rm -f "${PID_FILE}"
fi

XMRIG_CMD=(
  "${XMRIG_BINARY}"
  "--url=${POOL_URL}"
  "--user=${WALLET_ADDRESS}"
  "--pass=${WORKER_NAME}"
  "--threads=${THREADS}"
  "--cpu-priority=${CPU_PRIORITY}"
  "--coin=monero"
  "--http-host=${XMRIG_HTTP_HOST}"
  "--http-port=${XMRIG_HTTP_PORT}"
  "--http-access-token=${XMRIG_HTTP_TOKEN}"
)

if command -v cpulimit >/dev/null 2>&1; then
  exec nice -n "${NICE_LEVEL}" cpulimit -l "${CPU_LIMIT}" -- "${XMRIG_CMD[@]}"
fi

echo "cpulimit not found. Running with nice only."
exec nice -n "${NICE_LEVEL}" "${XMRIG_CMD[@]}"
