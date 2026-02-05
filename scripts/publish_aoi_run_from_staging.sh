#!/usr/bin/env bash
set -euo pipefail

# Publish a single AOI run from a staging directory into the Digital Twin repo.
#
# Required env vars:
#   RUN_ID
#   STAGING_DIR (e.g. /Users/server/projects/eudr-dmi-gil/out/site_publish/aoi_reports)
#
# This script:
# - creates/switches to branch publish/aoi_${RUN_ID}
# - rsyncs staging into docs/site/aoi_reports/
# - validates scope
# - commits only docs/site/aoi_reports/**
# - prints (but does not execute) the push command

RUN_ID="${RUN_ID:-}"
STAGING_DIR="${STAGING_DIR:-}"

if [[ -z "$RUN_ID" ]]; then
  echo "ERROR: RUN_ID is required" >&2
  exit 2
fi

if [[ -z "$STAGING_DIR" ]]; then
  echo "ERROR: STAGING_DIR is required" >&2
  exit 2
fi

if [[ ! -d "$STAGING_DIR" ]]; then
  echo "ERROR: STAGING_DIR does not exist: $STAGING_DIR" >&2
  exit 2
fi

# Ensure working tree is clean before switching branches.
if [[ -n "$(git status --porcelain)" ]]; then
  echo "ERROR: working tree is not clean. Commit or stash changes before publishing." >&2
  git status --porcelain >&2
  exit 1
fi

branch="publish/aoi_${RUN_ID}"

git checkout -B "$branch"

# Sync staging into docs/site/aoi_reports/
mkdir -p docs/site/aoi_reports
rsync -a --delete "$STAGING_DIR/" docs/site/aoi_reports/

# Render deterministic AOI artefacts from aoi_report.json and refresh hashes.
if [[ -d "docs/site/aoi_reports/runs" ]]; then
  while IFS= read -r -d '' run_dir; do
    if [[ -f "${run_dir}/aoi_report.json" ]]; then
      python3 scripts/render_aoi_report_from_json.py --run-dir "${run_dir}" --update-json
    fi
  done < <(find "docs/site/aoi_reports/runs" -mindepth 1 -maxdepth 1 -type d -print0)
fi

# Enforce publish scope
scripts/assert_publish_scope.sh

# Stage only AOI reports output

git add docs/site/aoi_reports/

# Verify staged changes are within allowed scope
if git diff --cached --name-only | grep -v '^docs/site/aoi_reports/' >/dev/null; then
  echo "ERROR: staged changes include paths outside docs/site/aoi_reports/" >&2
  git diff --cached --name-only | grep -v '^docs/site/aoi_reports/' >&2
  exit 1
fi

# Commit
if git diff --cached --quiet; then
  echo "ERROR: no changes staged (nothing to publish)" >&2
  exit 1
fi

git commit -m "Publish AOI run ${RUN_ID}"

# Print push command (do not execute)

echo ""
echo "Next step (manual):"
echo "git push -u origin ${branch}"
