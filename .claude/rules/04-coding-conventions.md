---
description: Quy ước code, nguyên tắc viết YAML/Ansible/script và danh sách những điều tuyệt đối không được làm trong project này.
alwaysApply: true
---

## Quy ước và nguyên tắc

1. **Production-grade trên hết** — Không dùng workaround tạm bợ. Ưu tiên official Helm charts thay vì manual assembly YAML.
2. **KHÔNG để placeholder** như `<IP_ADDRESS>` trong file cuối — điền giá trị thật (node0 = `10.10.10.10`, node1 = `10.10.10.11`, node2 = `10.10.10.12`).
3. **Idempotent** — Ansible playbook phải chạy lại được nhiều lần không lỗi.
4. **Comment tiếng Việt** trong YAML/script — đây là lab học tập, comment giúp đọc hiểu.
5. **Symlink thay vì copy** khi cần sync version giữa file.
6. **Private registry preferred** nếu cần image custom.
7. **PowerShell** cho command trên host Windows, **bash** cho command bên trong VM.

## Tuyệt đối không được làm

- ❌ Không dùng kubeadm — chỉ dùng k3s
- ❌ Không bật Alertmanager hoặc persistence — vi phạm RAM limit
- ❌ Không để VM > 4 GB RAM mỗi node
- ❌ Không expose Grafana bằng LoadBalancer — dùng NodePort + SSH tunnel
- ❌ Không để placeholder chưa điền giá trị thật trong file cuối
- ❌ Không đoán mò khi debug — phải đọc `kubectl describe` / `kubectl logs` / events trước
