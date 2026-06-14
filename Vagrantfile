# Vagrantfile — CNF/NFVI Testbed
# Đồ án IT3943 — HUST, Tô Hùng Anh (MSSV 20225164)
#
# Kiến trúc: 3 VM (node0 control-plane, node1/2 worker)
# Mỗi VM: 2 vCPU, 4 GB RAM → tổng 12 GB ≤ giới hạn 16 GB host
# Mạng:
#   eth1 → mgmt-net (10.10.10.0/24)   — management plane
#   eth2 → data-net (10.30.0.0/24)    — data plane (Multus + macvlan)

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-22.04"

  # Tắt auto-update box để tránh download không mong muốn
  config.vm.box_check_update = false

  # Cấu hình chung cho VirtualBox provider
  config.vm.provider "virtualbox" do |vb|
    vb.cpus   = 2
    vb.memory = 4096
    # Tắt audio và USB để nhẹ hơn
    vb.customize ["modifyvm", :id, "--audio", "none"]
    vb.customize ["modifyvm", :id, "--usb", "off"]
    # BẮT BUỘC cho macvlan trên data-net (nic3 = eth2): cho phép NIC nhận frame
    # gửi tới MAC con của macvlan. Thiếu dòng này → ping qua net1 "Host Unreachable".
    vb.customize ["modifyvm", :id, "--nicpromisc3", "allow-all"]
  end

  # ─────────────────────────────────────────────
  # node0 — control-plane (k3s server)
  # ─────────────────────────────────────────────
  config.vm.define "node0" do |node|
    node.vm.hostname = "node0"

    # eth1 — management network
    node.vm.network "private_network",
      ip: "10.10.10.10",
      virtualbox__intnet: "mgmt-net"

    # eth2 — data-plane network
    node.vm.network "private_network",
      ip: "10.30.0.10",
      virtualbox__intnet: "data-net"

    node.vm.provider "virtualbox" do |vb|
      vb.name = "cnf-node0"
    end

    # Chạy script khởi tạo cơ bản (common cho mọi node)
    node.vm.provision "shell", path: "scripts/bootstrap.sh"
  end

  # ─────────────────────────────────────────────
  # node1 — worker
  # ─────────────────────────────────────────────
  config.vm.define "node1" do |node|
    node.vm.hostname = "node1"

    node.vm.network "private_network",
      ip: "10.10.10.11",
      virtualbox__intnet: "mgmt-net"

    node.vm.network "private_network",
      ip: "10.30.0.11",
      virtualbox__intnet: "data-net"

    node.vm.provider "virtualbox" do |vb|
      vb.name = "cnf-node1"
    end

    node.vm.provision "shell", path: "scripts/bootstrap.sh"
  end

  # ─────────────────────────────────────────────
  # node2 — worker
  # ─────────────────────────────────────────────
  config.vm.define "node2" do |node|
    node.vm.hostname = "node2"

    node.vm.network "private_network",
      ip: "10.10.10.12",
      virtualbox__intnet: "mgmt-net"

    node.vm.network "private_network",
      ip: "10.30.0.12",
      virtualbox__intnet: "data-net"

    node.vm.provider "virtualbox" do |vb|
      vb.name = "cnf-node2"
    end

    node.vm.provision "shell", path: "scripts/bootstrap.sh"
  end
end
