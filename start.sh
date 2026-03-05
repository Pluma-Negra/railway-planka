#!/bin/sh
set -eu

echo "[planka-start] Booting..."

echo "[planka-start] PORT=${PORT:-<unset>}"
echo "[planka-start] BASE_URL=${BASE_URL:-<unset>}"
echo "[planka-start] DATABASE_URL=<set:${DATABASE_URL:+yes}>"
echo "[planka-start] SECRET_KEY=<set:${SECRET_KEY:+yes}>"
echo "[planka-start] TRUST_PROXY=${TRUST_PROXY:-<unset>}"

# Railway asigna PORT dinámicamente; Planka lo necesita como PORT
export PORT="${PORT:-1337}"

# Temporal: explorar estructura de la imagen
echo "[planka-start] === Explorando estructura ==="
ls /
ls /app 2>/dev/null || echo "/app no existe"
find / -name "migrate*" 2>/dev/null | head -20
echo "[planka-start] === Fin exploración ==="

exec /usr/local/bin/docker-entrypoint.sh "$@"
