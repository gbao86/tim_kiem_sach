class FavoriteBook {
  final String id;
  final String userId;
  final String bookId;
  final String title;
  final String? author;
  final String? coverUrl;

  FavoriteBook({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.title,
    this.author,
    this.coverUrl,
  });

  factory FavoriteBook.fromMap(Map<String, dynamic> data) {
    return FavoriteBook(
      id: data['id'] ?? '',
      userId: data['userId'] ?? '',
      bookId: data['bookId'] ?? '',
      title: data['title'] ?? '',
      author: data['author'],
      coverUrl: data['coverUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'bookId': bookId,
      'title': title,
      'author': author,
      'coverUrl': coverUrl,
    };
  }
}