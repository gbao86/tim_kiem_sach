import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../utils/theme_provider.dart';
import '../widgets/loading_indicator.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? userRole;
  bool isLoadingRole = true;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userModel = await authService.getCurrentUser();
    setState(() {
      userRole = userModel?.role ?? 'user';
      isLoadingRole = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authService = Provider.of<AuthService>(context);

    if (isLoadingRole || authService.isLoading) {
      return const Scaffold(
        body: LoadingIndicator(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Giao diện',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SwitchListTile(
              title: const Text('Chế độ tối'),
              value: themeProvider.isDarkMode,
              onChanged: (val) => themeProvider.toggleTheme(),
            ),
            const SizedBox(height: 30),
            const Text(
              'Tài khoản',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: Text(authService.user?.email ?? 'Chưa đăng nhập'),
              subtitle: Text('Quyền: ${userRole ?? 'user'}'),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Đăng xuất'),
              onTap: () async {
                await authService.signOut();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
            ),
            const SizedBox(height: 30),
            const Text(
              'Quản lý cá nhân',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ListTile(
              leading: const Icon(Icons.favorite),
              title: const Text('Sách yêu thích'),
              onTap: () => Navigator.pushNamed(context, '/favorites'),
            ),
            if (userRole == 'admin') ...[
              const SizedBox(height: 30),
              const Text(
                'Quản trị hệ thống',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ListTile(
                leading: const Icon(Icons.group),
                title: const Text('Quản lý người dùng'),
                onTap: () => Navigator.pushNamed(context, '/admin/users'),
              ),
              ListTile(
                leading: const Icon(Icons.analytics),
                title: const Text('Thống kê và biểu đồ'),
                onTap: () => Navigator.pushNamed(context, '/admin/analytics'),
              ),
              ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text('Gửi thông báo'),
                onTap: () => Navigator.pushNamed(context, '/admin/notifications'),
              ),
              ListTile(
                leading: const Icon(Icons.book),
                title: const Text('Cập nhật thông tin sách'),
                onTap: () => Navigator.pushNamed(context, '/admin/book-update'),
              ),
              ListTile(
                leading: const Icon(Icons.traffic),
                title: const Text('Lưu lượng truy cập'),
                onTap: () => Navigator.pushNamed(context, '/admin/traffic'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}