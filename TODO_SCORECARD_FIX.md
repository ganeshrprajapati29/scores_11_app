# Scorecard & Match Details Fix - TODO Steps

## Current Issues Fixed in This Plan:
- Route not found: "/scorecard"
- Invalid match ID error
- Type cast error: List<dynamic> → Map<String,dynamic>  
- setState() called during build
- Tournament service fallback error in scorecard context

## Step-by-Step Implementation Plan ✅ APPROVED

### Phase 1: Infrastructure Fixes (Routing + Navigation)
- [x] **Step 1**: Add '/scorecard' route to lib/main.dart ✅
- [x] **Step 2**: Read and fix lib/providers/dashboard_provider.dart (getFirstLiveMatchId safety) ✅
- [x] **Step 3**: Fix navigation in lib/features/dashboard/dashboard_screen.dart (check null matchId) ✅

### Phase 2: UI/State Management Fixes  
- [x] **Step 4**: Convert lib/features/matches/scorecard_screen.dart to StatefulWidget + initState load ✅
- [ ] **Step 5**: Update other scorecard navigations (live_match_screen.dart if needed)

### Phase 3: Data/API Safety Fixes
- [ ] **Step 6**: Fix type safety in lib/providers/scorecard_provider.dart (handle List/Map)
- [ ] **Step 7**: Fix lib/data/services/match_service.dart getFullScorecard() safe return

### Phase 4: Testing & Validation
- [ ] **Step 8**: Test full flow: Dashboard → Scorecard button → loads without errors
- [ ] **Step 9**: Add ✅ to completed steps, attempt_completion when all done

**Next Step: Phase 1 Step 1 - Edit main.dart**

