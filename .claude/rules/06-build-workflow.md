---
description: Thứ tự build toàn bộ testbed từ đầu — từ Vagrant lên đến test iperf3. Tham chiếu khi setup lần đầu hoặc rebuild cluster.
---

## Thứ tự build đề xuất

```
1.  Vagrantfile → vagrant up → verify eth1 (10.10.10.x) và eth2 (10.30.0.x)
2.  Ansible: k3s-master.yml → cài k3s server trên node0
3.  Ansible: k3s-worker.yml → join node1 và node2
4.  Verify: kubectl get nodes → 3 node trạng thái Ready
5.  Ansible: cni.yml → cài Multus + Whereabouts → tạo NAD (net1, VLAN 30)
6.  Kubectl apply manifests/cnf-demo/ → verify pod có IP net1 (10.30.0.x)
7.  Test Service + load balancing (ClusterIP)
8.  Ansible: monitoring.yml → Helm deploy kube-prometheus-stack
9.  SSH tunnel từ Windows → truy cập Grafana tại http://localhost:3000
10. Test TC-04: HPA auto-scaling
11. Test TC-02: iperf3 data-plane throughput (VLAN 30)
```

## Lệnh SSH tunnel (PowerShell — chạy trên host Windows)

`mgmt-net` là VirtualBox **intnet** → host Windows KHÔNG có route tới `10.10.10.10`.
Phải tunnel qua NAT của Vagrant; endpoint `localhost:30030` được resolve TRONG node0
(Grafana NodePort = 30030).

```powershell
vagrant ssh node0 -- -N -L 3000:localhost:30030
```

Sau đó mở browser tại `http://localhost:3000` (admin / admin).

## Verify nhanh sau mỗi bước

| Bước | Lệnh verify |
|------|-------------|
| 1 | `vagrant status` |
| 3 | `kubectl get nodes -o wide` |
| 5 | `kubectl get net-attach-def -A` |
| 6 | `kubectl exec -n cnf-demo <pod> -- ip addr show net1` |
| 8 | `kubectl get pods -n monitoring` |
| 9 | Browser → Grafana → Dashboards |
