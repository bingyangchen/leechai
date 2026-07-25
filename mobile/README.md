# Mobile App

## Prerequisites

- Flutter SDK (>=3.11.0)
- Android Studio (for Android development)
- Xcode (for iOS development, macOS only)
- CocoaPods (for iOS dependencies)

## Layered Architecture

Code under **`lib/`** matches the diagram: each **`features/<area>/`** has **`presentation/`**, **`domain/`**, **`data/`**, and optionally **`constants/`** beside those folders; **`core/`** owns **`AppDatabase`**, which runs each feature’s **`schema/`** migrations; **`shared/`** is reused widgets and theme.

```mermaid
flowchart TB
  subgraph entry_layer["Application entry"]
    main_dart["main.dart"]
    shell_dart["shell.dart"]
    main_dart --> shell_dart
  end

  subgraph presentation["presentation/"]
    pres_pages["pages/"]
    pres_widgets["widgets/"]
    pres_constants["constants/"]
    pres_pages --> pres_widgets
    pres_pages --> pres_constants
    pres_widgets --> pres_constants
  end

  subgraph feat_root["Feature root optional"]
    feat_constants["constants/"]
  end

  subgraph domain["domain/"]
    domain_files["*.dart — entities, enums, pure logic"]
  end

  subgraph data["data/"]
    data_repo["repositories/"]
    data_schema["schema/ — SQLite DDL & seeds"]
    data_svc["services/"]
    data_api["apis/ — HTTP wrappers & DTOs"]
    data_svc --> data_repo
    data_svc --> data_api
    data_repo --> domain_files
    data_svc --> domain_files
    data_schema -.->|some schemas| domain_files
  end

  subgraph core_layer["core/"]
    core_db["database — AppDatabase, schema.dart"]
    core_net["network — ApiClient"]
    core_auth["auth — credential_store, session events"]
    core_notif["notifications/"]
  end

  subgraph shared_layer["shared/"]
    shared_bundle["widgets • theme • scopes • utils • constants"]
  end

  main_dart --> core_notif

  shell_dart --> pres_pages

  pres_pages --> domain_files
  pres_widgets --> domain_files
  pres_constants --> domain_files

  pres_pages --> feat_constants
  pres_widgets --> feat_constants
  data_svc --> feat_constants

  pres_pages --> data_repo
  pres_pages --> data_svc
  pres_widgets --> data_repo
  pres_widgets --> data_svc

  pres_pages --> shared_bundle
  pres_widgets --> shared_bundle

  core_db --> data_schema
  data_repo --> core_db
  data_svc --> core_db

  data_api --> core_net
  data_svc --> core_net
  data_svc -.->|auth session events| core_auth
  data_repo -.->|credential adapters, auth| core_auth
```

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

## Launcher App Name (SSOT)

Desktop / home-screen display name is defined only in `pubspec.yaml` under `names_launcher`.

Do not hand-edit `Info.plist`, `*.lproj/InfoPlist.strings`, or Android `strings.xml` for the app name. After changing the config, regenerate:

```bash
cd mobile
dart run names_launcher:change
```

iOS includes `zh-Hant` in `names_launcher` so the binary ships `zh-Hant.lproj` (App Store product-page Languages can list Traditional Chinese). If you add another locale, also add that `.lproj` / `values-*` resource to the Xcode / Android project if the tool does not wire it automatically.

## 🚀 Release

### Build for iOS

0. Remember to update `version` in `pubspec.yaml`.

1. From project root, go to `mobile`:

   ```bash
   cd mobile
   ```

2. Install dependencies:

   ```bash
   flutter clean
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
