#!/usr/bin/env bash
# install-cni-plugins.sh — cài binary macvlan/static/ipvlan THẬT vào k3s CNI bin dir
#
# Lý do: multicall "cni" của k3s chỉ có 7 plugin (bridge, flannel, host-local...),
# KHÔNG có macvlan. Symlink macvlan->cni trả JSON rỗng → "unexpected end of JSON input".
# Tải bộ chuẩn containernetworking/plugins v1.5.1 (khớp k3s), trích 3 binary cần,
# cài lên node0 + phân phối qua mgmt LAN sang worker.
#
# Chạy TRÊN node0:  bash /vagrant/scripts/install-cni-plugins.sh
set -euo pipefail
VER="v1.5.1"
BIN_DIR="/var/lib/rancher/k3s/data/current/bin"
TGZ="/tmp/cni-plugins.tgz"
PLUGINS=(macvlan static ipvlan)
WORKERS=("10.10.10.11" "10.10.10.12")

if [ ! -f "$TGZ" ]; then
  echo "[cni] tai cni-plugins $VER..."
  curl -fsSL "https://github.com/containernetworking/plugins/releases/download/$VER/cni-plugins-linux-amd64-$VER.tgz" -o "$TGZ"
fi

echo "[cni] giai nen 3 binary -> /tmp"
for p in "${PLUGINS[@]}"; do
  tar -xzf "$TGZ" -C /tmp "./$p"
done

install_local() {
  for p in "${PLUGINS[@]}"; do
    sudo install -m 0755 "/tmp/$p" "$BIN_DIR/$p"
  done
}
echo "[cni] cai tren node0"
install_local

for w in "${WORKERS[@]}"; do
  echo "[cni] $w: copy + cai"
  for p in "${PLUGINS[@]}"; do
    scp -q -o StrictHostKeyChecking=no "/tmp/$p" "vagrant@$w:/tmp/$p"
  done
  ssh -o StrictHostKeyChecking=no "vagrant@$w" \
    "for p in ${PLUGINS[*]}; do sudo install -m 0755 /tmp/\$p $BIN_DIR/\$p; done"
done

echo "[cni] DONE. Kiem tra:"
file "$BIN_DIR/macvlan" || true
