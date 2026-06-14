#!/usr/bin/env bash
# bootstrap.sh — Cài đặt cơ bản cho mọi node trong cluster
# Chạy lần đầu khi vagrant provision, idempotent

set -euo pipefail

# Cập nhật package list (1 lần, tránh duplicate)
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq

# Cài các gói cần thiết
apt-get install -y -qq \
  curl \
  wget \
  git \
  vim \
  net-tools \
  iproute2 \
  iputils-ping \
  tcpdump \
  nfs-common \
  open-iscsi \
  jq

# Tắt swap — bắt buộc với k3s
swapoff -a
sed -i '/swap/d' /etc/fstab

# Tải modules kernel cần thiết cho container networking
modprobe br_netfilter
modprobe overlay

cat > /etc/modules-load.d/k8s.conf <<EOF
br_netfilter
overlay
EOF

# Thiết lập sysctl cho Kubernetes networking
cat > /etc/sysctl.d/99-kubernetes.conf <<EOF
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system -q

# Thiết lập SSH không check host key — cần cho Ansible
sed -i 's/#StrictHostKeyChecking ask/StrictHostKeyChecking no/' /etc/ssh/ssh_config

# DNS upstream tin cậy — stub systemd-resolved mặc định (qua NAT DNS) timeout chập chờn,
# gây EAI_AGAIN khi containerd pull image (ghcr.io). Trỏ thẳng 8.8.8.8 / 1.1.1.1.
mkdir -p /etc/systemd/resolved.conf.d
cat > /etc/systemd/resolved.conf.d/upstream-dns.conf <<EOF
[Resolve]
DNS=8.8.8.8 1.1.1.1
FallbackDNS=8.8.4.4
EOF
systemctl restart systemd-resolved

echo "[bootstrap] Node $(hostname) — done."
