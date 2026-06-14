#!/usr/bin/env bash
# preload-all.sh — nạp sẵn mọi image nhỏ cần cho test scenarios lên cả 3 node
set -uo pipefail
IMAGES=(
  "docker.io/traefik/whoami:v1.10.2"          # CNF workload
  "docker.io/networkstatic/iperf3:latest"      # TC-02 throughput
  "docker.io/polinux/stress:latest"            # TC-04 HPA load
  "docker.io/curlimages/curl:latest"           # TC-03 load-balancing client
)
for img in "${IMAGES[@]}"; do
  echo "==================== $img ===================="
  bash /vagrant/scripts/preload-image.sh "$img" || echo "[WARN] preload failed: $img"
done
echo "ALL DONE"
