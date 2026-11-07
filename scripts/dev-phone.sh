#!/usr/bin/env bash
# Serves the customer app so a phone on the same Wi-Fi can open it. Re-run whenever the Mac's Wi-Fi address changes.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
IP="$(ipconfig getifaddr en0 || ipconfig getifaddr en1 || true)"
[ -n "$IP" ] || { echo "No Wi-Fi address found. Connect this Mac to Wi-Fi first."; exit 1; }
ENV_FILE="$ROOT/backend/.env"
API_PORT="$(grep -E '^PORT=' "$ENV_FILE" | cut -d= -f2)"; API_PORT="${API_PORT:-3100}"

python3 - "$ENV_FILE" "$IP" "$API_PORT" <<'PY'
import re, sys
path, ip, api = sys.argv[1:]
s = open(path).read()
def put(key, value):
    global s
    line = f"{key}={value}"
    s, n = re.subn(rf"^{key}=.*$", line, s, flags=re.M)
    if not n: s = s.rstrip("\n") + "\n" + line + "\n"
put("PUBLIC_CUSTOMER_APP_URL", f"http://{ip}:8083")
put("PUBLIC_API_URL", f"http://{ip}:{api}")
base = "http://localhost:8080,http://localhost:8081,http://localhost:8082,http://localhost:8083"
put("CORS_ORIGINS", f"{base},http://{ip}:8083")
open(path, "w").write(s)
PY

echo "Building the customer app for http://$IP:$API_PORT ..."
cd "$ROOT/frontend/apps/cafe_customer_app"
flutter build web --release --dart-define=API_URL="http://$IP:$API_PORT" --no-web-resources-cdn | tail -1

echo
echo "Now restart the backend (Ctrl+C in its terminal, then: npm run dev), so it picks up the new address."
echo "On your phone, on the same Wi-Fi, scan a table QR from the owner app, or open a table link."
echo "Serving at http://$IP:8083  (Ctrl+C to stop)"
HOST=0.0.0.0 exec node "$ROOT/scripts/serve-web.mjs" build/web 8083
