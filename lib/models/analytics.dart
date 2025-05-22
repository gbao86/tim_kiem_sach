import 'package:cloud_firestore/cloud_firestore.dart';

class AnalyticsData {
  final String id;
  final int searchCount;
  final String bookId;
  final String bookTitle;
  final DateTime timestamp;

  AnalyticsData({
    required this.id,
    required this.searchCount,
    required this.bookId,
    required this.bookTitle,
    required this.timestamp,
  });

  factory AnalyticsData.fromMap(Map<String, dynamic> data) {
    return AnalyticsData(
      id: data['id'] ?? '',
      searchCount: data['searchCount'] ?? 0,
      bookId: data['bookId'] ?? '',
      bookTitle: data['bookTitle'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'searchCount': searchCount,
      'bookId': bookId,
      'bookTitle': bookTitle,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}