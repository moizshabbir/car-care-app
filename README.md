# CarCareApp 🚗

A comprehensive vehicle maintenance tracking app built with Flutter. Track fuel costs, maintenance work, and parts purchases with smart OCR receipt scanning.

## Features

- **🔐 Authentication** — Email/password and Google Sign-In via Firebase Auth
- **📷 Smart OCR Scanning** — Auto-detect receipt type (fuel, POS, mechanic bill) and extract structured data
- **⛽ Fuel Logging** — Log refueling with station name, liters, cost, and odometer captured via OCR
- **🔧 Maintenance Tracking** — Record repairs, services, and parts purchases
- **📊 Reports** — Three-tab reports: Refueling history, Maintenance timeline, Parts & Tools purchased
- **📱 Odometer Capture** — Take a photo of your odometer during refueling for automatic reading extraction
- **🧾 POS Receipt Scanning** — Scan auto parts store receipts to create individual transaction entries
- **📝 Mechanic Bill Scanning** — Scan handwritten mechanic bills with editable fields
- **💰 Cost-per-KM** — Calculate and share your vehicle's cost per kilometer
- **🔔 Notifications** — Configurable reminders for fuel, service, and odometer checks
- **🌙 Dark Theme** — Premium dark UI with #135BEC accent color and Inter font
- **📶 Offline-First** — Works offline with Hive local storage, syncs to Firestore when online

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.x |
| State Management | BLoC (flutter_bloc) |
| Authentication | Firebase Auth + Google Sign-In |
| Database (Remote) | Cloud Firestore |
| Database (Local) | Hive |
| OCR | Google ML Kit Text Recognition |
| DI | GetIt + Injectable |
| Analytics | Firebase Analytics + Crashlytics |

## Architecture

Clean Architecture with three layers per feature:

```
lib/
├── core/                   # Shared services, theme, config
│   ├── services/           # OCR, Location, Analytics, Receipt Parser
│   ├── theme/              # AppTheme (light/dark)
│   └── config/             # Firebase module
├── features/
│   ├── auth/               # Login, Signup, Forgot Password
│   │   ├── data/           # AuthRepositoryImpl
│   │   ├── domain/         # AuthRepository (abstract)
│   │   └── presentation/   # AuthBloc, LoginPage, SignupPage
│   ├── logs/               # Fuel & Maintenance logging
│   │   ├── data/           # Models, LogRepositoryImpl
│   │   ├── domain/         # LogRepository, LogStatsService
│   │   └── presentation/   # QuickLogBloc, DashboardBloc, Pages
│   ├── vehicles/           # Vehicle management (Garage)
│   ├── reports/            # Reports with 3 tabs
│   └── settings/           # Profile, Notifications, Privacy, Help
├── injection.dart          # GetIt + Injectable setup
└── main.dart               # App entry point with AuthGate
```

## Getting Started

### Prerequisites

- Flutter SDK 3.x
- Firebase project with `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)

### Setup

```bash
# Clone the repository
git clone <repo-url>
cd car-care-app

# Install dependencies
flutter pub get

# Generate injectable config (if needed)
flutter pub run build_runner build --delete-conflicting-outputs

# Run the app
flutter run
```

### Firebase Setup

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable **Authentication** (Email/Password + Google)
3. Enable **Cloud Firestore**
4. Download and place config files:
   - Android: `android/app/google-services.json`
   - iOS: `ios/Runner/GoogleService-Info.plist`

## Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/core/services/receipt_parser_service_test.dart
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License.