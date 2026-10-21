# App điểm danh sinh viên

ASP.NET Core 10 + Flutter Android + SQL Server Windows Authentication.

Bắt đầu với [hướng dẫn cấu hình, thứ tự file và kế hoạch 5 giờ](docs/HUONG_DAN_5_GIO.md).
Danh sách endpoint và JSON mẫu: [API](docs/API.md).

```powershell
# Tại thư mục gốc, nhập Gmail/App Password và thông tin admin
.\scripts\configure-local.ps1
# Chạy backend
dotnet run --project .\BackEnd\NguyenXuanPhu_KTGK_LTDD\NguyenXuanPhu_KTGK_LTDD --launch-profile http
```

```powershell
# Terminal khác
cd FrontEnd
flutter pub get
adb reverse tcp:5090 tcp:5090
flutter run -d MA_THIET_BI_ANDROID
```

MVP: email OTP, liên kết MSSV, bốn vai trò, CRUD hồ sơ/tài khoản/môn/lớp/lịch, danh sách lớp, đăng ký/cập nhật khuôn mặt, QR + GPS + so khớp khuôn mặt trong 10 giây, lịch sử và điều chỉnh bảng điểm danh.

Google OAuth/One-Tap và chống giả mạo khuôn mặt chưa nằm trong MVP. Xem phạm vi và hướng dẫn thử trên điện thoại thật trong tài liệu.
