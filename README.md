# TeleVault

Back up your device photos & videos to a private Telegram chat via your own bot. No servers, no cloud accounts, just Telegram.

## Features

- Scans your device gallery using `photo_manager`.
- Uploads selected photos as Telegram **photos** and videos as Telegram **videos** via the Bot API.
- Live per-file upload progress and a queue.
- Persistent statistics: total files uploaded and total bytes transferred.
- Material 3 UI (light & dark).
- Graceful runtime permission handling for Android 13+ (READ_MEDIA_IMAGES / READ_MEDIA_VIDEO) and Android 12 and below (READ_EXTERNAL_STORAGE).
- No backend required.

## Requirements

- Flutter **3.35+** (Dart 3.4+)
- Android SDK with **compileSdk 36**, **targetSdk 36**, **minSdk 21**
- Gradle **8.10.2** (via wrapper) & Android Gradle Plugin **8.7.0**
- A Telegram Bot Token (from [@BotFather](https://t.me/BotFather)) and a Chat ID.

## Configure the bot

1. Talk to [@BotFather](https://t.me/BotFather) on Telegram, run `/newbot`, follow the prompts and copy the **bot token**.
2. Start a chat with your new bot (send it any message) OR add it to a group / channel.
3. Open `https://api.telegram.org/bot<TOKEN>/getUpdates` in a browser after sending a message to the bot. Find the `chat.id` value.
4. Open `lib/constants.dart` and paste the two values:

```dart
class AppConstants {
  static const String botToken = 'PASTE_YOUR_BOT_TOKEN_HERE';
  static const String chatId   = 'PASTE_YOUR_CHAT_ID_HERE';
}
```

## Build & run

```bash
flutter pub get
flutter run                    # debug on connected device
flutter build apk --release    # release APK
```

The release APK will be at `build/app/outputs/flutter-apk/app-release.apk`.

## First launch on a fresh clone

If the Android Gradle wrapper jar is missing (e.g. after cloning without LFS), regenerate the platform folder once:

```bash
flutter create . --project-name televault --org com.televault --platforms=android
```

This preserves `lib/` and `pubspec.yaml` while restoring any missing Gradle wrapper binaries.

## Project structure

```
televault/
├── android/                # Full Android project (compileSdk 36, AGP 8.7, Gradle 8.10.2)
├── assets/icon/            # App icon source
├── lib/
│   ├── constants.dart      # Bot token & chat id go here
│   ├── main.dart
│   ├── screens/            # UI screens
│   ├── services/           # Telegram upload, permissions, storage
│   └── widgets/            # Reusable widgets
├── pubspec.yaml
├── analysis_options.yaml
└── README.md
```

## Notes

- Telegram Bot API limits file uploads to **50 MB** for `sendPhoto`, `sendVideo`, and `sendDocument`. Larger files are automatically skipped with an error tag.
- Uploads run sequentially to respect Telegram flood limits.
- Your bot token stays on-device. TeleVault never phones home.
