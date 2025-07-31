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

## Clean Room Dashboard

The project includes a complete dashboard for clean room monitoring.
It fetches sensor information from the backend APIs (customers, factories,
floors and rooms) and displays charts for current readings, historical data
and area statistics. Charts now include tooltips and visible markers for
better readability.

To open the dashboard after logging in:

1. From the home page choose the **Clean Room** module.
2. Use the filter button (top‑right) to select a date range and location.
3. The screen shows sensor overview numbers, room layout with sensor
positions and multiple charts (`SensorDataChartWidget`, `SensorHistoryChartWidget`,
`BarChartWidget` and `AreaChartWidget`).

These widgets live under `lib/screen/home/widget/clean_room/widget/` (with
subfolders like `charts/` and `layout/`; sensor marker pieces are in
`layout/marker/`) and are powered
by API calls in `lib/service/clean_room_api.dart`.

Sensor coordinates and the room image are fetched via the
`Location/GetConfigMapping` endpoint. The image is returned as a Base64 string
and the coordinates are used to place interactive markers on the layout.

Markers now change color based on sensor status. The dashboard checks the
`GetSensorDataOverview` endpoint: markers are **green** when data is available
for a sensor and **grey** when the sensor is offline.

Each marker starts with a small colored circle showing the sensor position.
An arrow points from the circle to a dark blue label with light horizontal
stripes. Depending on the configuration, this label can appear either to the
left or to the right of the dot so that markers do not overlap. The label
displays the sensor name and its **ON/OFF** status in green and the area name in
white. The circle stays visible so you can clearly see the exact location.

Tapping a marker opens a small dialog showing recent readings for that sensor.
 

