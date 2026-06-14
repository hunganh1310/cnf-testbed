---
description: Môi trường host và ràng buộc cứng về RAM, hypervisor, shell. Mọi command và config phải tuân thủ các giới hạn này.
alwaysApply: true
---

## Môi trường host

| Thành phần | Giá trị | Ghi chú |
|-----------|---------|---------|
| Host OS | Windows 11 | Shell mặc định: **PowerShell** |
| RAM | **16 GB (ràng buộc cứng)** | Mọi deployment phải tối ưu RAM |
| Hypervisor | VirtualBox | |
| IaC | Vagrant | box: `bento/ubuntu-22.04` |
| Config mgmt | Ansible | |
| K8s distro | **k3s** (KHÔNG dùng kubeadm) | Nhẹ, phù hợp 16 GB |

## Ràng buộc bắt buộc tuân thủ

1. **RAM tối ưu** — Tổng 3 VM không vượt 12 GB (chừa 4 GB cho host Windows). Mỗi VM: 2 vCPU, 4 GB RAM tối đa.
2. **Tắt component nặng** — Alertmanager OFF, persistence OFF (dùng `emptyDir`), Prometheus retention = 2d.
3. **Không dùng PVC/StorageClass phức tạp** — `emptyDir` là đủ cho testbed.
4. **PowerShell syntax** cho mọi command chạy trên host Windows. Bash chỉ dùng bên trong VM.
