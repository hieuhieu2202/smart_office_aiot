# Rack Monitor Feature

Rack Monitor feature được tổ chức theo **Clean Architecture** và sử dụng **GetX** để quản lý state.

## 📁 Cấu trúc thư mục

```
lib/features/racks_monitor/
├── data/                           # Data Layer
│   ├── datasources/               # Nguồn dữ liệu (API calls)
│   │   └── rack_monitor_remote_data_source.dart
│   ├── models/                    # Data models (JSON parsing)
│   │   └── rack_models.dart
│   └── repositories/              # Repository implementations
│       └── rack_monitor_repository_impl.dart
│
├── domain/                         # Domain Layer (Business Logic)
│   ├── entities/                  # Business entities
│   │   └── rack_entities.dart
│   ├── repositories/              # Repository interfaces
│   │   └── rack_monitor_repository.dart
│   └── usecases/                  # Use cases (business operations)
│       ├── get_rack_locations.dart
│       └── get_rack_monitoring_data.dart
│
├── presentation/                   # Presentation Layer (UI)
│   ├── controllers/               # GetX Controllers
│   │   ├── rack_monitor_binding.dart    # Dependency Injection
│   │   └── rack_monitor_controller.dart # State management
│   ├── pages/                     # Screens/Pages
│   │   └── rack_monitor_page.dart
│   ├── utils/                     # Presentation utilities
│   │   └── rack_data_utils.dart
│   └── widgets/                   # Reusable UI components
│       ├── rack_chart_footer.dart
│       ├── rack_filter_sheet.dart
│       ├── rack_kpi_summary.dart
│       ├── rack_left_panel.dart
│       ├── rack_list_filter.dart
│       ├── rack_monitor_header.dart
│       ├── rack_monitor_insights.dart
│       ├── rack_monitor_states.dart
│       ├── rack_panel_card.dart
│       ├── rack_partition.dart
│       ├── rack_pass_by_model_chart.dart
│       ├── rack_slot_status_donut.dart
│       ├── rack_status_utils.dart
│       ├── rack_wip_pass_summary.dart
│       ├── rack_yield_rate_gauge.dart
│       └── widgets.dart          # Barrel export
│
└── racks_monitor.dart             # Main export file
```

## 🏗️ Clean Architecture Layers

### 1. **Domain Layer** (Lớp Business Logic)
- **Entities**: Các đối tượng nghiệp vụ thuần túy, không phụ thuộc vào framework
- **Repositories**: Interface định nghĩa contract cho data layer
- **Use Cases**: Các business operations cụ thể

### 2. **Data Layer** (Lớp Dữ liệu)
- **Data Sources**: Giao tiếp với API, database, local storage
- **Models**: Data models có thể parse JSON, extends từ entities
- **Repository Implementations**: Triển khai interfaces từ domain layer

### 3. **Presentation Layer** (Lớp Giao diện)
- **Controllers**: GetX controllers quản lý state và business logic cho UI
- **Pages**: Các màn hình chính
- **Widgets**: Các component UI có thể tái sử dụng
- **Utils**: Các tiện ích cho presentation

## 🔄 Data Flow

```
UI (Page/Widget)
    ↓
Controller (GetX)
    ↓
Use Case
    ↓
Repository Interface (Domain)
    ↓
Repository Implementation (Data)
    ↓
Data Source
    ↓
API
```

## 📦 Dependency Injection với GetX

File `rack_monitor_binding.dart` quản lý việc inject dependencies:

```dart
RackMonitorBinding(
  initialFactory: 'F16',
  initialFloor: '3F',
  tag: 'unique_tag',
).dependencies();
```

## 🚀 Cách sử dụng

### Import feature:
```dart
import 'package:smart_factory/features/racks_monitor/racks_monitor.dart';
```

### Navigate đến page:
```dart
Get.to(() => RackMonitorPage(
  initialFactory: 'F16',
  initialFloor: '3F',
  initialRoom: 'ROOM1',
));
```

### Hoặc với custom tag:
```dart
Get.to(() => RackMonitorPage(
  initialFactory: 'F16',
  controllerTag: 'custom_rack_monitor_1',
));
```

## 🎯 Lợi ích của Clean Architecture

1. **Separation of Concerns**: Mỗi layer có trách nhiệm riêng biệt
2. **Testability**: Dễ dàng test từng layer độc lập
3. **Maintainability**: Code dễ bảo trì và mở rộng
4. **Reusability**: Entities và use cases có thể tái sử dụng
5. **Independence**: UI không phụ thuộc vào implementation details

## 🔧 Testing

- **Domain Layer**: Test use cases với mock repositories
- **Data Layer**: Test repositories với mock data sources
- **Presentation**: Test controllers với mock use cases

## 📝 Notes

- Sử dụng GetX cho state management và dependency injection
- Entities là immutable (const constructors)
- Models extend từ entities và thêm fromJson/toJson
- Controllers không được import trực tiếp service/API classes

