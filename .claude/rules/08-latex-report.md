---
description: Hướng dẫn viết báo cáo LaTeX cho đồ án IT3943 — cấu trúc chương, tổ chức file Overleaf, cách lấy hình và snippet LaTeX sẵn dùng.
globs: report/**,*.tex
---

## Thông tin bìa

```
Trường:    Hanoi University of Science and Technology
Khoa:      School of Information Technology and Communication
Môn:       IT3943 - Project III
Sinh viên: Tô Hùng Anh — MSSV: 20225164
```

Template gốc: `report_template.tex` — dùng lại toàn bộ preamble, chỉ thay nội dung.

---

## Cấu trúc chương

```
Section 1 — Introduction
  1.1  Motivation and Background   (NFV/SDN xu hướng telco, cloud-native)
  1.2  Problem Statement           (local testbed để học/demo ETSI NFV)
  1.3  Objectives                  (6 mục tiêu từ project overview)
  1.4  Report Organization

Section 2 — Theoretical Background
  2.1  NFV Architecture (ETSI GS NFV 002) — NFVI / VIM / VNF / VNFM / NFVO
  2.2  SDN Concepts (control/data plane separation)
  2.3  OpenStack as traditional VIM — Nova, Neutron, Cinder
  2.4  Kubernetes as Cloud-Native VIM — Pod, Deployment, Service, HPA

Section 3 — VNF to CNF Migration
  3.1  Limitations of VM-based VNF (boot time, resource overhead)
  3.2  Cloud-Native Network Functions (CNF)
  3.3  OpenStack → Kubernetes mapping (bảng ánh xạ ETSI)
  3.4  Multi-NIC Networking: Multus + macvlan

Section 4 — System Architecture
  4.1  Cluster Topology (node0/1/2, IP plan)
  4.2  Three-Plane Network Design (MGMT / K8s / DATA-PLANE)
  4.3  Technology Stack
  4.4  Resource Constraints and Optimizations (16 GB RAM limit)

Section 5 — Implementation
  5.1  Infrastructure as Code (Vagrantfile)
  5.2  Cluster Provisioning (Ansible — k3s server + workers)
  5.3  Secondary CNI (Multus + Whereabouts IPAM)
  5.4  CNF Deployment (namespace, NAD, Deployment, Service, HPA)
  5.5  Observability Stack (Helm — kube-prometheus-stack, SSH tunnel)

Section 6 — Testing and Evaluation
  6.1  TC-01: Multi-NIC Connectivity
  6.2  TC-02: Data-plane Throughput (iperf3)
  6.3  TC-03: Load Balancing
  6.4  TC-04: HPA Auto-scaling
  6.5  TC-05: Observability
  6.6  Summary Table + Discussion

Section 7 — Conclusion and Future Work
  7.1  Achievements
  7.2  Limitations
  7.3  Future Work (GitOps, SR-IOV, DPDK, multi-cluster)

References
Appendix A — Directory Structure
Appendix B — Key Configuration Files (Vagrantfile, monitoring-values.yaml)
```

---

## Tổ chức file trên Overleaf

```
report/
├── main.tex                   ← \input từng section
├── Images/
│   ├── hust_logo.jpg          ← logo trường (OIP.jpg từ template cũ)
│   ├── etsi_nfv_arch.png      ← vẽ bằng draw.io, export PNG 300 dpi
│   ├── cluster_topo.png       ← sơ đồ 3 node + 2 network
│   ├── grafana_overview.png
│   ├── grafana_hpa.png
│   ├── term_iperf3.png
│   ├── term_ping.png
│   └── term_kubectl_nodes.png
└── sections/
    ├── 01_intro.tex
    ├── 02_theory.tex
    ├── 03_vnf_cnf.tex
    ├── 04_architecture.tex
    ├── 05_implementation.tex
    ├── 06_testing.tex
    └── 07_conclusion.tex
```

---

## Cách thu thập hình ảnh

| Hình | Cách lấy |
|------|----------|
| Grafana dashboard | SSH tunnel → `http://localhost:3000` → Share → PNG |
| Grafana HPA panel | Khi chạy TC-04, crop panel CPU/Replicas |
| Terminal output | Screenshot PowerShell (font monospace) |
| iperf3 log | `kubectl logs iperf3-client > iperf3.txt` → dùng `\lstinputlisting` |
| Sơ đồ kiến trúc | draw.io → Export → PNG (300 dpi) |

---

## Snippet LaTeX sẵn dùng

```latex
% Chèn hình Grafana
\begin{figure}[H]
    \centering
    \includegraphics[width=0.9\textwidth]{Images/grafana_overview.png}
    \caption{Grafana Dashboard — Node Resource Overview}
    \label{fig:grafana_overview}
\end{figure}

% Chèn output terminal
\begin{lstlisting}[language=bash, caption=iperf3 throughput result]
[ ID] Interval       Transfer     Bitrate
[  5] 0.00-30.00 sec  2.87 GBytes   822 Mbits/sec   receiver
\end{lstlisting}

% Bảng kết quả kiểm thử
\begin{table}[H]
\centering
\begin{tabular}{clcc}
\toprule
\textbf{TC} & \textbf{Test Case} & \textbf{Result} & \textbf{Status} \\
\midrule
TC-01 & Multi-NIC Connectivity  & RTT = 0.8 ms, Loss = 0\%   & \textbf{PASS} \\
TC-02 & iperf3 Throughput       & 822 Mbps avg               & \textbf{PASS} \\
TC-03 & Load Balancing          & 10/10/10 distribution      & \textbf{PASS} \\
TC-04 & HPA Auto-scaling        & Scale-up in 72 s           & \textbf{PASS} \\
TC-05 & Observability           & 0 targets DOWN             & \textbf{PASS} \\
\bottomrule
\end{tabular}
\caption{Test Results Summary}
\label{tab:test_results}
\end{table}
```

---

## Tài liệu tham khảo chính

```
[1] ETSI GS NFV 002 V1.2.1 — Network Functions Virtualisation: Architectural Framework (2014)
[2] ETSI GR NFV-IFA 022 — Cloud-Native appliances (CNF) requirements (2021)
[3] Linux Foundation Networking — "Cloud Native Telco" (2022)
[4] k3s Documentation — https://docs.k3s.io
[5] Multus-CNI — https://github.com/k8snetworkplumbingwg/multus-cni
[6] Whereabouts IPAM — https://github.com/k8snetworkplumbingwg/whereabouts
[7] kube-prometheus-stack — https://github.com/prometheus-community/helm-charts
```
