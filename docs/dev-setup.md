# Dựng môi trường build Android

Ghi lại cấu hình đã verify được (build thành công cả `--debug --flavor dev` lẫn
`--release --flavor product`) trên Windows 10, máy 8 GB RAM, ổ C: gần đầy.

## Phiên bản

| Thành phần | Bản dùng |
|---|---|
| Flutter | 3.38.9 stable (Dart 3.10.8) |
| JDK | Temurin **21** (AGP 9.1 hỗ trợ chính thức 17 hoặc 21 — **không** dùng 19) |
| Android SDK | platform-36, build-tools 36.0.0, platform-tools, NDK 28.2.13676358 |
| AGP / Kotlin / Gradle | 9.1.0 / 2.4.0 / 9.3.1 |

`compileSdk`, `targetSdk` và `ndkVersion` đều lấy từ Flutter nên **phải khớp
đúng bản Flutter đang dùng**. Tra bằng:

```powershell
Select-String -Path "<FLUTTER_SDK>\packages\flutter_tools\gradle\src\main\kotlin\FlutterExtension.kt" -Pattern "SdkVersion|ndkVersion"
```

## Cài đặt (không cần Android Studio, không cần quyền admin)

Cài sang ổ có nhiều chỗ trống — SDK + NDK chiếm ~8 GB, và thư mục mặc định nằm
ở `C:\Users\<user>\AppData\Local\Android\Sdk`.

```powershell
# 1. JDK 21 (bản zip, không cần installer)
curl.exe -L -o E:\Android\_dl\jdk21.zip `
  "https://api.adoptium.net/v3/binary/latest/21/ga/windows/x64/jdk/hotspot/normal/eclipse"
Expand-Archive E:\Android\_dl\jdk21.zip -DestinationPath E:\Android\jdk

# 2. Android command line tools
#    Tên file đổi theo bản phát hành — lấy tên mới nhất ở https://developer.android.com/studio
curl.exe -L -o E:\Android\_dl\cmdline-tools.zip `
  "https://dl.google.com/android/repository/commandlinetools-win-15859902_latest.zip"
Expand-Archive E:\Android\_dl\cmdline-tools.zip -DestinationPath E:\Android\_dl\cli

# 3. QUAN TRỌNG: sdkmanager bắt buộc nằm ở <sdk>\cmdline-tools\latest\bin
New-Item -ItemType Directory -Force E:\Android\Sdk\cmdline-tools
Move-Item E:\Android\_dl\cli\cmdline-tools E:\Android\Sdk\cmdline-tools\latest
```

Giải nén thẳng zip vào `E:\Android\Sdk\cmdline-tools\` sẽ ra
`cmdline-tools\cmdline-tools\bin` và `sdkmanager` báo lỗi không tìm thấy package.
Phải đổi tên thư mục thành `latest`.

```powershell
# 4. Chấp nhận license (stdin phải là file, không thì lệnh treo chờ y/n)
(1..100 | ForEach-Object { "y" }) | Out-File E:\Android\_dl\yes.txt -Encoding ascii
cmd /c "set JAVA_HOME=E:\Android\jdk\jdk-21.0.12.1+1&& E:\Android\Sdk\cmdline-tools\latest\bin\sdkmanager.bat --sdk_root=E:\Android\Sdk --licenses < E:\Android\_dl\yes.txt"

# 5. Cài gói
cmd /c "set JAVA_HOME=E:\Android\jdk\jdk-21.0.12.1+1&& E:\Android\Sdk\cmdline-tools\latest\bin\sdkmanager.bat --sdk_root=E:\Android\Sdk ""platform-tools"" ""platforms;android-36"" ""build-tools;36.0.0"" ""ndk;28.2.13676358"" < E:\Android\_dl\yes.txt"

# 6. Biến môi trường (phạm vi User, không cần admin)
[Environment]::SetEnvironmentVariable("ANDROID_HOME", "E:\Android\Sdk", "User")
[Environment]::SetEnvironmentVariable("ANDROID_SDK_ROOT", "E:\Android\Sdk", "User")
[Environment]::SetEnvironmentVariable("JAVA_HOME", "E:\Android\jdk\jdk-21.0.12.1+1", "User")

# 7. Trỏ Flutter vào
flutter config --android-sdk "E:\Android\Sdk"
flutter config --jdk-dir "E:\Android\jdk\jdk-21.0.12.1+1"
flutter doctor        # phải ra "No issues found!"
```

CMake 3.22.1 sẽ được Gradle tự tải ở lần build đầu, không cần cài trước.

## Lệnh build

Dự án có product flavor nên **`flutter run` / `flutter build apk` trần sẽ fail** —
luôn phải kèm `--flavor`:

```powershell
flutter run   --flavor dev
flutter build apk --debug   --flavor dev
flutter build apk --release --flavor product
```

Kiểm chứng APK (thay vì tin vào file manifest nguồn):

```powershell
$aapt = Get-ChildItem "$env:ANDROID_HOME\build-tools" -Recurse -Filter aapt2.exe | Select-Object -First 1 -ExpandProperty FullName
& $aapt dump permissions build\app\outputs\flutter-apk\app-product-release.apk
& $aapt dump badging     build\app\outputs\flutter-apk\app-product-release.apk | Select-String "^package:|application-label:"
```

Kết quả đúng: có `android.permission.INTERNET`, `package: name='com.asc.elira'`,
`application-label:'ASC Photo AI'`. Bản dev phải ra `com.asc.elira.dev` và
`Elira Dev`.

## Những chỗ đã phải sửa trong repo để build được

Không cái nào liên quan tới code Dart — tất cả đều là cấu hình build có sẵn:

| Vấn đề | Biểu hiện | Đã sửa |
|---|---|---|
| Thiếu `android/local.properties` | `settings.gradle.kts` `require()` biến `flutter.sdk` | Tạo file, đã gitignore |
| Plugin Kotlin chưa bao giờ được apply | `Unresolved reference 'compilerOptions'` — file có khối `kotlin { }` nhưng `android.builtInKotlin=false` nên không có gì apply ngầm | Thêm `id("org.jetbrains.kotlin.android")` |
| `org.gradle.jvmargs=-Xmx8G -XX:MaxMetaspaceSize=4G` | Gradle daemon crash: *Native memory allocation (mmap) failed* — xin 8 GB heap trên máy chỉ có 7.9 GB RAM | Hạ xuống `-Xmx2G`, thêm `kotlin.daemon.jvmargs=-Xmx1G`, `org.gradle.workers.max=2` |
| Kotlin incremental compilation | *Could not close incremental caches* ở mọi module plugin Kotlin (file `.tab` memory-mapped). Tái hiện cả trên build sạch với daemon khoẻ ⇒ độc lập với vấn đề bộ nhớ ở trên | `kotlin.incremental=false` |
| Thiếu `android/app/proguard-rules.pro` | `Supplied proguard configuration does not exist` — AGP 9 bật R8 mặc định cho release | Tạo file với rule giữ Flutter/Firebase/Firestore |

## Cảnh báo về antivirus

Máy này có **Kaspersky Endpoint Security**. Khi bật, nó:

- **Xoá `dart.exe`** khỏi `<flutter>\bin\cache\dart-sdk\bin` (mọi lệnh `flutter` sau đó chết với *"is not recognized as an internal or external command"*)
- Làm `pub` **crash với `ACCESS_VIOLATION 0xC0000005`** khi giải nén gói `vm_service`, khiến `flutter pub get` fail mà không in ra lý do gì

Cần thêm exclusion cho `<FLUTTER_SDK>` và `%LOCALAPPDATA%\Pub\Cache`. Nếu
`dart.exe` đã bị xoá, khôi phục bằng:

```powershell
Remove-Item "<FLUTTER_SDK>\bin\cache\engine-dart-sdk.stamp"
flutter --version   # tự tải lại Dart SDK
```

## Nợ kỹ thuật cần xử lý trước khi lên store

`android/app/build.gradle.kts` đang có `release { signingConfig = signingConfigs.getByName("debug") }`
— **bản release đang ký bằng debug key**. Vô hại với email/password auth, nhưng
chí mạng với Google Sign-In (validate SHA-1). Phải tạo keystore thật trước khi
làm Google Sign-In hoặc phát hành.
