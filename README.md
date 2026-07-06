# TeleVault 📦

> *Your gallery, safely vaulted.*

A Flutter (Android) application that backs up your device photos and videos to a private Telegram chat using the Bot API.

---

## ✅ Prerequisites

| Tool | Version |
|------|---------|
| Flutter SDK | ≥ 3.0.0 |
| Dart | ≥ 3.0.0 |
| Android Studio | Hedgehog+ |
| Android SDK | API 21+ (minSdk) |
| JDK | 17 |

---

## 🚀 Setup

### 1. Clone / open the project

```bash
cd televault
flutter pub get
```

### 2. Configure your Telegram Bot

Edit `lib/utils/constants.dart`:

```dart
static const String botToken = 'YOUR_BOT_TOKEN_HERE';
static const String chatId   = 'YOUR_CHAT_ID_HERE';
```

**How to get a bot token:**
1. Open Telegram → search for `@BotFather`
2. Send `/newbot` and follow the steps
3. Copy the token

**How to get your chat ID:**
- Send a message to your bot, then open:  
  `https://api.telegram.org/bot<TOKEN>/getUpdates`  
  The `chat.id` field is your `CHAT_ID`.
- For a private channel, add the bot as an admin and use the channel's ID (starts with `-100…`).

### 3. Run on device / emulator

```bash
flutter run
```

### 4. Build release APK

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

---

## 🏗 Architecture

```
lib/
├── main.dart                    # App entry point, theme, providers
├── models/
│   ├── media_file.dart          # MediaFile entity (photo/video)
│   └── backup_stats.dart        # Gallery statistics model
├── screens/
│   ├── splash_screen.dart       # Animated launch screen
│   ├── permission_screen.dart   # Permission request + explanation
│   ├── home_screen.dart         # Stats, backup controls
│   └── settings_screen.dart     # Preferences & app info
├── services/
│   ├── gallery_service.dart     # MediaStore access via photo_manager
│   ├── telegram_service.dart    # Telegram Bot API — all upload logic
│   └── backup_service.dart      # Orchestrator + ChangeNotifier state
├── widgets/
│   ├── stat_card.dart           # Reusable stat display card
│   └── progress_dialog.dart     # Upload progress bottom sheet
└── utils/
    ├── constants.dart           # BOT_TOKEN, CHAT_ID, SharedPrefs keys
    └── permission_utils.dart    # Runtime permission helpers
```

---

## 📱 Features

| Feature | Detail |
|---------|--------|
| Gallery scan | Uses `photo_manager` (MediaStore under the hood) |
| Stats | Total photos, total videos, last backup time |
| Auto Backup toggle | Persisted to SharedPreferences |
| Backup Now | Uploads all selected media to Telegram |
| Skip already uploaded | Session-based deduplication by asset ID |
| Progress dialog | Live progress bar + file-by-file status |
| Error handling | Per-file errors logged; batch continues |
| Large file skip | Files > 50 MB are skipped (Telegram limit) |
| Notifications | `flutter_local_notifications` (POST_NOTIFICATIONS) |
| Material 3 UI | Dynamic colour + deep-blue seed |

---

## 🔒 Permissions

| Permission | Android API | Why |
|-----------|-------------|-----|
| `READ_MEDIA_IMAGES` | 33+ | Read photos |
| `READ_MEDIA_VIDEO` | 33+ | Read videos |
| `READ_EXTERNAL_STORAGE` | ≤32 | Fallback for older Android |
| `INTERNET` | all | Telegram API calls |
| `POST_NOTIFICATIONS` | 33+ | Backup complete notification |

---

## ⚠️ Important notes

- **BOT_TOKEN and CHAT_ID are hardcoded for demo purposes.** In a production app, store them in a secure backend or use Flutter's `--dart-define` mechanism.
- Files larger than **50 MB** are skipped automatically — this is a Telegram Bot API limitation.
- The app only backs up during the **current session** (no persistent upload log). Re-launching the app resets the session deduplication cache.

---

## 📦 Key dependencies

| Package | Purpose |
|---------|---------|
| `photo_manager` | MediaStore gallery access |
| `http` | Telegram multipart uploads |
| `permission_handler` | Runtime permission requests |
| `flutter_local_notifications` | Local push notifications |
| `provider` | State management |
| `shared_preferences` | Settings persistence |
| `mime` | MIME-type detection for uploads |
| `intl` | Date formatting |
