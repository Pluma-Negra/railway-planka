#!/bin/sh
set -eu

echo "[planka-wrapper] Inicializando persistencia en /app/data ..."

mkdir -p /app/data/protected/user-avatars \
         /app/data/protected/background-images \
         /app/data/private/attachments

mkdir -p /app/public /app/private

# Helper: detectar mountpoint (si /bin/mountpoint existe)
is_mountpoint() {
  command -v mountpoint >/dev/null 2>&1 && mountpoint -q "$1"
}

# user-avatars -> /app/data
rm -rf /app/public/user-avatars || true
ln -s /app/data/protected/user-avatars /app/public/user-avatars

# background-images -> /app/data
rm -rf /app/public/background-images || true
ln -s /app/data/protected/background-images /app/public/background-images

# attachments: si es mountpoint, NO tocarlo (evita "Resource busy")
if is_mountpoint /app/private/attachments; then
  echo "[planka-wrapper] /app/private/attachments es mountpoint (Resource busy). Se deja tal cual."
else
  rm -rf /app/private/attachments || true
  ln -s /app/data/private/attachments /app/private/attachments
fi

echo "[planka-wrapper] Ejecutando CMD original: $*"
exec "$@"
