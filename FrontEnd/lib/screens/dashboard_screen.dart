import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import 'attendance_screen.dart';
import 'face_camera_screen.dart';
import 'login_screen.dart';
import 'management_screen.dart';
import 'teaching_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String role = '', name = '';
  bool faceRegistered = false;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      role = preferences.getString('role') ?? '';
      name = preferences.getString('name') ?? '';
    });
    if (role == 'Student') {
      try {
        final status = await ApiService.request('GET', '/api/face');
        if (mounted) {
          setState(() => faceRegistered = status['registered'] == true);
        }
      } catch (e) {
        if (mounted) setState(() => error = e.toString());
      }
    }
  }

  void open(Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  Widget tile(String title, String subtitle, IconData icon, VoidCallback tap) =>
      Card(
        child: ListTile(
          leading: Icon(icon, color: Colors.indigo),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: tap,
        ),
      );
  void manage(String title, String endpoint) =>
      open(ManagementScreen(title: title, endpoint: endpoint, role: role));
  Future<void> registerFace() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => FaceCameraScreen(
          onEmbedding: (embedding) async {
            await ApiService.request(
              'PUT',
              '/api/face',
              body: {'embedding': embedding},
            );
          },
        ),
      ),
    );
    await load();
  }

  Future<void> history() async {
    try {
      final rows =
          (await ApiService.request('GET', '/api/attendance/mine'))['data']
              as List;
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Lịch sử điểm danh'),
          content: SizedBox(
            width: 400,
            child: ListView(
              shrinkWrap: true,
              children: rows.isEmpty
                  ? [const Text('Chưa có lượt điểm danh.')]
                  : rows
                        .map(
                          (r) => ListTile(
                            title: Text('Phiên #${r['sessionId']}'),
                            subtitle: Text(
                              '${r['attendedAtUtc']} UTC · ${r['method']}',
                            ),
                          ),
                        )
                        .toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleName =
        {
          'Admin': 'Quản trị viên',
          'Lecturer': 'Giảng viên',
          'Collaborator': 'Cộng tác viên',
          'Student': 'Sinh viên',
        }[role] ??
        'Đang tải';
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard $roleName'),
        actions: [
          IconButton(
            onPressed: () async {
              await ApiService.logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LoginScreen(onLoggedIn: () {}),
                  ),
                  (_) => false,
                );
              }
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Xin chào, $name',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text(roleName),
          const SizedBox(height: 20),
          if (error != null) Text(error!),
          if (role == 'Student') ...[
            tile(
              faceRegistered ? 'Cập nhật khuôn mặt' : 'Đăng ký khuôn mặt',
              faceRegistered
                  ? 'Đã có mẫu nhận diện'
                  : 'Cần đăng ký trước lần điểm danh đầu tiên',
              Icons.face,
              registerFace,
            ),
            tile(
              'Quét QR điểm danh',
              'GPS trong 150m · Khuôn mặt trong 10 giây',
              Icons.qr_code_scanner,
              () => open(const AttendanceScreen()),
            ),
            tile(
              'Lịch sử điểm danh',
              'Xem kết quả của bạn',
              Icons.history,
              history,
            ),
          ],
          if (role == 'Admin' || role == 'Lecturer') ...[
            tile(
              role == 'Admin'
                  ? 'Quản lý tài khoản giảng viên'
                  : 'Quản lý cộng tác viên',
              'Thêm, xem, sửa, xóa tài khoản',
              Icons.manage_accounts,
              () => manage('Tài khoản', '/api/accounts'),
            ),
            tile(
              'Môn học',
              'Thêm, sửa, xóa môn học',
              Icons.menu_book,
              () => manage('Môn học', '/api/courses'),
            ),
            tile(
              'Quản lý lớp',
              'Tạo lớp và phân công giảng viên',
              Icons.school,
              () => manage('Lớp học', '/api/classes'),
            ),
            tile(
              'Danh sách lớp và bảng điểm danh',
              'Ghi danh sinh viên, mở QR, xem và sửa kết quả',
              Icons.fact_check,
              () => open(const TeachingScreen()),
            ),
          ],
          if (role == 'Admin' || role == 'Lecturer' || role == 'Collaborator')
            tile(
              'Hồ sơ sinh viên',
              role == 'Collaborator'
                  ? 'Thêm hồ sơ MSSV và email cho sinh viên liên kết'
                  : 'Thêm, xem, sửa, xóa hồ sơ',
              Icons.people,
              () => manage('Sinh viên', '/api/students'),
            ),
          if (role.isNotEmpty)
            tile(
              'Lịch học',
              'Xem thời gian và phòng học',
              Icons.calendar_month,
              () => manage('Lịch học', '/api/schedules'),
            ),
        ],
      ),
    );
  }
}
