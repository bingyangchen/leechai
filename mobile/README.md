# Mobile App

## Prerequisites

- Flutter SDK (>=3.11.0)
- Android Studio (for Android development)
- Xcode (for iOS development, macOS only)
- CocoaPods (for iOS dependencies)

## Quick Start

Ensure the backend server is running locally first.

1. From project root, go to mobile:

   ```bash
   cd mobile
   ```

2. Install dependencies:

   ```bash
   flutter pub get
   ```

3. Run the app:

   ```bash
   flutter run
   ```

## Dependency Management

- From the `mobile` directory: `flutter pub add {DEPENDENCY}` or `flutter pub remove {DEPENDENCY}`.
- For iOS-only dependencies: go to `mobile/ios` and run `pod install`.
