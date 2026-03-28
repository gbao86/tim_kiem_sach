import 'dart:math';

import 'package:flutter/material.dart';
import '../api/google_books_api.dart';
import '../api/truyenfull_scraper.dart';
import '../models/book.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';
import '../widgets/book_card.dart';
import '../widgets/loading_indicator.dart';
import 'book_detail_screen.dart';

class SearchResultsScreen extends StatefulWidget {
  final String query;

  const SearchResultsScreen({super.key, required this.query});

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  final GoogleBooksApi _googleApi = GoogleBooksApi();
  final TruyenFullScraper _truyenFullScraper = TruyenFullScraper();
  final DatabaseService _databaseService = DatabaseService();
  final ScrollController _scrollController = ScrollController();

  List<Book> _books = [];
  List<Book> _queue = [];
  int _googleStartIndex = 0;
  int _truyenPage = 1;
  bool _googleExhausted = false;
  bool _truyenExhausted = false;

  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitial();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _isLoadingMore || _isInitialLoading) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 240) {
      _loadMore();
    }
  }

  Future<void> _loadInitial() async {
    setState(() {
      _isInitialLoading = true;
      _errorMessage = null;
      _books = [];
      _queue = [];
      _googleStartIndex = 0;
      _truyenPage = 1;
      _googleExhausted = false;
      _truyenExhausted = false;
      _hasMore = true;
    });

    try {
      final List<Book> googleBooks = await _googleApi
          .searchBooks(
            widget.query,
            startIndex: 0,
            maxResults: Constants.searchInitialBatchSize,
          )
          .catchError((e) {
        debugPrint('Lỗi Google Books: $e');
        return <Book>[];
      });

      final List<Book> truyenBooks = await _truyenFullScraper
          .searchBooks(widget.query, fetchDetails: false, page: 1)
          .catchError((e) {
        debugPrint('Lỗi TruyenFull: $e');
        return <Book>[];
      });

      final merged = <Book>[...googleBooks, ...truyenBooks];
      _googleStartIndex = googleBooks.length;
      _truyenPage = 2;
      // Hết Google khi không có kết quả hoặc API trả ít hơn số đã xin → không còn trang sau.
      _googleExhausted = googleBooks.isEmpty ||
          googleBooks.length < Constants.searchInitialBatchSize;
      _truyenExhausted = truyenBooks.isEmpty;

      final int first = Constants.searchInitialBatchSize;
      if (merged.length > first) {
        _books = merged.sublist(0, first);
        _queue = merged.sublist(first);
      } else {
        _books = List.from(merged);
        _queue = [];
      }

      _hasMore = _queue.isNotEmpty || !_googleExhausted || !_truyenExhausted;

      try {
        await _databaseService.saveSearchHistory(widget.query, _books.length);
      } catch (e) {
        debugPrint('Error saving search history: $e');
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      if (mounted) {
        setState(() => _isInitialLoading = false);
      }
    }
  }

  Future<void> _fetchNextChunkIntoQueue() async {
    if (!_googleExhausted) {
      final batch = await _googleApi
          .searchBooks(widget.query, startIndex: _googleStartIndex, maxResults: Constants.maxResults)
          .catchError((e) {
        debugPrint('Lỗi Google Books (load thêm): $e');
        return <Book>[];
      });
      if (batch.isEmpty) {
        _googleExhausted = true;
        await _fetchNextChunkIntoQueue();
        return;
      }
      _googleStartIndex += batch.length;
      _queue.addAll(batch);
      if (batch.length < Constants.maxResults) {
        _googleExhausted = true;
      }
      return;
    }
    if (!_truyenExhausted) {
      final batch = await _truyenFullScraper
          .searchBooks(widget.query, fetchDetails: false, page: _truyenPage)
          .catchError((e) {
        debugPrint('Lỗi TruyenFull (load thêm): $e');
        return <Book>[];
      });
      _truyenPage++;
      if (batch.isEmpty) {
        _truyenExhausted = true;
        return;
      }
      _queue.addAll(batch);
    }
  }

  Future<void> _appendCount(int n) async {
    int need = n;
    while (need > 0) {
      if (_queue.isNotEmpty) {
        final take = min(need, _queue.length);
        _books.addAll(_queue.sublist(0, take));
        _queue.removeRange(0, take);
        need -= take;
        continue;
      }
      if (_googleExhausted && _truyenExhausted) break;
      final before = _queue.length;
      await _fetchNextChunkIntoQueue();
      if (_queue.length == before && _googleExhausted && _truyenExhausted) break;
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _isLoadingMore || _isInitialLoading) return;
    setState(() => _isLoadingMore = true);
    try {
      await _appendCount(Constants.searchLoadMoreBatchSize);
      _hasMore = _queue.isNotEmpty || !_googleExhausted || !_truyenExhausted;
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kết quả tìm kiếm: "${widget.query}"'),
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isInitialLoading) {
      return const Center(child: LoadingIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 60),
              const SizedBox(height: 16),
              Text(
                'Đã xảy ra lỗi: $_errorMessage',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadInitial,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }
    if (_books.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              Constants.noResults,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Thử tìm kiếm với từ khóa khác',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _books.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _books.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: _isLoadingMore
                  ? const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      'Kéo để tải thêm',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
            ),
          );
        }
        final book = _books[index];
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
  }
}
