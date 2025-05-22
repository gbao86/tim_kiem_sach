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

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
    _fetchAnalytics();
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
      final snapshot = await FirebaseFirestore.instance
          .collection('analytics')
          .orderBy('timestamp', descending: true)
          .limit(30)
          .get();
      final analytics = snapshot.docs
          .map((doc) => AnalyticsData.fromMap(doc.data()))
          .toList();
      if (mounted) {
        setState(() {
          _analytics = analytics;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    return formatter.format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lưu lượng truy cập'),
        centerTitle: true,
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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= _analytics.length) return const Text('');
                          final date = _analytics[index].timestamp;
                          return Text('${date.day}/${date.month}');
                        },
                        reservedSize: 30,
                        interval: 5,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) => Text('${value.toInt()}'),
                        reservedSize: 40,
                        interval: 10,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _analytics.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), entry.value.searchCount.toDouble());
                      }).toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 4,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Dữ liệu gần đây',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _analytics.length,
              itemBuilder: (context, index) {
                final analytic = _analytics[index];
                return ListTile(
                  title: Text('Sách: ${analytic.bookTitle}'),
                  subtitle: Text('Lượt tìm kiếm: ${analytic.searchCount} - ${_formatDateTime(analytic.timestamp)}'),
                );
              },
            ),
          ],
        ),
      )
          : const Center(
        child: Text('Bạn không có quyền truy cập màn hình này'),
      ),
    );
  }
}