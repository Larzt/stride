#!/usr/bin/env bash
#
# Construye la landing (Astro) y la sirve por HTTPS en appstride.org
# a través del túnel cloudflared 'stride'. Ctrl+C para parar todo.
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Bun y cloudflared no están en el PATH del sistema.
export PATH="$HOME/.bun/bin:$HOME/.local/bin:$PATH"

PORT=8788
TUNNEL_CONFIG="$HOME/.cloudflared/stride.yml"
LOG_DIR="$(mktemp -d)"
pids=()

cleanup() {
  echo
  echo "🛑 Parando servicios..."
  for pid in "${pids[@]}"; do
    kill "$pid" 2>/dev/null || true
  done
  wait 2>/dev/null || true
}
trap cleanup EXIT INT TERM

echo "🏗️  Build (Astro)..."
( cd "$ROOT" && bun run build ) >"$LOG_DIR/build.log" 2>&1 || {
  echo "❌ Falló el build. Revisa $LOG_DIR/build.log"
  exit 1
}

echo "🎨 Sirviendo dist/ (astro preview, 127.0.0.1:$PORT)..."
( cd "$ROOT" && bun run preview --host 127.0.0.1 --port "$PORT" ) >"$LOG_DIR/preview.log" 2>&1 &
pids+=($!)

echo "🌐 Túnel HTTPS (cloudflared, appstride.org)..."
cloudflared tunnel --config "$TUNNEL_CONFIG" run stride >"$LOG_DIR/tunnel.log" 2>&1 &
pids+=($!)

url="https://appstride.org"

echo "────────────────────────────────────────────────────────"
echo "🌍 Online en:   $url"
echo "   Local:       http://127.0.0.1:$PORT"
echo "   Logs:        $LOG_DIR"
echo "────────────────────────────────────────────────────────"
echo "Ctrl+C para parar todo."

# Mantener vivo mientras corran los procesos.
wait
