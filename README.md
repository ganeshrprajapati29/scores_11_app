<!-- ============================================================================== -->
<!-- ============================================================================== -->
<!-- ============================================================================== -->
<!--                    Scores11 - FLUTTER MOBILE APP README                        -->
<!-- ============================================================================== -->
<!-- ============================================================================== -->
<!-- ============================================================================== -->

<p align="center">
  <br>
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart" alt="Dart">
  <img src="https://img.shields.io/badge/State-Management-Provider-green?style=for-the-badge" alt="Provider">
  <img src="https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge" alt="License">
  <br><br>
  <img src="https://img.shields.io/badge/Version-1.0.0+-blue?style=flat-square" alt="Version">
  <img src="https://img.shields.io/badge/Last Updated-March 2026-orange?style=flat-square" alt="Last Updated">
</p>

---

<p align="center">
  <h1>🏏 Scores11</h1>
  <h3>Play Cricket. Win Glory.</h3>
  <p>A comprehensive cricket management mobile application built with Flutter. Manage teams, players, matches, tournaments, and participate in fantasy contests - all in one app!</p>
</p>

---

## 📋 Table of Contents

| Section | Description |
|---------|-------------|
| [🚀 Features](#-features) | Core features of the app |
| [🛠️ Tech Stack](#-tech-stack) | Technologies used |
| [📁 Project Structure](#-project-structure) | File & folder organization |
| [🎨 Theme Design](#-theme-design) | Colors & typography |
| [⚡ Getting Started](#-getting-started) | Installation guide |
| [📱 App Screens](#-app-screens) | Screen descriptions |
| [🔌 API Integration](#-api-integration) | API setup & examples |
| [🧪 Testing](#-testing) | Testing commands |
| [📦 Build & Release](#-build--release) | Build instructions |
| [🤝 Contributing](#-contributing) | Contribution guidelines |
| [📄 License](#-license) | License info |

---

## 🚀 Features

### 🏟️ Core Cricket Features
| Feature | Description |
|---------|-------------|
| **Team Management** | Create and manage cricket teams with player rosters |
| **Player Profiles** | Detailed player statistics, batting/bowling styles |
| **Match Management** | Create, schedule, and track cricket matches |
| **Tournament Organization** | League and knockout tournaments with automatic points table |
| **Ball-by-Ball Scoring** | Real-time match scoring with over analysis |
| **Live Score Updates** | Socket.io powered real-time score updates |

### 🎮 Fantasy Features
| Feature | Description |
|---------|-------------|
| **Create Fantasy Contests** | Host your own fantasy leagues |
| **Multiple Contest Types** | Head-to-Head, League, Knockout, Grand League |
| **Team Selection** | Pick your dream team from real players |
| **Points System** | Automatic points calculation based on player performance |
| **Leaderboards** | Track rankings and compete with others |
| **Prize Distribution** | Automated prize distribution |

### 💰 Wallet & Transactions
| Feature | Description |
|---------|-------------|
| **Wallet System** | Deposit, withdraw, and transfer funds |
| **Transaction History** | Complete audit trail of all transactions |
| **Contest Entries** | Pay entry fees and win prizes |

### 📰 Content & Community
| Feature | Description |
|---------|-------------|
| **News & Blogs** | Latest cricket news and articles |
| **Community Posts** | Connect with other cricket enthusiasts |
| **Reviews & Ratings** | Rate players, teams, and matches |

### 👤 User Management
| Feature | Description |
|---------|-------------|
| **Authentication** | Secure JWT-based authentication |
| **User Profiles** | Personal profile management |
| **Notifications** | Push notifications for important updates |
| **Settings** | App preferences and configurations |

---

## 🛠️ Tech Stack

### Framework & Language
```
┌─────────────────┬──────────────────────────────────┐
│   Technology    │            Purpose               │
├─────────────────┼──────────────────────────────────┤
│    Flutter      │  Cross-platform mobile framework │
│      Dart       │       Programming language       │
│    Provider     │       State management           │
└─────────────────┴──────────────────────────────────┘
```

### Networking & APIs
```
┌─────────────────────┬─────────────────────────────────┐
│     Technology      │            Purpose              │
├─────────────────────┼─────────────────────────────────┤
│        Dio          │   HTTP client for API calls     │
│  Socket.io Client   │    Real-time communication      │
│   Firebase Core     │       Firebase integration      │
│ Firebase Messaging │      Push notifications          │
└─────────────────────┴─────────────────────────────────┘
```

### Storage & Utils
```
┌─────────────────────┬─────────────────────────────────┐
│     Technology      │            Purpose              │
├─────────────────────┼─────────────────────────────────┤
│ Flutter Secure Storage │    Secure data storage       │
│  Shared Preferences  │   Local data persistence       │
│    Image Picker     │      Image selection            │
│        Intl         │    Internationalization         │
└─────────────────────┴─────────────────────────────────┘
```

### UI/UX
```
┌─────────────────────┬─────────────────────────────────┐
│     Technology      │            Purpose              │
├─────────────────────┼─────────────────────────────────┤
│   Google Fonts      │       Custom typography         │
│ Cached Network Image│        Image caching            │
│  Flutter Animate    │          Animations             │
│      Shimmer        │       Loading effects           │
└─────────────────────┴─────────────────────────────────┘
```

---

## 📁 Project Structure

```
Scores11_app/
│
├── lib/
│   ├── core/                          # Core application files
│   │   ├── config/                    # App configurations
│   │   │   ├── api_config.dart        # API endpoints
│   │   │   ├── app_config.dart        # App settings
│   │   │   ├── firebase_config.dart   # Firebase setup
│   │   │   ├── socket_config.dart     # Socket.io setup
│   │   │   └── theme_config.dart     # Theme & colors
│   │   │
│   │   ├── constants/                 # App constants
│   │   │   ├── app_colors.dart        # Color definitions
│   │   │   ├── app_constants.dart     # App constants
│   │   │   ├── app_routes.dart        # Route definitions
│   │   │   ├── app_strings.dart      # String constants
│   │   │   └── enums.dart            # Enum definitions
│   │   │
│   │   ├── services/                  # Core services
│   │   │   ├── api_client.dart        # HTTP client
│   │   │   ├── connectivity_service.dart
│   │   │   ├── socket_service.dart    # Socket service
│   │   │   └── storage_service.dart   # Local storage
│   │   │
│   │   ├── utils/                    # Utility functions
│   │   │   ├── date_formatter.dart
│   │   │   ├── helpers.dart
│   │   │   └── validators.dart
│   │   │
│   │   └── widgets/                  # Reusable widgets
│   │       ├── custom_appbar.dart
│   │       ├── custom_button.dart
│   │       ├── custom_loader.dart
│   │       ├── custom_snackbar.dart
│   │       ├── custom_textfield.dart
│   │       ├── empty_state.dart
│   │       └── error_state.dart
│   │
│   ├── data/                         # Data layer
│   │   ├── models/                   # Data models
│   │   │   ├── ball_model.dart       # Ball scoring model
│   │   │   ├── match_model.dart      # Match model
│   │   │   ├── notification_model.dart
│   │   │   ├── player_model.dart     # Player model
│   │   │   ├── team_model.dart       # Team model
│   │   │   ├── tournament_model.dart # Tournament model
│   │   │   └── user_model.dart       # User model
│   │   │
│   │   └── services/                 # API services
│   │       ├── auth_service.dart     # Authentication
│   │       ├── match_service.dart    # Match API
│   │       ├── team_service.dart     # Team API
│   │       └── tournament_service.dart # Tournament API
│   │
│   ├── features/                     # App features/screens
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
│   │
│   ├── providers/                     # State providers
│   │   └── auth_provider.dart
│   │
│   └── main.dart                     # App entry point
│
├── assets/                           # Static assets
│   ├── icons/
│   └── images/
│
├── android/                          # Android platform files
├── ios/                             # iOS platform files
├── linux/                          # Linux platform files
├── macos/                          # macOS platform files
├── web/                            # Web platform files
├── windows/                        # Windows platform files
│
├── test/                           # Test files
├── pubspec.yaml                    # Flutter dependencies
└── README.md                       # This file
```

---

## 🎨 Theme Design

### Color Palette

```
dart
// ═══════════════════════════════════════════════════════
// PRIMARY COLORS
// ═══════════════════════════════════════════════════════
Color           │ Hex Code  │ Usage
────────────────┼───────────┼─────────────────────────────
primary        │ #1E88E5  │ Main brand color
primaryDark    │ #1565C0  │ Dark variant
primaryLight   │ #64B5F6  │ Light variant

// ═══════════════════════════════════════════════════════
// SECONDARY COLORS
// ═══════════════════════════════════════════════════════
Color           │ Hex Code  │ Usage
────────────────┼───────────┼─────────────────────────────
secondary       │ #FF6F00  │ Accent color
secondaryDark   │ #E65100  │ Dark variant
secondaryLight  │ #FFB74D  │ Light variant

// ═══════════════════════════════════════════════════════
// STATUS COLORS
// ═══════════════════════════════════════════════════════
Color           │ Hex Code  │ Usage
────────────────┼───────────┼─────────────────────────────
success         │ #4CAF50  │ Success states
error           │ #F44336  │ Error states
warning         │ #FFC107  │ Warning states
info            │ #2196F3  │ Info states

// ═══════════════════════════════════════════════════════
// MATCH STATUS COLORS
// ═══════════════════════════════════════════════════════
Color           │ Hex Code  │ Usage
────────────────┼───────────┼─────────────────────────────
live            │ #E53935  │ Live match indicator
scheduled      │ #9E9E9E  │ Scheduled match
completed       │ #4CAF50  │ Completed match
cancelled       │ #FF9800  │ Cancelled match
```

### Typography

```
┌─────────────────────────────────────────────────────────────┐
│  Font Family: Poppins (via Google Fonts)                    │
├─────────────────────────────────────────────────────────────┤
│  Heading 1   │  32px  │  Bold   │  Display text           │
│  Heading 2   │  28px  │  Bold   │  Section titles         │
│  Heading 3   │  24px  │  Bold   │  Page titles            │
│  Heading 4   │  22px  │  SemiBold│  Card titles           │
│  Heading 5   │  20px  │  SemiBold│  Sub-sections          │
│  Heading 6   │  18px  │  SemiBold│  Important headers     │
│  Body Large  │  16px  │  Normal │  Primary content       │
│  Body Medium │  14px  │  Normal │  Secondary content     │
│  Body Small  │  12px  │  Normal │  Captions, hints       │
│  Caption     │  10px  │  Medium │  Small labels          │
└─────────────────────────────────────────────────────────────┘
```

---

## ⚡ Getting Started

### Prerequisites

Before you begin, ensure you have the following installed:

```
✅ Flutter SDK 3.x or higher
✅ Dart SDK 3.x or higher
✅ Android SDK (for Android builds)
✅ Xcode (for iOS builds)
✅ Node.js 18+ (for backend)
✅ MongoDB 6.x (for backend)
✅ Redis 7.x (for backend)
```

### Installation Steps

#### Step 1: Clone the Repository
```
bash
git clone <repository-url>
cd Scores11_app
```

#### Step 2: Install Dependencies
```
bash
flutter pub get
```

#### Step 3: Configure API Settings
```
dart
// File: lib/core/config/api_config.dart

class ApiConfig {
  // UPDATE THESE VALUES WITH YOUR API URL
  static const String baseUrl = 'http://your-api-url:5000/api/v1';
  static const String socketUrl = 'http://your-api-url:5000';
  
  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
```

#### Step 4: Run the App

**Development Mode:**
```
bash
flutter run
```

**Build for Android:**
```
bash
# Debug build
flutter build apk --debug

# Release build
flutter build apk --release
```

**Build for iOS:**
```bash
# Debug build
flutter build ios --debug

# Release build
flutter build ios --release

# Build for simulator
flutter build ios --simulator --no-codesign
```

**Build for Web:**
```
bash
flutter build web
```

---

## 📱 App Screens

### 1. Splash Screen 🌀
```
┌────────────────────────────┐
│                            │
│        🏏 Scores11          │
│    Play Cricket.          │
│      Win Glory.           │
│                            │
│  [Animated Logo]          │
│                            │
└────────────────────────────┘
```
- App logo with animation
- Auto-navigation to login/home

### 2. Authentication 🔐
```
┌────────────────────────────┐
│         LOGIN              │
│                            │
│  Email    [____________]   │
│  Password  [____________]  │
│                            │
│  [    LOGIN BUTTON    ]    │
│                            │
│  Register  |  Forgot Pass  │
└────────────────────────────┘
```
- Login screen with email/password
- Registration form
- Forgot password flow

### 3. Dashboard 📊
```
┌────────────────────────────┐
│  Scores11    [Profile] ⚙️   │
├────────────────────────────┤
│  Welcome, User!            │
│                            │
│  ┌──────┐ ┌──────┐        │
│  │ Live │ │ Up   │        │
│  │Match │ │Coming│        │
│  └──────┘ └──────┘        │
│                            │
│  📰 Recent Activity        │
│  • Match started           │
│  • Team joined             │
│                            │
│  [Matches] [Teams]         │
│  [Tournaments] [Contests] │
└────────────────────────────┘
```
- Quick stats overview
- Live matches widget
- Recent activity feed
- Navigation to all features

### 4. Matches 🏟️
```
┌────────────────────────────┐
│       ALL MATCHES          │
├────────────────────────────┤
│ [All] [Live] [Upcoming]    │
│ [Completed]               │
├────────────────────────────┤
│  LIVE 🔴                  │
│  Team A vs Team B          │
│  145/2 (15.4 ov)          │
│  Team B needs 32 runs      │
│                            │
│  UPCOMING 📅              │
│  India vs Australia        │
│  Tomorrow, 7:00 PM        │
│  Wankhede Stadium         │
│                            │
└────────────────────────────┘
```
- List of all matches
- Filter by status
- Match details with scorecard

### 5. Teams 👥
```
┌────────────────────────────┐
│         MY TEAMS           │
├────────────────────────────┤
│  [+ Create Team]           │
├────────────────────────────┤
│  🏆 Royal Challengers     │
│  Owner: John Doe           │
│  Players: 15               │
│  Matches: 25 | Wins: 18    │
│                            │
│  🌟 Mumbai Indians         │
│  Owner: Jane Smith         │
│  Players: 18               │
│  Matches: 30 | Wins: 22    │
│                            │
└────────────────────────────┘
```
- Team listing
- Create/edit team
- Player management

### 6. Tournaments 🏆
```
┌────────────────────────────┐
│       TOURNAMENTS          │
├────────────────────────────┤
│  [All] [Ongoing] [Past]   │
├────────────────────────────┤
│  IPL 2026 (League)         │
│  Status: Active            │
│  Teams: 10 | Matches: 45   │
│                            │
│  World Cup (Knockout)      │
│  Status: Upcoming          │
│  Teams: 16 | Matches: 15   │
│                            │
│  [Points Table] [Schedule] │
└────────────────────────────┘
```
- Tournament listing
- Points table
- Match schedule

### 7. Contests 🎯
```
┌────────────────────────────┐
│       FANTASY CONTESTS     │
├────────────────────────────┤
│  [All] [My Contests]       │
├────────────────────────────┤
│  MEGA CONTEST 🌟           │
│  Prize: ₹10,00,000         │
│  Entry: ₹49                │
│  Spots: 50000/50000        │
│                            │
│  League Contest             │
│  Prize: ₹1,000             │
│  Entry: ₹10                │
│  Spots: 1000/5000          │
│                            │
│  [Create Contest] [Join]   │
└────────────────────────────┘
```
- Available contests
- Create contest
- Join contest
- Leaderboard

### 8. Profile 👤
```
┌────────────────────────────┐
│        MY PROFILE           │
│      [Edit] [Settings]      │
├────────────────────────────┤
│       [Avatar]             │
│                            │
│  Name: John Doe            │
│  Email: john@email.com      │
│  Phone: +91 98765 43210    │
├────────────────────────────┤
│  My Teams: 3                │
│  Tournaments: 5             │
│  Contests Won: 12           │
├────────────────────────────┤
│  💰 Wallet: ₹5,000          │
│  [Add Money] [Withdraw]    │
├────────────────────────────┤
│  My Teams                   │
│  My Tournaments             │
│  My Contests                │
│  Performance                │
│  Settings                   │
└────────────────────────────┘
```
- User profile
- My teams/tournaments
- Wallet balance
- Settings

---

## 🔌 API Integration

### Base Configuration

```
dart
// lib/core/config/api_config.dart

class ApiConfig {
  static const String baseUrl = 'http://localhost:5000/api/v1';
  static const String socketUrl = 'http://localhost:5000';
  
  // Connection timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
```

### Authentication API

#### Login
```
http
POST /api/v1/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123"
}
```

#### Register
```
http
POST /api/v1/auth/register
Content-Type: application/json

{
  "name": "John Doe",
  "email": "user@example.com",
  "password": "password123"
}
```

### Real-time Socket Integration

```
dart
// Connect to socket
final socket = IO.io(ApiConfig.socketUrl, <String, dynamic>{
  'transports': ['websocket'],
  'autoConnect': true,
});

// Join match room
socket.emit('joinMatch', matchId);

// Listen for live updates
socket.on('ballUpdate', (data) {
  // Update match score
  print('New ball: $data');
});

socket.on('overComplete', (data) {
  // Update over statistics
  print('Over completed: $data');
});

socket.on('matchUpdate', (data) {
  // Update match status
  print('Match updated: $data');
});

// Disconnect when done
socket.disconnect();
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

# Watch mode
flutter test --watch
```

---

## 📦 Build & Release

### Android Builds
```
bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# Split APKs by ABI
flutter build apk --debug --armeabi-v7a
flutter build apk --debug --arm64-v8a
flutter build apk --debug --x86_64
```

### iOS Builds
```
bash
# Debug build
flutter build ios --debug

# Release build
flutter build ios --release

# For simulator
flutter build ios --simulator --no-codesign
```

### Web Build
```
bash
flutter build web --release
```

---

## 🤝 Contributing

We welcome contributions! Please follow these steps:

```
1. Fork the repository
       │
       ▼
2. Create your feature branch
   git checkout -b feature/amazing-feature
       │
       ▼
3. Commit your changes
   git commit -m 'Add some amazing feature'
       │
       ▼
4. Push to the branch
   git push origin feature/amazing-feature
       │
       ▼
5. Open a Pull Request
```

---

## 📄 License

```
MIT License

Copyright (c) 2026 Scores11

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## 🙏 Acknowledgments

| Technology | Website |
|------------|---------|
| Flutter | https://flutter.dev |
| Dart | https://dart.dev |
| Provider | https://pub.dev/packages/provider |
| Dio | https://pub.dev/packages/dio |
| Socket.io | https://pub.dev/packages/socket_io_client |
| Google Fonts | https://fonts.google.com |

---

## 📞 Support

For support, email: **support@Scores11.com**

---

<p align="center">
  <br>
  <img src="https://img.shields.io/badge/Made with-❤️-red?style=for-the-badge" alt="Made with love">
  <br><br>
  <strong>© 2026 Scores11. All rights reserved.</strong>
  <br>
  <sub>Play Cricket. Win Glory. 🏏</sub>
</p>
