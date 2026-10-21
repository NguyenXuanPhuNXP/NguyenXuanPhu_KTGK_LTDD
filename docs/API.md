# API MVP

Base URL: `http://localhost:5090`. JSON camelCase. Thời gian gửi lên theo ISO 8601 UTC (hậu tố `Z`).
Các API ngoài `/auth/*` và `/health` cần header `Authorization: Bearer JWT`.

Vai trò: `Admin`, `Lecturer`, `Collaborator`, `Student`.

## 1. Xác thực

| Method | Endpoint | Nội dung |
|---|---|---|
| GET | `/api/health` | Kiểm tra API |
| POST | `/api/auth/register` | Liên kết hồ sơ MSSV/email có sẵn, tạo tài khoản chưa xác minh và gửi OTP |
| POST | `/api/auth/resend-email` | Gửi lại OTP xác minh cho SV/GV/CTV chưa xác minh |
| POST | `/api/auth/verify-email` | Xác minh email, không trả JWT |
| POST | `/api/auth/login` | Kiểm tra mật khẩu, gửi OTP, không trả JWT |
| POST | `/api/auth/verify-login` | Kiểm tra OTP và trả JWT |

Đăng ký:

```json
{ "email": "sv@example.com", "password": "MatKhau!123", "fullName": "", "studentCode": "SV001" }
```

`fullName` giữ tương thích request hiện có, họ tên thực lấy từ hồ sơ MSSV. Sinh viên không tự chọn vai trò.

Xác minh/gửi lại:

```json
{ "email": "sv@example.com", "otp": "123456" }
```

`resend-email` gửi `otp` rỗng. Email GV/CTV phải được xác minh sau khi giảng viên/admin tạo tài khoản.

Đăng nhập:

```json
{ "email": "sv@example.com", "password": "MatKhau!123" }
```

Response bước một:

```json
{ "message": "Đã gửi OTP tới email.", "email": "sv@example.com", "requiresOtp": true }
```

Gửi email/OTP qua `verify-login`, nhận:

```json
{ "token": "JWT", "role": "Student", "fullName": "Nguyễn Văn A", "email": "sv@example.com" }
```

OTP dùng Email token provider của ASP.NET Identity, kiểm tra ở backend và thay security stamp khi xác minh thành công để OTP không dùng lại. JWT hết hạn sau 8 giờ. Sai đăng nhập/OTP nhiều lần sẽ khóa theo Identity; các API auth giới hạn 15 lần/phút/IP.

## 2. Tài khoản GV/CTV và hồ sơ sinh viên

| Method | Endpoint | Quyền |
|---|---|---|
| GET | `/api/accounts` | Admin xem GV/CTV; GV xem CTV mình tạo |
| POST | `/api/accounts` | Admin chỉ tạo Lecturer; Lecturer chỉ tạo Collaborator |
| PUT | `/api/accounts/{userId}` | Admin/GV sở hữu: cập nhật họ tên, giữ email |
| DELETE | `/api/accounts/{userId}` | Admin/GV sở hữu; từ chối GV còn phụ trách lớp |
| GET | `/api/students` | Admin/Lecturer/Collaborator |
| POST | `/api/students` | Admin/Lecturer/Collaborator |
| PUT | `/api/students/{id}` | Admin/Lecturer |
| DELETE | `/api/students/{id}` | Admin/Lecturer, chỉ hồ sơ chưa liên kết và chưa được sử dụng |

Tạo GV/CTV:

```json
{ "email": "gv@example.com", "fullName": "Giảng viên A", "role": "Lecturer", "password": "MatKhau!123" }
```

Sửa tài khoản:

```json
{ "email": "gv@example.com", "fullName": "Giảng viên A đã sửa" }
```

Thêm/sửa hồ sơ SV:

```json
{ "studentCode": "SV001", "fullName": "Nguyễn Văn A", "email": "sv@example.com", "faculty": "CNTT" }
```

Không truyền `userId` từ frontend; backend tự liên kết khi sinh viên đăng ký bằng MSSV + email đúng hồ sơ. MSSV/email là duy nhất. Không đổi email/MSSV sau khi liên kết tài khoản.

## 3. Môn học, lớp, danh sách lớp, lịch học

| Method | Endpoint | Quyền/nội dung |
|---|---|---|
| GET | `/api/courses` | Người đã đăng nhập |
| POST | `/api/courses` | Admin/Lecturer |
| PUT/DELETE | `/api/courses/{id}` | Admin/Lecturer; không xóa môn còn có lớp |
| GET | `/api/classes` | Lọc lớp theo vai trò |
| POST | `/api/classes` | Admin/Lecturer |
| PUT/DELETE | `/api/classes/{id}` | Admin/GV phụ trách; không xóa lớp có lịch sử điểm danh |
| GET | `/api/classes/{id}/students` | Admin/GV phụ trách |
| POST | `/api/classes/{classId}/students/{studentId}` | Admin/GV phụ trách, thêm vào lớp |
| DELETE | `/api/classes/{classId}/students/{studentId}` | Admin/GV phụ trách, bỏ SV chưa có lịch sử trong lớp |
| GET | `/api/schedules` | Lọc theo lớp của người dùng |
| POST | `/api/schedules` | Admin/GV phụ trách |
| PUT/DELETE | `/api/schedules/{id}` | Admin/GV phụ trách |

Môn học:

```json
{ "code": "MOB101", "name": "Lập trình di động", "credits": 3 }
```

Lớp học (admin cần `lecturerUserId`; GV bỏ trường này, backend lấy từ JWT):

```json
{ "name": "LTDD01", "courseId": 1, "room": "A101", "lecturerUserId": "ID_TAI_KHOAN_GV" }
```

Lịch học:

```json
{ "classGroupId": 1, "startsAtUtc": "2026-10-21T00:00:00Z", "endsAtUtc": "2026-10-21T02:00:00Z", "room": "A101" }
```

Ví dụ trên tương ứng 07:00–09:00 tại Việt Nam. Flutter nhận giờ địa phương trong form rồi chuyển UTC khi gửi API.

## 4. Khuôn mặt

| Method | Endpoint | Nội dung |
|---|---|---|
| GET | `/api/face` | Student: `{ "registered": true/false }`, không trả vector đã lưu |
| PUT | `/api/face` | Student: tạo mới hoặc cập nhật mẫu khuôn mặt của chính mình |

Body: `{ "embedding": [...] }`, bắt buộc đúng **192 số hữu hạn**, norm khác 0. Mẫu từ MobileFaceNet 112×112, chuẩn hóa mỗi kênh `(pixel / 127.5) - 1`. Không nhận cờ `faceMatched: true` từ client.

## 5. Điểm danh

| Method | Endpoint | Nội dung |
|---|---|---|
| GET | `/api/attendance/sessions` | Admin/GV: danh sách phiên |
| POST | `/api/attendance/sessions` | Admin/GV phụ trách: mở phiên tại GPS hiện tại |
| PUT | `/api/attendance/sessions/{id}/close` | Admin/GV phụ trách: đóng phiên |
| POST | `/api/attendance/begin` | Student: kiểm tra QR, lớp, GPS; tạo challenge 10 giây |
| POST | `/api/attendance/mark` | Student: so khớp mặt và ghi nhận |
| GET | `/api/attendance/sessions/{id}/records` | Admin/GV phụ trách: danh sách lớp kèm record hoặc null |
| PUT | `/api/attendance/sessions/{id}/records/{studentId}` | Admin/GV phụ trách: điều chỉnh có mặt/vắng kèm lý do |
| GET | `/api/attendance/mine` | Student: lịch sử cá nhân |

Mở phiên:

```json
{ "classGroupId": 1, "latitude": 10.8, "longitude": 106.6, "durationMinutes": 10 }
```

Response là phiên có `id`, `qrToken`, `expiresAtUtc`, vị trí và lớp. Mã QR chỉ chứa `qrToken`.

Sau khi quét QR, kiểm tra GPS và camera đã sẵn sàng:

```json
{ "qrToken": "TOKEN_TU_QR", "latitude": 10.8, "longitude": 106.6 }
```

Gửi đến `/begin`, nhận:

```json
{ "challengeId": "ID_LUOT_QUET", "expiresAtUtc": "...", "seconds": 10 }
```

Trong 10 giây, `/mark` nhận `challengeId` và `embedding` 192 chiều mới lấy từ camera. Backend so khớp với mẫu đã lưu bằng cosine similarity, ngưỡng 0.70. Thành công:

```json
{ "message": "Điểm danh thành công: QR + GPS + khuôn mặt.", "similarity": 0.91 }
```

Challenge gắn với SV/phiên, chỉ dùng thành công một lần. Tạo challenge mới vô hiệu các challenge cũ chưa dùng của SV. Backend kiểm tra thời hạn và phiên còn mở, unique index bảo vệ một bản ghi/SV/phiên. GPS dùng Haversine với bán kính 150m.

Điều chỉnh kết quả:

```json
{ "present": false, "reason": "Giảng viên kiểm tra lại danh sách tại lớp" }
```

Lưu `Method=Manual:Present` hoặc `Manual:Absent` cùng `CorrectionReason`, `CorrectedByUserId`, `CorrectedAtUtc`; các trường này có trong record trả về. Bản ghi tự động có `Method=QR+GPS+Face`.

## 6. Mã lỗi

- `400`: dữ liệu không hợp lệ, QR/mẫu mặt không đúng, hết thời gian, ngoài bán kính.
- `401`: chưa đăng nhập, JWT hết hạn, mật khẩu/OTP không đúng.
- `403`: không đủ quyền, không phụ trách lớp hoặc SV không thuộc lớp.
- `404`: không tìm thấy dữ liệu.
- `409`: trùng dữ liệu hoặc dữ liệu đang được sử dụng.
- `429`: quá nhiều yêu cầu OTP.
- `503`: chưa gửi được email SMTP.

Xem thêm giới hạn bảo mật và checklist Android thật trong `HUONG_DAN_5_GIO.md`.

### Đăng nhập bằng mã sinh viên hoặc mã giảng viên

Trường `email` trong JSON của `/api/auth/login`, `/api/auth/verify-login`, `/api/auth/resend-email` và `/api/auth/verify-email` nhận MSSV (ví dụ `SV001`), mã giảng viên (ví dụ `GV001`) hoặc email. Giữ tên trường để tương thích client cũ. Mã không phân biệt hoa/thường và bỏ khoảng trắng hai đầu. Sinh viên cần liên kết tài khoản trước; OTP vẫn gửi tới email của tài khoản và phải xác minh email trước khi đăng nhập. Admin/cộng tác viên tiếp tục dùng email.
