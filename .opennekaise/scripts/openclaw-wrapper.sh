#!/usr/bin/env bash
set -euo pipefail

OPENCLAW_BIN="${OPENCLAW_BIN:-/usr/local/bin/openclaw-bin}"
OPENCLAW_HOME_DIR="${OPENCLAW_HOME:-/.opennekaise}"
GATEWAY_PATTERN="/usr/local/bin/openclaw-bin gateway"

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

LOG_DIR="$OPENCLAW_HOME_DIR/logs"
LOG_FILE="$LOG_DIR/opennekaise-gateway.log"
PID_FILE="$OPENCLAW_HOME_DIR/gateway.pid"
mkdir -p "$LOG_DIR"

stop_gateway_processes() {
    local stopped=0

    if [[ -f "$PID_FILE" ]]; then
        local pid
        pid="$(cat "$PID_FILE" 2>/dev/null || true)"
        if [[ "$pid" =~ ^[0-9]+$ ]] && kill -0 "$pid" >/dev/null 2>&1; then
            kill "$pid" >/dev/null 2>&1 || true
            sleep 1
            if kill -0 "$pid" >/dev/null 2>&1; then
                kill -9 "$pid" >/dev/null 2>&1 || true
            fi
            stopped=1
        fi
        rm -f "$PID_FILE"
    fi

    if command -v pkill >/dev/null 2>&1; then
        if pkill -f "$GATEWAY_PATTERN" >/dev/null 2>&1; then
            stopped=1
        fi
    fi

    return "$stopped"
}

if [[ "${1:-}" == "gateway" && "${2:-}" == "stop" ]] && [[ "$use_container_restart_fallback" -eq 1 ]]; then
    echo "Gateway stop fallback: systemctl --user is unavailable or unusable in this container."
    if stop_gateway_processes; then
        echo "Gateway stopped in container mode."
    else
        echo "No known gateway process found to stop."
    fi
    exit 0
fi

if [[ "${1:-}" == "gateway" && "${2:-}" == "restart" ]] && [[ "$use_container_restart_fallback" -eq 1 ]]; then
    echo "Gateway restart fallback: systemctl --user is unavailable or unusable in this container."
    echo "Restarting gateway process directly..."

    stop_gateway_processes >/dev/null 2>&1 || true

    # Start detached from exec TTY/session so it survives docker exec exit.
    if command -v setsid >/dev/null 2>&1; then
        setsid "$OPENCLAW_BIN" gateway >"$LOG_FILE" 2>&1 < /dev/null &
    else
        nohup "$OPENCLAW_BIN" gateway >"$LOG_FILE" 2>&1 < /dev/null &
    fi

    GW_PID="$!"
    echo "$GW_PID" >"$PID_FILE"

    # Detect immediate startup failures and return actionable output.
    sleep 2
    if ! kill -0 "$GW_PID" >/dev/null 2>&1; then
        rm -f "$PID_FILE"
        echo "Gateway failed to stay running after restart. Last log lines:"
        tail -n 50 "$LOG_FILE" 2>/dev/null || echo "(no log output)"
        exit 1
    fi

    echo "Gateway restarted in container mode. PID: $GW_PID Logs: $LOG_FILE"
    exit 0
fi

exec "$OPENCLAW_BIN" "$@"
