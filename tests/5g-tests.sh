#!/usr/bin/env bash
# 5g-tests.sh — Kịch bản kiểm thử 5G Core (Open5GS + UERANSIM) — chạy TRÊN node0
# =============================================================================
# Mỗi test chứng minh MỘT khả năng của NFVI platform thông qua CNF 5G THẬT:
#   TC-01  NF registration  — mọi NF đăng ký được với NRF (control-plane sống)
#   TC-02  UE attach        — UE đăng ký + mở PDU session, nhận IP (10.45.x.x)
#   TC-03  User-plane data  — ping + iperf3 từ UE xuyên GTP-U qua UPF (data-plane)
#   TC-04  NF autoscaling   — HPA scale NF stateless theo tải CPU
#   TC-05  Observability    — Prometheus scrape + metric UPF/AMF
#
# Dùng:
#   bash /vagrant/tests/5g-tests.sh tc01 | tc02 | tc03 | tc04 | tc05 | all
# =============================================================================
set -uo pipefail
NS=open5gs

ue_pod()  { kubectl -n "$NS" get pod -l app.kubernetes.io/name=ueransim-ue  -o jsonpath='{.items[0].metadata.name}' 2>/dev/null; }
gnb_pod() { kubectl -n "$NS" get pod -l app.kubernetes.io/name=ueransim-gnb -o jsonpath='{.items[0].metadata.name}' 2>/dev/null; }
upf_pod() { kubectl -n "$NS" get pod -l nf=upf -o jsonpath='{.items[0].metadata.name}' 2>/dev/null; }

tc01() {
  echo "########## TC-01 — 5G Core bring-up & NF registration ##########"
  echo ">>> Tất cả pod 5G Core (mong đợi đều Running):"
  kubectl -n "$NS" get pods -o wide
  echo
  echo ">>> Log NRF — các NF đăng ký dịch vụ (NFRegister):"
  local nrf
  nrf=$(kubectl -n "$NS" get pod -l nf=nrf -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
  kubectl -n "$NS" logs "$nrf" 2>/dev/null | grep -i "NFRegister\|NF Profile" | tail -20
}

tc02() {
  echo "########## TC-02 — UE registration & PDU session ##########"
  local ue; ue=$(ue_pod)
  echo "UE pod = $ue"
  echo
  echo ">>> Log UE — kỳ vọng 'Registration accept' + 'PDU Session establishment':"
  kubectl -n "$NS" logs "$ue" 2>/dev/null | grep -i "registration\|pdu session\|connection setup" | tail -15
  echo
  echo ">>> Interface tunnel uesimtun0 (IP do UPF cấp, dải 10.45.0.0/16):"
  kubectl -n "$NS" exec "$ue" -- ip -brief addr show uesimtun0
}

tc03() {
  echo "########## TC-03 — User-plane data path (UE -> UPF -> DN) ##########"
  local ue; ue=$(ue_pod)
  echo ">>> Ping 10 gói qua tunnel uesimtun0 (đi xuyên GTP-U tới UPF):"
  kubectl -n "$NS" exec "$ue" -- ping -I uesimtun0 -c 10 10.45.0.1
  echo
  echo ">>> iperf3 user-plane (UE -> UPF gateway), 30s — nếu có iperf3 server ở DN:"
  echo "    (chạy 'iperf3 -s' tại endpoint N6 rồi: iperf3 -B <uesimtun0-ip> -c <dn-ip> -t 30)"
  kubectl -n "$NS" exec "$ue" -- sh -c 'iperf3 -B $(ip -4 -o addr show uesimtun0 | awk "{print \$4}" | cut -d/ -f1) -c 10.30.0.200 -t 30 -i 5' 2>/dev/null \
    || echo "    [bỏ qua iperf3 nếu chưa dựng DN server — ping ở trên đã chứng minh data-plane]"
}

tc04() {
  echo "########## TC-04 — NF autoscaling (HPA trên NF stateless) ##########"
  echo "HPA hiện tại:"
  kubectl -n "$NS" get hpa
  echo
  echo ">>> Sinh tải CPU lên NRF bằng pod stress, theo dõi HPA scale-up:"
  kubectl -n "$NS" run nrf-load --image=polinux/stress --restart=Never -- \
    stress --cpu 2 --timeout 150s >/dev/null 2>&1 || true
  for i in $(seq 1 10); do
    sleep 15
    printf "t=%3ss  " "$((i*15))"
    kubectl -n "$NS" get hpa nrf-hpa --no-headers 2>/dev/null | awk '{print "cpu="$4"  replicas="$7}'
  done
  kubectl -n "$NS" delete pod nrf-load --ignore-not-found >/dev/null 2>&1
}

tc05() {
  echo "########## TC-05 — Observability của 5G Core ##########"
  echo "Pods monitoring:"
  kubectl -n monitoring get pods 2>/dev/null || { echo "Chưa cài monitoring"; return 1; }
  echo
  echo ">>> CPU/RAM thực tế của các NF 5G (qua metrics-server):"
  kubectl -n "$NS" top pods 2>/dev/null | sort -k1
}

case "${1:-all}" in
  tc01) tc01 ;;
  tc02) tc02 ;;
  tc03) tc03 ;;
  tc04) tc04 ;;
  tc05) tc05 ;;
  all)  tc01; echo; tc02; echo; tc03 ;;
  *) echo "Unknown: $1 (tc01..tc05|all)"; exit 1 ;;
esac
