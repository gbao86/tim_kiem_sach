import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../widgets/loading_indicator.dart'; // Đảm bảo bạn có widget này hoặc thay thế bằng CircularProgressIndicator

class AdminUserManagementScreen extends StatefulWidget {
  @override
  _AdminUserManagementScreenState createState() => _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  final AdminService _adminService = AdminService();
  final AuthService _authService = AuthService();
  Future<List<UserModel>>? _usersFuture;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() {
    setState(() {
      _usersFuture = _adminService.getAllUsers();
    });
  }

  // Hàm hiển thị hộp thoại xác nhận và cập nhật quyền
  void _showRoleUpdateDialog(UserModel user) {
    String? selectedRole = user.role; // Giữ quyền hiện tại làm giá trị mặc định

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Cập nhật quyền cho ${user.displayName ?? user.email}'),
          content: StatefulBuilder( // Sử dụng StatefulBuilder để cập nhật trạng thái radio buttons bên trong dialog
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  RadioListTile<String>(
                    title: const Text('Người dùng (user)'),
                    value: 'user',
                    groupValue: selectedRole,
                    onChanged: (String? value) {
                      setState(() {
                        selectedRole = value;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Quản trị viên (admin)'),
                    value: 'admin',
                    groupValue: selectedRole,
                    onChanged: (String? value) {
                      setState(() {
                        selectedRole = value;
                      });
                    },
                  ),
                ],
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Cập nhật'),
              onPressed: () async {
                if (selectedRole != null && selectedRole != user.role) {
                  try {
                    await _adminService.updateUserRole(user.uid, selectedRole!);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Cập nhật quyền thành công cho ${user.displayName ?? user.email}')),
                    );
                    _loadUsers(); // Tải lại danh sách người dùng sau khi cập nhật
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi cập nhật quyền: $e')),
                    );
                  }
                }
                Navigator.of(context).pop(); // Đóng hộp thoại
              },
            ),
          ],
        );
      },
    );
  }

  // Hàm xác nhận xóa người dùng
  void _confirmDeleteUser(UserModel user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận xóa người dùng'),
          content: Text('Bạn có chắc muốn xóa người dùng "${user.displayName ?? user.email}"?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Xóa'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                try {
                  await _adminService.deleteUser(user.uid);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Đã xóa người dùng ${user.displayName ?? user.email}')),
                  );
                  _loadUsers(); // Tải lại danh sách người dùng sau khi xóa
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi xóa người dùng: $e')),
                  );
                }
                Navigator.of(context).pop();
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
          return const Scaffold(
            body: Center(child: Text('Truy cập bị từ chối: Chỉ dành cho quản trị viên')),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text('Quản Trị Người Dùng'),
            backgroundColor: Colors.blueAccent,
          ),
          body: FutureBuilder<List<UserModel>>(
            future: _usersFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: LoadingIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Lỗi: ${snapshot.error}'));
              }
              final users = snapshot.data ?? [];
              if (users.isEmpty) {
                return const Center(child: Text('Không có người dùng nào.'));
              }
              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blueGrey,
                        child: Text(
                          user.displayName?.isNotEmpty == true
                              ? user.displayName![0].toUpperCase()
                              : user.email.isNotEmpty == true
                              ? user.email[0].toUpperCase()
                              : '?',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(user.displayName ?? user.email,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Email: ${user.email}'),
                          Text('Quyền: ${user.role}'),
                          Text('UID: ${user.uid}'),
                          if (user.createdAt != null)
                            Text('Tạo lúc: ${user.createdAt!.toLocal().toString().split('.')[0]}'),
                          if (user.lastSignInTime != null)
                            Text('Đăng nhập cuối: ${user.lastSignInTime!.toLocal().toString().split('.')[0]}'),
                        ],
                      ),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Nút cập nhật quyền
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onSelected: (String result) {
                              if (result == 'update_role') {
                                _showRoleUpdateDialog(user);
                              }
                            },
                            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                              const PopupMenuItem<String>(
                                value: 'update_role',
                                child: Text('Cập nhật quyền'),
                              ),
                            ],
                          ),
                          // Nút xóa người dùng
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _confirmDeleteUser(user),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}