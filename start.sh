#!/bin/sh
set -eu

echo "[planka-wrapper] Starting basic wrapper..."

ORIG_ENTRYPOINT="/usr/local/bin/docker-entrypoint.sh"

if [ ! -x "$ORIG_ENTRYPOINT" ]; then
  echo "[planka-wrapper] ERROR: No se encontró $ORIG_ENTRYPOINT"
  ls -la /usr/local/bin || true
  exit 1
fi

echo "[planka-wrapper] Delegando a entrypoint original..."
exec "$ORIG_ENTRYPOINT" "$@"
