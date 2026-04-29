# Nexus Photo - Frontend

## Overview

- Flutter client for Nexus Photo that handles login, gallery browsing, uploads, collections, trash, sharing, and metadata viewing.
- Platforms supported: Android, iOS, Web, Windows, macOS, Linux.

## Tech Stack

- Flutter: >=3.38.4 (pubspec.lock)
- Dart: >=3.10.3 <4.0.0 (pubspec.lock); SDK constraint ^3.8.0 (pubspec.yaml)

### Packages (pubspec.yaml)

| Package                     | Version | Purpose                                   |
| --------------------------- | ------- | ----------------------------------------- |
| cupertino_icons             | ^1.0.8  | iOS-style icons                           |
| http                        | ^1.1.0  | API calls                                 |
| file_picker                 | ^6.1.1  | Image selection (used for uploads)        |
| mime                        | ^1.0.6  | MIME type detection                       |
| shared_preferences          | ^2.2.2  | Token persistence                         |
| url_launcher                | ^6.3.1  | Open external links (share targets, maps) |
| share_plus                  | ^10.0.2 | Share photos and links                    |
| intl                        | ^0.19.0 | Date/time formatting                      |
| flutter_staggered_grid_view | ^0.7.0  | Masonry grid layout                       |
| shimmer                     | ^3.0.0  | Loading placeholders                      |

### Dev Packages

| Package       | Version | Purpose    |
| ------------- | ------- | ---------- |
| flutter_lints | ^5.0.0  | Lint rules |

image_picker: Coming Soon (not in pubspec.yaml; uploads use file_picker).

## Project Structure

```text
BockPhotosFlutterUI/
├── .dockerignore
├── .flutter-plugins-dependencies
├── .gitignore
├── .metadata
├── Dockerfile
├── README.md
├── analysis_options.yaml
├── nginx.conf
├── pubspec.lock
├── pubspec.yaml
├── assets/
│   └── auth_side.png
├── lib/
│   ├── config.dart
│   ├── main.dart
│   ├── screens/
│   │   ├── collections_screen.dart
│   │   ├── favourites_screen.dart
│   │   ├── gallery_screen.dart
│   │   ├── login_screen.dart
│   │   ├── notifications_screen.dart
│   │   ├── photo_viewer_screen.dart
│   │   ├── profile_screen.dart
│   │   ├── search_screen.dart
│   │   ├── signup_screen.dart
│   │   ├── trash_screen.dart
│   │   └── upload_screen.dart
│   ├── services/
│   │   ├── api_client.dart
│   │   ├── auth_service.dart
│   │   ├── health_service.dart
│   │   ├── photo_service.dart
│   │   └── token_store.dart
│   └── widgets/
│       ├── authenticated_image.dart
│       └── photo_tile.dart
├── test/
│   └── widget_test.dart
├── web/
│   ├── favicon.png
│   ├── index.html
│   ├── manifest.json
│   └── icons/
│       ├── Icon-192.png
│       ├── Icon-512.png
│       ├── Icon-maskable-192.png
│       └── Icon-maskable-512.png
├── android/
│   ├── .gitignore
│   ├── app/
│   │   ├── build.gradle.kts
│   │   └── src/
│   │       ├── debug/AndroidManifest.xml
│   │       ├── profile/AndroidManifest.xml
│   │       └── main/
│   │           ├── AndroidManifest.xml
│   │           ├── kotlin/com/example/hynorvixx_psql_frotend/MainActivity.kt
│   │           └── res/
│   │               ├── drawable/launch_background.xml
│   │               ├── drawable-v21/launch_background.xml
│   │               ├── values/styles.xml
│   │               ├── values-night/styles.xml
│   │               ├── mipmap-hdpi/ic_launcher.png
│   │               ├── mipmap-mdpi/ic_launcher.png
│   │               ├── mipmap-xhdpi/ic_launcher.png
│   │               ├── mipmap-xxhdpi/ic_launcher.png
│   │               └── mipmap-xxxhdpi/ic_launcher.png
│   ├── build.gradle.kts
│   ├── gradle.properties
│   ├── settings.gradle.kts
│   └── gradle/
│       └── wrapper/gradle-wrapper.properties
├── ios/
│   ├── .gitignore
│   ├── Flutter/
│   │   ├── AppFrameworkInfo.plist
│   │   ├── Debug.xcconfig
│   │   └── Release.xcconfig
│   ├── Runner/
│   │   ├── AppDelegate.swift
│   │   ├── Info.plist
│   │   ├── Runner-Bridging-Header.h
│   │   ├── Base.lproj/
│   │   │   ├── LaunchScreen.storyboard
│   │   │   └── Main.storyboard
│   │   └── Assets.xcassets/
│   │       ├── AppIcon.appiconset/
│   │       │   ├── Contents.json
│   │       │   ├── Icon-App-20x20@1x.png
│   │       │   ├── Icon-App-20x20@2x.png
│   │       │   ├── Icon-App-20x20@3x.png
│   │       │   ├── Icon-App-29x29@1x.png
│   │       │   ├── Icon-App-29x29@2x.png
│   │       │   ├── Icon-App-29x29@3x.png
│   │       │   ├── Icon-App-40x40@2x.png
│   │       │   ├── Icon-App-40x40@3x.png
│   │       │   ├── Icon-App-60x60@2x.png
│   │       │   ├── Icon-App-60x60@3x.png
│   │       │   ├── Icon-App-76x76@1x.png
│   │       │   ├── Icon-App-76x76@2x.png
│   │       │   ├── Icon-App-83.5x83.5@2x.png
│   │       │   └── Icon-App-1024x1024@1x.png
│   │       └── LaunchImage.imageset/
│   │           ├── Contents.json
│   │           ├── LaunchImage.png
│   │           ├── LaunchImage@2x.png
│   │           ├── LaunchImage@3x.png
│   │           └── README.md
│   ├── Runner.xcodeproj/
│   │   ├── project.pbxproj
│   │   ├── xcshareddata/xcschemes/Runner.xcscheme
│   │   └── project.xcworkspace/
│   │       ├── contents.xcworkspacedata
│   │       └── xcshareddata/
│   │           ├── IDEWorkspaceChecks.plist
│   │           └── WorkspaceSettings.xcsettings
│   ├── Runner.xcworkspace/
│   │   ├── contents.xcworkspacedata
│   │   └── xcshareddata/
│   │       ├── IDEWorkspaceChecks.plist
│   │       └── WorkspaceSettings.xcsettings
│   └── RunnerTests/
│       └── RunnerTests.swift
├── macos/
│   ├── .gitignore
│   ├── Flutter/
│   │   ├── Flutter-Debug.xcconfig
│   │   ├── Flutter-Release.xcconfig
│   │   └── GeneratedPluginRegistrant.swift
│   ├── Runner/
│   │   ├── AppDelegate.swift
│   │   ├── DebugProfile.entitlements
│   │   ├── Info.plist
│   │   ├── MainFlutterWindow.swift
│   │   ├── Release.entitlements
│   │   ├── Base.lproj/MainMenu.xib
│   │   ├── Assets.xcassets/AppIcon.appiconset/Contents.json
│   │   ├── Assets.xcassets/AppIcon.appiconset/app_icon_16.png
│   │   ├── Assets.xcassets/AppIcon.appiconset/app_icon_32.png
│   │   ├── Assets.xcassets/AppIcon.appiconset/app_icon_64.png
│   │   ├── Assets.xcassets/AppIcon.appiconset/app_icon_128.png
│   │   ├── Assets.xcassets/AppIcon.appiconset/app_icon_256.png
│   │   ├── Assets.xcassets/AppIcon.appiconset/app_icon_512.png
│   │   └── Assets.xcassets/AppIcon.appiconset/app_icon_1024.png
│   │   └── Configs/
│   │       ├── AppInfo.xcconfig
│   │       ├── Debug.xcconfig
│   │       ├── Release.xcconfig
│   │       └── Warnings.xcconfig
│   ├── Runner.xcodeproj/
│   │   ├── project.pbxproj
│   │   ├── xcshareddata/xcschemes/Runner.xcscheme
│   │   └── project.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist
│   ├── Runner.xcworkspace/
│   │   ├── contents.xcworkspacedata
│   │   └── xcshareddata/IDEWorkspaceChecks.plist
│   └── RunnerTests/RunnerTests.swift
├── linux/
│   ├── .gitignore
│   ├── CMakeLists.txt
│   ├── flutter/
│   │   ├── CMakeLists.txt
│   │   ├── generated_plugin_registrant.cc
│   │   ├── generated_plugin_registrant.h
│   │   └── generated_plugins.cmake
│   └── runner/
│       ├── CMakeLists.txt
│       ├── main.cc
│       ├── my_application.cc
│       └── my_application.h
└── windows/
    ├── .gitignore
    ├── CMakeLists.txt
    ├── flutter/
    │   ├── CMakeLists.txt
    │   ├── generated_plugin_registrant.cc
    │   ├── generated_plugin_registrant.h
    │   └── generated_plugins.cmake
    └── runner/
        ├── CMakeLists.txt
        ├── Runner.rc
        ├── flutter_window.cpp
        ├── flutter_window.h
        ├── main.cpp
        ├── resource.h
        ├── runner.exe.manifest
        ├── utils.cpp
        ├── utils.h
        ├── win32_window.cpp
        ├── win32_window.h
        └── resources/app_icon.ico
```

## Screens

### Home Screen (Gallery)

- Shows the main masonry grid of photos with responsive columns.
- Key features: selection mode, share, add to collection, move to trash, favorites.
- Screenshot description: multi-column photo grid with contextual actions.

### Login Screen

- Email and password login (JWT-based).
- Backend health banner appears when /health is unreachable.

### Register Screen

- Email and password registration with validation.
- NexusID auto-generation display: Coming Soon.

### Collections Screen

- Grid of user collections with cover photos and counts.
- Create, rename, delete, and add/remove photos.

### Trash Screen

- Displays deleted photos.
- Restore or permanently delete.

### Full Screen Viewer

- Swipe navigation across photos.
- Pinch to zoom and metadata info panel.

### Profile Screen

- Basic profile screen with sign out.
- Username edit: Coming Soon.

### Upload Screen

- File picker upload (local or S3 presigned flow via backend).

### Favourites Screen

- Shows starred photos and allows toggling star state.

### Search Screen

- Placeholder UI for search. Coming Soon.

### Notifications Screen

- Placeholder UI for notifications. Coming Soon.

## Features

- [x] Photo grid with responsive layout
- [x] Full screen photo viewer
- [x] Swipe between photos
- [x] Pinch to zoom
- [x] Star / favourite photos
- [x] Move to trash
- [x] Restore from trash
- [x] Collections (create, add, remove, rename, delete)
- [x] Share photos (mobile share or share link)
- [x] Image metadata display
- [x] JWT authentication (email + password)
- [x] Profile sign out
- [ ] NexusID authentication (Coming Soon)
- [ ] Search backend integration (Coming Soon)
- [ ] Notifications (Coming Soon)

## Environment Variables / Configuration

API base URL is configured in `lib/config.dart`:

```dart
class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  static const String publicBucketBaseUrl = String.fromEnvironment(
    'PUBLIC_BUCKET_BASE_URL',
    defaultValue: '',
  );
}
```

To change the backend URL:

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000
```

Optional public bucket/CDN base URL:

```bash
flutter run -d chrome --dart-define=PUBLIC_BUCKET_BASE_URL=https://your-bucket.s3.amazonaws.com
```

## Installation & Setup

1. Install Flutter SDK (>=3.38.4 recommended).
2. Clone the repository.
3. Navigate to the frontend folder:
   ```bash
   cd BockPhotosFlutterUI
   ```
4. Install dependencies:
   ```bash
   flutter pub get
   ```
5. Update API base URL in `lib/config.dart` or pass `--dart-define=API_BASE_URL=...`.
6. Run on Android:
   ```bash
   flutter run -d android
   ```
7. Run on Web:
   ```bash
   flutter run -d chrome
   ```
8. Build APK:
   ```bash
   flutter build apk
   ```
9. Build for Web:
   ```bash
   flutter build web
   ```

## App Theme

- Primary color (seed): #914294
- Background color: #FAF2FB
- AppBar color: #914294
- Elevated button color: #914294
- Bottom navigation selected item: #914294
- Font: default Flutter font

## API Integration

API calls use `ApiClient` with automatic JWT injection and refresh:

```dart
final response = await http.get(
  Uri.parse('${AppConfig.apiBaseUrl}/api/photos'),
  headers: {'Authorization': 'Bearer $token'},
);
```

JWT storage:

- Access token is cached in memory and persisted in SharedPreferences.
- Refresh token is stored in SharedPreferences.

## State Management

- Stateful widgets with `setState`.
- Shared auth state is handled through `TokenStore` and `ApiClient`.

## Navigation

```
Login -> Gallery -> Photo Viewer
               -> Upload
               -> Collections -> Collection Photos
               -> Favourites
               -> Trash
               -> Search
               -> Notifications
               -> Profile
```

## Known Issues / Troubleshooting

- Backend health degraded warning: verify `API_BASE_URL` and backend `/health` endpoint.
- Images not loading: verify backend storage settings and `PUBLIC_BUCKET_BASE_URL` when using S3.
- Login failing: verify backend is running and email/password credentials are valid. NexusID support is Coming Soon.
