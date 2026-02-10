# Rafiq - Muslim Companion App

Rafiq ("Companion" in Arabic) is a comprehensive Flutter application designed to serve as a daily companion for Muslims. It integrates essential religious features such as prayer times, Qibla direction, Quran reading, Azkar, and more into a modern, user-friendly interface.

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/firebase-%23039BE5.svg?style=for-the-badge&logo=firebase)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)

## 🌟 Features

- **Prayer Times**: Accurate prayer times calculation based on your location using the `adhan` package.
- **Qibla Direction**: Real-time compass to find the Qibla direction from anywhere.
- **Quran**: Read the Holy Quran with a clean and adjustable interface.
- **Azkar & Tasbeeh**: Digital Tasbeeh counter and collection of daily Azkar.
- **Hadith**: Access to a collection of Hadiths.
- **Islamic Quiz**: Test your knowledge with built-in Islamic quizzes.
- **Authentication**: Secure user authentication via Firebase (Email, Google, Apple).
- **Localization**: Full support for English and Arabic languages.
- **Dark Mode**: Beautifully designed dark and light themes for comfortable reading.
- **Notifications**: Reminders for prayer times using `awesome_notifications`.

## 🛠️ Tech Stack

- **Framework**: [Flutter](https://flutter.dev/)
- **Language**: [Dart](https://dart.dev/)
- **State Management**: [flutter_bloc](https://pub.dev/packages/flutter_bloc)
- **Navigation**: [go_router](https://pub.dev/packages/go_router)
- **Backend (BaaS)**: [Firebase](https://firebase.google.com/) (Auth, Firestore, Analytics)
- **Localization**: [easy_localization](https://pub.dev/packages/easy_localization)
- **Local Storage**: [sqflite](https://pub.dev/packages/sqflite), [shared_preferences](https://pub.dev/packages/shared_preferences)
- **Audio**: [just_audio](https://pub.dev/packages/just_audio)

## 🚀 Getting Started

Follow these steps to get a local copy up and running.

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Dart SDK](https://dart.dev/get-dart)
- An IDE (VS Code, Android Studio, or IntelliJ)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/rafiq.git
   cd rafiq
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   This project uses Firebase. You need to configure it with your own project:
   - Create a project on [Firebase Console](https://console.firebase.google.com/).
   - Install the Firebase CLI.
   - Run `flutterfire configure` to generate `firebase_options.dart`.

4. **Run the app**
   ```bash
   flutter run
   ```

## 📂 Project Structure

```
lib/
├── core/            # Core utilities, theme, router, and dependency injection
├── features/        # Feature-based folder structure
│   ├── auth/        # Authentication (Login, Register)
│   ├── prayer/      # Prayer times and notifications
│   ├── quran/       # Quran reading and logic
│   ├── qibla/       # Qibla compass
│   ├── azkar/       # Azkar and supplications
│   ├── tasbeeh/     # Digital Tasbeeh
│   ├── quiz/        # Islamic Quiz
│   ├── profile/     # User profile and settings
│   └── ...
├── main.dart        # Entry point of the application
└── firebase_options.dart # Firebase configuration
```

## 🤝 Contributing

Contributions are what make the open-source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.
