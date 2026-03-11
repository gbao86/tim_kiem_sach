# 📚 Tìm Kiếm Sách (Book Search App)

**Tìm Kiếm Sách** là một ứng dụng di động đa nền tảng được phát triển trên nền tảng **Flutter**, kết hợp với hệ sinh thái **Firebase** để cung cấp một trải nghiệm toàn diện và liên tục cho người dùng. Ứng dụng không chỉ hỗ trợ người dùng tìm kiếm, lưu trữ sách yêu thích mà còn cung cấp một hệ thống quản trị chuyên sâu dành cho Admin để phân tích và quản lý dữ liệu.

---

### 🎥 Video Demo

Bạn có thể xem video giới thiệu tại đây:

👉 [Xem Video Demo trên YouTube](https://youtu.be/saU-wb5OcF8?si=IYv2xMcbLG_XW2UX)

---

## ✨ Tính Năng Nổi Bật

### 👤 Dành Cho Người Dùng (Users)

* **🔍 Tìm kiếm sách**: Tích hợp **Google Books API** giúp tìm kiếm sách nhanh chóng và chính xác.
* **❤️ Quản lý sách yêu thích**: Người dùng có thể lưu lại những cuốn sách mình yêu thích để dễ dàng xem lại.
* **📖 Lịch sử tìm kiếm**: Tự động lưu và hiển thị những từ khóa tìm kiếm gần đây.
* **🔐 Xác thực an toàn**: Đăng nhập nhanh chóng và bảo mật thông qua cấu hình Firebase Authentication.

### 🛡️ Dành Cho Quản Trị Viên (Admins)

* **📊 Thống kê & Phân tích**: Sử dụng `fl_chart` để trực quan hóa dữ liệu truy cập, lượng tìm kiếm và sách yêu thích bằng các biểu đồ sinh động.
* **👥 Quản lý người dùng**: Phân quyền chi tiết (Admin / User), xem danh sách người dùng và truy cập dữ liệu liên quan.
* **🔔 Quản lý thông báo**: Hệ thống gửi và quản lý thông báo qua **Firebase Cloud Messaging**.
* **📈 Xem nhật ký truy cập**: Theo dõi lưu lượng truy cập và hành vi tìm kiếm của người dùng trong ứng dụng.

---

## 🛠️ Công Nghệ Sử Dụng

* **Bộ khung (Framework)**: [Flutter](https://flutter.dev/) (phiên bản SDK >=3.0.0)
* **Quản lý trạng thái (State Management)**: `provider`
* **Dịch vụ Backend (BaaS)**: [Firebase](https://firebase.google.com/)
  * `firebase_core`, `firebase_auth`, `google_sign_in`
  * `cloud_firestore` (Lưu trữ dữ liệu)
  * `cloud_functions` (Các hàm logic backend)
  * `firebase_messaging` (Push notifications)
* **Giao diện & Tiện ích**:
  * `cached_network_image`: Tối ưu hóa tải ảnh.
  * `fl_chart`: Vẽ biểu đồ thống kê cao cấp.
  * `share_plus`, `url_launcher`: Chia sẻ liên kết và chuyển trang.
  * `intl`: Định dạng tiền tệ, ngày tháng.
* **Dịch vụ mạng**: `http` (Gọi API thư viện sách).

---

## 📂 Cấu Trúc Thư Mục Chính

Ứng dụng được tổ chức theo cấu trúc rõ ràng, dễ dàng mở rộng và bảo trì:

```text
lib/
├── api/          # Xử lý các yêu cầu HTTP (Google Books API)
├── models/       # Định nghĩa các Data Models (Book, User, Analytics,...)
├── screens/      # Giao diện người dùng (Home, Login, Search, Admin,...)
├── services/     # Tương tác với Database, Auth và Services bên thứ 3
├── utils/        # Hằng số, hàm hỗ trợ, cấu hình giao diện (theme)
├── widgets/      # Các thành phần giao diện dùng chung (BookCard, SearchBar,...)
└── main.dart     # Entry point của ứng dụng
```

---

## 🚀 Hướng Dẫn Cài Đặt (Getting Started)

### 👉 Yêu Cầu Hệ Thống
* Cài đặt **Flutter SDK** phiên bản ổn định mới nhất.
* Cài đặt **Android Studio** hoặc **Xcode** (cho iOS) với các công cụ phát triển cần thiết.
* Có sẵn file `google-services.json` (Android) và cấu hình Firebase phù hợp.

### 👉 Các Bước Chạy Ứng Dụng

1. **Clone mã nguồn về máy** (nếu bạn sử dụng git):
   ```bash
   git clone <địa_chỉ_repository_của_bạn>
   cd tim_kiem_sach
   ```

2. **Cài đặt các thư viện phụ thuộc (dependencies)**:
   ```bash
   flutter pub get
   ```

3. **Cấu hình Firebase**:
   * Đặt file `google-services.json` vào thư mục `android/app/`.
   * Thực hiện nạp đúng tham số môi trường và API key cho các dịch vụ Firebase nếu có.

4. **Chạy ứng dụng**:
   Bạn có thể chạy dự án trên máy ảo (Emulator) hoặc thiết bị thật (Physical device):
   ```bash
   flutter run
   ```

---

## 📜 Nhật Ký Thay Đổi (Changelog)

Để theo dõi các bản cập nhật mới nhất, thay đổi tính năng và sửa lỗi, vui lòng xem chi tiết tại file **[CHANGELOG.md](./CHANGELOG.md)**.

---

## 🤝 Giấy Phép & Phân Phối (License & Distribution)

Dự án này là mã nguồn kín, với tùy chọn xuất bản (publish_to) được vô hiệu hóa để đảm bảo đây là một private package (`publish_to: 'none'`). Xem thêm file [LICENSE](./LICENSE) (nếu được cung cấp) để nắm rõ chi tiết về điều khoản sử dụng.

> Cảm ơn bạn đã quan tâm đến dự án **Tìm Kiếm Sách**. Nếu có bất cứ câu hỏi nào, xin vui lòng kiểm tra source code hoặc liên hệ quản trị viên!
