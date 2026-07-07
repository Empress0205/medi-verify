# 🛡️ MediVerify — AI-Powered Medicine Authentication App

A professional Flutter mobile application for verifying medicine authenticity using AI-powered QR/barcode scanning.

---

## 📁 Folder Structure

```
mediverify/
├── lib/
│   ├── main.dart                          # App entry point, routes, theme setup
│   │
│   ├── theme/
│   │   └── app_theme.dart                 # Colors, gradients, typography, shadows
│   │
│   ├── models/
│   │   └── scan_record.dart               # ScanRecord model + VerificationStatus enum
│   │
│   ├── services/
│   │   └── app_state.dart                 # AppState ChangeNotifier (state management)
│   │
│   ├── widgets/
│   │   └── shared_widgets.dart            # Reusable UI components:
│   │                                      #   - GradientHeader
│   │                                      #   - StatsCard
│   │                                      #   - QuickActionCard
│   │                                      #   - StatusBadge
│   │                                      #   - ScanHistoryTile
│   │                                      #   - MediBottomNav (custom bottom nav)
│   │
│   └── screens/
│       ├── onboarding/
│       │   └── onboarding_screen.dart     # 3-page onboarding with smooth page indicator
│       │
│       ├── home/
│       │   ├── home_screen.dart           # Dashboard: stats, quick actions, recent scans
│       │   └── main_shell.dart            # Bottom nav shell (IndexedStack)
│       │
│       ├── scan/
│       │   └── scan_screen.dart           # Camera viewfinder, scan animation, demo mode
│       │
│       ├── result/
│       │   └── result_screen.dart         # Verification result: details, confidence, actions
│       │
│       ├── history/
│       │   └── history_screen.dart        # Scan history with search + filter chips
│       │
│       ├── report/
│       │   └── report_screen.dart         # Counterfeit report form + success state
│       │
│       └── help/
│           └── help_screen.dart           # FAQ accordion, how-it-works, safety tips
│
├── android/
│   └── app/src/main/AndroidManifest.xml   # Camera, storage, internet permissions
│
├── assets/
│   ├── images/                            # (add app images here)
│   └── icons/                            # (add custom icons here)
│
└── pubspec.yaml                           # Dependencies
```

---

## 🖥️ Screens Overview

| Screen | Route | Description |
|--------|-------|-------------|
| Onboarding | `/onboarding` | 3-page intro with smooth page indicator |
| Home | `/main` | Dashboard with stats, quick actions, recent scans |
| Scan | `/scan` | Camera scanner with animated scan line |
| Result | `/result` | AI verification result with confidence score |
| History | `/history` | Filterable scan history with search |
| Report | `/report` | Counterfeit report form |
| Help | `/help` | FAQ, how-it-works, safety tips |

---

## 🎨 Design System

### Colors
| Token | Hex | Usage |
|-------|-----|-------|
| `primary` | `#00A878` | Brand green, CTAs, nav |
| `accent` | `#00C9A7` | Gradient accent |
| `danger` | `#E05C2A` | Counterfeit alerts |
| `success` | `#27AE60` | Verified status |
| `warning` | `#F5A623` | Unknown status |
| `info` | `#2F80ED` | History action |

### Typography
- **Font**: Poppins (Google Fonts)
- **Weights**: 400 (body) · 500 (medium) · 600 (semibold) · 700 (bold)

---

## 📦 Key Dependencies

| Package | Purpose |
|---------|---------|
| `provider` | State management |
| `google_fonts` | Poppins font |
| `mobile_scanner` | QR/barcode scanning |
| `image_picker` | Gallery image selection |
| `smooth_page_indicator` | Onboarding dots |
| `uuid` | Unique scan IDs |
| `permission_handler` | Camera permissions |

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK ≥ 3.0.0
- Dart ≥ 3.0.0
- Android Studio / Xcode

### Installation

```bash
# 1. Clone or copy the project
cd mediverify

# 2. Install dependencies
flutter pub get

# 3. Create asset folders
mkdir -p assets/images assets/icons

# 4. Run on device/emulator
flutter run

# 5. Build APK for Android
flutter build apk --release

# 6. Build for iOS
flutter build ios --release
```

### iOS Setup (Info.plist)
Add these entries to `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>MediVerify needs camera access to scan medicine barcodes</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>MediVerify needs photo access to scan images from gallery</string>
```

---

## 🏗️ Architecture

```
User Action
    │
    ▼
Screen Widget  ──reads──►  AppState (ChangeNotifier)
    │                           │
    │                           ▼
    │                      ScanRecord (Model)
    │
    ▼
Shared Widgets (reusable UI components)
```

- **State**: Provider + ChangeNotifier
- **Navigation**: Named routes (push/pop)
- **Data**: In-memory with sample data (ready for API integration)

---

## 🔧 Customization

### Adding Real Backend
Replace the demo scan logic in `scan_screen.dart`:
```dart
// In _startDemo(), replace with actual API call:
final result = await ApiService.verifyScan(scannedCode);
```

### Adding Real Camera
The `mobile_scanner` package is included. Replace the mock camera in `scan_screen.dart`:
```dart
// Replace _buildCameraGrid() with:
MobileScanner(
  onDetect: (capture) {
    final barcode = capture.barcodes.first;
    _processBarcode(barcode.rawValue);
  },
)
```

---

## 📱 Supported Platforms
- ✅ Android (API 21+)
- ✅ iOS (13.0+)

---

## 🤝 Contributing
Built with ❤️ for public health safety. Report issues or contribute improvements via pull requests.