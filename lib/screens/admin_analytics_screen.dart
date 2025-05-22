import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../services/admin_service.dart';
import '../models/analytics.dart';
import '../services/auth_service.dart';
import '../widgets/loading_indicator.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  @override
  _AdminAnalyticsScreenState createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  final AdminService _adminService = AdminService();

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    return FutureBuilder<bool>(
      future: authService.isAdmin(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!) {
          return Scaffold(
            body: const Center(child: Text('Access denied: Admins only')),
          );
        }
        return Scaffold(
          appBar: AppBar(title: const Text('Thống kê')),
          body: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Text('Thống kê tìm kiếm', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(
                  height: 200,
                  child: FutureBuilder<List<AnalyticsData>>(
                    future: AdminService().getSearchAnalytics(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: LoadingIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      final analytics = snapshot.data ?? [];
                      return BarChart(
                        BarChartData(
                          gridData: const FlGridData(show: true),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final index = value.toInt();
                                  if (index < 0 || index >= analytics.length) return const Text('');
                                  return Text(analytics[index].bookTitle);
                                },
                                reservedSize: 40,
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                            ),
                          ),
                          borderData: FlBorderData(show: true),
                          barGroups: analytics
                              .asMap()
                              .entries
                              .map((entry) => BarChartGroupData(
                            x: entry.key,
                            barRods: [
                              BarChartRodData(
                                toY: entry.value.searchCount.toDouble(),
                                color: Colors.blue,
                              ),
                            ],
                          ))
                              .toList(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Thống kê lưu lượng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(
                  height: 200,
                  child: FutureBuilder<List<AnalyticsData>>(
                    future: AdminService().getTrafficAnalytics(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: LoadingIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      final analytics = snapshot.data ?? [];
                      return LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: true),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final index = value.toInt();
                                  if (index < 0 || index >= analytics.length) return const Text('');
                                  final date = analytics[index].timestamp;
                                  return Text('${date.day}/${date.month}');
                                },
                                reservedSize: 40,
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                            ),
                          ),
                          borderData: FlBorderData(show: true),
                          lineBarsData: [
                            LineChartBarData(
                              spots: analytics
                                  .asMap()
                                  .entries
                                  .map((entry) => FlSpot(entry.key.toDouble(), entry.value.searchCount.toDouble()))
                                  .toList(),
                              isCurved: true,
                              color: Colors.green,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}