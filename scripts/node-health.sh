#!/usr/bin/env bash
# node-health.sh — xem điều kiện Ready và runtime của node
kubectl get nodes -o wide 2>&1
echo "=== node0 Ready condition ==="
kubectl describe node node0 2>&1 | grep -A1 -E 'Ready|ContainerRuntime|NetworkReady' | head -20
echo "=== k3s recent ==="
sudo journalctl -u k3s --no-pager -n 5 2>&1 | tail -5
