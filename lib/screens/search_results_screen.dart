import 'dart:math';

import 'package:flutter/material.dart';
import '../api/google_books_api.dart';
import '../api/truyenfull_scraper.dart';
import '../api/open_library_api.dart';
import '../api/metruyenchu_scraper.dart';
import '../models/book.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';
import '../widgets/book_card.dart';
import '../widgets/loading_indicator.dart';
import 'book_detail_screen.dart';

class SearchResultsScreen extends StatefulWidget {
  final String query;
  final String? categorySearchKey; // Key tiếng Anh để search sâu

  const SearchResultsScreen({super.key, required this.query, this.categorySearchKey});

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  final GoogleBooksApi _googleApi = GoogleBooksApi();
  final TruyenFullScraper _truyenFullScraper = TruyenFullScraper();
  final OpenLibraryApi _openLibraryApi = OpenLibraryApi();
  final MetruyenchuScraper _metruyenchuScraper = MetruyenchuScraper();
  
  final DatabaseService _databaseService = DatabaseService();
  final ScrollController _scrollController = ScrollController();

  List<Book> _allBooks = [];
  List<Book> _queue = [];

  int _googleStartIndex = 0;
  int _truyenPage = 1;
  int _openLibraryPage = 1;
  int _metruyenPage = 1;

  bool _googleExhausted = false;
  bool _truyenExhausted = false;
  bool _openLibraryExhausted = false;
  bool _metruyenExhausted = false;

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
      _allBooks = [];
      _queue = [];
      _googleStartIndex = 0;
      _truyenPage = 1;
      _openLibraryPage = 1;
      _metruyenPage = 1;
      _googleExhausted = false;
      _truyenExhausted = false;
      _openLibraryExhausted = false;
      _metruyenExhausted = false;
      _hasMore = true;
    });

    try {
      // Nếu có categorySearchKey, ta sẽ ưu tiên tìm kiếm theo subject trên Google/OpenLib
      String googleQuery = widget.query;
      if (widget.categorySearchKey != null) {
        googleQuery = 'subject:${widget.categorySearchKey}';
      }

      final results = await Future.wait([
        _googleApi.searchBooks(googleQuery, startIndex: 0, maxResults: 15).catchError((e) => <Book>[]),
        _truyenFullScraper.searchBooks(widget.query, page: 1).catchError((e) => <Book>[]),
        _openLibraryApi.searchBooks(googleQuery, limit: 15, page: 1).catchError((e) => <Book>[]),
        _metruyenchuScraper.searchBooks(widget.query, page: 1).catchError((e) => <Book>[]),
      ]);

      final List<Book> googleBooks = results[0];
      final List<Book> truyenBooks = results[1];
      final List<Book> openLibBooks = results[2];
      final List<Book> metruyenBooks = results[3];

      final merged = <Book>[...googleBooks, ...truyenBooks, ...openLibBooks, ...metruyenBooks];
      
      _googleStartIndex = googleBooks.length;
      _truyenPage = 2;
      _openLibraryPage = 2;
      _metruyenPage = 2;

      _googleExhausted = googleBooks.isEmpty || googleBooks.length < 15;
      _truyenExhausted = truyenBooks.isEmpty;
      _openLibraryExhausted = openLibBooks.isEmpty;
      _metruyenExhausted = metruyenBooks.isEmpty;

      final int first = Constants.searchInitialBatchSize;
      if (merged.length > first) {
        _allBooks = merged.sublist(0, first);
        _queue = merged.sublist(first);
      } else {
        _allBooks = List.from(merged);
        _queue = [];
      }

      _hasMore = _queue.isNotEmpty || !_googleExhausted || !_truyenExhausted || !_openLibraryExhausted || !_metruyenExhausted;

      try {
        await _databaseService.saveSearchHistory(widget.query, _allBooks.length);
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
    String googleQuery = widget.query;
    if (widget.categorySearchKey != null) {
      googleQuery = 'subject:${widget.categorySearchKey}';
    }

    if (!_googleExhausted) {
      final batch = await _googleApi.searchBooks(googleQuery, startIndex: _googleStartIndex, maxResults: 15).catchError((e) => <Book>[]);
      if (batch.isEmpty) { _googleExhausted = true; await _fetchNextChunkIntoQueue(); return; }
      _googleStartIndex += batch.length;
      _queue.addAll(batch);
      if (batch.length < 15) _googleExhausted = true;
      return;
    }
    
    if (!_openLibraryExhausted) {
      final batch = await _openLibraryApi.searchBooks(googleQuery, limit: 15, page: _openLibraryPage).catchError((e) => <Book>[]);
      _openLibraryPage++;
      if (batch.isEmpty) { _openLibraryExhausted = true; await _fetchNextChunkIntoQueue(); return; }
      _queue.addAll(batch);
      return;
    }

    if (!_truyenExhausted) {
      final batch = await _truyenFullScraper.searchBooks(widget.query, page: _truyenPage).catchError((e) => <Book>[]);
      _truyenPage++;
      if (batch.isEmpty) { _truyenExhausted = true; await _fetchNextChunkIntoQueue(); return; }
      _queue.addAll(batch);
      return;
    }

    if (!_metruyenExhausted) {
      final batch = await _metruyenchuScraper.searchBooks(widget.query, page: _metruyenPage).catchError((e) => <Book>[]);
      _metruyenPage++;
      if (batch.isEmpty) { _metruyenExhausted = true; return; }
      _queue.addAll(batch);
    }
  }

  Future<void> _appendCount(int n) async {
    int need = n;
    while (need > 0) {
      if (_queue.isNotEmpty) {
        final take = min(need, _queue.length);
        _allBooks.addAll(_queue.sublist(0, take));
        _queue.removeRange(0, take);
        need -= take;
        continue;
      }
      if (_googleExhausted && _truyenExhausted && _openLibraryExhausted && _metruyenExhausted) break;
      final before = _queue.length;
      await _fetchNextChunkIntoQueue();
      if (_queue.length == before && _googleExhausted && _truyenExhausted && _openLibraryExhausted && _metruyenExhausted) break;
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _isLoadingMore || _isInitialLoading) return;
    setState(() => _isLoadingMore = true);
    try {
      await _appendCount(Constants.searchLoadMoreBatchSize);
      _hasMore = _queue.isNotEmpty || !_googleExhausted || !_truyenExhausted || !_openLibraryExhausted || !_metruyenExhausted;
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kết quả: "${widget.query}"'),
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
        child: Padding(padding: const EdgeInsets.all(16.0), child: Text('Lỗi: $_errorMessage')),
      );
    }
    if (_allBooks.isEmpty) {
      return Center(child: Text(Constants.noResults));
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _allBooks.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _allBooks.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        final book = _allBooks[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: BookCard(
            book: book,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => BookDetailScreen(book: book)),
              );
            },
          ),
        );
      },
    );
  }
}
