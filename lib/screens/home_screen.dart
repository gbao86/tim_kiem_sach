import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/constants.dart';
import '../services/auth_service.dart';
import '../utils/theme_provider.dart';
import '../widgets/search_bar.dart';
import 'search_results_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 1.0, curve: Curves.easeInOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    if (query.trim().isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SearchResultsScreen(query: query),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authService = Provider.of<AuthService>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          Constants.appName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
      ),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeInAnimation,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDarkMode
                      ? [
                    Theme.of(context).scaffoldBackgroundColor,
                    Color(0xFF1A1A2E),
                  ]
                      : [
                    Color(0xFFE3F2FD),
                    Colors.white,
                  ],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.menu_book_rounded,
                    size: size.width * 0.3,
                    color: Theme.of(context).primaryColor,
                  ),
                  SizedBox(height: 24),
                  Text(
                    Constants.welcomeMessage,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 40),
                  CustomSearchBar(
                    controller: _searchController,
                    onSearch: _onSearch,
                    hintText: Constants.searchHint,
                  ),
                  SizedBox(height: 30),
                  if (!authService.isLoggedIn)
                    ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          await authService.signInWithGoogle();
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(Constants.errorLoginFailed)),
                          );
                        }
                      },
                      icon: Icon(Icons.login),
                      label: Text(Constants.loginWithGoogle),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  if (authService.isLoggedIn)
                    Text(
                      'Xin chào, ${authService.user?.displayName ?? 'Người dùng'}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}