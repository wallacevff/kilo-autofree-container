#!/usr/bin/env bash
set -euo pipefail

KILO_INTERNAL_PORT="${KILO_INTERNAL_PORT:-4100}"
KILO_PUBLIC_PORT="${KILO_PUBLIC_PORT:-4096}"

kilo serve --hostname 127.0.0.1 --port "$KILO_INTERNAL_PORT" --cors "*" &
kilo_pid="$!"

KILO_PROXY_PORT="$KILO_PUBLIC_PORT" KILO_TARGET_PORT="$KILO_INTERNAL_PORT" node /usr/local/bin/kilo-csp-proxy.js &
proxy_pid="$!"

term() {
  kill "$kilo_pid" "$proxy_pid" 2>/dev/null || true
}

trap term INT TERM EXIT

wait -n "$kilo_pid" "$proxy_pid"
