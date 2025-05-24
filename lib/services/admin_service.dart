import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/user_model.dart';
import '../models/analytics.dart';
import '../models/stat_item.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  //Quyền lấy thông tin user
  Future<List<UserModel>> getAllUsers() async {
    final snapshot = await _firestore.collection('users').get();
    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data()))
        .toList();
  }

  //Quyền cập nhật quyền cho user, đã xong
  Future<void> updateUserRole(String userId, String role) async {
    await _firestore.collection('users').doc(userId).update({'role': role});
  }

  //Quyền xóa user, xong
  Future<void> deleteUser(String userId) async {
    await _firestore.collection('users').doc(userId).delete();
  }

  // Thống kê các từ khóa tìm kiếm phổ biến nhất trên toàn bộ hệ thống
  Future<List<StatItem>> getOverallMostFrequentKeywords() async {
    try {
      final querySnapshot = await _firestore
          .collectionGroup('search_history')
          .get();
      final queryCount = <String, int>{};
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final query = data['query'] as String;
        if (query.isNotEmpty) {
          queryCount[query.toLowerCase()] = (queryCount[query.toLowerCase()] ?? 0) + 1;
        }
      }

      final sortedKeywords = queryCount.entries.map((entry) =>
          StatItem(name: entry.key, count: entry.value))
          .toList()
        ..sort((a, b) => b.count.compareTo(a.count));

      return sortedKeywords;
    } catch (e) {
      print('Error fetching overall search keywords: $e');
      return [];
    }
  }
  //Thống kê lưu lượng tìm kiếm, lịch sử và sách iu thích của user💅, xong
  Future<List<AnalyticsData>> getTrafficAnalytics() async {
    try {
      final querySnapshot = await _firestore
          .collectionGroup('search_history')
          .orderBy('timestamp')
          .limit(30)
          .get();
      final dailyCount = <DateTime, int>{};
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final timestamp = DateTime.parse(data['timestamp'] as String);
        final date = DateTime(timestamp.year, timestamp.month, timestamp.day);
        dailyCount[date] = (dailyCount[date] ?? 0) + 1;
      }
      return dailyCount.entries.map((entry) {
        return AnalyticsData(
          id: '',
          bookId: '',
          bookTitle: '',
          searchCount: entry.value,
          timestamp: entry.key,
        );
      }).toList();
    } catch (e) {
      print('Error fetching traffic analytics: $e');
      return [];
    }
  }

  //Gửi thông báo đến tất cả người dùng, không được do phải mua bản trả phí =((
  Future<void> sendNotificationToAll(String title, String body) async {
    try {
      final callable = _functions.httpsCallable('sendNotificationToAllUsers');
      final HttpsCallableResult result = await callable.call(<String, dynamic>{
        'title': title,
        'body': body,
      });
      print('Notification sent successfully: ${result.data}');
    } catch (e) {
      print('Lỗi gửi thông báo: $e');
      rethrow;
    }
  }

  // Lấy lịch sử tìm kiếm của một người dùng cụ thể
  Future<List<Map<String, dynamic>>> getUserSearchHistory(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('search_history')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error fetching user search history: $e');
      return [];
    }
  }

  // Lấy danh sách sách yêu thích của một người dùng cụ thể
  Future<List<Map<String, dynamic>>> getUserFavoriteBooks(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error fetching user favorite books: $e');
      return [];
    }
  }

  // Thống kê sách được yêu thích nhất trên toàn bộ hệ thống
  Future<List<StatItem>> getOverallMostFavoriteBooks() async {
    try {
      final querySnapshot = await _firestore
          .collectionGroup('favorites')
          .get();
      final bookCount = <String, int>{};

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final bookTitle = data['title'] as String? ?? 'Không có tiêu đề';
        if (bookTitle.isNotEmpty) {
          bookCount[bookTitle] = (bookCount[bookTitle] ?? 0) + 1;
        }
      }

      final sortedBooks = bookCount.entries.map((entry) =>
          StatItem(name: entry.key, count: entry.value))
          .toList()
        ..sort((a, b) => b.count.compareTo(a.count));

      return sortedBooks;
    } catch (e) {
      print('Error fetching overall most favorite books: $e');
      return [];
    }
  }
}
