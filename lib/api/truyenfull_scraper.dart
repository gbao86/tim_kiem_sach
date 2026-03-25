import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import '../models/book.dart';

class TruyenFullScraper {
  final String baseUrl = 'https://truyenfull.vision';

  // Fake thông tin trình duyệt cực chuẩn để không bị TruyenFull chặn
  final Map<String, String> headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
  };

  Future<List<Book>> searchBooks(String query) async {
    final List<Book> books = [];

    try {
      final String searchUrl = '$baseUrl/tim-kiem/?tukhoa=${Uri.encodeComponent(query)}';
      final response = await http.get(Uri.parse(searchUrl), headers: headers);

      if (response.statusCode == 200) {
        var document = parser.parse(response.body);
        var bookElements = document.querySelectorAll('.list-truyen .row');

        // BẢO VỆ CHỐNG CHẶN: Chỉ cào sâu tối đa 10 truyện đầu tiên
        // (Nếu cào cùng lúc 20-30 truyện, Cloudflare của TruyenFull sẽ tưởng app mình là bot DDOS và khóa IP)
        int limit = bookElements.length > 10 ? 10 : bookElements.length;

        List<Future<Book?>> detailFutures = [];

        for (int i = 0; i < limit; i++) {
          var element = bookElements[i];

          // Lấy các thông tin cơ bản ngoài trang tìm kiếm
          var titleElement = element.querySelector('.truyen-title a');
          String title = titleElement?.text.trim() ?? 'Không có tiêu đề';
          String detailUrl = titleElement?.attributes['href'] ?? '';

          var authorElement = element.querySelector('.author');
          String author = authorElement?.text.trim() ?? 'Đang cập nhật';

          var coverElement = element.querySelector('.lazyimg');
          String coverUrl = coverElement?.attributes['data-image'] ??
              coverElement?.attributes['data-src'] ??
              coverElement?.attributes['src'] ?? '';

          if (detailUrl.isNotEmpty) {
            // Đẩy nhiệm vụ "Cào sâu" vào danh sách chờ xử lý song song
            detailFutures.add(_fetchBookDetails(detailUrl, title, author, coverUrl));
          }
        }

        // Chạy song song tất cả các luồng cào chi tiết để tiết kiệm thời gian
        var detailedBooks = await Future.wait(detailFutures);

        for (var book in detailedBooks) {
          if (book != null) books.add(book);
        }
      } else {
        print('TruyenFull chặn truy cập: Mã ${response.statusCode}');
      }
    } catch (e) {
      print('Lỗi khi cào danh sách TruyenFull: $e');
    }

    return books;
  }

  // --- HÀM CÀO SÂU: VÀO TẬN TRANG CHI TIẾT ĐỂ LẤY THÊM INFO ---
  Future<Book?> _fetchBookDetails(String url, String title, String author, String coverUrl) async {
    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        var doc = parser.parse(response.body);

        // 1. Cào hàng chục THỂ LOẠI (Kiếm hiệp, Ngôn tình, Dị giới...)
        var genreElements = doc.querySelectorAll('.info a[itemprop="genre"]');
        List<String> categories = genreElements.map((e) => e.text.trim()).toList();
        if (categories.isEmpty) categories = ['Truyện Chữ'];

        // 2. Cào MÔ TẢ TRUYỆN siêu chi tiết
        var descElement = doc.querySelector('.desc-text');
        String description = descElement?.text.trim() ?? 'Đang cập nhật mô tả...';

        // 3. Cào ĐIỂM ĐÁNH GIÁ (Rate)
        double rating = 0.0;
        var ratingElement = doc.querySelector('span[itemprop="ratingValue"]');
        if (ratingElement != null) {
          double rawRating = double.tryParse(ratingElement.text.trim()) ?? 0.0;
          // TruyenFull chấm điểm hệ số 10, Google chấm hệ 5 -> Chia 2 để đồng bộ UI
          rating = rawRating / 2;
        }

        // 4. Cào TRẠNG THÁI (Đang ra / Hoàn thành)
        String status = 'Đang cập nhật';
        var infoElements = doc.querySelectorAll('.info div');
        for (var el in infoElements) {
          if (el.text.contains('Trạng thái:')) {
            status = el.text.replaceAll('Trạng thái:', '').trim();
            break;
          }
        }

        String bookId = 'tf_${Uri.parse(url).pathSegments.join('_')}';

        // Trả về dữ liệu Full HD không che
        return Book(
          id: bookId,
          title: title,
          authors: [author],
          description: description,
          thumbnail: coverUrl,
          previewLink: url,
          rating: rating,
          pageCount: 0, // Truyện chữ thường không có số trang cụ thể
          publishedDate: status, // Tận dụng field Ngày xuất bản để hiện Trạng thái truyện
          categories: categories,
          publisher: 'TruyenFull',
          language: 'vi',
        );
      }
    } catch (e) {
      print('Lỗi cào chi tiết ($url): $e');
    }

    // Nếu lỗi kết nối khi cào sâu, vẫn trả về dữ liệu cơ bản để không bị mất truyện
    return Book(
      id: 'tf_${Uri.parse(url).pathSegments.join('_')}',
      title: title,
      authors: [author],
      description: 'Lỗi tải mô tả chi tiết từ TruyenFull.',
      thumbnail: coverUrl,
      previewLink: url,
      rating: 0.0,
      pageCount: 0,
      publishedDate: 'Đang cập nhật',
      categories: ['Truyện Việt Nam'],
      publisher: 'TruyenFull',
      language: 'vi',
    );
  }
}