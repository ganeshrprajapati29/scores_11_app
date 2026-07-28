import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/scorecard_provider.dart';
import '../../providers/leaderboard_provider.dart';

/// Logs the current user out and clears every other provider's cached
/// data, so a different account signing in on the same app instance never
/// briefly sees the previous user's dashboard/scorecard/leaderboard state.
Future<void> performLogout(BuildContext context) async {
  await context.read<AuthProvider>().logout();
  if (!context.mounted) return;
  context.read<DashboardProvider>().reset();
  context.read<ScorecardProvider>().reset();
  context.read<LeaderboardProvider>().reset();
}
