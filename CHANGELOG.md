# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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