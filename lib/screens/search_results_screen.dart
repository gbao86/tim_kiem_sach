import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/google_books_api.dart';
import '../api/truyenfull_scraper.dart'; // Thêm dòng import bộ cào TruyenFull
import '../models/book.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';
import '../widgets/book_card.dart';
import '../widgets/loading_indicator.dart';
import 'book_detail_screen.dart';

class SearchResultsScreen extends StatefulWidget {
  final String query;

  SearchResultsScreen({required this.query});

  @override
  _SearchResultsScreenState createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  late Future<List<Book>> _booksFuture;

  // Khởi tạo cả 2 nguồn tìm kiếm
  final GoogleBooksApi _googleApi = GoogleBooksApi();
  final TruyenFullScraper _truyenFullScraper = TruyenFullScraper();

  final DatabaseService _databaseService = DatabaseService();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchBooks();
  }

  Future<void> _searchBooks() async {
    setState(() {
      _isSearching = true;
      _booksFuture = _fetchAllSources(); // Gọi hàm gom dữ liệu mới
    });

    try {
      final books = await _booksFuture;
      await _databaseService.saveSearchHistory(widget.query, books.length);
    } catch (e) {
      print('Error saving search history: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  // --- HÀM MỚI: TÌM KIẾM SONG SONG 2 NGUỒN ---
  Future<List<Book>> _fetchAllSources() async {
    // Dùng Future.wait để tìm kiếm cùng lúc, giúp app không bị chậm
    final List<List<Book>> results = await Future.wait([
      // Nguồn 1: Google Books (Bắt lỗi để app không sập nếu API có vấn đề)
      _googleApi.searchBooks(widget.query).catchError((e) {
        print('Lỗi Google Books: $e');
        return <Book>[];
      }),

      // Nguồn 2: TruyenFull
      _truyenFullScraper.searchBooks(widget.query).catchError((e) {
        print('Lỗi TruyenFull: $e');
        return <Book>[];
      }),
    ]);

    // Gom tất cả kết quả vào một danh sách duy nhất
    List<Book> combinedBooks = [];
    for (var list in results) {
      combinedBooks.addAll(list);
    }

    return combinedBooks;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kết quả tìm kiếm: "${widget.query}"'),
        elevation: 0,
      ),
      body: FutureBuilder<List<Book>>(
        future: _booksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && _isSearching) {
            return Center(child: LoadingIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 60,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Đã xảy ra lỗi: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _searchBooks,
                      child: Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    Constants.noResults,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Thử tìm kiếm với từ khóa khác',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          final books = snapshot.data!;
          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: BookCard(
                  book: book,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookDetailScreen(book: book),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}