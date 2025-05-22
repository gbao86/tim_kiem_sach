class Book {
  final String id;
  final String title;
  final List<String> authors;
  final String description;
  final String thumbnail;
  final String publisher;
  final String publishedDate;
  final int pageCount;
  final List<String> categories;
  final String language;
  final String previewLink;
  final double rating;

  Book({
    required this.id,
    required this.title,
    required this.authors,
    required this.description,
    required this.thumbnail,
    required this.publisher,
    required this.publishedDate,
    required this.pageCount,
    required this.categories,
    required this.language,
    required this.previewLink,
    required this.rating,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    final volumeInfo = json['volumeInfo'] ?? {};
    final imageLinks = volumeInfo['imageLinks'] ?? {};

    return Book(
      id: json['id'] ?? '',
      title: volumeInfo['title'] ?? 'Không có tiêu đề',
      authors: List<String>.from(volumeInfo['authors'] ?? ['Không rõ tác giả']),
      description: volumeInfo['description'] ?? 'Không có mô tả',
      thumbnail: imageLinks['thumbnail'] ?? 'https://via.placeholder.com/128x192.png?text=No+Image',
      publisher: volumeInfo['publisher'] ?? 'Không rõ nhà xuất bản',
      publishedDate: volumeInfo['publishedDate'] ?? 'Không rõ ngày xuất bản',
      pageCount: volumeInfo['pageCount'] ?? 0,
      categories: List<String>.from(volumeInfo['categories'] ?? []),
      language: volumeInfo['language'] ?? 'Không rõ',
      previewLink: volumeInfo['previewLink'] ?? '',
      rating: (volumeInfo['averageRating'] != null)
          ? (volumeInfo['averageRating'] as num).toDouble()
          : 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'authors': authors,
      'description': description,
      'thumbnail': thumbnail,
      'publisher': publisher,
      'publishedDate': publishedDate,
      'pageCount': pageCount,
      'categories': categories,
      'language': language,
      'previewLink': previewLink,
      'rating': rating,
    };
  }
}