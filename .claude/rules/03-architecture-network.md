---
description: Kiến trúc cluster 3 node và thiết kế mạng 3 lớp (MGMT / K8s / DATA-PLANE). Áp dụng khi chỉnh Vagrantfile, Ansible playbook, manifest networking hoặc CNI config.
globs: Vagrantfile,ansible/**,manifests/**,helm/**
---

## Kiến trúc cluster

```
node0 (control-plane) — 10.10.10.10 — kubectl, Helm, k3s server
node1 (worker)        — 10.10.10.11 — CNF workload
node2 (worker)        — 10.10.10.12 — CNF workload
```

Mỗi VM có **2 network interface**:
- `eth1` → MGMT network (10.10.10.0/24)
- `eth2` → DATA-PLANE network (10.30.0.0/24, VLAN 30)

## Thiết kế mạng — 3 lớp KHÔNG được trộn lẫn

| Lớp | CIDR | Interface | CNI | Tương đương ETSI |
|-----|------|-----------|-----|------------------|
| MGMT | 10.10.10.0/24 | eth1 | VirtualBox intnet `mgmt-net` | Management plane |
| K8s Cluster | 10.42.0.0/16 | flannel.1 | Flannel (VXLAN overlay) | Control plane signaling |
| DATA-PLANE | 10.30.0.0/24 | eth2 → `net1` trong pod | Multus + macvlan + Whereabouts | User plane |

## Lưu ý quan trọng

- VirtualBox dùng `virtualbox__intnet` (Internal Network) → host Windows **KHÔNG có route** vào 10.10.10.0/24. Truy cập Grafana phải qua **SSH tunnel**.
- Data-plane (`net1`) dùng **macvlan master = eth2**, IPAM = Whereabouts range `10.30.0.100–10.30.0.200`.
- Ba lớp mạng phải **tách biệt hoàn toàn** — không route chéo giữa MGMT và DATA-PLANE.
