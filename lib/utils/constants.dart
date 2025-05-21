class Constants {
  // API
  static const String googleBooksBaseUrl = 'https://www.googleapis.com/books/v1/volumes';
  static const int maxResults = 20;

  // Firestore collections
  static const String usersCollection = 'users';
  static const String historyCollection = 'search_history';

  // Shared Preferences keys
  static const String keyDarkMode = 'dark_mode';
  static const String keyIsLoggedIn = 'is_logged_in';

  // Error messages
  static const String errorLoading = 'Không thể tải sách. Vui lòng thử lại sau.';
  static const String errorLoginFailed = 'Đăng nhập thất bại. Vui lòng thử lại.';
  static const String errorNoInternet = 'Không có kết nối internet. Vui lòng kiểm tra lại.';

  // Labels
  static const String appName = 'Tìm kiếm Sách';
  static const String home = 'Trang chủ';
  static const String history = 'Lịch sử';
  static const String settings = 'Cài đặt';
  static const String search = 'Tìm kiếm';
  static const String searchHint = 'Nhập tên sách, tác giả hoặc nội dung...';
  static const String noResults = 'Không tìm thấy kết quả';
  static const String noHistory = 'Bạn chưa có lịch sử tìm kiếm';
  static const String darkMode = 'Chế độ tối';
  static const String login = 'Đăng nhập';
  static const String logout = 'Đăng xuất';
  static const String loginWithGoogle = 'Đăng nhập với Google';
  static const String welcomeMessage = 'Chào mừng đến với Ứng dụng Tìm kiếm Sách';
}