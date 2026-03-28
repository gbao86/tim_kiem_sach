import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;
  bool _isLoading = false;

  /// Role đọc từ Firestore sau khi ghi/merge document (`user` hoặc `admin`).
  /// User mới không có doc → ghi `role: user` rồi gán vào đây.
  /// `null` khi đã đăng nhập nhưng chưa đồng bộ xong (ví dụ mở app có phiên sẵn).
  String? _firestoreRole;

  AuthService() {
    // Mỗi khi phiên đăng nhập thay đổi (đăng nhập / mở app đã có phiên / đăng xuất):
    // đồng bộ document `users/{uid}` trên Firestore và cập nhật [_firestoreRole].
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      if (user == null) {
        _firestoreRole = null;
        notifyListeners();
        _updateLoginStatus(false);
        return;
      }
      notifyListeners();
      _updateLoginStatus(true);
      _syncFirestoreRoleAfterEnsure(user);
    });
  }

  User? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isLoading => _isLoading;

  /// Role hiện tại từ Firebase (`user` / `admin`). Chỉ dùng khi [isRoleReady] == true.
  String? get firestoreRole => _firestoreRole;

  /// Đã có role từ Firestore để hiển thị Cài đặt (sau đăng nhập hoặc sau khi sync xong).
  bool get isRoleReady => !isLoggedIn || _firestoreRole != null;

  Future<void> _syncFirestoreRoleAfterEnsure(User user) async {
    final role = await _ensureUserDocumentExists(user);
    if (_user?.uid != user.uid) return;
    _firestoreRole = role;
    notifyListeners();
  }

  /// Tạo/cập nhật doc `users/{uid}`; user mới → `role: user`. Trả về role sau khi ghi (đọc lại từ server).
  Future<String> _ensureUserDocumentExists(User user) async {
    final userDocRef = _firestore.collection('users').doc(user.uid);
    final userDocSnapshot = await userDocRef.get();

    Map<String, dynamic> userDataToUpdate = {
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName ?? '',
      'photoURL': user.photoURL ?? '',
      'lastSignInTime': FieldValue.serverTimestamp(),
    };

    if (!userDocSnapshot.exists) {
      userDataToUpdate['role'] = 'user';
      userDataToUpdate['createdAt'] = FieldValue.serverTimestamp();
    } else {
      if (userDocSnapshot.data()?['role'] == null) {
        userDataToUpdate['role'] = 'user';
      }
    }

    await userDocRef.set(
      userDataToUpdate,
      SetOptions(merge: true),
    );

    final snap = await userDocRef.get();
    final raw = snap.data()?['role'];
    if (raw is String && raw.isNotEmpty) {
      return raw;
    }
    return 'user';
  }

  // --- HÀM MỚI: ĐĂNG NHẬP BẰNG EMAIL & MẬT KHẨU ---
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Ghi / cập nhật bản ghi user trên Firestore trước khi coi đăng nhập xong.
      // (authStateChanges cũng gọi _ensureUserDocumentExists — merge:true nên an toàn nếu chạy gần nhau.)
      if (cred.user != null) {
        _firestoreRole = await _ensureUserDocumentExists(cred.user!);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception('Failed to sign in with Email: $e');
    }
  }

  // --- HÀM MỚI: ĐĂNG KÝ BẰNG EMAIL & MẬT KHẨU ---
  Future<void> signUpWithEmailAndPassword(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (cred.user != null) {
        _firestoreRole = await _ensureUserDocumentExists(cred.user!);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception('Failed to sign up with Email: $e');
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      _isLoading = true;
      notifyListeners();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      if (userCredential.user != null) {
        _firestoreRole = await _ensureUserDocumentExists(userCredential.user!);
      }

      _isLoading = false;
      notifyListeners();
      return userCredential;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception('Failed to sign in with Google: $e');
    }
  }

  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _googleSignIn.signOut();
      await _auth.signOut();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception('Failed to sign out: $e');
    }
  }

  Future<void> _updateLoginStatus(bool isLoggedIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', isLoggedIn);
  }

  Future<bool> isAdmin() async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      return false;
    }

    if (_firestoreRole != null) {
      return _firestoreRole == 'admin';
    }

    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        return userData['role'] == 'admin';
      }
      return false;
    } catch (e) {
      print("Lỗi khi kiểm tra vai trò admin: $e");
      return false;
    }
  }

  Future<UserModel?> getCurrentUser() async {
    if (_user != null) {
      DocumentSnapshot doc = await _firestore.collection('users').doc(_user!.uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      if (_firestoreRole != null) {
        return UserModel(
          uid: _user!.uid,
          email: _user!.email ?? '',
          role: _firestoreRole!,
          displayName: _user!.displayName,
          photoURL: _user!.photoURL,
        );
      }
    }
    return null;
  }
}