# Hợp đồng backend AI

Tài liệu này mô tả **API mà server phải hiện thực** để 4 tab AI trong app chạy được.
Phía app đã viết xong và có test: xem [`lib/data/ai/elira_ai_service.dart`](../lib/data/ai/elira_ai_service.dart).

## Vì sao phải có server, không gọi thẳng Replicate

Spec §25 và `CLAUDE.md` bắt buộc key của nhà cung cấp nằm **server-side**.
Lý do không phải là hình thức:

- APK là file công khai. Ai tải về cũng giải nén và đọc được chuỗi bên trong.
  Key nhúng trong app = key **đã bị công bố**, kể cả khi có obfuscate.
- `firestore.rules` (mục 1) đặt `credits` là **chỉ server ghi được**. Nếu client
  tự gọi Replicate thì không ai trừ credit cả — hoặc client tự trừ, mà client tự
  trừ được thì cũng tự **không** trừ được.
- Đổi nhà cung cấp (Replicate → cái khác) khi đó thành việc **đổi server**, không
  phải phát hành lại app và chờ người dùng cập nhật.

Vì vậy app chỉ biết địa chỉ server của chúng ta. Trong toàn bộ `lib/` không có
tên model, không có key, không có endpoint của Replicate hay remove.bg.

## Cấu hình phía app

```powershell
flutter build apk --flavor product --dart-define=ELIRA_AI_ENDPOINT=https://api.example.com
```

Không truyền `ELIRA_AI_ENDPOINT` thì `AiConfig.isConfigured == false`, app đăng ký
`FakeAiService(configured: false)` và mọi tab AI hiện thẳng trạng thái
"chưa kết nối" thay vì quay vòng rồi báo lỗi khó hiểu.

## Xác thực

Mọi request mang header:

```
Authorization: Bearer <Firebase ID token>
```

Server **phải** verify token bằng Firebase Admin SDK và lấy `uid` từ đó.
Không được tin bất kỳ `uid` nào do client gửi trong body.

## Endpoints

### `POST {base}/v1/jobs`

`multipart/form-data`:

| field | kiểu | ghi chú |
|---|---|---|
| `tool` | string | id trong `AiTools` — `ai_enhance`, `remove_bg`, `ai_retouch`, `remove_object`, `expand`, `replace`, `relight`, `restore`, `headshot`, `product` |
| `prompt` | string | chỉ với `expand` và `replace` |
| `image` | file | JPEG, app đã chặn > 12 MB trước khi gửi |

Trả `202`:

```json
{ "jobId": "j_abc123", "status": "queued", "credits": 4 }
```

**Trừ credit ngay tại đây**, trong cùng một transaction với việc nhận job.
Trừ sau khi model chạy xong nghĩa là ai ngắt mạng giữa chừng thì dùng miễn phí.

`credits` trả về là **số thực sự đã trừ**. App đọc lại con số này chứ không tự
tính, nên đổi giá là việc của server.

### `GET {base}/v1/jobs/{jobId}`

```json
{
  "status": "queued | running | succeeded | failed | cancelled",
  "progress": 0.42,
  "resultUrl": "https://...",
  "error": "insufficient_credits",
  "credits": 4
}
```

- `progress` **không bắt buộc**. Thiếu thì app hiện thanh tiến trình không xác
  định — thà vậy còn hơn một con số phần trăm giả rồi đứng im.
- `resultUrl` phải là **signed URL hết hạn ngắn** (spec §25), không phải URL
  công khai vĩnh viễn. Ảnh của người dùng không được để ai đoán link là xem được.
- `status: "succeeded"` mà thiếu `resultUrl` bị app coi là **lỗi server**, không
  phải thành công.

App poll mỗi 1.5s, bỏ cuộc sau 3 phút.

### `POST {base}/v1/jobs/{jobId}/cancel`

Trả `204`. Best-effort: job đã chạy quá xa thì server cứ tính tiền, app không
giả vờ là đã huỷ được.

## Mã lỗi

Ưu tiên `error` trong body; nếu không có thì app suy từ HTTP status.

| `error` | HTTP | Người dùng thấy |
|---|---|---|
| `insufficient_credits` | 402 | "You don't have enough credits for this." |
| `quota_exceeded` | 429 | "AI tools are busy right now. Try again shortly." |
| `unsupported_image` | 415 / 422 | "This photo could not be processed." |
| `too_large` | 413 | "This photo is too large to upload." |
| `unauthorized` | 401 / 403 | "Create a free account to use AI tools." |
| `timeout` | — | "That took too long. Please try again." |
| (khác) | 5xx | "Something went wrong on our side." |

Chuỗi lỗi thô của nhà cung cấp **không bao giờ** hiện cho người dùng — map nằm ở
`AppStrings.aiErrors`.

## Quy tắc nghiệp vụ server phải giữ

1. **Guest (anonymous auth) không được chạy AI trả phí.** App đã chặn ở client
   nhưng client không phải là ranh giới bảo mật — server chặn lại lần nữa.
2. Không train trên ảnh người dùng nếu chưa có đồng ý (spec §25).
3. Phải có đường xoá: Delete AI history / Delete account / Delete cloud projects
   (spec §25).
4. Ảnh nguồn và ảnh kết quả nên có TTL, không giữ vô thời hạn.

## Còn thiếu

- Luồng **mua credit**. Hiện hết credit thì app báo đúng tình trạng và dừng ở
  đó, vì chưa có store flow. Thuộc phần subscription/IAP.
