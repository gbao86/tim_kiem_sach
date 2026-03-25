import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../models/favorite_book.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../utils/theme_provider.dart';
import 'login_screen.dart';

class FavoriteBooksScreen extends StatefulWidget {
  const FavoriteBooksScreen({Key? key}) : super(key: key);

  @override
  _FavoriteBooksScreenState createState() => _FavoriteBooksScreenState();
}

class _FavoriteBooksScreenState extends State<FavoriteBooksScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);
    final isDark = themeProvider.isDarkMode;

    if (!authService.isLoggedIn) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: _buildAppBar(isDark),
        body: _buildNotLoggedInView(context, theme),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(isDark),
      body: FutureBuilder<UserModel?>(
        future: authService.getCurrentUser(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: theme.primaryColor));
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return _buildErrorView(context, theme, snapshot.error?.toString());
          }

          final String currentUserId = snapshot.data!.uid;

          return StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('users')
                .doc(currentUserId)
                .collection('favorites')
                .snapshots(),
            builder: (context, streamSnapshot) {
              if (streamSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(color: theme.primaryColor));
              }

              if (streamSnapshot.hasError) {
                return Center(child: Text('Lỗi tải dữ liệu: ${streamSnapshot.error}'));
              }

              final favorites = streamSnapshot.data!.docs
                  .map((doc) => FavoriteBook.fromMap(doc.data() as Map<String, dynamic>))
                  .toList();

              if (favorites.isEmpty) {
                return _buildEmptyView(context, theme);
              }

              return ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: favorites.length,
                itemBuilder: (context, index) {
                  final book = favorites[index];
                  return _buildBookCard(context, book, currentUserId, isDark);
                },
              );
            },
          );
        },
      ),
    );
  }

  // --- WIDGETS ---

  AppBar _buildAppBar(bool isDark) {
    return AppBar(
      title: Text(
        'Sách Yêu Thích',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      iconTheme: IconThemeData(
        color: isDark ? Colors.white : Colors.black87,
      ),
    );
  }

  Widget _buildBookCard(BuildContext context, FavoriteBook book, String userId, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Dismissible(
          key: Key(book.bookId),
          direction: DismissDirection.endToStart,
          // Hiện cảnh báo khi vuốt để xóa
          confirmDismiss: (direction) async {
            return await _showConfirmDeleteDialog(context, book);
          },
          background: Container(
            color: Colors.red.shade400,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            child: const Icon(Icons.delete_rounded, color: Colors.white, size: 28),
          ),
          onDismissed: (direction) => _deleteFavorite(book, userId),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: book.coverUrl != null && book.coverUrl!.isNotEmpty
                      ? Image.network(
                    book.coverUrl!,
                    width: 65,
                    height: 95,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                  )
                      : _buildPlaceholderImage(),
                ),
                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, height: 1.3),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        book.author?.isNotEmpty == true ? book.author! : 'Đang cập nhật',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                IconButton(
                  icon: Icon(Icons.favorite_rounded, color: Colors.redAccent.shade200),
                  tooltip: 'Bỏ yêu thích',
                  onPressed: () async {
                    // Hiện cảnh báo khi bấm nút trái tim
                    final confirm = await _showConfirmDeleteDialog(context, book);
                    if (confirm == true) {
                      _deleteFavorite(book, userId);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Hộp thoại xác nhận xóa
  Future<bool?> _showConfirmDeleteDialog(BuildContext context, FavoriteBook book) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Theme.of(context).cardColor,
        title: const Text(
          'Bỏ yêu thích',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text('Bạn có chắc chắn muốn xóa sách "${book.title}" khỏi danh sách yêu thích không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.redAccent,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Xác nhận xóa'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 65,
      height: 95,
      color: Colors.grey.withOpacity(0.1),
      child: const Icon(Icons.menu_book_rounded, color: Colors.grey),
    );
  }

  Widget _buildEmptyView(BuildContext context, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.favorite_border_rounded, size: 64, color: Colors.redAccent),
          ),
          const SizedBox(height: 24),
          Text(
            'Chưa có sách yêu thích',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Hãy thả tim những cuốn sách Jisy thích\nđể lưu vào đây nhé!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildNotLoggedInView(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.lock_person_rounded, size: 64, color: theme.primaryColor),
            ),
            const SizedBox(height: 24),
            Text(
              'Chưa đăng nhập',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Jisy cần đăng nhập để xem và quản lý\ndanh sách sách yêu thích của mình.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600, height: 1.5),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LoginScreen())),
              icon: const Icon(Icons.login_rounded),
              label: const Text('Đăng nhập ngay'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                elevation: 0,
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, ThemeData theme, String? errorMsg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 60, color: Colors.redAccent),
          const SizedBox(height: 16),
          Text(
            'Lỗi tải dữ liệu người dùng.\nVui lòng thử đăng xuất và đăng nhập lại.',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  // --- LOGIC ---

  Future<void> _deleteFavorite(FavoriteBook book, String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .where('bookId', isEqualTo: book.bookId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        await querySnapshot.docs.first.reference.delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã bỏ yêu thích "${book.title}"'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi xóa: $e')),
        );
      }
    }
  }
}