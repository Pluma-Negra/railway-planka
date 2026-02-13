#!/bin/sh
set -eu

echo "[planka-wrapper] Inicializando persistencia en /app/data ..."

# 1) Estructura unificada (Planka v2)
mkdir -p /app/data/protected/user-avatars \
         /app/data/protected/background-images \
         /app/data/private/attachments

# Asegurar que existen los padres legacy
mkdir -p /app/public /app/private

# 2) (Best-effort) Copiar data legacy a /app/data si existe y aún no es symlink
# Nota: en Railway, tras redeploy normalmente ya no existirá legacy, pero esto no estorba.
if [ -d /app/public/user-avatars ] && [ ! -L /app/public/user-avatars ]; then
  echo "[planka-wrapper] Copiando legacy user-avatars -> /app/data/protected/user-avatars"
  cp -an /app/public/user-avatars/. /app/data/protected/user-avatars/ 2>/dev/null || true
fi

if [ -d /app/public/background-images ] && [ ! -L /app/public/background-images ]; then
  echo "[planka-wrapper] Copiando legacy background-images -> /app/data/protected/background-images"
  cp -an /app/public/background-images/. /app/data/protected/background-images/ 2>/dev/null || true
fi

if [ -d /app/private/attachments ] && [ ! -L /app/private/attachments ]; then
  echo "[planka-wrapper] Copiando legacy attachments -> /app/data/private/attachments"
  cp -an /app/private/attachments/. /app/data/private/attachments/ 2>/dev/null || true
fi

# 3) Sustituir carpetas legacy por symlinks hacia el volumen /app/data (idempotente)
rm -rf /app/public/user-avatars /app/public/background-images /app/private/attachments

ln -s /app/data/protected/user-avatars /app/public/user-avatars
ln -s /app/data/protected/background-images /app/public/background-images
ln -s /app/data/private/attachments /app/private/attachments

# 4) Ajuste opcional de permisos si el contenedor corre como root
# (si no es root, no podemos chown; pero normalmente la imagen ya está preparada)
if [ "$(id -u)" = "0" ]; then
  echo "[planka-wrapper] Ajustando permisos en /app/data (root detected)"
  chown -R 1000:1000 /app/data 2>/dev/null || true
fi

echo "[planka-wrapper] Symlinks listos:"
ls -la /app/public/user-avatars /app/public/background-images /app/private/attachments || true

# 5) Arranque del comando original (heredado del CMD base)
# Esto es CLAVE para no tener que conocer el comando exacto.
echo "[planka-wrapper] Ejecutando CMD original: $*"
exec "$@"
