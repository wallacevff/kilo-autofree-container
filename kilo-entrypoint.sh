#!/usr/bin/env bash
set -euo pipefail

KILO_INTERNAL_PORT="${KILO_INTERNAL_PORT:-4100}"
KILO_PUBLIC_PORT="${KILO_PUBLIC_PORT:-4096}"
export HOME="/workspace"
export BASH_ENV="${HOME}/.bashrc"

if [ -f "${HOME}/.bashrc" ] && [ ! -f "${HOME}/.bash_profile" ]; then
  cat > "${HOME}/.bash_profile" <<'EOF'
if [ -f ~/.bashrc ]; then
  . ~/.bashrc
fi
EOF
fi

export SOURCE_BASHRC_NONINTERACTIVE=1

for rc in "${HOME}/.bashrc" /root/.bashrc /home/node/.bashrc; do
  if [ -f "$rc" ]; then
    set -a
    set +u
    # shellcheck disable=SC1090
    . "$rc"
    set -u
    set +a
  fi
done

kilo serve --hostname 127.0.0.1 --port "$KILO_INTERNAL_PORT" --cors "*" &
kilo_pid="$!"

KILO_PROXY_PORT="$KILO_PUBLIC_PORT" KILO_TARGET_PORT="$KILO_INTERNAL_PORT" node /usr/local/bin/kilo-csp-proxy.js &
proxy_pid="$!"

term() {
  kill "$kilo_pid" "$proxy_pid" 2>/dev/null || true
}

trap term INT TERM EXIT

wait -n "$kilo_pid" "$proxy_pid"
