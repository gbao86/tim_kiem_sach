# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.4] - 2026-03-30

### ✨ Thêm mới (Added)
- **Đa nguồn dữ liệu cực lớn:** Tích hợp thêm **Open Library API** (sách quốc tế/học thuật) và **Mê Truyện Chữ Scraper** (kho truyện chữ Việt Nam khổng lồ).
- **Hệ thống lọc thể loại thông minh:** 
  - Thêm thanh lọc (Filter Bar) với 27 thể loại phổ biến (Tiên hiệp, Ngôn tình, Đam mỹ, Hệ thống, Sách học thuật, Truyện tranh...).
  - Tự động ánh xạ từ khóa tiếng Anh (`subject:searchKey`) khi tìm kiếm trên Google Books/Open Library để đảm bảo tính chính xác cao nhất.
- **Giao diện thẻ thể loại (Category Cards):** Thiết kế lại phần khám phá tại Trang chủ với màu sắc riêng biệt cho từng thể loại, giúp tăng trải nghiệm thị giác.

### 🛠 Sửa lỗi (Fixed)
- **Xử lý phân trang đa nguồn:** Khắc phục lỗi biến trạng thái `_metruyenExhausted` giúp luồng tải thêm (Load more) hoạt động chính xác khi kết hợp cả 4 nguồn dữ liệu cùng lúc.
- **Tính ổn định:** Cải thiện cơ chế `Future.wait` để app không bị treo nếu một trong các nguồn API gặp lỗi hoặc timeout.

---

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
... (giữ nguyên phần còn lại)
