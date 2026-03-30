# 📚 Tìm Kiếm Sách (Book Search App) - Ultimate Edition v2.0.4

[![Flutter](https://img.shields.io/badge/Flutter-3.29.2-blue.svg)](https://flutter.dev/)
[![Firebase](https://img.shields.io/badge/Firebase-Powered-orange.svg)](https://firebase.google.com/)
[![Version](https://img.shields.io/badge/Version-2.0.5-green.svg)](#)

**Tìm Kiếm Sách** là một ứng dụng di động đa nền tảng mạnh mẽ, kết hợp giữa hệ sinh thái **Flutter** và **Firebase**. Ứng dụng mang đến trải nghiệm đọc sách "tất cả trong một" nhờ khả năng tổng hợp dữ liệu từ 4 nguồn lớn cùng hệ thống lọc thể loại thông minh.

---

## 🎥 Video Demo & Preview

⚡ Hiện tại ứng dụng đã cập nhật lên phiên bản mới và đã thêm/cải thiện đáng kể chức năng và giao diện, video demo cho phiên bản mới sẽ sớm được cập nhật

Bạn có thể xem video giới thiệu tại đây:

👉 **[Xem Video Demo v1.0.1 trên YouTube](https://youtu.be/s3EeOYbCrl0?si=GE2SGLBO_agpzHvt)**

---

## 🚀 Có gì mới ở phiên bản 2.0.4?

*   **🔍 Tìm kiếm 4 nguồn song song**: Kết hợp dữ liệu từ **Google Books**, **Open Library**, **TruyenFull** và **Mê Truyện Chữ**.
*   **🏷️ Hệ thống Lọc thông minh**: 
    *   Thanh lọc 27 thể loại chuyên sâu (Tiên hiệp, Ngôn tình, Sách học thuật, Truyện tranh...).
    *   Tự động ánh xạ từ khóa tiếng Anh (`subject mapping`) để tìm kiếm chính xác trên các thư viện quốc tế.
*   **🎨 Giao diện Thể loại Mới**: Các thẻ thể loại tại Trang chủ được thiết kế lại với màu sắc đặc trưng, sinh động.
*   **⚡ Tối ưu hiệu năng**: Cải thiện tốc độ tải trang và xử lý phân trang (Infinite Scroll) mượt mà cho đa nguồn.

---

## ✨ Tính Năng Cốt Lõi

### 👤 Dành Cho Người Dùng (Users)
*   **🔍 Hybrid Search Engine**: Tìm kiếm đồng thời sách giấy, ebook quốc tế và truyện chữ Việt Nam.
*   **📖 In-app Reader Pro**:
    *   **Smart Ad-Blocker**: Chặn sạch quảng cáo từ các nguồn web truyện.
    *   **Auto Dark Mode**: Đảo màu trang web đồng bộ với giao diện ứng dụng.
    *   **Pinch-to-zoom**: Hỗ trợ thu phóng mượt mà.
*   **❤️ Đồng bộ đám mây**: Lưu yêu thích và lịch sử tìm kiếm qua Firebase Firestore.

### 🛡️ Dành Cho Quản Trị Viên (Admins)
*   **📊 Dashboard Thống kê**: Biểu đồ phân tích lưu lượng và xu hướng đọc sách (`fl_chart`).
*   **👥 Quản lý User**: Phân quyền Admin/User và quản lý tài khoản chuyên sâu.

---

## 🛠️ Công Nghệ Sử Dụng

| Thành phần | Công nghệ / Thư viện |
| :--- | :--- |
| **Framework** | Flutter (SDK >=3.0.0) |
| **API/Scraping** | Google Books, Open Library, TruyenFull, Metruyenchu |
| **Backend** | Firebase (Auth, Firestore, Messaging, Functions) |
| **Networking** | `http`, `html` (Web Scraping), `webview_flutter` |

---

## 📂 Cấu Trúc Thư Mục

```text
lib/
├── api/          # Google Books, Open Library, TruyenFull, Metruyenchu
├── models/       # Book, User, Analytics models
├── screens/      # Home, SearchResults, Reader, Admin panels
├── services/     # Firebase & Database logic
└── widgets/      # BookCard, CategoryBar, CustomSearchBar
```

---

## 📜 Nhật Ký Thay Đổi (Changelog)

Xem chi tiết lịch sử cập nhật tại file **[CHANGELOG.md](./CHANGELOG.md)**.

---

## 🚀 Hướng Dẫn Chạy App

1. **Cài đặt dependencies**: `flutter pub get`
2. **Cấu hình Firebase**: Thêm `google-services.json` vào `android/app/`.
3. **Run**: `flutter run`

---
## License
Dự án này được phát hành dưới giấy phép [GNU GPL v3](LICENSE).
---
> Phiên bản v2.0.4 mang đến sự lột xác về khả năng tìm kiếm và trải nghiệm người dùng. Cảm ơn bạn đã đồng hành cùng **Tìm Kiếm Sách**!
