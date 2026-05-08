# Scorecard 404 Fix Plan

## Issue
The scorecard screen shows 404 error when loading match scorecard data:
```
❌ Load scorecard error: DioException [bad response]: This exception was thrown because the response has a status code of 404
```

## Root Cause Analysis
1. The Flutter app calls `/scoring/match/{matchId}/scorecard` endpoint
2. Backend has this route defined at `backend/src/routes/scoring.routes.js`
3. The 404 occurs because either:
   - Match doesn't exist in database
   - The scoring data hasn't been initialized
   - Dio is configured to throw on 404 by default

## Fix Plan

### Step 1: Fix Match Service (match_service.dart)
- Add proper 404 handling with `Options(validateStatus: (status) => status! < 500)`
- Make the fallback more robust when scorecard API fails

### Step 2: Enhance Scorecard Provider (scorecard_provider.dart)
- Handle 404 errors gracefully without throwing
- Use match data as fallback when scorecard API fails

### Step 3: Test the fix
- Load a match with scorecard data
- Verify proper fallback is shown for matches without scorecard

## Files to Edit
1. `cric11_app/lib/data/services/match_service.dart` - Fix getFullScorecard method
2. `cric11_app/lib/providers/scorecard_provider.dart` - Handle 404 gracefully
