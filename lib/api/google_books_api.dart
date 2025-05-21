import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/book.dart';
import '../utils/constants.dart';

class GoogleBooksApi {
  final String baseUrl = Constants.googleBooksBaseUrl;
  final int maxResults = Constants.maxResults;

  Future<List<Book>> searchBooks(String query) async {
    if (query.trim().isEmpty) {
      return [];
    }

    final encodedQuery = Uri.encodeComponent(query);
    final url = '$baseUrl?q=$encodedQuery&maxResults=$maxResults';

    try {
      final response = await http.get(Uri.parse(url));

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
      final response = await http.get(Uri.parse(url));

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