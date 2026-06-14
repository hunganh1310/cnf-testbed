# validate-on-save

Kiểm tra lại cấu hình hook tự động chạy validation khi file được chỉnh sửa.
Hook đã được cấu hình trong `.claude/settings.json` — skill này để kiểm tra và cập nhật nếu cần.

## Hook hiện tại

Hook `PostToolUse` (trigger: Edit hoặc Write) kiểm tra file_path trong JSON input và:

| File được sửa | Lệnh tự động chạy |
|---------------|-------------------|
| `Vagrantfile` | `vagrant validate` |
| `ansible/**/*.yml` | `ansible-lint .` (nếu đã cài) |

## Khi người dùng gọi skill này

1. Đọc `.claude/settings.json`
2. Hiển thị hooks hiện tại
3. Hỏi người dùng có muốn thêm hook mới không (ví dụ: helm lint, yamllint)
4. Nếu có, cập nhật `settings.json` — giữ nguyên mọi key hiện có, chỉ thêm vào mảng hooks

## Thêm hook mới — ví dụ mẫu

Nếu người dùng muốn thêm `yamllint` cho manifests:

```json
{
  "type": "command",
  "command": "input=$(cat); if echo \"$input\" | grep -q 'manifests' && echo \"$input\" | grep -q '\\.yaml'; then echo '--- [hook] yamllint ---'; command -v yamllint >/dev/null 2>&1 && yamllint . || echo '[SKIP] yamllint not installed'; fi",
  "timeout": 15000
}
```

Thêm object này vào mảng `hooks` của matcher `Edit|Write` trong `settings.json`.

## Cài ansible-lint (nếu chưa có)

Trên môi trường WSL hoặc Linux VM:
```bash
pip install ansible-lint
```

Trên Windows (nếu dùng WSL):
```bash
wsl pip install ansible-lint
```
