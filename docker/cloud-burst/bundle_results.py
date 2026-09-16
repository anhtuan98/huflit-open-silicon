#!/usr/bin/env python3
"""Curate and hash-compare picorv32 cloud-burst run outputs before retrieval.

Walks the reference run directory and every replica directory, and for each
one that actually completed (has a runs/*/final/ directory), collects only
the small, meaningful artifacts -- final/gds/*.gds, final/metrics.json,
flow.log -- into one small tarball. Intentionally leaves out the bulky
per-stage intermediate directories (each run's runs/*/NN-tool-step/ can be
hundreds of MB to a few GB; there is no reason to pay to transfer that off
a metered VM when only the final signoff artifacts matter for the
determinism check and the teaching writeup).

Also computes sha256 of each completed run's GDS file and writes a
summary.md verdict: PASS if every completed run's hash matches the
reference, FAIL (with a diff of which runs differ) otherwise.
"""

import argparse
import hashlib
import json
import shutil
import tarfile
from pathlib import Path


def find_latest_run(design_dir: Path) -> Path | None:
    runs_dir = design_dir / "runs"
    if not runs_dir.is_dir():
        return None
    candidates = sorted(p for p in runs_dir.iterdir() if p.is_dir())
    for candidate in reversed(candidates):
        if (candidate / "final" / "gds").is_dir():
            return candidate
    return None


def sha256_of(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def collect(name: str, design_dir: Path, stage_dir: Path) -> dict:
    run_dir = find_latest_run(design_dir)
    entry = {"name": name, "completed": False}
    if run_dir is None:
        return entry

    gds_files = list((run_dir / "final" / "gds").glob("*.gds"))
    metrics_path = run_dir / "final" / "metrics.json"
    flow_log = run_dir / "flow.log"
    if not gds_files or not metrics_path.exists():
        return entry

    entry["completed"] = True
    entry["run_id"] = run_dir.name
    entry["gds_sha256"] = sha256_of(gds_files[0])
    entry["gds_name"] = gds_files[0].name

    metrics = json.loads(metrics_path.read_text())
    for key in (
        "design__instance__count",
        "design__instance__count__stdcell",
        "design__die__area",
        "design__core__area",
        "design__instance__utilization",
        "timing__setup__ws",
        "timing__hold__ws",
        "timing__setup_vio__count",
        "timing__hold_vio__count",
        "power__total",
        "magic__drc_error__count",
        "klayout__drc_error__count",
        "design__lvs_error__count",
        "route__antenna_violation__count",
        "flow__errors__count",
    ):
        entry[key] = metrics.get(key)

    dest = stage_dir / name
    dest.mkdir(parents=True, exist_ok=True)
    shutil.copy(gds_files[0], dest / gds_files[0].name)
    shutil.copy(metrics_path, dest / "metrics.json")
    if flow_log.exists():
        shutil.copy(flow_log, dest / "flow.log")
    return entry


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--design-dir", required=True, type=Path)
    ap.add_argument("--replica-root", required=True, type=Path)
    ap.add_argument("--out", required=True, type=Path)
    ap.add_argument("--summary", required=True, type=Path)
    args = ap.parse_args()

    stage_dir = args.out.parent / "bundle_staging"
    if stage_dir.exists():
        shutil.rmtree(stage_dir)
    stage_dir.mkdir(parents=True)

    entries = [collect("reference", args.design_dir, stage_dir)]
    if args.replica_root.is_dir():
        for replica_dir in sorted(args.replica_root.iterdir()):
            if replica_dir.is_dir():
                entries.append(collect(replica_dir.name, replica_dir, stage_dir))

    completed = [e for e in entries if e["completed"]]
    hashes = {e["gds_sha256"] for e in completed}

    lines = ["# picorv32 cloud-burst results summary", ""]
    lines.append(f"Runs attempted: {len(entries)}. Completed: {len(completed)}.")
    lines.append("")
    if not completed:
        lines.append("[FAIL] No run completed -- nothing to compare. See per-run logs.")
    elif len(hashes) == 1:
        lines.append(
            f"[PASS] All {len(completed)} completed run(s) produced an identical GDS "
            f"(sha256 {next(iter(hashes))[:16]}...) -- flow is deterministic on this hardware/config."
        )
    else:
        lines.append(
            f"[FAIL] {len(hashes)} distinct GDS hashes among {len(completed)} completed "
            "run(s) -- non-determinism detected. See per-run hashes below."
        )
    lines.append("")
    lines.append("| Run | Completed | GDS sha256 (first 16) | Instances | Utilization | Setup WS | Hold WS | DRC/LVS/Antenna errors |")
    lines.append("|---|---|---|---|---|---|---|---|")
    for e in entries:
        if not e["completed"]:
            lines.append(f"| {e['name']} | no | - | - | - | - | - | - |")
            continue
        drc = (e.get("magic__drc_error__count", "?"), e.get("klayout__drc_error__count", "?"))
        lvs = e.get("design__lvs_error__count", "?")
        ant = e.get("route__antenna_violation__count", "?")
        lines.append(
            f"| {e['name']} | yes | {e['gds_sha256'][:16]}... "
            f"| {e.get('design__instance__count')} "
            f"| {e.get('design__instance__utilization')} "
            f"| {e.get('timing__setup__ws')} "
            f"| {e.get('timing__hold__ws')} "
            f"| magic={drc[0]} klayout={drc[1]} lvs={lvs} antenna={ant} |"
        )

    args.summary.write_text("\n".join(lines) + "\n")

    with tarfile.open(args.out, "w:gz") as tar:
        tar.add(stage_dir, arcname="picorv32_results")
        tar.add(args.summary, arcname="picorv32_results/summary.md")

    print(f"[OK] wrote {args.out} and {args.summary}")


if __name__ == "__main__":
    main()
