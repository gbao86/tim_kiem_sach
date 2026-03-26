import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/admin_service.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../widgets/loading_indicator.dart';

class AdminUserManagementScreen extends StatefulWidget {
  @override
  _AdminUserManagementScreenState createState() => _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  final AdminService _adminService = AdminService();
  final AuthService _authService = AuthService();

  // Quản lý danh sách để Lọc/Sắp xếp tại chỗ (Local) mà không cần gọi API nhiều lần
  List<UserModel> _allUsers = [];
  List<UserModel> _displayedUsers = [];
  bool _isLoadingUsers = true;
  String _currentFilter = 'none'; // Các bộ lọc: 'none', 'az', 'newest', 'oldest', 'admin_only'

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoadingUsers = true);
    try {
      final users = await _adminService.getAllUsers();
      if (mounted) {
        setState(() {
          _allUsers = users;
          _applyFilter(_currentFilter); // Áp dụng lại bộ lọc hiện tại cho dữ liệu mới
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi tải dữ liệu: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoadingUsers = false);
    }
  }

  // --- LOGIC LỌC VÀ SẮP XẾP ---
  void _applyFilter(String filterType) {
    setState(() {
      _currentFilter = filterType;
      List<UserModel> tempList = List.from(_allUsers); // Tạo bản sao từ danh sách gốc

      switch (filterType) {
        case 'az':
          tempList.sort((a, b) {
            String nameA = (a.displayName?.isNotEmpty == true ? a.displayName! : a.email).toLowerCase();
            String nameB = (b.displayName?.isNotEmpty == true ? b.displayName! : b.email).toLowerCase();
            return nameA.compareTo(nameB);
          });
          break;
        case 'newest':
          tempList.sort((a, b) {
            DateTime dateA = a.createdAt ?? DateTime(1970);
            DateTime dateB = b.createdAt ?? DateTime(1970);
            return dateB.compareTo(dateA); // Giảm dần (Mới nhất lên đầu)
          });
          break;
        case 'oldest':
          tempList.sort((a, b) {
            DateTime dateA = a.createdAt ?? DateTime(9999);
            DateTime dateB = b.createdAt ?? DateTime(9999);
            return dateA.compareTo(dateB); // Tăng dần (Cũ nhất lên đầu)
          });
          break;
        case 'admin_only':
          tempList = tempList.where((u) => u.role == 'admin').toList();
          break;
        case 'none':
        default:
        // Giữ nguyên thứ tự gốc
          break;
      }
      _displayedUsers = tempList;
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Chưa xác định';
    return DateFormat('HH:mm - dd/MM/yyyy').format(date.toLocal());
  }

  // Helper để tạo các item trong menu lọc cho gọn đẹp
  PopupMenuItem<String> _buildFilterMenuItem(String value, IconData icon, String text) {
    final isSelected = _currentFilter == value;
    final primaryColor = Theme.of(context).primaryColor;
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: isSelected ? primaryColor : Colors.grey.shade600, size: 20),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              color: isSelected ? primaryColor : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showRoleUpdateDialog(UserModel user) {
    String? selectedRole = user.role;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Column(
            children: [
              Icon(Icons.admin_panel_settings_rounded, size: 48, color: Theme.of(context).primaryColor),
              const SizedBox(height: 12),
              const Text('Cập Nhật Phân Quyền', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    user.displayName ?? user.email,
                    style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: selectedRole == 'user' ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: selectedRole == 'user' ? Theme.of(context).primaryColor : Colors.grey.shade300),
                    ),
                    child: RadioListTile<String>(
                      title: const Text('Người dùng (User)', style: TextStyle(fontWeight: FontWeight.w600)),
                      value: 'user',
                      groupValue: selectedRole,
                      activeColor: Theme.of(context).primaryColor,
                      onChanged: (String? value) => setState(() => selectedRole = value),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: selectedRole == 'admin' ? Colors.green.withOpacity(0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: selectedRole == 'admin' ? Colors.green : Colors.grey.shade300),
                    ),
                    child: RadioListTile<String>(
                      title: const Text('Quản trị viên (Admin)', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.green)),
                      value: 'admin',
                      groupValue: selectedRole,
                      activeColor: Colors.green,
                      onChanged: (String? value) => setState(() => selectedRole = value),
                    ),
                  ),
                ],
              );
            },
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy', style: TextStyle(color: Colors.grey, fontSize: 16)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text('Cập nhật', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              onPressed: () async {
                if (selectedRole != null && selectedRole != user.role) {
                  try {
                    await _adminService.updateUserRole(user.uid, selectedRole!);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Đã cập nhật quyền thành: ${selectedRole!.toUpperCase()}')),
                      );
                      _loadUsers();
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                    }
                  }
                }
                if (mounted) Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteUser(UserModel user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Column(
            children: [
              Icon(Icons.warning_rounded, size: 48, color: Colors.redAccent),
              SizedBox(height: 12),
              Text('Cảnh báo xóa', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
            ],
          ),
          content: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(color: Colors.grey.shade800, fontSize: 16, height: 1.4),
              children: [
                const TextSpan(text: 'Bạn có chắc chắn muốn xóa vĩnh viễn người dùng\n'),
                TextSpan(text: '"${user.displayName ?? user.email}"', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                const TextSpan(text: ' khỏi hệ thống không? Hành động này không thể hoàn tác.'),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy', style: TextStyle(color: Colors.grey, fontSize: 16)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text('Xóa vĩnh viễn', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              onPressed: () async {
                try {
                  await _adminService.deleteUser(user.uid);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã xóa người dùng khỏi hệ thống')),
                    );
                    _loadUsers();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                  }
                }
                if (mounted) Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _authService.isAdmin(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: LoadingIndicator()));
        }
        if (!snapshot.hasData || !snapshot.data!) {
          return Scaffold(
            appBar: AppBar(title: const Text('Truy cập từ chối')),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.security, size: 64, color: Colors.redAccent),
                  SizedBox(height: 16),
                  Text('Chỉ dành cho Quản trị viên', style: TextStyle(fontSize: 18)),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: const Text('Quản Lý Người Dùng', style: TextStyle(fontWeight: FontWeight.bold)),
            elevation: 0,
            centerTitle: true,
            // --- ĐÃ THÊM: Nút Lọc và Sắp xếp ở góc phải AppBar ---
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.filter_list_rounded),
                tooltip: 'Sắp xếp & Lọc',
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                offset: const Offset(0, 50),
                onSelected: _applyFilter,
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  _buildFilterMenuItem('none', Icons.clear_all_rounded, 'Mặc định (Tất cả)'),
                  const PopupMenuDivider(),
                  _buildFilterMenuItem('az', Icons.sort_by_alpha_rounded, 'Tên A-Z'),
                  _buildFilterMenuItem('newest', Icons.new_releases_rounded, 'Tài khoản mới nhất'),
                  _buildFilterMenuItem('oldest', Icons.history_rounded, 'Tài khoản cũ nhất'),
                  const PopupMenuDivider(),
                  _buildFilterMenuItem('admin_only', Icons.admin_panel_settings_rounded, 'Chỉ hiện Quản trị viên'),
                ],
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: _isLoadingUsers
              ? const Center(child: LoadingIndicator())
              : _displayedUsers.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text('Không tìm thấy người dùng nào phù hợp', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
              ],
            ),
          )
              : RefreshIndicator(
            onRefresh: _loadUsers,
            child: ListView.separated(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              padding: const EdgeInsets.all(16),
              itemCount: _displayedUsers.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final user = _displayedUsers[index];
                final isAdmin = user.role == 'admin';

                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: isAdmin ? Colors.green.withOpacity(0.1) : Theme.of(context).primaryColor.withOpacity(0.1),
                              child: Text(
                                user.displayName?.isNotEmpty == true
                                    ? user.displayName![0].toUpperCase()
                                    : user.email.isNotEmpty == true
                                    ? user.email[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                    color: isAdmin ? Colors.green : Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20
                                    ,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.displayName ?? 'Chưa cập nhật tên',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user.email,
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isAdmin ? Colors.green.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                user.role?.toUpperCase() ?? 'USER',
                                style: TextStyle(
                                  color: isAdmin ? Colors.green.shade700 : Colors.blue.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(height: 1, thickness: 1),
                        ),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInfoRow(Icons.history_rounded, 'Online: ${_formatDate(user.lastSignInTime)}'),
                                  const SizedBox(height: 4),
                                  _buildInfoRow(Icons.app_registration_rounded, 'Tạo lúc: ${_formatDate(user.createdAt)}'),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Phân quyền',
                                  icon: Icon(Icons.shield_outlined, color: Theme.of(context).primaryColor),
                                  onPressed: () => _showRoleUpdateDialog(user),
                                  style: IconButton.styleFrom(backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1)),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  tooltip: 'Xóa người dùng',
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                                  onPressed: () => _confirmDeleteUser(user),
                                  style: IconButton.styleFrom(backgroundColor: Colors.redAccent.withOpacity(0.1)),
                                ),
                              ],
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}