class SearchHistory {
  final String id;
  final String query;
  final DateTime timestamp;
  final int resultCount;

  SearchHistory({
    required this.id,
    required this.query,
    required this.timestamp,
    required this.resultCount,
  });

  factory SearchHistory.fromJson(Map<String, dynamic> json) {
    return SearchHistory(
      id: json['id'],
      query: json['query'],
      timestamp: (json['timestamp'] != null)
          ? (json['timestamp'] is DateTime
          ? json['timestamp']
          : DateTime.parse(json['timestamp'].toString()))
          : DateTime.now(),
      resultCount: json['resultCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'query': query,
      'timestamp': timestamp.toIso8601String(),
      'resultCount': resultCount,
    };
  }
}