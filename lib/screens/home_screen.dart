import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';
import '../services/auth_service.dart';
import '../utils/theme_provider.dart';
import '../widgets/search_bar.dart';
import '../models/book.dart';
import '../api/google_books_api.dart';
import '../api/truyenfull_scraper.dart';
import 'search_results_screen.dart';
import 'book_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  final TextEditingController _searchController = TextEditingController();

  Future<List<Book>>? _recommendedBooks;
  String _currentSuggestKeyword = '';

  final List<String> _categories = [
    'Đam Mỹ', 'Tiên Hiệp', 'Kiếm Hiệp', 'Ngôn Tình', 'Xuyên Không', 'Hài Hước',
    'Hồi hộp', 'Kinh Dị', 'Trinh Thám', 'Mạt Thế', 'Quan Trường', 'Võng Du',
    'Linh Dị', 'Khoa Huyễn', 'Hệ Thống', 'Sủng', 'Ngược',
    'Dị Giới', 'Dị Năng', 'Cung Đấu', 'Nữ Cường', 'Gia Đấu',
    'Đông Phương', 'Đô Thị', 'Bách Hợp', 'Lịch Sử', 'Quân Sự'
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        // Lần đầu load sẽ ưu tiên lấy từ lịch sử Firebase
        _recommendedBooks = _loadPersonalizedRecommendations(forceRandom: false);
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    if (query.trim().isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SearchResultsScreen(query: query)),
      );
    }
  }

  // THÊM THAM SỐ forceRandom ĐỂ FIX NÚT REFRESH
  Future<List<Book>> _loadPersonalizedRecommendations({bool forceRandom = false}) async {
    final authService = Provider.of<AuthService>(context, listen: false);

    // Xáo trộn danh sách thể loại và lấy cái đầu tiên làm mặc định
    List<String> shuffledCats = List.from(_categories)..shuffle();
    String targetKeyword = shuffledCats.first;

    // Nếu KHÔNG ép lấy ngẫu nhiên, thì mới chui vào Firebase để tìm lịch sử
    if (!forceRandom) {
      try {
        if (authService.isLoggedIn && authService.user != null) {
          final snapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(authService.user!.uid)
              .collection('search_history')
              .orderBy('timestamp', descending: true)
              .limit(1)
              .get();

          if (snapshot.docs.isNotEmpty) {
            targetKeyword = snapshot.docs.first.data()['query'] ?? targetKeyword;
          }
        }
      } catch (e) {
        debugPrint('Lỗi khi lấy lịch sử tìm kiếm: $e');
      }
    }

    // Cập nhật giao diện chữ
    if (mounted) setState(() => _currentSuggestKeyword = targetKeyword);

    final GoogleBooksApi googleApi = GoogleBooksApi();
    final TruyenFullScraper truyenFullApi = TruyenFullScraper();

    final results = await Future.wait([
      googleApi.searchBooks(targetKeyword).catchError((_) => <Book>[]),
      truyenFullApi.searchBooks(targetKeyword).catchError((_) => <Book>[]),
    ]);

    List<Book> combinedBooks = [];
    combinedBooks.addAll(results[0]);
    combinedBooks.addAll(results[1]);
    combinedBooks.shuffle();

    return combinedBooks;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authService = Provider.of<AuthService>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeInAnimation,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context, authService),
                    const SizedBox(height: 32),
                    CustomSearchBar(
                      controller: _searchController,
                      onSearch: _onSearch,
                      hintText: Constants.searchHint,
                    ),
                    const SizedBox(height: 32),
                    _buildHeroBanner(context, isDarkMode),

                    const SizedBox(height: 32),
                    // THÊM: Phần Khám phá Thể Loại
                    _buildCategoriesSection(context),

                    const SizedBox(height: 36),
                    _buildRecommendations(context),
                    const SizedBox(height: 20), // Khoảng trống dưới cùng
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // --- UI: KHÁM PHÁ THỂ LOẠI ---
  Widget _buildCategoriesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Khám phá thể loại',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        // Tạo thanh cuộn ngang, chứa các tag thể loại xếp thành 2 dòng
        SizedBox(
          height: 100, // Chiều cao cố định để ép các chip xuống dòng tạo thành 2 hàng
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Wrap(
              direction: Axis.vertical, // Xếp dọc xuống, hết 100px sẽ tự tạo cột mới
              spacing: 12, // Khoảng cách giữa 2 dòng
              runSpacing: 12, // Khoảng cách giữa các cột
              children: _categories.map((category) {
                return InkWell(
                  onTap: () => _onSearch(category),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Theme.of(context).primaryColor.withOpacity(0.2),
                      ),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendations(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                _currentSuggestKeyword.isNotEmpty
                    ? 'Gợi ý: $_currentSuggestKeyword' // ĐÃ SỬA: Rút gọn chữ để không bị tràn
                    : 'Gợi ý cho bạn',
                style: const TextStyle( // ĐÃ SỬA: Cố định font size 18 cho an toàn
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Tải gợi ý ngẫu nhiên',
              onPressed: () {
                setState(() {
                  // ĐÃ SỬA: Gọi forceRandom = true để bỏ qua lịch sử, ép lấy ngẫu nhiên
                  _recommendedBooks = _loadPersonalizedRecommendations(forceRandom: true);
                });
              },
            )
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 240,
          child: FutureBuilder<List<Book>>(
            future: _recommendedBooks,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(color: Theme.of(context).primaryColor),
                );
              }

              if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                return Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      'Chưa có gợi ý nào lúc này.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                );
              }

              final books = snapshot.data!;

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: books.length > 10 ? 10 : books.length,
                itemBuilder: (context, index) {
                  final book = books[index];

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => BookDetailScreen(book: book)),
                      );
                    },
                    child: Container(
                      width: 140,
                      margin: const EdgeInsets.only(right: 16, bottom: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                              child: Image.network(
                                book.thumbnail,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    book.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    book.authors.isNotEmpty ? book.authors.first : 'Đang cập nhật',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, AuthService authService) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Xin chào,',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              authService.isLoggedIn ? (authService.user?.displayName ?? 'Jisy') : 'Khách',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        if (!authService.isLoggedIn)
          ElevatedButton.icon(
            onPressed: () async {
              try {
                await authService.signInWithGoogle();
                setState(() {
                  _recommendedBooks = _loadPersonalizedRecommendations(forceRandom: false);
                });
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(Constants.errorLoginFailed)));
              }
            },
            icon: const Icon(Icons.login, size: 20),
            label: const Text('Đăng nhập'),
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              foregroundColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          )
        else
          CircleAvatar(
            radius: 22,
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
            child: Icon(Icons.person, color: Theme.of(context).primaryColor),
          ),
      ],
    );
  }

  Widget _buildHeroBanner(BuildContext context, bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [const Color(0xFF2A2A4A), const Color(0xFF1A1A2E)]
              : [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withOpacity(0.7)],
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Constants.welcomeMessage,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, height: 1.3),
                ),
                const SizedBox(height: 12),
                Text(
                  'Bắt đầu hành trình hôm nay',
                  style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
            child: const Icon(Icons.menu_book_rounded, size: 40, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Icon(Icons.menu_book_rounded, size: 48, color: Theme.of(context).primaryColor.withOpacity(0.5)),
    );
  }
}