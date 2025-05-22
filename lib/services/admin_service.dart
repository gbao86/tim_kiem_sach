import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/analytics.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<UserModel>> getAllUsers() async {
    final snapshot = await _firestore.collection('users').get();
    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data()))
        .toList();
  }

  Future<void> updateUserRole(String userId, String role) async {
    await _firestore.collection('users').doc(userId).update({'role': role});
  }

  Future<void> deleteUser(String userId) async {
    await _firestore.collection('users').doc(userId).delete();
  }

  Future<List<AnalyticsData>> getSearchAnalytics() async {
    final snapshot = await _firestore
        .collection('analytics')
        .orderBy('searchCount', descending: true)
        .limit(10)
        .get();
    return snapshot.docs
        .map((doc) => AnalyticsData.fromMap(doc.data()))
        .toList();
  }

  Future<List<AnalyticsData>> getTrafficAnalytics() async {
    final snapshot = await _firestore
        .collection('analytics')
        .orderBy('timestamp', descending: true)
        .limit(30)
        .get();
    return snapshot.docs
        .map((doc) => AnalyticsData.fromMap(doc.data()))
        .toList();
  }
}