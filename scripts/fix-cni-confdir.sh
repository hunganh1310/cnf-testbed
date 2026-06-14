#!/usr/bin/env bash
# fix-cni-confdir.sh — symlink default CNI conf dir -> k3s conf dir
#
# k3s đặt CNI config tại /var/lib/rancher/k3s/agent/etc/cni/net.d, nhưng nhiều
# plugin (whereabouts) lại đọc config ở path mặc định /etc/cni/net.d/<plugin>.d.
# Tạo symlink /etc/cni/net.d -> path k3s để mọi plugin tìm thấy config.
#
# Chạy TRÊN node0:  bash /vagrant/scripts/fix-cni-confdir.sh
set -euo pipefail
K3S_CONF="/var/lib/rancher/k3s/agent/etc/cni/net.d"
NODES=("10.10.10.10" "10.10.10.11" "10.10.10.12")

fix_one() {
  local host="$1"
  local cmd="
    set -e
    if [ -L /etc/cni/net.d ]; then
      echo 'da la symlink, bo qua'
    else
      sudo rm -rf /etc/cni/net.d
      sudo mkdir -p /etc/cni
      sudo ln -sfn $K3S_CONF /etc/cni/net.d
      echo 'da tao symlink /etc/cni/net.d -> $K3S_CONF'
    fi
  "
  if [ "$host" = "10.10.10.10" ]; then
    bash -c "$cmd"
  else
    ssh -o StrictHostKeyChecking=no "vagrant@$host" "$cmd"
  fi
}

for n in "${NODES[@]}"; do
  echo -n "[$n] "
  fix_one "$n"
done
echo "DONE"
