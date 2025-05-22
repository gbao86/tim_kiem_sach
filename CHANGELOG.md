# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-05-22 11:44PM

### Added
- Thêm các tính năng quản trị mới (Thống kê, Thông báo, Quản lý người dùng, Quản lý truy cập).
- Thêm mô hình dữ liệu cho Analytics, FavoriteBook, UserModel.
- Tích hợp Firebase Functions cho các chức năng backend.

### Changed
- Cập nhật cấu hình Android Manifest cho các truy vấn ứng dụng và adaptive icon.
- Nâng cấp phiên bản `share_plus` lên 11.0.0.
- Nâng cấp phiên bản `url_launcher` lên 6.3.1.
- Cập nhật các dependency Firebase (core, auth, firestore, messaging, functions).
- Cập nhật phiên bản Flutter SDK lên 3.29.2.
- Cập nhật cấu hình Gradle và Android Gradle Plugin cho tương thích.

### Fixed
- Khắc phục lỗi `MissingPluginException` cho `share_plus` và `url_launcher` trên Android.

### Removed
- Xóa các file icon `ic_launcher.png` cũ.

### Security
- (Không có thay đổi bảo mật cụ thể trong phiên bản này)