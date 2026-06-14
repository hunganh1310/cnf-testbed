# set-env

Cấu hình biến môi trường cho dự án CNF testbed trong `.claude/settings.json`.

## Khi người dùng gọi skill này

Hỏi người dùng muốn set biến gì, sau đó cập nhật `settings.json` — thêm vào key `env` ở root level.

## Biến môi trường thường dùng trong project này

| Biến | Giá trị gợi ý | Mục đích |
|------|---------------|----------|
| `KUBECONFIG` | `/home/vagrant/.kube/config` | kubectl trỏ đúng cluster k3s |
| `VAGRANT_DEFAULT_PROVIDER` | `virtualbox` | Không cần gõ `--provider` |
| `ANSIBLE_HOST_KEY_CHECKING` | `False` | Bỏ qua SSH host key check khi provision |
| `ANSIBLE_INVENTORY` | `ansible/inventory.ini` | Chạy ansible-playbook không cần `-i` |

## Format trong settings.json

```json
{
  "env": {
    "VAGRANT_DEFAULT_PROVIDER": "virtualbox",
    "ANSIBLE_HOST_KEY_CHECKING": "False",
    "ANSIBLE_INVENTORY": "ansible/inventory.ini"
  }
}
```

## Cách thực hiện

1. Đọc `.claude/settings.json` hiện tại
2. Thêm hoặc cập nhật key `env` ở root level
3. Không xoá bất kỳ key nào đang có
4. Ghi lại file

## Lưu ý

- `KUBECONFIG` chỉ hữu ích nếu kubectl chạy trực tiếp từ host — với project này kubectl chạy trong VM node0, nên không cần set trên host.
- Với Windows host, set `VAGRANT_DEFAULT_PROVIDER=virtualbox` trong PowerShell profile sẽ hiệu quả hơn.
