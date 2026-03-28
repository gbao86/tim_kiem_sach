import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/book.dart';

class OpenLibraryApi {
  final String baseUrl = 'https://openlibrary.org/search.json';
  final Duration requestTimeout = const Duration(seconds: 10);

  Future<List<Book>> searchBooks(String query, {int limit = 20, int page = 1}) async {
    if (query.trim().isEmpty) return [];

    final url = Uri.parse('$baseUrl?q=${Uri.encodeComponent(query)}&limit=$limit&page=$page');
    
    try {
      final response = await http.get(url).timeout(requestTimeout);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List docs = data['docs'] ?? [];
        
        return docs.map((doc) {
          final String coverId = doc['cover_i']?.toString() ?? '';
          final List authors = doc['author_name'] ?? ['Không rõ tác giả'];
          
          return Book(
            id: 'ol_${doc['key']?.toString().replaceAll('/works/', '') ?? DateTime.now().millisecondsSinceEpoch}',
            title: doc['title'] ?? 'Không rõ tiêu đề',
            authors: List<String>.from(authors),
            description: 'Số bản in: ${doc['edition_count'] ?? 0}. Xuất bản lần đầu: ${doc['first_publish_year'] ?? 'N/A'}. Nhà xuất bản: ${(doc['publisher'] as List?)?.first ?? 'N/A'}',
            thumbnail: coverId.isNotEmpty 
                ? 'https://covers.openlibrary.org/b/id/$coverId-M.jpg' 
                : 'https://via.placeholder.com/128x192.png?text=No+Cover',
            publisher: (doc['publisher'] as List?)?.first ?? 'N/A',
            publishedDate: doc['first_publish_year']?.toString() ?? 'N/A',
            pageCount: doc['number_of_pages_median'] ?? 0,
            categories: List<String>.from(doc['subject']?.take(3).toList() ?? ['Sách ngoại văn']),
            language: (doc['language'] as List?)?.first ?? 'en',
            previewLink: 'https://openlibrary.org${doc['key']}',
            rating: 0.0,
          );
        }).toList();
      }
    } catch (e) {
      print('Lỗi OpenLibrary: $e');
    }
    return [];
  }
}
