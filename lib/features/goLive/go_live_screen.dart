import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../providers/auth_provider.dart';
import '../../data/services/live_stream_service.dart';
import '../live_stream/live_player_screen.dart';
import '../../data/models/live_stream_model.dart';
import 'dart:io';

class AppColors {
  static const Color primary = Color(0xFF1E88E5);
  static const Color primaryDark = Color(0xFF1565C0);
  static const Color secondary = Color(0xFFFB8C00);
  static const Color success = Color(0xFF43A047);
  static const Color error = Color(0xFFE53935);
}

class GoLiveScreen extends StatefulWidget {
  const GoLiveScreen({super.key});

  @override
  State<GoLiveScreen> createState() => _GoLiveScreenState();
}

class _GoLiveScreenState extends State<GoLiveScreen>
    with SingleTickerProviderStateMixin {
  
  late TabController _tabController;

  List<LiveStreamModel> _liveStreams = [];
  List<LiveStreamModel> _featuredStreams = [];
  bool _isLoading = true;
  String? _error;
  
  String _selectedLanguage = 'English';
  bool _acceptTerms = false;
  bool _isCreating = false;
  
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _reqCtrl = TextEditingController();
  
  String _streamType = 'mobile';
  String _quality = '720p';
  String _pricing = 'free';
  double _priceAmount = 99;
  bool _isPrivate = false;
  List<String> _lookingFor = [];

  static const _languages = ['English', 'Hindi'];
  
  // Permission status
  bool _hasCameraPermission = false;
  bool _hasMicrophonePermission = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initService();
    _loadStreams();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final cameraStatus = await Permission.camera.status;
    final micStatus = await Permission.microphone.status;
    
    setState(() {
      _hasCameraPermission = cameraStatus.isGranted;
      _hasMicrophonePermission = micStatus.isGranted;
    });
    
    if (!_hasCameraPermission || !_hasMicrophonePermission) {
      _requestPermissions();
    }
  }

  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.microphone,
    ].request();
    
    setState(() {
      _hasCameraPermission = statuses[Permission.camera]?.isGranted ?? false;
      _hasMicrophonePermission = statuses[Permission.microphone]?.isGranted ?? false;
    });
    
    if (!_hasCameraPermission || !_hasMicrophonePermission) {
      _showPermissionDialog();
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Permissions Required'),
        content: const Text('Camera and microphone permissions are required for live streaming. Please grant them in settings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
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
    super.dispose();
  }

  String _t(String en, String hi) =>
      _selectedLanguage == 'Hindi' ? hi : en;

  Future<bool> _checkAuth() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.status != AuthStatus.authenticated) {
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
        title: const Text('Login Required'),
        content: const Text('Please login to access live streams.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Go to Login'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadStreams() async {
    if (!await _checkAuth()) return;
    
    setState(() { 
      _isLoading = true; 
      _error = null; 
    });
    try {
      final live = await LiveStreamService.getLiveStreams(status: 'live');
      final featured = live.take(3).toList();
      setState(() {
        _liveStreams = live;
        _featuredStreams = featured;
        _isLoading = false;
      });
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('401') || errorStr.contains('unauthorized')) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.logout();
        _showAuthDialog();
      } else {
        setState(() { 
          _error = errorStr; 
          _isLoading = false; 
        });
      }
    }
  }

  Future<void> _createStream() async {
    if (!await _checkAuth()) return;
    
    // Check permissions
    if (!_hasCameraPermission || !_hasMicrophonePermission) {
      _showPermissionDialog();
      return;
    }
    
    if (!_acceptTerms) {
      _snack(_t('Please accept Terms & Conditions', 'कृपया नियम स्वीकार करें'), isError: true);
      return;
    }
    if (_titleCtrl.text.trim().isEmpty) {
      _snack(_t('Please enter title', 'शीर्षक दर्ज करें'), isError: true);
      return;
    }

    setState(() => _isCreating = true);
    try {
      final data = {
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        'streamType': _streamType,
        'streamQuality': _quality,
        'isPrivate': _isPrivate,
        'pricing': {
          'type': _pricing,
          'amount': _pricing == 'free' ? 0 : _priceAmount,
          'currency': 'INR',
        },
        'lookingFor': _lookingFor,
        'requirements': _reqCtrl.text.trim().isEmpty ? null : _reqCtrl.text.trim(),
      };

      final stream = await LiveStreamService.createStream(data);
      debugPrint('🎥 Created stream ${stream.id}, starting...');
      await LiveStreamService.startStream(stream.id);
      debugPrint('✅ Stream ${stream.id} started, navigating to player');

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => LivePlayerScreen(
              streamId: stream.id,
              isHost: true,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ GoLive _createStream error: $e');
      String errorMsg = _t('Failed to start stream. Please try again.', 'स्ट्रीम शुरू करने में विफल। पुनः प्रयास करें।');
      
      if (e.toString().contains('401') || e.toString().contains('unauthorized')) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.logout();
        errorMsg = _t('Session expired. Please login again.', 'सत्र समाप्त। कृपया पुनः लॉगिन करें।');
        _showAuthDialog();
      } else if (e.toString().contains('permission')) {
        errorMsg = _t('Camera/Microphone permission denied. Please grant permissions.', 'कैमरा/माइक्रोफोन अनुमति अस्वीकृत। कृपया अनुमति दें।');
        _requestPermissions();
      }
      
      if (mounted) _snack(errorMsg, isError: true);
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
    ));
  }

  void _showLangDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(_t('Select Language', 'भाषा चुनें')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _languages.map((lang) => ListTile(
            leading: Text(lang == 'Hindi' ? '🇮🇳' : '🇺🇸', style: const TextStyle(fontSize: 22)),
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

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.status == AuthStatus.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
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
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (authProvider.status == AuthStatus.authenticated)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.green, size: 16),
                                    SizedBox(width: 4),
                                    Text('Logged In', style: TextStyle(color: Colors.white, fontSize: 12)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                          )
                        else
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Login', style: TextStyle(color: Colors.white)),
                          ),
                        GestureDetector(
                          onTap: _showLangDialog,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_selectedLanguage == 'Hindi' ? '🇮🇳' : '🇺🇸', style: const TextStyle(fontSize: 16)),
                                const SizedBox(width: 6),
                                Text(_selectedLanguage, style: const TextStyle(color: Colors.white, fontSize: 13)),
                                const Icon(Icons.arrow_drop_down, color: Colors.white, size: 18),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Permission warning banner
                  if (!_hasCameraPermission || !_hasMicrophonePermission)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _t('Camera/Microphone permission required', 'कैमरा/माइक्रोफोन अनुमति आवश्यक'),
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                          TextButton(
                            onPressed: _requestPermissions,
                            child: const Text('Grant', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      labelColor: AppColors.primary,
                      unselectedLabelColor: Colors.white,
                      tabs: [
                        Tab(text: _t('🔴 Live Now', '🔴 अभी लाइव')),
                        Tab(text: _t('📺 Go Live', '📺 लाइव करें')),
                        Tab(text: _t('📋 Watch', '📋 देखें')),
                        Tab(text: _t('❓ Help', '❓ सहायता')),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
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
      },
    );
  }

  Widget _buildLiveNowTab() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(_t('Error loading streams', 'स्ट्रीम लोड में त्रुटि'), style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _loadStreams, child: Text(_t('Retry', 'पुनः प्रयास'))),
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
            Text(_t('No live streams', 'कोई लाइव स्ट्रीम नहीं'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
        itemBuilder: (_, i) => _buildStreamCard(all[i], isFeatured: i < _featuredStreams.length),
      ),
    );
  }

  Widget _buildStreamCard(LiveStreamModel stream, {bool isFeatured = false}) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LivePlayerScreen(
            streamId: stream.id,
            isHost: false,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isFeatured ? Border.all(color: AppColors.secondary, width: 2) : null,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 170,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                  ),
                  child: stream.thumbnail != null
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                        child: Image.network(
                          stream.thumbnail!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: Icon(Icons.broken_image, size: 40, color: Colors.grey[400]),
                          ),
                        ),
                      )
                    : Center(child: Icon(Icons.live_tv, size: 56, color: Colors.grey[500])),
                ),
                Positioned(top: 10, left: 10, child: _liveBadge(stream)),
                Positioned(
                  bottom: 10, right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.visibility, color: Colors.white, size: 13),
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
                  Text(stream.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _chip(stream.streamTypeDisplay, AppColors.primary),
                      if (!stream.isFree) ...[
                        const SizedBox(width: 8),
                        _chip(stream.pricing?.displayPrice ?? 'Paid', AppColors.secondary),
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

  Widget _chip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
    child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
  );

  Widget _liveBadge(LiveStreamModel stream) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: stream.isLive ? AppColors.error : Colors.grey, borderRadius: BorderRadius.circular(4)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (stream.isLive) ...[
          Icon(Icons.circle, color: Colors.white, size: 7),
          const SizedBox(width: 4),
        ],
        Text(stream.statusDisplay, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
      ],
    ),
  );

  Widget _buildGoLiveTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Permission Status Indicator
          if (!_hasCameraPermission || !_hasMicrophonePermission)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _t('Camera and microphone permissions needed to go live', 'लाइव जाने के लिए कैमरा और माइक्रोफोन अनुमति आवश्यक'),
                      style: TextStyle(color: Colors.orange.shade800, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          
          _sectionTitle(_t('🎥 Stream Type', 'स्ट्रीम प्रकार')),
          const SizedBox(height: 12),
          _streamTypeCard('mobile', '📱', _t('Mobile Camera', 'मोबाइल कैमरा'), _t('Phone camera', 'फोन कैमरा')),
          _streamTypeCard('professional', '🎬', _t('Professional', 'प्रोफेशनल'), _t('DSLR/External', 'DSLR')),
          
          const SizedBox(height: 24),
          _sectionTitle(_t('📝 Details', 'विवरण')),
          TextField(
            controller: _titleCtrl,
            decoration: InputDecoration(
              labelText: _t('Title *', 'शीर्षक *'),
              hintText: _t('Enter stream title', 'स्ट्रीम का शीर्षक दर्ज करें'),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey[50],
              prefixIcon: const Icon(Icons.title),
            ),
            maxLength: 100,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: _t('Description', 'विवरण'),
              hintText: _t('Tell viewers about your stream', 'दर्शकों को अपने स्ट्रीम के बारे में बताएं'),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey[50],
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 24),
          _sectionTitle(_t('💰 Pricing', 'मूल्य')),
          Row(
            children: [
              Expanded(child: _pricingCard('free', _t('Free', 'मुफ्त'), '₹0')),
              const SizedBox(width: 12),
              Expanded(child: _pricingCard('paid', _t('Paid', 'सशुल्क'), '₹${_priceAmount.toInt()}')),
            ],
          ),
          if (_pricing == 'paid')
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  const Text('Amount: '),
                  Expanded(
                    child: Slider(
                      value: _priceAmount,
                      min: 10,
                      max: 1000,
                      divisions: 99,
                      label: '₹${_priceAmount.toInt()}',
                      onChanged: (v) => setState(() => _priceAmount = v),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('₹${_priceAmount.toInt()}'),
                  ),
                ],
              ),
            ),
          SwitchListTile(
            title: Text(_t('Private Stream', 'प्राइवेट स्ट्रीम')),
            subtitle: Text(_t('Only invited users can join', 'केवल आमंत्रित उपयोगकर्ता जुड़ सकते हैं')),
            value: _isPrivate,
            onChanged: (v) => setState(() => _isPrivate = v),
            activeColor: AppColors.primary,
          ),
          CheckboxListTile(
            title: Text(_t('I accept the Terms & Conditions', 'मैं नियम और शर्तें स्वीकार करता हूं')),
            value: _acceptTerms,
            onChanged: (v) => setState(() => _acceptTerms = v ?? false),
            activeColor: AppColors.success,
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: (_acceptTerms && !_isCreating && _hasCameraPermission && _hasMicrophonePermission) 
                  ? _createStream 
                  : null,
              icon: _isCreating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.live_tv),
              label: Text(
                _isCreating 
                    ? _t('Starting...', 'शुरू हो रहा है') 
                    : _t('Start Live Stream', 'लाइव स्ट्रीम शुरू करें'),
                style: const TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _pricingCard(String value, String title, String price) {
    final selected = _pricing == value;
    final color = value == 'free' ? AppColors.success : AppColors.secondary;
    return GestureDetector(
      onTap: () => setState(() => _pricing = value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.1) : Colors.grey[100],
          border: Border.all(color: selected ? color : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: selected ? color : null)),
            const SizedBox(height: 4),
            Text(price, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: selected ? color : null)),
          ],
        ),
      ),
    );
  }

  Widget _streamTypeCard(String value, String emoji, String title, String subtitle) {
    final selected = _streamType == value;
    return GestureDetector(
      onTap: () => setState(() => _streamType = value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withOpacity(0.08) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppColors.primary : Colors.transparent),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary.withOpacity(0.15) : Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(child: Text(emoji, style: const TextStyle(fontSize: 26))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: selected ? AppColors.primary : null)),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
            Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, color: selected ? AppColors.primary : Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
    text, 
    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
  );

  Widget _buildWatchTab() => _buildLiveNowTab();
  
  Widget _buildHelpTab() => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_t('Need Help?', 'सहायता चाहिए?'), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        _faqItem(
          _t('How to start a live stream?', 'लाइव स्ट्रीम कैसे शुरू करें?'),
          _t('1. Grant camera/microphone permissions\n2. Fill in stream details\n3. Accept terms\n4. Click "Start Live Stream"', 
             '1. कैमरा/माइक्रोफोन अनुमति दें\n2. स्ट्रीम विवरण भरें\n3. नियम स्वीकार करें\n4. "लाइव स्ट्रीम शुरू करें" क्लिक करें'),
        ),
        _faqItem(
          _t('What equipment do I need?', 'क्या उपकरण चाहिए?'),
          _t('• Smartphone with good camera\n• Stable internet (5Mbps+)\n• Good lighting\n• External mic (optional)', 
             '• अच्छे कैमरे वाला स्मार्टफोन\n• स्थिर इंटरनेट (5Mbps+)\n• अच्छी रोशनी\n• बाहरी माइक (वैकल्पिक)'),
        ),
        _faqItem(
          _t('How to earn from streams?', 'स्ट्रीम से कैसे कमाएं?'),
          _t('Set your stream as "Paid" and set the price. Viewers will pay to watch your stream.', 
             'अपनी स्ट्रीम को "सशुल्क" सेट करें और मूल्य निर्धारित करें। दर्शक आपकी स्ट्रीम देखने के लिए भुगतान करेंगे।'),
        ),
        _faqItem(
          _t('Stream quality settings', 'स्ट्रीम गुणवत्ता सेटिंग्स'),
          _t('• 720p - Good for mobile data\n• 1080p - Best for WiFi\n• 4K - Requires very fast internet', 
             '• 720p - मोबाइल डेटा के लिए अच्छा\n• 1080p - WiFi के लिए सर्वश्रेष्ठ\n• 4K - बहुत तेज़ इंटरनेट चाहिए'),
        ),
        _faqItem(
          _t('Having technical issues?', 'तकनीकी समस्या?'),
          _t('Contact support: support@scores11.com\nOr call: +91-XXXXXXXXXX', 
             'सहायता से संपर्क करें: support@scores11.com\nया कॉल करें: +91-XXXXXXXXXX'),
        ),
      ],
    ),
  );

  Widget _faqItem(String q, String a) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    elevation: 1,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: ExpansionTile(
      title: Text(q, style: const TextStyle(fontWeight: FontWeight.w600)),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            a,
            style: TextStyle(color: Colors.grey[700], height: 1.5),
          ),
        ),
      ],
    ),
  );
}