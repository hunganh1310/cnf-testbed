---
description: 5 kịch bản kiểm thử cho đồ án — lệnh chạy, tiêu chí Pass/Fail và hướng dẫn capture kết quả. Áp dụng khi làm việc với file test hoặc chạy kiểm thử.
globs: tests/**
---

## Quy tắc chung

Mỗi TC phải ghi lại: **lệnh chạy + output terminal hoặc Grafana screenshot + kết quả Pass/Fail**.

---

## TC-01 — Multi-NIC Connectivity

**Mục đích:** Xác nhận data-plane (net1 / VLAN 30) hoạt động độc lập với management plane.

```bash
kubectl exec -n cnf-demo <pod-A> -- ip addr show net1
kubectl exec -n cnf-demo <pod-B> -- ip addr show net1
kubectl exec -n cnf-demo <pod-A> -- ping -c 10 <IP_net1_pod-B>
```

**Pass:** Mỗi pod có IP trong `10.30.0.100–10.30.0.200`, packet loss = 0%, RTT < 5 ms.
**Capture:** screenshot `ip addr` + output ping.

---

## TC-02 — iperf3 Throughput

**Mục đích:** Đo băng thông thực tế qua macvlan (net1) trên VLAN 30.

```bash
kubectl apply -f tests/iperf3-server.yaml
kubectl apply -f tests/iperf3-client.yaml
kubectl logs -n cnf-demo iperf3-client   # chạy 3 lần, 30s mỗi lần
```

**Pass:** Throughput ≥ 800 Mbps, Jitter < 1 ms, Retransmits < 50.
**Capture:** output iperf3 đầy đủ (3 lần); tính trung bình ghi vào bảng báo cáo.

---

## TC-03 — Load Balancing

**Mục đích:** Xác nhận ClusterIP Service phân phối request đến cả 3 replica.

```bash
kubectl run -it --rm curl-test --image=curlimages/curl --restart=Never -- \
  sh -c 'for i in $(seq 1 30); do curl -s http://<ClusterIP>:<port>/hostname; done'

kubectl logs -n cnf-demo -l app=cnf-demo --prefix | grep "request"
```

**Pass:** Mỗi pod nhận ≥ 8/30 request (phân phối ~33%), không có pod bị bỏ qua.
**Capture:** output vòng lặp curl + log 3 pod.

---

## TC-04 — HPA Auto-scaling

**Mục đích:** Kiểm tra HPA tăng replica khi CPU vượt ngưỡng.

```bash
# Terminal 1 — theo dõi real-time
kubectl get hpa -n cnf-demo -w

# Terminal 2 — sinh tải CPU
kubectl run -n cnf-demo stress --image=polinux/stress --restart=Never -- \
  stress --cpu 2 --timeout 120s

kubectl get pods -n cnf-demo -w
```

**Pass:** CPU > 70% → scale-up trong < 90 s, replicas ≥ 5. Sau khi tắt tải, cool-down về 3 trong < 5 phút.
**Capture:** Grafana panel "CPU Usage per Pod" + output `kubectl get hpa -w`.

---

## TC-05 — Observability

**Mục đích:** Xác nhận Prometheus scrape đủ metrics và Grafana hiển thị live.

```powershell
# Mở SSH tunnel (PowerShell — host Windows)
ssh -L 3000:localhost:3000 vagrant@10.10.10.10 -N
# Truy cập http://localhost:3000 (admin/admin)
```

**Checklist Grafana:**
- [ ] Node Exporter → CPU, RAM, Disk cho cả 3 node
- [ ] kube-state-metrics → pod count, deployment status
- [ ] Panel Network I/O hiển thị traffic trên eth2
- [ ] Prometheus `/targets` → tất cả UP

**Pass:** 0 target DOWN, dashboard cập nhật live < 30 s, RAM tổng cluster < 12 GB.
**Capture:** screenshot Grafana dashboard overview + Prometheus `/targets`.

---

## Bảng tổng hợp

| TC | Tên | Metrics chính | Tiêu chí Pass |
|----|-----|---------------|---------------|
| TC-01 | Multi-NIC Connectivity | Packet loss, RTT | Loss=0%, RTT<5ms |
| TC-02 | iperf3 Throughput | Bandwidth, Jitter | ≥800 Mbps, Jitter<1ms |
| TC-03 | Load Balancing | Request distribution | Mỗi pod ≥8/30 req |
| TC-04 | HPA Auto-scaling | Scale-up time, replicas | <90s, replicas≥5 |
| TC-05 | Observability | Prometheus targets | 0 DOWN, lag<30s |
