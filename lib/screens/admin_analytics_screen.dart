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
import 'dart:math';

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

  final Random _random = Random();

  // Bảng màu cố định cho biểu đồ
  final List<Color> _colorPalette = [
    Colors.blue.shade600,
    Colors.green.shade600,
    Colors.red.shade600,
    Colors.orange.shade600,
    Colors.purple.shade600,
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
    setState(() {
      _isLoadingOverall = true;
    });
    try {
      _allUsers = await _adminService.getAllUsers();
      _overallMostFrequentKeywords = await _adminService.getOverallMostFrequentKeywords();
      _overallMostFavoriteBooks = await _adminService.getOverallMostFavoriteBooks();
    } catch (e) {
      print('Lỗi khi lấy dữ liệu thống kê: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingOverall = false;
        });
      }
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
      print('Lỗi khi lấy dữ liệu người dùng: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingUserSpecific = false;
        });
      }
    }
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return DateFormat('HH:mm dd/MM/yyyy').format(dateTime);
  }

  Color _getColor(int index) {
    return _colorPalette[index % _colorPalette.length];
  }

  List<PieChartSectionData> _getSearchHistoryChartData() {
    if (_userSearchHistory.isEmpty) return [];

    final Map<String, int> queryCounts = {};
    for (var history in _userSearchHistory) {
      final query = history['query'] as String? ?? 'Không rõ';
      if (query.isNotEmpty) {
        queryCounts[query] = (queryCounts[query] ?? 0) + 1;
      }
    }

    final sortedQueries = queryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    double totalCount = sortedQueries.fold(0, (sum, entry) => sum + entry.value);

    return sortedQueries.take(7).map((entry) {
      final percentage = (entry.value / totalCount) * 100;
      return PieChartSectionData(
        color: _getColor(sortedQueries.indexOf(entry)),
        value: entry.value.toDouble(),
        title: '${entry.key}\n${percentage.toStringAsFixed(1)}%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        badgeWidget: Text(entry.value.toString(), style: const TextStyle(color: Colors.white, fontSize: 8)),
        badgePositionPercentageOffset: 0.9,
      );
    }).toList();
  }

  List<PieChartSectionData> _getFavoriteBooksChartData() {
    if (_userFavoriteBooks.isEmpty) return [];

    final Map<String, int> bookTitleCounts = {};
    for (var book in _userFavoriteBooks) {
      final title = book['title'] as String? ?? 'Không có tiêu đề';
      if (title.isNotEmpty) {
        bookTitleCounts[title] = (bookTitleCounts[title] ?? 0) + 1;
      }
    }

    final sortedBooks = bookTitleCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    double totalCount = sortedBooks.fold(0, (sum, entry) => sum + entry.value);

    return sortedBooks.take(7).map((entry) {
      final percentage = (entry.value / totalCount) * 100;
      return PieChartSectionData(
        color: _getColor(sortedBooks.indexOf(entry)),
        value: entry.value.toDouble(),
        title: '${entry.key}\n${percentage.toStringAsFixed(1)}%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        badgeWidget: Text(entry.value.toString(), style: const TextStyle(color: Colors.white, fontSize: 8)),
        badgePositionPercentageOffset: 0.9,
      );
    }).toList();
  }

  List<BarChartGroupData> _getOverallKeywordsBarChartData() {
    final top5Keywords = _overallMostFrequentKeywords.toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    return top5Keywords.take(5).toList().asMap().entries.map((entry) {
      int index = entry.key;
      StatItem item = entry.value;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: item.count.toDouble(),
            color: _getColor(index),
            width: 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
        showingTooltipIndicators: [0],
      );
    }).toList();
  }

  List<BarChartGroupData> _getOverallFavoriteBooksBarChartData() {
    final top5Books = _overallMostFavoriteBooks.toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    return top5Books.take(5).toList().asMap().entries.map((entry) {
      int index = entry.key;
      StatItem item = entry.value;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: item.count.toDouble(),
            color: _getColor(index),
            width: 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
        showingTooltipIndicators: [0],
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdmin) {
      return const Scaffold(
        body: Center(child: Text('Bạn không có quyền truy cập màn hình này')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Thống kê & Phân tích')),
      body: _isLoadingOverall
          ? const Center(child: LoadingIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thống kê chung',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            Text(
              'Biểu đồ phân bổ từ khóa tìm kiếm phổ biến nhất (Top 5)',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _overallMostFrequentKeywords.isEmpty
                ? const Text('Không có dữ liệu từ khóa để hiển thị biểu đồ.')
                : Card(
              elevation: 4,
              child: SizedBox(
                height: 300,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: BarChart(
                    BarChartData(
                      barGroups: _getOverallKeywordsBarChartData(),
                      groupsSpace: 20,
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 100,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              final sortedKeywords = _overallMostFrequentKeywords.toList()
                                ..sort((a, b) => b.count.compareTo(a.count));
                              if (index >= 0 && index < sortedKeywords.take(5).length) {
                                final label = sortedKeywords[index].name.length > 12
                                    ? '${sortedKeywords[index].name.substring(0, 3)}...'
                                    : sortedKeywords[index].name;
                                return Transform.rotate(
                                  angle: (3.1415926535 / 180),
                                  alignment: Alignment.topRight,
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      label,
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: const TextStyle(fontSize: 11),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: (_overallMostFrequentKeywords.isNotEmpty
                            ? _overallMostFrequentKeywords.first.count.toDouble() / 5
                            : 1),
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey.withOpacity(0.2),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          tooltipPadding: const EdgeInsets.all(8),
                          tooltipMargin: 8,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final sortedKeywords = _overallMostFrequentKeywords.toList()
                              ..sort((a, b) => b.count.compareTo(a.count));
                            if (group.x.toInt() >= sortedKeywords.take(5).length) return null;
                            return BarTooltipItem(
                              '',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 5,
                              ),
                              children: [
                                TextSpan(
                                  text: ' (${rod.toY.toInt()} lượt)',
                                  style: const TextStyle(
                                    color: Colors.yellow,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      maxY: (_overallMostFrequentKeywords.isNotEmpty
                          ? _overallMostFrequentKeywords.first.count.toDouble() * 1.3
                          : 10) +
                          1,
                      minY: 0,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Tất cả từ khóa tìm kiếm phổ biến',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _overallMostFrequentKeywords.isEmpty
                ? const Text('Không có dữ liệu từ khóa.')
                : Card(
              elevation: 2,
              child: SizedBox(
                height: 200,
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: _overallMostFrequentKeywords.length,
                  itemBuilder: (context, index) {
                    final item = _overallMostFrequentKeywords[index];
                    return ListTile(
                      leading: Text('${index + 1}.', style: const TextStyle(fontWeight: FontWeight.bold)),
                      title: Text(item.name),
                      trailing: Text('${item.count} lượt'),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 30),

            Text(
              'Biểu đồ phân bổ sách được yêu thích nhất (Top 5)',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _overallMostFavoriteBooks.isEmpty
                ? const Text('Không có dữ liệu sách yêu thích để hiển thị biểu đồ.')
                : Card(
              elevation: 4,
              child: SizedBox(
                height: 300,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: BarChart(
                    BarChartData(
                      barGroups: _getOverallFavoriteBooksBarChartData(),
                      groupsSpace: 20,
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 100,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              final sortedBooks = _overallMostFavoriteBooks.toList()
                                ..sort((a, b) => b.count.compareTo(a.count));
                              if (index >= 0 && index < sortedBooks.take(5).length) {
                                final label = sortedBooks[index].name.length > 12
                                    ? '${sortedBooks[index].name.substring(0, 3)}...'
                                    : sortedBooks[index].name;
                                return Transform.rotate(
                                  angle: (3.1415926535 / 180),
                                  alignment: Alignment.topRight,
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      label,
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: const TextStyle(fontSize: 11),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: (_overallMostFavoriteBooks.isNotEmpty
                            ? _overallMostFavoriteBooks.first.count.toDouble() / 5
                            : 1),
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey.withOpacity(0.2),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          tooltipPadding: const EdgeInsets.all(8),
                          tooltipMargin: 8,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final sortedBooks = _overallMostFavoriteBooks.toList()
                              ..sort((a, b) => b.count.compareTo(a.count));
                            if (group.x.toInt() >= sortedBooks.take(5).length) return null;
                            return BarTooltipItem(
                              '',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 5,
                              ),
                              children: [
                                TextSpan(
                                  text: ' (${rod.toY.toInt()} lượt)',
                                  style: const TextStyle(
                                    color: Colors.yellow,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      maxY: (_overallMostFavoriteBooks.isNotEmpty
                          ? _overallMostFavoriteBooks.first.count.toDouble() * 1.3
                          : 10) +
                          1,
                      minY: 0,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Tất cả sách được yêu thích nhất',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _overallMostFavoriteBooks.isEmpty
                ? const Text('Không có dữ liệu sách yêu thích.')
                : Card(
              elevation: 2,
              child: SizedBox(
                height: 200,
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: _overallMostFavoriteBooks.length,
                  itemBuilder: (context, index) {
                    final item = _overallMostFavoriteBooks[index];
                    return ListTile(
                      leading: Text('${index + 1}.', style: const TextStyle(fontWeight: FontWeight.bold)),
                      title: Text(item.name),
                      trailing: Text('${item.count} lượt yêu thích'),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 30),

            const Divider(),
            const SizedBox(height: 20),

            const Text(
              'Phân tích theo người dùng',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<UserModel>(
              value: _selectedUser,
              hint: const Text('Chọn một người dùng'),
              isExpanded: true,
              onChanged: (UserModel? newValue) {
                if (newValue != null) {
                  _fetchUserSpecificAnalytics(newValue);
                }
              },
              items: _allUsers.map<DropdownMenuItem<UserModel>>((UserModel user) {
                return DropdownMenuItem<UserModel>(
                  value: user,
                  child: Text(user.displayName ?? user.email),
                );
              }).toList(),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              ),
            ),
            const SizedBox(height: 20),

            if (_selectedUser != null)
              _isLoadingUserSpecific
                  ? const Center(child: LoadingIndicator())
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chi tiết người dùng: ${_selectedUser!.displayName ?? _selectedUser!.email}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Email: ${_selectedUser!.email}'),
                          Text('UID: ${_selectedUser!.uid}'),
                          Text('Vai trò: ${_selectedUser!.role}'),
                          Text('Lần truy cập cuối: ${_formatDateTime(_selectedUser!.lastSignInTime)}'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'Phân bổ từ khóa tìm kiếm của ${_selectedUser!.displayName ?? 'người dùng này'}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _userSearchHistory.isEmpty
                      ? const Text('Không có lịch sử tìm kiếm để hiển thị biểu đồ.')
                      : SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sections: _getSearchHistoryChartData(),
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        borderData: FlBorderData(show: false),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Text(
                    'Chi tiết lịch sử tìm kiếm (${_userSearchHistory.length})',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _userSearchHistory.isEmpty
                      ? const Text('Không có lịch sử tìm kiếm.')
                      : Card(
                    elevation: 2,
                    child: SizedBox(
                      height: 200,
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: _userSearchHistory.length,
                        itemBuilder: (context, index) {
                          final history = _userSearchHistory[index];
                          DateTime? timestamp;
                          if (history['timestamp'] is Timestamp) {
                            timestamp = (history['timestamp'] as Timestamp).toDate();
                          } else if (history['timestamp'] is String) {
                            try {
                              timestamp = DateTime.parse(history['timestamp']);
                            } catch (e) {
                              print('Lỗi parse timestamp: $e');
                            }
                          }
                          return ListTile(
                            title: Text(history['query'] ?? 'N/A'),
                            subtitle: Text(_formatDateTime(timestamp)),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'Phân bổ sách yêu thích của ${_selectedUser!.displayName ?? 'người dùng này'}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _userFavoriteBooks.isEmpty
                      ? const Text('Không có sách yêu thích để hiển thị biểu đồ.')
                      : SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sections: _getFavoriteBooksChartData(),
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        borderData: FlBorderData(show: false),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Text(
                    'Chi tiết sách yêu thích (${_userFavoriteBooks.length})',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _userFavoriteBooks.isEmpty
                      ? const Text('Không có sách yêu thích.')
                      : Card(
                    elevation: 2,
                    child: SizedBox(
                      height: 200,
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: _userFavoriteBooks.length,
                        itemBuilder: (context, index) {
                          final book = _userFavoriteBooks[index];
                          return ListTile(
                            leading: (book['coverUrl'] != null && book['coverUrl'].isNotEmpty)
                                ? SizedBox(
                              width: 40,
                              height: 60,
                              child: Image.network(
                                book['coverUrl'],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.broken_image, size: 30, color: Colors.grey),
                              ),
                            )
                                : const Icon(Icons.book, size: 40, color: Colors.blueGrey),
                            title: Text(book['title'] ?? 'Không có tiêu đề'),
                            subtitle: Text(book['author'] ?? 'Không rõ tác giả'),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}