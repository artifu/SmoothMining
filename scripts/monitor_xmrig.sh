#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_DIR="${ROOT_DIR}/logs"
INTERVAL="${1:-15}"
OUTPUT_FILE="${2:-${LOG_DIR}/xmrig-monitor.csv}"

mkdir -p "${LOG_DIR}"

if ! command -v pgrep >/dev/null 2>&1; then
  echo "pgrep is required but not available."
  exit 1
fi

if ! command -v ps >/dev/null 2>&1; then
  echo "ps is required but not available."
  exit 1
fi

TOTAL_MEM_BYTES="$(sysctl -n hw.memsize)"
PAGE_SIZE_BYTES="$(sysctl -n hw.pagesize)"

if [[ ! -f "${OUTPUT_FILE}" ]]; then
  echo "timestamp,pid,process_cpu_percent,process_rss_mb,process_state,process_elapsed,system_mem_used_percent,loadavg_1m,loadavg_5m,loadavg_15m" > "${OUTPUT_FILE}"
fi

get_mem_used_percent() {
  local vm_output pages_free pages_inactive pages_speculative pages_used
  vm_output="$(vm_stat)"

  pages_free="$(awk '/Pages free/ {gsub("\\.", "", $3); print $3}' <<< "${vm_output}")"
  pages_inactive="$(awk '/Pages inactive/ {gsub("\\.", "", $3); print $3}' <<< "${vm_output}")"
  pages_speculative="$(awk '/Pages speculative/ {gsub("\\.", "", $3); print $3}' <<< "${vm_output}")"

  pages_free="${pages_free:-0}"
  pages_inactive="${pages_inactive:-0}"
  pages_speculative="${pages_speculative:-0}"

  pages_used=$(( (TOTAL_MEM_BYTES / PAGE_SIZE_BYTES) - pages_free - pages_inactive - pages_speculative ))

  awk -v used_pages="${pages_used}" -v total_bytes="${TOTAL_MEM_BYTES}" -v page_bytes="${PAGE_SIZE_BYTES}" 'BEGIN {
    used_bytes = used_pages * page_bytes
    printf "%.2f", (used_bytes / total_bytes) * 100
  }'
}

while true; do
  pid="$(pgrep -x xmrig | head -n 1 || true)"

  if [[ -z "${pid}" ]]; then
    echo "xmrig process not found. Exiting monitor."
    exit 0
  fi

  ps_line="$(ps -o pid=,%cpu=,rss=,state=,etime= -p "${pid}")"
  process_cpu_percent="$(awk '{print $2}' <<< "${ps_line}")"
  process_rss_kb="$(awk '{print $3}' <<< "${ps_line}")"
  process_state="$(awk '{print $4}' <<< "${ps_line}")"
  process_elapsed="$(awk '{print $5}' <<< "${ps_line}")"
  process_rss_mb="$(awk -v rss_kb="${process_rss_kb}" 'BEGIN { printf "%.2f", rss_kb / 1024 }')"
  system_mem_used_percent="$(get_mem_used_percent)"

  read -r load_1 load_5 load_15 _ < /proc/loadavg 2>/dev/null || read -r load_1 load_5 load_15 <<< "$(sysctl -n vm.loadavg | sed 's/[{}]//g')"

  printf "%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n" \
    "$(date '+%Y-%m-%d %H:%M:%S')" \
    "${pid}" \
    "${process_cpu_percent}" \
    "${process_rss_mb}" \
    "${process_state}" \
    "${process_elapsed}" \
    "${system_mem_used_percent}" \
    "${load_1}" \
    "${load_5}" \
    "${load_15}" >> "${OUTPUT_FILE}"

  sleep "${INTERVAL}"
done

