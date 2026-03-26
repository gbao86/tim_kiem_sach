import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/admin_service.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../models/stat_item.dart';
import '../widgets/loading_indicator.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  @override
  _AdminAnalyticsScreenState createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  final AdminService _adminService = AdminService();
  UserModel? _selectedUser;
  List<UserModel> _allUsers = [];
  List<Map<String, dynamic>> _userSearchHistory = [];
  List<Map<String, dynamic>> _userFavoriteBooks = [];
  List<StatItem> _overallMostFrequentKeywords = [];
  List<StatItem> _overallMostFavoriteBooks = [];

  bool _isLoadingOverall = true;
  bool _isLoadingUserSpecific = false;
  bool _isAdmin = false;

  // ĐÃ THÊM: Biến lưu trữ vị trí ngón tay chạm trên biểu đồ tròn
  int _touchedSearchIndex = -1;
  int _touchedBookIndex = -1;

  final List<Color> _chartColors = [
    const Color(0xFF6C63FF), // Tím nhạt
    const Color(0xFFFF6584), // Hồng
    const Color(0xFF38B2AC), // Xanh lơ
    const Color(0xFFFFB020), // Vàng cam
    const Color(0xFF00C49F), // Xanh lá
    const Color(0xFFFF8042), // Cam đậm
    const Color(0xFF8884d8), // Tím pastel
  ];

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
    _fetchAllUsersAndOverallAnalytics();
  }

  Future<void> _checkAdminStatus() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final isAdmin = await authService.isAdmin();
    if (mounted) {
      setState(() {
        _isAdmin = isAdmin;
      });
    }
  }

  Future<void> _fetchAllUsersAndOverallAnalytics() async {
    setState(() => _isLoadingOverall = true);
    try {
      _allUsers = await _adminService.getAllUsers();
      _overallMostFrequentKeywords = await _adminService.getOverallMostFrequentKeywords();
      _overallMostFavoriteBooks = await _adminService.getOverallMostFavoriteBooks();
    } catch (e) {
      debugPrint('Lỗi khi lấy dữ liệu thống kê: $e');
    } finally {
      if (mounted) setState(() => _isLoadingOverall = false);
    }
  }

  Future<void> _fetchUserSpecificAnalytics(UserModel user) async {
    setState(() {
      _isLoadingUserSpecific = true;
      _selectedUser = user;
      _userSearchHistory = [];
      _userFavoriteBooks = [];
    });
    try {
      _userSearchHistory = await _adminService.getUserSearchHistory(user.uid);
      _userFavoriteBooks = await _adminService.getUserFavoriteBooks(user.uid);
    } catch (e) {
      debugPrint('Lỗi khi lấy dữ liệu người dùng: $e');
    } finally {
      if (mounted) setState(() => _isLoadingUserSpecific = false);
    }
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return DateFormat('HH:mm - dd/MM/yyyy').format(dateTime);
  }

  Color _getColor(int index) => _chartColors[index % _chartColors.length];

  List<MapEntry<String, int>> _statItemsToMapEntries(List<StatItem> items) {
    final sorted = items.toList()..sort((a, b) => b.count.compareTo(a.count));
    return sorted.map((e) => MapEntry(e.name, e.count)).toList();
  }

  List<MapEntry<String, int>> _getSortedSearchHistory() {
    final Map<String, int> counts = {};
    for (var h in _userSearchHistory) {
      final q = h['query'] as String? ?? 'Khác';
      if (q.isNotEmpty) counts[q] = (counts[q] ?? 0) + 1;
    }
    return counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  }

  List<MapEntry<String, int>> _getSortedFavoriteBooks() {
    final Map<String, int> counts = {};
    for (var b in _userFavoriteBooks) {
      final t = b['title'] as String? ?? 'Khác';
      if (t.isNotEmpty) counts[t] = (counts[t] ?? 0) + 1;
    }
    return counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  }

  // ĐÃ SỬA: Thêm tham số touchedIndex để biết miếng nào đang bị chạm
  List<PieChartSectionData> _buildPieSections(List<MapEntry<String, int>> sortedData, int touchedIndex) {
    if (sortedData.isEmpty) return [];
    double total = sortedData.fold(0, (sum, e) => sum + e.value);

    return sortedData.take(5).toList().asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final pct = (data.value / total) * 100;

      // Xử lý logic khi chạm
      final isTouched = index == touchedIndex;
      final fontSize = isTouched ? 16.0 : 12.0;
      final radius = isTouched ? 60.0 : 50.0;
      final titleText = isTouched ? '${data.value} lượt' : '${pct.toStringAsFixed(0)}%';

      return PieChartSectionData(
        color: _getColor(index),
        value: data.value.toDouble(),
        title: titleText,
        radius: radius,
        titleStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();
  }

  Widget _buildLegend(List<MapEntry<String, int>> sortedData) {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: sortedData.take(5).toList().asMap().entries.map((entry) {
        final index = entry.key;
        final label = entry.value.key;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(color: _getColor(index), shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label.length > 20 ? '${label.substring(0, 20)}...' : label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        );
      }).toList(),
    );
  }

  List<BarChartGroupData> _getOverallKeywordsBarChartData() {
    final top5 = _overallMostFrequentKeywords.toList()..sort((a, b) => b.count.compareTo(a.count));
    double maxVal = top5.isNotEmpty ? top5.first.count.toDouble() : 10;

    return top5.take(5).toList().asMap().entries.map((e) {
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: e.value.count.toDouble(),
            color: _getColor(e.key),
            width: 32,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: maxVal * 1.2,
              color: Colors.grey.withOpacity(0.1),
            ),
          ),
        ],
      );
    }).toList();
  }

  List<BarChartGroupData> _getOverallFavoriteBooksBarChartData() {
    final top5 = _overallMostFavoriteBooks.toList()..sort((a, b) => b.count.compareTo(a.count));
    double maxVal = top5.isNotEmpty ? top5.first.count.toDouble() : 10;

    return top5.take(5).toList().asMap().entries.map((e) {
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: e.value.count.toDouble(),
            color: _getColor(e.key),
            width: 32,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: maxVal * 1.2,
              color: Colors.grey.withOpacity(0.1),
            ),
          ),
        ],
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Truy cập từ chối')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.security, size: 64, color: Colors.redAccent),
              SizedBox(height: 16),
              Text('Bạn không có quyền quản trị viên', style: TextStyle(fontSize: 18)),
            ],
          ),
        ),
      );
    }

    double keywordMaxY = _overallMostFrequentKeywords.isNotEmpty
        ? _overallMostFrequentKeywords.first.count.toDouble() * 1.4 : 10;
    double bookMaxY = _overallMostFavoriteBooks.isNotEmpty
        ? _overallMostFavoriteBooks.first.count.toDouble() * 1.4 : 10;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Bảng Phân Tích', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoadingOverall
          ? const Center(child: LoadingIndicator())
          : RefreshIndicator(
        onRefresh: _fetchAllUsersAndOverallAnalytics,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Tổng Quan Hệ Thống'),
              const SizedBox(height: 16),

              // --- TỪ KHÓA TÌM KIẾM ---
              _buildChartCard(
                title: 'Top 5 Từ Khóa Tìm Kiếm',
                icon: Icons.search_rounded,
                isEmpty: _overallMostFrequentKeywords.isEmpty,
                chartWidget: BarChart(
                  BarChartData(
                    maxY: keywordMaxY,
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        fitInsideHorizontally: true,
                        fitInsideVertically: true,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            '${rod.toY.toInt()} lượt',
                            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          );
                        },
                      ),
                    ),
                    barGroups: _getOverallKeywordsBarChartData(),
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                  ),
                ),
                legendWidget: _buildLegend(_statItemsToMapEntries(_overallMostFrequentKeywords)),
              ),
              const SizedBox(height: 24),

              // --- SÁCH YÊU THÍCH ---
              _buildChartCard(
                title: 'Top 5 Sách Yêu Thích',
                icon: Icons.favorite_rounded,
                isEmpty: _overallMostFavoriteBooks.isEmpty,
                chartWidget: BarChart(
                  BarChartData(
                    maxY: bookMaxY,
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        fitInsideHorizontally: true,
                        fitInsideVertically: true,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            '${rod.toY.toInt()} lượt',
                            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          );
                        },
                      ),
                    ),
                    barGroups: _getOverallFavoriteBooksBarChartData(),
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                  ),
                ),
                legendWidget: _buildLegend(_statItemsToMapEntries(_overallMostFavoriteBooks)),
              ),

              const SizedBox(height: 32),
              const Divider(height: 1, thickness: 1),
              const SizedBox(height: 32),

              // --- PHÂN TÍCH THEO USER ---
              _buildSectionTitle('Phân Tích Người Dùng'),
              const SizedBox(height: 16),

              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<UserModel>(
                    value: _selectedUser,
                    hint: const Text('Tra cứu theo người dùng...'),
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    onChanged: (UserModel? newValue) {
                      if (newValue != null) _fetchUserSpecificAnalytics(newValue);
                    },
                    items: _allUsers.map((UserModel user) {
                      return DropdownMenuItem<UserModel>(
                        value: user,
                        child: Text(user.displayName ?? user.email,
                            style: const TextStyle(fontWeight: FontWeight.w500)),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              if (_selectedUser != null)
                _isLoadingUserSpecific
                    ? const Center(child: LoadingIndicator())
                    : _buildUserSpecificView(),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI HELPER WIDGETS ---

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 0.5),
    );
  }

  Widget _buildChartCard({required String title, required IconData icon, required bool isEmpty, required Widget chartWidget, Widget? legendWidget}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Theme.of(context).primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: Theme.of(context).primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 24),
          isEmpty
              ? _buildEmptyState()
              : Column(
            children: [
              SizedBox(height: 200, child: chartWidget),
              if (legendWidget != null) ...[
                const SizedBox(height: 24),
                legendWidget,
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Icon(Icons.data_usage_rounded, size: 48, color: Colors.grey.withOpacity(0.4)),
            const SizedBox(height: 12),
            const Text('Chưa có dữ liệu thống kê', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildUserSpecificView() {
    final searchData = _getSortedSearchHistory();
    final bookData = _getSortedFavoriteBooks();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                child: Text(
                  (_selectedUser!.displayName ?? _selectedUser!.email)[0].toUpperCase(),
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_selectedUser!.displayName ?? 'Người dùng', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(_selectedUser!.email, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                      child: Text('Online: ${_formatDateTime(_selectedUser!.lastSignInTime)}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
        const SizedBox(height: 24),

        // --- ĐÃ SỬA: Thêm pieTouchData cho biểu đồ tìm kiếm ---
        _buildChartCard(
          title: 'Tỉ trọng Tìm kiếm',
          icon: Icons.pie_chart_rounded,
          isEmpty: searchData.isEmpty,
          chartWidget: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      _touchedSearchIndex = -1;
                      return;
                    }
                    _touchedSearchIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              sections: _buildPieSections(searchData, _touchedSearchIndex), // Truyền touchedIndex vào
              centerSpaceRadius: 40,
              sectionsSpace: 4,
            ),
          ),
          legendWidget: _buildLegend(searchData),
        ),
        const SizedBox(height: 24),

        // --- ĐÃ SỬA: Thêm pieTouchData cho biểu đồ sách yêu thích ---
        _buildChartCard(
          title: 'Thể loại Sách Yêu Thích',
          icon: Icons.bookmark_added_rounded,
          isEmpty: bookData.isEmpty,
          chartWidget: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      _touchedBookIndex = -1;
                      return;
                    }
                    _touchedBookIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              sections: _buildPieSections(bookData, _touchedBookIndex), // Truyền touchedIndex vào
              centerSpaceRadius: 40,
              sectionsSpace: 4,
            ),
          ),
          legendWidget: _buildLegend(bookData),
        ),
      ],
    );
  }
}