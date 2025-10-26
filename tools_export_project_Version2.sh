#!/usr/bin/env bash
# Create a zip archive of the Flutter project (exclude build folders)
set -e
OUT="shiskar_studio_manager_export_$(date -u +%Y%m%dT%H%M%SZ).zip"
echo "Creating $OUT ..."
zip -r "$OUT" . -x "build/*" ".gradle/*" ".idea/*" "ios/*" "android/.gradle/*"
echo "Done. Archive created at $OUT"