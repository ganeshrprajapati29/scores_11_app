import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/config/theme_config.dart';
import '../../data/services/live_stream_service.dart';
import '../../data/models/live_stream_model.dart';
import '../../providers/auth_provider.dart';

class GoLiveScreen extends StatefulWidget {
  const GoLiveScreen({super.key});

  @override
  State<GoLiveScreen> createState() => _GoLiveScreenState();
}

class _GoLiveScreenState extends State<GoLiveScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final LiveStreamService _liveStreamService = LiveStreamService();
  
  List<LiveStreamModel> _liveStreams = [];
  List<LiveStreamModel> _featuredStreams = [];
  bool _isLoading = true;
  String? _error;
  
  // Language selection
  String _selectedLanguage = 'English';
  
  // Terms acceptance
  bool _acceptTerms = false;
  
  // Stream creation form
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _requirementsController = TextEditingController();
  String _selectedStreamType = 'mobile';
  String _selectedQuality = '720p';
  String _selectedCategory = 'other';
  bool _isPrivate = false;
  String _selectedPricing = 'free';
  double _priceAmount = 0;
  List<String> _lookingFor = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadStreams();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _requirementsController.dispose();
    super.dispose();
  }

  Future<void> _loadStreams() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final liveResult = await _liveStreamService.getLiveStreams(status: 'live');
      final featuredResult = await _liveStreamService.getFeaturedStreams();

      setState(() {
        _liveStreams = _liveStreamService.parseLiveStreams(liveResult);
        _featuredStreams = _liveStreamService.parseLiveStreams(featuredResult);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _createStream() async {
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept Terms and Conditions'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title'), backgroundColor: AppColors.error),
      );
      return;
    }

    try {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.status != AuthStatus.authenticated) {
        Navigator.pushNamed(context, '/login');
        return;
      }

      final streamData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'streamType': _selectedStreamType,
        'streamQuality': _selectedQuality,
        'category': _selectedCategory,
        'isPrivate': _isPrivate,
        'pricing': {
          'type': _selectedPricing,
          'amount': _selectedPricing == 'free' ? 0 : _priceAmount,
          'currency': 'INR'
        },
        'lookingFor': _lookingFor,
        'requirements': _requirementsController.text,
      };

      final result = await _liveStreamService.createLiveStream(streamData);
      final stream = _liveStreamService.parseLiveStream(result);
      
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LiveStreamPlayerScreen(stream: stream),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption('English', '🇺🇸'),
            _buildLanguageOption('हिंदी', '🇮🇳'),
            _buildLanguageOption('தமிழ்', '🇮🇳'),
            _buildLanguageOption('తెలుగు', '🇮🇳'),
            _buildLanguageOption('मराठी', '🇮🇳'),
            _buildLanguageOption('ગુજરાતી', '🇮🇳'),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String lang, String flag) {
    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 24)),
      title: Text(lang),
      trailing: _selectedLanguage == lang ? const Icon(Icons.check, color: AppColors.primary) : null,
      onTap: () {
        setState(() => _selectedLanguage = lang);
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Go Live',
                        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.language, color: Colors.white),
                      onPressed: _showLanguageDialog,
                    ),
                  ],
                ),
              ),
              
              // Language indicator
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🌐', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(_selectedLanguage, style: const TextStyle(color: Colors.white)),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
                  ],
                ),
              ),
              
              // Tab Bar
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelColor: AppColors.primary,
                  unselectedLabelColor: Colors.white,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  tabs: const [
                    Tab(text: '🏏 Live Now'),
                    Tab(text: '📺 Go Live'),
                    Tab(text: '🔍 Watch'),
                    Tab(text: '❓ Help'),
                  ],
                ),
              ),
              
              // Tab Content
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveNowTab() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text('Error: $_error'));

    final allStreams = [..._featuredStreams, ..._liveStreams];
    
    if (allStreams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.live_tv, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('No live streams', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _tabController.animateTo(1),
              icon: const Icon(Icons.add),
              label: const Text('Go Live'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStreams,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: allStreams.length,
        itemBuilder: (context, index) {
          final stream = allStreams[index];
          return _buildStreamCard(stream, isFeatured: index < _featuredStreams.length);
        },
      ),
    );
  }

  Widget _buildStreamCard(LiveStreamModel stream, {bool isFeatured = false}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LiveStreamPlayerScreen(stream: stream),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: isFeatured ? Border.all(color: AppColors.secondary, width: 2) : null,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: stream.thumbnail != null
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          child: Image.network(stream.thumbnail!, fit: BoxFit.cover, width: double.infinity),
                        )
                      : Center(child: Icon(Icons.live_tv, size: 64, color: Colors.grey[500])),
                ),
                Positioned(
                  top: 12, left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: stream.isLive ? AppColors.error : Colors.grey,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (stream.isLive) const Icon(Icons.circle, color: Colors.white, size: 8),
                        const SizedBox(width: 4),
                        Text(stream.statusDisplay, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12, right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
                    child: Row(
                      children: [
                        const Icon(Icons.visibility, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text('${stream.viewerCount}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(stream.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), maxLines: 2),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                        child: Text(stream.streamTypeDisplay, style: TextStyle(color: AppColors.primary, fontSize: 12)),
                      ),
                      if (!stream.isFree) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                          child: Text(stream.pricing?.displayPrice ?? '', style: TextStyle(color: AppColors.secondary, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
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

  Widget _buildGoLiveTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stream Type Selection
          const Text('🎥 Stream Type', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStreamTypeChip('mobile', '📱 Mobile Camera', 'Use phone camera'),
              _buildStreamTypeChip('professional', '🎬 Professional', 'DSLR/Pro camera'),
              _buildStreamTypeChip('session', '🎓 Live Session', 'Teaching/coaching'),
              _buildStreamTypeChip('watch', '📺 Watch Party', 'Watch & react'),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Quality Selection
          const Text('✨ Quality', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildQualityChip('720p', '720p HD'),
              _buildQualityChip('1080p', '1080p Full HD'),
              _buildQualityChip('4k', '4K Ultra HD'),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Looking For Section
          const Text('👥 Looking For', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildLookingForChip('co-host', '🤝 Co-host'),
              _buildLookingForChip('commentator', '🎙️ Commentator'),
              _buildLookingForChip('analyst', '📊 Analyst'),
              _buildLookingForChip('viewer', '👀 Viewers'),
              _buildLookingForChip('player', '🏏 Player'),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Stream Details
          const Text('📝 Stream Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Title',
              hintText: 'Enter stream title',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Pricing
          const Text('💰 Pricing', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildPricingCard('free', 'Free', '₹0', true)),
              const SizedBox(width: 12),
              Expanded(child: _buildPricingCard('paid', 'Paid', 'Custom', false)),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Private Stream
          SwitchListTile(
            title: const Text('Private Stream'),
            subtitle: const Text('Only invited can watch'),
            value: _isPrivate,
            onChanged: (v) => setState(() => _isPrivate = v),
          ),
          
          const SizedBox(height: 16),
          
          // Terms & Conditions
          CheckboxListTile(
            value: _acceptTerms,
            onChanged: (v) => setState(() => _acceptTerms = v ?? false),
            title: const Text('I accept Terms & Conditions'),
            subtitle: const Text('Read terms before streaming'),
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: AppColors.primary,
          ),
          
          const SizedBox(height: 16),
          
          // Go Live Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _acceptTerms ? _createStream : null,
              icon: const Icon(Icons.live_tv),
              label: const Text('Start Streaming', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _acceptTerms ? AppColors.primary : Colors.grey,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Free OK Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedPricing = 'free';
                  _acceptTerms = true;
                  _titleController.text = 'Free Cricket Stream';
                });
              },
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Free - OK!'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.success,
                side: const BorderSide(color: AppColors.success),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreamTypeChip(String value, String label, String subtitle) {
    final isSelected = _selectedStreamType == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedStreamType = value),
      child: Container(
        width: (MediaQuery.of(context).size.width - 48) / 2 - 4,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppColors.primary : Colors.transparent, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? AppColors.primary : Colors.black)),
            Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildQualityChip(String value, String label) {
    final isSelected = _selectedQuality == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedQuality = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black)),
      ),
    );
  }

  Widget _buildLookingForChip(String value, String label) {
    final isSelected = _lookingFor.contains(value);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) _lookingFor.remove(value);
          else _lookingFor.add(value);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondary : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black)),
      ),
    );
  }

  Widget _buildPricingCard(String value, String title, String price, bool isFree) {
    final isSelected = _selectedPricing == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedPricing = value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? (isFree ? AppColors.success : AppColors.secondary).withValues(alpha: 0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? (isFree ? AppColors.success : AppColors.secondary) : Colors.transparent, width: 2),
        ),
        child: Column(
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? (isFree ? AppColors.success : AppColors.secondary) : Colors.black)),
            Text(price, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isSelected ? (isFree ? AppColors.success : AppColors.secondary) : Colors.black)),
          ],
        ),
      ),
    );
  }

  Widget _buildWatchTab() => _buildLiveNowTab();

  Widget _buildHelpTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // What You Get Section
          const Text('🎁 What You Get', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildWhatYouGetCard('📡', 'Live Streaming', 'Broadcast to thousands'),
                _buildWhatYouGetCard('💬', 'Chat', 'Interact with viewers'),
                _buildWhatYouGetCard('👥', 'Find Players', 'Recruit for your team'),
                _buildWhatYouGetCard('🏆', 'Earn Money', 'Paid streams & gifts'),
                _buildWhatYouGetCard('📊', 'Analytics', 'Track your growth'),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // What You Need Section
          const Text('🛠️ What You Need', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildWhatYouNeedItem('📱', 'Smartphone', 'Any modern smartphone with camera'),
          _buildWhatYouNeedItem('🌐', 'Internet', 'Stable broadband connection (5+ Mbps)'),
          _buildWhatYouNeedItem('🔋', 'Power', 'Charging while streaming recommended'),
          _buildWhatYouNeedItem('💡', 'Lighting', 'Good lighting for clear video'),
          
          const SizedBox(height: 24),
          
          // FAQ
          const Text('❓ FAQ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildFAQItem('How do I start?', 'Go to "Go Live" tab, select type, add title, tap Start'),
          _buildFAQItem('Can I stream matches?', 'Yes! Use "Watch Party" type to stream and commentate live matches'),
          _buildFAQItem('How to earn money?', 'Set paid streams or get tips from viewers'),
          
          const SizedBox(height: 24),
          
          // Premium Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.workspace_premium, color: Colors.amber, size: 32),
                    SizedBox(width: 8),
                    Text('Go Premium', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Unlock all features!', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
                    child: const Text('Tap to Purchase Plan'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhatYouGetCard(String emoji, String title, String subtitle) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primary.withValues(alpha: 0.1), AppColors.secondary.withValues(alpha: 0.1)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600]), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildWhatYouNeedItem(String emoji, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(description, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return ExpansionTile(
      title: Text(question, style: const TextStyle(fontWeight: FontWeight.bold)),
      children: [Padding(padding: const EdgeInsets.all(16), child: Text(answer))],
    );
  }
}

// Live Stream Player Screen with Video & Scorecard
class LiveStreamPlayerScreen extends StatefulWidget {
  final LiveStreamModel stream;
  
  const LiveStreamPlayerScreen({super.key, required this.stream});

  @override
  State<LiveStreamPlayerScreen> createState() => _LiveStreamPlayerScreenState();
}

class _LiveStreamPlayerScreenState extends State<LiveStreamPlayerScreen> {
  bool _showScorecard = true;
  bool _isFullScreen = false;
  
  // Mock score data
  final Map<String, dynamic> _matchScore = {
    'team1': {'name': 'India', 'score': '245/6', 'overs': '42.3'},
    'team2': {'name': 'Australia', 'score': '180/2', 'overs': '28.1'},
    'currentBatsman1': {'name': 'Virat Kohli', 'runs': 67, 'balls': 89, 'fours': 5, 'sixes': 1},
    'currentBatsman2': {'name': 'Rohit Sharma', 'runs': 42, 'balls': 51, 'fours': 4, 'sixes': 2},
    'currentBowler': {'name': 'Starc', 'overs': '7.3', 'runs': 45, 'wickets': 2},
    'lastOver': [0, 1, 4, 0, 6, 2],
    'venue': 'Wankhede Stadium, Mumbai',
    'format': 'ODI - World Cup',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Video Player Area
            Expanded(
              flex: _showScorecard ? 2 : 4,
              child: Stack(
                children: [
                  // Video placeholder
                  Container(
                    color: Colors.black,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.live_tv, size: 80, color: Colors.white54),
                          SizedBox(height: 16),
                          Text('Live Stream', style: TextStyle(color: Colors.white, fontSize: 18)),
                          Text('RTMP Stream Playing', style: TextStyle(color: Colors.white54)),
                        ],
                      ),
                    ),
                  ),
                  
                  // Top controls
                  Positioned(
                    top: 0, left: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black87, Colors.transparent]),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.stream.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                Row(
                                  children: [
                                    Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(4)), child: const Row(children: [Icon(Icons.circle, color: Colors.white, size: 6), SizedBox(width: 4), Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10))])),
                                    const SizedBox(width: 8),
                                    Text('${widget.stream.viewerCount} watching', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(icon: const Icon(Icons.fullscreen, color: Colors.white), onPressed: () => setState(() => _isFullScreen = !_isFullScreen)),
                        ],
                      ),
                    ),
                  ),
                  
                  // Bottom controls
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black87, Colors.transparent]),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildControlButton(Icons.thumb_up, '${widget.stream.likes}'),
                          _buildControlButton(Icons.share, 'Share'),
                          _buildControlButton(Icons.chat, 'Chat'),
                          _buildControlButton(_showScorecard ? Icons.scoreboard : Icons.scoreboard_outlined, 'Score', onTap: () => setState(() => _showScorecard = !_showScorecard)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Match Scorecard (when enabled)
            if (_showScorecard)
              Expanded(
                flex: 2,
                child: Container(
                  decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Match header
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            children: [
                              const Icon(Icons.sports_cricket, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_matchScore['format'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    Text(_matchScore['venue'], style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Team scores
                        _buildTeamScoreRow(_matchScore['team1']['name'], _matchScore['team1']['score'], _matchScore['team1']['overs'], isWinner: true),
                        _buildTeamScoreRow(_matchScore['team2']['name'], _matchScore['team2']['score'], _matchScore['team2']['overs'], isWinner: false),
                        
                        const SizedBox(height: 16),
                        
                        // Current batsmen
                        const Text('Current Batsmen', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        _buildBatsmanRow(_matchScore['currentBatsman1']['name'], _matchScore['currentBatsman1']['runs'], _matchScore['currentBatsman1']['balls'], _matchScore['currentBatsman1']['fours'], _matchScore['currentBatsman1']['sixes'], isStrike: true),
                        _buildBatsmanRow(_matchScore['currentBatsman2']['name'], _matchScore['currentBatsman2']['runs'], _matchScore['currentBatsman2']['balls'], _matchScore['currentBatsman2']['fours'], _matchScore['currentBatsman2']['sixes'], isStrike: false),
                        
                        const SizedBox(height: 16),
                        
                        // Current bowler
                        const Text('Current Bowler', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        _buildBowlerRow(_matchScore['currentBowler']['name'], _matchScore['currentBowler']['overs'], _matchScore['currentBowler']['runs'], _matchScore['currentBowler']['wickets']),
                        
                        const SizedBox(height: 16),
                        
                        // Last over
                        const Text('Last Over', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(
                          children: (_matchScore['lastOver'] as List).map((ball) => Container(
                            width: 40, height: 40,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: ball == 4 ? Colors.blue : ball == 6 ? Colors.purple : ball == 0 ? Colors.red : Colors.orange,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(child: Text('$ball', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                          )).toList(),
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

  Widget _buildControlButton(IconData icon, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildTeamScoreRow(String name, String score, String overs, {required bool isWinner}) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isWinner ? AppColors.success.withValues(alpha: 0.1) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: isWinner ? Border.all(color: AppColors.success) : null,
      ),
      child: Row(
        children: [
          Expanded(child: Text(name, style: TextStyle(fontWeight: isWinner ? FontWeight.bold : FontWeight.normal))),
          Text(score, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isWinner ? AppColors.success : Colors.black)),
          const SizedBox(width: 8),
          Text('($overs)', style: TextStyle(color: Colors.grey[600])),
          if (isWinner) ...[
            const SizedBox(width: 8),
Container(
  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
  decoration: BoxDecoration(
    color: AppColors.error,
    borderRadius: BorderRadius.circular(4),
  ),
  child: const Row(
    children: [
      Icon(Icons.circle, color: Colors.white, size: 6),
      SizedBox(width: 4),
      Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10)),
    ],
  ),
)          ],
        ],
      ),
    );
  }

  Widget _buildBatsmanRow(String name, int runs, int balls, int fours, int sixes, {required bool isStrike}) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(isStrike ? Icons.sports_cricket : Icons.sports_cricket_outlined, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('$fours fours, $sixes sixes', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$runs', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              Text('$balls balls', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBowlerRow(String name, String overs, int runs, int wickets) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const Icon(Icons.sports_score, color: AppColors.secondary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('$overs overs', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$runs runs', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('$wickets wickets', style: TextStyle(fontSize: 12, color: AppColors.secondary)),
            ],
          ),
        ],
      ),
    );
  }
}
