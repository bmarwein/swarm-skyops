#!/usr/bin/env bash
set -euo pipefail

# Mapping fichier -> nom du secret Swarm (avec le préfixe "pi-swarm-")
declare -A MAP=(
  [odoo_pg_password]=pi-swarm-odoo-pg-password
  [doli_root_password]=pi-swarm-doli-root-password
  [doli_user_password]=pi-swarm-doli-user-password
  [grafana_admin_password]=pi-swarm-grafana-admin-password
  [portainer_admin_password_hash]=pi-swarm-portainer-admin-password
  [nextcloud_db_password]=pi-swarm-nextcloud-db-password
  [nextcloud_admin_password]=pi-swarm-nextcloud-admin-password
)

SECRETS_DIR="${SECRETS_DIR:-$(cd "$(dirname "$0")/.." && pwd)/secrets}"
FORCE="${FORCE:-false}"  # FORCE=true => rotation (supprime et recrée)

echo "Secrets dir: $SECRETS_DIR"
[ -d "$SECRETS_DIR" ] || { echo "ERR: dossier secrets introuvable"; exit 1; }

# permissions strictes
chmod 700 "$SECRETS_DIR" || true
find "$SECRETS_DIR" -type f -maxdepth 1 -exec chmod 600 {} \; || true

for file in "${!MAP[@]}"; do
  src="$SECRETS_DIR/$file"
  name="${MAP[$file]}"

  if [ ! -f "$src" ]; then
    echo "SKIP: $src absent → $name non créé"
    continue
  fi

  if docker secret ls --format '{{.Name}}' | grep -qx "$name"; then
    if [ "$FORCE" = "true" ]; then
      echo "ROTATE: $name"
      docker secret rm "$name" >/dev/null
    else
      echo "OK: $name existe (skip)."
      continue
    fi
  fi

  # crée le secret depuis le fichier
  if docker secret create "$name" "$src" >/dev/null; then
    echo "CREATED: $name"
  else
    echo "ERR: création $name"; exit 1
  fi
done

echo "Done."