import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

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

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
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
      final String title = widget.book.title ?? 'Cuốn sách không tên';
      final String authors = widget.book.authors.isNotEmpty ? widget.book
          .authors.join(', ') : 'Tác giả không rõ';
      final String description = widget.book.description?.isNotEmpty ?? false
          ? (widget.book.description!.length > 200 ? '${widget.book.description!
          .substring(0, 200)}...' : widget.book.description!)
          : 'Không có mô tả';
      final String previewLink = widget.book.previewLink.isNotEmpty ? widget
          .book.previewLink : 'Không có liên kết';

      final String shareText =
          "Hãy xem cuốn sách này: '$title' của $authors.\n"
          "Mô tả: $description\n"
          "Link preview: $previewLink";

      await SharePlus.instance.share(ShareParams(
        text: shareText,
        subject: 'Đề xuất sách: $title',
      ));
    }
      catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi chia sẻ: $e')),
      );
    }
  }

  Future<void> _launchPreviewLink() async {
    if (widget.book.previewLink.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có liên kết xem trước cho cuốn sách này.')),
      );
      return;
    }

    print('Preview Link: ${widget.book.previewLink}');
    try {
      final Uri url = Uri.parse(widget.book.previewLink.startsWith('http') ? widget.book.previewLink : 'https://${widget.book.previewLink}');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể mở liên kết xem trước. Liên kết không hợp lệ.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      print('Launch Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi mở liên kết: $e')),
      );
    }
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
                widget.book.title,
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
                      imageUrl: widget.book.thumbnail,
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
                          Colors.black.withValues(alpha: 0.7),
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
                          imageUrl: widget.book.thumbnail,
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
                              widget.book.title,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tác giả: ${widget.book.authors.join(', ')}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            if (widget.book.rating > 0)
                              Row(
                                children: [
                                  ...List.generate(5, (index) {
                                    return Icon(
                                      index < widget.book.rating.floor()
                                          ? Icons.star
                                          : (index < widget.book.rating)
                                          ? Icons.star_half
                                          : Icons.star_border,
                                      color: Colors.amber,
                                      size: 20,
                                    );
                                  }),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${widget.book.rating}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 8),
                            Text(
                              'Nhà xuất bản: ${widget.book.publisher}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Ngày xuất bản: ${widget.book.publishedDate}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Số trang: ${widget.book.pageCount}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Mô tả',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.book.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  if (widget.book.categories.isNotEmpty) ...[
                    Text(
                      'Thể loại',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.book.categories.map((category) {
                        return Chip(
                          label: Text(category),
                          backgroundColor: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                          labelStyle: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _launchPreviewLink,
                  icon: const Icon(Icons.remove_red_eye),
                  label: const Text('Xem trước'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _toggleFavorite,
                  icon: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite ? Colors.red : null,
                  ),
                  label: Text(_isFavorite ? 'Đã yêu thích' : 'Yêu thích'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
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