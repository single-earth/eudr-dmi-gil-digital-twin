#!/usr/bin/env bash
set -euo pipefail

# Validate that only AOI report publish outputs are staged/modified.
# Allowed paths:
# - docs/site/aoi_reports/index.html
# - docs/site/aoi_reports/runs/

allowed_index="docs/site/aoi_reports/index.html"
allowed_runs_prefix="docs/site/aoi_reports/runs/"

changes="$(git status --porcelain)"
if [[ -z "$changes" ]]; then
  exit 0
fi

offenders=()

while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  # Strip status (first two columns) and space to get the path
  path="${line:3}"

  if [[ "$path" == "$allowed_index" ]]; then
    continue
  fi

  if [[ "$path" == "$allowed_runs_prefix"* ]]; then
    continue
  fi

  offenders+=("$path")
done <<< "$changes"

if (( ${#offenders[@]} > 0 )); then
  echo "ERROR: publish scope includes disallowed paths:" >&2
  for p in "${offenders[@]}"; do
    echo "  - $p" >&2
  done
  exit 1
fi
