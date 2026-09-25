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

### Lỗi phát hiện khi chạy máy thật
- [x] **Kéo text / khung crop tụt lại sau ngón tay.** Overlay cộng `details.delta` vào giá trị chụp lúc build, nhưng build chỉ chạy 1 lần/frame trong khi màn cảm ứng bắn nhiều pointer event/frame → mọi event trong cùng frame ghi đè nhau, chỉ giữ 1 delta. Test tái hiện: kéo 100px, text chỉ đi **10px**. Nay tính theo **vị trí lúc chạm + tổng quãng ngón tay đã đi** (`text_overlay.dart`, `crop_overlay.dart`, cả kéo khung lẫn 4 góc), kèm `DragStartBehavior.down` để không khựng ở đầu cú kéo
- [x] **Mỗi tick kéo rebuild cả canvas ảnh**: `colorMatrix` dựng từ `currentState` nên canvas subscribe luôn `texts` + `geometry`. Nay chỉ đọc adjust + filter
- [x] Bớt việc thừa mỗi tick: `updateText` notify 2 lần → 1; `TextPanel` không rebuild khi chỉ đổi vị trí; style Google Fonts cache theo font; mỗi layer có `RepaintBoundary`
- Test: `editor_drag_test.dart` — nhiều lần move **trong cùng một frame** cho text, khung crop, góc crop, và ca đếm rebuild của canvas. Cả 4 fail trên code cũ

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

## 6. Export (`screen_export/`) — ĐÃ THI CÔNG

### `ExportService` — nơi stack được replay thật
- [x] Replay **toàn bộ** `EditState` ở **độ phân giải gốc**: geometry → spatial → ma trận màu. Editor chỉnh trên bản 1440px, đây là chỗ duy nhất chạy lại trên pixel thật (spec §7/§23)
- [x] Dùng **đúng các stage và đúng ma trận màu** của `ImagePipeline` mà canvas dùng — khác nhau ở đây là bug, nên có test so preview với export
- [x] `ExportStage`: rendering → compositing → encoding → saving → done, báo ra UI
- [x] Ảnh gốc **không bao giờ bị ghi đè** (có test)

### Text — chỗ khó nhất của mục này
- [x] Thêm `RawPixels`: pipeline có điểm thoát **trước khi encode**, vì `TextPainter` cần engine Flutter nên **không chạy được trong isolate**
- [x] Luồng: isolate (pixel) → main isolate (vẽ chữ bằng `TextPainter`) → isolate (encode). Mỗi bước vẫn testable riêng
- [x] Dùng **cùng `TextFonts`** với editor → chữ xuất ra khớp với chữ trên màn, không phải xấp xỉ bằng bitmap font của package `image`
- [x] Cỡ chữ và vị trí **chuẩn hoá theo ảnh** → cùng một caption trông như nhau ở bản 1080px và bản 6000px (có test tỉ lệ)
- [x] Layer trắng nội dung bị bỏ qua; không có text và không watermark thì **bỏ hẳn bước compositing** (có test)

### Controller
- [x] `exportPhoto()` bỏ `Future.delayed(2s)` → render thật
- [x] Format JPEG/PNG **wire thật**; quality slider **tự khoá khi chọn PNG** (PNG lossless, để slider sống trên một giá trị bị bỏ qua là nút lừa người dùng)
- [x] Resolution: Original / 2048 / 1080, và nhãn **tính từ crop + xoay thật** — trước đây hardcode "3024 × 4032" bất kể đã làm gì với ảnh
- [x] Watermark vẽ thật, **co theo kích thước ảnh** chứ không phải cỡ pixel cố định
- [x] Lưu vào thư viện qua `gal`, xin quyền khi cần
- [x] Share qua `Share.shareXFiles`; 4 nút social đều mở share sheet
- [x] Progress theo **giai đoạn thật**, success state có độ phân giải + dung lượng file

### Quyết định đáng nói
- **Lưu thư viện thất bại ≠ export thất bại.** Quyền bị từ chối thì file vẫn tồn tại và vẫn share được; app báo đúng phần nào hỏng thay vì vứt cả kết quả
- **4 nút social mở share sheet hệ thống**, không deep-link riêng từng app. Deep-link vào Instagram/TikTok cần SDK riêng của họ và quy trình duyệt riêng; share sheet là thứ chạy được hôm nay
- **`gal` thay vì `image_gallery_saver`** (TODO cho chọn 1 trong 2): `image_gallery_saver` đã lâu không cập nhật cho Android 13+ scoped storage

### Lỗi thật phát hiện khi viết test
- [x] **`google_fonts` tải font qua mạng và ném lỗi bất đồng bộ kiểu fire-and-forget.** Nghĩa là export có thể **âm thầm vẽ chữ bằng font fallback**, khác với thứ người dùng vừa thấy trên editor. Đã cho `ExportService` **nạp font trước rồi `await GoogleFonts.pendingFonts()`** và bắt lỗi, nên hoặc dùng đúng font, hoặc fallback một cách có kiểm soát
- [x] Thêm `TextFonts.allowDownloadableFonts` — tắt là không đụng mạng. Test dùng cờ này để kết quả tất định. **Cách sửa đúng vẫn là đóng gói file .ttf vào assets**, ghi nợ ở dưới

### Chưa làm (thuộc mục khác)
- [ ] Lưu `EditProject` xuống sqflite/Firestore sau export — **mục 9**. `EditState.toMap()` đã bao gồm cả 6 lát
- [ ] Upload lên Firebase Storage (TODO ghi "optional") — `firebase_storage` chưa có trong pubspec, và nó kéo theo Storage rules + quota, nên để cùng phần cloud project
- [ ] "Success → navigate về home": hiện ở lại màn Export kèm khối kết quả + nút Share. Đá người dùng đi ngay sau khi export là lấy mất cơ hội share, vốn là việc họ mở màn này để làm

### Nợ kỹ thuật
- Font vẫn tải runtime. Lần mở đầu không mạng → chữ (cả preview lẫn export) dùng font hệ thống. Đóng gói .ttf vào assets là việc của đợt polish

**Verify:** `analyze` 0 issue · `test` **272/272 pass** (từ 238) · `build apk --debug --flavor dev` xanh.
Test mới: `export_service_test.dart` (độ phân giải gốc/cap/crop/xoay, magic bytes JPEG-PNG, brightness–filter–effect có mặt trong pixel xuất ra, **export khớp preview**, text scale theo ảnh, thứ tự stage), `export_controller_test.dart` (gallery giả: có quyền / bị từ chối / ném lỗi — **từ chối quyền vẫn còn file share được**).

---

## 7. Home (`screen_home/`) — ĐÃ THI CÔNG

> Mục này **bắt buộc kéo phần local của mục 9 lên trước**: đầu việc đầu tiên của
> nó là "load recent projects từ sqflite". Không có store thì Home chỉ có hai
> lựa chọn — dữ liệu giả, hoặc rỗng vĩnh viễn. Nên phần lưu trữ **cục bộ** làm ở
> đây; **đồng bộ Firestore vẫn thuộc mục 9**.

### Lưu trữ project (phần local của mục 9)
- [x] `AppDatabase`: sqflite, schema v1, bảng `projects` + index `updated_at DESC` (Home query đúng cột này mỗi lần mở)
- [x] `ProjectRepository` (abstract) + `SqfliteProjectRepository` + `InMemoryProjectRepository` + `NullProjectRepository`
- [x] `touch()` **chỉ ghi field được truyền** — ghi cả row sẽ xoá mất tên vừa đổi hoặc thumbnail do đường khác ghi
- [x] Mở DB hỏng → rơi về in-memory. Mất danh sách project là tệ, nhưng không mở được app vì nó còn tệ hơn
- [x] `ProjectDraftService` **tự lưu row ngay khi tạo draft** — để không có thư mục ảnh nào tồn tại mà thiếu row trỏ tới (đó là cách thư mục mồ côi sinh ra)

### Editor ghi ngược lại
- [x] `EditorController` lưu **cả stack operation** (debounce 600ms + lưu nốt khi `onClose`)
- [x] Mở lại project từ Home **khôi phục đúng chỗ đã dừng, gồm cả lịch sử undo**
- [x] Chỉ lưu operation **đã áp dụng** — undo rồi thoát thì lần sau mở lên vẫn là trạng thái đã undo
- [x] Draft do bản build mới hơn ghi mà đọc không hiểu → mở với lịch sử rỗng, không chặn người dùng vào editor

### Controller
- [x] `HomeController` bỏ skeleton: `recentProjects`, `isLoadingProjects`, `projectsFailed`, `deleteProject`
- [x] Xoá sạch "Santorini Trip" / "My Puppy"
- [x] DB lỗi → Home vẫn dùng được, chỉ là không có lịch sử
- [x] Quay lại tab Home **tự load lại** — `MainShell` giữ cả 4 tab sống trong `IndexedStack` nên không có gì tự rebuild; và quay về từ editor cũng load lại

### UI
- [x] "Continue Editing" là project thật, thumbnail thật, bấm vào mở đúng project (truyền cả `EditProject` chứ không chỉ path, nên stack được khôi phục)
- [x] **Empty state thật**: bản cài mới không có gì để "continue", nay là một ô mời chọn ảnh thay vì 2 card bịa
- [x] 3 nút `onSeeAll` rỗng đã wire: Quick Actions → tab AI · Continue Editing → `/projects` · Popular Presets → picker mở thẳng tab Filters
- [x] Màn mới `/projects` (`screen_project_list` trong TODO): lưới toàn bộ project, pull-to-refresh, nhấn giữ để xoá kèm xác nhận
- [x] Xoá project có hỏi trước — nó xoá bản sao ảnh người dùng đã bỏ công chỉnh (ảnh trong gallery không đụng tới)

### Preset — khác TODO một chút
TODO ghi "preset thumbnails thật (không phải colored box)". Làm hơn thế: preset
trên Home nay **chính là filter thật của editor** (`PhotoFilters`), và mỗi card
là **ảnh gần nhất của chính người dùng** xem qua ma trận màu của filter đó. Một
lần decode ảnh cho cả dải, vì filter chỉ là ma trận màu (mục 4).
Chưa có ảnh nào thì rơi về một gradient **cũng đi qua đúng ma trận đó** — vẫn
cho thấy preset làm gì, thay vì ô xám.

### Chưa làm (thuộc mục khác)
- [ ] Đồng bộ Firestore, bảng `presets`, migration > v1 — **mục 9**
- [ ] "Load user's recent filters/presets" (preset **do người dùng tự lưu**) — cần bảng presets, **mục 9**. Hiện dải preset là catalogue dựng sẵn
- [ ] Màn `/templates` — **mục 8**

**Verify:** `analyze` 0 issue · `test` **296/296 pass** (từ 272) · `build apk --debug --flavor dev` xanh.
Test mới: `project_repository_test.dart` (thứ tự recent, limit, `touch` không ghi đè field khác, delete, `NullProjectRepository`), `home_controller_test.dart` (bản cài mới rỗng, DB hỏng vẫn dùng được, xoá, **mở lại project khôi phục cả lịch sử undo**, draft từ bản build mới hơn không làm vỡ editor).

### Chưa kiểm chứng được
`SqfliteProjectRepository` **chưa có test** — sqflite cần binding native nên unit
test chạy được `InMemoryProjectRepository` (cùng interface, cùng hợp đồng) chứ
không chạy được đường sqflite thật. Muốn phủ thì cần `sqflite_common_ffi` trong
dev_dependencies, hoặc integration test trên máy thật.

---

## 8. Create (`screen_create/`) — ĐÃ THI CÔNG

### Template là gì trong app này
Editor là pipeline **một ảnh**. Nên một template ở đây = **một hình dạng + một
tông màu**: tỉ lệ khung + filter + adjust + effect.

Điểm thiết kế chính: **template biên dịch thẳng thành `EditOperation` thường**.
Không có loại tài liệu mới, không có đường lưu riêng. Hệ quả:
- Áp template **không tốn thêm gì** — nó chỉ là stack đã điền sẵn
- **Từng bước một đều undo được**: thích crop nhưng không thích grain thì undo mỗi grain
- Lưu và mở lại bằng **đúng code của mục 7**, không thêm cột, không thêm plumbing
- Editor **không hề biết** template tồn tại

### Model + catalogue
- [x] `PhotoTemplate`: id, tên, category, tỉ lệ, adjust/filter/effect
- [x] 9 template qua 4 nhóm: Social · Portrait · Product · Cinematic
- [x] **Crop tính tại thời điểm áp**, không lưu sẵn: 9:16 trên ảnh ngang là hình chữ nhật khác hẳn trên ảnh dọc — và hình chữ nhật mới là thứ được lưu
- [x] Catalogue **nằm trong app**, không phải Firestore. TODO cho chọn "Firestore hoặc local asset" — chọn local vì template chỉ là vài con số, tải về nghĩa là tab Create rỗng ở lần mở đầu không mạng, cho dữ liệu vốn không đổi giữa hai bản phát hành
- [x] Id lạ → trả null, không ném lỗi
- [x] Gộp lại phép tính crop theo tỉ lệ: panel Crop (mục 4) và template dùng **chung một hàm**, nên 1:1 ở hai nơi không thể lệch nhau

### Controller + UI
- [x] `CreateController` bỏ rỗng: danh sách theo category, recent styles, `startTemplate()`
- [x] **Recent styles** lưu bằng `shared_preferences` (package đã khai báo từ đầu, tới giờ mới dùng thật). Id lạ còn sót từ bản cũ bị loại, không hiện card rỗng
- [x] 2 nút `onSeeAll` rỗng → màn `/templates` mới, lọc theo category
- [x] Template → picker mang theo id → draft sinh ra **đã có sẵn operation của template**
- [x] Card template hiện **đúng tỉ lệ thật** và **đúng ma trận màu** editor sẽ áp, không phải ô xám

### Nói thẳng: 3 thứ không làm được
`Collage`, `Poster`, `Product Card` **cần thứ engine chưa có** — ghép nhiều ảnh
trong một khung, và layer dạng shape/text box. Đây là khoảng trống thật, không
phải chuyện wire thêm.
- [x] 3 tile này nay **nói rõ còn thiếu gì** khi bấm, thay vì không làm gì
- [ ] Collage: cần compositing nhiều ảnh
- [ ] Poster: cần layer shape / text box / background
- [ ] Product Card: chờ tách nền (mục 5)

Đổi lại, 2 tile Quick Create đầu (`Story`, `Post`) nay chạy template thật.

### Chưa làm (thuộc mục khác)
- [ ] Template do người dùng tự lưu (lưu look hiện tại thành preset) — cần bảng `presets`, **mục 9**
- [ ] Đồng bộ template/preset lên Firestore — **mục 9**

**Verify:** `analyze` 0 issue · `test` **327/327 pass** (từ 296) · `build apk --debug --flavor dev` xanh.
Test mới: `photo_template_test.dart` (catalogue, `centeredCrop` các hướng khung, template gập thành state đúng, round-trip qua draft), `template_flow_test.dart` (**đi hết đường: tạo draft → editor khôi phục → tỉ lệ crop đúng → undo từng bước về ảnh gốc → mở lại vẫn còn**, và ảnh gốc không bị đụng).

---

## 9. Database Layer — ĐÃ THI CÔNG

> Phần **sqflite** đã làm ở mục 7 (vì Home không tồn tại được nếu thiếu nó).
> Mục này đóng nốt: test chạy qua **SQL thật**, bảng `presets`, và Firestore.

### Đóng lỗ hổng test đã tự nêu ở mục 7
- [x] Thêm `sqflite_common_ffi` (dev): bộ test chạy **SQL thật trên desktop VM**, không chỉ biên dịch
- [x] Viết **hợp đồng dùng chung**, chạy **hai lần** — một lần với `InMemory…`, một lần với `Sqflite…`. Mọi test khác của dự án dùng bản in-memory, nên nếu nó không hành xử giống bản SQL thật thì các test đó chẳng chứng minh điều gì
- [x] Test `PRAGMA table_info` khẳng định **mọi cột `EditProject.toMap()`/`UserPreset.toMap()` ghi ra đều tồn tại thật** — gõ sai tên cột là lỗi runtime mà trình biên dịch không bao giờ bắt được
- [x] Test **migration v1 → v2**: tạo DB v1 y như máy người dùng đang có, chèn dữ liệu, rồi mở bằng code hiện tại — draft cũ phải còn nguyên

### `DatabaseService` (mục 9 gọi là `LocalDb`)
- [x] `AppDatabase`: schema có version, `_onUpgrade` cộng dồn từng version, không bao giờ tạo lại bảng
- [x] CRUD đủ: `save` / `recent` / `all` / `byId` / `touch` / `delete` / `count`
- [x] `EditProject` serialize/deserialize — đã có từ mục 2, nay được test qua SQL thật

### Bảng `presets` (v2) — trả nốt món nợ của mục 7
- [x] `UserPreset` = **chỉ lát màu và effect**. Crop hay caption thuộc về *một tấm ảnh*, lưu vào look thì áp sang ảnh khác sẽ ra thứ khác hẳn
- [x] `PresetRepository` + sqflite + in-memory + null
- [x] `markUsed` dùng **một câu `UPDATE … use_count + 1`**, không read-modify-write: bấm nhanh hai lần thì không mất lượt nào
- [x] UI trong panel Filters: "Save look", dải look đã lưu, nhấn giữ để xoá. Nút Save **tắt khi chưa có gì để lưu**
- [x] Áp preset = **push operation thường** → undo được từng bước, lưu như mọi chỉnh sửa khác. Editor không cần biết preset là gì

### Firestore — và giới hạn thật của nó
- [x] `/users/{uid}` — đã xong từ mục 1
- [x] `/users/{uid}/projects/{pid}` + rules: chủ sở hữu mới đọc/ghi, **khoá cứng danh sách field**, chặn tên > 200 ký tự và stack > 64 phần tử (chống dùng document làm kho miễn phí)
- [x] `ProjectSync` + `FirestoreProjectSync` + `NullProjectSync` + `BackgroundProjectSync`
- [x] Editor push lên cloud sau mỗi lần lưu local, **không bao giờ await trên đường chỉnh sửa**: Firestore bật offline persistence nên một write không resolve cho tới khi có mạng — await nó là treo editor ở chế độ máy bay
- [x] Lỗi push/pull đều nuốt và log: DB local mới là nguồn sự thật và đã ghi xong trước đó

**Chỉ đồng bộ *công thức*, không đồng bộ ảnh.** Chưa có Firebase Storage nên
byte ảnh vẫn nằm trên máy. Hệ quả cần nói thẳng:
- Cài lại trên **cùng máy** → khôi phục được, vì ảnh vẫn trong thư viện và tìm lại được bằng `sourceAssetId`
- Sang **máy khác** → **không**. `CloudProject.isRestorable` là chỗ UI phân biệt hai ca này, thay vì mời người dùng khôi phục một thứ chắc chắn hỏng
- Ảnh chụp từ camera trong app chưa từng là asset thư viện → cũng không khôi phục được

**Đường dẫn máy không bao giờ rời thiết bị.** `originalPath`/`thumbnailPath`/
`editedPath` không có trong document: sang máy khác chúng vô nghĩa, và chúng để
lộ cấu trúc thư mục. Có test khẳng định điều này.

### Chưa làm
- [ ] **Firebase Storage** cho byte ảnh — đây là thứ chặn đồng bộ đa thiết bị, không phải chuyện wire thêm
- [ ] Màn "khôi phục từ cloud": `BackgroundProjectSync.restorable()` đã sẵn sàng, còn thiếu bước dựng lại bản sao làm việc từ `sourceAssetId` (cần quyền thư viện, không test headless được)
- [ ] Đồng bộ `presets` lên cloud — hiện chỉ local
- [ ] Test rules bằng `firebase emulators:exec` — chưa chạy

**Verify:** `analyze` 0 issue · `test` **373/373 pass** (từ 327).
Test mới: `database_test.dart` (**hợp đồng chạy 2 lần trên 2 implementation**, schema, cột khớp model, **migration v1→v2 giữ nguyên dữ liệu**), `project_sync_test.dart` (đường dẫn máy không rò ra ngoài, field khớp đúng rules, push lỗi không ném vào editor, `restorable` ẩn thứ không khôi phục được).

---

## 10. Packages — ĐÃ RÀ SOÁT

Phần lớn danh sách này đã tự giải quyết trong lúc thi công mục 2–9.

| Package | Trạng thái |
|---|---|
| `image` | ✅ đang dùng thật (mục 3–6), là lõi pipeline |
| `image_cropper` | ❌ **cố ý không dùng** — nó mở màn native riêng và trả về file đã cắt, làm đứt mạch non-destructive. Crop tự viết ở mục 4 là một operation replay được |
| `gal` | ✅ đã thêm ở mục 6 (chọn thay `image_gallery_saver`, vốn lâu không cập nhật cho scoped storage Android 13+) |
| `dio` | ❌ **chưa cần** — TODO ghi "thay http nếu cần interceptor". Client AI hiện không cần interceptor; `http` + `MockClient` đang test tốt |
| `permission_handler` | ✅ đang dùng (mục 2) |
| `share_plus` | ✅ đang dùng (mục 6) |
| `firebase_auth`, `cloud_firestore` | ✅ đang dùng (mục 1, 9) |
| `firebase_storage` | ❌ **chưa thêm** — cần cho byte ảnh trên cloud; xem giới hạn ở mục 9 |
| `sqflite_common_ffi` | ✅ **mới thêm (dev)** — để test SQL thật |

### Khai báo nhưng chưa dùng dòng nào
Đã kiểm bằng cách grep `package:<tên>/` trong `lib/`:

`cached_network_image` · `firebase_analytics` · `flutter_svg` · `lottie` ·
`intl` · `cupertino_icons`

- [ ] **Quyết định giữ hay bỏ.** Tôi **không tự xoá** vì có thể bạn đang để dành:
  `lottie` cho animation, `flutter_svg` cho icon, `intl` cho i18n (đang hoãn từ mục 1)
- [ ] `firebase_analytics` đáng chú ý riêng: đã khai báo nhưng **chưa init dòng nào**, nên hiện **không ghi nhận gì cả**. Hoặc wire vào, hoặc bỏ — để nguyên là tưởng có mà không có

---

## Màn cần tạo mới (chưa có)

| Màn | Route | Mục đích |
|-----|-------|----------|
| ~~`screen_login`~~ | `/login` | ✅ đã tạo |
| ~~`screen_signup`~~ | `/signup` | ✅ đã tạo |
| ~~`screen_forgot_password`~~ | `/forgot-password` | ✅ đã tạo |
| ~~`screen_template_list`~~ | `/templates` | ✅ đã tạo (mục 8) |
| ~~`screen_project_list`~~ | `/projects` | ✅ đã tạo (mục 7) |

---

## Notes kỹ thuật

- `EditorController` cần giữ cả `ui.Image` (processed) lẫn original bytes
- AI tool results nên cache vào temp dir, không re-process mỗi lần
- Credits system: trừ credits TRƯỚC khi gọi API, hoàn lại nếu API fail
- Remove BG cần result trước khi Background/Expand có thể dùng
- Text/Sticker layers nên là separate overlay widget, không burn vào ảnh cho đến khi export
