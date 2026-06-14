# Hướng dẫn tự kiểm thử — CNF/NFVI Testbed

Tài liệu hướng dẫn chạy lại 5 kịch bản kiểm thử (TC-01…TC-05) và đọc kết quả.

> **Quy ước:** mọi lệnh chạy trong **PowerShell** trên host Windows, tại thư mục
> `d:\CODE\cnf-testbed`. Logic test nằm trong `tests/selftest.sh` (chạy bên trong
> node0 để tránh lỗi quoting khi truyền `--` qua `vagrant ssh`).

## 0. Điều kiện tiên quyết

```powershell
# Cụm phải đang chạy và 3 node Ready
vagrant ssh node0 -c "kubectl get nodes"
# CNF đã deploy
vagrant ssh node0 -c "kubectl -n cnf-demo get pods"
```

Nếu chưa dựng, xem [README.md](README.md).

> **Lưu ý gói thử data-plane:** TC-01 và TC-02 dùng 2 pod `iperf3-server` /
> `iperf3-client` (image `network-multitool`, có sẵn `ip`/`ping`/`iperf3`/`ab`).
> Hàm `ensure_dataplane` trong script tự tạo chúng khi cần. CNF chính (`whoami`)
> là image distroless nên không exec được — đó là lý do dùng pod multitool riêng
> cho các bài cần công cụ mạng.

---

## TC-01 — Multi-NIC Connectivity

**Mục đích:** xác nhận data-plane (net1 / macvlan trên eth2) hoạt động độc lập.

```powershell
vagrant ssh node0 -c "bash /vagrant/tests/selftest.sh tc01"
```

**Việc script làm:**
1. Tạo 2 pod data-plane (cùng node1).
2. In `ip addr show net1` của mỗi pod → phải có IP `10.30.0.x`.
3. In net1 của 3 pod CNF `whoami` (đọc từ annotation multus).
4. Ping `client(10.30.0.199) → server(10.30.0.200)` qua net1, 10 gói.

**Tiêu chí PASS:** mỗi pod có IP trong `10.30.0.100–200`; packet loss = 0%; RTT < 5 ms.

> macvlan-bridge **nội node** giao tiếp qua kernel bridge nên không cần
> promiscuous mode. Test **cross-node** (server/client khác node) cần bật
> `--nicpromisc3 allow-all` cho NIC eth2 trên VirtualBox — đây là hạn chế đã biết.

---

## TC-02 — iperf3 Throughput

**Mục đích:** đo băng thông data-plane qua net1.

```powershell
vagrant ssh node0 -c "bash /vagrant/tests/selftest.sh tc02"
```

**Việc script làm:** exec `iperf3 -c 10.30.0.200 -t 30` từ client tới server qua net1.

**Tiêu chí PASS:** throughput ≥ 800 Mbps (intra-node macvlan đạt hàng chục Gbps),
retransmits thấp.

---

## TC-03 — Load Balancing

**Mục đích:** xác nhận ClusterIP Service phân phối tới cả 3 replica.

```powershell
vagrant ssh node0 -c "bash /vagrant/tests/selftest.sh tc03"
```

**Việc script làm:** gửi 30 request `curl http://<ClusterIP>/api`, đếm hostname trả về.

**Tiêu chí PASS:** cả 3 pod đều nhận request, phân phối xấp xỉ đều (~33% mỗi pod).

---

## TC-04 — HPA Auto-scaling

**Mục đích:** kiểm tra HPA tăng replica khi CPU vượt 70%.

```powershell
vagrant ssh node0 -c "bash /vagrant/tests/selftest.sh tc04"
```

**Việc script làm:**
1. In HPA ban đầu (3 replica).
2. Chạy ApacheBench `ab -t 150 -c 200 -k` từ pod multitool vào ClusterIP → đẩy CPU.
3. Theo dõi HPA + số replica mỗi 15s trong ~165s.
4. Dừng tải, in HPA cuối (cool-down).

**Tiêu chí PASS:** CPU > 70% → scale-up < 90s, replicas tăng (tối đa 6).
Sau khi tắt tải, cool-down về 3 trong vài phút.

> Xem real-time song song ở terminal khác:
> `vagrant ssh node0 -c "kubectl -n cnf-demo get hpa -w"`

---

## TC-05 — Observability

**Mục đích:** xác nhận Prometheus scrape đủ target và Grafana hiển thị.

```powershell
# 1. Kiểm tra target Prometheus + pod monitoring
vagrant ssh node0 -c "bash /vagrant/tests/selftest.sh tc05"

# 2. Mở Grafana qua SSH tunnel (giữ cửa sổ này chạy)
#    mgmt-net là intnet → host Windows KHÔNG route tới 10.10.10.10.
#    Phải tunnel qua NAT của Vagrant; "localhost:30030" được resolve TRONG node0.
vagrant ssh node0 -- -N -L 3000:localhost:30030
# rồi mở http://localhost:3000  (admin / admin)
```

**Checklist Grafana:**
- [ ] Node Exporter → CPU/RAM/Disk cho cả 3 node
- [ ] kube-state-metrics → pod count, deployment status
- [ ] Prometheus `/targets` → tất cả UP

**Tiêu chí PASS:** 0 target DOWN; dashboard cập nhật < 30s; RAM cụm < 12 GB.

---

## Dọn dẹp pod test

```powershell
vagrant ssh node0 -c "bash /vagrant/tests/selftest.sh tc02_clean"
```

## Bảng tổng hợp tiêu chí

| TC | Tên | Metrics chính | Tiêu chí PASS |
|----|-----|---------------|---------------|
| TC-01 | Multi-NIC Connectivity | Packet loss, RTT | Loss=0%, RTT<5ms |
| TC-02 | iperf3 Throughput | Bandwidth | ≥800 Mbps |
| TC-03 | Load Balancing | Phân phối request | Cả 3 pod đều nhận |
| TC-04 | HPA Auto-scaling | Scale-up time, replicas | <90s, replicas tăng |
| TC-05 | Observability | Prometheus targets | 0 DOWN |
