#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="${1:-}"
[ -n "$SRC" ] || { echo "Usage: $0 backups/skyops-YYYY-MM-DD-HHMM"; exit 1; }
[ -d "$SRC" ] || { echo "Not a directory: $SRC"; exit 1; }

echo "==> RESTORE from $SRC"
echo "Important:"
echo "  - stoppez ou retirez les stacks concernées avant de restaurer (docker stack rm ...)"
echo "  - restaurez d'abord les volumes/bind, puis redéployez les stacks, puis les DB"
read -r -p "Continue (y/N)? " ans
[[ "${ans:-N}" =~ ^[Yy]$ ]] || exit 1

# ---------- restore des binds (volumes/) ----------
restore_tar() {
  local tgz="$1"
  local dest="$2"
  if [ -f "$tgz" ]; then
    echo "-- restore $(basename "$tgz") to $dest"
    mkdir -p "$dest"
    tar -xzf "$tgz" -C "$dest"
  fi
}

restore_tar "$SRC/volumes-traefik.tgz"   "$ROOT/volumes/traefik"
restore_tar "$SRC/volumes-web.tgz"       "$ROOT/volumes/web"
restore_tar "$SRC/volumes-odoo.tgz"      "$ROOT/volumes/odoo"
restore_tar "$SRC/volumes-dolibarr.tgz"  "$ROOT/volumes/dolibarr"
restore_tar "$SRC/volumes-nextcloud.tgz" "$ROOT/volumes/nextcloud"
restore_tar "$SRC/volumes-grafana.tgz"   "$ROOT/volumes/grafana"
restore_tar "$SRC/volumes-prometheus.tgz" "$ROOT/volumes/prometheus"
restore_tar "$SRC/volumes-loki.tgz"      "$ROOT/volumes/loki"
restore_tar "$SRC/volumes-promtail.tgz"  "$ROOT/volumes/promtail"

echo "==> Volumes restored. Re-deploy stacks now (deploy.sh) before DB import."