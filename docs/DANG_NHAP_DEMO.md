# Hướng dẫn đăng nhập demo

Tài khoản đã được liên kết và xác minh email. Không chọn đăng ký/liên kết MSSV lại.

| Vai trò | Ô đăng nhập | Mật khẩu demo | Gmail nhận OTP |
|---|---|---|---|
| Giảng viên | `GV001` | `DemoGv@2026` | `nxp125it@gmail.com` |
| Sinh viên | `SV001` | `DemoSv@2026` | `nxuanphu2k5@gmail.com` |
| Admin | `nxp125it@gmail.com` | `DemoGv@2026` | `nxp125it@gmail.com` |

Admin và GV001 dùng chung tài khoản và mật khẩu. Đăng nhập bằng mã GV001 chọn quyền Lecturer; đăng nhập bằng email chọn quyền Admin.

1. Mở màn hình đăng nhập (nếu đang trong tài khoản cũ, đăng xuất trước).
2. Nhập mã và mật khẩu đúng chữ hoa/thường theo bảng.
3. Bấm **Đăng nhập và gửi OTP**.
4. Mở Gmail đúng tài khoản, xem Hộp thư đến hoặc Thư rác.
5. Nhập OTP 6 số vừa nhận và bấm **Xác minh OTP**.
6. Nếu cần mã mới, bấm **Gửi lại OTP đăng nhập**. Không dùng OTP xác minh đăng ký để đăng nhập.

Mật khẩu trên là mật khẩu ứng dụng điểm danh, không phải mật khẩu Gmail hay App Password SMTP. Nhập sai nhiều lần có thể bị khóa 5 phút.

## Demo điểm danh

Giảng viên đăng nhập GV001, chọn lớp **LTDD-DEMO-01** (ID 1), mở phiên điểm danh tại vị trí thực tế và hiển thị QR. Sinh viên đăng nhập SV001, đăng ký/kiểm tra khuôn mặt, quét QR và hoàn tất trong 10 giây; đứng cách giảng viên tối đa 150 m. Có thể dùng Admin mở phiên QR khi chỉ có một điện thoại đăng nhập sinh viên.

Các hồ sơ SV002–SV010 vẫn nằm trong lớp nhưng chưa liên kết tài khoản. CTV vẫn dùng email mẫu nên chưa có Gmail nhận OTP.

Đã kiểm tra backend gửi OTP thật thành công cho GV001 và SV001; 58 kiểm thử tích hợp đạt. Giữ nguyên hồ sơ sinh viên, khuôn mặt, lớp, lịch học và lịch sử điểm danh hiện có.
