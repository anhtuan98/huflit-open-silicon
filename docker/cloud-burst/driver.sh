#!/usr/bin/env bash
# Adaptive driver for the picorv32 cloud-burst job. Run on the rented VM,
# from the repo root, inside tmux/screen (this can run for hours and must
# survive an SSH disconnect):
#
#   tmux new -s burst
#   PEAK_RAM_GB=<measured locally by the prep fork> ./docker/cloud-burst/driver.sh
#
# What it does:
#   Phase A -- one reference full LibreLane flow run on designs/picorv32,
#              timed. This alone is the guaranteed deliverable: a real,
#              meaningfully-sized open design signed off end to end.
#   Phase B -- as many parallel, byte-identical replica runs as the
#              *measured* Phase A time and RAM budget allow, for the
#              GDS-hash determinism check (kickoff doc Sec 5.2, the
#              "ECC of the poor man's" idea -- also catches software bugs,
#              not just hardware bit-flips).
#   Phase C -- hard cutoff (5 min before TOTAL_BUDGET_SECONDS elapses):
#              stop waiting on stragglers, bundle whatever final/ artifacts
#              exist into one small tarball, hash-compare them, write a
#              summary. Retrieve that one file, then destroy the VM.
#
# Nothing here guesses N in advance -- it is computed from Phase A's own
# measured wall-clock time, so the plan adapts to however slow or fast
# picorv32's flow actually turns out to be on this machine.

set -uo pipefail   # NOT -e: a failed replica must not kill the whole driver

TOTAL_BUDGET_SECONDS="${TOTAL_BUDGET_SECONDS:-9900}"   # default 2h45m of a 3h rental
PEAK_RAM_GB="${PEAK_RAM_GB:-8}"                          # override from local dry-run measurement
DESIGN_DIR="designs/picorv32"
REPLICA_ROOT="tmp/picorv32_replicas"
RESULTS_DIR="tmp/picorv32_results"
START_TS=$(date +%s)

log() { printf '[%s] %s\n' "$(date -u +%H:%M:%S)" "$1"; }
elapsed() { echo $(( $(date +%s) - START_TS )); }
remaining() { echo $(( TOTAL_BUDGET_SECONDS - $(elapsed) )); }

run_flow() {
  # $1 = path (relative to repo root) containing config.yaml + src/
  local dir="$1"
  docker compose -f docker/docker-compose.yml run --rm \
    --workdir "/workspace/${dir}" \
    librelane-dev --skip \
    librelane -p sky130A -s sky130_fd_sc_hd config.yaml
}

mkdir -p "$REPLICA_ROOT" "$RESULTS_DIR"

if [ ! -f "${DESIGN_DIR}/config.yaml" ]; then
  log "[FAIL] ${DESIGN_DIR}/config.yaml not found -- did the local prep step land? Aborting."
  exit 1
fi

log "=== Phase A: reference run (budget so far: $(remaining)s remaining of ${TOTAL_BUDGET_SECONDS}s) ==="
PHASE_A_START=$(date +%s)
run_flow "$DESIGN_DIR" > "${RESULTS_DIR}/reference.log" 2>&1
REF_STATUS=$?
PHASE_A_SECONDS=$(( $(date +%s) - PHASE_A_START ))
log "Reference run exit=${REF_STATUS} in ${PHASE_A_SECONDS}s"

if [ "$REF_STATUS" -ne 0 ]; then
  log "[FAIL] Reference run itself failed -- see ${RESULTS_DIR}/reference.log. Stopping here; do not burn budget on replicas of a broken config."
  N_REPLICAS=0
else
  REMAIN=$(remaining)
  log "Remaining budget: ${REMAIN}s"
  if [ "$REMAIN" -lt "$PHASE_A_SECONDS" ]; then
    log "[WARN] Not enough budget left for even one more full replica -- stopping after the reference run. That alone is the deliverable."
    N_REPLICAS=0
  else
    SAFE_REMAIN=$(( REMAIN - 600 ))                 # 10-min safety margin before bundling
    N_BY_TIME=$(( SAFE_REMAIN / PHASE_A_SECONDS ))
    N_BY_RAM=$(( 90 / PEAK_RAM_GB ))                 # 90 of 96GB, leaving host/docker headroom
    N_BY_CORES=$(( $(nproc) - 2 ))                   # leave 2 cores for host/orchestration
    N_REPLICAS=$N_BY_TIME
    [ "$N_BY_RAM"   -lt "$N_REPLICAS" ] && N_REPLICAS=$N_BY_RAM
    [ "$N_BY_CORES" -lt "$N_REPLICAS" ] && N_REPLICAS=$N_BY_CORES
    [ "$N_REPLICAS" -lt 1 ] && N_REPLICAS=0
    log "N_by_time=${N_BY_TIME} N_by_ram=${N_BY_RAM} (at ${PEAK_RAM_GB}GB/replica) N_by_cores=${N_BY_CORES} -> using N=${N_REPLICAS}"
  fi
fi

if [ "$N_REPLICAS" -gt 0 ]; then
  log "=== Phase B: launching ${N_REPLICAS} parallel determinism replicas ==="
  for i in $(seq 1 "$N_REPLICAS"); do
    rdir="${REPLICA_ROOT}/replica_${i}"
    mkdir -p "$rdir"
    cp -r "${DESIGN_DIR}/src" "${DESIGN_DIR}/config.yaml" "$rdir/"
    (
      run_flow "$rdir" > "${RESULTS_DIR}/replica_${i}.log" 2>&1
      log "replica ${i} finished exit=$?"
    ) &
  done

  CUTOFF_TS=$(( START_TS + TOTAL_BUDGET_SECONDS - 300 ))   # 5-min bundling margin
  while true; do
    running=$(jobs -rp | wc -l)
    [ "$running" -eq 0 ] && { log "All replicas finished before cutoff."; break; }
    if [ "$(date +%s)" -ge "$CUTOFF_TS" ]; then
      log "[WARN] Hard cutoff reached with ${running} replica(s) still running -- bundling now. Unfinished replicas simply have no final/ dir and are excluded below, not corrupted."
      break
    fi
    sleep 30
  done
fi

log "=== Phase C: bundle + hash-compare ==="
python3 docker/cloud-burst/bundle_results.py \
  --design-dir "$DESIGN_DIR" \
  --replica-root "$REPLICA_ROOT" \
  --out "${RESULTS_DIR}/bundle.tar.gz" \
  --summary "${RESULTS_DIR}/summary.md"

log "[OK] Done in $(elapsed)s. Retrieve now: scp/rsync ${RESULTS_DIR}/bundle.tar.gz off this VM, then destroy it."
log "     From your laptop: docker/cloud-burst/retrieve.sh <vm-ip>"
cat "${RESULTS_DIR}/summary.md"
