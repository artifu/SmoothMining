#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "${ROOT_DIR}"

bash scripts/stop_all.sh >/dev/null 2>&1 || true
pkill -x xmrig >/dev/null 2>&1 || true
pkill -f monitor_xmrig.sh >/dev/null 2>&1 || true
pkill -f "node dashboard/server.js" >/dev/null 2>&1 || true
rm -f tmp/*.pid >/dev/null 2>&1 || true

echo "Mining stack force-stopped."
echo "Checked: xmrig, monitor_xmrig.sh, dashboard/server.js"

