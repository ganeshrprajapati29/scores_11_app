# Team Match Player Enhancement - TODO

## Task Summary:
1. Quick Player Add feature - allow adding multiple players in model when creating team
2. Player search functionality during team creation
3. Minimum 2 teams validation in match creation

## Current State:
- create_team_screen.dart has syntax error with `>>` 
- Only single player can be added at a time in Quick Player Add
- No player search in team creation flow
- No minimum team validation in match creation

## Plan:

### Phase 1: Fix Syntax Error & Enhance Team Creation
- [ ] Fix syntax error: `final List<Map<String, dynamic>>` → `final List<Map<String, dynamic>>`
- [ ] Add multiple player support in Quick Player Add card
- [ ] Add "Add Another Player" button
- [ ] Show list of players added during team creation

### Phase 2: Player Search in Team Creation
- [ ] Add player search field in team creation screen
- [ ] Search existing players from database
- [ ] Add searched player to team

### Phase 3: Match Creation Validation
- [ ] Add minimum 2 teams check before creating match
- [ ] Show error message if less than 2 teams selected
- [ ] Add team count display in UI

## Files to Edit:
1. cric11_app/lib/features/teams/create_team_screen.dart
2. cric11_app/lib/features/matches/create_match_screen.dart
