import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/search_history.dart';
import '../utils/constants.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = Uuid();

  // Reference to current user's search history
  CollectionReference<Map<String, dynamic>>? _getHistoryCollection() {
    final user = _auth.currentUser;
    if (user == null) return null;

    return _firestore
        .collection(Constants.usersCollection)
        .doc(user.uid)
        .collection(Constants.historyCollection);
  }

  // Save search query to history
  Future<void> saveSearchHistory(String query, int resultCount) async {
    final historyCollection = _getHistoryCollection();
    if (historyCollection == null) return;

    final searchHistory = SearchHistory(
      id: _uuid.v4(),
      query: query,
      timestamp: DateTime.now(),
      resultCount: resultCount,
    );

    await historyCollection.doc(searchHistory.id).set(searchHistory.toJson());
  }

  // Get search history
  Stream<List<SearchHistory>> getSearchHistory() {
    final historyCollection = _getHistoryCollection();
    if (historyCollection == null) {
      return Stream.value([]);
    }

    return historyCollection
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => SearchHistory.fromJson(doc.data()))
          .toList();
    });
  }

  // Clear search history
  Future<void> clearSearchHistory() async {
    final historyCollection = _getHistoryCollection();
    if (historyCollection == null) return;

    final batch = _firestore.batch();
    final querySnapshot = await historyCollection.get();

    for (var doc in querySnapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  // Delete a single search history entry
  Future<void> deleteSearchHistoryItem(String id) async {
    final historyCollection = _getHistoryCollection();
    if (historyCollection == null) return;

    await historyCollection.doc(id).delete();
  }
}