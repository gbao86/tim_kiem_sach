import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../models/favorite_book.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class FavoriteBooksScreen extends StatefulWidget {
  @override
  _FavoriteBooksScreenState createState() => _FavoriteBooksScreenState();
}

class _FavoriteBooksScreenState extends State<FavoriteBooksScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    if (!authService.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('Sách Yêu Thích')),
        body: _buildNotLoggedInView(context),
      );
    }

    return FutureBuilder<UserModel?>(
      future: authService.getCurrentUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Sách Yêu Thích')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: Text('Error loading user data: ${snapshot.error}')),
            body: Center(child: Text('Error loading user data: ${snapshot.error}')),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Sách Yêu Thích')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_off, size: 60, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Không tìm thấy thông tin người dùng trong Firestore. '
                        'Vui lòng thử đăng xuất và đăng nhập lại.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          );
        }

        final userModel = snapshot.data!;
        final String currentUserId = userModel.uid;

        return Scaffold(
          appBar: AppBar(title: const Text('Sách Yêu Thích')),
          body: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('users')
                .doc(currentUserId)
                .collection('favorites')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              final favorites = snapshot.data!.docs
                  .map((doc) => FavoriteBook.fromMap(doc.data() as Map<String, dynamic>))
                  .toList();

              if (favorites.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.favorite_border,
                        size: 80,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Bạn chưa có sách yêu thích nào.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: favorites.length,
                itemBuilder: (context, index) {
                  final book = favorites[index];
                  return ListTile(
                    title: Text(book.title),
                    subtitle: Text(book.author ?? ''),
                    leading: book.coverUrl != null && book.coverUrl!.isNotEmpty
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(4.0),
                      child: Image.network(
                        book.coverUrl!,
                        width: 50,
                        height: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.book),
                      ),
                    )
                        : const Icon(Icons.book, size: 50),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        final QuerySnapshot querySnapshot = await _firestore
                            .collection('users')
                            .doc(currentUserId)
                            .collection('favorites')
                            .where('bookId', isEqualTo: book.bookId)
                            .limit(1)
                            .get();

                        if (querySnapshot.docs.isNotEmpty) {
                          await querySnapshot.docs.first.reference.delete();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Đã xóa "${book.title}" khỏi sách yêu thích')),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Không tìm thấy sách để xóa')),
                          );
                        }
                      },
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildNotLoggedInView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.favorite_border,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'Bạn cần đăng nhập để xem sách yêu thích.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
            child: const Text('Đăng nhập'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}