#!/usr/bin/env bash
# selftest.sh — chạy các kịch bản kiểm thử TC-01..TC-05 trên node0
#
# Dùng (TRÊN node0):
#   bash /vagrant/tests/selftest.sh tc01     # multi-NIC connectivity
#   bash /vagrant/tests/selftest.sh tc02     # iperf3 throughput
#   bash /vagrant/tests/selftest.sh tc03     # load balancing
#   bash /vagrant/tests/selftest.sh tc04     # HPA auto-scaling
#   bash /vagrant/tests/selftest.sh tc05     # observability targets
#   bash /vagrant/tests/selftest.sh all      # tc01 + tc03 (nhanh)
set -uo pipefail
NS=cnf-demo

pods() { kubectl -n "$NS" get pods -l app=cnf-demo -o jsonpath='{.items[*].metadata.name}'; }

ensure_dataplane() { # tạo 2 pod data-plane (multitool) nếu chưa có
  kubectl apply -f /vagrant/tests/iperf3-server.yaml >/dev/null
  kubectl apply -f /vagrant/tests/iperf3-client.yaml >/dev/null
  echo "Chờ 2 pod data-plane sẵn sàng..."
  kubectl -n "$NS" wait --for=condition=Ready pod/iperf3-server pod/iperf3-client --timeout=120s
}

tc01() {
  echo "########## TC-01 — Multi-NIC Connectivity ##########"
  ensure_dataplane
  echo
  echo "----- iperf3-server : net1 (mong đợi 10.30.0.200) -----"
  kubectl -n "$NS" exec iperf3-server -- ip -brief addr show net1
  echo "----- iperf3-client : net1 (mong đợi 10.30.0.199) -----"
  kubectl -n "$NS" exec iperf3-client -- ip -brief addr show net1
  echo
  echo ">>> CNF whoami pods cũng có net1 (đọc từ multus network-status):"
  for p in $(pods); do
    local s
    s=$(kubectl -n "$NS" get pod "$p" -o jsonpath='{.metadata.annotations.k8s\.v1\.cni\.cncf\.io/network-status}')
    echo "  $p : $(echo "$s" | tr '}' '\n' | grep -A2 net1 | grep -o '10\.30\.0\.[0-9]*' | head -1)"
  done
  echo
  echo ">>> Ping client(10.30.0.199) -> server(10.30.0.200) qua net1 (10 gói):"
  kubectl -n "$NS" exec iperf3-client -- ping -c 10 10.30.0.200
}

tc03() {
  echo "########## TC-03 — Load Balancing (ClusterIP) ##########"
  local cip; cip=$(kubectl -n "$NS" get svc cnf-demo -o jsonpath='{.spec.clusterIP}')
  echo "ClusterIP = $cip ; gửi 30 request /api ..."
  echo
  local out
  out=$(for i in $(seq 1 30); do
          curl -s "http://$cip/api" | tr ',' '\n' | grep -i '"hostname"';
        done)
  echo "$out" | sort | uniq -c | sort -rn
  echo
  echo ">>> Tổng request: $(echo "$out" | grep -c hostname) / 30"
}

tc02() {
  echo "########## TC-02 — iperf3 Throughput (net1 / data-plane) ##########"
  ensure_dataplane
  echo
  echo ">>> iperf3 client(.199) -> server(.200) qua net1 (macvlan-bridge nội node1), 30s:"
  kubectl -n "$NS" exec iperf3-client -- iperf3 -c 10.30.0.200 -t 30 -i 5
}

tc02_clean() {
  kubectl -n "$NS" delete pod iperf3-server iperf3-client --ignore-not-found
}

tc04() {
  echo "########## TC-04 — HPA Auto-scaling ##########"
  ensure_dataplane   # cần iperf3-client (multitool có ApacheBench 'ab')
  local cip; cip=$(kubectl -n "$NS" get svc cnf-demo -o jsonpath='{.spec.clusterIP}')
  echo "Trạng thái HPA ban đầu:"
  kubectl -n "$NS" get hpa cnf-demo
  echo
  echo ">>> Sinh tải HTTP bằng ApacheBench (c=200, keepalive, 150s) từ pod -> $cip"
  # whoami distroless không exec được → đẩy CPU pod bằng request HTTP cường độ cao
  # -n lớn để ab không dừng sớm ở mốc 50000 request mặc định (giữ tải đủ 150s)
  kubectl -n "$NS" exec iperf3-client -- sh -c "ab -t 150 -n 100000000 -c 200 -k http://$cip/ >/tmp/ab.log 2>&1" &
  local abpid=$!
  echo "Theo dõi HPA + replicas (mỗi 15s, ~165s):"
  printf "%-6s %-32s %-s\n" "t(s)" "HPA cpu/target / cur-replicas" "READY-PODS"
  local peak=3
  for i in $(seq 1 11); do
    sleep 15
    local hpa rep cur
    hpa=$(kubectl -n "$NS" get hpa cnf-demo --no-headers 2>/dev/null | awk '{print $4" / cur "$7}')
    cur=$(kubectl -n "$NS" get hpa cnf-demo --no-headers 2>/dev/null | awk '{print $7}')
    rep=$(kubectl -n "$NS" get pods -l app=cnf-demo --no-headers 2>/dev/null | grep -c '1/1')
    [ "${rep:-0}" -gt "$peak" ] && peak=$rep
    printf "%-6s %-32s %-s\n" "$((i*15))" "$hpa" "$rep"
  done
  echo ">>> Đỉnh replicas đạt: $peak. Chờ ab kết thúc + cool-down..."
  wait $abpid 2>/dev/null || true
  kubectl -n "$NS" get hpa cnf-demo
}

tc05() {
  echo "########## TC-05 — Observability ##########"
  echo "Pods monitoring:"
  kubectl -n monitoring get pods 2>/dev/null || { echo "Chưa cài monitoring"; return 1; }
  echo
  echo "Prometheus targets (health):"
  local pp
  pp=$(kubectl -n monitoring get pod -l app.kubernetes.io/name=prometheus -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
  kubectl -n monitoring exec "$pp" -c prometheus -- \
    wget -qO- 'http://localhost:9090/api/v1/targets?state=active' 2>/dev/null \
    | tr ',' '\n' | grep -i '"health"' | sort | uniq -c
}

case "${1:-all}" in
  tc01) tc01 ;;
  tc02) tc02 ;;
  tc02_clean) tc02_clean ;;
  tc03) tc03 ;;
  tc04) tc04 ;;
  tc05) tc05 ;;
  all)  tc01; echo; tc03 ;;
  *) echo "Unknown: $1"; exit 1 ;;
esac
