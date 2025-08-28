#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT_DIR="${OUT_DIR:-$ROOT/backups}"
STAMP="$(date +%F-%H%M)"
LIST="/tmp/skyops-images.txt"
ARCHIVE="$OUT_DIR/images-$STAMP.tar.gz"

mkdir -p "$OUT_DIR"

# Collecter toutes les images mentionnées dans stacks/*.yml
grep -hR 'image:' "$ROOT/stacks" | awk '{print $2}' | sort -u > "$LIST"

echo "Pulling images..."
xargs -n1 docker pull < "$LIST"

echo "Saving images to $ARCHIVE ..."
docker save $(cat "$LIST") | gzip > "$ARCHIVE"
echo "OK: $ARCHIVE"