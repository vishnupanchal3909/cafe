#!/usr/bin/env bash
# Local-only Redis on loopback for development.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; RUN="$ROOT/.devdata/redis"; mkdir -p "$RUN"
case "${1:-}" in
  start) redis-server --bind 127.0.0.1 --port 6379 --daemonize yes --dir "$RUN" --pidfile "$RUN/redis.pid" --logfile "$RUN/redis.log" --save "" ;;
  stop)  redis-cli -p 6379 shutdown nosave ;;
  status) redis-cli -p 6379 ping ;;
  *) echo "usage: $0 {start|stop|status}"; exit 2 ;;
esac
