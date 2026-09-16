#!/usr/bin/env bash
# Bundle whatever results currently exist (primary + any finished/partial
# replicas) into one small, fast-to-download archive, and write a
# determinism report comparing GDS hashes across all completed runs.
# Safe to run mid-flight (e.g. called by the burst script's hard timer
# while some replicas are still running) -- a run that isn't done yet is
# noted and skipped, not treated as an error.
#
# Deliberately excludes the bulky per-stage intermediate directories
# (tmp/, *.def, *.spef, *.odb, waveforms) -- only final/ artifacts +
# top-level logs, so the whole bundle should be well under 1GB even with
# several replicas, keeping the download step (the last thing before
# destroying the VM) fast.
set -uo pipefail

REPO_DIR="${REPO_DIR:-$HOME/huflit-open-silicon}"
WORK_ROOT="${WORK_ROOT:-$HOME/picorv32_burst}"
BUNDLE_DIR="$WORK_ROOT/bundle_$(date -u +%Y%m%d_%H%M%S)"
mkdir -p "$BUNDLE_DIR"

latest_run_dir() {
  # $1 = design directory (repo copy or a replica copy)
  local runs_dir="$1/runs"
  [ -d "$runs_dir" ] || return 1
  ls -dt "$runs_dir"/RUN_* 2>/dev/null | head -n1
}

collect_primary() {
  local design_dir="$REPO_DIR/designs/picorv32"
  local run_dir
  run_dir=$(latest_run_dir "$design_dir") || { echo "[WARN] primary: no run directory yet"; return; }
  local dest="$BUNDLE_DIR/primary"
  mkdir -p "$dest"
  cp -r "$run_dir/final" "$dest/" 2>/dev/null || echo "[WARN] primary: no final/ yet (still running)"
  for f in flow.log warning.log error.log; do
    [ -f "$run_dir/$f" ] && cp "$run_dir/$f" "$dest/"
  done
  echo "$run_dir" > "$dest/source_run_dir.txt"
}

collect_replica() {
  local i="$1"
  local design_dir="$WORK_ROOT/replica_$i"
  local run_dir
  run_dir=$(latest_run_dir "$design_dir") || { echo "[WARN] replica_$i: no run directory yet"; return; }
  local dest="$BUNDLE_DIR/replica_$i"
  mkdir -p "$dest"
  [ -f "$run_dir/final/metrics.json" ] && cp "$run_dir/final/metrics.json" "$dest/"
  [ -f "$run_dir/flow.log" ] && cp "$run_dir/flow.log" "$dest/"
  local gds
  gds=$(ls "$run_dir"/final/gds/*.gds 2>/dev/null | head -n1)
  if [ -n "${gds:-}" ]; then
    sha256sum "$gds" | awk '{print $1}' > "$dest/gds_sha256.txt"
  else
    echo "[WARN] replica_$i: no final GDS yet (still running or failed)"
  fi
}

echo "[OK] collecting primary"
collect_primary

echo "[OK] collecting replicas"
for d in "$WORK_ROOT"/replica_*; do
  [ -d "$d" ] || continue
  i="${d##*replica_}"
  collect_replica "$i"
done

# --- determinism report: compare every completed replica's GDS hash
#     against the primary's ---
{
  echo "# Determinism check (GDS hash comparison)"
  echo "Generated: $(date -u +%FT%TZ)"
  echo
  primary_gds=$(ls "$BUNDLE_DIR"/primary/final/gds/*.gds 2>/dev/null | head -n1)
  if [ -n "${primary_gds:-}" ]; then
    primary_hash=$(sha256sum "$primary_gds" | awk '{print $1}')
    echo "primary: $primary_hash"
    for d in "$BUNDLE_DIR"/replica_*; do
      [ -d "$d" ] || continue
      name=$(basename "$d")
      if [ -f "$d/gds_sha256.txt" ]; then
        rep_hash=$(cat "$d/gds_sha256.txt")
        if [ "$rep_hash" = "$primary_hash" ]; then
          echo "$name: $rep_hash  [MATCH]"
        else
          echo "$name: $rep_hash  [MISMATCH -- investigate, do not assume it's fine]"
        fi
      else
        echo "$name: (no GDS collected -- run not finished)"
      fi
    done
  else
    echo "primary GDS not yet available -- cannot run the comparison yet."
  fi
} > "$BUNDLE_DIR/DETERMINISM_REPORT.txt"
cat "$BUNDLE_DIR/DETERMINISM_REPORT.txt"

# also snapshot the resource log so far, whatever's captured
[ -f "$WORK_ROOT/resource_log.txt" ] && cp "$WORK_ROOT/resource_log.txt" "$BUNDLE_DIR/"

# --- compress and report exactly what to download ---
ARCHIVE="$WORK_ROOT/$(basename "$BUNDLE_DIR").tar.gz"
tar -C "$WORK_ROOT" -cf - "$(basename "$BUNDLE_DIR")" | pigz -9 > "$ARCHIVE" 2>/dev/null \
  || tar -C "$WORK_ROOT" -czf "$ARCHIVE" "$(basename "$BUNDLE_DIR")"

echo
echo "[OK] bundle ready: $ARCHIVE"
du -h "$ARCHIVE"
sha256sum "$ARCHIVE"
echo
echo "[OK] download it now, BEFORE destroying the VM, e.g. from your own machine:"
echo "    scp <vm-user>@<vm-ip>:$ARCHIVE ."
