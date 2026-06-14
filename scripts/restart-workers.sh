#!/usr/bin/env bash
# restart-workers.sh — restart k3s-agent trên node1/node2 qua mgmt SSH (chạy trên node0)
set -uo pipefail
for ip in 10.10.10.11 10.10.10.12; do
  echo "=== $ip ==="
  ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 "vagrant@$ip" \
    "sudo systemctl restart k3s-agent && echo restarted && sudo systemctl is-active k3s-agent" \
    || echo "[FAIL] $ip unreachable"
done
