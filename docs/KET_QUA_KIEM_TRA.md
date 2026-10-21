# Kết quả kiểm tra MVP

- Backend .NET 10: build thành công.
- SQL Server `XPHU\SQLEXPRESS01`, Windows Authentication: kết nối thành công; đã tạo database `NguyenXuanPhu_KTGK_LTDD` và áp dụng 3 migration.
- Kiểm thử tích hợp: **56 lượt gọi HTTP đạt** với backend thật, database SQL Server riêng và SMTP cục bộ. Bao gồm đăng ký MSSV/email, OTP, từ chối OTP đã dùng, JWT, phân quyền admin/GV/CTV/SV, CRUD, so khớp vector, ngoài bán kính, chưa thuộc lớp, quét trùng, hết hạn sau 11 giây chờ thật, đóng phiên và sửa bảng điểm danh.
- Flutter analyzer: **No issues found**.
- Widget test: kiểm tra form đăng nhập/đăng ký liên kết MSSV.
- Android debug APK: đã build thành công. File `FrontEnd/build/app/outputs/flutter-apk/app-debug.apk`.
- Đã sửa xung đột JVM target của `tflite_flutter` với Java/Kotlin trên máy.

Chưa xác minh Gmail thật vì chưa được cấu hình App Password. Kiểm thử SMTP cục bộ xác nhận luồng gửi/nhập OTP hoạt động; cần thử một lần với Gmail sau khi chạy `scripts/configure-local.ps1`.

Chưa có Android thật kết nối trong danh sách thiết bị lúc thực hiện. Chưa xác minh tốc độ suy luận MobileFaceNet, độ chính xác ngưỡng 0.70, camera và GPS trên điện thoại của bạn. Bài kiểm thử vector tổng hợp xác nhận logic so khớp backend, không thay thế thử khuôn mặt thật.

Google OAuth/One-Tap và chống giả mạo bằng ảnh/video chưa triển khai trong MVP. Chi tiết phạm vi nằm ở `HUONG_DAN_5_GIO.md`.
