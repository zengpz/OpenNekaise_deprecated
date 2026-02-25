#!/usr/bin/env bash
set -euo pipefail

OPENCLAW_BIN="${OPENCLAW_BIN:-/usr/local/bin/openclaw-bin}"

if [[ ! -x "$OPENCLAW_BIN" ]]; then
    echo "OpenNekaise wrapper error: delegated CLI not found at $OPENCLAW_BIN" >&2
    exit 127
fi

use_container_restart_fallback=0
if [[ "${OPENNEKAISE_FORCE_GATEWAY_RESTART_FALLBACK:-0}" == "1" ]]; then
    use_container_restart_fallback=1
elif ! command -v systemctl >/dev/null 2>&1; then
    use_container_restart_fallback=1
elif ! systemctl --user show-environment >/dev/null 2>&1; then
    use_container_restart_fallback=1
fi

if [[ "${1:-}" == "gateway" && "${2:-}" == "restart" ]] && [[ "$use_container_restart_fallback" -eq 1 ]]; then
    echo "Gateway restart fallback: systemctl --user is unavailable or unusable in this container."
    echo "Restarting gateway process directly..."

    # Stop any existing gateway started by the OpenClaw CLI.
    pkill -f "/usr/local/bin/openclaw-bin gateway" >/dev/null 2>&1 || true

    nohup "$OPENCLAW_BIN" gateway >/tmp/opennekaise-gateway.log 2>&1 &
    echo "Gateway restarted in container mode. Logs: /tmp/opennekaise-gateway.log"
    exit 0
fi

exec "$OPENCLAW_BIN" "$@"
