import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/analytics.dart';
import '../services/auth_service.dart';
import '../widgets/loading_indicator.dart';

class AdminTrafficScreen extends StatefulWidget {
  const AdminTrafficScreen({Key? key}) : super(key: key);

  @override
  _AdminTrafficScreenState createState() => _AdminTrafficScreenState();
}

class _AdminTrafficScreenState extends State<AdminTrafficScreen> {
  bool _isLoading = true;
  bool _isAdmin = false;
  List<AnalyticsData> _analytics = [];
  List<Map<String, dynamic>> _favoriteBooks = [];

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
    _fetchAnalytics();
    _fetchFavoriteBooks();
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

  Future<void> _fetchAnalytics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collectionGroup('search_history')
          .orderBy('timestamp', descending: true)
          .orderBy('query', descending: true)
          .orderBy('resultCount', descending: true)
          .get();

      final dailyCount = <DateTime, int>{};
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        DateTime? timestamp;

        if (data['timestamp'] is Timestamp) {
          timestamp = (data['timestamp'] as Timestamp).toDate();
        } else if (data['timestamp'] is String) {
          final timestampString = data['timestamp'] as String;
          try {
            timestamp = DateTime.parse(timestampString);
          } catch (e) {
            print('Lỗi parse timestamp string trong _fetchAnalytics: $timestampString, Lỗi: $e');
            continue;
          }
        }

        if (timestamp != null) {
          final date = DateTime(timestamp.year, timestamp.month, timestamp.day);
          dailyCount[date] = (dailyCount[date] ?? 0) + 1;
        }
      }

      final analyticsList = dailyCount.entries.map((entry) {
        return AnalyticsData(
          id: '',
          bookId: '',
          bookTitle: '',
          searchCount: entry.value,
          timestamp: entry.key,
        );
      }).toList();

      analyticsList.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      if (mounted) {
        setState(() {
          _analytics = analyticsList;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu phân tích: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchFavoriteBooks() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collectionGroup('favorites')
          .orderBy('userId', descending: true)
          .orderBy('title', descending: true)
          .orderBy('author', descending: true)
          .orderBy('coverUrl', descending: true)
          .get();

      final List<Map<String, dynamic>> fetchedBooks = [];
      for (var doc in querySnapshot.docs) {
        fetchedBooks.add(doc.data() as Map<String, dynamic>);
      }

      if (mounted) {
        setState(() {
          _favoriteBooks = fetchedBooks;
        });
      }
    } catch (e) {
      print('Lỗi tải danh sách sách yêu thích: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải danh sách sách yêu thích: $e')),
        );
      }
    }
  }

  String _formatChartDate(DateTime dateTime) {
    return DateFormat('dd/MM').format(dateTime);
  }

  String _formatListDate(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy').format(dateTime);
  }

  Future<List<Map<String, dynamic>>> _fetchSpecificQueriesForDay(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

    try {
      Query query = FirebaseFirestore.instance.collectionGroup('search_history');

      query = query
          .where('timestamp', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
          .where('timestamp', isLessThanOrEqualTo: endOfDay.toIso8601String());

      query = query
          .orderBy('timestamp', descending: true)
          .orderBy('query', descending: true)
          .orderBy('resultCount', descending: true);

      final querySnapshot = await query.get();

      List<Map<String, dynamic>> queriesWithTimestamp = [];
      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        String? actualQuery = data['query'] as String?;
        if (actualQuery == null || actualQuery.isEmpty) {
          actualQuery = data['bookTitle'] as String?;
        }

        if (actualQuery != null && actualQuery.isNotEmpty) {
          DateTime? queryTime;
          if (data['timestamp'] is String) {
            try {
              queryTime = DateTime.parse(data['timestamp'] as String);
            } catch (e) {
              print('Lỗi parse timestamp string trong chi tiết query: ${data['timestamp']}, Lỗi: $e');
            }
          } else if (data['timestamp'] is Timestamp) {
            queryTime = (data['timestamp'] as Timestamp).toDate();
          }
          queriesWithTimestamp.add({
            'query': actualQuery,
            'timestamp': queryTime,
          });
        }
      }
      return queriesWithTimestamp;
    } catch (e) {
      print('Error fetching specific queries for day ${date.toIso8601String()}: $e');
      if (e.toString().contains('requires an index')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi chỉ mục Firestore cho truy vấn chi tiết. Vui lòng kiểm tra Firebase Console để tạo chỉ mục mới được đề xuất.'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
      return [];
    }
  }

  void _showDetailsDialog(DateTime selectedDate) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Chi tiết tìm kiếm ngày ${_formatListDate(selectedDate)}'),
          content: SizedBox(
            width: double.maxFinite,
            height: MediaQuery.of(context).size.height * 0.6,
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchSpecificQueriesForDay(selectedDate),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: LoadingIndicator());
                }
                if (snapshot.hasError) {
                  print('Lỗi trong FutureBuilder chi tiết query: ${snapshot.error}');
                  return Center(child: Text('Lỗi tải chi tiết: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Không có query nào trong ngày này.'));
                }

                final queries = snapshot.data!;
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: queries.length,
                  itemBuilder: (context, index) {
                    final queryData = queries[index];
                    final queryText = queryData['query'] as String;
                    final queryTime = queryData['timestamp'] as DateTime?;

                    String timeString = queryTime != null ? DateFormat('HH:mm').format(queryTime) : '';

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                      elevation: 1,
                      child: ListTile(
                        leading: const Icon(Icons.search, size: 20),
                        title: Text(
                          queryText,
                          style: const TextStyle(fontSize: 16),
                        ),
                        trailing: timeString.isNotEmpty
                            ? Text(
                          timeString,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Đóng'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showFavoriteBookDetailsDialog(Map<String, dynamic> bookData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(bookData['title'] ?? 'Chi tiết sách yêu thích'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                if (bookData['coverUrl'] != null && bookData['coverUrl'].isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Center(
                      child: Image.network(
                        bookData['coverUrl'],
                        height: 150,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 100, color: Colors.grey),
                      ),
                    ),
                  ),
                Divider(),
                _buildDetailRow('Tiêu đề sách:', bookData['title'] ?? 'N/A'),
                _buildDetailRow('Tác giả:', bookData['author'] ?? 'N/A'),
                _buildDetailRow('Book ID:', bookData['bookId'] ?? 'N/A'),
                _buildDetailRow('Favorite ID:', bookData['id'] ?? 'N/A'),
                _buildDetailRow('User ID:', bookData['userId'] ?? 'N/A'),
                // Bạn có thể thêm các trường khác nếu có trong dữ liệu 'favorites' của bạn
                // Ví dụ: _buildDetailRow('Ngày thêm:', DateFormat('dd/MM/yyyy').format(bookData['addedDate'].toDate()) ?? 'N/A'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Đóng'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lưu lượng truy cập'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: _isAdmin
          ? _isLoading
          ? const Center(child: LoadingIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Biểu đồ hoạt động tìm kiếm',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  height: 280,
                  child: _analytics.isEmpty
                      ? const Center(child: Text('Không có dữ liệu tìm kiếm'))
                      : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        horizontalInterval: 1,
                        verticalInterval: 1,
                        getDrawingHorizontalLine: (value) {
                          return const FlLine(
                            color: Color(0xff37434d),
                            strokeWidth: 0.5,
                          );
                        },
                        getDrawingVerticalLine: (value) {
                          return const FlLine(
                            color: Color(0xff37434d),
                            strokeWidth: 0.5,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= _analytics.length) return const Text('');
                              final date = _analytics[index].timestamp;
                              if (_analytics.length > 7 && index % (_analytics.length ~/ 7).clamp(1, 5) != 0) {
                                return const Text('');
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  _formatChartDate(date),
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            interval: (_analytics.isNotEmpty && _analytics.map((e) => e.searchCount).reduce((a, b) => a > b ? a : b) > 10)
                                ? ((_analytics.map((e) => e.searchCount).reduce((a, b) => a > b ? a : b) / 5).ceilToDouble())
                                : 1,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${value.toInt()}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: const Color(0xff37434d), width: 1),
                      ),
                      minX: 0,
                      maxX: (_analytics.length > 0 ? _analytics.length - 1 : 0).toDouble(),
                      minY: 0,
                      maxY: (_analytics.isNotEmpty
                          ? (_analytics.map((e) => e.searchCount).reduce((a, b) => a > b ? a : b).toDouble() * 1.2)
                          : 5),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _analytics.asMap().entries.map((entry) {
                            return FlSpot(entry.key.toDouble(), entry.value.searchCount.toDouble());
                          }).toList(),
                          isCurved: true,
                          color: Colors.lightBlueAccent,
                          gradient: const LinearGradient(
                            colors: [
                              Colors.cyanAccent,
                              Colors.blueAccent,
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          barWidth: 3,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, bar, index) {
                              return FlDotCirclePainter(
                                radius: 3,
                                color: Colors.blue,
                                strokeWidth: 1,
                                strokeColor: Colors.white,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                Colors.blueAccent.withOpacity(0.3),
                                Colors.cyanAccent.withOpacity(0),
                              ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Dữ liệu chi tiết gần đây',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _analytics.length,
              itemBuilder: (context, index) {
                final analytic = _analytics[_analytics.length - 1 - index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: ListTile(
                      leading: const Icon(Icons.calendar_today, color: Colors.blueGrey),
                      title: Text(
                        'Ngày: ${_formatListDate(analytic.timestamp)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          '${analytic.searchCount} lượt',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      onTap: () {
                        _showDetailsDialog(analytic.timestamp);
                      },
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),
            const Text(
              'Danh sách Sách yêu thích của tất cả User',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey),
            ),
            const SizedBox(height: 16),
            _favoriteBooks.isEmpty
                ? const Center(child: Text('Không có sách yêu thích nào.'))
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _favoriteBooks.length,
              itemBuilder: (context, index) {
                final book = _favoriteBooks[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  child: ListTile(
                    leading: const Icon(Icons.book, size: 20, color: Colors.deepOrange),
                    title: Text(
                      book['title'] ?? 'Không có tiêu đề',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      'Tác giả: ${book['author'] ?? 'Không rõ'} - User ID: ${book['userId'] ?? 'N/A'}',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    trailing: book['coverUrl'] != null && book['coverUrl'].isNotEmpty
                        ? SizedBox(
                      width: 40,
                      height: 60,
                      child: Image.network(
                        book['coverUrl'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 30, color: Colors.grey),
                      ),
                    )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    onTap: () {
                      _showFavoriteBookDetailsDialog(book); // Gọi hàm hiển thị chi tiết
                    },
                  ),
                );
              },
            ),
          ],
        ),
      )
          : const Center(
        child: Text(
          'Bạn không có quyền truy cập màn hình này',
          style: TextStyle(fontSize: 16, color: Colors.redAccent),
        ),
      ),
    );
  }
}