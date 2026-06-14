---
description: Tổng quan dự án CNF testbed — mục tiêu, tech stack và ánh xạ ETSI NFV sang Kubernetes. Đọc trước khi làm bất kỳ việc gì trong project.
alwaysApply: true
---

## Tổng quan dự án

Xây dựng **mini NFVI stack** mô phỏng kiến trúc ETSI NFV ở quy mô nhỏ, dùng cloud-native (Kubernetes thay vì OpenStack), chạy local trên máy cá nhân.

**Mục tiêu:**
- Provision multi-node Kubernetes cluster bằng IaC (Vagrant + Ansible)
- Triển khai CNF (Cloud-Native Network Function) với multi-NIC networking
- Tách biệt management / control / data plane (đúng pattern telco)
- Observability đầy đủ (Prometheus + Grafana)
- Auto-scaling (HPA) + data-plane throughput test (iperf3)
- Ánh xạ đúng kiến trúc ETSI NFV → Kubernetes

## Tech Stack

- Kubernetes: k3s (embedded etcd/SQLite)
- CNI primary: Flannel (VXLAN overlay)
- CNI secondary: Multus (meta-plugin) + macvlan + Whereabouts IPAM
- Package mgmt: Helm (chart: kube-prometheus-stack)
- Monitoring: Prometheus + Grafana + node-exporter + kube-state-metrics
- Testing: iperf3 (data-plane throughput)
- IaC: Vagrant + Ansible

## Ánh xạ ETSI NFV → Kubernetes (tham chiếu khi code)

| Khối ETSI | Tương đương trong testbed |
|-----------|---------------------------|
| NFVI | VirtualBox VMs (node0/1/2) |
| VIM | k3s API Server + Scheduler |
| VNF/CNF | Pods trong namespace `cnf-demo` |
| VNFM | Helm |
| NFVO | kubectl / GitOps (manual) |
