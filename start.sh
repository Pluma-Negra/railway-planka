#!/bin/sh
set -e

log() { echo "[planka-wrapper] $*"; }

ORIG_ENTRYPOINT="/usr/local/bin/docker-entrypoint.sh"

log "=== BOOT DIAGNOSTICS ==="
log "whoami: $(whoami || true)"
log "id: $(id || true)"
log "pwd: $(pwd || true)"
log "node: $(node -v 2>/dev/null || echo 'NO_NODE')"
log "npm:  $(npm -v 2>/dev/null || echo 'NO_NPM')"
log "Env vars (filtered):"
env | grep -E '^(DATABASE_URL|POSTGRES|PG|PLANKA|PORT)=' || true

# --- Persistencia ---
log "Inicializando persistencia en /app/data ..."
mkdir -p /app/data/protected/user-avatars \
         /app/data/protected/background-images \
         /app/data/private/attachments
mkdir -p /app/public /app/private

rm -rf /app/public/user-avatars /app/public/background-images 2>/dev/null || true
ln -sf /app/data/protected/user-avatars /app/public/user-avatars
ln -sf /app/data/protected/background-images /app/public/background-images

# No tocar /app/private/attachments si es mountpoint
if command -v mountpoint >/dev/null 2>&1 && mountpoint -q /app/private/attachments; then
  log "/app/private/attachments es mountpoint; se deja tal cual."
else
  rm -rf /app/private/attachments 2>/dev/null || true
  ln -sf /app/data/private/attachments /app/private/attachments
fi

log "Mounts relevantes:"
mount | grep -E "/app/data|/app/private/attachments" || true

# --- DB CHECK ---
if [ -z "${DATABASE_URL:-}" ]; then
  log "ERROR: DATABASE_URL no está definido. Planka no puede inicializar DB."
  exit 1
fi

log "Probando conectividad a Postgres (hasta 60s)..."
node - <<'NODE'
const { Client } = require('pg');
const url = process.env.DATABASE_URL;
const sleep = ms => new Promise(r => setTimeout(r, ms));
(async () => {
  for (let i=0; i<60; i++) {
    try {
      const c = new Client({ connectionString: url });
      await c.connect();
      const r = await c.query('SELECT now() as now');
      console.log("[planka-wrapper] Postgres OK:", r.rows[0].now);
      await c.end();
      process.exit(0);
    } catch (e) {
      console.log("[planka-wrapper] Postgres no listo:", e.message);
      await sleep(1000);
    }
  }
  console.error("[planka-wrapper] ERROR: Postgres no respondió en 60s");
  process.exit(1);
})();
NODE

# --- Buscar comandos disponibles ---
log "Buscando scripts npm relevantes..."
( npm run | grep -E 'db:|migrat|seed|knex|prisma' ) || true

# Intentar init/migrate si existen (no todos los builds tienen lo mismo)
if npm run | grep -q "db:init"; then
  log "Ejecutando npm run db:init"
  npm run db:init
elif npm run | grep -q "db:migrate"; then
  log "Ejecutando npm run db:migrate"
  npm run db:migrate
else
  log "ADVERTENCIA: no encontré db:init ni db:migrate en npm scripts."
fi

log "Verificando si ya hay tablas..."
node - <<'NODE'
const { Client } = require('pg');
(async () => {
  const c = new Client({ connectionString: process.env.DATABASE_URL });
  await c.connect();
  const r = await c.query(`
    SELECT count(*)::int as n
    FROM information_schema.tables
    WHERE table_schema NOT IN ('pg_catalog','information_schema')
  `);
  console.log("[planka-wrapper] Tablas user visibles:", r.rows[0].n);
  await c.end();
})();
NODE

# --- Delegar al entrypoint original ---
if [ ! -x "$ORIG_ENTRYPOINT" ]; then
  log "ERROR: No encontré entrypoint original en $ORIG_ENTRYPOINT"
  ls -la /usr/local/bin || true
  exit 1
fi

log "Delegando a entrypoint original: $ORIG_ENTRYPOINT $*"
exec "$ORIG_ENTRYPOINT" "$@"
