import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Screens
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/login_screen.dart';
import 'screens/search_results_screen.dart';
import 'screens/favorite_books_screen.dart';
import 'screens/admin_user_management_screen.dart';
import 'screens/admin_analytics_screen.dart';
import 'screens/admin_notification_screen.dart';
import 'screens/admin_traffic_screen.dart';

// Services & Utils
import 'utils/theme_provider.dart';
import 'services/auth_service.dart';
import 'widgets/bottom_navigation.dart';

Future<void> logAppOpenEvent() async {
  try {
    await FirebaseFirestore.instance.collection('app_traffic').add({
      'event_type': 'app_open',
      'timestamp': FieldValue.serverTimestamp(),
    });
    print('✅ Đã ghi nhận sự kiện mở app vào Firestore.');
  } catch (e) {
    print('❌ Lỗi ghi log app_open: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Gọi ghi log khi mở app
  logAppOpenEvent();

  await FirebaseMessaging.instance.subscribeToTopic('all_users');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Tìm kiếm Sách',
            // Sử dụng theme từ provider để Dark Mode áp dụng toàn app
            theme: themeProvider.themeData,
            debugShowCheckedModeBanner: false,
            initialRoute: '/',
            routes: {
              '/': (context) => const AuthWrapper(),
              '/login': (context) => LoginScreen(),
              '/home': (context) => const MainScreen(),
              '/search-results': (context) => SearchResultsScreen(query: ''),
              '/favorites': (context) => FavoriteBooksScreen(),
              '/admin/users': (context) => AdminUserManagementScreen(),
              '/admin/analytics': (context) => AdminAnalyticsScreen(),
              '/admin/notifications': (context) => const AdminNotificationScreen(),
              '/admin/traffic': (context) => const AdminTrafficScreen(),
            },
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Consumer đảm bảo rebuild khi auth thay đổi (Provider.of cũng listen mặc định,
    // nhưng Consumer rõ ràng hơn cho luồng đăng nhập/đăng xuất).
    return Consumer<AuthService>(
      builder: (context, auth, _) {
        return auth.isLoggedIn ? const MainScreen() : LoginScreen();
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Danh sách các màn hình chính (Đã bỏ HistoryScreen)
  final List<Widget> _screens = const [
    HomeScreen(),
    SettingsScreen(), // Chỉ còn lại Trang chủ (Index 0) và Cài đặt (Index 1)
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack giúp giữ trạng thái của các tab khi chuyển đổi
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigation(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}