import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../utils/theme_provider.dart';
import '../widgets/loading_indicator.dart';
import 'history_screen.dart';

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
    if (mounted) {
      setState(() {
        userRole = userModel?.role ?? 'user';
        isLoadingRole = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authService = Provider.of<AuthService>(context);
    final isDarkMode = themeProvider.isDarkMode;

    if (isLoadingRole || authService.isLoading) {
      return const Scaffold(body: LoadingIndicator());
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Cài đặt', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isDarkMode ? Colors.white : Colors.black87,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          children: [
            // 1. Profile Header
            _buildProfileHeader(authService, isDarkMode),
            const SizedBox(height: 24),

            // 2. Giao diện Section
            _buildSectionTitle('Giao diện'),
            _buildSettingsCard(children: [
              SwitchListTile(
                secondary: Icon(
                  isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  color: isDarkMode ? Colors.amber : Colors.blue,
                ),
                title: const Text('Chế độ tối', style: TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text(isDarkMode ? 'Đang bật' : 'Đang tắt'),
                value: isDarkMode,
                onChanged: (val) => themeProvider.toggleTheme(),
                activeColor: Colors.amber,
              ),
            ]),

            const SizedBox(height: 24),

            // 3. Quản lý cá nhân Section
            _buildSectionTitle('Quản lý cá nhân'),
            _buildSettingsCard(children: [
              _buildListTile(
                icon: Icons.favorite_rounded,
                color: Colors.redAccent,
                title: 'Sách yêu thích',
                onTap: () => Navigator.pushNamed(context, '/favorites'),
              ),
              _buildListTile(
                icon: Icons.history_rounded,
                color: Colors.blueAccent,
                title: 'Lịch sử tìm kiếm',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HistoryScreen()),
                  );
                },
              ),
              _buildListTile(
                icon: Icons.logout_rounded,
                color: Colors.grey,
                title: 'Đăng xuất',
                onTap: () async {
                  await authService.signOut();
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                },
              ),
            ]),

            // 4. Admin Section (Chỉ hiện nếu là admin)
            if (userRole == 'admin') ...[
              const SizedBox(height: 24),
              _buildSectionTitle('Quản trị hệ thống'),
              _buildSettingsCard(
                color: isDarkMode ? const Color(0xFF2C2C2C) : const Color(0xFFF5F9FF),
                children: [
                  _buildListTile(
                    icon: Icons.group_rounded,
                    color: Colors.indigo,
                    title: 'Quản lý người dùng',
                    onTap: () => Navigator.pushNamed(context, '/admin/users'),
                  ),
                  _buildListTile(
                    icon: Icons.analytics_rounded,
                    color: Colors.teal,
                    title: 'Thống kê và biểu đồ',
                    onTap: () => Navigator.pushNamed(context, '/admin/analytics'),
                  ),
                  _buildListTile(
                    icon: Icons.notifications_active_rounded,
                    color: Colors.orange,
                    title: 'Gửi thông báo',
                    onTap: () => Navigator.pushNamed(context, '/admin/notifications'),
                  ),
                  _buildListTile(
                    icon: Icons.traffic_rounded,
                    color: Colors.purple,
                    title: 'Lưu lượng truy cập',
                    onTap: () => Navigator.pushNamed(context, '/admin/traffic'),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPER ---

  Widget _buildProfileHeader(AuthService auth, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF303030), const Color(0xFF1A1A1A)]
              : [Colors.blue.shade400, Colors.blue.shade700],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(isDark ? 0 : 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: Colors.white24,
            backgroundImage: auth.user?.photoURL != null
                ? NetworkImage(auth.user!.photoURL!)
                : null,
            child: auth.user?.photoURL == null
                ? const Icon(Icons.person, size: 40, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  auth.user?.displayName ?? 'Người dùng Jisy',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  auth.user?.email ?? 'N/A',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    userRole?.toUpperCase() ?? 'USER',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children, Color? color}) {
    return Container(
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required Color color,
    required String title,
    required VoidCallback onTap
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      onTap: onTap,
    );
  }
}