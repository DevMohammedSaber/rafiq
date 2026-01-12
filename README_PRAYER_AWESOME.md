# Prayer Notifications Setup with Awesome Notifications

This document provides setup instructions for prayer notifications with custom sounds.

## Overview

The app uses Awesome Notifications with 3 notification channels:
1. **prayer_reminder** - Reminder before Adhan (uses `reminder` sound)
2. **prayer_adhan** - Adhan notification (uses `adhan` sound)
3. **prayer_iqama** - Iqama notification (uses `iqama` sound)

---

## Android Setup

### 1. Add Sound Files

Place your MP3 sound files in:
```
android/app/src/main/res/raw/
```

Required files:
- `reminder.mp3` - Short reminder sound
- `adhan.mp3` - Adhan sound (keep under 30 seconds for notification)
- `iqama.mp3` - Iqama sound

### 2. Sound Reference in Code

Sounds are referenced as:
```dart
soundSource: 'resource://raw/reminder'
soundSource: 'resource://raw/adhan'
soundSource: 'resource://raw/iqama'
```

---

## iOS Setup

### 1. Add Sound Files to Xcode

1. Open `ios/Runner.xcworkspace` in Xcode
2. Right-click on `Runner` folder in the project navigator
3. Select "Add Files to Runner..."
4. Add your sound files

Supported formats for iOS:
- `.aiff` (recommended)
- `.caf` (recommended)
- `.wav`

### 2. File Naming

Use the same names:
- `reminder.caf` or `reminder.aiff`
- `adhan.caf` or `adhan.aiff`
- `iqama.caf` or `iqama.aiff`

### 3. iOS Notification Sound Limits

**Important**: iOS notification sounds must be less than 30 seconds.

For longer Adhan audio:
- Use a short notification sound
- Play full audio when user taps the notification

---

## Flutter Assets (for in-app playback)

Place files in:
```
assets/sounds/
├── reminder.mp3
├── adhan.mp3
└── iqama.mp3
```

---

## Notification Channels

| Channel Key | Name | Sound | Use |
|------------|------|-------|-----|
| `prayer_reminder` | Prayer Reminder | reminder | Before Adhan notification |
| `prayer_adhan` | Prayer Adhan | adhan | Adhan time notification |
| `prayer_iqama` | Prayer Iqama | iqama | Iqama time notification |

---

## Scheduling Details

### Notification ID Formula
```
id = (yyyyMMdd * 100) + (prayerIndex * 10) + typeIndex
```

Where:
- `prayerIndex`: fajr=1, dhuhr=2, asr=3, maghrib=4, isha=5
- `typeIndex`: beforeAdhan=1, adhan=2, beforeIqama=3, iqama=4

### iOS Scheduling Limits

iOS limits scheduled notifications to ~64. The app dynamically calculates days.

### Android Scheduling

Android can schedule 7 days of notifications by default.
