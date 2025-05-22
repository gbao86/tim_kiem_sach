import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AdminUserManagementScreen extends StatefulWidget {
  @override
  _AdminUserManagementScreenState createState() => _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  final AdminService _adminService = AdminService();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _authService.isAdmin(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!) {
          return Scaffold(
            body: Center(child: Text('Access denied: Admins only')),
          );
        }
        return Scaffold(
          appBar: AppBar(title: Text('User Management')),
          body: FutureBuilder<List<UserModel>>(
            future: _adminService.getAllUsers(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              final users = snapshot.data ?? [];
              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return ListTile(
                    title: Text(user.displayName ?? user.email),
                    subtitle: Text('Role: ${user.role}'),
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () async {
                        await _adminService.deleteUser(user.uid);
                        setState(() {});
                      },
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