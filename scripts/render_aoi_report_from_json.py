#!/usr/bin/env python3
from __future__ import annotations

import argparse
from pathlib import Path

from aoi_report_renderer import load_report, render_aoi_run, update_evidence_hashes, write_report


def render_run(run_dir: Path, update_json: bool) -> None:
    report_path = run_dir / "aoi_report.json"
    report = load_report(report_path)

    render_aoi_run(run_dir)

    if update_json:
        updated = update_evidence_hashes(run_dir, report)
        write_report(report_path, updated)


def main() -> int:
    parser = argparse.ArgumentParser(description="Render AOI HTML/JSON/CSV from aoi_report.json.")
    parser.add_argument("--run-dir", required=True, help="Path to site/aoi_reports/runs/<run_id>")
    parser.add_argument("--update-json", action="store_true", help="Update evidence_artifacts hashes and sizes")
    args = parser.parse_args()

    run_dir = Path(args.run_dir)
    if not run_dir.is_dir():
        raise SystemExit(f"Run dir not found: {run_dir}")

    render_run(run_dir, update_json=args.update_json)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
