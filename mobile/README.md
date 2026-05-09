# Mobile App

## Prerequisites

- Flutter SDK (>=3.11.0)
- Android Studio (for Android development)
- Xcode (for iOS development, macOS only)
- CocoaPods (for iOS dependencies)

## Quick Start

Ensure that the API server is running locally first.

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

## How to Manage Dependencies

- **Step 1**: From the `mobile` directory: `flutter pub add {DEPENDENCY}` or `flutter pub remove {DEPENDENCY}`.
- **Step 2**: For iOS-only dependencies: go to `mobile/ios` and run `pod install`.

## Release

### Build for iOS

0. Remember to update `version` in `pubspec.yaml`.

1. From project root, go to `mobile`:

   ```bash
   cd mobile
   ```

2. Install dependencies:

   ```bash
   flutter pub get
   ```

3. Build iOS archive and export `.ipa`:

   ```bash
   flutter build ipa --release
   ```

4. Open Transporter (Mac App Store app), then drag the generated `.ipa` file into Transporter:

   ```text
   build/ios/ipa/*.ipa
   ```
