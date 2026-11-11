import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/friendly_error.dart';
import '../../core/widgets/custom_appbar.dart';
import '../../data/models/tournament_model.dart';
import '../../data/services/tournament_service.dart';

class PointsTableScreen extends StatefulWidget {
  final String tournamentId;

  const PointsTableScreen({super.key, required this.tournamentId});

  @override
  State<PointsTableScreen> createState() => _PointsTableScreenState();
}

class _PointsTableScreenState extends State<PointsTableScreen> {
  final TournamentService _service = TournamentService();
  List<PointsTable> _points = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPoints();
  }

  Future<void> _loadPoints() async {
    if (widget.tournamentId.isEmpty) {
      setState(() {
        _error = 'Tournament id missing';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final points = await _service.getPointsTable(widget.tournamentId);
      if (!mounted) return;
      setState(() {
        _points = points;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = friendlyError(e, fallback: 'Could not load points table.');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: CustomAppBar(
        title: 'Points Table',
        showBackButton: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _loadPoints),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    if (_error != null) return _ErrorPanel(message: _error!, onRetry: _loadPoints);
    if (_points.isEmpty) return const _EmptyPanel(message: 'Points table will appear after matches start');

    final sorted = [..._points]..sort((a, b) {
        final byPoints = b.points.compareTo(a.points);
        return byPoints != 0 ? byPoints : b.netRunRate.compareTo(a.netRunRate);
      });

    return RefreshIndicator(
      onRefresh: _loadPoints,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _HeaderRow(),
          ...sorted.asMap().entries.map((entry) => _PointRow(rank: entry.key + 1, row: entry.value)),
          const SizedBox(height: 16),
          const _Legend(),
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: const Row(
        children: [
          SizedBox(width: 34, child: Text('#', style: _headStyle)),
          Expanded(child: Text('Team', style: _headStyle)),
          _HeadCell('M'),
          _HeadCell('W'),
          _HeadCell('L'),
          _HeadCell('T'),
          _HeadCell('Pts'),
          _HeadCell('NRR'),
        ],
      ),
    );
  }
}

class _PointRow extends StatelessWidget {
  final int rank;
  final PointsTable row;

  const _PointRow({required this.rank, required this.row});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          SizedBox(width: 34, child: Text('$rank', style: const TextStyle(fontWeight: FontWeight.w800))),
          Expanded(
            child: Text(
              row.team.isEmpty ? 'Team' : row.team,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          _Cell('${row.matchesPlayed}'),
          _Cell('${row.matchesWon}', color: const Color(0xFF16A34A)),
          _Cell('${row.matchesLost}', color: const Color(0xFFEF4444)),
          _Cell('${row.matchesTied}'),
          _Cell('${row.points}', bold: true),
          _Cell("${row.netRunRate > 0 ? '+' : ''}${row.netRunRate.toStringAsFixed(3)}", color: row.netRunRate >= 0 ? const Color(0xFF16A34A) : const Color(0xFFEF4444)),
        ],
      ),
    );
  }
}

class _HeadCell extends StatelessWidget {
  final String label;
  const _HeadCell(this.label);

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: 40, child: Text(label, textAlign: TextAlign.center, style: _headStyle));
  }
}

class _Cell extends StatelessWidget {
  final String value;
  final Color? color;
  final bool bold;

  const _Cell(this.value, {this.color, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      child: Text(
        value,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color ?? const Color(0xFF0F172A),
          fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Points System', style: TextStyle(fontWeight: FontWeight.w800)),
            SizedBox(height: 8),
            Text('Win: 2 points, Tie/No result: 1 point, Loss: 0 points', style: TextStyle(color: Color(0xFF64748B))),
            SizedBox(height: 4),
            Text('NRR is used as a tie-breaker when teams have equal points.', style: TextStyle(color: Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  final String message;
  const _EmptyPanel({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF64748B))));
  }
}

class _ErrorPanel extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorPanel({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF64748B))),
            const SizedBox(height: 14),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

const _headStyle = TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12);
