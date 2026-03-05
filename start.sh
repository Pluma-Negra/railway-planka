#!/bin/sh
set -eu

echo "[planka-start] Booting..."

ORIG_ENTRYPOINT="/usr/local/bin/docker-entrypoint.sh"

if [ ! -x "$ORIG_ENTRYPOINT" ]; then
  echo "[planka-start] ERROR: No existe o no es ejecutable: $ORIG_ENTRYPOINT"
  echo "[planka-start] Contenido de /usr/local/bin:"
  ls -la /usr/local/bin || true
  exit 1
fi

# Log mínimo de variables clave (sin exponer credenciales)
echo "[planka-start] PORT=${PORT:-<unset>}"
echo "[planka-start] BASE_URL=${BASE_URL:-<unset>}"
echo "[planka-start] DATABASE_URL=<set:${DATABASE_URL:+yes}>"
echo "[planka-start] SECRET_KEY=<set:${SECRET_KEY:+yes}>"
echo "[planka-start] TRUST_PROXY=${TRUST_PROXY:-<unset>}"

echo "[planka-start] Delegando a entrypoint original..."
exec "$ORIG_ENTRYPOINT" "$@"
