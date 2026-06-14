---
description: Cấu trúc thư mục chuẩn của project. Tham chiếu khi tạo file mới hoặc cần biết file nào nằm ở đâu.
---

## Cấu trúc thư mục

```
cnf-testbed\
├── CLAUDE.md                        # Project context (root)
├── .claude\
│   ├── CLAUDE.md                    # Index trỏ đến rules
│   └── rules\                       # Rule files theo chủ đề
├── README.md                        # Hướng dẫn setup
├── Vagrantfile                      # Định nghĩa 3 VM + 2 network
├── ansible\
│   ├── inventory.ini
│   └── playbooks\
│       ├── k3s-master.yml           # Cài k3s control-plane (node0)
│       ├── k3s-worker.yml           # Join worker (node1, node2)
│       ├── cni.yml                  # Multus + Whereabouts
│       └── monitoring.yml           # Deploy Prometheus/Grafana
├── helm\
│   └── monitoring-values.yaml       # Values tối ưu 16 GB RAM
├── manifests\
│   ├── cnf-demo\
│   │   ├── namespace.yaml
│   │   ├── nad.yaml                 # NetworkAttachmentDefinition (net1/VLAN30)
│   │   ├── deployment.yaml          # CNF workload (replicas=3)
│   │   ├── service.yaml             # ClusterIP + load balancing
│   │   └── hpa.yaml                 # HorizontalPodAutoscaler
│   └── multus\
│       └── whereabouts-ipam.yaml
├── tests\
│   ├── iperf3-server.yaml
│   └── iperf3-client.yaml
└── report\                          # Báo cáo LaTeX (Overleaf)
    ├── main.tex
    ├── Images\
    └── sections\
```
