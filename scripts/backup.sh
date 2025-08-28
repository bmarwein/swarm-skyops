#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST_BASE="$ROOT/backups"
STAMP="$(date +%F-%H%M)"
DEST="$DEST_BASE/skyops-$STAMP"
mkdir -p "$DEST"

echo "==> Backup to: $DEST"

# helper: retourne un container ID d'un service Swarm
cid() {
  local svc="$1"
  docker ps -q --filter "label=com.docker.swarm.service.name=$svc" | head -n1
}

# ---------- DB dumps ----------
echo "-- DB dumps"

# Odoo (Postgres)
CID_ODPG="$(cid pi-swarm-odoo_pi-swarm-odoo-db || true)"
if [ -n "$CID_ODPG" ]; then
  docker exec "$CID_ODPG" pg_dump -U odoo -d odoo > "$DEST/odoo.sql" || echo "WARN: odoo dump failed"
fi

# Dolibarr (MariaDB)
CID_DOLI="$(cid pi-swarm-dolibarr_pi-swarm-doli-db || true)"
if [ -n "$CID_DOLI" ]; then
  # Essaie avec root (root password file monté dans le conteneur)
  docker exec "$CID_DOLI" sh -lc 'mysqldump -uroot -p"$(cat /run/secrets/pi-swarm-doli-root-password 2>/dev/null || echo root)" --databases dolibarr' \
    > "$DEST/dolibarr.sql" || echo "WARN: dolibarr dump failed"
fi

# Nextcloud (Postgres)
CID_NCPG="$(cid pi-swarm-nextcloud_pi-swarm-next-db || true)"
if [ -n "$CID_NCPG" ]; then
  docker exec "$CID_NCPG" pg_dump -U nextcloud -d nextcloud > "$DEST/nextcloud.sql" || echo "WARN: nextcloud dump failed"
fi

# ---------- Bind volumes archives ----------
echo "-- Volumes"

tar -czf "$DEST/volumes-traefik.tgz"   -C "$ROOT/volumes/traefik" .
tar -czf "$DEST/volumes-web.tgz"       -C "$ROOT/volumes/web"     . || true
tar -czf "$DEST/volumes-odoo.tgz"      -C "$ROOT/volumes/odoo"    .
tar -czf "$DEST/volumes-dolibarr.tgz"  -C "$ROOT/volumes/dolibarr" .
tar -czf "$DEST/volumes-nextcloud.tgz" -C "$ROOT/volumes/nextcloud" . || true
tar -czf "$DEST/volumes-grafana.tgz"   -C "$ROOT/volumes/grafana" . || true
tar -czf "$DEST/volumes-prometheus.tgz" -C "$ROOT/volumes/prometheus" . || true
tar -czf "$DEST/volumes-loki.tgz"      -C "$ROOT/volumes/loki" . || true
tar -czf "$DEST/volumes-promtail.tgz"  -C "$ROOT/volumes/promtail" . || true

# ---------- Stacks & files ----------
echo "-- Stacks, env & files"
tar -czf "$DEST/configs.tgz" -C "$ROOT" stacks env files Makefile

# ---------- Secrets sources (si tu utilises la méthode fichiers) ----------
if [ -d "$ROOT/secrets" ]; then
  tar -czf "$DEST/secrets.tgz" -C "$ROOT" secrets
fi

echo "==> Backup done: $DEST"