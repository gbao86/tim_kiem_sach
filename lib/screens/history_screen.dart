import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/search_history.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';
import 'search_results_screen.dart';
import 'login_screen.dart';

class HistoryScreen extends StatelessWidget {
  final DatabaseService _databaseService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(Constants.history),
        elevation: 0,
        actions: [
          if (authService.isLoggedIn)
            IconButton(
              icon: Icon(Icons.delete_sweep),
              onPressed: () {
                _showClearHistoryDialog(context);
              },
              tooltip: 'Xóa tất cả lịch sử',
            ),
        ],
      ),
      body: !authService.isLoggedIn
          ? _buildNotLoggedInView(context)
          : _buildHistoryView(context),
    );
  }

  Widget _buildNotLoggedInView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Bạn cần đăng nhập để xem lịch sử tìm kiếm',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
            child: Text(Constants.login),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryView(BuildContext context) {
    return StreamBuilder<List<SearchHistory>>(
      stream: _databaseService.getSearchHistory(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 60, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  'Đã xảy ra lỗi khi tải lịch sử tìm kiếm',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(snapshot.error.toString()),
              ],
            ),
          );
        }

        final histories = snapshot.data ?? [];

        if (histories.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 80,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  Constants.noHistory,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: EdgeInsets.all(16),
          itemCount: histories.length,
          separatorBuilder: (context, index) => Divider(),
          itemBuilder: (context, index) {
            final history = histories[index];
            final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
            return Dismissible(
              key: Key(history.id),
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: EdgeInsets.only(right: 16),
                child: Icon(
                  Icons.delete,
                  color: Colors.white,
                ),
              ),
              direction: DismissDirection.endToStart,
              onDismissed: (direction) {
                _databaseService.deleteSearchHistoryItem(history.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Đã xóa "${history.query}" khỏi lịch sử')),
                );
              },
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Icon(
                    Icons.search,
                    color: Colors.white,
                  ),
                ),
                title: Text(
                  history.query,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Row(
                  children: [
                    Icon(Icons.access_time, size: 14),
                    SizedBox(width: 4),
                    Text(dateFormat.format(history.timestamp)),
                    SizedBox(width: 10),
                    Icon(Icons.book, size: 14),
                    SizedBox(width: 4),
                    Text('${history.resultCount} kết quả'),
                  ],
                ),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SearchResultsScreen(query: history.query),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  void _showClearHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Xóa lịch sử tìm kiếm'),
        content: Text('Bạn có chắc chắn muốn xóa tất cả lịch sử tìm kiếm không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              _databaseService.clearSearchHistory();
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Đã xóa tất cả lịch sử tìm kiếm')),
              );
            },
            child: Text(
              'Xóa',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}