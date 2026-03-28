import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import '../models/book.dart';

class MetruyenchuScraper {
  final String baseUrl = 'https://metruyenchu.com.vn';
  final Duration requestTimeout = const Duration(seconds: 8);

  final Map<String, String> headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
  };

  Future<List<Book>> searchBooks(String query, {int page = 1}) async {
    final List<Book> books = [];
    try {
      final String searchUrl = '$baseUrl/tim-kiem?keyword=${Uri.encodeComponent(query)}&page=$page';
      final response = await http.get(Uri.parse(searchUrl), headers: headers).timeout(requestTimeout);

      if (response.statusCode == 200) {
        var document = parser.parse(response.body);
        var bookElements = document.querySelectorAll('li.border-b');

        for (var element in bookElements) {
          var titleElement = element.querySelector('h3 a');
          String title = titleElement?.text.trim() ?? 'Không có tiêu đề';
          String detailUrl = titleElement?.attributes['href'] ?? '';
          if (!detailUrl.startsWith('http')) detailUrl = '$baseUrl$detailUrl';

          var authorElement = element.querySelector('.text-gray-600');
          String author = authorElement?.text.trim() ?? 'Đang cập nhật';

          var coverElement = element.querySelector('img');
          String coverUrl = coverElement?.attributes['src'] ?? '';

          var descElement = element.querySelector('.line-clamp-2');
          String description = descElement?.text.trim() ?? 'Đang cập nhật mô tả...';

          if (detailUrl.isNotEmpty) {
            books.add(Book(
              id: 'mtc_${Uri.parse(detailUrl).pathSegments.last}',
              title: title,
              authors: [author],
              description: description,
              thumbnail: coverUrl,
              previewLink: detailUrl,
              rating: 0.0,
              pageCount: 0,
              publishedDate: 'Mê Truyện Chữ',
              categories: ['Truyện Chữ'],
              publisher: 'MeTruyenChu',
              language: 'vi',
            ));
          }
        }
      }
    } catch (e) {
      print('Lỗi Metruyenchu: $e');
    }
    return books;
  }
}
