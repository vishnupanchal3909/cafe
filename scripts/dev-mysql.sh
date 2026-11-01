#!/usr/bin/env bash
# Local-only MySQL 8.4 for development. Loopback binding, data under .devdata/ (gitignored).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BIN="${MYSQL_BIN:-/opt/homebrew/opt/mysql@8.4/bin}"
DATA="$ROOT/.devdata/mysql"
RUN="$ROOT/.devdata/run"
PORT="${DEV_MYSQL_PORT:-3307}"
SOCK="$RUN/mysql.sock"

running() { "$BIN/mysqladmin" --no-defaults -uroot --socket="$SOCK" ping >/dev/null 2>&1; }

case "${1:-}" in
  start)
    mkdir -p "$RUN"
    if running; then echo "already running on 127.0.0.1:$PORT"; exit 0; fi
    if [ ! -d "$DATA" ]; then
      echo "initializing data directory"
      "$BIN/mysqld" --no-defaults --initialize-insecure --datadir="$DATA" --log-error="$RUN/init.log"
    fi
    "$BIN/mysqld" --no-defaults --daemonize \
      --datadir="$DATA" --socket="$SOCK" --pid-file="$RUN/mysql.pid" --log-error="$RUN/error.log" \
      --bind-address=127.0.0.1 --port="$PORT" --mysqlx=OFF \
      --default-time-zone=+00:00 --character-set-server=utf8mb4 --collation-server=utf8mb4_0900_ai_ci \
      --log-bin-trust-function-creators=1 --transaction-isolation=READ-COMMITTED \
      --sql-mode=STRICT_TRANS_TABLES,NO_ZERO_DATE,NO_ZERO_IN_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION,ONLY_FULL_GROUP_BY
    for _ in $(seq 1 30); do running && break; sleep 1; done
    running && echo "started on 127.0.0.1:$PORT" || { echo "failed; see $RUN/error.log"; exit 1; }
    ;;
  stop)
    running && "$BIN/mysqladmin" --no-defaults -uroot --socket="$SOCK" shutdown && echo stopped || echo "not running"
    ;;
  status)
    running && echo "running on 127.0.0.1:$PORT" || echo "not running"
    ;;
  shell)
    exec "$BIN/mysql" --no-defaults -uroot --socket="$SOCK" "${@:2}"
    ;;
  *)
    echo "usage: $0 {start|stop|status|shell}"; exit 2
    ;;
esac
