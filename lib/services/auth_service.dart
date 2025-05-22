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

  AuthService() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
      _updateLoginStatus(user != null);
      if (user != null) {
        _ensureUserDocumentExists(user);
      }
    });
  }

  User? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isLoading => _isLoading;

  Future<void> _ensureUserDocumentExists(User user) async {
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
    print('User document processed for ${user.email ?? user.uid}');
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
        await _ensureUserDocumentExists(userCredential.user!);
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
    }
    return null;
  }
}

/*
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

  AuthService() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
      _updateLoginStatus(user != null);
    });
  }

  User? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isLoading => _isLoading;

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
        final userDocRef = _firestore.collection('users').doc(userCredential.user!.uid);
        final userDocSnapshot = await userDocRef.get();

        // Tạo một map dữ liệu để cập nhật
        Map<String, dynamic> userDataToUpdate = {
          'uid': userCredential.user!.uid,
          'email': userCredential.user!.email,
          'displayName': userCredential.user!.displayName,
          'photoURL': userCredential.user!.photoURL,
          'lastSignInTime': FieldValue.serverTimestamp(),
        };

        // CHỈ ĐẶT 'role' là 'user' nếu nó CHƯA TỒN TẠI (hoặc không phải là 'admin')
        if (!userDocSnapshot.exists || userDocSnapshot.data()?['role'] == null) {
          // Nếu document chưa tồn tại hoặc trường 'role' chưa có, đặt mặc định là 'user'
          userDataToUpdate['role'] = 'user';
        }
        // else if (userDocSnapshot.data()?['role'] == 'admin') {
        //   // Nếu đã là admin, không làm gì, giữ nguyên
        // }
        // Ngược lại, nếu là user thông thường, giữ nguyên 'user'

        await userDocRef.set(
          userDataToUpdate,
          SetOptions(merge: true),
        );
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
    }
    return null;
  }
}
*/