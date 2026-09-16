#!/usr/bin/env bash
# Run this on your LOCAL machine (not the VM) to pull the curated results
# bundle down fast, so the VM can be destroyed immediately after.
#
# Usage: ./retrieve.sh <vm-ip> [ssh-user] [remote-repo-dir]

set -euo pipefail

VM_IP="${1:?Usage: retrieve.sh <vm-ip> [ssh-user] [remote-repo-dir]}"
SSH_USER="${2:-root}"
REMOTE_DIR="${3:-/root/huflit-open-silicon}"
LOCAL_OUT="tmp/picorv32_results_from_vm"

mkdir -p "$LOCAL_OUT"

echo "[*] Pulling bundle.tar.gz and per-run logs from ${SSH_USER}@${VM_IP}:${REMOTE_DIR} ..."
rsync -avz --progress \
  "${SSH_USER}@${VM_IP}:${REMOTE_DIR}/tmp/picorv32_results/bundle.tar.gz" \
  "${SSH_USER}@${VM_IP}:${REMOTE_DIR}/tmp/picorv32_results/summary.md" \
  "${SSH_USER}@${VM_IP}:${REMOTE_DIR}/tmp/picorv32_results/"*.log \
  "$LOCAL_OUT/"

echo "[OK] Retrieved to ${LOCAL_OUT}/. Verify before destroying the VM:"
echo "     cat ${LOCAL_OUT}/summary.md"
echo "     tar tzf ${LOCAL_OUT}/bundle.tar.gz | head"
echo ""
echo "Once you've confirmed the bundle looks right, destroy the Linode VM."
