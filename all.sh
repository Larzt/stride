#!/usr/bin/env bash
#
# Levanta a la vez:
#   - stride        (landing Astro + túnel appstride.org)
#   - focus.stride  (backend Go + frontend Vite + túnel focus.appstride.org)
# Cada sub-script gestiona su propia limpieza. Ctrl+C para parar todo.
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

STRIDE_DEV="$ROOT/dev.sh"
FOCUS_DEV="$ROOT/../focus.stride/dev.sh"

for script in "$STRIDE_DEV" "$FOCUS_DEV"; do
  [ -x "$script" ] || { echo "❌ No encuentro (o no es ejecutable): $script"; exit 1; }
done

pids=()

cleanup() {
  echo
  echo "🛑 Parando todo..."
  # SIGTERM a cada sub-script: dispara su propio trap cleanup.
  for pid in "${pids[@]}"; do
    kill -TERM "$pid" 2>/dev/null || true
  done
  wait 2>/dev/null || true
}
trap cleanup EXIT INT TERM

# Prefijo coloreado por servicio. Usamos process substitution (> >(...))
# en vez de un pipe para que $! siga siendo el PID del sub-script y el
# trap pueda mandarle SIGTERM directamente.
C_STRIDE=$'\033[36m'  # cian
C_FOCUS=$'\033[35m'   # magenta
C_RESET=$'\033[0m'

echo "🚀 Arrancando stride..."
"$STRIDE_DEV" > >(sed "s/^/${C_STRIDE}[stride]${C_RESET} /") 2>&1 &
pids+=($!)

echo "🚀 Arrancando focus.stride..."
"$FOCUS_DEV" > >(sed "s/^/${C_FOCUS}[focus] ${C_RESET} /") 2>&1 &
pids+=($!)

echo "════════════════════════════════════════════════════════"
echo "Ambos servicios arrancando. Ctrl+C para parar todo."
echo "════════════════════════════════════════════════════════"

wait
