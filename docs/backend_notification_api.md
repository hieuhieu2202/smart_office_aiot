# Hướng dẫn triển khai backend thông báo cho SendNoti

Tài liệu này mô tả cách thiết kế cơ sở dữ liệu, luồng đồng bộ và các API cần có để ứng dụng di động chỉ nhận thông báo từ server (không gửi ngược lại), đồng thời đảm bảo phát hiện cập nhật ứng dụng ngay khi admin tạo bản ghi mới.

## 1. Kiến trúc tổng thể

```
Admin Dashboard  --->  REST API (ASP.NET Core)
                                  |-- SQL Server (EF Core Code First)
Ứng dụng di động  <---  SSE (Server-Sent Events) & REST
```

* **REST API** cung cấp CRUD cho admin (tạo phiên bản app, tạo thông báo) và endpoint đọc cho client.
* **SSE stream** giúp client nhận thông báo mới ngay khi có bản ghi được chèn vào bảng `Notifications`.
* **SQL Server** lưu toàn bộ trạng thái. EF Core đảm nhận migration tự động.

## 2. Thiết kế cơ sở dữ liệu

### 2.1 Bảng `AppVersions`

| Cột | Kiểu | Mô tả |
| --- | ---- | ----- |
| `AppVersionId` | `INT IDENTITY` | Khóa chính. |
| `Platform` | `NVARCHAR(20)` | `android`, `ios`, ... |
| `VersionName` | `NVARCHAR(50)` | Chuỗi phiên bản hiển thị (ví dụ: `1.4.2`). |
| `BuildNumber` | `INT` | Dùng đối chiếu với client (ví dụ build 54). |
| `MinSupported` | `NVARCHAR(50)` | Phiên bản tối thiểu mà server chấp nhận. |
| `ReleaseNotes` | `NVARCHAR(MAX)` | Ghi chú phát hành (Markdown/HTML). |
| `FileUrl` | `NVARCHAR(255)` | Đường dẫn tải APK/IPA. |
| `FileChecksum` | `NVARCHAR(128)` | Hash SHA256 để kiểm tra toàn vẹn. |
| `FileSizeBytes` | `BIGINT` | Dữ liệu hiển thị tiến trình tải. |
| `ReleaseDate` | `DATETIME2` | Dùng sắp xếp/hiển thị. |

```sql
CREATE TABLE AppVersions (
    AppVersionId   INT IDENTITY(1,1) PRIMARY KEY,
    Platform       NVARCHAR(20)  NOT NULL,
    VersionName    NVARCHAR(50)  NOT NULL,
    BuildNumber    INT           NOT NULL,
    MinSupported   NVARCHAR(50)  NOT NULL,
    ReleaseNotes   NVARCHAR(MAX) NULL,
    FileUrl        NVARCHAR(255) NOT NULL,
    FileChecksum   NVARCHAR(128) NULL,
    FileSizeBytes  BIGINT        NULL,
    ReleaseDate    DATETIME2     NOT NULL DEFAULT SYSUTCDATETIME()
);
GO
CREATE UNIQUE INDEX IX_AppVersions_Platform_Build
    ON AppVersions(Platform, BuildNumber DESC);
```

### 2.2 Bảng `Notifications`

| Cột | Kiểu | Mô tả |
| --- | ---- | ----- |
| `NotificationId` | `INT IDENTITY` | Khóa chính. |
| `Title` | `NVARCHAR(150)` | Tiêu đề ngắn gọn. |
| `Message` | `NVARCHAR(MAX)` | Nội dung chi tiết (Markdown/HTML). |
| `Link` | `NVARCHAR(255)` | Link thao tác (tùy chọn). |
| `FileUrl` | `NVARCHAR(255)` | Đường dẫn file đính kèm (tùy chọn). |
| `FileName` | `NVARCHAR(150)` | Hiển thị tên file cho client. |
| `MimeType` | `NVARCHAR(100)` | `application/pdf`, `image/png`, ... |
| `CreatedAt` | `DATETIME2` | Thời điểm tạo (UTC). |
| `IsActive` | `BIT` | Cho phép ẩn thông báo mà không xóa khỏi DB. |
| `AppVersionId` | `INT` | Khóa ngoại (nếu thông báo liên quan tới bản cập nhật). |

```sql
CREATE TABLE Notifications (
    NotificationId INT IDENTITY(1,1) PRIMARY KEY,
    Title          NVARCHAR(150) NOT NULL,
    Message        NVARCHAR(MAX) NOT NULL,
    Link           NVARCHAR(255) NULL,
    FileUrl        NVARCHAR(255) NULL,
    FileName       NVARCHAR(150) NULL,
    MimeType       NVARCHAR(100) NULL,
    CreatedAt      DATETIME2     NOT NULL DEFAULT SYSUTCDATETIME(),
    IsActive       BIT           NOT NULL DEFAULT 1,
    AppVersionId   INT           NULL,
    CONSTRAINT FK_Notifications_AppVersions_AppVersionId
        FOREIGN KEY (AppVersionId)
        REFERENCES AppVersions(AppVersionId)
        ON DELETE SET NULL
);
GO
CREATE INDEX IX_Notifications_Active_CreatedAt
    ON Notifications(IsActive, CreatedAt DESC);
```

### 2.3 Bảng `NotificationPushQueue` (tùy chọn)

Nếu muốn tách xử lý realtime, tạo bảng hàng đợi để worker lấy ra và bắn SSE/WebSocket:

```sql
CREATE TABLE NotificationPushQueue (
    QueueId        BIGINT IDENTITY(1,1) PRIMARY KEY,
    NotificationId INT          NOT NULL,
    CreatedAt      DATETIME2    NOT NULL DEFAULT SYSUTCDATETIME(),
    ProcessedAt    DATETIME2    NULL,
    RetryCount     INT          NOT NULL DEFAULT 0
);
```

Worker (hoặc trigger) sẽ thêm bản ghi vào bảng này mỗi khi có thông báo mới, sau đó SSE service đọc và phát đi.

## 3. Luồng phát hiện và phát SSE

1. Admin tạo thông báo mới (`Notifications.IsActive = 1`).
2. `NotificationService` gọi `DbContext.SaveChangesAsync()`.
3. Trong `SaveChanges`, override `AfterSaveChanges` hoặc dùng `DomainEvent` để push `NotificationPushQueue`.
4. `NotificationsStreamController` giữ một `Channel<NotificationDto>` và mỗi kết nối SSE sẽ đọc từ channel.
5. Worker đọc từ bảng/queue liên tục, khi thấy bản ghi mới → load dữ liệu → push xuống channel.

> Không nên truy vấn DB mỗi X giây. Sử dụng queue + SignalR/SSE để phát sự kiện ngay lập tức, tránh tình trạng client phải bấm "Load" thủ công.

## 4. API mẫu

### 4.1 Admin

#### `POST /api/control/app-version/upload`
Dùng `multipart/form-data` để upload file cài đặt.

| Field | Bắt buộc | Mô tả |
| ----- | -------- | ----- |
| `platform` | ✔ | `android`, `ios`, ... |
| `latest` | ✔ | Phiên bản dạng chuỗi (`1.4.2`). |
| `build` | ✔ | Build number (`54`). |
| `minSupported` | ✔ | Ví dụ `1.2.0`. |
| `notesVi` | ✖ | Ghi chú tiếng Việt. |
| `notesEn` | ✖ | Ghi chú tiếng Anh. |
| `file` | ✔ | APK/IPA.

**Phản hồi mẫu**
```json
{
  "appVersionId": 7,
  "platform": "android",
  "versionName": "1.4.2",
  "buildNumber": 54,
  "fileUrl": "https://10.220.130.117:2222/SendNoti/uploads/builds/app-1.4.2.apk",
  "fileChecksum": "a2b3c4d5...",
  "fileSizeBytes": 45875200,
  "releaseDate": "2025-09-17T09:30:00Z"
}
```

#### `POST /api/control/send-notification-json`
```json
{
  "title": "🔧 Bảo trì hệ thống",
  "message": "Hệ thống bảo trì lúc 23h ngày 20/09",
  "link": "https://portal.example.com/maintenance",
  "fileUrl": null,
  "fileName": null,
  "mimeType": null,
  "appVersionId": null
}
```

#### `POST /api/control/send-notification`
Multipart để gắn file:

| Field | Bắt buộc | Mô tả |
| ----- | -------- | ----- |
| `title` | ✔ | Tiêu đề. |
| `message` | ✔ | Nội dung chi tiết. |
| `link` | ✖ | Link hành động. |
| `appVersionId` | ✖ | Gắn vào bản cập nhật. |
| `file` | ✖ | File đính kèm. |

**Phản hồi**: trả về DTO giống JSON.

### 4.2 Client (ứng dụng di động)

#### `GET /api/control/get-notifications`
Query:
- `page`: mặc định `1`.
- `pageSize`: tối đa `50` để hạn chế tải dữ liệu.

**Response**
```json
{
  "total": 124,
  "page": 1,
  "pageSize": 20,
  "items": [
    {
      "notificationId": 321,
      "title": "Cập nhật 1.4.2",
      "message": "Fix lỗi đăng nhập",
      "link": null,
      "fileUrl": null,
      "fileName": null,
      "mimeType": null,
      "createdAt": "2025-09-17T09:30:00Z",
      "appVersion": {
        "versionName": "1.4.2",
        "buildNumber": 54,
        "releaseNotes": "Fix lỗi đăng nhập, tối ưu hiệu năng",
        "fileUrl": "https://.../app-1.4.2.apk"
      }
    }
  ]
}
```

#### `GET /api/control/notifications-stream`
*Trả về SSE.* Mỗi sự kiện có dạng:

```
data: {"notificationId":321,"title":"Cập nhật 1.4.2","message":"Fix lỗi đăng nhập","createdAt":"2025-09-17T09:30:00Z"}

```

Client cần:
1. Mở kết nối lâu dài (giữ `http.Client().send(...)`).
2. Nếu kết nối lỗi → retry với backoff (1s, 2s, 5s...).
3. Khi nhận sự kiện → parse JSON → thêm vào danh sách và cập nhật badge chưa đọc.

#### `GET /api/control/check-app-version`
Query: `currentVersion=1.3.0&platform=android&build=51`.

Response:
```json
{
  "currentVersion": "1.3.0",
  "currentBuild": 51,
  "serverVersion": "1.4.2",
  "serverBuild": 54,
  "updateAvailable": true,
  "forceUpdate": false,
  "latestRelease": {
    "versionName": "1.4.2",
    "buildNumber": 54,
    "minSupported": "1.2.0",
    "releaseNotes": "- Fix lỗi đăng nhập\n- Tối ưu hiệu năng",
    "fileUrl": "https://.../app-1.4.2.apk",
    "fileChecksum": "a2b3c4d5...",
    "fileSizeBytes": 45875200
  }
}
```

Logic server:
- So sánh `currentBuild` với build mới nhất trong bảng `AppVersions` (cùng `Platform`).
- Nếu `currentBuild < latest.BuildNumber` ⇒ `updateAvailable = true`.
- Nếu `currentBuild < latest.MinSupported` ⇒ `forceUpdate = true`.

#### `GET /api/control/app-version`
Trả về manifest hiện tại (có thể dùng caching):
```json
{
  "platform": "android",
  "latest": "1.4.2",
  "build": 54,
  "minSupported": "1.2.0",
  "notesVi": "Fix lỗi đăng nhập",
  "notesEn": "Bug fixes",
  "fileUrl": "https://.../app-1.4.2.apk",
  "fileChecksum": "a2b3c4d5",
  "fileSizeBytes": 45875200
}
```

## 5. Gợi ý cài đặt trong ứng dụng Flutter

1. **Không đặt logic vào `main.dart`**: tạo các service (`NotificationService`, `UpdateService`) và inject bằng `GetIt` hoặc `Provider`.
2. **NotificationController**
   - Giữ `List<NotificationEntry>`.
   - Mở SSE ngay khi ứng dụng khởi động → khi có sự kiện mới: thêm vào đầu danh sách, show snackbar 2s, cập nhật badge.
   - Định kỳ đồng bộ (ví dụ mỗi 10 phút) để đề phòng SSE bị gián đoạn.
3. **Badge chưa đọc**
   - Lưu `Set<int>` các `NotificationId` đã đọc vào `GetStorage`/`SharedPreferences`.
   - Mỗi lần mở chi tiết → đánh dấu đã đọc và cập nhật badge.
4. **Chi tiết thông báo**
   - Khi người dùng bấm vào card → điều hướng tới `NotificationDetailScreen` hiển thị `message`, link, file đính kèm.

## 6. Checklist kiểm thử

| Kịch bản | Mô tả |
| --------| ----- |
| Thêm thông báo mới | Admin dùng API JSON → client đang mở nhận ngay qua SSE + snackbar 2s. |
| Kết nối SSE rớt | Tắt mạng 5s → mở lại → client retry và nhận thông báo mới sau khi reconnect. |
| Badge chưa đọc | Có 3 thông báo chưa xem → badge hiển thị `3`. Sau khi mở từng thông báo → badge giảm tương ứng. |
| Cập nhật ứng dụng | Admin upload bản mới với `forceUpdate=true` → client gọi `/check-app-version` → hiển thị dialog bắt cập nhật. |

## 7. Triển khai production

* Bật HTTPS (Reverse proxy Nginx/Traefik) để tránh lỗi CORS khi client kết nối SSE.
* Cấu hình header `Cache-Control: no-cache` cho endpoint SSE.
* Dọn file upload cũ bằng background job để tránh chiếm dung lượng.
* Ghi log mỗi lần client check version để theo dõi tỷ lệ người dùng cập nhật.

---
Nếu cần mẫu project ASP.NET Core tối giản, có thể tạo Web API với EF Core scaffold theo cấu trúc trên và tách controller thành 2 nhóm:
- `ControlController` (admin)
- `ClientController` (public)

Trong ứng dụng Flutter, chỉ dùng nhóm public (`get-notifications`, `notifications-stream`, `check-app-version`, `app-version`).
