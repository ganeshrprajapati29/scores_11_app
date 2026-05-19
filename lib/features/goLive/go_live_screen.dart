import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../data/services/live_stream_service.dart';
import '../goLive/stream_preview_screen.dart';
import '../live_stream/live_player_screen.dart';
import '../../data/models/live_stream_model.dart';
import '../../core/utils/safe_list.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const _white        = Color(0xFFFFFFFF);
const _pageBg       = Color(0xFFF4F5F8);
const _surfaceGrey  = Color(0xFFF4F5F8);
const _border       = Color(0xFFE4E8F0);
const _textPrimary  = Color(0xFF0D1B2A);
const _textSecondary= Color(0xFF4B5563);
const _textMuted    = Color(0xFF9CA3AF);
const _primary      = Color(0xFF1B8A4E);
const _primaryBg    = Color(0xFFE6F5ED);
const _primaryBorder= Color(0xFF9DCDB5);
const _red          = Color(0xFFE53935);
const _redBg        = Color(0xFFFFF0F0);
const _redBorder    = Color(0xFFFFCDD2);
const _amber        = Color(0xFFF59E0B);
const _amberBg      = Color(0xFFFFFBEB);
const _blue         = Color(0xFF2563EB);
const _blueBg       = Color(0xFFEFF4FF);
const _shadow       = Color(0x08000000);
const _cardShadow   = Color(0x0A000000);

class GoLiveScreen extends StatefulWidget {
  const GoLiveScreen({super.key});

  @override
  State<GoLiveScreen> createState() => _GoLiveScreenState();
}

class _GoLiveScreenState extends State<GoLiveScreen>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;

  List<LiveStreamModel> _liveStreams    = [];
  List<LiveStreamModel> _featuredStreams = [];
  bool   _isLoading  = true;
  String? _error;

  String _selectedLanguage = 'English';
  bool   _acceptTerms      = false;
  bool   _isCreating       = false;

  final _titleCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();
  final _reqCtrl   = TextEditingController();
  final _youtubeUrlCtrl = TextEditingController();

  String _streamType   = 'mobile';
  String _quality      = '720p';
  String _pricing      = 'free';
  double _priceAmount  = 99;
  bool   _isPrivate    = false;
  List<String> _lookingFor = [];

  static const _languages = ['English', 'Hindi'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initService();
    _loadStreams();
  }

  Future<void> _initService() async {
    await LiveStreamService.initSocket();
  }

  @override
  void dispose() {
    LiveStreamService.dispose();
    _tabController.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _reqCtrl.dispose();
    _youtubeUrlCtrl.dispose();
    super.dispose();
  }

  String _t(String en, String hi) =>
      _selectedLanguage == 'Hindi' ? hi : en;

  Future<bool> _checkAuth() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.status != AuthStatus.authenticated) {
      _showAuthDialog();
      return false;
    }
    return true;
  }

  void _showAuthDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Login Required',
            style: TextStyle(
                fontWeight: FontWeight.w700, color: _textPrimary)),
        content: const Text(
            'Please login to access live streams.',
            style: TextStyle(color: _textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: _textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Go to Login',
                style: TextStyle(color: _white)),
          ),
        ],
      ),
    );
  }

  Future<void> _loadStreams() async {
    setState(() {
      _isLoading = true;
      _error     = null;
    });
    try {
      final live     = await LiveStreamService.getLiveStreams(status: 'live');
      final featured = live.take(3).toList();
      setState(() {
        _liveStreams = live.where((s) => s.id.isNotEmpty && s.title.isNotEmpty).toList();
        _featuredStreams = _liveStreams.take(3).toList();
        _isLoading = false;
      });
    } catch (e) {
      final s = e.toString();
      if (s.contains('401') || s.contains('unauthorized')) {
        final auth = Provider.of<AuthProvider>(context, listen: false);
        await auth.logout();
        _showAuthDialog();
      } else {
        setState(() {
          _error     = s;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createStream() async {
    if (!await _checkAuth()) return;
    if (!_acceptTerms) {
      _snack(_t('Please accept Terms & Conditions',
          'कृपया नियम स्वीकार करें'), isError: true);
      return;
    }
    if (_titleCtrl.text.trim().isEmpty) {
      _snack(_t('Please enter title', 'शीर्षक दर्ज करें'), isError: true);
      return;
    }

    if (_streamType == 'youtube' && _youtubeUrlCtrl.text.trim().isEmpty) {
      _snack('Please enter YouTube Live URL or video ID', isError: true);
      return;
    }

    setState(() => _isCreating = true);
    try {
      final data = {
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        'streamType': _streamType,
        'provider': _streamType == 'youtube' ? 'youtube' : 'zenstream',
        if (_streamType == 'youtube') 'youtubeUrl': _youtubeUrlCtrl.text.trim(),
        'streamQuality': _quality,
        'isPrivate': _isPrivate,
        'pricing': {
          'type': _pricing,
          'amount': _pricing == 'free' ? 0 : _priceAmount,
          'currency': 'INR',
        },
        'lookingFor': _lookingFor,
        'requirements': _reqCtrl.text.trim().isEmpty
            ? null
            : _reqCtrl.text.trim(),
      };

      final created = await LiveStreamService.createStream(data);
      debugPrint('🎥 Created stream ${created.id}, starting...');
      await LiveStreamService.startStream(created.id);
      _snack(
        created.isYoutube
            ? 'YouTube Live added. Viewers can watch now.'
            : 'RTMP Ready! Server: ${LiveStreamService.zenstreamRtmpServer} | Key: ${created.streamKey.isNotEmpty ? created.streamKey : created.id}',
        isError: false,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => created.isYoutube
                ? LivePlayerScreen(streamId: created.id, isHost: true)
                : StreamPreviewScreen(stream: created),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ _createStream error: $e');
      String msg = _t(
          'Failed to start stream. Please try again.',
          'स्ट्रीम शुरू करने में विफल। पुनः प्रयास करें।');
      if (e.toString().contains('401')) {
        final auth = Provider.of<AuthProvider>(context, listen: false);
        await auth.logout();
        msg = _t('Session expired. Please login again.',
            'सत्र समाप्त। कृपया पुनः लॉगिन करें।');
        _showAuthDialog();
      }
      if (mounted) _snack(msg, isError: true);
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: const TextStyle(
                color: _white, fontWeight: FontWeight.w500)),
        backgroundColor: isError ? _red : _primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showLangDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text(_t('Select Language', 'भाषा चुनें'),
            style: const TextStyle(
                fontWeight: FontWeight.w700, color: _textPrimary)),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _languages.map((lang) {
            final sel = _selectedLanguage == lang;
            return ListTile(
              leading: Text(lang == 'Hindi' ? '🇮🇳' : '🇺🇸',
                  style: const TextStyle(fontSize: 22)),
              title: Text(lang,
                  style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: sel ? _primary : _textPrimary)),
              trailing: sel
                  ? const Icon(Icons.check_circle, color: _primary)
                  : null,
              onTap: () {
                setState(() => _selectedLanguage = lang);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── BUILD ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.status == AuthStatus.loading) {
          return const Scaffold(
            backgroundColor: _pageBg,
            body: Center(
                child: CircularProgressIndicator(color: _primary)),
          );
        }
        return Scaffold(
          backgroundColor: _pageBg,
          body: Column(
            children: [
              _buildTopBar(auth),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildLiveNowTab(),
                    _buildGoLiveTab(),
                    _buildWatchTab(),
                    _buildHelpTab(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── TOP BAR ──────────────────────────────────────────────────────────────────
  Widget _buildTopBar(AuthProvider auth) {
    final mq = MediaQuery.of(context);
    return Container(
      color: _white,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Back
              _iconBtn(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(width: 12),

              // Title
              Expanded(
                child: Text(
                  _t('Go Live', 'लाइव जाएं'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  ),
                ),
              ),

              // Auth badge / login btn
              if (auth.status == AuthStatus.authenticated)
                _statusBadge(
                    icon: Icons.check_circle_rounded,
                    label: 'Live Ready',
                    color: _primary,
                    bg: _primaryBg)
              else
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _primary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Login',
                      style: TextStyle(color: _primary, fontSize: 13)),
                ),

              const SizedBox(width: 8),

              // Language picker
              GestureDetector(
                onTap: _showLangDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: _surfaceGrey,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _border, width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                          _selectedLanguage == 'Hindi' ? '🇮🇳' : '🇺🇸',
                          style: const TextStyle(fontSize: 15)),
                      const SizedBox(width: 5),
                      Text(_selectedLanguage,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _textPrimary)),
                      const Icon(Icons.keyboard_arrow_down_rounded,
                          size: 16, color: _textMuted),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconBtn(
      {required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _surfaceGrey,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _border, width: 0.8),
        ),
        child: Icon(icon, size: 16, color: _textPrimary),
      ),
    );
  }

  Widget _statusBadge({
    required IconData icon,
    required String label,
    required Color color,
    required Color bg,
  }) =>
      Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3), width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );

  // ── TAB BAR ──────────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      color: _white,
      child: Column(
        children: [
          Divider(height: 1, color: _border),
          TabBar(
            controller: _tabController,
            labelColor: _primary,
            unselectedLabelColor: _textMuted,
            labelStyle: const TextStyle(
                fontSize: 12.5, fontWeight: FontWeight.w600),
            unselectedLabelStyle:
                const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
            indicatorColor: _primary,
            indicatorWeight: 2.5,
            indicatorSize: TabBarIndicatorSize.label,
            splashFactory: NoSplash.splashFactory,
            tabs: [
              Tab(text: _t('🔴 Live Now', '🔴 अभी लाइव')),
              Tab(text: _t('📺 Go Live', '📺 लाइव करें')),
              Tab(text: _t('📋 Watch', '📋 देखें')),
              Tab(text: _t('❓ Help', '❓ सहायता')),
            ],
          ),
        ],
      ),
    );
  }

  // ── LIVE NOW TAB ─────────────────────────────────────────────────────────────
  Widget _buildLiveNowTab() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: _primary));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: _redBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: _redBorder),
                ),
                child: const Icon(Icons.wifi_off_rounded,
                    color: _red, size: 32),
              ),
              const SizedBox(height: 16),
              const Text('Something went wrong',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary)),
              const SizedBox(height: 6),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 13, color: _textMuted, height: 1.5)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadStreams,
                icon: const Icon(Icons.refresh_rounded,
                    size: 16, color: _white),
                label: const Text('Retry',
                    style: TextStyle(color: _white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (_liveStreams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: _primaryBg,
                  shape: BoxShape.circle),
              child: const Icon(Icons.live_tv_rounded,
                  size: 36, color: _primary),
            ),
            const SizedBox(height: 16),
            const Text('No live streams right now',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary)),
            const SizedBox(height: 6),
            const Text('Check back later or start your own!',
                style: TextStyle(fontSize: 13, color: _textMuted)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _tabController.animateTo(1),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
              ),
              child: const Text('Start Streaming',
                  style: TextStyle(color: _white)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: _primary,
      onRefresh: _loadStreams,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _featuredStreams.length + _liveStreams.length,
        itemBuilder: (context, index) {
          LiveStreamModel? safeStream;
          if (index < _featuredStreams.length) {
            safeStream = _featuredStreams.elementAtOrNull(index);
          } else {
            final listIndex = index - _featuredStreams.length;
            safeStream = _liveStreams.elementAtOrNull(listIndex);
          }
          if (safeStream == null || safeStream.id.isEmpty) {
            return const SizedBox.shrink();
          }
          return _buildStreamCard(safeStream, isFeatured: index < _featuredStreams.length);
        },
      ),
    );
  }

  Widget _buildStreamCard(LiveStreamModel stream,
      {bool isFeatured = false}) {
    if (stream.id.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFeatured
              ? _primaryBorder.withOpacity(0.5)
              : _border,
          width: isFeatured ? 1.2 : 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: isFeatured ? _primary.withOpacity(0.07) : _cardShadow,
            blurRadius: isFeatured ? 16 : 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LivePlayerScreen(
                  streamId: stream.id, isHost: false),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 78,
                    height: 58,
                    color: _surfaceGrey,
                    child: stream.thumbnail != null
                        ? Image.network(stream.thumbnail!,
                            fit: BoxFit.cover)
                        : const Icon(Icons.play_circle_rounded,
                            color: _textMuted, size: 28),
                  ),
                ),
                const SizedBox(width: 12),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _liveBadge(stream),
                          const SizedBox(width: 6),
                          if (stream.isPrivate) ...[
                            const Icon(Icons.lock_rounded,
                                color: _amber, size: 13),
                            const SizedBox(width: 2),
                          ],
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        stream.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                          color: _textPrimary,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${stream.viewerCount} viewers · ${stream.streamTypeDisplay}',
                        style: const TextStyle(
                            color: _textMuted, fontSize: 12.5),
                      ),
                      if (!stream.isFree) ...[
                        const SizedBox(height: 4),
                        Text(
                          stream.pricing?.displayPrice ?? 'Paid',
                          style: const TextStyle(
                              color: _amber,
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5),
                        ),
                      ],
                    ],
                  ),
                ),

                // Like
                Column(
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.favorite_border_rounded,
                          color: _red, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(height: 2),
                    Text('${stream.likes}',
                        style: const TextStyle(
                            fontSize: 11.5, color: _textMuted)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _liveBadge(LiveStreamModel stream) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: stream.isLive ? _redBg : _surfaceGrey,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: stream.isLive ? _redBorder : _border,
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (stream.isLive) ...[
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                    color: _red, shape: BoxShape.circle),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              stream.statusDisplay,
              style: TextStyle(
                color: stream.isLive ? _red : _textMuted,
                fontWeight: FontWeight.w700,
                fontSize: 10.5,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );

  // ── GO LIVE TAB ──────────────────────────────────────────────────────────────
  Widget _buildGoLiveTab() {
    final mq   = MediaQuery.of(context);
    final hPad = mq.size.width > 600 ? mq.size.width * 0.08 : 16.0;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stream details card
          _sectionLabel('Stream Details'),
          _card(
            child: Column(
              children: [
                _field(
                  controller: _titleCtrl,
                  label: 'Stream Title *',
                  hint: 'e.g. IPL Live Commentary',
                  icon: Icons.title_rounded,
                ),
                const SizedBox(height: 12),
                _field(
                  controller: _descCtrl,
                  label: 'Description',
                  hint: 'What will you stream about?',
                  icon: Icons.description_outlined,
                  maxLines: 3,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Stream type
          _sectionLabel('Stream Type'),
          _streamTypeCard('youtube', 'YT', 'YouTube Live', 'Paste live URL'),
          if (_streamType == 'youtube') ...[
            const SizedBox(height: 12),
            _card(
              child: _field(
                controller: _youtubeUrlCtrl,
                label: 'YouTube Live URL or Video ID *',
                hint: 'https://youtube.com/watch?v=...',
                icon: Icons.smart_display_rounded,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _streamTypeCard(
                      'mobile', '📱', 'Mobile', 'Use phone camera')),
              const SizedBox(width: 12),
              Expanded(
                  child: _streamTypeCard(
                      'professional', '🎥', 'Professional', 'Studio setup')),
            ],
          ),
          const SizedBox(height: 18),

          // Pricing
          _sectionLabel('Pricing'),
          Row(
            children: [
              Expanded(child: _pricingCard('free', 'FREE', '₹0')),
              const SizedBox(width: 12),
              Expanded(child: _pricingCard('paid', 'PAID', '₹99')),
            ],
          ),
          const SizedBox(height: 18),

          // Additional info
          _sectionLabel('Additional Info'),
          _card(
            child: _field(
              controller: _reqCtrl,
              label: 'Looking for co-hosts?',
              hint: 'e.g. Need Hindi commentator',
              icon: Icons.group_add_outlined,
              maxLines: 2,
            ),
          ),
          const SizedBox(height: 18),

          // Terms
          _card(
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _acceptTerms,
                    activeColor: _primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5)),
                    side: const BorderSide(color: _textMuted, width: 1.2),
                    onChanged: (_) =>
                        setState(() => _acceptTerms = !_acceptTerms),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'I accept the Terms & Conditions',
                    style: TextStyle(
                        fontSize: 13.5,
                        color: _textSecondary,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Go Live button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: _isCreating ? _primary.withOpacity(0.7) : _primary,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: _primary.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: _isCreating ? null : _createStream,
                  child: Center(
                    child: _isCreating
                        ? const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(_white),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('Creating Stream…',
                                  style: TextStyle(
                                      color: _white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700)),
                            ],
                          )
                        : const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.stream_rounded,
                                  color: _white, size: 20),
                              SizedBox(width: 10),
                              Text('Go Live Now',
                                  style: TextStyle(
                                      color: _white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Container(
              width: 3,
              height: 16,
              decoration: BoxDecoration(
                  color: _primary,
                  borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
          ],
        ),
      );

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border, width: 0.8),
          boxShadow: const [
            BoxShadow(
                color: _cardShadow, blurRadius: 10, offset: Offset(0, 3)),
          ],
        ),
        child: child,
      );

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) =>
      TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(
            fontSize: 14,
            color: _textPrimary,
            fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          labelStyle:
              const TextStyle(color: _textMuted, fontSize: 13),
          hintText: hint,
          hintStyle:
              const TextStyle(color: _textMuted, fontSize: 13),
          prefixIcon: Icon(icon, color: _textMuted, size: 19),
          filled: true,
          fillColor: _surfaceGrey,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 13),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _border, width: 0.8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _primary, width: 1.6),
          ),
        ),
      );

  Widget _streamTypeCard(
      String value, String emoji, String title, String subtitle) {
    final sel = _streamType == value;
    return GestureDetector(
      onTap: () => setState(() => _streamType = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: sel ? _primaryBg : _white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: sel ? _primary : _border,
            width: sel ? 1.5 : 0.8,
          ),
          boxShadow: [
            BoxShadow(
                color: sel ? _primary.withOpacity(0.08) : _cardShadow,
                blurRadius: 10,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(title,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: sel ? _primary : _textPrimary)),
            const SizedBox(height: 3),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: _textMuted, fontSize: 11.5)),
            if (sel) ...[
              const SizedBox(height: 8),
              const Icon(Icons.check_circle_rounded,
                  color: _primary, size: 18),
            ],
          ],
        ),
      ),
    );
  }

  Widget _pricingCard(String value, String title, String price) {
    final sel = _pricing == value;
    return GestureDetector(
      onTap: () => setState(() {
        _pricing = value;
        if (value == 'paid') _priceAmount = 99;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: sel ? _primaryBg : _white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: sel ? _primary : _border,
            width: sel ? 1.5 : 0.8,
          ),
          boxShadow: [
            BoxShadow(
                color: sel ? _primary.withOpacity(0.08) : _cardShadow,
                blurRadius: 10,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          children: [
            Text(title,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: sel ? _primary : _textMuted,
                    letterSpacing: 0.8)),
            const SizedBox(height: 4),
            Text(price,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: sel ? _primary : _textSecondary)),
            if (sel) ...[
              const SizedBox(height: 6),
              const Icon(Icons.check_circle_rounded,
                  color: _primary, size: 18),
            ],
          ],
        ),
      ),
    );
  }

  // ── WATCH TAB ────────────────────────────────────────────────────────────────
  Widget _buildWatchTab() => _buildLiveNowTab();

  // ── HELP TAB ─────────────────────────────────────────────────────────────────
  Widget _buildHelpTab() {
    final mq   = MediaQuery.of(context);
    final hPad = mq.size.width > 600 ? mq.size.width * 0.08 : 16.0;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _primaryBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: _primaryBorder.withOpacity(0.4), width: 0.8),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.help_outline_rounded,
                      color: _primary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_t('Need Help?', 'सहायता चाहिए?'),
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: _textPrimary)),
                      const SizedBox(height: 3),
                      const Text('Frequently asked questions',
                          style: TextStyle(
                              fontSize: 12.5, color: _textMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _faqItem(
            _t('How to go live?', 'लाइव कैसे जाएं?'),
            _t(
              'Click on 📺 Go Live tab, fill your stream details, and press "Go Live Now".',
              '📺 लाइव जाएं टैब पर क्लिक करें, विवरण भरें, और "लाइव जाएं" दबाएं।',
            ),
            Icons.cast_rounded,
          ),
          _faqItem(
            _t('What is RTMP URL?', 'RTMP URL क्या है?'),
            _t(
              'RTMP URL is the server address you enter in OBS or any streaming software. You will get it automatically after starting a stream.',
              'RTMP URL वह सर्वर पता है जिसे आपको OBS में डालना है। स्ट्रीम शुरू करने के बाद यह अपने आप मिलेगा।',
            ),
            Icons.link_rounded,
          ),
          _faqItem(
            _t('How much does it cost?', 'इसकी कीमत क्या है?'),
            _t(
              'Basic streaming is completely free. Paid streams have a small fee set by the streamer.',
              'बेसिक स्ट्रीमिंग पूरी तरह मुफ्त है। भुगतान वाली स्ट्रीम पर स्ट्रीमर द्वारा शुल्क निर्धारित होती है।',
            ),
            Icons.currency_rupee_rounded,
          ),
          _faqItem(
            _t('Can I earn money?', 'क्या मैं पैसा कमा सकता हूं?'),
            _t(
              'Yes! Create paid streams or receive gifts from your viewers to earn money.',
              'हाँ! भुगतान वाली स्ट्रीम बनाकर या दर्शकों से उपहार प्राप्त करके कमाई करें।',
            ),
            Icons.monetization_on_rounded,
          ),
        ],
      ),
    );
  }

  Widget _faqItem(String q, String a, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border, width: 0.8),
        boxShadow: const [
          BoxShadow(
              color: _cardShadow, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          leading: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _primaryBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: _primary, size: 16),
          ),
          title: Text(q,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                  color: _textPrimary)),
          iconColor: _primary,
          collapsedIconColor: _textMuted,
          tilePadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding:
              const EdgeInsets.fromLTRB(14, 0, 14, 14),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _surfaceGrey,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(a,
                  style: const TextStyle(
                      color: _textSecondary,
                      fontSize: 13,
                      height: 1.6)),
            ),
          ],
        ),
      ),
    );
  }
}
