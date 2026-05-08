# Player List Fix - TODO

## ✅ COMPLETED

### 1. Player List Screen (player_list_screen.dart)
- ✅ Added toggle for "My Players" vs "All Players"
- ✅ Added `_showMyPlayersOnly` boolean flag
- ✅ Added `_toggleMyPlayersFilter()` method
- ✅ Updated `_loadPlayers()` to use `getMyPlayers()` when showing My Players only
- ✅ Added toggle UI with "All Players" and "My Players" options
- ✅ Role filter chips are hidden when showing "My Players" (no search needed)

### 2. Player Service (player_service.dart)
- ✅ Already has `searchMyPlayers()` method - searches only current user's players
- ✅ Already has `getMyPlayers()` method - returns paginated list of user's players
- ✅ Both methods use authenticated endpoint `/players/my/search` and `/players/my`

### 3. Backend Player Routes (player.routes.js)
- ✅ Already has `/players/my/search` endpoint (requires auth)
- ✅ Already has `/players/my` endpoint (requires auth)
- ✅ Both properly filter by logged-in user's ID

### 4. Backend User Registration (user.service.js)
- ✅ When user registers with `role='player'`, auto-creates player profile
- ✅ Player is linked to user via `user` field in Player model (ObjectId reference)
- ✅ This ensures "My Players" correctly returns only that user's players

## 📋 VERIFIED FLOW

### Flow 1: Registration with Player Role
1. User opens Register Screen
2. Selects "Player" from role dropdown
3. Fills name, email, password, phone
4. Submits registration
5. Backend creates User with role='player'
6. Backend ALSO auto-creates Player profile linked to user
7. Player appears in player's "My Players" list

### Flow 2: Manual Player Creation
1. Logged-in user taps "Add Player" in player list screen
2. Fills player details (name, role, batting/bowling style)
3. Creates player via authenticated `/players` endpoint
4. Backend links player to current user
5. Player appears in "My Players" list

### Flow 3: Search Players
1. User searches in player list
2. If "All Players" selected - searches all public players
3. If "My Players" selected - searches only user's own players

## 🔍 TO VERIFY

### Backend - Check player creation includes user ID
The player_service.js needs to pass userId when creating player:
- Via protected API endpoint (uses auth header internally)
- Backend extracts user ID from JWT token
- Player is saved with user reference

### App - Check role selection during registration
- register_screen.dart has role dropdown
- Selected role passed to authProvider.register()
- Auth service sends role to backend
- If role='player', backend auto-creates player profile

## 📝 NOTES

- The toggle UI is placed below search bar in filter section
- Defaults to showing "All Players" (broader search)
- When toggled to "My Players", searches only the logged-in user's players
- This is useful for team selection and managing your own players
- The "All Players" option is useful for finding other players to add to team
