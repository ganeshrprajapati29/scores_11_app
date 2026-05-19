import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/custom_appbar.dart';
import '../../data/services/player_service.dart';
import '../../data/models/player_model.dart';

// ─── Color Tokens ─────────────────────────────────────────────────────────────
class _C {
  static const primary      = Color(0xFF185FA5);
  static const primaryLight = Color(0xFFE6F1FB);
  static const primaryMid   = Color(0xFF85B7EB);
  static const surface      = Color(0xFFF7F8FA);
  static const white        = Colors.white;
  static const border       = Color(0xFFE4E7EC);
  static const borderMid    = Color(0xFFCDD2DA);
  static const textPrimary  = Color(0xFF111827);
  static const textSecondary= Color(0xFF6B7280);
  static const textTertiary = Color(0xFF9CA3AF);
  static const danger       = Color(0xFFDC2626);
  static const dangerLight  = Color(0xFFFEF2F2);
}

// ─── Main Screen ──────────────────────────────────────────────────────────────

class PlayerProfileScreen extends StatefulWidget {
  final String playerId;
  const PlayerProfileScreen({super.key, required this.playerId});

  @override
  State<PlayerProfileScreen> createState() => _PlayerProfileScreenState();
}

class _PlayerProfileScreenState extends State<PlayerProfileScreen>
    with SingleTickerProviderStateMixin {
  final PlayerService _playerService = PlayerService();

  Player? _player;
  bool _isLoading = true;
  String? _error;

  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.07),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _loadPlayerProfile();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _loadPlayerProfile() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final player = await _playerService.getPlayerById(widget.playerId);
      if (!mounted) return;
      setState(() {
        _player = player;
        _isLoading = false;
      });
      _ctrl.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.surface,
      appBar: CustomAppBar(
        title: 'Player Profile',
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const _LoadingView();
    if (_error != null) {
      return _ErrorView(error: _error!, onRetry: _loadPlayerProfile);
    }
    if (_player == null) return const _EmptyView();

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: _ProfileBody(player: _player!),
      ),
    );
  }
}

// ─── Loading ──────────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: _C.primary,
        strokeWidth: 2,
      ),
    );
  }
}

// ─── Error ────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: _C.dangerLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 34,
                color: _C.danger,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: _C.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: _C.textTertiary),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: 130,
              child: ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _C.primary,
                  foregroundColor: _C.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                child: const Text('Retry',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty ────────────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Player not found',
        style: TextStyle(fontSize: 15, color: _C.textTertiary),
      ),
    );
  }
}

// ─── Profile Body ─────────────────────────────────────────────────────────────

class _ProfileBody extends StatelessWidget {
  final Player player;
  const _ProfileBody({required this.player});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeaderCard(player: player),
          const SizedBox(height: 12),
          _StyleRow(player: player),
          const SizedBox(height: 20),
          _SectionLabel(label: 'Career Stats'),
          const SizedBox(height: 12),
          player.stats != null
              ? _StatsCard(stats: player.stats!)
              : const _EmptyStatsCard(),
          const SizedBox(height: 20),
          _ActionRow(player: player),
        ],
      ),
    );
  }
}

// ─── Header Card ──────────────────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  final Player player;
  const _HeaderCard({required this.player});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _PlayerAvatar(player: player),
          const SizedBox(width: 16),
          Expanded(child: _PlayerInfo(player: player)),
        ],
      ),
    );
  }
}

// ─── Avatar ───────────────────────────────────────────────────────────────────

class _PlayerAvatar extends StatelessWidget {
  final Player player;
  const _PlayerAvatar({required this.player});

  @override
  Widget build(BuildContext context) {
    final url = player.photo ?? player.profileImage;
    final hasImage = url != null && url.isNotEmpty;

    return Container(
      width: 86,
      height: 86,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _C.primaryMid, width: 2),
      ),
      child: ClipOval(
        child: hasImage
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    _AvatarFallback(name: player.name),
              )
            : _AvatarFallback(name: player.name),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  final String name;
  const _AvatarFallback({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _C.primaryLight,
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: _C.primary,
        ),
      ),
    );
  }
}

// ─── Player Info ──────────────────────────────────────────────────────────────

class _PlayerInfo extends StatelessWidget {
  final Player player;
  const _PlayerInfo({required this.player});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          player.name,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _C.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        if (player.role != null) ...[
          const SizedBox(height: 6),
          _RoleBadge(role: player.role!),
        ],
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 6,
          children: [
            if (player.jerseyNumber != null)
              _MetaChip(
                icon: Icons.tag_rounded,
                label: '${player.jerseyNumber}',
              ),
            if (player.teamName != null)
              _MetaChip(
                icon: Icons.group_rounded,
                label: player.teamName!,
              ),
          ],
        ),
      ],
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _C.primaryLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.primaryMid, width: 0.5),
      ),
      child: Text(
        role.toUpperCase(),
        style: const TextStyle(
          color: _C.primary,
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: _C.textTertiary),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: _C.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Style Row ────────────────────────────────────────────────────────────────

class _StyleRow extends StatelessWidget {
  final Player player;
  const _StyleRow({required this.player});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StyleCard(
            icon: Icons.sports_cricket_rounded,
            label: 'Batting',
            value: player.battingStyle ?? 'N/A',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StyleCard(
            icon: Icons.rotate_right_rounded,
            label: 'Bowling',
            value: player.bowlingStyle ?? 'N/A',
          ),
        ),
      ],
    );
  }
}

class _StyleCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StyleCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _C.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: _C.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11,
                        color: _C.textTertiary,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _C.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: _C.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _C.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

// ─── Stats Card ───────────────────────────────────────────────────────────────

class _StatsCard extends StatelessWidget {
  final PlayerStats stats;
  const _StatsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return _Card(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatsSectionHeader(
              title: 'Batting', icon: Icons.sports_cricket_rounded),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: _BattingGrid(stats: stats),
          ),
          const Divider(color: _C.border, height: 1, thickness: 0.5),
          _StatsSectionHeader(
              title: 'Bowling', icon: Icons.rotate_right_rounded),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: _BowlingGrid(stats: stats),
          ),
        ],
      ),
    );
  }
}

class _StatsSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _StatsSectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: Row(
        children: [
          Icon(icon, size: 15, color: _C.primary),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _C.primary,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Batting Grid ─────────────────────────────────────────────────────────────

class _BattingGrid extends StatelessWidget {
  final PlayerStats stats;
  const _BattingGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final items = [
      _SI('Matches', stats.matches.toString()),
      _SI('Runs', stats.runs.toString()),
      _SI('Average', stats.average.toStringAsFixed(1)),
      _SI('Strike Rate', stats.strikeRate.toStringAsFixed(1)),
      _SI('Highest', stats.highestScore.toString()),
      _SI('100s', stats.hundreds.toString()),
      _SI('50s', stats.fifties.toString()),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((i) => _StatTile(item: i)).toList(),
    );
  }
}

// ─── Bowling Grid ─────────────────────────────────────────────────────────────

class _BowlingGrid extends StatelessWidget {
  final PlayerStats stats;
  const _BowlingGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final items = [
      _SI('Wickets', stats.wickets.toString()),
      _SI('Economy', stats.economy.toStringAsFixed(1)),
      _SI('Best', '${stats.bestBowlingWickets}/${stats.bestBowlingRuns}'),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((i) => _StatTile(item: i)).toList(),
    );
  }
}

// ─── Stat item model ──────────────────────────────────────────────────────────

class _SI {
  final String label;
  final String value;
  const _SI(this.label, this.value);
}

// ─── Stat Tile ────────────────────────────────────────────────────────────────

class _StatTile extends StatelessWidget {
  final _SI item;
  const _StatTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final w = (MediaQuery.of(context).size.width - 32 - 28 - 16) / 3;
    return Container(
      width: w.clamp(80.0, 115.0),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _C.border, width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            item.value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: _C.primary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            item.label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              color: _C.textTertiary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty Stats ─────────────────────────────────────────────────────────────

class _EmptyStatsCard extends StatelessWidget {
  const _EmptyStatsCard();

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        children: const [
          Icon(Icons.bar_chart_rounded, size: 38, color: _C.textTertiary),
          SizedBox(height: 8),
          Text(
            'No stats available',
            style: TextStyle(fontSize: 13, color: _C.textTertiary),
          ),
        ],
      ),
    );
  }
}

// ─── Action Row ───────────────────────────────────────────────────────────────

class _ActionRow extends StatelessWidget {
  final Player player;
  const _ActionRow({required this.player});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.person_add_alt_1_rounded, size: 17),
            label: const Text('Follow'),
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.primary,
              foregroundColor: _C.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.share_outlined, size: 17),
            label: const Text('Share'),
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: _C.primary,
              side: const BorderSide(color: _C.primaryMid, width: 1),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Shared Card Widget ───────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _Card({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.border, width: 0.5),
      ),
      child: child,
    );
  }
}