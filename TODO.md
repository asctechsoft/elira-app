# Elira — TODO & Roadmap

> Cập nhật: 2026-09-24  
> Trạng thái: **Mục 1 (Firebase & Auth), 2 (Photo Picker), 3 (Editor Core) đã thi công.** Các mục 4–10 vẫn là UI mockup (riêng Adjust Panel ở mục 4 đã xong 2/3 ý).
>
> Chi tiết cấu hình Firebase: [docs/firebase-setup.md](docs/firebase-setup.md)

---

## 0. Gỡ blocker build (không có trong bản TODO gốc — đã xong)

Dự án trước đó **không build được**. Đã sửa:

- [x] `environment: sdk: ^3.13.3` → `^3.10.0` (Dart trên máy là 3.10.8 → `pub get` fail ngay)
- [x] Bỏ khai báo `assets/images/svg/` (thư mục không tồn tại → lỗi asset)
- [x] Thêm quyền `INTERNET` vào AndroidManifest chính (trước đó chỉ có ở `src/debug` và `src/profile` ⇒ **bản release chết mọi call mạng trong im lặng**)
- [x] `android:label` dùng `@string/app_name` thay vì hardcode `"elira"` (đang vô hiệu hóa resValue của 3 flavor)
- [x] Pin `minSdk = 24` (firebase_auth cần ≥ 23)
- [x] Thêm `NSPhotoLibraryUsageDescription` / `NSCameraUsageDescription` / `NSPhotoLibraryAddUsageDescription` (thiếu hoàn toàn ⇒ `photo_manager` crash app iOS)
- [x] Xóa `.gitmodules` (khai báo submodule `dsp_base` nhưng không có gitlink lẫn thư mục)
- [x] Thêm `android/local.properties` + đưa vào `.gitignore`
- [x] Sửa `PrimaryButton`: `isLoading` không làm nút đổi sang trạng thái disabled ⇒ nút đang chạy vẫn trông bấm được
- [x] Apply plugin `org.jetbrains.kotlin.android` (file có khối `kotlin { compilerOptions }` nhưng chưa bao giờ apply plugin ⇒ `Unresolved reference`)
- [x] Hạ `org.gradle.jvmargs` từ `-Xmx8G -XX:MaxMetaspaceSize=4G` xuống `-Xmx2G` (xin nhiều hơn RAM vật lý ⇒ Gradle daemon crash)
- [x] `kotlin.incremental=false` (mọi module plugin Kotlin fail *Could not close incremental caches*)
- [x] Tạo `android/app/proguard-rules.pro` (AGP 9 bật R8 mặc định cho release, thiếu file ⇒ build release fail)

**Đã verify bằng build thật:** `--debug --flavor dev` và `--release --flavor product` đều xanh; `aapt dump` xác nhận APK release **có** quyền INTERNET, `applicationId` đúng theo flavor và label lấy từ `@string/app_name` (`ASC Photo AI` / `Elira Dev`).

> Môi trường build (JDK 21 + Android SDK, và cảnh báo Kaspersky phá toolchain): [docs/dev-setup.md](docs/dev-setup.md)

---

## Tổng quan ưu tiên

| # | Nhóm | Ảnh hưởng | Ước lượng |
|---|------|-----------|-----------|
| 1 | Firebase Auth flow | Blocker toàn app | 2–3 ngày |
| 2 | Image processing (adjust/crop) | Core editor | 3–5 ngày |
| 3 | Export thật ra gallery | Hoàn thiện editor | 1 ngày |
| 4 | AI API integration | Feature chính | 3–5 ngày |
| 5 | Filters / Effects / Retouch | UX editor | 3–4 ngày |
| 6 | Database (sqflite + Firestore) | Persistence | 2–3 ngày |
| 7 | Profile + Settings thật | Polish | 1–2 ngày |

---

## 1. Firebase & Auth

### Màn: `main.dart`
- [x] Gọi `Firebase.initializeApp()` trước `runApp()`
- [x] Thêm `google-services.json` Android cho 3 flavor (dev/alpha/product) — project `elira-ai`, gitignored
- [ ] Thêm `GoogleService-Info.plist` (iOS) + add vào target Runner trong Xcode
- [x] Deploy `firestore.rules`: `firebase deploy --only firestore:rules` (đã có `firebase.json` + `.firebaserc`)

### Màn: Splash (`screen_splash/splash_screen.dart`)
- [x] Check `FirebaseAuth.instance.currentUser` thay vì hardcode delay 3s
  - Nếu đã login → route `/main`
  - Nếu chưa → route `/onboarding`
- [x] Xử lý Firebase loading state (tránh flicker)

### Màn: Onboarding (`screen_onboarding/onboarding_screen.dart`)
- [x] Tạo `AuthController` (hoặc mở rộng `OnboardingController`)
- [x] Nút "Get Started" → màn Signup/Login (chưa có màn này, cần tạo)
- [x] Nút "Skip" → route `/main` chỉ khi đã có anonymous auth hoặc bỏ skip
- [x] Firebase Anonymous Auth (optional — cho phép dùng thử không login)

### Màn: Signup / Login (ĐÃ TẠO)
- [x] Tạo `screen_auth/` với 2 sub-screen: `login_screen.dart`, `signup_screen.dart`
- [x] Tạo `AuthController`:
  - [x] `signInWithEmail(email, password)`
  - [x] `signUpWithEmail(email, password, name)`
  - [ ] `signInWithGoogle()` (optional — hoãn, xem docs/firebase-setup.md)
  - [x] `signOut()`
  - [x] `resetPassword(email)`
- [x] Validate form (email format, password min 6 ký tự)
- [x] Xử lý error từ Firebase (wrong-password, user-not-found, email-in-use)
- [x] Sau signup → tạo user document trong Firestore `/users/{uid}`
- [x] Persist session — dùng `authStateChanges().first` (không dùng `currentUser`, vốn là race lúc cold start và chính là nguyên nhân flicker). Ma trận cold-start cần chạy trên máy thật: xem docs/firebase-setup.md

### Màn: Profile (`screen_profile/profile_screen.dart`)
- [x] Load user từ `FirebaseAuth.instance.currentUser` (displayName, email, photoURL)
- [x] Load stats từ Firestore `/users/{uid}` (projects count, favorites count, credits)
- [x] Nút "Edit Profile" → update displayName, avatar
- [x] Nút "Sign Out" → `AuthController.signOut()` → route `/onboarding`
- [x] Xóa hardcode "Emma Carter", 128, 56, 2850, `isPro = true`

---

## 2. Photo Picker (`screen_photo_picker/`) — ĐÃ THI CÔNG

### Controller: `PhotoPickerController`
- [x] Chọn ảnh xong → tạo draft `EditProject` → route `/editor` với arguments đúng
- [x] Camera capture (xin quyền `Permission.camera` trước, vì manifest có khai báo CAMERA nên Android bắt buộc runtime grant)
- [x] Permission denied state (icon + giải thích + nút "Open Settings" + nút "I have enabled it" để load lại)
- [x] Thêm trạng thái **limited access** (iOS "Selected Photos" / Android 14 partial) — grid chạy nhưng chỉ thấy ảnh đã chia sẻ, có nút "Manage" để mở rộng. `TODO.md` không nhắc nhưng spec §30 yêu cầu
- [x] Tab **Albums** hoạt động thật (trước đây `activeTab` đổi nhưng grid không đổi gì)
- [x] **Phân trang** (trước đây hard cap đúng 120 ảnh, ảnh thứ 121 trở đi biến mất trong im lặng)

### Việc phát sinh — dây bị đứt giữa Home và Editor
- [x] Home gửi `Get.toNamed(photoPicker, arguments: {'tool': qa.id})` nhưng picker **vứt đi**, nên bấm "Remove" hay "Edit Photo" đều vào cùng một tab mặc định. Nay `initialTool` đi theo `EditProject` sang editor và mở đúng tool

### Model + service mới
- [x] `EditProject` reshape lại (trước đó khai báo rồi **không ai dùng**): thêm `originalPath`, `sourceAssetId`, `thumbnailPath`, `editedPath`, `width/height`, `createdAt`, `initialTool`, `adjustments` + `toMap`/`fromMap` — tên cột khớp sẵn bảng `projects` ở mục 9
- [x] `ProjectDraftService`: **copy** ảnh gốc vào `<app-docs>/projects/<id>/original.<ext>` rồi sinh thumbnail. Không bao giờ sửa ảnh gốc (spec §6), và không trỏ thẳng vào `AssetEntity.file` vì đó là cache do OS quản lý, có thể bị xoá giữa lúc đang sửa
- [x] Cảnh báo ảnh quá nhỏ cho AI enhance (spec §6) + hiển thị độ phân giải ảnh đã chọn
- [x] `EditorController` nhận `EditProject` qua `Get.arguments` (vẫn chấp nhận `String` path để deep link/test cũ không gãy); top bar bỏ hardcode "Portrait Edit" / "Saved 2 min ago"

**Chưa làm ở mục này (thuộc mục khác):** lưu draft xuống sqflite là **mục 9**; `EditProject` hiện sống trong bộ nhớ nhưng đã có sẵn serialization để mục 9 cắm vào. Multi-select cho collage thuộc mục 8.

**Verify:** `analyze` 0 issue · `test` 53/53 pass (thêm `edit_project_test.dart`, `editor_controller_test.dart`) · `build apk --debug --flavor dev` xanh.

---

## 3. Editor — Core (`screen_editor/editor_screen.dart`) — ĐÃ THI CÔNG

### Controller: `EditorController`
- [x] **Undo/Redo stack** — chọn **command pattern**, không phải `List<ImageState>`: history là con trỏ trên danh sách operation nên bộ nhớ phẳng dù stack sâu bao nhiêu, và undo không phụ thuộc file đã render (spec §18)
- [x] `canUndo` / `canRedo` cập nhật đúng sau mọi thao tác
- [x] **Apply adjustments thật**: brightness, contrast, saturation, sharpness
- [x] Debounce khi kéo slider — hạ 300ms → **150ms**, và nay chỉ áp cho sharpness (3 slider màu không còn render CPU, xem bên dưới)
- [x] Load ảnh gốc từ path và giữ bản gốc để reset/undo

### UI
- [x] Version strip bind vào history thật (entry 0 = Original, mỗi entry có thumbnail + nhãn, bấm để nhảy tới mốc đó)
- [x] Hiển thị ảnh đã processed (`Image.memory` + `gaplessPlayback` để không nháy canvas khi render)
- [x] **Preview màu realtime trên GPU**: brightness/contrast/saturation gộp thành 1 ma trận màu 4×5, canvas áp bằng `ColorFiltered` ngay trong frame — kéo slider hay bấm liên tục version chip không còn chờ render
- [x] AdjustPanel có đủ **4 slider** (trước đây chỉ Brightness, còn contrast/saturation/sharpness là observable không có UI)

### Khác với TODO một chút, có lý do
- **Không dùng `ui.Image`** như TODO đề xuất. Pipeline làm việc trên bytes + `img.Image` của package `image` vì `ui.Image` không đi qua được ranh giới isolate. Toàn bộ pixel work chạy trong `Isolate.run` nên không kẹt UI thread (spec §26: 60 FPS khi kéo slider)
- **Preview render ở 1440px**, không phải full-res. Spec §7/§23 yêu cầu rõ: chỉ export mới replay stack ở full resolution. Render lại ảnh 48MP mỗi tick slider chính là thứ làm editor rớt frame
- **Gộp history theo control**: kéo slider Brightness 200 lần vẫn chỉ ra **1 entry**, undo một phát về sạch. Đổi sang control khác mới tạo entry mới
- **Chia pipeline làm 2 tầng**: sharpness (tích chập, bắt buộc CPU) chạy trước, rồi tới ma trận màu. Canvas làm tầng 1 trên CPU và tầng 2 trên GPU; export chạy cả hai trên CPU bằng **cùng một ma trận** (`ImagePipeline.colorMatrix`) nên ảnh xuất khớp với preview
- **Saturation đổi công thức**: từ HSV của package `image` (không biểu diễn được bằng ma trận) sang saturation theo luma Rec. 709. Hướng tác dụng giữ nguyên, sắc độ ở mức cực đại hơi khác trước
- **Render sharpness tuần tự, không song song**: chỉ 1 isolate tại một thời điểm, burst thao tác nhanh chỉ render giá trị cuối (thay cho cơ chế token cũ, vốn vẫn để N isolate chạy tranh CPU). Kết quả cache theo giá trị sharpness (tối đa 6), quay lại version cũ hiện ngay

### Lỗi thật phát hiện khi viết test / chạy máy thật
- [x] **Màn Editor crash đỏ** "improper use of GetX" ngay khi chọn ảnh: `Obx(() => _Canvas(...))` / `Obx(() => _VersionStrip(...))` chỉ dựng widget, `.value` đọc trong `build()` con nằm ngoài scope của `Obx`. Đã chuyển `Obx` vào trong `build()`; thêm widget test dựng `EditorScreen`
- [x] **Race khi load 2 lần**: lần load về muộn đè kết quả lần mới hơn. Nay có load token
- [x] `img.decodeImage` **ném RangeError** với file hỏng thay vì trả `null` (probe format PSD đọc quá biên). Chưa bọc thì người dùng gặp crash thay vì thông báo — spec §30 yêu cầu có state "ảnh hỏng/không hỗ trợ"

### Chưa làm ở mục này (thuộc mục khác)
Nút **Auto** của AdjustPanel, filters/effects/crop/retouch là **mục 4**. Export replay stack ở full-res là **mục 6**. Lưu `adjustments` xuống DB là **mục 9** (`EditOperation.toMap` đã sẵn sàng).

**Verify:** `analyze` 0 issue · `test` **92/92 pass** · `build apk --debug --flavor dev` xanh (trước bản sửa GPU; bản sửa GPU mới verify bằng analyze + test, cần chạy lại trên máy thật).
Test mới: `edit_stack_test.dart` (undo/redo/jumpTo/discard redo tail), `image_pipeline_test.dart` (đo luminance/saturation/contrast thật trên ảnh sinh ra), `editor_controller_test.dart` (chạy pipeline thật trên file thật, có ca **khẳng định file gốc trên đĩa không bị sửa**).

---

## 4. Editor — Tool Panels — ĐÃ THI CÔNG

### Nền tảng: `EditState` chia lát, pipeline 3 tầng
- [x] `EditState` tách thành 4 lát độc lập: `adjust` · `filter` · `effects` · `geometry` (+ `texts`). Mỗi operation **chỉ thay lát của nó** — chọn filter không còn xoá mất crop đã làm 3 bước trước
- [x] Pipeline chạy đúng thứ tự: **geometry** (xoay/lật/cắt) → **spatial** (sharpness, blur, glow, vignette, grain) → **màu** (1 ma trận 4×5)
- [x] `spatialKey`: khoá cache của tầng CPU. Slider màu và filter **không** làm đổi khoá này, nên không kích hoạt render lại lần nào
- [x] Bán kính hiệu ứng **scale theo độ phân giải** — cùng giá trị slider cho ra cùng cảm giác trên preview 1440px và trên bản export 6000px

### Adjust Panel
- [x] Nút **Auto** thật: đọc histogram của chính tấm ảnh (phân vị 0.5%/99.5%, không phải min/max — 1 điểm cháy sáng không được quyết định cả bức)
- [x] Auto **đẩy giá trị lên slider** rồi commit như mọi thao tác khác → người dùng thấy nó làm gì và chỉnh tiếp được; undo được
- [x] Reset từng slider + "Reset all"
- [x] Chip control có chấm báo khi giá trị khác 0 (thấy được cả khi đang ở tab khác)

### Filters Panel
- [x] 9 preset: Original, Cinematic, Vibrant, Aesthetic, Golden Hour, B&W, Fade, Warm, Cool
- [x] **Mỗi filter là một ma trận màu**, gộp chung với ma trận Adjust → chọn filter tốn **0 pixel work**
- [x] Thumbnail là **ảnh của chính người dùng**, không phải ảnh mẫu — và cả dải dùng chung **1 lần render nhỏ** (mỗi ô chỉ khác nhau ở ColorFilter trên GPU)
- [x] Slider **Strength** 0–100, nội suy tuyến tính trong không gian ma trận nên 50% đúng là một nửa
- [x] Thumbnail tự cập nhật theo crop / effect / adjust hiện tại

### Effects Panel
- [x] Vignette, Blur, Grain, Glow — mỗi cái **giữ giá trị riêng và cộng dồn**, không phải chọn một trong các lựa chọn
- [x] Mỗi effect có slider cường độ riêng + "Clear all"
- [x] Grain chạy **cuối cùng** để không bị các tầng trên làm nhoè
- [x] Chip "Sharpen" trong Effects sửa **đúng tham số sharpness của tab Adjust** — một tham số, hai đường vào, không thể lệch nhau

### Crop Panel
- [x] Overlay crop thật trên canvas: kéo 4 góc, kéo cả khung, lưới 1/3, làm tối vùng ngoài
- [x] Preset tỉ lệ Free / 1:1 / 4:3 / 16:9 / 3:4 / 9:16, và tỉ lệ được **giữ trong lúc kéo góc**, không chỉ lúc bấm
- [x] Rotate 90° / Flip H / Flip V, mỗi cái là 1 bước undo riêng
- [x] Confirm crop → commit vào stack; rời tab mà không Apply thì **huỷ khung**, không commit
- [x] **Không dùng `image_cropper`**: package đó mở một màn native riêng, làm đứt mạch non-destructive (nó trả về file đã cắt, còn ở đây crop phải là một operation replay được)

### Text Panel
- [x] `TextLayer`: nội dung, font, màu, canh lề, vị trí, cỡ chữ
- [x] Add Text (dialog) · kéo thả trên ảnh · chọn layer để sửa · xoá layer
- [x] 5 font (Sans/Serif/Display/Script/Mono), 8 màu, canh trái/giữa/phải, slider cỡ chữ
- [x] Text nằm **trên** `ColorFiltered` của canvas → filter không nhuộm màu chữ; và text không thuộc tầng render nào nên thêm chữ tốn **0 render**
- [x] Vị trí/cỡ chữ lưu **chuẩn hoá theo ảnh hiển thị** (giống crop) → khớp giữa preview và export
- [x] Layer bị xoá trắng nội dung thì **bị loại bỏ**, không để lại layer vô hình không bấm lại được

### Chuyển sang mục 5 — có lý do, không phải bỏ sót
`Remove` · `Background` · `Retouch` · `AI panel` **cần API cloud** (Replicate / remove.bg, key phải nằm server-side theo spec §25). TODO cũng đã ghi rõ điều này cho Retouch và Background.
- [x] 4 panel này nay hiển thị **đúng chức năng sẽ có + trạng thái "chưa kết nối"**, thay vì nút bấm không làm gì. Nút giả vờ chạy rồi báo thành công còn tệ hơn nút nói thật
- [ ] Đấu nối thật (gồm `AiStudioController.runTool`, trừ credit, progress overlay, nạp ảnh kết quả) — **mục 5**

Ghi chú nợ: `AiStudioController` hiện vẫn `credits = 120` hardcode, mâu thuẫn với credit thật trong Firestore (mục 1 đặt 30). Sửa ở mục 5.

### Chưa làm ở mục này (thuộc mục khác)
Render text và replay stack ở full-res khi **export** là **mục 6** (text phải composite bằng `TextPainter` trên main isolate, `dart:ui` không qua được ranh giới isolate). Lưu `EditState` xuống DB là **mục 9** — `EditState.toMap()` đã bao gồm cả 5 lát.

**Verify:** `analyze` 0 issue · `test` **199/199 pass** (từ 92) · `build apk --debug --flavor dev` xanh.
Test mới: `color_matrix_test.dart` (thứ tự compose, lerp), `photo_filters_test.dart` (mỗi preset làm đúng tên của nó), `edit_state_test.dart` (lát độc lập, `spatialKey`, xoay có mang theo khung crop), `image_pipeline_stages_test.dart` (geometry/effects/auto đo trên pixel thật), `editor_controller_tools_test.dart` (có ca **khẳng định slider màu và filter không đụng tới base đã cache**), `text_layer_test.dart`.

### Lỗi thật phát hiện khi viết test
- [x] **Auto làm ảnh tối càng tối hơn.** Contrast xoay quanh mức xám giữa nên kéo mean xuống nhanh hơn khoảng brightness (±50%) kéo lên được. Nay Auto xin contrast tối đa rồi **lùi dần cho tới khi phơi sáng đạt** — ảnh đúng sáng quan trọng hơn ảnh đậm nét
- [x] **3 `Obx` không theo dõi gì cả** (Adjust/Effects/Crop): thân `Obx` chỉ dựng `ListView`, còn `.value` đọc trong `itemBuilder` — chạy *sau*, ngoài scope theo dõi. Cùng đúng cái bẫy đã gặp ở mục 3, lần này test `widget_test.dart` bắt được ngay

---

## 5. AI Studio (`screen_ai_studio/`) — ĐÃ THI CÔNG PHÍA APP

> **Chưa gọi được Replicate / remove.bg thật, vì chưa có backend.** Spec §25 và
> `CLAUDE.md` bắt key phải nằm server-side. APK là file công khai — key nhúng
> trong app là key đã bị công bố. Nên phần làm ở mục này là **toàn bộ nửa app
> của hợp đồng đó**, cộng một backend giả để cả luồng chạy và test được.
> Hợp đồng server: [`docs/ai-backend-contract.md`](docs/ai-backend-contract.md).

### Tầng data
- [x] `AiTool` + `AiTools`: 10 tool, mỗi tool có **giá credit**, tool nào cần prompt, độ phân giải tối thiểu
- [x] `AiJob` + `AiJobStatus`: uploading → queued → running → downloading → succeeded/failed/cancelled
- [x] `AiFailureCode` + map sang thông điệp người dùng (`AppStrings.aiErrors`) — chuỗi lỗi thô của nhà cung cấp không bao giờ tới mắt người dùng
- [x] `AiService` (abstract) — **không có tên nhà cung cấp, không có key, không có model id** trong contract
- [x] `EliraAiService`: HTTP thật tới backend của mình (submit multipart → poll → tải kết quả từ signed URL), `Authorization: Bearer <Firebase ID token>`
- [x] `FakeAiService`: chạy đủ chuỗi trạng thái, trả ảnh xử lý cục bộ, **đánh dấu `isSimulated`** để UI nói rõ đây không phải kết quả AI thật
- [x] `AiConfig`: đọc `ELIRA_AI_ENDPOINT` từ `--dart-define`. Không có endpoint → app đăng ký `FakeAiService(configured: false)` và nói thẳng "chưa kết nối"
- [x] `AuthService.idToken()` thêm vào cả 3 impl — app chứng minh mình là ai, server quyết định được tiêu bao nhiêu

### Controller
- [x] `credits` **bỏ hardcode 120**, đọc từ `AppUser.credits.balance` trong Firestore (mục 1 cấp 30 khi đăng ký)
- [x] `blockerFor(tool)` chặn **trước khi upload**: chưa kết nối / là guest / không đủ credit / thiếu prompt
- [x] `isProcessing`, `activeJob`, `lastFailure`, `cancel()`
- [x] Chạy xong **không tự áp vào ảnh** — giữ ở `pendingResult` chờ Apply hoặc Discard
- [x] Sau mỗi job gọi lại `loadProfile()` để lấy số dư server đã trừ

### Khác TODO — và đây là chỗ TODO sai theo hướng nguy hiểm
TODO ghi *"trừ credits sau mỗi lần dùng"* ở client. **Không làm vậy.**
`firestore.rules` (mục 1) đã đặt `credits` là chỉ-server-ghi, và đó là đúng:
client tự trừ được thì cũng tự **không** trừ được. Server trừ trong cùng
transaction nhận job, app chỉ đọc lại. Ngoài ra trừ *sau* khi model chạy xong
nghĩa là ai ngắt mạng giữa chừng thì dùng miễn phí — nên trừ lúc nhận job.

### Editor — kết quả AI vào stack thế nào
- [x] Thêm `EditOperationType.ai` mang `sourcePath`: kết quả ghi ra **file mới** cạnh project, ảnh gốc không bao giờ bị đè
- [x] Toàn bộ stack (adjust/filter/effect/crop/text) **replay tiếp lên trên** kết quả AI
- [x] **Undo qua bước AI trả về đúng ảnh gốc** — chạy AI là một bước, không phải điểm không quay lại
- [x] `EditorController.applyAiResult()` + nạp lại preview source khi nguồn đổi

### UI
- [x] `AiRunPanel` dùng chung cho Remove / Background / Retouch / AI: giá, số dư, nút Run bị chặn kèm lý do, tiến trình + Cancel, Apply/Discard
- [x] Thanh tiến trình **không xác định** khi server không báo `progress` — thà vậy còn hơn phần trăm giả rồi đứng im
- [x] Màn AI Studio: credit thật, mỗi tool hiện **giá ngay trên icon**, bấm tool → photo picker mang theo tool id (đường dây có sẵn từ mục 2/3)
- [x] "Explore AI Tools" (trước là `onTap: () {}`) → photo picker
- [x] Kết quả giả lập luôn ghi rõ "Simulated locally — no AI service is connected"

### Chưa làm
- [ ] **Backend.** Toàn bộ mục này chờ nó. Hợp đồng đã viết sẵn ở `docs/ai-backend-contract.md`
- [ ] Luồng **mua credit**: hết credit thì app báo đúng tình trạng rồi dừng, vì chưa có store flow (thuộc phần subscription/IAP)
- [ ] "Recent AI Results" ở màn AI Studio vẫn là 4 ô giả — cần lưu lịch sử job, thuộc **mục 9**
- [ ] Background tab mới làm được bước tách nền; chọn màu/gradient/ảnh thay nền là bước sau đó

**Verify:** `analyze` 0 issue · `test` **238/238 pass** (từ 199) · `build apk --debug --flavor dev` xanh.
Test mới: `ai_service_test.dart` (map lỗi, MockClient kiểm 402/body-error/thiếu resultUrl/JSON hỏng, **khẳng định request chỉ mang Bearer token, không mang key nào**), `ai_studio_controller_test.dart` (credit thật không phải 120, guest bị chặn, thiếu credit **không upload**, Apply/Discard, **undo qua bước AI về đúng ảnh gốc**, **file gốc không bị ghi đè**).

---

## 6. Export (`screen_export/`)

### Controller: `ExportController`
- [ ] `exportPhoto()` hiện = fake 2s delay
- [ ] Implement thật:
  - Render ảnh cuối (với tất cả adjustments + layers)
  - Save ra file temp
  - `image_gallery_saver` hoặc `gal` package → save vào Camera Roll
  - Upload lên Firestore Storage (optional, cho cloud backup)
  - Lưu `EditProject` record vào sqflite/Firestore

### UI
- [ ] Format selector (JPEG/PNG) — hiện UI có, chưa wire vào logic
- [ ] Quality slider — hiện UI có, chưa dùng khi export
- [ ] Share button → `Share.shareXFiles([result file])`
- [ ] Progress indicator thật khi đang export
- [ ] Success state + navigate về home sau export

---

## 7. Home (`screen_home/`)

### Controller: `HomeController`
- [ ] Load recent projects từ sqflite/Firestore → hiển thị "Continue Editing"
- [ ] Xóa hardcode "Santorini Trip", "My Puppy"
- [ ] Load user's recent filters/presets

### UI
- [ ] 3 nút `onSeeAll: () {}` rỗng → navigate tới list screens tương ứng
- [ ] "Continue Editing" items → route `/editor` với đúng project
- [ ] Empty state khi chưa có project nào
- [ ] Preset thumbnails thật (không phải colored box)

---

## 8. Create (`screen_create/`)

### Controller: `CreateController`
- [ ] Rỗng hoàn toàn — cần implement:
  - Load templates từ Firestore hoặc local asset
  - Tạo mới project từ template
  - Recent styles

### UI
- [ ] `onSeeAll: () {}` rỗng → navigate tới template list
- [ ] Template items → route `/editor` với template pre-loaded

---

## 9. Database Layer

### sqflite (local)
- [ ] Tạo `DatabaseService` hoặc `LocalDb` class
- [ ] Schema:
  ```sql
  CREATE TABLE projects (
    id TEXT PRIMARY KEY,
    name TEXT,
    original_path TEXT,
    edited_path TEXT,
    thumbnail_path TEXT,
    created_at INTEGER,
    updated_at INTEGER,
    adjustments TEXT  -- JSON blob
  );
  ```
- [ ] CRUD: `saveProject`, `loadProjects`, `deleteProject`, `updateProject`
- [ ] `EditProject` model → serialize/deserialize

### Firestore (cloud)
- [ ] `/users/{uid}` — profile, credits, subscription
- [ ] `/users/{uid}/projects/{pid}` — project metadata + cloud export URL
- [ ] Sync local sqflite ↔ Firestore khi có mạng

---

## 10. Packages cần thêm

```yaml
# image processing
image: ^4.x
image_cropper: ^5.x
image_gallery_saver: ^2.x  # hoặc gal: ^1.x

# HTTP + API
dio: ^5.x  # thay http nếu cần interceptor

# Permissions
permission_handler: ^11.x

# Share
share_plus: ^9.x

# Firebase (đã có, cần init)
firebase_auth: ^5.x
cloud_firestore: ^5.x
firebase_storage: ^12.x  # nếu cần cloud backup
```

---

## Màn cần tạo mới (chưa có)

| Màn | Route | Mục đích |
|-----|-------|----------|
| ~~`screen_login`~~ | `/login` | ✅ đã tạo |
| ~~`screen_signup`~~ | `/signup` | ✅ đã tạo |
| ~~`screen_forgot_password`~~ | `/forgot-password` | ✅ đã tạo |
| `screen_template_list` | `/templates` | Browse all templates |
| `screen_project_list` | `/projects` | All user projects |

---

## Notes kỹ thuật

- `EditorController` cần giữ cả `ui.Image` (processed) lẫn original bytes
- AI tool results nên cache vào temp dir, không re-process mỗi lần
- Credits system: trừ credits TRƯỚC khi gọi API, hoàn lại nếu API fail
- Remove BG cần result trước khi Background/Expand có thể dùng
- Text/Sticker layers nên là separate overlay widget, không burn vào ảnh cho đến khi export
