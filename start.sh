#!/bin/sh
set -eu

echo "[planka-start] Booting..."

# Log mínimo de variables clave (sin exponer credenciales)
echo "[planka-start] PORT=${PORT:-<unset>}"
echo "[planka-start] BASE_URL=${BASE_URL:-<unset>}"
echo "[planka-start] DATABASE_URL=<set:${DATABASE_URL:+yes}>"
echo "[planka-start] SECRET_KEY=<set:${SECRET_KEY:+yes}>"
echo "[planka-start] TRUST_PROXY=${TRUST_PROXY:-<unset>}"


exec /usr/local/bin/docker-entrypoint.sh "$@"
