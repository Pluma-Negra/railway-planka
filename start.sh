#!/bin/sh
set -eu

log() { echo "[planka-wrapper] $*"; }

ORIG_ENTRYPOINT="/usr/local/bin/docker-entrypoint.sh"

log "Inicializando persistencia en /app/data ..."

# Estructura unificada (Planka v2)
mkdir -p /app/data/protected/user-avatars \
         /app/data/protected/background-images \
         /app/data/private/attachments

mkdir -p /app/public /app/private

# Detectar mountpoint (si la utilidad existe)
is_mountpoint() {
  command -v mountpoint >/dev/null 2>&1 && mountpoint -q "$1"
}

# Symlinks para assets públicos
rm -rf /app/public/user-avatars || true
ln -s /app/data/protected/user-avatars /app/public/user-avatars

rm -rf /app/public/background-images || true
ln -s /app/data/protected/background-images /app/public/background-images

# Attachments:
# Si Railway todavía monta algo ahí, NO lo borres (evita "Resource busy").
if is_mountpoint /app/private/attachments; then
  log "/app/private/attachments es mountpoint; se deja tal cual."
else
  rm -rf /app/private/attachments || true
  ln -s /app/data/private/attachments /app/private/attachments
fi

# Delegar al entrypoint original del contenedor base
if [ ! -x "$ORIG_ENTRYPOINT" ]; then
  log "ERROR: No encontré $ORIG_ENTRYPOINT (no es ejecutable)."
  exit 1
fi

log "Delegando a entrypoint original: $ORIG_ENTRYPOINT $*"
exec "$ORIG_ENTRYPOINT" "$@"
