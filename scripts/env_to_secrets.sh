#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="${ENV_FILE:-$(cd "$(dirname "$0")/.." && pwd)/secrets/.secrets.env}"
FORCE="${FORCE:-false}"

declare -A MAP=(
  [ODOO_PG_PASSWORD]=pi-swarm-odoo-pg-password
  [DOLI_ROOT_PASSWORD]=pi-swarm-doli-root-password
  [DOLI_USER_PASSWORD]=pi-swarm-doli-user-password
  [GRAFANA_ADMIN_PASSWORD]=pi-swarm-grafana-admin-password
  [PORTAINER_ADMIN_PASSWORD_HASH]=pi-swarm-portainer-admin-password
  [NEXTCLOUD_DB_PASSWORD]=pi-swarm-nextcloud-db-password
  [NEXTCLOUD_ADMIN_PASSWORD]=pi-swarm-nextcloud-admin-password
)

[ -f "$ENV_FILE" ] || { echo "ERR: $ENV_FILE introuvable"; exit 1; }

# shellcheck source=/dev/null
set -a; source "$ENV_FILE"; set +a

for key in "${!MAP[@]}"; do
  name="${MAP[$key]}"
  val="${!key:-}"

  if [ -z "${val}" ]; then
    echo "SKIP: $key vide → $name"
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

  # passe la valeur via stdin
  printf "%s" "$val" | docker secret create "$name" - >/dev/null && \
    echo "CREATED: $name"
done

echo "Done."