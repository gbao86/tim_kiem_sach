# 📚 Tìm Kiếm Sách (Book Search App) - Ultimate Edition

[![Flutter](https://img.shields.io/badge/Flutter-3.29.2-blue.svg)](https://flutter.dev/)
[![Firebase](https://img.shields.io/badge/Firebase-Powered-orange.svg)](https://firebase.google.com/)
[![License](https://img.shields.io/badge/License-Private-red.svg)](#)

**Tìm Kiếm Sách** là một ứng dụng di động đa nền tảng mạnh mẽ, kết hợp giữa hệ sinh thái **Flutter** và **Firebase**. Ứng dụng mang đến trải nghiệm đọc sách "tất cả trong một" nhờ khả năng tổng hợp dữ liệu từ nhiều nguồn lớn (Global & Local) cùng trình đọc sách tối ưu hóa trải nghiệm người dùng.

---

## 🎥 Video Demo & Preview

Trải nghiệm thực tế các tính năng tìm kiếm đa nguồn và trình đọc sách thông minh:

👉 **[Xem Video Demo v1.0.1 trên YouTube](https://youtu.be/s3EeOYbCrl0?si=GE2SGLBO_agpzHvt)**

---

## ✨ Tính Năng Nổi Bật

### 👤 Dành Cho Người Dùng (Users)
*   **🔍 Tìm kiếm Đa nguồn (Hybrid Search)**: 
    *   Tích hợp **Google Books API** cho kho sách quốc tế và chính thống.
    *   Sử dụng **TruyenFull Scraper** (Deep Scraping) để truy cập hàng chục thể loại truyện chữ Việt Nam (Tiên hiệp, Ngôn tình, Kiếm hiệp...).
*   **📖 Trình đọc sách In-app Pro**:
    *   **Smart Ad-Blocker**: Tự động chặn popup, banner và quảng cáo rác từ các nguồn web.
    *   **Auto Dark Mode**: Tự động đảo màu (Smart Invert) trang web theo giao diện hệ thống.
    *   **Hỗ trợ Thu phóng**: Kích hoạt Pinch-to-zoom (2 ngón tay) cho mọi trang web.
    *   **Điều hướng nhanh**: Hệ thống nút chuyển trang trong suốt và nút "Lên đầu trang" (Scroll-to-top).
*   **❤️ Quản lý cá nhân**: Lưu sách yêu thích (Firestore), quản lý lịch sử tìm kiếm và đồng bộ tài khoản qua **Firebase Auth**.

### 🛡️ Dành Cho Quản Trị Viên (Admins)
*   **📊 Dashboard Thống kê**: Trực quan hóa dữ liệu truy cập và xu hướng tìm kiếm bằng biểu đồ **fl_chart**.
*   **👥 Quản lý Người dùng**: Phân quyền chi tiết (Admin/User) và theo dõi nhật ký hoạt động.
*   **🔔 Push Notifications**: Gửi thông báo đẩy qua **Firebase Cloud Messaging (FCM)**.

---

## 🛠️ Công Nghệ Sử Dụng

| Thành phần | Công nghệ / Thư viện |
| :--- | :--- |
| **Framework** | [Flutter](https://flutter.dev/) (SDK >=3.0.0) |
| **State Management** | `provider` |
| **Backend** | Firebase (Auth, Firestore, Messaging, Functions) |
| **Networking** | `http`, `html` (Web Scraping) |
| **Giao diện** | `webview_flutter`, `fl_chart`, `cached_network_image` |
| **Tiện ích** | `share_plus`, `intl`, `theme_provider` |

---

## 📂 Cấu Trúc Thư Mục Chính

```text
lib/
├── api/          # Xử lý HTTP Request & Web Scraper (TruyenFull)
├── models/       # Định nghĩa Data Models (Book, User, Analytics,...)
├── screens/      # Giao diện chính (Home, Reader, Admin, Auth,...)
├── services/     # Tương tác Firebase, Database & Business Logic
├── utils/        # Theme, Hằng số, Hàm hỗ trợ (Helper functions)
├── widgets/      # Các thành phần giao diện dùng chung (BookCard, SearchBar,...)
└── main.dart     # Entry point & Cấu hình Routes
---
```

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
