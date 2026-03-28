# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.3] - 2026-03-28

### ✨ Thêm mới (Added)
- **Phân trang kết quả tìm kiếm:** Màn `SearchResultsScreen` tải trước **30** kết quả (gom Google Books + TruyenFull); kéo gần cuối danh sách sẽ tự tải thêm **15** cuốn mỗi lần cho đến khi hết dữ liệu. `GoogleBooksApi` hỗ trợ `startIndex` / `maxResults`; `TruyenFullScraper` hỗ trợ tham số `page` cho các trang sau. Hằng số `searchInitialBatchSize` / `searchLoadMoreBatchSize` trong `Constants`.

### 🛠 Sửa lỗi (Fixed)
- **Đăng nhập / điều hướng:** Sau đăng xuất không còn dùng `pushReplacementNamed('/login')` (tránh mất `AuthWrapper` ở route `'/'`). Đăng nhập thành công dùng `_navigateAfterAuthSuccess()`: `pop` nếu mở Login bằng stack, còn không thì `pushNamedAndRemoveUntil('/', …)` để về trang chủ ngay, không cần thoát app.
- **`AuthWrapper`:** Bọc bằng `Consumer<AuthService>` để rebuild đúng khi trạng thái đăng nhập thay đổi.
- **Google Sign-In:** Sửa luồng trả về `UserCredential` sau khi đăng nhập; bỏ qua điều hướng khi người dùng hủy chọn tài khoản Google.

### ⚡ Hiệu năng & kiến trúc (Performance)
- **Tìm kiếm:** `TruyenFullScraper` mặc định không “cào sâu” từng trang chi tiết lúc tìm kiếm (`fetchDetails: false`); chỉ tải HTML danh sách + thông tin cơ bản. Chi tiết TruyenFull được tải khi mở `BookDetailScreen` (giảm thời gian loading màn kết quả).
- **HTTP:** Thêm timeout (8s) cho request Google Books API và TruyenFull để tránh treo lâu khi mạng chậm.

### 🔐 Xác thực & Firestore (Auth)
- **`AuthService`:** Cache `firestoreRole` (`user` / `admin`) ngay sau `_ensureUserDocumentExists`; getter `isRoleReady` để UI chờ đồng bộ xong. User mới không có document: ghi `role: user` như trước; đọc lại role sau `set` để hiển thị đúng.
- **`SettingsScreen`:** Dùng `authService.firestoreRole` và `isRoleReady` thay vì tự `getCurrentUser()` một lần trong `initState` (tránh sai / chậm hiển thị quyền sau đăng nhập).
- **`isAdmin()`:** Ưu tiên `firestoreRole` đã cache khi có.

---

## [2.0.2] - 2026-03-26

### ✨ Thêm mới (Added)
- **Hệ thống xác thực:** Tích hợp phương thức đăng nhập và đăng ký bằng Email/Mật khẩu bên cạnh Google Sign-In.
- **Bộ lọc người dùng:** Thêm tính năng sắp xếp danh sách theo Tên (A-Z), Thời gian tạo (Mới nhất/Cũ nhất) và Lọc theo quyền Quản trị viên.
- **Tương tác biểu đồ:** Thêm hiệu ứng chạm (Touch interaction) cho biểu đồ tròn, hiển thị số lượt cụ thể khi nhấn vào từng phần.
- **Thoát ứng dụng:** Nút "Quay lại sau" tại màn hình đăng nhập giờ đây cho phép thoát ứng dụng an toàn qua hệ thống.

### 🎨 Cải thiện giao diện (UI/UX)
- **Tối ưu tốc độ:** Rút ngắn thời gian Animation màn hình Login giúp cảm giác ứng dụng phản hồi nhanh hơn.
- **Dashboard Admin:** Thiết kế lại trang Phân tích (Analytics) theo phong cách hiện đại, sử dụng thẻ Card bo góc và màu sắc đồng bộ.
- **Chú thích biểu đồ:** Thêm bảng chú thích (Legend) cho tất cả biểu đồ tròn và biểu đồ cột để dễ dàng theo dõi dữ liệu.
- **Quản lý người dùng:** Nâng cấp giao diện danh sách User với Huy hiệu quyền (Role Badge) và các nút hành động trực quan.

### 🛠 Sửa lỗi (Fixed)
- **Lỗi tràn viền (Overflow):** Khắc phục triệt để lỗi hiển thị trên các thiết bị màn hình hẹp (4.4px overflow).
- **Lỗi hình ảnh:** Sửa lỗi "Invalid image data" khi tải logo Google bằng cách chuyển sang định dạng PNG.
- **Lỗi màn hình đen:** Sửa lỗi điều hướng khiến màn hình bị đen sau khi đăng nhập thành công.
- **Lỗi hiển thị biểu đồ:** Sửa lỗi Tooltip bị che khuất khi nhấn vào các cột dữ liệu cao nhất.

---

## [2.0.0] - 2026-03-25

### Added
- **Multi-source Search**: Tích hợp bộ cào dữ liệu (**TruyenFull Scraper**) mở rộng kho truyện chữ Việt Nam (Tiên hiệp, Ngôn tình, Kiếm hiệp...).
- **In-app Reader Pro**: Trình đọc sách tràn viền (Full-screen), loại bỏ hoàn toàn khoảng trắng dư thừa ở AppBar.
- **Smart Ad-Blocker**: Hệ thống chặn quảng cáo đa tầng (CSS + JS Patrol) tự động tiêu diệt popup và banner quảng cáo theo thời gian thực.
- **Auto Dark Mode**: Tính năng tự động đảo ngược màu sắc trang web (Smart Invert) đồng bộ với giao diện tối của ứng dụng.
- **Navigation Tools**: Thêm nút "Lên đầu trang" (Scroll-to-top) và hệ thống nút điều hướng trong suốt cực lớn.
- **Pinch-to-zoom**: Hỗ trợ thu phóng hai ngón tay trên Android WebView cho mọi nguồn truyện.

### Changed
- **Concurrent Search**: Tối ưu hóa hiệu năng tìm kiếm bằng cách gọi đa nguồn song song thông qua `Future.wait`.
- **Deep Scraping**: Nâng cấp bộ cào để lấy chi tiết Thể loại, Mô tả chi tiết, Trạng thái truyện và Đánh giá người dùng.
- **UI Optimization**: Cải thiện độ mượt khi cuộn trang (Scrolling Physics) cho trình duyệt tích hợp.

### Fixed
- Lỗi thiếu tham số `language` bắt buộc trong Model `Book`.
- Lỗi `ERR_CLEARTEXT_NOT_PERMITTED` bằng cách ép buộc giao thức HTTPS.
- Xử lý ngoại lệ khi nguồn dữ liệu bên thứ ba gặp lỗi kết nối (Graceful Error Handling).

---

## [1.0.1] - 2025-05-24

### Added
- Cập nhật chức năng thống kê nâng cao và biểu đồ phân tích dữ liệu (`fl_chart`).
- Thêm tính năng theo dõi lưu lượng tìm kiếm từ người dùng thực tế.
- Trực quan hóa dữ liệu sách yêu thích và lượt truy cập cho Admin.
- Chức năng quản lý phân quyền người dùng (Admin/User) chi tiết.
- Tích hợp logic truy xuất Firestore theo vai trò người dùng.
- Video demo giới thiệu tính năng trên YouTube.

---

## [1.0.0] - 2025-05-22

### Added
- Khởi tạo các tính năng quản trị cốt lõi (Thống kê, Thông báo, Quản lý người dùng).
- Xây dựng mô hình dữ liệu chuẩn cho `Analytics`, `FavoriteBook`, `UserModel`.
- Tích hợp **Firebase Functions** xử lý logic backend.

### Changed
- Nâng cấp Flutter SDK lên phiên bản **3.29.2**.
- Cập nhật toàn bộ hệ sinh thái Firebase (Core, Auth, Firestore, Messaging, Functions).
- Tối ưu hóa Android Manifest cho Adaptive Icons và App Queries.

### Fixed
- Khắc phục lỗi `MissingPluginException` cho các thư viện `share_plus` và `url_launcher` trên Android.

### Removed
- Loại bỏ các tài nguyên icon cũ (`ic_launcher.png`) không còn sử dụng.