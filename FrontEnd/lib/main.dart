import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const AttendanceApp());
}

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Điểm danh sinh viên',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      useMaterial3: true,
    ),
    home: const StartScreen(),
  );
}

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});
  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  bool loading = true;
  bool logged = false;
  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final p = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        logged = p.getString('token') != null;
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return logged
        ? const DashboardScreen()
        : LoginScreen(onLoggedIn: () => setState(() => logged = true));
  }
}
