#!/bin/sh
set -eu

log() { echo "[planka-wrapper] $*"; }

log "Inicializando persistencia en /app/data ..."

# Estructura unificada en el volumen
mkdir -p /app/data/protected/user-avatars \
         /app/data/protected/background-images \
         /app/data/private/attachments

mkdir -p /app/public /app/private

# Detectar si un path es mountpoint (si existe mountpoint)
is_mountpoint() {
  command -v mountpoint >/dev/null 2>&1 && mountpoint -q "$1"
}

# Enlazar rutas legacy -> /app/data (sin tocar mountpoints “busy”)
rm -rf /app/public/user-avatars || true
ln -s /app/data/protected/user-avatars /app/public/user-avatars

rm -rf /app/public/background-images || true
ln -s /app/data/protected/background-images /app/public/background-images

if is_mountpoint /app/private/attachments; then
  log "/app/private/attachments es mountpoint; no se reemplaza (evita Resource busy)."
else
  rm -rf /app/private/attachments || true
  ln -s /app/data/private/attachments /app/private/attachments
fi

# --- DB INIT ---
# Validación mínima
if [ -z "${DATABASE_URL:-}" ]; then
  log "ERROR: DATABASE_URL no está definido en el servicio Planka."
  exit 1
fi

# Esperar a Postgres (sin herramientas extra: usa node si está disponible)
log "Esperando disponibilidad de Postgres ..."
node - <<'NODE'
const { Client } = require('pg');
const url = process.env.DATABASE_URL;
const sleep = (ms) => new Promise(r => setTimeout(r, ms));

(async () => {
  for (let i = 0; i < 60; i++) {
    try {
      const c = new Client({ connectionString: url });
      await c.connect();
      await c.query('SELECT 1');
      await c.end();
      process.exit(0);
    } catch (e) {
      await sleep(1000);
    }
  }
  console.error("Postgres no respondió a tiempo (60s). Revisa DATABASE_URL/conectividad.");
  process.exit(1);
})();
NODE

log "Ejecutando inicialización/migraciones (db:init) ..."
# En Planka v2 Docker normalmente se hace esto antes de iniciar. :contentReference[oaicite:2]{index=2}
# Si el comando no existe en tu build, fallará y lo verás en logs.
npm run db:init

# Arranque del CMD original (heredado de la imagen base)
log "Arrancando Planka (CMD original): $*"
exec "$@"
