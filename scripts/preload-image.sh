#!/usr/bin/env bash
# preload-image.sh — đảm bảo image có trên CẢ 3 node, phân phối qua mgmt LAN
#
# Lý do: băng thông tới ghcr.io/docker.io/quay.io rất chậm (~0.26 MB/s).
# Pull mỗi node độc lập mất hàng chục phút × 3. Thay vào đó:
#   pull(node0) → export tar → scp qua 10.10.10.0/24 (~1Gbps) → import(worker).
#
# Chạy TRÊN node0:  bash /vagrant/scripts/preload-image.sh <full-image-ref>
# Ví dụ:           bash /vagrant/scripts/preload-image.sh docker.io/traefik/whoami:v1.10.2
set -euo pipefail
IMG="${1:?Can truyen full image ref, vd: docker.io/traefik/whoami:v1.10.2}"
WORKERS=("10.10.10.11" "10.10.10.12")
TAR="/tmp/img-$(echo "$IMG" | tr '/:@' '___').tar"

# Pull trên node0 nếu chưa có
if sudo k3s ctr images ls -q | grep -qx "$IMG"; then
  echo "[preload] $IMG da co tren node0, bo qua pull."
else
  echo "[preload] pull $IMG tren node0..."
  sudo k3s ctr images pull "$IMG"
fi

echo "[preload] export -> $TAR"
sudo k3s ctr images export "$TAR" "$IMG"
sudo chown vagrant:vagrant "$TAR"

for w in "${WORKERS[@]}"; do
  echo "[preload] $w: scp + import"
  scp -q -o StrictHostKeyChecking=no "$TAR" "vagrant@$w:$TAR"
  ssh -o StrictHostKeyChecking=no "vagrant@$w" "sudo k3s ctr images import $TAR && rm -f $TAR"
done

rm -f "$TAR"
echo "[preload] DONE: $IMG san sang tren ca 3 node."
