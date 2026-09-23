# Elira — TODO & Roadmap

> Cập nhật: 2026-09-23  
> Trạng thái: 100% UI mockup — chưa có logic thật nào chạy được

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
- [ ] Gọi `Firebase.initializeApp()` trước `runApp()`
- [ ] Thêm `google-services.json` (Android) + `GoogleService-Info.plist` (iOS) — gitignored

### Màn: Splash (`screen_splash/splash_screen.dart`)
- [ ] Check `FirebaseAuth.instance.currentUser` thay vì hardcode delay 3s
  - Nếu đã login → route `/main`
  - Nếu chưa → route `/onboarding`
- [ ] Xử lý Firebase loading state (tránh flicker)

### Màn: Onboarding (`screen_onboarding/onboarding_screen.dart`)
- [ ] Tạo `AuthController` (hoặc mở rộng `OnboardingController`)
- [ ] Nút "Get Started" → màn Signup/Login (chưa có màn này, cần tạo)
- [ ] Nút "Skip" → route `/main` chỉ khi đã có anonymous auth hoặc bỏ skip
- [ ] Firebase Anonymous Auth (optional — cho phép dùng thử không login)

### Màn: Signup / Login (CHƯA CÓ — cần tạo mới)
- [ ] Tạo `screen_auth/` với 2 sub-screen: `login_screen.dart`, `signup_screen.dart`
- [ ] Tạo `AuthController`:
  - `signInWithEmail(email, password)`
  - `signUpWithEmail(email, password, name)`
  - `signInWithGoogle()` (optional)
  - `signOut()`
  - `resetPassword(email)`
- [ ] Validate form (email format, password min 6 ký tự)
- [ ] Xử lý error từ Firebase (wrong-password, user-not-found, email-in-use)
- [ ] Sau signup → tạo user document trong Firestore `/users/{uid}`
- [ ] Persist session — Firebase tự handle, nhưng cần test cold start

### Màn: Profile (`screen_profile/profile_screen.dart`)
- [ ] Load user từ `FirebaseAuth.instance.currentUser` (displayName, email, photoURL)
- [ ] Load stats từ Firestore `/users/{uid}` (projects count, favorites count, credits)
- [ ] Nút "Edit Profile" → update displayName, avatar
- [ ] Nút "Sign Out" → `AuthController.signOut()` → route `/onboarding`
- [ ] Xóa hardcode "Emma Carter", 128, 56, 2850, `isPro = true`

---

## 2. Photo Picker (`screen_photo_picker/`)

### Controller: `PhotoPickerController`
- [ ] Hiện tại load ảnh từ gallery OK — nhưng không persist selection
- [ ] Sau khi chọn ảnh → save path vào `EditProject` → route `/editor` với arguments đúng
- [ ] Camera capture (nếu có permission flow)
- [ ] Permission denied state (hiện icon + message hướng dẫn vào Settings)

---

## 3. Editor — Core (`screen_editor/editor_screen.dart`)

### Controller: `EditorController`
- [ ] **Undo/Redo stack** — hiện `undo()`/`redo()` rỗng hoàn toàn
  - Dùng `List<ImageState>` hoặc command pattern
  - `canUndo` / `canRedo` observables cần cập nhật đúng
- [ ] **Apply image adjustments thật** — hiện chỉ lưu slider value
  - Tích hợp package `image` (dart) hoặc `flutter_image_compress`
  - Apply: brightness, contrast, saturation, sharpness lên `ui.Image`
  - Debounce 300ms để không lag khi kéo slider
- [ ] Load ảnh gốc từ path argument vào `ui.Image` object
- [ ] Lưu bản gốc để reset/undo

### UI
- [ ] Version strip (4 thumbnail dummy hiện tại) → bind vào undo history thật
- [ ] Hiển thị ảnh đã processed (hiện chỉ `Image.file` tĩnh)

---

## 4. Editor — Tool Panels

### Adjust Panel (`tools/adjust_panel.dart`)
- [ ] Nút "Auto" (`onAuto: () {}` rỗng) → tự động tính brightness/contrast optimal
- [ ] Slider changes → apply thật lên ảnh (debounced)
- [ ] Reset từng slider về 0

### Filters Panel (`tools/filters_panel.dart`)
- [ ] `_selected` local state hiện không làm gì
- [ ] Apply filter thật lên ảnh khi chọn (LUT hoặc color matrix)
- [ ] Preview thumbnail từng filter trên ảnh hiện tại (không phải ảnh mẫu cố định)
- [ ] Filter list: Cinematic, Vibrant, Aesthetic, Golden Hour, B&W, Fade, Warm, Cool

### Effects Panel (`tools/effects_panel.dart`)
- [ ] `_selected` state không apply gì
- [ ] Implement: Vignette, Blur, Grain, Glow, Sharpen
- [ ] Mỗi effect có intensity slider

### Crop Panel (`tools/crop_panel.dart`)
- [ ] `_selectedRatio` local state không crop thật
- [ ] Tích hợp `image_cropper` package (hoặc custom)
- [ ] Ratio presets: Free, 1:1, 4:3, 16:9, 3:4, 9:16
- [ ] Rotate 90° / flip horizontal / flip vertical
- [ ] Confirm crop → update ảnh trong EditorController

### Retouch Panel (`tools/retouch_panel.dart`)
- [ ] UI local state không xử lý gì
- [ ] Smooth Skin, Whiten Teeth, Eye Brighten — cần AI hoặc HSL local processing
- [ ] Brush size slider
- [ ] Intensity slider
- [ ] Kết hợp với AI nếu có (giai đoạn sau)

### Remove Panel (`tools/remove_panel.dart`)
- [ ] Nút "Remove" không có callback
- [ ] Tích hợp API Remove.bg hoặc Replicate (segment-anything)
- [ ] Gửi ảnh lên API → nhận mask → apply lên ảnh
- [ ] Loading state + error handling

### Background Panel (`tools/background_panel.dart`)
- [ ] UI tabs (Color/Gradient/Image) không làm gì
- [ ] Yêu cầu: Remove BG xong mới thay background được
- [ ] Color tab → color picker → apply background solid color
- [ ] Gradient tab → chọn gradient preset
- [ ] Image tab → pick ảnh từ gallery làm background

### Text Panel (`tools/text_panel.dart`)
- [ ] Nút "Add Text" không wire
- [ ] Thêm text overlay lên ảnh (draggable, resizable)
- [ ] Font picker (basic: 3–5 font)
- [ ] Color picker cho text
- [ ] Text align (left/center/right)
- [ ] Double tap để edit text đã thêm
- [ ] Xóa text layer

### AI Panel (`tools/ai_panel.dart`)
- [ ] Tất cả `onTap: () {}` rỗng
- [ ] Wire từng tool → gọi `AiStudioController.runTool(id)`
- [ ] Khi processing: disable panel, hiện progress overlay
- [ ] Khi done: load ảnh kết quả vào EditorController

---

## 5. AI Studio (`screen_ai_studio/`)

### Controller: `AiStudioController`
- [ ] `runTool(String name)` hiện = fake 3s delay
- [ ] Cần implement thật với API:

| Tool | API gợi ý | Input | Output |
|------|-----------|-------|--------|
| Remove BG | remove.bg API | image file | PNG no-bg |
| AI Enhance | Replicate (Real-ESRGAN) | image | upscaled image |
| AI Retouch | Replicate (InstantID/face restore) | image | retouched image |
| Expand (Outpaint) | Replicate (Stable Diffusion Inpaint) | image + prompt | expanded image |
| Relight | Replicate (IC-Light) | image | relit image |
| Restore (Old photo) | Replicate (CodeFormer) | image | restored image |

- [ ] `credits` (hardcode 120) → load từ Firestore, trừ credits sau mỗi lần dùng
- [ ] `isProcessing` đã có → wire vào UI đúng (disable buttons khi processing)
- [ ] Upload ảnh lên API (multipart/form-data hoặc base64)
- [ ] Download kết quả → save temp file → load vào editor
- [ ] Error handling: network fail, API quota, invalid image

### UI: `ai_studio_screen.dart`
- [ ] "Explore AI Tools" button (`onTap: () {}` rỗng) → navigate đến tool list
- [ ] Credit counter hiển thị thật từ controller
- [ ] Sau khi AI xử lý xong → show result, cho phép "Apply" hoặc "Discard"

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
| `screen_login` | `/login` | Email/password login |
| `screen_signup` | `/signup` | Tạo tài khoản |
| `screen_forgot_password` | `/forgot-password` | Reset password |
| `screen_template_list` | `/templates` | Browse all templates |
| `screen_project_list` | `/projects` | All user projects |

---

## Notes kỹ thuật

- `EditorController` cần giữ cả `ui.Image` (processed) lẫn original bytes
- AI tool results nên cache vào temp dir, không re-process mỗi lần
- Credits system: trừ credits TRƯỚC khi gọi API, hoàn lại nếu API fail
- Remove BG cần result trước khi Background/Expand có thể dùng
- Text/Sticker layers nên là separate overlay widget, không burn vào ảnh cho đến khi export
