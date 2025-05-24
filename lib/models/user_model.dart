import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String role;
  final String? displayName;
  final String? photoURL;
  final DateTime? createdAt;
  final DateTime? lastSignInTime;

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    this.displayName,
    this.photoURL,
    this.createdAt,
    this.lastSignInTime,
  });

  factory UserModel.fromMap(Map<String, dynamic> data) {
    DateTime? parsedCreatedAt;
    if (data['createdAt'] is Timestamp) {
      parsedCreatedAt = (data['createdAt'] as Timestamp).toDate();
    } else if (data['createdAt'] is String) {
      try {
        parsedCreatedAt = DateTime.parse(data['createdAt']);
      } catch (e) {
        // print('Lỗi parse createdAt string: ${data['createdAt']} - $e'); // Bỏ comment debug
      }
    }

    DateTime? parsedLastSignInTime;
    if (data['lastSignInTime'] is Timestamp) {
      parsedLastSignInTime = (data['lastSignInTime'] as Timestamp).toDate();
    } else if (data['lastSignInTime'] is String) {
      try {
        parsedLastSignInTime = DateTime.parse(data['lastSignInTime']);
      } catch (e) {
        // print('Lỗi parse lastSignInTime string: ${data['lastSignInTime']} - $e'); // Bỏ comment debug
      }
    }

    return UserModel(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'user',
      displayName: data['displayName'],
      photoURL: data['photoURL'],
      createdAt: parsedCreatedAt,
      lastSignInTime: parsedLastSignInTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'role': role,
      'displayName': displayName,
      'photoURL': photoURL,
    };
  }
}