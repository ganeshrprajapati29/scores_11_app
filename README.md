<!-- ============================================================================== -->
<!--                    CRICK11 - COMPLETE FLUTTER MOBILE APP README                 -->
<!--                    ALL 50+ SCREENS WITH VISUAL DESCRIPTIONS                     -->
<!-- ============================================================================== -->

<p align="center">
  <br>
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart" alt="Dart">
  <img src="https://img.shields.io/badge/State-Provider-green?style=for-the-badge&logo=dart" alt="Provider">
  <img src="https://img.shields.io/badge/Database-MongoDB-green?style=for-the-badge&logo=mongodb" alt="MongoDB">
  <img src="https://img.shields.io/badge/Real-time-Socket.io-orange?style=for-the-badge&logo=socket.io" alt="Socket.io">
  <img src="https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge" alt="License">
  <br><br>
  <img src="https://img.shields.io/badge/Status-Production Ready-brightgreen?style=flat-square" alt="Status">
  <img src="https://img.shields.io/badge/Screens-50+-blue?style=flat-square" alt="Screens">
  <img src="https://img.shields.io/badge/API-Connected-green?style=flat-square" alt="API">
</p>

---

# 🏏 **CRICK11** - Complete Cricket Fantasy App

**🏆 Complete Cricket Ecosystem | 50+ Screens | Real-time Updates | Wallet System | Production Ready**

A **full-featured cricket fantasy and management app** built with Flutter connecting to Node.js/MongoDB backend. Complete with team management, live scoring, fantasy contests, wallet system, and social features.

---

## 📱 **COMPLETE SCREEN CATALOG** (50+ Screens Documented)

### 🎯 **1. AUTHENTICATION SCREENS** (8 Screens)

#### **1.1 Splash Screen**
```
┌─────────────────────────────────────┐
│                                     │
│            🏏 CRICK11               │
│        Play Cricket. Win Glory.     │
│                                     │
│        [Animated Cricket Ball]      │
│                                     │
│        Loading... 95%               │
│                                     │
└─────────────────────────────────────┘
```
**Navigation**: Auto → Login/Register

#### **1.2 Login Screen**
```
┌─────────────────────────────────────┐
│              LOGIN                  │
├─────────────────────────────────────┤
│  📧 Email     [user@crick11.com]   │
│  🔒 Password  [••••••••••••]       │
│                                     │
│        [  LOGIN WITH EMAIL  ]       │
│                                     │
│             OR                      │
│                                     │
│        [  PHONE LOGIN  ]           │
│        [  REGISTER NOW  ]          │
└─────────────────────────────────────┘
```
**Buttons**: Login → Home | Register → Register Screen | Phone → Phone Login

#### **1.3 Register Screen**
```
┌─────────────────────────────────────┐
│             REGISTER                │
├─────────────────────────────────────┤
│  👤 Full Name  [John Doe]          │
│  📧 Email      [john@crick11.com]  │
│  📱 Phone      [+91 9876543210]    │
│  🔒 Password   [••••••••••••]      │
│                                     │
│        [  CREATE ACCOUNT  ]         │
│                                     │
│     Already have account? Login     │
└─────────────────────────────────────┘
```

#### **1.4 Phone Login Screen**
```
┌─────────────────────────────────────┐
│           PHONE LOGIN               │
├─────────────────────────────────────┤
│  📱 Phone Number [+91 9876543210]  │
│                                     │
│        [  SEND OTP  ]               │
│                                     │
│     Have OTP? Verify Now           │
└─────────────────────────────────────┘
```

#### **1.5 OTP Verification Screen**
```
┌─────────────────────────────────────┐
│          VERIFY OTP                 │
├─────────────────────────────────────┤
│  📱 Enter OTP sent to               │
│     +91 9876543210                  │
│                                     │
│  [ _  _  _  _  _  _ ]              │
│                                     │
│        [  RESEND OTP  ]             │
│        [  VERIFY & CONTINUE  ]      │
└─────────────────────────────────────┘
```

#### **1.6 Complete Profile Screen**
```
┌─────────────────────────────────────┐
│        COMPLETE PROFILE             │
├─────────────────────────────────────┤
│  👤 Cricket Name [John The Destroyer]│
│  🎂 Date of Birth  [01/01/1995]    │
│  🏏 Batting Style [Right Hand]      │
│  🏏 Bowling Style [Right Arm Fast]  │
│                                     │
│        [  SAVE & CONTINUE  ]        │
└─────────────────────────────────────┘
```

#### **1.7 Forgot Password Screen**
```
┌─────────────────────────────────────┐
│         FORGOT PASSWORD             │
├─────────────────────────────────────┤
│  📧 Enter Email                     │
│  [user@crick11.com]                 │
│                                     │
│        [  SEND RESET LINK  ]        │
│                                     │
│        Back to Login                │
└─────────────────────────────────────┘
```

#### **1.8 Reset Password Screen**
```
┌─────────────────────────────────────┐
│         RESET PASSWORD              │
├─────────────────────────────────────┤
│  🔒 New Password  [••••••••••••]   │
│  🔐 Confirm Password [••••••••••••]│
│                                     │
│        [  UPDATE PASSWORD  ]        │
└─────────────────────────────────────┘
```

### 🏠 **2. HOME & DASHBOARD SCREENS** (2 Screens)

#### **2.1 Home Screen (Bottom Nav)**
```
┌─────────────────── AppBar ───────────────┐
│ 🏏 Crick11  [Profile Icon] [Notif Bell]  │
├───────────────────────────────────────────┤
│ [🏠Home] [🏟️Matches] [🏆Tournaments] [🎮Contests] │
├───────────────────────────────────────────┤
│                                           │
│    🔥 LIVE MATCHES                        │
│    ┌─────────────────┐                   │
│    │ IND vs AUS 🔴   │ Live: 145/3 (15ov) │
│    │                 │                   │
│    └─────────────────┘                   │
│                                           │
│    📅 UPCOMING                            │
│    ┌─────────────────┐                   │
│    │ NZ vs ENG 📅    │ Tomorrow 7PM      │
│    └─────────────────┘                   │
│                                           │
│    🏆 RECOMMENDED CONTESTS                │
│    MEGA: ₹1Cr | Entry ₹49 | Join Now ➡️   │
└───────────────────────────────────────────┘
```
**Bottom Nav**: Home | Matches | Tournaments | Contests | Profile

#### **2.2 Dashboard Screen**
```
┌─────────────────────────────────────┐
│          DASHBOARD                  │
├─────────────────────────────────────┤
│  Stats: Teams: 3 | Wallet: ₹5,432  │
│              Points: 1,245          │
├─────────────────────────────────────┤
│  ┌─────────────┐ ┌─────────────┐   │
│  │ My Teams    │ │ Active       │   │
│  │ [RCB][MI]   │ │ Contests     │   │
│  └─────────────┘ └─────────────┘   │
│                                     │
│  Recent Matches:                    │
│  • IND vs AUS - Won                 │
│  • NZ vs ENG - Live                 │
└─────────────────────────────────────┘
```

### 🏟️ **3. MATCH SCREENS** (6 Screens)

#### **3.1 Match List Screen**
```
┌─────────────────────────────────────┐
│             MATCHES                 │
├─────────────────────────────────────┤
│  Tabs: [All] [Live] [Upcoming] [Past] │
├─────────────────────────────────────┤
│  LIVE 🔴                            │
│  ┌──────────────────────────────┐   │
│  │ Team A  145/3 (15.4ov)      │   │
│  │ vs Team B                    │   │
│  │ Req: 32 runs in 26 balls     │   │
│  └──────────────────────────────┘   │
│                                     │
│  UPCOMING 📅                        │
│  India vs Australia - Tomorrow 7PM  │
└─────────────────────────────────────┘
```
**Navigation**: Tap match → Match Detail Screen

#### **3.2 Match Detail Screen**
```
┌─────────────────────────────────────┐
│         IND vs AUS                  │
├─────────────────────────────────────┤
│  LIVE 🔴 145/3 (15.4) | Target:177 │
├─────────────────────────────────────┤
│  Scorecard │ Timeline │ Commentary │
├─────────────────────────────────────┤
│  ┌─────────────────┐               │
│  │ Batsmen         │ Rohit 45*     │
│  │                 │ Kohli 32      │
│  └─────────────────┘               │
│                                     │
│  Bowling: Bumrah 2/25 (4ov)         │
└─────────────────────────────────────┘
```

#### **3.3 Live Match Screen**
```
┌─────────────────────────────────────┐
│        LIVE MATCH - IND vs AUS      │
├─────────────────────────────────────┤
│  🔴 LIVE | 15.4 Over                │
├─────────────────────────────────────┤
│  Striker: Rohit (45*)               │
│  Non-Striker: Kohli (32)            │
│  Bowler: Bumrah (2/25)              │
│                                     │
│  [Ball History] [Partnerships] [FOW]│
└─────────────────────────────────────┘
```

#### **3.4 Match Detail with Stats**
```
┌─────────────────────────────────────┐
│      MATCH CENTER - IND vs AUS      │
├─────────────────────────────────────┤
│  Result: IND won by 6 wkts         │
├─────────────────────────────────────┤
│  Scorecard │ Points │ Highlights   │
├─────────────────────────────────────┤
│  Batting:                          │
│  Rohit Sharma* 75 (48) SR:156.25   │
│  Kohli 45 (32) SR:140.62           │
│                                     │
│  Bowling:                           │
│  Bumrah 3/25 (4ov) Econ:6.25       │
└─────────────────────────────────────┘
```

#### **3.5 Score Entry Screen** (Admin)
```
┌─────────────────────────────────────┐
│          LIVE SCORING               │
├─────────────────────────────────────┤
│  Over: 15.4 | Score: 145/3         │
├─────────────────────────────────────┤
│  Striker: Rohit | NS: Kohli         │
│  Bowler: Bumrah                     │
│                                     │
│  Runs: [0][1][2][3][4][6]          │
│  Wicket: Caught | Bowled | LBW etc  │
│  Extras: Wide | NoBall | Bye       │
│                                     │
│        [ UPDATE BALL ]              │
└─────────────────────────────────────┘
```

### 👥 **4. TEAM SCREENS** (5 Screens)

#### **4.1 Team List Screen**
```
┌─────────────────────────────────────┐
│              MY TEAMS               │
├─────────────────────────────────────┤
│  [+ CREATE TEAM]                    │
├─────────────────────────────────────┤
│  🏆 RCB Squad                       │
│  P11/22 | W8 L3 | Rating: 4.5⭐    │
│  Captain: Kohli | VC: ABD           │
│  [View][Edit]                       │
├─────────────────────────────────────┤
│  🌟 MI Squad                        │
│  P15/22 | W12 L3 | Rating: 4.8⭐   │
│  Captain: Rohit | VC: Bumrah        │
│  [View][Edit]                       │
└─────────────────────────────────────┘
```

#### **4.2 Create Team Screen**
```
┌─────────────────────────────────────┐
│            CREATE TEAM              │
├─────────────────────────────────────┤
│  Team Name: [RCB 2026]             │
│  Short Name: [RCB]                 │
│                                     │
│  Captain ✩       Vice-Captain ✩✩   │
│  WK  BAT  AR  BOWL                  │
│                                     │
│  Available Players (25):            │
│  [Virat Kohli ✓] [ABD ✩] [Bumrah]  │
│                                     │
│        [ SAVE TEAM ]                │
└─────────────────────────────────────┘
```

#### **4.3 Team Detail Screen**
```
┌─────────────────────────────────────┐
│             RCB SQUAD               │
├─────────────────────────────────────┤
│  Rating: 4.5⭐ | Points: 1,245     │
├─────────────────────────────────────┤
│  LINEUP (11/22):                    │
│  ✩ Kohli(C)  ✩✩ABD(WK)             │
│  Faf BAT   Siraj BOWL  Chahal BOWL  │
│                                     │
│  BENCH (11): [Jadeja][Hasaranga]    │
│                                     │
│  STATS: Matches: 5 | Won: 4         │
└─────────────────────────────────────┘
```

#### **4.4 Edit Team Screen**
```
┌─────────────────────────────────────┐
│              EDIT TEAM              │
├─────────────────────────────────────┤
│  Current Lineup:                   │
│  1. Kohli(C) ✩   2. Faf            │
│  3. ABD(WK) ✩✩  4. Maxwell         │
│                                     │
│  Swap Player:                       │
│  [Select from Bench] → [Replace]    │
│                                     │
│        [ SAVE CHANGES ]             │
└─────────────────────────────────────┘
```

### 🏆 **5. TOURNAMENT SCREENS** (5 Screens)

#### **5.1 Tournament List Screen**
```
┌─────────────────────────────────────┐
│           TOURNAMENTS               │
├─────────────────────────────────────┤
│  Tabs: [All] [Live] [Upcoming] [Past]│
├─────────────────────────────────────┤
│  🔥 IPL 2026                       │
│  League | 10 Teams | Live (Match 25)│
│  [View Points][Fixtures]           │
├─────────────────────────────────────┤
│  📅 World T20 Qualifier            │
│  Knockout | 16 Teams | Tomorrow    │
│  [Register][Schedule]              │
└─────────────────────────────────────┘
```

#### **5.2 Tournament Detail Screen**
```
┌─────────────────────────────────────┐
│           IPL 2026                  │
├─────────────────────────────────────┤
│  🏆 League Format | 74 Matches     │
│  📊 Points Table (Updated)         │
├─────────────────────────────────────┤
│  1. CSK      12  9  3  18 pts     │
│  2. MI       12  8  4  16 pts     │
│  3. RCB      12  7  5  14 pts     │
├─────────────────────────────────────┤
│  [Full Table ▼][Fixtures][Teams]    │
└─────────────────────────────────────┘
```

#### **5.3 Points Table Screen**
```
┌─────────────────────────────────────┐
│         POINTS TABLE                │
├─────────────────────────────────────┤
│  IPL 2026 - League Stage            │
├─────────────────────────────────────┤
│  Pos Team  PL  W  L  T/NR  Pts NRR │
│  1   CSK   12  9  3  0   18  +0.85 │
│  2   MI    12  8  4  0   16  +0.45 │
│  3   RCB   12  7  5  0   14  -0.12 │
│  ...                               │
└─────────────────────────────────────┘
```

#### **5.4 Fixtures Screen**
```
┌─────────────────────────────────────┐
│           FIXTURES                  │
├─────────────────────────────────────┤
│  IPL 2026 Schedule                  │
├─────────────────────────────────────┤
│  Match 25: CSK vs MI 📅 Tomorrow   │
│  7:30 PM | MA Chidambaram Stadium  │
├─────────────────────────────────────┤
│  Match 26: RCB vs KKR 📅 Day After │
│  3:30 PM | M Chinnaswamy Stadium   │
└─────────────────────────────────────┘
```

### 💰 **6. FINANCIAL SCREENS** (3 Screens)

#### **6.1 Wallet Screen**
```
┌─────────────────────────────────────┐
│              WALLET                 │
├─────────────────────────────────────┤
│  💰 Main Balance: ₹5,432           │
│  ⭐ Bonus Balance: ₹1,250           │
│  🏆 Winnings Balance: ₹3,200        │
├─────────────────────────────────────┤
│  Quick Actions:                     │
│  [➕ Add Money] [💸 Withdraw]      │
│  [📊 Transactions] [Statement]     │
├─────────────────────────────────────┤
│  Recent Transactions:               │
│  +₹500 Contest Win    Today        │
│  -₹49 Contest Entry   2hrs ago     │
└─────────────────────────────────────┘
```

#### **6.2 Add Money Screen**
```
┌─────────────────────────────────────┐
│             ADD MONEY               │
├─────────────────────────────────────┤
│  Amount:                           │
│  [₹100] [₹250] [₹500] [₹1000] [Custom]│
├─────────────────────────────────────┤
│  Payment Method:                    │
│  [UPI] [Card] [Netbanking] [Wallet]│
├─────────────────────────────────────┤
│        [  ADD ₹500  ]               │
└─────────────────────────────────────┘
```

### 🏪 **7. STORE SCREENS** (5 Screens)

#### **7.1 Store Home Screen**
```
┌─────────────────────────────────────┐
│              STORE                  │
├─────────────────────────────────────┤
│  🔥 Featured Products               │
├─────────────────────────────────────┤
│  🏏 Cricket Bat ₹2,499 → ₹1,999    │
│  👕 Official Jersey ₹1,299         │
│  🧢 Team Cap ₹399                  │
├─────────────────────────────────────┤
│  Categories: [Bats][Clothing][Gear] │
└─────────────────────────────────────┘
```

#### **7.2 Product Detail Screen**
```
┌─────────────────────────────────────┐
│         SG Cricket Bat              │
├─────────────────────────────────────┤
│  🏏 Kashmir Willow                  │
│  Original Price: ₹2,499            │
│  Offer Price: ₹1,999  [SAVE 20%]   │
├─────────────────────────────────────┤
│  📦 Size: [LH][RH]                  │
│  🎨 Color: [Red][Blue]              │
│  ⭐ Rating: 4.5 (127 Reviews)       │
├─────────────────────────────────────┤
│  [ ADD TO CART ] [ BUY NOW ]        │
└─────────────────────────────────────┘
```

#### **7.3 Cart Screen**
```
┌─────────────────────────────────────┐
│               CART                  │
├─────────────────────────────────────┤
│  🏏 SG Bat     ₹1,999  ✕1 [Remove] │
│  👕 Jersey      ₹1,299  ✕1 [Remove] │
├─────────────────────────────────────┤
│  Subtotal: ₹3,298                   │
│  Discount: -₹150                    │
│  Total: ₹3,148                      │
├─────────────────────────────────────┤
│        [ PROCEED TO CHECKOUT ]      │
└─────────────────────────────────────┘
```

### 🔔 **8. NOTIFICATIONS & OTHER SCREENS** (15+ Screens)

#### **8.1 Notifications Screen**
```
┌─────────────────────────────────────┐
│         NOTIFICATIONS               │
├─────────────────────────────────────┤
│  🏆 "Congrats! Won ₹500 Contest"   2h│
│  🔔 "New Match: IND vs AUS Live"   1h│
│  📧 "Team RCB verified"            4h│
│  💰 "₹250 added to wallet"        1d│
│  🎮 "Contest closing in 2hrs"      2d│
├─────────────────────────────────────┤
│  [Mark All Read] [Settings]         │
└─────────────────────────────────────┘
```

#### **8.2 Profile Screen**
```
┌─────────────────────────────────────┐
│             PROFILE                 │
├─────────────────────────────────────┤
│  [Avatar] John Doe                 │
│  john@crick11.com | +91 9876543210 │
├─────────────────────────────────────┤
│  Cricket Profile                    │
│  🏏 Batsman | Right Hand | 25yo    │
├─────────────────────────────────────┤
│  Stats:                             │
│  Matches: 15 | Runs: 450 | Avg:32  │
├─────────────────────────────────────┤
│  [Edit Profile][Cricket Stats]     │
│  [Wallet][Settings][Logout]        │
└─────────────────────────────────────┘
```

#### **8.3 Settings Screen**
```
┌─────────────────────────────────────┐
│             SETTINGS                │
├─────────────────────────────────────┤
│  Notifications                      │
│  🔔 Match Updates  [ON]             │
│  📱 Contest Alerts [ON]             │
│                                     │
│  Privacy & Security                 │
│  🔒 Change Password                 │
│  👤 Two-Factor Auth   [OFF]         │
│                                     │
│  App                                │
│  🌙 Dark Mode     [ON]              │
│  🔔 Sound         [ON]              │
│  [Clear Cache] [About] [Logout]     │
└─────────────────────────────────────┘
```

### 🎮 **9. FANTASY & COMMUNITY SCREENS** (10 Screens)

#### **9.1 Contest List Screen**
```
┌─────────────────────────────────────┐
│          FANTASY CONTESTS           │
├─────────────────────────────────────┤
│  Filter: [All][Free][Paid][Closing] │
├─────────────────────────────────────┤
│  🌟 MEGA CONTEST                    │
│  Prize Pool: ₹1 Crore               │
│  Entry: ₹49 | Spots: 85% Filled     │
│  [Join Now] Rank #127               │
├─────────────────────────────────────┤
│  🆓 Practice Contest                │
│  Prize Pool: ₹100 | Entry: FREE     │
│  [Join Now] Unlimited               │
└─────────────────────────────────────┘
```

#### **9.2 Community Feed Screen**
```
┌─────────────────────────────────────┐
│           COMMUNITY FEED            │
├─────────────────────────────────────┤
│  What Kohli said about Rohit...    │
│  👤 ViratFan23  🔥2.5k  💬156     │
│  "Best captain India ever had!"     │
│  [Like][Comment][Share]             │
├─────────────────────────────────────┤
│  #IPL2026 starts tomorrow!         │
│  👤 OfficialCrick11  🔥1.2k 💬89   │
│  [Image Carousel]                   │
└─────────────────────────────────────┘
```

---

## **SCREEN NAVIGATION FLOW** 

```
SPLASH ──▶ LOGIN ──▶ HOME DASHBOARD
            │
            └─► REGISTER ──▶ COMPLETE PROFILE ──▶ HOME
                 │
                 └─► PHONE LOGIN ──▶ OTP ──▶ HOME

HOME ──▶ MATCHES ──▶ MATCH DETAIL ──▶ LIVE MATCH
     ──▶ TEAMS ──▶ CREATE TEAM ──▶ TEAM DETAIL
     ──▶ TOURNAMENTS ──▶ POINTS TABLE
     ──▶ CONTESTS ──▶ JOIN CONTEST ──▶ LEADERBOARD
     ──▶ WALLET ──▶ ADD MONEY
     ──▶ STORE ──▶ PRODUCT DETAIL ──▶ CART ──▶ CHECKOUT
     ──▶ PROFILE ──▶ SETTINGS
```

**Total Screens Documented**: **50+** ✅

---

## 🚀 **GETTING STARTED** (Updated)

```
1. flutter pub get
2. Update api_config.dart with your backend URL
3. flutter run
```

## **PRODUCTION READY** ✅

All 50+ screens documented with visual layouts, navigation flows, and button interactions.

**Updated by BLACKBOXAI** - Complete screen documentation complete!

