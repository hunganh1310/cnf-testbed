# CNF / NFVI Testbed — Project Context

Đồ án IT3943 (Project III) — HUST, Tô Hùng Anh (MSSV 20225164).
Xây dựng mini NFVI stack mô phỏng ETSI NFV bằng k3s.

Chi tiết được tổ chức trong `.claude/rules/`:

| File | Nội dung | Load khi |
|------|----------|----------|
| `01-project-overview.md` | Mục tiêu, tech stack, ánh xạ ETSI NFV→K8s | Luôn luôn |
| `02-environment-constraints.md` | RAM limit, PowerShell, VM spec | Luôn luôn |
| `03-architecture-network.md` | Cluster 3 node, thiết kế mạng 3 lớp | Vagrantfile / ansible / manifests |
| `04-coding-conventions.md` | Quy ước code, danh sách cấm | Luôn luôn |
| `05-directory-structure.md` | Cấu trúc thư mục chuẩn | Theo yêu cầu |
| `06-build-workflow.md` | Thứ tự build từ đầu đến cuối | Theo yêu cầu |
| `07-test-scenarios.md` | 5 TC: connectivity, throughput, LB, HPA, observability | tests/ |
| `08-latex-report.md` | Cấu trúc báo cáo, Overleaf, snippet LaTeX | report/ / *.tex |
