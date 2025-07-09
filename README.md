# smart_office_aiot

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


Smart Factory App
0: :flutter pub run icons_launcher:create đọc tạo Icon
1: Màn hình splash Screen (21/5) ( cần sửa thêm hiệu ứng chuyển động các màn hình mượt khi đến bước 2)
2: Màn hình login (khi bấm vao chỗ nhập user và pass bàn phím đẩy lên và giữ nguyên layout )
    2.1 -> Mục tiêu login bằng ICVET
    2.2 -> Luu trạng thái đăng nhập và thoát 
3: Thông báo kết quả login nêus sai
4: Tính năng Mode dark và light (22/5)
5: Tính năng kết nối tới winscp gửi ảnh
6: Tải ảnh. zoom ảnh.
## Đăng nhập lại khi đã lưu tài khoản
Khi ứng dụng đã nhớ `username`, trường tài khoản sẽ tự động hiển thị giá trị đã lưu. Nhập mật khẩu của tài khoản hiện tại để tiếp tục đăng nhập. Nếu muốn sử dụng tài khoản khác, chọn **Dùng tài khoản khác** dưới trường username, trường nhập sẽ xóa thông tin cũ và cho phép bạn nhập tên người dùng mới.

## Yêu cầu và cấu hình đăng nhập sinh trắc học
Ứng dụng có thể kích hoạt xác thực vân tay/Face ID thông qua gói `local_auth`. Thiết bị cần hỗ trợ sinh trắc học và đã thiết lập ít nhất một phương thức bảo mật.

Các bước cấu hình:
1. Thêm `local_auth` vào `pubspec.yaml` và chạy `flutter pub get`.
2. Android: khai báo quyền `USE_BIOMETRIC` trong `android/app/src/main/AndroidManifest.xml`.
3. iOS: thêm khóa `NSFaceIDUsageDescription` vào `ios/Runner/Info.plist`.
4. Trong màn hình đăng nhập, sử dụng `LocalAuthentication().authenticate()` để xác thực trước khi gọi API đăng nhập.
 

