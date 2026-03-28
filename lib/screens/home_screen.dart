import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/constants.dart';
import '../services/auth_service.dart';
import '../utils/theme_provider.dart';
import '../widgets/search_bar.dart';
import '../models/book.dart';
import '../api/google_books_api.dart';
import 'search_results_screen.dart';
import 'book_detail_screen.dart';

class CategoryItem {
  final String name;
  final String searchKey;
  CategoryItem({required this.name, required this.searchKey});
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

  // DANH SÁCH 55+ THỂ LOẠI CHUẨN XÁC
  final List<CategoryItem> _categories = [
    CategoryItem(name: 'Truyện tranh', searchKey: 'comics'),
    CategoryItem(name: 'Truyện mới cập nhật', searchKey: 'new updates'),
    CategoryItem(name: 'Truyện Hot', searchKey: 'trending'),
    CategoryItem(name: 'Truyện Full', searchKey: 'completed'),
    CategoryItem(name: 'Tiên Hiệp Hay', searchKey: 'best xianxia'),
    CategoryItem(name: 'Kiếm Hiệp Hay', searchKey: 'best wuxia'),
    CategoryItem(name: 'Truyện Teen Hay', searchKey: 'best teen fiction'),
    CategoryItem(name: 'Ngôn Tình Hay', searchKey: 'best romance'),
    CategoryItem(name: 'Ngôn Tình Ngược', searchKey: 'sad romance'),
    CategoryItem(name: 'Ngôn Tình Sủng', searchKey: 'sweet romance'),
    CategoryItem(name: 'Ngôn Tình Hài', searchKey: 'romance comedy'),
    CategoryItem(name: 'Đam Mỹ Hài', searchKey: 'bl comedy'),
    CategoryItem(name: 'Đam Mỹ Hay', searchKey: 'best bl'),
    CategoryItem(name: 'Truyện Hay', searchKey: 'popular novels'),
    CategoryItem(name: 'Tiên Hiệp', searchKey: 'xianxia'),
    CategoryItem(name: 'Kiếm Hiệp', searchKey: 'wuxia'),
    CategoryItem(name: 'Ngôn Tình', searchKey: 'romance'),
    CategoryItem(name: 'Đam Mỹ', searchKey: 'bl romance'),
    CategoryItem(name: 'Quan Trường', searchKey: 'officialdom'),
    CategoryItem(name: 'Võng Du', searchKey: 'gaming'),
    CategoryItem(name: 'Khoa Huyễn', searchKey: 'science fiction'),
    CategoryItem(name: 'Hệ Thống', searchKey: 'litrpg'),
    CategoryItem(name: 'Huyền Huyễn', searchKey: 'high fantasy'),
    CategoryItem(name: 'Dị Giới', searchKey: 'isekai'),
    CategoryItem(name: 'Dị Năng', searchKey: 'superpower'),
    CategoryItem(name: 'Sắc', searchKey: 'erotica'),
    CategoryItem(name: 'Quân Sự', searchKey: 'military'),
    CategoryItem(name: 'Lịch Sử', searchKey: 'history'),
    CategoryItem(name: 'Xuyên Không', searchKey: 'reincarnation'),
    CategoryItem(name: 'Xuyên Nhanh', searchKey: 'fast travel'),
    CategoryItem(name: 'Trọng Sinh', searchKey: 'rebirth'),
    CategoryItem(name: 'Trinh Thám', searchKey: 'mystery'),
    CategoryItem(name: 'Thám Hiểm', searchKey: 'adventure'),
    CategoryItem(name: 'Linh Dị', searchKey: 'ghost story'),
    CategoryItem(name: 'Ngược', searchKey: 'angst'),
    CategoryItem(name: 'Sủng', searchKey: 'sweet love'),
    CategoryItem(name: 'Cung Đấu', searchKey: 'palace conflict'),
    CategoryItem(name: 'Nữ Cường', searchKey: 'strong female lead'),
    CategoryItem(name: 'Gia Đấu', searchKey: 'family conflict'),
    CategoryItem(name: 'Đông Phương', searchKey: 'eastern'),
    CategoryItem(name: 'Đô Thị', searchKey: 'urban'),
    CategoryItem(name: 'Bách Hợp', searchKey: 'gl romance'),
    CategoryItem(name: 'Hài Hước', searchKey: 'humor'),
    CategoryItem(name: 'Điền Văn', searchKey: 'farming life'),
    CategoryItem(name: 'Cổ Đại', searchKey: 'ancient'),
    CategoryItem(name: 'Mạt Thế', searchKey: 'apocalypse'),
    CategoryItem(name: 'Truyện Teen', searchKey: 'teen fiction'),
    CategoryItem(name: 'Phương Tây', searchKey: 'western'),
    CategoryItem(name: 'Nữ Phụ', searchKey: 'supporting lead'),
    CategoryItem(name: 'Light Novel', searchKey: 'light novel'),
    CategoryItem(name: 'Việt Nam', searchKey: 'vietnamese'),
    CategoryItem(name: 'Đoản Văn', searchKey: 'flash fiction'),
    CategoryItem(name: 'Review sách', searchKey: 'book review'),
    CategoryItem(name: 'Truyện Ngắn', searchKey: 'short stories'),
    CategoryItem(name: 'Khác', searchKey: 'general'),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    _animationController.forward();
    _refreshRecommendations();
  }

  void _refreshRecommendations() {
    setState(() {
      _recommendedBooks = GoogleBooksApi().searchBooks(_categories[DateTime.now().millisecond % _categories.length].name);
    });
  }

  void _onSearch(String query, {String? categoryKey}) {
    if (query.trim().isNotEmpty) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => SearchResultsScreen(query: query, categorySearchKey: categoryKey)));
    }
  }

  // Hàm tạo màu pastel ngẫu nhiên nhưng cố định theo index để giao diện sinh động
  Color _getPastelColor(int index) {
    final colors = [
      Colors.blue.shade50, Colors.pink.shade50, Colors.green.shade50,
      Colors.orange.shade50, Colors.purple.shade50, Colors.teal.shade50,
      Colors.indigo.shade50, Colors.red.shade50,
    ];
    return colors[index % colors.length];
  }

  Color _getTextColor(int index) {
    final colors = [
      Colors.blue.shade700, Colors.pink.shade700, Colors.green.shade700,
      Colors.orange.shade700, Colors.purple.shade700, Colors.teal.shade700,
      Colors.indigo.shade700, Colors.red.shade700,
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeInAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(auth),
                const SizedBox(height: 24),
                CustomSearchBar(controller: _searchController, onSearch: (q) => _onSearch(q), hintText: 'Tìm truyện, sách...'),
                const SizedBox(height: 32),
                _buildCategoriesGrid(),
                const SizedBox(height: 32),
                _buildRecommendationsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AuthService auth) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Khám phá ngay', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          Text(auth.isLoggedIn ? 'Chào, ${auth.user?.displayName}' : 'Chào bạn!', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ]),
        CircleAvatar(radius: 24, backgroundColor: Colors.blueAccent, child: const Icon(Icons.person, color: Colors.white)),
      ],
    );
  }

  Widget _buildCategoriesGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Thể loại hot', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            InkWell(
              onTap: _showAllCategoriesSheet,
              child: const Text('Xem tất cả', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600, fontSize: 14)),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 🚀 BỌC TRONG LAYOUTBUILDER ĐỂ LẤY KÍCH THƯỚC MÀN HÌNH THỰC TẾ
        LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - (12 * 3)) / 4;

              const itemHeight = 100.0;

              final dynamicRatio = itemWidth / itemHeight;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: dynamicRatio, // Nhét tỷ lệ vừa tính vào đây
                ),
                itemCount: 8,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final bgColor = _getPastelColor(index);
                  final textColor = _getTextColor(index);

                  return InkWell(
                    onTap: () => _onSearch(cat.name, categoryKey: cat.searchKey),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              cat.name.substring(0, 1).toUpperCase(),
                              style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          const SizedBox(height: 6),

                          // 🚀 DÙNG EXPANDED ĐỂ ÉP CHỮ NẰM GỌN GÀNG KHÔNG BAO GIỜ TRÀN
                          Expanded(
                            child: Text(
                              cat.name,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: textColor.withOpacity(0.8),
                                  height: 1.1
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }
        ),
      ],
    );
  }

  void _showAllCategoriesSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tất cả 55+ Thể loại', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
            ),
            Divider(color: Colors.grey.shade200, height: 1),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(20),
                physics: const BouncingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // Chia 2 cột để đọc dễ hơn chữ dài
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 3.5, // Tỷ lệ thẻ dẹt giống cái nút
                ),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  return InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      _onSearch(cat.name, categoryKey: cat.searchKey);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(
                        cat.name,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey.shade800),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Gợi ý hôm nay', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          IconButton(icon: const Icon(Icons.refresh, color: Colors.blue), onPressed: _refreshRecommendations),
        ]),
        const SizedBox(height: 16),
        SizedBox(
          height: 210,
          child: FutureBuilder<List<Book>>(
            future: _recommendedBooks,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              final books = snapshot.data ?? [];
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: books.length,
                itemBuilder: (context, index) => _buildBookCard(books[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBookCard(Book book) {
    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 16),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => BookDetailScreen(book: book))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: book.thumbnail,
                      fit: BoxFit.cover,
                      placeholder: (c, u) => Container(color: Colors.grey[200]),
                      errorWidget: (c, u, e) => const Icon(Icons.book),
                    )
                )
            ),
            const SizedBox(height: 8),
            Text(book.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}