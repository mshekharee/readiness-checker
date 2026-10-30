#!/usr/bin/env bash
# Download and run a reviewed GitHub repository release without installing an app.
set -euo pipefail
REPO="${1:-mshekharee/readiness-checker}"
if [[ ! "$REPO" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]]; then
  echo 'Usage: bash install.sh [OWNER/REPO]' >&2
  exit 2
fi
for cmd in curl unzip mktemp; do command -v "$cmd" >/dev/null 2>&1 || { echo "Required tool missing: $cmd" >&2; exit 1; }; done
BRANCH="${PAIRING_REF:-main}"
if [[ ! "$BRANCH" =~ ^[A-Za-z0-9._/-]+$ || "$BRANCH" == *..* ]]; then echo 'Invalid Git ref' >&2; exit 2; fi
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
url="https://github.com/${REPO}/archive/refs/heads/${BRANCH}.zip"
echo "Downloading ${REPO} (${BRANCH}) from GitHub..."
curl -fL --retry 2 --connect-timeout 10 --max-time 90 "$url" -o "$work/src.zip"
unzip -q "$work/src.zip" -d "$work/extracted"
source_dir=$(find "$work/extracted" -mindepth 1 -maxdepth 1 -type d -print -quit)
if [[ -z "$source_dir" || ! -f "$source_dir/readiness.sh" || ! -f "$source_dir/report.html" ]]; then echo 'Archive missing checker files' >&2; exit 1; fi
# Keep latest generated report somewhere persistent so it remains available when this process exits.
dest="${HOME}/.pairing-readiness-checker"
mkdir -p "$dest"
cp "$source_dir/readiness.sh" "$source_dir/report.html" "$dest/"
echo 'Running local system checks...'
bash "$dest/readiness.sh"
echo "Report files: $dest"
