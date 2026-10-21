# Hướng dẫn hoàn thành và trình bày MVP trong 5 giờ

Thư mục gốc: `C:\LTDD\NguyenXuanPhu_KTGK_LTDD`.
Backend: ASP.NET Core 10 + Identity + JWT + EF Core + SQL Server Windows Authentication.
Frontend: Flutter Android, ML Kit phát hiện mặt + MobileFaceNet của demo bạn cung cấp tạo vector 192 chiều.

## 1. Chạy lần đầu

### 1.1 Chuẩn bị Gmail, cấu hình bí mật và tài khoản admin

1. Bật xác minh hai bước cho Gmail gửi OTP.
2. Tạo App Password tại https://myaccount.google.com/apppasswords. Nếu tùy chọn không xuất hiện, kiểm tra điều kiện tài khoản theo [hướng dẫn chính thức Google](https://support.google.com/mail/answer/185833?hl=vi).
3. Trong terminal PowerShell tại thư mục gốc chạy:

```powershell
.\scripts\configure-local.ps1
```

Script lần lượt hỏi:

| Thông tin nhập | Lưu vào cấu hình |
|---|---|
| Gmail gửi OTP | `Smtp:User`, `Smtp:From` |
| App Password Gmail | `Smtp:Password` |
| Email quản trị viên, phải nhận được thư | `SeedAdmin:Email` |
| Mật khẩu admin bạn chọn | `SeedAdmin:Password` |

Mật khẩu admin cần có ít nhất 8 ký tự, chữ hoa, chữ thường, chữ số và ký hiệu.
Script tự tạo `Jwt:Secret` ngẫu nhiên; nếu chạy Development mà khóa này chưa được nạp hoặc còn là giá trị mẫu, backend tự dùng khóa ngẫu nhiên 64 byte lưu trong `.local/jwt-signing.key` của project (bị loại khỏi Git/publish); thiết lập Gmail SMTP qua `smtp.gmail.com:587`, STARTTLS. [Tài liệu Google về SMTP](https://support.google.com/a/answer/176600?hl=vi).

Tất cả bí mật nằm trong .NET User Secrets của project có ID `attendance-nguyenxuanphu-mvp`, không nằm trong source. Chạy backend với môi trường Development để đọc User Secrets.
Trong Visual Studio: nhấp phải backend project → **Manage User Secrets** để chỉnh lại nếu cần. Các khóa nằm trong bảng trên; không điền bí mật vào Flutter hoặc `.env`.

Nếu muốn sửa riêng từng khóa:

```powershell
$apiProject = '.\BackEnd\NguyenXuanPhu_KTGK_LTDD\NguyenXuanPhu_KTGK_LTDD'
dotnet user-secrets set 'Smtp:User' 'GMAIL_CUA_BAN' --project $apiProject
dotnet user-secrets set 'Smtp:From' 'GMAIL_CUA_BAN' --project $apiProject
```

Dùng script để nhập mật khẩu ở chế độ ẩn. Tài khoản admin được tạo lúc backend khởi động lần đầu, chỉ khi email chưa tồn tại. Đổi `SeedAdmin:Password` sau đó không thay mật khẩu tài khoản đã có.

### 1.2 SQL Server và backend trong VS 2026

Mở solution:

`BackEnd\NguyenXuanPhu_KTGK_LTDD\NguyenXuanPhu_KTGK_LTDD.slnx`

Connection string nằm trong backend `appsettings.json`:

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=XPHU\\SQLEXPRESS01;Database=NguyenXuanPhu_KTGK_LTDD;Trusted_Connection=True;TrustServerCertificate=True"
  }
}
```

Database trên đã được tạo và áp dụng migration trong phiên sửa code này. Backend cũng tự áp dụng migration khi khởi động. Không cần chạy `EnsureCreated` hoặc tạo bảng thủ công. Tài khoản Windows chạy backend cần quyền truy cập database; lần tạo DB cần quyền tạo database.

Chọn profile **http** trong Visual Studio, hoặc chạy ở thư mục gốc:

```powershell
dotnet run --project .\BackEnd\NguyenXuanPhu_KTGK_LTDD\NguyenXuanPhu_KTGK_LTDD --launch-profile http
```

Kiểm tra:

- API health: http://localhost:5090/api/health
- Swagger: http://localhost:5090/swagger

### 1.3 Chạy Flutter trên Android thật qua USB

Bật Developer Options và USB debugging trên điện thoại, cắm USB và chấp nhận hộp thoại cấp quyền.
Mở terminal thứ hai:

```powershell
cd C:\LTDD\NguyenXuanPhu_KTGK_LTDD\FrontEnd
flutter pub get
flutter devices
adb reverse tcp:5090 tcp:5090
flutter run -d MA_THIET_BI
```

Nếu `adb` không có trong PATH, dùng `adb.exe` ở `platform-tools` trong Android SDK của bạn (xem SDK Location trong Android Studio). Sau khi rút/cắm USB hoặc khởi động lại máy có thể cần chạy lại `adb reverse`.

URL API nằm trong `FrontEnd/.env` ở khóa `API_BASE_URL`, được đọc chung qua `FrontEnd/lib/config/config_api.dart`. Để dùng USB reverse, đặt `API_BASE_URL=http://127.0.0.1:5090` (không kèm `/api`). Điện thoại dùng camera/GPS thật, không dùng địa chỉ emulator `10.0.2.2`.

Hoặc dùng Wi-Fi cùng mạng:

```powershell
# Terminal backend tại thư mục gốc
dotnet run --project .\BackEnd\NguyenXuanPhu_KTGK_LTDD\NguyenXuanPhu_KTGK_LTDD --launch-profile http --urls http://0.0.0.0:5090
# Terminal Flutter tại FrontEnd, thay bằng IPv4 máy tính
# Đặt API_BASE_URL=http://192.168.1.100:5090 trong FrontEnd/.env rồi chạy:
flutter run -d MA_THIET_BI
```

Cho phép backend qua Windows Firewall trên mạng riêng nếu dùng Wi-Fi. Đổi `.env` cần khởi động lại đầy đủ hoặc build lại app.

APK debug đã tạo tại:

`FrontEnd\build\app\outputs\flutter-apk\app-debug.apk`

APK gọi máy chủ khai báo trong `.env` lúc build; nếu đổi máy chủ thì sửa `API_BASE_URL` trong `.env` và build lại.

## 2. Kịch bản sử dụng theo đúng thứ tự

1. Admin đăng nhập email + mật khẩu → nhận OTP → nhập OTP. Chỉ sau OTP backend mới cấp JWT.
2. Dashboard admin → **Quản lý tài khoản giảng viên** → thêm email, họ tên, mật khẩu ban đầu.
3. Giảng viên mở màn hình đăng nhập → nhập email → **Tài khoản chưa xác minh? Gửi lại OTP email** → nhập OTP xác minh; sau đó đăng nhập mật khẩu + OTP.
4. Giảng viên có thể tạo cộng tác viên. Cộng tác viên xác minh email bằng cách giống bước 3.
5. Giảng viên hoặc cộng tác viên → **Hồ sơ sinh viên** → thêm MSSV, họ tên, email, khoa. Sinh viên chưa cần tài khoản ở bước này.
6. Sinh viên → **Sinh viên liên kết MSSV có sẵn** → nhập đúng email + MSSV trong hồ sơ + mật khẩu mới → nhận OTP và xác minh. Không tự khai quyền, không tự tạo hồ sơ MSSV.
7. Sinh viên đăng nhập + OTP → **Đăng ký khuôn mặt**. Camera trước tự chụp, phát hiện một khuôn mặt, tạo vector và lưu backend.
8. Giảng viên tạo môn học → lớp học → lịch học. Admin tạo lớp phải chọn giảng viên. Giảng viên tạo lớp thì tự được phân công lớp đó.
9. Giảng viên → **Danh sách lớp và bảng điểm danh** → biểu tượng nhóm người → thêm sinh viên vào lớp. Có thể mở lại để bỏ sinh viên chưa có lịch sử điểm danh.
10. Giảng viên bật GPS, tại lớp nhấn biểu tượng QR để mở phiên 10 phút tại vị trí hiện tại. QR hiển thị ngay, có thể mở lại bằng **Hiện QR**.
11. Sinh viên bật GPS → **Quét QR điểm danh** → quét QR → app kiểm tra vị trí, chuẩn bị camera trước → backend cấp lượt xác thực 10 giây → camera tự quét và gửi vector để so khớp.
12. Backend chỉ ghi nhận nếu sinh viên thuộc lớp, trong bán kính 150m, phiên còn mở, lượt xác thực còn hạn và cosine similarity >= 0.70. Một sinh viên chỉ có một bản ghi trong mỗi phiên.
13. Giảng viên xem bảng điểm danh, có thể sửa có mặt/vắng kèm lý do. Backend lưu người sửa và thời gian sửa. Giảng viên đóng phiên khi cần.
14. Sinh viên xem lịch sử và lịch học của lớp mình.

Cần hai thiết bị hoặc hiển thị QR trên màn hình khác để sinh viên quét. Có thể đăng nhập giảng viên trên một điện thoại, chụp QR hiển thị lên máy tính, rồi chuyển điện thoại sang tài khoản sinh viên để thử. QR còn hiệu lực đến khi hết phiên/giảng viên đóng phiên.

## 3. Kế hoạch 5 giờ

Code MVP đã được sửa trực tiếp; dùng thời gian này để cấu hình và chạy thử trên thiết bị thật.

| Thời gian | Việc thực hiện | Điều kiện hoàn thành |
|---|---|---|
| 00:00–00:40 | Gmail, User Secrets, khởi động API, USB reverse | Admin đăng nhập qua OTP được |
| 00:40–01:25 | Tạo giảng viên, CTV, MSSV; liên kết email | Ba vai trò đăng nhập đúng dashboard |
| 01:25–02:10 | CRUD môn học, lớp, lịch học; thêm danh sách lớp | Sinh viên thấy lịch học của mình |
| 02:10–03:10 | Đăng ký mặt, mở phiên, thử QR + GPS + mặt | Điểm danh thành công trên Android thật |
| 03:10–04:10 | Thử mặt khác, hết 10 giây, xa GPS, quét trùng, đóng phiên | App từ chối đúng, không thêm bản ghi sai |
| 04:10–05:00 | Chuẩn bị tài khoản/dữ liệu demo, luyện trình bày, giữ APK | Demo hoàn chỉnh và giải thích được API |

Đăng nhập Google/One-Tap để sau MVP theo quyết định đã chốt. Chưa có Google OAuth trong bản này.

## 4. Thứ tự đọc code: file nằm ở đâu, làm gì

Đường dẫn backend dưới đây tính từ `BackEnd/NguyenXuanPhu_KTGK_LTDD/NguyenXuanPhu_KTGK_LTDD`.
Code thật đã ở các file này; không cần sao chép lại từ tài liệu.

| Thứ tự | File | Nội dung cần đọc |
|---|---|---|
| 1 | `Models/AppUser.cs` | Tài khoản Identity, họ tên, người tạo CTV/GV |
| 2 | `Models/Entities.cs` | Student, Lecturer, Course, ClassGroup, ClassMember, Schedule, FaceProfile, AttendanceSession/Challenge/Record |
| 3 | `Models/AppDbContext.cs` | DbSet, unique index, khóa ngoại giữ toàn vẹn dữ liệu |
| 4 | `DTOs/AuthDtos.cs` | Request/response JSON của API; không nhận trực tiếp entity từ client |
| 5 | `Program.cs` | SQL Server, Identity, JWT Bearer, rate limit OTP, DI, Swagger, migration và seed admin |
| 6 | `Services/EmailService.cs` | Gửi OTP qua SMTP cấu hình bằng User Secrets |
| 7 | `Controllers/AuthController.cs` | Đăng ký từ MSSV + email, xác minh, đăng nhập hai bước |
| 8 | `Controllers/AccountsController.cs` | Admin tạo GV, GV tạo CTV, CRUD tài khoản |
| 9 | `Controllers/StudentsController.cs` | CRUD hồ sơ sinh viên, CTV chỉ thêm và xem |
| 10 | `Controllers/CoursesController.cs` | CRUD môn học |
| 11 | `Controllers/ClassesController.cs` | CRUD lớp, thêm/bỏ sinh viên, giới hạn lớp theo quyền |
| 12 | `Controllers/SchedulesController.cs` | CRUD lịch học, sinh viên chỉ xem lớp mình |
| 13 | `Controllers/FaceController.cs` | Tạo/cập nhật mẫu MobileFaceNet 192 chiều, không trả mẫu qua GET |
| 14 | `Controllers/AttendanceController.cs` | Mở/đóng phiên, GPS Haversine, challenge 10s, cosine similarity, ghi nhận, sửa và xem lịch sử |
| 15 | `Models/DesignTimeDbContextFactory.cs` | Tạo migration không cần cấu hình SMTP/JWT |
| 16 | `Migrations/` | Lược đồ ban đầu, trường điều chỉnh, ràng buộc dữ liệu |

Flutter, tính từ thư mục `FrontEnd`:

| Thứ tự | File | Nội dung |
|---|---|---|
| 17 | `lib/config/config_api.dart` | Đọc `API_BASE_URL` từ `.env`, cung cấp `baseURL` và ghép endpoint |
| 18 | `lib/services/api_service.dart` | JSON HTTP, gắn JWT, timeout, thông báo lỗi |
| 19 | `lib/main.dart` | Khởi động ứng dụng và kiểm tra phiên đăng nhập đã lưu |
| 20 | `lib/screens/login_screen.dart` | Form liên kết MSSV, đăng nhập OTP, gửi lại OTP xác minh |
| 21 | `lib/screens/dashboard_screen.dart` | Điều hướng theo Admin/Lecturer/Collaborator/Student |
| 22 | `lib/screens/management_screen.dart` | Form CRUD có nhãn, dropdown môn/lớp/GV, xác nhận xóa |
| 23 | `lib/screens/teaching_screen.dart` | Danh sách lớp, danh sách SV, QR, đóng phiên, sửa bảng điểm danh |
| 24 | `lib/services/location_service.dart` | Quyền GPS, vị trí chính xác, từ chối mock trên client |
| 25 | `lib/screens/attendance_screen.dart` | Chuyển camera QR sang camera khuôn mặt, gọi begin/mark |
| 26 | `lib/screens/face_camera_screen.dart` | Camera tự chụp lặp, đếm ngược, đọc đúng hướng EXIF, dọn ảnh tạm |
| 27 | `lib/services/face_detector_service.dart` | ML Kit phát hiện mặt |
| 28 | `lib/services/face_crop_service.dart` | Cắt đúng bounding box khuôn mặt |
| 29 | `lib/services/face_embedding_service.dart` | MobileFaceNet, ảnh 112×112, chuẩn hóa [-1,1], vector 192 |
| 30 | `assets/models/mobilefacenet.tflite` | Mô hình chép từ demo của bạn |
| 31 | `pubspec.yaml` | Các package và khai báo asset |
| 32 | `android/app/src/main/AndroidManifest.xml` | Internet, camera, vị trí, HTTP cho demo nội bộ |
| 33 | `android/build.gradle.kts` | Đồng bộ Kotlin JVM 11 riêng cho plugin tflite_flutter |
| 34 | `android/app/build.gradle.kts` | Android minSdk >=23, JVM app 17 |
| 35 | `test/widget_test.dart` | Kiểm tra màn hình đăng nhập và form MSSV |

File hỗ trợ ở thư mục gốc:

- `scripts/configure-local.ps1`: nhập Gmail/admin/JWT đúng vị trí, mật khẩu nhập ẩn.
- `tests/ApiVerification/Program.cs`: kiểm thử HTTP thật + SQL Server + SMTP giả lập cục bộ, tự dọn database kiểm thử riêng.
- `docs/API.md`: danh sách endpoint và JSON mẫu.

## 5. Kiểm tra và lỗi thường gặp

```powershell
# Tại thư mục gốc
dotnet build .\BackEnd\NguyenXuanPhu_KTGK_LTDD\NguyenXuanPhu_KTGK_LTDD
dotnet run --project .\tests\ApiVerification\ApiVerification.csproj
# Trong FrontEnd
flutter analyze
flutter test
flutter build apk --debug
```

Kiểm thử API dùng Windows Authentication và server trong `appsettings.json`, tự tạo database có tên ngẫu nhiên `Attendance_Verification_...`, kiểm tra xong tự xóa đúng database đó. Không cần Gmail thật, không chỉnh database ứng dụng. Cần quyền tạo/xóa database kiểm thử. Vector tổng hợp chỉ kiểm tra logic so khớp backend; chất lượng nhận diện phải kiểm tra bằng camera thật.

| Hiện tượng | Cách xử lý |
|---|---|
| JWT khi chạy Development | Backend tự tạo khóa ngẫu nhiên cục bộ nếu User Secrets chưa nạp; Production vẫn phải cấu hình khóa hợp lệ |
| OTP không gửi được / HTTP 503 | Kiểm tra Gmail App Password, SSL, mạng; tài khoản đã tạo dùng nút gửi lại OTP, không đăng ký lặp |
| Tài khoản GV/CTV chưa xác minh | Nhập email rồi dùng nút gửi lại OTP email tại màn hình đăng nhập |
| API không kết nối trên Android | Backend chạy chưa; USB reverse còn hiệu lực chưa; nếu Wi-Fi kiểm tra IPv4 và firewall |
| Không có điện thoại trong flutter devices | Bật USB debugging, đổi cáp, chấp nhận quyền ADB |
| GPS chưa chính xác | Bật vị trí chính xác, chờ GPS ổn định/ra chỗ thoáng; tránh vị trí giả |
| Chưa thuộc lớp | Giảng viên ghi danh SV trước khi quét |
| Hết 10 giây | Quay lại quét QR để tạo lượt xác thực mới |
| Khuôn mặt không khớp | Ánh sáng đủ, nhìn thẳng; đăng ký lại cùng mô hình; 0.70 là ngưỡng từ demo, cần hiệu chỉnh trên điện thoại thật |
| Không xóa được dữ liệu | Bản ghi đang được sử dụng hoặc đã có lịch sử; backend bảo vệ dữ liệu liên quan |
| HTTP 429 | Đợi một phút; OTP giới hạn 15 request/phút/IP |

## 6. Phạm vi và phần cần thử trên thiết bị

- Đã có so khớp danh tính theo vector, không chỉ phát hiện có khuôn mặt.
- 10 giây bắt đầu khi camera trước sẵn sàng và API `begin` xác nhận QR/lớp/GPS; không trừ thời gian xin quyền, lấy GPS và khởi động camera. Backend quyết định hết hạn, app không tự kéo dài được.
- Chưa có liveness/chống dùng ảnh hoặc video. Client tạo vector và gửi tọa độ; MVP chưa có chứng thực thiết bị hoặc mô hình suy luận trên server để chống client bị sửa.
- Bán kính 150m và thời gian phiên mặc định 10 phút; thời gian xác thực mặt 10 giây; ngưỡng cosine 0.70.
- Sửa bảng điểm danh là quyền GV phụ trách/admin, có lý do và trường người/thời gian sửa; không giả thành kết quả nhận diện tự động.
- CRUD sinh viên xóa hồ sơ chưa liên kết/chưa có lịch sử; email/MSSV đã liên kết được giữ cố định. CRUD tài khoản GV/CTV giữ email cố định. Đổi email có xác minh lại và đặt lại mật khẩu là bước sau MVP.
- Lịch học được quản lý và hiển thị; phiên điểm danh do GV chủ động mở, chưa tự động buộc theo lịch.
- JWT lưu SharedPreferences cho bản demo; khi triển khai thật nên chuyển sang kho bí mật của thiết bị và HTTPS.
- Google OAuth/One-Tap được hoãn sau MVP. Không có nút Google giả.
- Chưa kiểm tra camera/GPS/nhận diện trên Android thật vì chưa có điện thoại kết nối lúc sửa code. Cần thử bước 7–13 trước buổi trình bày.


