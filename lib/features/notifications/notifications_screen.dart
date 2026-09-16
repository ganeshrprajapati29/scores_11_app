import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/friendly_error.dart';
import '../../core/widgets/custom_appbar.dart';
import '../../data/models/notification_model.dart';
import '../../data/services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  static const _bg = Color(0xFFF6F8FB);
  static const _ink = Color(0xFF101828);
  static const _muted = Color(0xFF667085);
  static const _border = Color(0xFFE4E7EC);

  final NotificationService _service = NotificationService();
  final ScrollController _scrollController = ScrollController();
  late final TabController _tabController;

  final List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _isMarkingAll = false;
  String? _error;
  int _page = 1;
  int _total = 0;
  bool _hasMore = false;

  static const _tabs = <_NotificationTab>[
    _NotificationTab('All', 'all', Icons.notifications_rounded),
    _NotificationTab('Unread', 'unread', Icons.mark_email_unread_rounded),
    _NotificationTab('Matches', 'match,score,contest,fantasy', Icons.sports_cricket_rounded),
    _NotificationTab('Social', 'social,post,comment,like,follow,chat', Icons.people_alt_rounded),
    _NotificationTab('System', 'system,wallet,promotion,achievement', Icons.tune_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) _loadNotifications(reset: true);
    });
    _scrollController.addListener(_onScroll);
    _loadNotifications(reset: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _isLoading || _isLoadingMore) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 260) {
      _loadMore();
    }
  }

  Future<void> _loadNotifications({bool reset = false}) async {
    final tab = _tabs[_tabController.index];
    if (reset) {
      setState(() {
        _isLoading = true;
        _error = null;
        _page = 1;
      });
    }

    try {
      final result = await _service.getNotifications(
        page: reset ? 1 : _page,
        limit: 20,
        type: tab.type == 'unread' ? null : tab.type,
        unreadOnly: tab.type == 'unread',
      );
      if (!mounted) return;
      setState(() {
        if (reset) {
          _notifications
            ..clear()
            ..addAll(result.notifications);
        } else {
          _notifications.addAll(result.notifications);
        }
        _total = result.total;
        _hasMore = result.hasMore;
        _page = result.page;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = friendlyError(e, fallback: 'Notifications load nahi ho paaye.');
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _loadMore() async {
    setState(() {
      _isLoadingMore = true;
      _page += 1;
    });
    await _loadNotifications();
  }

  Future<void> _refresh() => _loadNotifications(reset: true);

  Future<void> _markAsRead(NotificationModel notification) async {
    if (notification.isRead || notification.id.isEmpty) return;
    try {
      await _service.markAsRead(notification.id);
      if (!mounted) return;
      setState(() {
        final index = _notifications.indexWhere((item) => item.id == notification.id);
        if (index != -1) {
          _notifications[index] = _notifications[index].copyWith(isRead: true);
        }
      });
    } catch (_) {}
  }

  Future<void> _markAllAsRead() async {
    if (_notifications.every((item) => item.isRead)) return;
    setState(() => _isMarkingAll = true);
    try {
      await _service.markAllAsRead();
      if (!mounted) return;
      setState(() {
        for (var i = 0; i < _notifications.length; i++) {
          _notifications[i] = _notifications[i].copyWith(isRead: true);
        }
      });
    } finally {
      if (mounted) setState(() => _isMarkingAll = false);
    }
  }

  Future<void> _deleteNotification(NotificationModel notification) async {
    final removedIndex = _notifications.indexWhere((item) => item.id == notification.id);
    if (removedIndex == -1) return;
    setState(() => _notifications.removeAt(removedIndex));
    try {
      await _service.deleteNotification(notification.id);
    } catch (e) {
      if (!mounted) return;
      setState(() => _notifications.insert(removedIndex, notification));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyError(e, fallback: 'Notification delete nahi ho payi.'))),
      );
    }
  }

  Future<void> _openNotification(NotificationModel notification) async {
    await _markAsRead(notification);
    if (!mounted) return;
    _openNotificationTarget(notification);
  }

  void _openNotificationTarget(NotificationModel notification) {
    final data = notification.data;
    final type = notification.type.toLowerCase();
    final id = (notification.referenceId ??
            data['matchId'] ??
            data['teamId'] ??
            data['tournamentId'] ??
            data['postId'] ??
            data['chatId'] ??
            data['userId'] ??
            data['senderId'] ??
            '')
        .toString()
        .trim();
    final actionUrl = data['actionUrl']?.toString() ?? '';

    if (id.isNotEmpty && (type.contains('match') || type.contains('score') || type.contains('contest'))) {
      Navigator.pushNamed(context, '/match/$id');
    } else if (id.isNotEmpty && type.contains('team')) {
      Navigator.pushNamed(context, '/team-detail', arguments: id);
    } else if (id.isNotEmpty && type.contains('tournament')) {
      Navigator.pushNamed(context, '/tournament/$id');
    } else if (id.isNotEmpty && (type.contains('post') || type.contains('comment') || type.contains('like') || actionUrl.contains('post'))) {
      Navigator.pushNamed(context, '/post-detail', arguments: id);
    } else if (type.contains('chat') || actionUrl.contains('chat')) {
      Navigator.pushNamed(context, '/chats');
    } else if (id.isNotEmpty && (type.contains('follow') || type.contains('social'))) {
      Navigator.pushNamed(context, '/player-profile/$id');
    }
  }

  @override
  Widget build(BuildContext context) {
    final unread = _notifications.where((item) => !item.isRead).length;
    return Scaffold(
      backgroundColor: _bg,
      appBar: CustomAppBar(
        title: unread == 0 ? 'Notifications' : 'Notifications ($unread)',
        showBackButton: true,
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _isLoading ? null : _refresh,
          ),
          IconButton(
            tooltip: 'Mark all read',
            icon: _isMarkingAll
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.done_all_rounded),
            onPressed: _isMarkingAll ? null : _markAllAsRead,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(54),
          child: Container(
            alignment: Alignment.centerLeft,
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: _border), bottom: BorderSide(color: _border)),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: AppColors.primary,
              unselectedLabelColor: _muted,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
              unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              tabs: _tabs
                  .map((tab) => Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(tab.icon, size: 17),
                            const SizedBox(width: 6),
                            Text(tab.label),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _notifications.isEmpty) {
      return _EmptyPanel(
        icon: Icons.cloud_off_rounded,
        title: 'Notifications load nahi ho paaye',
        message: _error!,
        actionLabel: 'Retry',
        onAction: _refresh,
      );
    }
    if (_notifications.isEmpty) {
      return _EmptyPanel(
        icon: Icons.notifications_none_rounded,
        title: 'No notifications yet',
        message: 'Match, team, chat, social aur system updates yahan dynamic aayenge.',
        actionLabel: 'Refresh',
        onAction: _refresh,
      );
    }

    final rows = _sectionedRows(_notifications);
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        itemCount: rows.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == rows.length) {
            return const Padding(
              padding: EdgeInsets.all(18),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
          final row = rows[index];
          if (row.header != null) return _SectionHeader(title: row.header!);
          final notification = row.notification!;
          return Dismissible(
            key: ValueKey(notification.id),
            direction: DismissDirection.endToStart,
            background: Container(
              margin: const EdgeInsets.only(bottom: 10),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 18),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
            ),
            onDismissed: (_) => _deleteNotification(notification),
            child: _NotificationTile(
              notification: notification,
              onTap: () => _openNotification(notification),
              onMarkRead: () => _markAsRead(notification),
              onOpenTarget: _openTargetByType,
            ),
          );
        },
      ),
    );
  }

  List<_NotificationRow> _sectionedRows(List<NotificationModel> items) {
    final rows = <_NotificationRow>[];
    String? current;
    for (final item in items) {
      final header = _sectionLabel(item.createdAt);
      if (header != current) {
        current = header;
        rows.add(_NotificationRow.header(header));
      }
      rows.add(_NotificationRow.item(item));
    }
    return rows;
  }

  String _sectionLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final itemDay = DateTime(date.year, date.month, date.day);
    final diff = today.difference(itemDay).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return 'This week';
    return 'Earlier';
  }

  void _openTargetByType(String targetType, String id) {
    if (id.trim().isEmpty) return;
    switch (targetType) {
      case 'match':
        Navigator.pushNamed(context, '/match/$id');
        break;
      case 'team':
        Navigator.pushNamed(context, '/team-detail', arguments: id);
        break;
      case 'player':
        Navigator.pushNamed(context, '/player-profile/$id');
        break;
    }
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onMarkRead;
  final void Function(String targetType, String id) onOpenTarget;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onMarkRead,
    required this.onOpenTarget,
  });

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(notification.type);
    final read = notification.isRead;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: read ? Colors.white : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: read ? _NotificationsScreenState._border : color.withOpacity(0.28)),
        boxShadow: read
            ? const []
            : [
                BoxShadow(
                  color: color.withOpacity(0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_typeIcon(notification.type), color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title.isEmpty ? 'Scores11 update' : notification.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _NotificationsScreenState._ink,
                              fontSize: 14,
                              fontWeight: read ? FontWeight.w800 : FontWeight.w900,
                            ),
                          ),
                        ),
                        if (!read)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      notification.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _NotificationsScreenState._muted,
                        fontSize: 12,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    _NotificationEntityChips(
                      notification: notification,
                      onOpenTarget: onOpenTarget,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _TypeChip(type: notification.type, color: color),
                        const Spacer(),
                        Text(
                          _timeAgo(notification.createdAt),
                          style: const TextStyle(
                            color: Color(0xFF98A2B3),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!read)
                IconButton(
                  tooltip: 'Mark read',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.done_rounded, size: 18),
                  onPressed: onMarkRead,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String type;
  final Color color;

  const _TypeChip({required this.type, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _typeLabel(type),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _NotificationEntityChips extends StatelessWidget {
  final NotificationModel notification;
  final void Function(String targetType, String id) onOpenTarget;

  const _NotificationEntityChips({
    required this.notification,
    required this.onOpenTarget,
  });

  @override
  Widget build(BuildContext context) {
    final data = notification.data;
    final chips = <_EntityChipData>[];
    void add(String targetType, dynamic id, String fallback, [dynamic label]) {
      final value = id?.toString().trim() ?? '';
      if (value.isEmpty || chips.any((chip) => chip.targetType == targetType && chip.id == value)) {
        return;
      }
      final text = label?.toString().trim();
      chips.add(_EntityChipData(
        targetType: targetType,
        id: value,
        label: text == null || text.isEmpty ? fallback : text,
        icon: _entityIcon(targetType),
      ));
    }

    final notificationType = notification.type.toLowerCase();
    final matchId = data['matchId'] ??
        ((notificationType.contains('match') || notificationType.contains('score') || notificationType.contains('contest'))
            ? notification.referenceId
            : null);
    add('match', matchId, 'Live match', data['matchName']);
    add('team', data['battingTeamId'] ?? data['teamId'], 'Batting team', data['battingTeamName'] ?? data['teamName']);
    add('team', data['bowlingTeamId'], 'Bowling team', data['bowlingTeamName']);
    add('team', data['winnerTeamId'], 'Winner team', data['winnerTeamName']);
    add('player', data['playerId'] ?? data['batsmanId'], 'Player', data['playerName'] ?? data['batsmanName']);
    add('player', data['bowlerId'], 'Bowler', data['bowlerName']);
    add('player', data['playerOfMatchId'], 'Player of match', data['playerOfMatchName']);

    if (chips.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: chips.take(4).map((chip) {
          return InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => onOpenTarget(chip.targetType, chip.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F4F7),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFE4E7EC)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(chip.icon, size: 12, color: _NotificationsScreenState._muted),
                  const SizedBox(width: 4),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 110),
                    child: Text(
                      chip.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _NotificationsScreenState._ink,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: _NotificationsScreenState._muted,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _EmptyPanel({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(28),
      children: [
        const SizedBox(height: 90),
        Icon(icon, size: 72, color: const Color(0xFF98A2B3)),
        const SizedBox(height: 18),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, color: _NotificationsScreenState._ink, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: _NotificationsScreenState._muted, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 20),
        Center(
          child: FilledButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(actionLabel),
          ),
        ),
      ],
    );
  }
}

class _EntityChipData {
  final String targetType;
  final String id;
  final String label;
  final IconData icon;

  const _EntityChipData({
    required this.targetType,
    required this.id,
    required this.label,
    required this.icon,
  });
}

class _NotificationTab {
  final String label;
  final String type;
  final IconData icon;

  const _NotificationTab(this.label, this.type, this.icon);
}

class _NotificationRow {
  final String? header;
  final NotificationModel? notification;

  const _NotificationRow.header(this.header) : notification = null;
  const _NotificationRow.item(this.notification) : header = null;
}

IconData _entityIcon(String targetType) {
  switch (targetType) {
    case 'team':
      return Icons.groups_rounded;
    case 'player':
      return Icons.person_rounded;
    case 'match':
    default:
      return Icons.sports_cricket_rounded;
  }
}

IconData _typeIcon(String type) {
  final value = type.toLowerCase();
  if (value.contains('match') || value.contains('score') || value.contains('contest') || value.contains('fantasy')) {
    return Icons.sports_cricket_rounded;
  }
  if (value.contains('team')) return Icons.groups_rounded;
  if (value.contains('tournament')) return Icons.emoji_events_rounded;
  if (value.contains('wallet')) return Icons.account_balance_wallet_rounded;
  if (value.contains('chat')) return Icons.chat_bubble_rounded;
  if (value.contains('follow')) return Icons.person_add_alt_1_rounded;
  if (value.contains('like')) return Icons.favorite_rounded;
  if (value.contains('comment')) return Icons.mode_comment_rounded;
  if (value.contains('post') || value.contains('social')) return Icons.forum_rounded;
  if (value.contains('achievement')) return Icons.workspace_premium_rounded;
  return Icons.notifications_rounded;
}

Color _typeColor(String type) {
  final value = type.toLowerCase();
  if (value.contains('match') || value.contains('score')) return const Color(0xFF039855);
  if (value.contains('team')) return AppColors.primary;
  if (value.contains('tournament')) return const Color(0xFFD97706);
  if (value.contains('wallet')) return const Color(0xFF7C3AED);
  if (value.contains('chat')) return const Color(0xFF0891B2);
  if (value.contains('follow') || value.contains('like') || value.contains('comment') || value.contains('post') || value.contains('social')) {
    return const Color(0xFFE11D48);
  }
  if (value.contains('achievement')) return const Color(0xFFB42318);
  return const Color(0xFF475467);
}

String _typeLabel(String type) {
  final value = type.trim().isEmpty ? 'update' : type.trim();
  return value.replaceAll('_', ' ').toUpperCase();
}

String _timeAgo(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${date.day}/${date.month}/${date.year}';
}
