import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import '../models/analytics.dart';
import '../services/auth_service.dart';
import '../widgets/loading_indicator.dart';

enum TimeFilter { day, month, year }

class AdminTrafficScreen extends StatefulWidget {
  const AdminTrafficScreen({Key? key}) : super(key: key);

  @override
  _AdminTrafficScreenState createState() => _AdminTrafficScreenState();
}

class _AdminTrafficScreenState extends State<AdminTrafficScreen> {
  bool _isLoading = true;
  bool _isAdmin = false;

  Map<String, String> _userMap = {};
  List<DateTime> _rawTimestamps = [];
  List<Map<String, dynamic>> _allSearchDetails = [];
  List<AnalyticsData> _analytics = [];
  List<Map<String, dynamic>> _favoriteBooks = [];

  TimeFilter _selectedFilter = TimeFilter.day;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _checkAdminStatus();
    if (_isAdmin) {
      await _fetchUserMap();
      await Future.wait([
        _fetchRawAnalyticsData(),
        _fetchFavoriteBooks(),
      ]);
    }
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

  Future<void> _fetchUserMap() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').get();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final name = data['displayName'] as String?;
        final email = data['email'] as String?;
        _userMap[doc.id] = (name != null && name.trim().isNotEmpty) ? name : (email ?? 'Khách');
      }
    } catch (e) {
      print('Lỗi tải danh sách user: $e');
    }
  }

  Future<void> _fetchRawAnalyticsData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        FirebaseFirestore.instance.collectionGroup('search_history').get(),
        FirebaseFirestore.instance.collection('analytics').get(),
      ]);

      final List<DateTime> timestamps = [];
      final List<Map<String, dynamic>> details = [];

      for (var querySnapshot in results) {
        for (var doc in querySnapshot.docs) {
          final data = doc.data();
          if (data['timestamp'] != null) {
            DateTime? dt;
            if (data['timestamp'] is Timestamp) {
              dt = (data['timestamp'] as Timestamp).toDate();
            } else if (data['timestamp'] is String) {
              try {
                dt = DateTime.parse(data['timestamp'] as String);
              } catch (_) {}
            }

            if (dt != null) {
              timestamps.add(dt);
              String? queryText = data['query'] as String? ?? data['bookTitle'] as String?;
              String userId = data['userId'] as String? ??
                  (doc.reference.parent.parent != null ? doc.reference.parent.parent!.id : '');
              String displayUser = userId.isNotEmpty ? (_userMap[userId] ?? userId) : 'Khách';

              if (queryText != null && queryText.trim().isNotEmpty) {
                details.add({
                  'query': queryText,
                  'timestamp': dt,
                  'userName': displayUser,
                });
              }
            }
          }
        }
      }

      _rawTimestamps = timestamps;
      _allSearchDetails = details;
      _aggregateData();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _aggregateData() {
    final Map<DateTime, int> groupedCount = {};
    for (var timestamp in _rawTimestamps) {
      DateTime groupKey;
      switch (_selectedFilter) {
        case TimeFilter.year: groupKey = DateTime(timestamp.year); break;
        case TimeFilter.month: groupKey = DateTime(timestamp.year, timestamp.month); break;
        default: groupKey = DateTime(timestamp.year, timestamp.month, timestamp.day); break;
      }
      groupedCount[groupKey] = (groupedCount[groupKey] ?? 0) + 1;
    }

    final list = groupedCount.entries.map((e) => AnalyticsData(id: '', bookId: '', bookTitle: '', searchCount: e.value, timestamp: e.key)).toList();
    list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    if (mounted) setState(() { _analytics = list; _isLoading = false; });
  }

  void _onFilterChanged(TimeFilter filter) {
    if (_selectedFilter != filter) {
      setState(() {
        _selectedFilter = filter;
        _isLoading = true;
      });
      Future.delayed(const Duration(milliseconds: 300), () => _aggregateData());
    }
  }

  Future<void> _fetchFavoriteBooks() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance.collectionGroup('favorites').orderBy('title').get();
      final List<Map<String, dynamic>> fetchedBooks = [];
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        String userId = data['userId'] as String? ?? '';
        data['userName'] = userId.isNotEmpty ? (_userMap[userId] ?? userId) : 'Khách';
        fetchedBooks.add(data);
      }
      if (mounted) setState(() => _favoriteBooks = fetchedBooks);
    } catch (e) {}
  }

  String _formatChartDate(DateTime dateTime) {
    switch (_selectedFilter) {
      case TimeFilter.year: return DateFormat('yyyy').format(dateTime);
      case TimeFilter.month: return DateFormat('MM/yy').format(dateTime);
      default: return DateFormat('dd/MM').format(dateTime);
    }
  }

  String _formatListDate(DateTime dateTime) {
    switch (_selectedFilter) {
      case TimeFilter.year: return 'Năm ${DateFormat('yyyy').format(dateTime)}';
      case TimeFilter.month: return 'Tháng ${DateFormat('MM/yyyy').format(dateTime)}';
      default: return DateFormat('dd/MM/yyyy').format(dateTime);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchQueries(DateTime date) async {
    return _allSearchDetails.where((e) {
      final t = e['timestamp'] as DateTime;
      return t.year == date.year && t.month == date.month && t.day == date.day;
    }).toList();
  }

  void _showDetailsDialog(DateTime selectedDate) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Chi tiết ${_formatListDate(selectedDate)}'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchQueries(selectedDate),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: LoadingIndicator());
              if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('Không có dữ liệu.'));
              return ListView.separated(
                itemCount: snapshot.data!.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final data = snapshot.data![index];
                  return ListTile(
                    leading: const Icon(Icons.person_search, color: Colors.blueAccent),
                    title: Text(data['query'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('User: ${data['userName']}'),
                    trailing: Text(DateFormat('HH:mm').format(data['timestamp'])),
                  );
                },
              );
            },
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (!_isAdmin && !_isLoading) return Scaffold(body: Center(child: Text('Admin Only', style: theme.textTheme.titleMedium)));

    double maxY = 5;
    if (_analytics.isNotEmpty) maxY = _analytics.map((e) => e.searchCount).reduce(max).toDouble() * 1.3;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Thống kê hệ thống', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading ? const Center(child: LoadingIndicator()) : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter Toggle
            Center(
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.grey.shade200, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildFilterBtn('Ngày', TimeFilter.day),
                    _buildFilterBtn('Tháng', TimeFilter.month),
                    _buildFilterBtn('Năm', TimeFilter.year),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Chart
            Row(children: [const Icon(Icons.insights, color: Colors.blueAccent), const SizedBox(width: 8), Text('Biểu đồ lượng tìm kiếm', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))]),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), blurRadius: 10)]),
              child: _analytics.isEmpty ? const SizedBox(height: 250, child: Center(child: Text('Trống'))) : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: const EdgeInsets.only(top: 32, right: 24, left: 12, bottom: 12),
                  child: SizedBox(
                    width: max(MediaQuery.of(context).size.width - 64, _analytics.length * 64.0),
                    height: 250,
                    child: LineChart(LineChartData(
                      gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: maxY / 4, getDrawingHorizontalLine: (_) => FlLine(color: isDark ? Colors.white10 : Colors.black12, strokeWidth: 1)),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (v, _) => Text(v.toInt().toString(), style: TextStyle(color: theme.hintColor, fontSize: 10)))),
                        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 1, getTitlesWidget: (v, _) {
                          if (v < 0 || v >= _analytics.length) return const SizedBox();
                          return Padding(padding: const EdgeInsets.only(top: 8), child: Text(_formatChartDate(_analytics[v.toInt()].timestamp), style: TextStyle(fontSize: 10, color: theme.hintColor)));
                        })),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [LineChartBarData(
                        spots: _analytics.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.searchCount.toDouble())).toList(),
                        isCurved: true,
                        color: Colors.blueAccent,
                        barWidth: 4,
                        belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [Colors.blueAccent.withOpacity(0.3), Colors.blueAccent.withOpacity(0)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
                        dotData: FlDotData(show: true),
                      )],
                    )),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
            Text('Chi tiết lưu lượng', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _analytics.length,
              itemBuilder: (context, index) {
                final analytic = _analytics[_analytics.length - 1 - index];
                return Card(
                  color: theme.cardColor,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    leading: const Icon(Icons.calendar_today, color: Colors.blueAccent),
                    title: Text(_formatListDate(analytic.timestamp), style: const TextStyle(fontWeight: FontWeight.bold)),
                    trailing: Chip(label: Text('${analytic.searchCount} lượt'), backgroundColor: Colors.blueAccent.withOpacity(0.1)),
                    onTap: () => _showDetailsDialog(analytic.timestamp),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),
            Text('Sách được yêu thích', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _favoriteBooks.isEmpty ? const Center(child: Text('Trống')) : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _favoriteBooks.length,
              itemBuilder: (context, index) {
                final b = _favoriteBooks[index];
                return Card(
                  color: theme.cardColor,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: b['coverUrl'] != null ? Image.network(b['coverUrl'], width: 40, fit: BoxFit.cover) : const Icon(Icons.book),
                    title: Text(b['title'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Tác giả: ${b['author']} - User: ${b['userName']}'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBtn(String label, TimeFilter filter) {
    bool sel = _selectedFilter == filter;
    return GestureDetector(
      onTap: () => _onFilterChanged(filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(color: sel ? Colors.blueAccent : Colors.transparent, borderRadius: BorderRadius.circular(16)),
        child: Text(label, style: TextStyle(color: sel ? Colors.white : Colors.grey, fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }
}