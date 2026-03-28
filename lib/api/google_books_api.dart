import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/book.dart';
import '../utils/constants.dart';

class GoogleBooksApi {
  final String baseUrl = Constants.googleBooksBaseUrl;
  final int maxResults = Constants.maxResults;
  final Duration requestTimeout = const Duration(seconds: 8);

  /// [startIndex]: offset Google Books API (0-based). [maxResults]: tối đa 40 mỗi request.
  Future<List<Book>> searchBooks(
    String query, {
    int startIndex = 0,
    int? maxResults,
  }) async {
    if (query.trim().isEmpty) {
      return [];
    }

    final int count = (maxResults ?? this.maxResults).clamp(1, 40);
    final encodedQuery = Uri.encodeComponent(query);
    final url = '$baseUrl?q=$encodedQuery&startIndex=$startIndex&maxResults=$count';

    try {
      final response = await http.get(Uri.parse(url)).timeout(requestTimeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['totalItems'] != null && data['totalItems'] > 0 && data['items'] != null) {
          final List<dynamic> items = data['items'];
          return items.map((item) => Book.fromJson(item)).toList();
        } else {
          return [];
        }
      } else {
        throw Exception('Failed to load books. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching books: $e');
    }
  }

  Future<Book> getBookDetails(String bookId) async {
    final url = '$baseUrl/$bookId';

    try {
      final response = await http.get(Uri.parse(url)).timeout(requestTimeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Book.fromJson(data);
      } else {
        throw Exception('Failed to load book details. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting book details: $e');
    }
  }
}