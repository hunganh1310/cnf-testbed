# Hình ảnh cho báo cáo

Đặt các file ảnh sau vào thư mục này (tên phải khớp `\includegraphics` trong các section):

| File | Nội dung | Cách lấy |
|------|----------|----------|
| `hust_logo.jpg` | Logo HUST | Dùng lại `OIP.jpg` từ project trước |
| `etsi_nfv_arch.png` | Sơ đồ kiến trúc ETSI NFV + ánh xạ | Vẽ draw.io, export PNG 300 dpi |
| `cluster_topo.png` | Sơ đồ 3 node + 2 mạng | Vẽ draw.io |
| `grafana_overview.png` | Dashboard Grafana node overview | SSH tunnel → Share → PNG |
| `grafana_hpa.png` | Panel CPU/Replicas khi chạy TC-04 | Crop khi chạy TC-04 |
| `term_ping.png` | Output TC-01 ping | Screenshot terminal |
| `term_iperf3.png` | Output TC-02 iperf3 | Screenshot terminal |
| `term_kubectl_nodes.png` | `kubectl get nodes -o wide` | Screenshot terminal |

> Các section đã chèn sẵn `\includegraphics` cho `hust_logo.jpg`,
> `etsi_nfv_arch.png`, `cluster_topo.png`. Nếu chưa có ảnh, comment dòng
> `\includegraphics` tương ứng để biên dịch thử.
