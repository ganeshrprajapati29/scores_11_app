# TODO: Multiple Player & Match Team Selection Enhancement

## Task Summary
Add multiple player selection options in team creation, player search during match creation, and validation for minimum 2 teams to start a match.

## Current Implementation Analysis

### Existing Files:
1. **create_team_screen.dart** - Creates teams with optional single player
2. **create_match_screen.dart** - Creates matches with team selection

### Current Features Working:
- Quick Player Add during team creation (single player)
- Team search and selection in match creation
- Validation: Requires both teams selected before showing match details

## Requirements

### 1. Multiple Players in Team Creation
- Allow adding multiple players at team creation time
- Display list of added players with option to remove
- Show player count (e.g., "5 players added")

### 2. Player Search During Match Creation
- Search players from selected teams
- Filter by name, role, or jersey number
- Add searched players to team lineup

### 3. Turnt/Unselected Players Management
- Show unselected players in a separate section
- Allow quick turnt selection for match lineup

### 4. Minimum 2 Teams Validation
- Message: "Minimum 2 teams required to start a match"
- This is already partially implemented - show as banner

## Implementation Plan

### File: create_team_screen.dart
- [ ] Update _playersList to handle multiple players
- [ ] Add player count display
- [ ] Add remove player functionality
- [ ] Add "Add More Players" button

### File: create_match_screen.dart
- [ ] Add player search/filter in team selector
- [ ] Add player count badges
- [ ] Add "Minimum 2 teams" banner
- [ ] Add player lineup preview

## Follow-up Steps
1. Test player multiple addition
2. Test player search in match creation
3. Verify minimum 2 teams validation message
