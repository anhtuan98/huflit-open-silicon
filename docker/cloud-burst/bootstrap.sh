#!/usr/bin/env bash
# Bootstrap a fresh Ubuntu Linode VM for the picorv32 cloud-burst job.
#
# Run this once, right after the VM boots, as the first thing you do over
# SSH. It installs Docker, clones the repo, and pulls/builds the pinned
# toolchain image (docker/Dockerfile pins hpretl/iic-osic-tools:2026.08,
# ~3.76GB compressed -- see that file for why). Everything here is
# unattended; no interactive prompts.
#
# Usage: ./bootstrap.sh <git-branch-to-clone>
#   e.g. ./bootstrap.sh picorv32-cloud-burst
#
# Prereq: the branch named above must already be pushed to the repo's
# GitHub remote -- this script does NOT copy local uncommitted files from
# your laptop. Review and push before renting the VM (see
# docs/picorv32-cloud-burst-plan.md).

set -euo pipefail

BRANCH="${1:?Usage: bootstrap.sh <branch-name>}"
REPO_URL="https://github.com/anhtuan98/huflit-open-silicon.git"
REPO_DIR="$HOME/huflit-open-silicon"

log() { printf '[%s] %s\n' "$(date -u +%H:%M:%S)" "$1"; }

log "=== 1/4: apt update + base packages ==="
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq git rsync jq tmux ca-certificates curl >/dev/null

log "=== 2/4: install Docker CE + compose plugin (official convenience script) ==="
if ! command -v docker >/dev/null 2>&1; then
  curl -fsSL https://get.docker.com | sh
fi
docker --version
docker compose version

log "=== 3/4: clone ${REPO_URL} @ ${BRANCH} ==="
if [ -d "$REPO_DIR" ]; then
  log "[WARN] ${REPO_DIR} already exists -- pulling instead of cloning"
  git -C "$REPO_DIR" fetch origin "$BRANCH"
  git -C "$REPO_DIR" checkout "$BRANCH"
  git -C "$REPO_DIR" reset --hard "origin/${BRANCH}"
else
  git clone --branch "$BRANCH" --single-branch "$REPO_URL" "$REPO_DIR"
fi
cd "$REPO_DIR"

log "=== 4/4: pull/build the pinned toolchain image (this is the slow step -- expect a few minutes) ==="
time docker compose -f docker/docker-compose.yml build

log "=== Smoke test ==="
docker compose -f docker/docker-compose.yml run --rm librelane-dev --skip librelane --version

log "[OK] Bootstrap complete. Repo at ${REPO_DIR}. Next: run docker/cloud-burst/driver.sh inside a tmux session."
log "     tmux new -s burst"
log "     cd ${REPO_DIR} && PEAK_RAM_GB=<value from local dry run> ./docker/cloud-burst/driver.sh"
