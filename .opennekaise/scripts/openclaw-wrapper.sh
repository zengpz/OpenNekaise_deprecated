#!/usr/bin/env bash
set -euo pipefail

OPENCLAW_BIN="${OPENCLAW_BIN:-/usr/local/bin/openclaw-bin}"
OPENCLAW_HOME_DIR="${OPENCLAW_HOME:-/.opennekaise}"

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

    LOG_DIR="$OPENCLAW_HOME_DIR/logs"
    LOG_FILE="$LOG_DIR/opennekaise-gateway.log"
    PID_FILE="$OPENCLAW_HOME_DIR/gateway.pid"
    mkdir -p "$LOG_DIR"

    # Stop any existing gateway started by the OpenClaw CLI.
    pkill -f "/usr/local/bin/openclaw-bin gateway" >/dev/null 2>&1 || true

    nohup "$OPENCLAW_BIN" gateway >"$LOG_FILE" 2>&1 &
    GW_PID=$!
    echo "$GW_PID" >"$PID_FILE"

    # Detect immediate startup failures and return actionable output.
    sleep 1
    if ! kill -0 "$GW_PID" >/dev/null 2>&1; then
        echo "Gateway failed to stay running after restart. Last log lines:"
        tail -n 50 "$LOG_FILE" 2>/dev/null || echo "(no log output)"
        exit 1
    fi

    echo "Gateway restarted in container mode. PID: $GW_PID Logs: $LOG_FILE"
    exit 0
fi

exec "$OPENCLAW_BIN" "$@"
