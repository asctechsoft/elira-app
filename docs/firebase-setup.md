# Thiết lập Firebase (giai đoạn 1 — Auth)

App **chạy được mà không cần làm gì trong tài liệu này**. Khi `Firebase.initializeApp()`
thất bại, `ServiceLocator` tự rơi về một stack auth chạy trong bộ nhớ, nên toàn bộ
luồng đăng ký / đăng nhập / khách / hồ sơ vẫn bấm thử được. Những bước dưới đây là
thứ biến nó thành tài khoản thật, lưu bền.

Không file nào ở đây được commit — `.gitignore` đã loại `google-services.json` và
`GoogleService-Info.plist` ở mọi cấp thư mục.

---

## 1. Tạo project trên Firebase Console

1. Tạo project tên **`elira-ai`**.
2. **Authentication → Sign-in method** → bật **Email/Password** và **Anonymous**.
   Giữ nguyên **Email Enumeration Protection** đang bật (xem mục Ghi chú cuối bài).
3. **Firestore Database** → tạo ở chế độ **Native mode**.

> Bật Anonymous là bắt buộc: nút "Skip" ở màn onboarding đăng nhập ẩn danh chứ
> không bỏ qua auth. Nhờ vậy khách vẫn có `uid` thật, credits/stats nằm cùng một
> đường `/users/{uid}` như mọi user khác, và khi họ đăng ký thì tài khoản được
> **link tại chỗ, giữ nguyên uid** — không mất dữ liệu, không phải viết code migrate.

---

## 2. Đăng ký app

Android gắn thêm hậu tố theo flavor, nên **3 flavor là 3 app Android khác nhau** —
plugin `google-services` so khớp `package_name` với `applicationId` **cuối cùng**,
không có đường tắt dùng chung một file. iOS không có flavor (chỉ Debug/Release/Profile
và một scheme duy nhất) nên chỉ cần đăng ký một lần.

| Đăng ký app | File config đặt vào |
|---|---|
| `com.asc.elira.dev` | `android/app/src/dev/google-services.json` |
| `com.asc.elira.alpha` | `android/app/src/alpha/google-services.json` |
| `com.asc.elira` | `android/app/src/product/google-services.json` |
| iOS `com.asc.elira` | `ios/Runner/GoogleService-Info.plist` |

**Vì sao tách file theo flavor thay vì gộp một file `android/app/google-services.json`?**
File gộp cũng chạy, nhưng nó đưa app-id production vào mọi bản dev. Và sau này khi
muốn tách production sang một Firebase project riêng (việc chắc chắn sẽ xảy ra trước
khi lên store), tách sẵn thì chỉ cần thay một file, còn gộp thì phải đấu lại từ đầu.

Có thể tải file từ Console, hoặc sinh bằng CLI:

```powershell
dart pub global activate flutterfire_cli
npm install -g firebase-tools
firebase login

flutterfire configure --project=elira-ai --platforms=android --android-package-name=com.asc.elira.dev
flutterfire configure --project=elira-ai --platforms=android --android-package-name=com.asc.elira.alpha
flutterfire configure --project=elira-ai --platforms=android,ios --android-package-name=com.asc.elira --ios-bundle-id=com.asc.elira
```

Chạy `flutterfire configure --help` trước để xem tên cờ chỉ định đường ra ở phiên bản
CLI bạn đang dùng — các cờ này đổi tên qua nhiều bản. Nếu bản hiện tại không có, cứ
để nó ghi ra vị trí mặc định rồi **chuyển file bằng tay** vào đúng `src/<flavor>/`.
Chỉ vị trí cuối cùng mới quan trọng.

App gọi `Firebase.initializeApp()` **không truyền options**, nên file config native
là nguồn sự thật duy nhất và **không cần** file `firebase_options*.dart` sinh tự động.

---

## 3. Gradle — đã đấu sẵn

Đã xong trong `android/app/build.gradle.kts`. Plugin `com.google.gms.google-services`
được apply **có điều kiện**, vì nó làm **fail build ngay** khi không tìm thấy file
config — như vậy sẽ chặn mọi người chưa được cấp quyền vào Firebase Console.

Thả một `google-services.json` vào bất kỳ thư mục `src/<flavor>/` nào là nó tự kích
hoạt ở lần build kế tiếp. Build khi chưa có file nào sẽ in ra:

```
[elira] No google-services.json found - Firebase Android wiring is inactive.
```

---

## 4. Deploy security rules

```powershell
firebase deploy --only firestore:rules
```

`firestore.rules` là **file quan trọng nhất của giai đoạn này**. Nó ghim số credit
tặng lúc đăng ký ngay tại thời điểm tạo document, và biến `credits`, `subscription`,
`stats` thành **chỉ server được ghi** sau đó — client không bao giờ sửa được.

Bỏ qua bước này thì Firestore hoặc mở toang ở test mode, hoặc khoá chặt. Tệ hơn:
**test mode hết hạn sau 30 ngày**, và một tháng nữa nó sẽ biểu hiện thành một lỗi
toàn app không rõ nguyên nhân.

---

## 5. Kiểm chứng

```powershell
flutter run --flavor dev -d <device>
flutter build apk --release --flavor product
```

Lệnh thứ hai quan trọng: **đường release là nơi lỗi thiếu quyền INTERNET ẩn nấp**
(bản debug vẫn chạy bình thường vì Flutter tự thêm quyền đó cho `src/debug`).

Lưu ý: từ khi dự án có product flavor, **`flutter run` trần sẽ fail** — mọi lệnh
đều phải kèm `--flavor`.

Các ca cold-start nên thử trên máy thật:

| # | Thao tác | Kỳ vọng |
|---|---|---|
| 1 | Đăng nhập → force-stop → mở lại | Vào thẳng `/main`, **không thấy frame onboarding** (đây là bài test flicker) |
| 2 | Như trên nhưng bật chế độ máy bay | Vẫn `/main`, stats lấy từ cache, **không treo** |
| 3 | Cài mới + chế độ máy bay | Splash hiện nút Retry, **không phải màn trắng** |
| 4 | Skip (khách) → đăng ký | **Cùng một uid** trên Console, không phải tài khoản thứ hai |
| 5 | Đăng xuất → đăng nhập lại | `credits.balance` **không đổi** và `createdAt` giữ nguyên (chứng minh `ensureCreated` không tặng credit lại) |
| 6 | Đăng xuất | Về `/onboarding`, nút Back Android không làm gì |
| 7 | Deep link `/editor` khi chưa đăng nhập | Bị đá về `/onboarding` |

Ca 2 và 5 là hai ca hay bị bỏ sót nhất và cũng là hai ca hay hỏng nhất.

---

## Ghi chú — ba quyết định cố ý khác với `TODO.md`

**1. Sai mật khẩu và email không tồn tại hiện CÙNG một thông báo.**
Khi bật Email Enumeration Protection, Firebase trả `invalid-credential` cho cả hai
trường hợp. Phân biệt chúng ra chính là lỗ hổng account-enumeration mà cơ chế bảo vệ
này sinh ra để bịt. `TODO.md` yêu cầu tách riêng thông báo — yêu cầu đó vừa không
làm được, vừa không nên làm. Đừng tắt protection để "sửa".

**2. Google Sign-In cố ý để ngoài giai đoạn 1.**
Nó cần SHA-1 đăng ký riêng cho từng `applicationId` (tức 3 flavor), trong khi
`release` hiện đang ký bằng **debug key**. Mọi SHA-1 đăng ký bây giờ sẽ sai vào đúng
ngày dự án có keystore thật. Làm sau khi cấu hình ký đã chuẩn.

**3. Upload avatar để ngoài giai đoạn 1.**
Cần `firebase_storage` (chưa có trong pubspec) cộng luồng pick → crop → nén → upload
và file Storage rules riêng. Hiện màn Profile hiển thị chữ cái đầu sinh tự động, đủ
dùng và không tốn gì.
