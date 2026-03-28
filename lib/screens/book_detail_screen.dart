import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import 'book_reader_screen.dart';
import '../api/truyenfull_scraper.dart';
import '../models/book.dart';
import '../widgets/loading_indicator.dart';
import '../services/auth_service.dart';
import '../models/favorite_book.dart';

class BookDetailScreen extends StatefulWidget {
  final Book book;
  const BookDetailScreen({super.key, required this.book});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  bool _isFavorite = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = Uuid();
  late Book _book;
  bool _isLoadingTruyenFullDetails = false;
  final TruyenFullScraper _truyenFullScraper = TruyenFullScraper();

  @override
  void initState() {
    super.initState();
    _book = widget.book;
    _checkIfFavorite();
    _maybeLoadTruyenFullDetails();
  }

  Future<void> _maybeLoadTruyenFullDetails() async {
    if (_book.publisher != 'TruyenFull') return;
    if (_book.previewLink.isEmpty) return;

    setState(() => _isLoadingTruyenFullDetails = true);
    try {
      final detailed = await _truyenFullScraper.fetchDetailsFromUrl(
        _book.previewLink,
        title: _book.title,
        author: _book.authors.isNotEmpty ? _book.authors.first : null,
        coverUrl: _book.thumbnail,
      );
      if (!mounted) return;
      if (detailed != null) {
        setState(() => _book = detailed);
      }
    } finally {
      if (mounted) setState(() => _isLoadingTruyenFullDetails = false);
    }
  }

  Future<void> _checkIfFavorite() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.user;

    if (currentUser != null) {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('favorites')
          .where('bookId', isEqualTo: widget.book.id)
          .limit(1)
          .get();

      if (mounted) {
        setState(() {
          _isFavorite = querySnapshot.docs.isNotEmpty;
        });
      }
    }
  }

  Future<void> _toggleFavorite() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.user;

    if (currentUser == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn cần đăng nhập để thêm vào yêu thích.')),
      );
      return;
    }

    HapticFeedback.mediumImpact();

    final userFavoritesRef = _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('favorites');

    if (_isFavorite) {
      final querySnapshot = await userFavoritesRef
          .where('bookId', isEqualTo: widget.book.id)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        await querySnapshot.docs.first.reference.delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa khỏi danh sách yêu thích')),
          );
        }
      }
    } else {
      final favoriteBook = FavoriteBook(
        id: _uuid.v4(),
        userId: currentUser.uid,
        bookId: widget.book.id,
        title: widget.book.title,
        author: widget.book.authors.join(', '),
        coverUrl: widget.book.thumbnail,
      );
      await userFavoritesRef.add(favoriteBook.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã thêm vào danh sách yêu thích')),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isFavorite = !_isFavorite;
      });
    }
  }

  Future<void> _shareBook() async {
    try {
      final String title = _book.title;
      final String authors = _book.authors.isNotEmpty ? _book.authors.join(', ') : 'Tác giả không rõ';
      final String description = _book.description.isNotEmpty
          ? (_book.description.length > 200 ? '${_book.description.substring(0, 200)}...' : _book.description)
          : 'Không có mô tả';
      final String previewLink = _book.previewLink.isNotEmpty ? _book.previewLink : 'Không có liên kết';

      final String shareText =
          "Hãy xem cuốn sách này: '$title' của $authors.\n"
          "Mô tả: $description\n"
          "Link preview: $previewLink";

      await Share.share(
        shareText,
        subject: 'Đề xuất sách: $title',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi chia sẻ: $e')),
      );
    }
  }

  Future<void> _launchPreviewLink() async {
    if (_book.previewLink.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có bản đọc thử cho cuốn sách này.')),
      );
      return;
    }

    String secureUrl = _book.previewLink;
    if (secureUrl.startsWith('http://')) {
      secureUrl = secureUrl.replaceFirst('http://', 'https://');
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookReaderScreen(
          title: _book.title,
          url: secureUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _book.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 3.0,
                      color: Color.fromARGB(255, 0, 0, 0),
                    ),
                  ],
                ),
                overflow: TextOverflow.ellipsis,
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'book-cover-${widget.book.id}',
                    child: CachedNetworkImage(
                      imageUrl: _book.thumbnail,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => LoadingIndicator(),
                      errorWidget: (context, url, error) => Image.network(
                        'https://via.placeholder.com/400x600.png?text=No+Image',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: _shareBook,
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: CachedNetworkImage(
                          imageUrl: _book.thumbnail,
                          width: 120,
                          height: 180,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 120,
                            height: 180,
                            color: Colors.grey[300],
                            child: const Center(child: LoadingIndicator()),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 120,
                            height: 180,
                            color: Colors.grey[300],
                            child: const Icon(Icons.error),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _book.title,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tác giả: ${_book.authors.join(', ')}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            if (_book.rating > 0)
                              Row(
                                children: [
                                  ...List.generate(5, (index) {
                                    return Icon(
                                      index < _book.rating.floor()
                                          ? Icons.star
                                          : (index < _book.rating)
                                          ? Icons.star_half
                                          : Icons.star_border,
                                      color: Colors.amber,
                                      size: 20,
                                    );
                                  }),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${_book.rating}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 8),
                            Text(
                              'Nhà xuất bản: ${_book.publisher}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Ngày xuất bản: ${_book.publishedDate}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Số trang: ${_book.pageCount}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (_isLoadingTruyenFullDetails)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        children: [
                          SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                          SizedBox(width: 10),
                          Text('Đang tải chi tiết...'),
                        ],
                      ),
                    ),
                  Text(
                    'Mô tả',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _book.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  if (_book.categories.isNotEmpty) ...[
                    Text(
                      'Thể loại',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _book.categories.map((cat) {
                        return Chip(
                          label: Text(cat),
                          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                          labelStyle: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],
                  const SizedBox(height: 100), // Khoảng trống cho Bottom Bar
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: _toggleFavorite,
                  icon: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite ? Colors.red : Colors.grey[700],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _launchPreviewLink,
                    icon: const Icon(Icons.menu_book),
                    label: const Text(
                      'BẮT ĐẦU ĐỌC',
                      style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
