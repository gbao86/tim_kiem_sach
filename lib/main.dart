import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'screens/home_screen.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/login_screen.dart';
import 'screens/book_detail_screen.dart';
import 'screens/search_results_screen.dart';
import 'screens/favorite_books_screen.dart';
import 'screens/admin_user_management_screen.dart';
import 'screens/admin_analytics_screen.dart';
import 'screens/admin_notification_screen.dart';
import 'screens/admin_traffic_screen.dart';
import 'utils/theme_provider.dart';
import 'services/auth_service.dart';
import 'widgets/bottom_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
            theme: themeProvider.themeData,
            debugShowCheckedModeBanner: false,
            initialRoute: '/',
            routes: {
              '/': (context) => const AuthWrapper(),
              '/login': (context) => LoginScreen(),
              '/home': (context) => MainScreen(),
              '/search-results': (context) => SearchResultsScreen(query: ''),
              '/favorites': (context) => FavoriteBooksScreen(),
              '/admin/users': (context) => AdminUserManagementScreen(),
              '/admin/analytics': (context) => AdminAnalyticsScreen(),
              '/admin/notifications': (context) => AdminNotificationScreen(),
              '/admin/traffic': (context) => AdminTrafficScreen(),
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
    final authService = Provider.of<AuthService>(context);
    return authService.isLoggedIn ? MainScreen() : LoginScreen();
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final List<Widget> _screens = [
    HomeScreen(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigation(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}