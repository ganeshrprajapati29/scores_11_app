# 🏏 Cric11 - Play Cricket. Win Glory.

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-blue?style=for-the-badge&logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-3.x-blue?style=for-the-badge&logo=dart" alt="Dart">
  <img src="https://img.shields.io/badge/State-Management-Provider-green?style=for-the-badge" alt="Provider">
  <img src="https://img.shields.io/badge/API-RESTful-orange?style=for-the-badge" alt="REST API">
  <img src="https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge" alt="License">
</p>

<p align="center">
  A comprehensive cricket management mobile application built with Flutter. Manage teams, players, matches, tournaments, and participate in fantasy contests - all in one app!
</p>

---

## 📱 Features

### 🏟️ Core Cricket Features
- **Team Management** - Create and manage your cricket teams with player rosters
- **Player Profiles** - Detailed player statistics, batting/bowling styles
- **Match Management** - Create, schedule, and track cricket matches
- **Tournament Organization** - League and knockout tournaments with automatic points table
- **Ball-by-Ball Scoring** - Real-time match scoring with over analysis
- **Live Score Updates** - Socket.io powered real-time score updates

### 🎮 Fantasy Features
- **Create Fantasy Contests** - Host your own fantasy leagues
- **Multiple Contest Types** - Head-to-Head, League, Knockout, Grand League
- **Team Selection** - Pick your dream team from real players
- **Points System** - Automatic points calculation based on player performance
- **Leaderboards** - Track rankings and compete with others
- **Prize Distribution** - Automated prize distribution

### 💰 Wallet & Transactions
- **Wallet System** - Deposit, withdraw, and transfer funds
- **Transaction History** - Complete audit trail of all transactions
- **Contest Entries** - Pay entry fees and win prizes

### 📰 Content & Community
- **News & Blogs** - Latest cricket news and articles
- **Community Posts** - Connect with other cricket enthusiasts
- **Reviews & Ratings** - Rate players, teams, and matches

### 👤 User Management
- **Authentication** - Secure JWT-based authentication
- **User Profiles** - Personal profile management
- **Notifications** - Push notifications for important updates
- **Settings** - App preferences and configurations

---

## 🛠️ Tech Stack

### Framework & Language
| Technology | Purpose |
|------------|---------|
| Flutter | Cross-platform mobile framework |
| Dart | Programming language |
| Provider | State management |

### Networking & APIs
| Technology | Purpose |
|------------|---------|
| Dio | HTTP client for API calls |
| Socket.io Client | Real-time communication |
| Firebase Core | Firebase integration |
| Firebase Messaging | Push notifications |

### Storage & Utils
| Technology | Purpose |
|------------|---------|
| Flutter Secure Storage | Secure data storage |
| Shared Preferences | Local data persistence |
| Image Picker | Image selection |
| Intl | Internationalization |

### UI/UX
| Technology | Purpose |
|------------|---------|
| Google Fonts | Custom typography |
| Cached Network Image | Image caching |
| Flutter Animate | Animations |
| Shimmer | Loading effects |

---

## 📁 Project Structure

```
cric11_app/
├── lib/
│   ├── core/
│   │   ├── config/           # App configurations
│   │   │   ├── api_config.dart
│   │   │   ├── app_config.dart
│   │   │   ├── firebase_config.dart
│   │   │   ├── socket_config.dart
│   │   │   └── theme_config.dart
│   │   ├── constants/        # App constants
│   │   │   ├── app_colors.dart
│   │   │   ├── app_constants.dart
│   │   │   ├── app_routes.dart
│   │   │   ├── app_strings.dart
│   │   │   └── enums.dart
│   │   ├── services/         # Core services
│   │   │   ├── api_client.dart
│   │   │   ├── connectivity_service.dart
│   │   │   ├── socket_service.dart
│   │   │   └── storage_service.dart
│   │   ├── utils/            # Utility functions
│   │   │   ├── date_formatter.dart
│   │   │   ├── helpers.dart
│   │   │   └── validators.dart
│   │   └── widgets/          # Reusable widgets
│   │       ├── custom_appbar.dart
│   │       ├── custom_button.dart
│   │       ├── custom_loader.dart
│   │       ├── custom_snackbar.dart
│   │       ├── custom_textfield.dart
│   │       ├── empty_state.dart
│   │       └── error_state.dart
│   ├── data/
│   │   ├── models/           # Data models
│   │   │   ├── ball_model.dart
│   │   │   ├── match_model.dart
│   │   │   ├── notification_model.dart
│   │   │   ├── player_model.dart
│   │   │   ├── team_model.dart
│   │   │   ├── tournament_model.dart
│   │   │   └── user_model.dart
│   │   └── services/         # API services
│   │       ├── auth_service.dart
│   │       ├── match_service.dart
│   │       ├── team_service.dart
│   │       └── tournament_service.dart
│   ├── features/             # App features/screens
│   │   ├── auth/
│   │   │   └── login_screen.dart
│   │   ├── dashboard/
│   │   │   └── dashboard_screen.dart
│   │   ├── matches/
│   │   │   └── match_list_screen.dart
│   │   ├── profile/
│   │   │   └── profile_screen.dart
│   │   ├── splash/
│   │   │   └── splash_screen.dart
│   │   ├── teams/
│   │   │   └── team_list_screen.dart
│   │   └── tournaments/
│   │       └── tournament_list_screen.dart
│   ├── providers/            # State providers
│   │   └── auth_provider.dart
│   └── main.dart             # App entry point
├── assets/
│   ├── icons/
│   └── images/
├── android/
├── ios/
├── linux/
├── macos/
├── web/
├── windows/
├── test/
├── pubspec.yaml
└── README.md
```

---

## 🎨 Theme & Design

### Color Palette
```
dart
// Primary Colors
primary: #1E88E5        // Main brand color
primaryDark: #1565C0    // Dark variant
primaryLight: #64B5F6   // Light variant

// Secondary Colors  
secondary: #FF6F00      // Accent color
secondaryDark: #E65100
secondaryLight: #FFB74D

// Status Colors
success: #4CAF50        // Success states
error: #F44336          // Error states
warning: #FFC107        // Warning states
info: #2196F3           // Info states

// Match Status
live: #E53935           // Live match indicator
scheduled: #9E9E9E      // Scheduled match
completed: #4CAF50     // Completed match
cancelled: #FF9800     // Cancelled match
```

### Typography
- **Font Family**: Poppins (via Google Fonts)
- **Headings**: Bold, 18-32px
- **Body**: Regular, 12-16px
- **Captions**: Light, 10-12px

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.x or higher
- Dart SDK 3.x or higher
- Android SDK / Xcode (for iOS)
- Node.js 18+ (for backend)

### Installation

1. **Clone the repository**
```
bash
git clone <repository-url>
cd cric11_app
```

2. **Install dependencies**
```
bash
flutter pub get
```

3. **Configure the app**
```
dart
// Update lib/core/config/api_config.dart
class ApiConfig {
  static const String baseUrl = 'http://your-api-url:5000/api/v1';
  static const String socketUrl = 'http://your-api-url:5000';
}
```

4. **Run the app**
```
bash
# Development
flutter run

# Build for Android
flutter build apk --debug

# Build for iOS
flutter build ios --debug

# Build for Web
flutter build web
```

---

## 📱 App Screens

### 1. Splash Screen
- App logo with animation
- Auto-navigation to login/home

### 2. Authentication
- Login screen with email/password
- Registration form
- Forgot password flow

### 3. Dashboard
- Quick stats overview
- Live matches widget
- Recent activity feed
- Navigation to all features

### 4. Matches
- List of all matches
- Filter by status (Live/Upcoming/Completed)
- Match details with scorecard
- Live scoring interface

### 5. Teams
- Team listing
- Create/edit team
- Player management
- Team statistics

### 6. Tournaments
- Tournament listing
- Points table
- Match schedule
- Tournament details

### 7. Contests
- Available contests
- Create contest
- Join contest
- Leaderboard

### 8. Profile
- User profile
- My teams
- My tournaments
- Wallet balance
- Settings

---

## 🔌 API Integration

### Base Configuration
```
dart
class ApiConfig {
  static const String baseUrl = 'http://localhost:5000/api/v1';
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
```

### Authentication
```
dart
// Login
POST /api/v1/auth/login
{
  "email": "user@example.com",
  "password": "password123"
}

// Register
POST /api/v1/auth/register
{
  "name": "John Doe",
  "email": "user@example.com",
  "password": "password123"
}
```

### Real-time Updates
```
dart
// Connect to socket
final socket = IO.io(ApiConfig.socketUrl, <String, dynamic>{
  'transports': ['websocket'],
  'autoConnect': true,
});

// Listen for live updates
socket.on('ballUpdate', (data) {
  // Update match score
});
```

---

## 🧪 Testing

### Run Tests
```
bash
# All tests
flutter test

# With coverage
flutter test --coverage

# Specific test file
flutter test test/widget_test.dart
```

---

## 📦 Build & Release

### Android
```
bash
# Debug build
flutter build apk --debug

# Release build
flutter build apk --release

# Build for specific architecture
flutter build apk --armeabi-v7a
flutter build apk --arm64-v8a
```

### iOS
```bash
# Debug build
flutter build ios --debug

# Release build
flutter build ios --release

# Build for simulator
flutter build ios --simulator --no-codesign
```

---

## 🤝 Contributing

1. **Fork the repository**
2. **Create your feature branch** (`git checkout -b feature/amazing-feature`)
3. **Commit your changes** (`git commit -m 'Add some amazing feature'`)
4. **Push to the branch** (`git push origin feature/amazing-feature`)
5. **Open a Pull Request**

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- [Flutter](https://flutter.dev) - UI framework
- [Dart](https://dart.dev) - Programming language
- [Provider](https://pub.dev/packages/provider) - State management
- [Dio](https://pub.dev/packages/dio) - HTTP client
- [Socket.io](https://pub.dev/packages/socket_io_client) - Real-time communication
- [Google Fonts](https://fonts.google.com) - Typography

---

## 📞 Support

For support, email support@cric11.com or join our Slack channel.

---

<p align="center">
  Made with ❤️ for Cricket Lovers
  <br>
  © 2026 Ganesh All rights reserved.
</p>
#   s c o r e s _ 1 1 _ a p p  
 