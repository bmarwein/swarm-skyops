#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Ordre conseillé (réseau/monitoring d'abord, puis apps)
DEFAULT_STACKS=(
  docker-compose.traefik.yml
  docker-compose.logs.yml
  docker-compose.cadvisor.yml
  docker-compose.node-exporter.yml
  docker-compose.prometheus.yml
  docker-compose.grafana.yml
  docker-compose.web.yml
  docker-compose.odoo.yml
  docker-compose.dolibarr.yml
  docker-compose.nextcloud.yml
  docker-compose.portainer.yml
)

STACKS_DIR="$ROOT/stacks"

deploy_file () {
  local file="$1"
  local name
  name="$(basename "$file" .yml)"
  echo "==> Deploy stack: $name  [$file]"
  docker stack deploy -c "$STACKS_DIR/$file" "$name"
}

if [ "$#" -gt 0 ]; then
  for f in "$@"; do
    [[ -f "$STACKS_DIR/$f" ]] || { echo "Not found: $STACKS_DIR/$f"; exit 1; }
    deploy_file "$f"
  done
else
  for f in "${DEFAULT_STACKS[@]}"; do
    [[ -f "$STACKS_DIR/$f" ]] && deploy_file "$f" || echo "skip (missing): $f"
  done
fi