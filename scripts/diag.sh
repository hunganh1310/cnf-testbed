#!/usr/bin/env bash
# diag.sh — chẩn đoán nhanh pod (tránh quoting khi gọi qua vagrant ssh trên Windows)
# Dùng: bash /vagrant/scripts/diag.sh <namespace> <pod-name> <container>
set -uo pipefail
NS="${1:-kube-system}"
POD="${2:-}"
CON="${3:-}"

echo "==== get pod ===="
kubectl -n "$NS" get pod "$POD" -o wide

echo "==== last terminated state ===="
kubectl -n "$NS" get pod "$POD" -o jsonpath='{range .status.containerStatuses[*]}{.name}{": exit="}{.lastState.terminated.exitCode}{" reason="}{.lastState.terminated.reason}{" msg="}{.lastState.terminated.message}{"\n"}{end}'

echo ""
echo "==== current logs ($CON) ===="
kubectl -n "$NS" logs "$POD" -c "$CON" --tail=40 2>&1

echo "==== previous logs ($CON) ===="
kubectl -n "$NS" logs "$POD" -c "$CON" --previous --tail=40 2>&1
