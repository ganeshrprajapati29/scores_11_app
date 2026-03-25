import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
// MOCK MODELS  (replace with your real imports)
// ─────────────────────────────────────────────
class AppColors {
  static const Color primary     = Color(0xFF1E88E5);
  static const Color primaryDark = Color(0xFF1565C0);
  static const Color secondary   = Color(0xFFFB8C00);
  static const Color success     = Color(0xFF43A047);
  static const Color error       = Color(0xFFE53935);
}

class LiveStreamPricing {
  final String type;
  final double amount;
  final String currency;
  LiveStreamPricing({required this.type, required this.amount, required this.currency});
  String get displayPrice => type == 'free' ? 'Free' : '₹${amount.toStringAsFixed(0)}';
}

class LiveStreamModel {
  final String id;
  final String title;
  final String? description;
  final String? thumbnail;
  final String status;
  final int viewerCount;
  final int likes;
  final String streamType;
  final bool isPrivate;
  final LiveStreamPricing? pricing;

  LiveStreamModel({
    required this.id,
    required this.title,
    this.description,
    this.thumbnail,
    required this.status,
    required this.viewerCount,
    required this.likes,
    required this.streamType,
    required this.isPrivate,
    this.pricing,
  });

  bool get isLive     => status == 'live';
  bool get isFree     => pricing == null || pricing!.type == 'free';
  String get statusDisplay     => isLive ? 'LIVE' : status.toUpperCase();
  String get streamTypeDisplay => streamType == 'mobile'       ? 'Mobile Camera'
                                : streamType == 'professional' ? 'Pro Camera'
                                : 'Live Session';
}

// ─────────────────────────────────────────────
// MOCK SERVICE  (replace with your real service)
// ─────────────────────────────────────────────
class LiveStreamService {
  Future<List<LiveStreamModel>> getLiveStreams({String status = 'live'}) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return [
      LiveStreamModel(id: '1', title: 'India vs Australia ODI', status: 'live',
          viewerCount: 12450, likes: 3200, streamType: 'mobile', isPrivate: false,
          pricing: LiveStreamPricing(type: 'free', amount: 0, currency: 'INR')),
      LiveStreamModel(id: '2', title: 'IPL 2024 Match Analysis', status: 'live',
          viewerCount: 5600, likes: 1100, streamType: 'professional', isPrivate: false,
          pricing: LiveStreamPricing(type: 'paid', amount: 49, currency: 'INR')),
    ];
  }

  Future<List<LiveStreamModel>> getFeaturedStreams() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return [
      LiveStreamModel(id: '3', title: 'World Cup Highlights', status: 'live',
          viewerCount: 30000, likes: 8000, streamType: 'professional', isPrivate: false,
          pricing: LiveStreamPricing(type: 'free', amount: 0, currency: 'INR')),
    ];
  }

  Future<LiveStreamModel> createLiveStream(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(seconds: 1));
    return LiveStreamModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: data['title'] as String,
      description: data['description'] as String?,
      status: 'live',
      viewerCount: 0,
      likes: 0,
      streamType: data['streamType'] as String,
      isPrivate: data['isPrivate'] as bool,
      pricing: LiveStreamPricing(
        type: (data['pricing'] as Map)['type'] as String,
        amount: ((data['pricing'] as Map)['amount'] as num).toDouble(),
        currency: 'INR',
      ),
    );
  }
}

// ─────────────────────────────────────────────
// MAIN SCREEN
// ─────────────────────────────────────────────
class GoLiveScreen extends StatefulWidget {
  const GoLiveScreen({super.key});

  @override
  State<GoLiveScreen> createState() => _GoLiveScreenState();
}

class _GoLiveScreenState extends State<GoLiveScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final LiveStreamService _service = LiveStreamService();

  List<LiveStreamModel> _liveStreams    = [];
  List<LiveStreamModel> _featuredStreams = [];
  bool   _isLoading = true;
  String? _error;

  // Language
  String _selectedLanguage = 'English';

  // Form
  bool   _acceptTerms  = false;
  bool   _isCreating   = false;
  final  _titleCtrl    = TextEditingController();
  final  _descCtrl     = TextEditingController();
  final  _reqCtrl      = TextEditingController();

  // Stream type: only 3 options
  String _streamType   = 'mobile';        // 'mobile' | 'professional' | 'session'
  String _quality      = '720p';
  String _category     = 'other';
  bool   _isPrivate    = false;
  String _pricing      = 'free';
  double _priceAmount  = 99;
  List<String> _lookingFor = [];

  // ── Bilingual labels ─────────────────────────────
  String _t(String en, String hi) =>
      _selectedLanguage == 'Hindi' ? hi : en;

  // ── Language list ──────────────────────────────────
  static const _languages = ['English', 'Hindi'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadStreams();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _reqCtrl.dispose();
    super.dispose();
  }

  // ── Data ─────────────────────────────────────────
  Future<void> _loadStreams() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final live     = await _service.getLiveStreams(status: 'live');
      final featured = await _service.getFeaturedStreams();
      setState(() {
        _liveStreams     = live;
        _featuredStreams = featured;
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  // ── Create stream ────────────────────────────────
  Future<void> _createStream() async {
    if (!_acceptTerms) {
      _snack(_t('Please accept Terms & Conditions',
                 'कृपया नियम व शर्तें स्वीकार करें'), isError: true);
      return;
    }
    if (_titleCtrl.text.trim().isEmpty) {
      _snack(_t('Please enter a title', 'कृपया शीर्षक दर्ज करें'), isError: true);
      return;
    }

    setState(() => _isCreating = true);
    try {
      final data = {
        'title':        _titleCtrl.text.trim(),
        'description':  _descCtrl.text.trim(),
        'streamType':   _streamType,
        'streamQuality': _quality,
        'category':     _category,
        'isPrivate':    _isPrivate,
        'pricing': {
          'type':     _pricing,
          'amount':   _pricing == 'free' ? 0 : _priceAmount,
          'currency': 'INR',
        },
        'lookingFor':   _lookingFor,
        'requirements': _reqCtrl.text.trim(),
      };

      final stream = await _service.createLiveStream(data);

      if (mounted) {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => LiveStreamPlayerScreen(stream: stream),
        ));
      }
    } catch (e) {
      if (mounted) _snack('${_t("Error","त्रुटि")}: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.success,
    ));
  }

  // ── Language dialog ──────────────────────────────
  void _showLangDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(_t('Select Language', 'भाषा चुनें')),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _languages.map((lang) => ListTile(
            leading: Text(lang == 'Hindi' ? '🇮🇳' : '🇺🇸',
                style: const TextStyle(fontSize: 22)),
            title: Text(lang),
            trailing: _selectedLanguage == lang
                ? const Icon(Icons.check_circle, color: AppColors.primary)
                : null,
            onTap: () {
              setState(() => _selectedLanguage = lang);
              Navigator.pop(context);
            },
          )).toList(),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end:   Alignment.bottomRight,
            colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ──────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        _t('Go Live', 'लाइव जाएं'),
                        style: const TextStyle(
                          color: Colors.white, fontSize: 22,
                          fontWeight: FontWeight.bold),
                      ),
                    ),
                    // Language pill
                    GestureDetector(
                      onTap: _showLangDialog,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_selectedLanguage == 'Hindi' ? '🇮🇳' : '🇺🇸',
                                style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 6),
                            Text(_selectedLanguage,
                                style: const TextStyle(color: Colors.white,
                                    fontSize: 13)),
                            const Icon(Icons.arrow_drop_down,
                                color: Colors.white, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),

              // ── Tab Bar ──────────────────────────────
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelColor: AppColors.primary,
                  unselectedLabelColor: Colors.white,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 11),
                  tabs: [
                    Tab(text: _t('🔴 Live Now', '🔴 अभी लाइव')),
                    Tab(text: _t('📺 Go Live', '📺 लाइव करें')),
                    Tab(text: _t('📋 Watch', '📋 देखें')),
                    Tab(text: _t('❓ Help', '❓ सहायता')),
                  ],
                ),
              ),

              // ── Tab Body ─────────────────────────────
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20)),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20)),
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────
  //  TAB 1 – LIVE NOW
  // ─────────────────────────────────────────────────
  Widget _buildLiveNowTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(_t('Error loading streams', 'स्ट्रीम लोड करने में त्रुटि'),
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadStreams,
              child: Text(_t('Retry', 'पुनः प्रयास')),
            ),
          ],
        ),
      );
    }

    final all = [..._featuredStreams, ..._liveStreams];

    if (all.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.live_tv, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(_t('No live streams', 'कोई लाइव स्ट्रीम नहीं'),
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _tabController.animateTo(1),
              icon: const Icon(Icons.add),
              label: Text(_t('Go Live', 'लाइव जाएं')),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStreams,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: all.length,
        itemBuilder: (_, i) => _buildStreamCard(
            all[i], isFeatured: i < _featuredStreams.length),
      ),
    );
  }

  Widget _buildStreamCard(LiveStreamModel stream,
      {bool isFeatured = false}) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => LiveStreamPlayerScreen(stream: stream))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isFeatured
              ? Border.all(color: AppColors.secondary, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Stack(
              children: [
                Container(
                  height: 170,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(14)),
                  ),
                  child: stream.thumbnail != null
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(14)),
                          child: Image.network(stream.thumbnail!,
                              fit: BoxFit.cover, width: double.infinity),
                        )
                      : Center(
                          child: Icon(Icons.live_tv,
                              size: 56, color: Colors.grey[500])),
                ),
                // LIVE badge
                Positioned(
                  top: 10, left: 10,
                  child: _liveBadge(stream),
                ),
                // Viewer count
                Positioned(
                  bottom: 10, right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(6)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.visibility,
                            color: Colors.white, size: 13),
                        const SizedBox(width: 4),
                        Text('${stream.viewerCount}',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(stream.title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _chip(stream.streamTypeDisplay, AppColors.primary),
                      if (!stream.isFree) ...[
                        const SizedBox(width: 8),
                        _chip(stream.pricing!.displayPrice,
                            AppColors.secondary),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _liveBadge(LiveStreamModel stream) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: stream.isLive ? AppColors.error : Colors.grey,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (stream.isLive) ...[
              const Icon(Icons.circle, color: Colors.white, size: 7),
              const SizedBox(width: 4),
            ],
            Text(stream.statusDisplay,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11)),
          ],
        ),
      );

  Widget _chip(String label, Color color) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(6)),
        child: Text(label,
            style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      );

  // ─────────────────────────────────────────────────
  //  TAB 2 – GO LIVE (FORM)
  // ─────────────────────────────────────────────────
  Widget _buildGoLiveTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Stream Type ──────────────────────────
          _sectionTitle(
              _t('🎥 Stream Type', '🎥 स्ट्रीम प्रकार')),
          const SizedBox(height: 12),
          Column(
            children: [
              _streamTypeCard(
                value:    'mobile',
                emoji:    '📱',
                title:    _t('Mobile Camera', 'मोबाइल कैमरा'),
                subtitle: _t('Use your phone camera',
                             'अपने फोन कैमरे का उपयोग करें'),
              ),
              const SizedBox(height: 8),
              _streamTypeCard(
                value:    'professional',
                emoji:    '🎬',
                title:    _t('Professional Camera', 'प्रोफेशनल कैमरा'),
                subtitle: _t('DSLR / External camera',
                             'DSLR / बाहरी कैमरा'),
              ),
              const SizedBox(height: 8),
              _streamTypeCard(
                value:    'session',
                emoji:    '🎓',
                title:    _t('Live Session', 'लाइव सेशन'),
                subtitle: _t('Teaching / coaching',
                             'शिक्षण / कोचिंग'),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Quality ──────────────────────────────
          _sectionTitle(_t('✨ Quality', '✨ गुणवत्ता')),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _qualityChip('720p',  '720p HD'),
              _qualityChip('1080p', '1080p Full HD'),
              _qualityChip('4k',    '4K Ultra HD'),
            ],
          ),

          const SizedBox(height: 24),

          // ── Looking For ──────────────────────────
          _sectionTitle(_t('👥 Looking For', '👥 क्या चाहिए')),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _lookChip('co-host',     _t('🤝 Co-host',     '🤝 को-होस्ट')),
              _lookChip('commentator', _t('🎙️ Commentator', '🎙️ कमेंटेटर')),
              _lookChip('analyst',     _t('📊 Analyst',     '📊 विश्लेषक')),
              _lookChip('viewer',      _t('👀 Viewers',     '👀 दर्शक')),
              _lookChip('player',      _t('🏏 Player',      '🏏 खिलाड़ी')),
            ],
          ),

          const SizedBox(height: 24),

          // ── Stream Details ────────────────────────
          _sectionTitle(_t('📝 Stream Details', '📝 स्ट्रीम विवरण')),
          const SizedBox(height: 12),
          TextField(
            controller: _titleCtrl,
            decoration: InputDecoration(
              labelText: _t('Title *', 'शीर्षक *'),
              hintText:  _t('Enter stream title', 'स्ट्रीम शीर्षक दर्ज करें'),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: _t('Description', 'विवरण'),
              hintText:  _t('Tell viewers what this is about',
                            'दर्शकों को बताएं यह किस बारे में है'),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reqCtrl,
            decoration: InputDecoration(
              labelText: _t('Requirements', 'आवश्यकताएं'),
              hintText:
                  _t('e.g. Wear team jersey', 'जैसे टीम जर्सी पहनें'),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),

          const SizedBox(height: 24),

          // ── Pricing ───────────────────────────────
          _sectionTitle(_t('💰 Pricing', '💰 मूल्य निर्धारण')),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _pricingCard('free', _t('Free', 'मुफ़्त'), '₹0')),
              const SizedBox(width: 12),
              Expanded(
                  child: _pricingCard(
                      'paid', _t('Paid', 'सशुल्क'), '₹${_priceAmount.toInt()}')),
            ],
          ),
          if (_pricing == 'paid') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Text(_t('Amount (₹): ', 'राशि (₹): '),
                    style:
                        const TextStyle(fontWeight: FontWeight.w600)),
                Expanded(
                  child: Slider(
                    value: _priceAmount,
                    min: 10,
                    max: 999,
                    divisions: 98,
                    label: '₹${_priceAmount.toInt()}',
                    activeColor: AppColors.secondary,
                    onChanged: (v) =>
                        setState(() => _priceAmount = v),
                  ),
                ),
                Text('₹${_priceAmount.toInt()}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary)),
              ],
            ),
          ],

          const SizedBox(height: 8),

          // ── Private switch ────────────────────────
          Card(
            elevation: 0,
            color: Colors.grey[100],
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: SwitchListTile(
              title: Text(_t('Private Stream', 'प्राइवेट स्ट्रीम'),
                  style:
                      const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                  _t('Only invited people can watch',
                     'केवल आमंत्रित लोग देख सकते हैं'),
                  style: const TextStyle(fontSize: 12)),
              value: _isPrivate,
              activeColor: AppColors.primary,
              onChanged: (v) => setState(() => _isPrivate = v),
            ),
          ),

          const SizedBox(height: 8),

          // ── Terms ─────────────────────────────────
          Card(
            elevation: 0,
            color: _acceptTerms
                ? AppColors.success.withOpacity(0.08)
                : Colors.grey[100],
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                    color: _acceptTerms
                        ? AppColors.success
                        : Colors.transparent)),
            child: CheckboxListTile(
              value: _acceptTerms,
              onChanged: (v) =>
                  setState(() => _acceptTerms = v ?? false),
              title: Text(
                  _t('I accept Terms & Conditions',
                     'मैं नियम व शर्तें स्वीकार करता/करती हूं'),
                  style:
                      const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                  _t('Please read before streaming',
                     'स्ट्रीम करने से पहले पढ़ें'),
                  style: const TextStyle(fontSize: 12)),
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: AppColors.success,
            ),
          ),

          const SizedBox(height: 20),

          // ── Start Button ──────────────────────────
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: (_acceptTerms && !_isCreating)
                  ? _createStream
                  : null,
              icon: _isCreating
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.live_tv),
              label: Text(
                _isCreating
                    ? _t('Starting...', 'शुरू हो रहा है...')
                    : _t('Start Streaming', 'स्ट्रीमिंग शुरू करें'),
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _acceptTerms
                    ? AppColors.primary
                    : Colors.grey[400],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: _acceptTerms ? 4 : 0,
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(text,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold));

  // Stream type full-width card
  Widget _streamTypeCard({
    required String value,
    required String emoji,
    required String title,
    required String subtitle,
  }) {
    final selected = _streamType == value;
    return GestureDetector(
      onTap: () => setState(() => _streamType = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.08)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withOpacity(0.15)
                    : Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                  child: Text(emoji,
                      style: const TextStyle(fontSize: 26))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: selected
                              ? AppColors.primary
                              : Colors.black87)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: selected ? AppColors.primary : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _qualityChip(String value, String label) {
    final sel = _quality == value;
    return GestureDetector(
      onTap: () => setState(() => _quality = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: sel ? AppColors.primary : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                color: sel ? Colors.white : Colors.black87,
                fontWeight:
                    sel ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }

  Widget _lookChip(String value, String label) {
    final sel = _lookingFor.contains(value);
    return GestureDetector(
      onTap: () {
        setState(() {
          sel ? _lookingFor.remove(value) : _lookingFor.add(value);
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? AppColors.secondary : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                color: sel ? Colors.white : Colors.black87,
                fontWeight:
                    sel ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }

  Widget _pricingCard(String value, String title, String price) {
    final sel      = _pricing == value;
    final isFree   = value == 'free';
    final color    = isFree ? AppColors.success : AppColors.secondary;
    return GestureDetector(
      onTap: () => setState(() => _pricing = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: sel ? color.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: sel ? color : Colors.grey.shade300,
              width: sel ? 2 : 1),
        ),
        child: Column(
          children: [
            Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: sel ? color : Colors.grey[700])),
            const SizedBox(height: 4),
            Text(price,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: sel ? color : Colors.grey[700])),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────
  //  TAB 3 – WATCH (reuse Live Now)
  // ─────────────────────────────────────────────────
  Widget _buildWatchTab() => _buildLiveNowTab();

  // ─────────────────────────────────────────────────
  //  TAB 4 – HELP
  // ─────────────────────────────────────────────────
  Widget _buildHelpTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // What You Get
          _sectionTitle(_t('🎁 What You Get', '🎁 आपको क्या मिलेगा')),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _getCard('📡', _t('Live Streaming', 'लाइव स्ट्रीमिंग'),
                    _t('Broadcast to thousands', 'हजारों को प्रसारित करें')),
                _getCard('💬', _t('Live Chat', 'लाइव चैट'),
                    _t('Interact with viewers', 'दर्शकों से बातचीत करें')),
                _getCard('👥', _t('Find Players', 'खिलाड़ी खोजें'),
                    _t('Recruit for your team', 'टीम के लिए भर्ती करें')),
                _getCard('🏆', _t('Earn Money', 'पैसे कमाएं'),
                    _t('Paid streams & gifts', 'सशुल्क स्ट्रीम')),
                _getCard('📊', _t('Analytics', 'विश्लेषण'),
                    _t('Track your growth', 'अपनी वृद्धि ट्रैक करें')),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // What You Need
          _sectionTitle(
              _t('🛠️ What You Need', '🛠️ आपको क्या चाहिए')),
          const SizedBox(height: 12),
          _needItem('📱', _t('Smartphone', 'स्मार्टफोन'),
              _t('Any modern phone with camera',
                 'कैमरे वाला कोई भी आधुनिक फोन')),
          _needItem('🌐', _t('Internet', 'इंटरनेट'),
              _t('Stable connection (5+ Mbps)', 'स्थिर कनेक्शन (5+ Mbps)')),
          _needItem('🔋', _t('Power', 'पावर'),
              _t('Charging recommended while live',
                 'लाइव के दौरान चार्जिंग सुझाई जाती है')),
          _needItem('💡', _t('Lighting', 'रोशनी'),
              _t('Good lighting for clear video',
                 'स्पष्ट वीडियो के लिए अच्छी रोशनी')),

          const SizedBox(height: 24),

          // FAQ
          _sectionTitle(_t('❓ FAQ', '❓ अक्सर पूछे जाने वाले सवाल')),
          const SizedBox(height: 12),
          _faqItem(
            _t('How do I start streaming?',
               'स्ट्रीमिंग कैसे शुरू करें?'),
            _t('Go to "Go Live" tab → select type → add title → tap Start Streaming.',
               '"लाइव जाएं" टैब पर जाएं → प्रकार चुनें → शीर्षक जोड़ें → "स्ट्रीमिंग शुरू करें" दबाएं।'),
          ),
          _faqItem(
            _t('Which camera should I choose?',
               'कौन सा कैमरा चुनें?'),
            _t('Use "Mobile Camera" for quick streams. Choose "Professional Camera" for high-quality DSLR/external camera setup.',
               'त्वरित स्ट्रीम के लिए "मोबाइल कैमरा" चुनें। उच्च गुणवत्ता DSLR के लिए "प्रोफेशनल कैमरा" चुनें।'),
          ),
          _faqItem(
            _t('How to earn money?',
               'पैसे कैसे कमाएं?'),
            _t('Select "Paid" pricing and set your amount. Viewers pay before joining your stream.',
               '"सशुल्क" मूल्य निर्धारण चुनें और राशि तय करें। दर्शक शामिल होने से पहले भुगतान करते हैं।'),
          ),
          _faqItem(
            _t('Can I stream cricket matches?',
               'क्या मैं क्रिकेट मैच स्ट्रीम कर सकता हूं?'),
            _t('Yes! Use "Live Session" type to commentate and stream live matches.',
               'हां! लाइव मैचों की कमेंट्री के लिए "लाइव सेशन" प्रकार चुनें।'),
          ),

          const SizedBox(height: 24),

          // Premium banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.workspace_premium,
                        color: Colors.amber, size: 30),
                    const SizedBox(width: 8),
                    Text(
                        _t('Go Premium', 'प्रीमियम लें'),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                    _t('Unlock all features!',
                       'सभी सुविधाएं अनलॉक करें!'),
                    style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10))),
                    child: Text(
                        _t('Purchase Plan', 'प्लान खरीदें'),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _getCard(String emoji, String title, String sub) =>
      Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            AppColors.primary.withOpacity(0.08),
            AppColors.secondary.withOpacity(0.08),
          ]),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 34)),
            const SizedBox(height: 8),
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13),
                textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(sub,
                style: TextStyle(
                    fontSize: 11, color: Colors.grey[600]),
                textAlign: TextAlign.center),
          ],
        ),
      );

  Widget _needItem(String emoji, String title, String desc) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: Center(
                  child:
                      Text(emoji, style: const TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style:
                          const TextStyle(fontWeight: FontWeight.bold)),
                  Text(desc,
                      style: TextStyle(
                          color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _faqItem(String q, String a) => ExpansionTile(
        title: Text(q,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 14)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(a, style: TextStyle(color: Colors.grey[700], fontSize: 13))
        ],
      );
}

// ─────────────────────────────────────────────────────────
//  LIVE STREAM PLAYER SCREEN
// ─────────────────────────────────────────────────────────
class LiveStreamPlayerScreen extends StatefulWidget {
  final LiveStreamModel stream;
  const LiveStreamPlayerScreen({super.key, required this.stream});

  @override
  State<LiveStreamPlayerScreen> createState() =>
      _LiveStreamPlayerScreenState();
}

class _LiveStreamPlayerScreenState
    extends State<LiveStreamPlayerScreen> {
  bool _showScorecard = true;

  final _score = {
    'team1':    {'name': 'India',     'score': '245/6', 'overs': '42.3'},
    'team2':    {'name': 'Australia', 'score': '180/2', 'overs': '28.1'},
    'bat1':     {'name': 'Virat Kohli',   'runs': 67, 'balls': 89, 'fours': 5, 'sixes': 1},
    'bat2':     {'name': 'Rohit Sharma',  'runs': 42, 'balls': 51, 'fours': 4, 'sixes': 2},
    'bowler':   {'name': 'Starc', 'overs': '7.3', 'runs': 45, 'wickets': 2},
    'lastOver': [0, 1, 4, 0, 6, 2],
    'venue':    'Wankhede Stadium, Mumbai',
    'format':   'ODI - World Cup',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Video area
            Expanded(
              flex: _showScorecard ? 2 : 5,
              child: Stack(
                children: [
                  // Placeholder video
                  Container(
                    color: Colors.black,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.live_tv,
                              size: 72, color: Colors.white38),
                          const SizedBox(height: 12),
                          Text(widget.stream.title,
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16),
                              textAlign: TextAlign.center),
                          const SizedBox(height: 4),
                          const Text('● LIVE',
                              style: TextStyle(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  // Top gradient + controls
                  Positioned(
                    top: 0, left: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black87,
                            Colors.transparent
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back,
                                color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Expanded(
                            child: Text(widget.stream.title,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                          _livePill(),
                          const SizedBox(width: 8),
                          Text('${widget.stream.viewerCount} 👁',
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12)),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                  ),
                  // Bottom controls
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black87,
                            Colors.transparent
                          ],
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceEvenly,
                        children: [
                          _ctrl(Icons.thumb_up_outlined,
                              '${widget.stream.likes}'),
                          _ctrl(Icons.share_outlined, 'Share'),
                          _ctrl(Icons.chat_bubble_outline, 'Chat'),
                          GestureDetector(
                            onTap: () => setState(
                                () => _showScorecard =
                                    !_showScorecard),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _showScorecard
                                      ? Icons.scoreboard
                                      : Icons.scoreboard_outlined,
                                  color: _showScorecard
                                      ? Colors.amber
                                      : Colors.white,
                                  size: 24,
                                ),
                                const SizedBox(height: 4),
                                Text('Score',
                                    style: TextStyle(
                                        color: _showScorecard
                                            ? Colors.amber
                                            : Colors.white,
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Scorecard
            if (_showScorecard)
              Expanded(
                flex: 3,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20)),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        // Match info
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: AppColors.primary
                                  .withOpacity(0.08),
                              borderRadius:
                                  BorderRadius.circular(12)),
                          child: Row(
                            children: [
                              const Icon(Icons.sports_cricket,
                                  color: AppColors.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        _score['format'] as String,
                                        style: const TextStyle(
                                            fontWeight:
                                                FontWeight.bold)),
                                    Text(
                                        _score['venue'] as String,
                                        style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _teamRow(_score['team1'] as Map, true),
                        _teamRow(_score['team2'] as Map, false),
                        const SizedBox(height: 12),
                        const Text('Current Batsmen',
                            style: TextStyle(
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        _batsmanRow(
                            _score['bat1'] as Map, true),
                        _batsmanRow(
                            _score['bat2'] as Map, false),
                        const SizedBox(height: 12),
                        const Text('Current Bowler',
                            style: TextStyle(
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        _bowlerRow(_score['bowler'] as Map),
                        const SizedBox(height: 12),
                        const Text('Last Over',
                            style: TextStyle(
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(
                          children: (_score['lastOver'] as List)
                              .map((b) => _ballBubble(b as int))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _livePill() => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: AppColors.error,
            borderRadius: BorderRadius.circular(4)),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, color: Colors.white, size: 7),
            SizedBox(width: 4),
            Text('LIVE',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      );

  Widget _ctrl(IconData icon, String label) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 4),
          Text(label,
              style:
                  const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      );

  Widget _teamRow(Map t, bool isLead) => Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isLead
              ? AppColors.success.withOpacity(0.08)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: isLead
              ? Border.all(color: AppColors.success)
              : null,
        ),
        child: Row(
          children: [
            Expanded(
                child: Text(t['name'] as String,
                    style: TextStyle(
                        fontWeight: isLead
                            ? FontWeight.bold
                            : FontWeight.normal))),
            Text(t['score'] as String,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: isLead
                        ? AppColors.success
                        : Colors.black)),
            const SizedBox(width: 6),
            Text('(${t['overs']})',
                style: TextStyle(color: Colors.grey[600])),
            if (isLead) ...[
              const SizedBox(width: 8),
              _livePill(),
            ],
          ],
        ),
      );

  Widget _batsmanRow(Map b, bool isStrike) => Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Icon(
                isStrike
                    ? Icons.sports_cricket
                    : Icons.sports_cricket_outlined,
                color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(b['name'] as String,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold)),
                  Text(
                      '${b['fours']} fours  ${b['sixes']} sixes',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${b['runs']}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20)),
                Text('${b['balls']} balls',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ],
        ),
      );

  Widget _bowlerRow(Map b) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: AppColors.secondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            const Icon(Icons.sports_score,
                color: AppColors.secondary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(b['name'] as String,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold)),
                  Text('${b['overs']} overs',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${b['runs']} runs',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold)),
                Text('${b['wickets']} wkts',
                    style: const TextStyle(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ],
            ),
          ],
        ),
      );

  Widget _ballBubble(int runs) => Container(
        width: 38, height: 38,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: runs == 4
              ? Colors.blue
              : runs == 6
                  ? Colors.purple
                  : runs == 0
                      ? Colors.red[700]
                      : Colors.orange,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text('$runs',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
        ),
      );
}