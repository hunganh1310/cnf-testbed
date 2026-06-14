# CNF / NFVI Testbed — mini NFVI stack mô phỏng ETSI NFV trên k3s

Đồ án IT3943 (Project III) — HUST, Tô Hùng Anh (MSSV 20225164).

Dựng một **mini NFVI stack** mô phỏng kiến trúc ETSI NFV ở quy mô nhỏ bằng
công nghệ cloud-native (Kubernetes/k3s thay cho OpenStack), chạy local trên
một máy Windows 16 GB RAM.

## Kiến trúc

```
node0 (control-plane) 10.10.10.10 / 10.30.0.10   k3s server, kubectl, Helm
node1 (worker)        10.10.10.11 / 10.30.0.11   CNF workload
node2 (worker)        10.10.10.12 / 10.30.0.12   CNF workload
```

Ba lớp mạng tách biệt:

| Lớp | CIDR | Interface | CNI |
|-----|------|-----------|-----|
| Management | 10.10.10.0/24 | eth1 | VirtualBox intnet `mgmt-net` |
| K8s cluster | 10.42.0.0/16 | flannel.1 | Flannel (VXLAN) |
| Data-plane | 10.30.0.0/24 | eth2 → net1 | Multus + macvlan + Whereabouts |

## Yêu cầu host

- Windows 10/11, 16 GB RAM
- VirtualBox 7.x
- Vagrant 2.4.x
- (Tùy chọn) OpenSSH client cho SSH tunnel

## Cài đặt từ đầu

> Mọi lệnh chạy trong PowerShell tại thư mục `cnf-testbed`.

```powershell
# 0. (Một lần) đặt thư mục chứa VM nếu muốn — ví dụ D:\VB
#    Cần tạo sẵn và cấp quyền ghi.

# 1. Dựng 3 VM + 2 mạng nội bộ (eth1 mgmt, eth2 data)
vagrant up

# 2. Cài k3s server trên node0
vagrant ssh node0 -c "cd /vagrant/ansible && ANSIBLE_CONFIG=/vagrant/ansible/ansible.cfg ansible-playbook -i inventory.ini playbooks/k3s-master.yml"

# 3. Join node1, node2 làm worker
vagrant ssh node0 -c "cd /vagrant/ansible && ANSIBLE_CONFIG=/vagrant/ansible/ansible.cfg ansible-playbook -i inventory.ini playbooks/k3s-worker.yml"

# 4. Verify 3 node Ready
vagrant ssh node0 -c "kubectl get nodes -o wide"

# 5. Cài Multus + Whereabouts + tạo NAD net1
vagrant ssh node0 -c "cd /vagrant/ansible && ANSIBLE_CONFIG=/vagrant/ansible/ansible.cfg ansible-playbook -i inventory.ini playbooks/cni.yml"

# 6. Deploy CNF (namespace, deployment, service, hpa)
vagrant ssh node0 -c "kubectl apply -f /vagrant/manifests/cnf-demo/"

# 7. Cài monitoring (Prometheus + Grafana)
vagrant ssh node0 -c "cd /vagrant/ansible && ANSIBLE_CONFIG=/vagrant/ansible/ansible.cfg ansible-playbook -i inventory.ini playbooks/monitoring.yml"
```

> **Lưu ý quan trọng:** Ansible chạy **bên trong** node0 (không cần cài Ansible
> trên Windows). Vì `/vagrant` là synced folder world-writable nên phải truyền
> `ANSIBLE_CONFIG=/vagrant/ansible/ansible.cfg` rõ ràng.

## Truy cập Grafana (qua SSH tunnel)

Host Windows không có route vào mạng nội bộ → tunnel qua node0:

```powershell
ssh -L 3000:10.10.10.10:30030 vagrant@10.10.10.10 -N
# mở http://localhost:3000  (admin / admin)
```

## Kiểm thử

Xem [TESTING.md](TESTING.md) — hướng dẫn chi tiết 5 kịch bản TC-01…TC-05.
Chạy nhanh:

```powershell
vagrant ssh node0 -c "bash /vagrant/tests/selftest.sh tc01"   # multi-NIC
vagrant ssh node0 -c "bash /vagrant/tests/selftest.sh tc02"   # iperf3
vagrant ssh node0 -c "bash /vagrant/tests/selftest.sh tc03"   # load balancing
vagrant ssh node0 -c "bash /vagrant/tests/selftest.sh tc04"   # HPA
vagrant ssh node0 -c "bash /vagrant/tests/selftest.sh tc05"   # observability
```

## Ánh xạ ETSI NFV → testbed

| Khối ETSI | Tương đương |
|-----------|-------------|
| NFVI | VirtualBox VMs (node0/1/2) |
| VIM | k3s API server + scheduler |
| VNF/CNF | Pods trong namespace `cnf-demo` |
| VNFM | Helm |
| NFVO | kubectl / GitOps (manual) |

## Cấu trúc thư mục

Xem `report/sections/08_appendix.tex` hoặc rule `.claude/rules/05-directory-structure.md`.

## Dọn dẹp

```powershell
vagrant destroy -f
```
