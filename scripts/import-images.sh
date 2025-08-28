#!/usr/bin/env bash
set -euo pipefail
ARCHIVE="${1:-}"
[ -f "$ARCHIVE" ] || { echo "Usage: $0 backups/images-YYYY-MM-DD-HHMM.tar.gz"; exit 1; }
gunzip -c "$ARCHIVE" | docker load
echo "Images imported from $ARCHIVE"