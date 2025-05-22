class UserModel {
  final String uid;
  final String email;
  final String role; // 'admin' or 'user'
  final String? displayName;

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    this.displayName,
  });

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'user',
      displayName: data['displayName'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'role': role,
      'displayName': displayName,
    };
  }
}