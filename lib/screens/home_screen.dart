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

class CategoryItem {
  final String name;
  final String searchKey; // Từ khóa tiếng Anh để tìm trên Google/OpenLibrary
  final Color color;
  CategoryItem({required this.name, required this.searchKey, required this.color});
}

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

  // DANH SÁCH THỂ LOẠI NÂNG CẤP VỚI MÀU SẮC VÀ SEARCH KEY
  final List<CategoryItem> _categories = [
    CategoryItem(name: 'Tiên Hiệp', searchKey: 'fantasy', color: Colors.blue),
    CategoryItem(name: 'Ngôn Tình', searchKey: 'romance', color: Colors.pink),
    CategoryItem(name: 'Truyện Tranh', searchKey: 'comics', color: Colors.orange),
    CategoryItem(name: 'Sách Học Thuật', searchKey: 'academic', color: Colors.teal),
    CategoryItem(name: 'Kinh Dị', searchKey: 'horror', color: Colors.deepPurple),
    CategoryItem(name: 'Trinh Thám', searchKey: 'mystery', color: Colors.indigo),
    CategoryItem(name: 'Khoa Huyễn', searchKey: 'science fiction', color: Colors.cyan),
    CategoryItem(name: 'Đam Mỹ', searchKey: 'lgbt romance', color: Colors.redAccent),
    CategoryItem(name: 'Hệ Thống', searchKey: 'game', color: Colors.amber),
    CategoryItem(name: 'Lịch Sử', searchKey: 'history', color: Colors.brown),
    CategoryItem(name: 'Kinh Tế', searchKey: 'economics', color: Colors.green),
    CategoryItem(name: 'Kỹ Năng', searchKey: 'self-help', color: Colors.lightGreen),
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

  void _onSearch(String query, {String? categoryKey}) {
    if (query.trim().isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SearchResultsScreen(
            query: query, 
            categorySearchKey: categoryKey, // Truyền key tiếng Anh sang
          )
        ),
      );
    }
  }

  Future<List<Book>> _loadPersonalizedRecommendations({bool forceRandom = false}) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    List<CategoryItem> shuffledCats = List.from(_categories)..shuffle();
    CategoryItem target = shuffledCats.first;

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
            String lastQuery = snapshot.docs.first.data()['query'] ?? '';
            _currentSuggestKeyword = lastQuery;
          }
        }
      } catch (e) {
        debugPrint('Error: $e');
      }
    }

    if (mounted && _currentSuggestKeyword.isEmpty) {
      setState(() => _currentSuggestKeyword = target.name);
    }

    final GoogleBooksApi googleApi = GoogleBooksApi();
    final results = await googleApi.searchBooks(_currentSuggestKeyword);
    return results;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authService = Provider.of<AuthService>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeInAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context, authService),
                    const SizedBox(height: 32),
                    CustomSearchBar(
                      controller: _searchController,
                      onSearch: (q) => _onSearch(q),
                      hintText: Constants.searchHint,
                    ),
                    const SizedBox(height: 32),
                    _buildHeroBanner(context, isDarkMode),
                    const SizedBox(height: 32),
                    _buildCategoriesSection(context),
                    const SizedBox(height: 36),
                    _buildRecommendations(context),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoriesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Khám phá thể loại', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final cat = _categories[index];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: InkWell(
                  onTap: () => _onSearch(cat.name, categoryKey: cat.searchKey),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 100,
                    decoration: BoxDecoration(
                      color: cat.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cat.color.withOpacity(0.3)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_awesome_mosaic_rounded, color: cat.color),
                        const SizedBox(height: 8),
                        Text(cat.name, textAlign: TextAlign.center, style: TextStyle(color: cat.color, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- Các hàm build khác giữ nguyên như cũ để đảm bảo tính năng ---
  Widget _buildHeader(BuildContext context, AuthService authService) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Xin chào,', style: TextStyle(color: Colors.grey.shade600)),
            Text(authService.isLoggedIn ? (authService.user?.displayName ?? 'Jisy') : 'Khách',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
        CircleAvatar(backgroundColor: Colors.blue.withOpacity(0.1), child: const Icon(Icons.person, color: Colors.blue)),
      ],
    );
  }

  Widget _buildHeroBanner(BuildContext context, bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(colors: [Colors.blue, Colors.blue.shade800]),
      ),
      child: const Text('Tìm kiếm hàng triệu cuốn sách\ntừ đa nguồn dữ liệu', 
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildRecommendations(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Gợi ý hôm nay', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: FutureBuilder<List<Book>>(
            future: _recommendedBooks,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final books = snapshot.data!;
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: books.length,
                itemBuilder: (context, index) {
                  final book = books[index];
                  return Container(
                    width: 120,
                    margin: const EdgeInsets.only(right: 12),
                    child: Column(
                      children: [
                        Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(book.thumbnail, fit: BoxFit.cover))),
                        const SizedBox(height: 4),
                        Text(book.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        )
      ],
    );
  }

  Widget _buildPlaceholderImage() => Container(color: Colors.grey.shade200, child: const Icon(Icons.book));
}
