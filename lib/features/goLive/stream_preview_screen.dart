import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';

import '../../data/services/live_stream_service.dart';
import '../../data/models/live_stream_model.dart';
import '../../features/live_stream/live_player_screen.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const _black       = Color(0xFF000000);
const _dark1       = Color(0xFF0D0D0D);
const _dark2       = Color(0xFF141414);
const _dark3       = Color(0xFF1C1C1E);
const _dark4       = Color(0xFF242428);
const _border      = Color(0xFF2A2A2E);
const _white       = Color(0xFFFFFFFF);
const _white70     = Color(0xB3FFFFFF);
const _white40     = Color(0x66FFFFFF);
const _white15     = Color(0x26FFFFFF);
const _red         = Color(0xFFE53935);
const _redBg       = Color(0x1AE53935);
const _redBorder   = Color(0x40E53935);
const _green       = Color(0xFF22C55E);
const _greenBg     = Color(0x1A22C55E);
const _blue        = Color(0xFF3B82F6);
const _blueBg      = Color(0x1A3B82F6);
const _muted       = Color(0xFF6B6B70);

class StreamPreviewScreen extends StatefulWidget {
  final LiveStreamModel stream;

  const StreamPreviewScreen({
    super.key,
    required this.stream,
  });

  @override
  State<StreamPreviewScreen> createState() => _StreamPreviewScreenState();
}

class _StreamPreviewScreenState extends State<StreamPreviewScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {

  bool _cameraReady   = false;
  bool _isStreaming   = false;
  bool _isMuted       = false;
  bool _isFrontCamera = false;
  bool _showKey       = false;

  String _rtmpUrl    = '';
  String _streamKey  = '';
  int    _duration   = 0; // seconds since stream started

  CameraController?       _cameraController;
  List<CameraDescription>? _cameras;

  // Live pulse animation
  AnimationController? _pulseCtrl;
  Animation<double>?   _pulseAnim;

  // Stream duration timer
  DateTime? _streamStart;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl!, curve: Curves.easeInOut),
    );

    _initializeCameraAndStream();
  }

  // ── Init camera + auto start stream ─────────────────────────────────────────
  Future<void> _initializeCameraAndStream() async {
    try {
      _rtmpUrl   = LiveStreamService.zenstreamRtmpServer;
      _streamKey = widget.stream.streamKey;

      _cameras = await availableCameras();
      await _setupCamera(_isFrontCamera ? 1 : 0);
      await _startStreaming();
    } catch (e) {
      debugPrint('Init error: $e');
    }
  }

  Future<void> _setupCamera(int index) async {
    if (_cameras == null || _cameras!.isEmpty) return;
    final camIndex = index.clamp(0, _cameras!.length - 1);

    await _cameraController?.dispose();
    _cameraController = CameraController(
      _cameras![camIndex],
      ResolutionPreset.high,
      enableAudio: !_isMuted,
    );

    await _cameraController!.initialize();
    if (mounted) setState(() => _cameraReady = true);
  }

  // ── Start stream ─────────────────────────────────────────────────────────────
  Future<void> _startStreaming() async {
    setState(() => _isStreaming = true);
    _streamStart = DateTime.now();
    _tickDuration();

    try {
      await LiveStreamService.startStream(widget.stream.id);
      if (mounted) _showSnack('🎥 Stream is live!', _green);
    } catch (e) {
      setState(() => _isStreaming = false);
      if (mounted) _showSnack('Stream failed: $e', _red);
    }
  }

  // ── Stop stream ──────────────────────────────────────────────────────────────
  Future<void> _stopStreaming() async {
    try {
      await _cameraController?.dispose();
      _cameraController = null;
      setState(() {
        _isStreaming  = false;
        _cameraReady  = false;
        _streamStart  = null;
        _duration     = 0;
      });
      if (mounted) _showSnack('Stream ended', _muted);
    } catch (e) {
      debugPrint('Stop error: $e');
    }
  }

  // ── Toggle mute ──────────────────────────────────────────────────────────────
  Future<void> _toggleMute() async {
    setState(() => _isMuted = !_isMuted);
    await _setupCamera(_isFrontCamera ? 1 : 0);
  }

  // ── Flip camera ──────────────────────────────────────────────────────────────
  Future<void> _flipCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;
    setState(() {
      _isFrontCamera = !_isFrontCamera;
      _cameraReady   = false;
    });
    await _setupCamera(_isFrontCamera ? 1 : 0);
  }

  // ── Duration ticker ──────────────────────────────────────────────────────────
  void _tickDuration() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted || !_isStreaming) return;
      setState(() => _duration++);
      _tickDuration();
    });
  }

  String get _durationLabel {
    final h = _duration ~/ 3600;
    final m = (_duration % 3600) ~/ 60;
    final s = _duration % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: const TextStyle(color: _white, fontWeight: FontWeight.w500)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    _showSnack('$label copied', _blue);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulseCtrl?.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCameraAndStream();
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final mq       = MediaQuery.of(context);
    final sw       = mq.size.width;
    final sh       = mq.size.height;
    final isTablet = sw > 600;

    // Responsive camera height
    final camH = isTablet ? sh * 0.45 : sh * 0.38;
    final hPad = isTablet ? sw * 0.08 : 16.0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _black,
        body: SafeArea(
          child: Column(
            children: [
              // ── TOP BAR ───────────────────────────────────────────────
              _buildTopBar(hPad),

              // ── CAMERA PREVIEW ────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: hPad, vertical: 12),
                    child: Column(
                      children: [
                        // Camera
                        _buildCameraPreview(camH),
                        const SizedBox(height: 16),

                        // Camera controls (mute / flip)
                        _buildCameraControls(),
                        const SizedBox(height: 16),

                        // Stream info card
                        _buildStreamInfoCard(),
                        const SizedBox(height: 20),

                        // Stop button
                        _buildStopButton(),
                        const SizedBox(height: 12),
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

  // ── Top bar ──────────────────────────────────────────────────────────────────
  Widget _buildTopBar(double hPad) {
    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 4),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _white15,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _border, width: 0.8),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: _white, size: 16),
            ),
          ),
          const SizedBox(width: 12),

          // Title + status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.stream.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _white,
                    letterSpacing: 0.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    // Live pulse dot
                    if (_isStreaming) ...[
                      AnimatedBuilder(
                        animation:
                            _pulseAnim ?? const AlwaysStoppedAnimation(1.0),
                        builder: (_, __) => Opacity(
                          opacity:
                              (_pulseAnim ?? const AlwaysStoppedAnimation(1.0))
                                  .value,
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: _red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text('LIVE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _red,
                            letterSpacing: 1.2,
                          )),
                      const SizedBox(width: 8),
                      Text(
                        _durationLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          color: _white40,
                          fontWeight: FontWeight.w500,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ] else ...[
                      const Text('Preparing…',
                          style: TextStyle(fontSize: 12, color: _muted)),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Live badge pill
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: _isStreaming ? _redBg : _dark3,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isStreaming ? _redBorder : _border,
                width: 0.8,
              ),
            ),
            child: Text(
              _isStreaming ? '● LIVE' : '○ OFFLINE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _isStreaming ? _red : _muted,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Camera preview ───────────────────────────────────────────────────────────
  Widget _buildCameraPreview(double height) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: _dark3,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isStreaming ? _redBorder : _border,
          width: _isStreaming ? 1.5 : 0.8,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Camera feed or loader
            if (_cameraReady && _cameraController != null)
              CameraPreview(_cameraController!)
            else
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        color: _isStreaming ? _red : _blue,
                        strokeWidth: 2.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _isStreaming
                          ? 'Starting camera…'
                          : 'Initializing…',
                      style: const TextStyle(
                          color: _white40,
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),

            // Live indicator overlay (top-left)
            if (_isStreaming)
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _red.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.fiber_manual_record,
                          color: _white, size: 9),
                      SizedBox(width: 4),
                      Text('LIVE',
                          style: TextStyle(
                            color: _white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          )),
                    ],
                  ),
                ),
              ),

            // Muted overlay (top-right)
            if (_isMuted)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.mic_off_rounded,
                      color: _white, size: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Camera controls (mute / flip) ────────────────────────────────────────────
  Widget _buildCameraControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _controlBtn(
          icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
          label: _isMuted ? 'Unmute' : 'Mute',
          active: _isMuted,
          activeColor: _red,
          onTap: _toggleMute,
        ),
        const SizedBox(width: 16),
        _controlBtn(
          icon: Icons.flip_camera_ios_rounded,
          label: 'Flip',
          active: false,
          activeColor: _blue,
          onTap: _cameras != null && _cameras!.length > 1
              ? _flipCamera
              : null,
        ),
      ],
    );
  }

  Widget _controlBtn({
    required IconData icon,
    required String label,
    required bool active,
    required Color activeColor,
    VoidCallback? onTap,
  }) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: active ? activeColor.withOpacity(0.15) : _dark3,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? activeColor.withOpacity(0.5) : _border,
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 18,
                color: !enabled
                    ? _muted
                    : active
                        ? activeColor
                        : _white70),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: !enabled
                    ? _muted
                    : active
                        ? activeColor
                        : _white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Stream info card ─────────────────────────────────────────────────────────
  Widget _buildStreamInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: _dark2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border, width: 0.8),
      ),
      child: Column(
        children: [
          // Card header
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _blueBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.settings_input_antenna_rounded,
                      color: _blue, size: 14),
                ),
                const SizedBox(width: 10),
                const Text('Stream Configuration',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: _white,
                    )),
              ],
            ),
          ),
          Divider(height: 1, color: _border),

          // RTMP URL
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoField(
                  label: 'RTMP Server URL',
                  value: _rtmpUrl,
                  icon: Icons.link_rounded,
                  iconColor: _blue,
                  obscure: false,
                ),
                const SizedBox(height: 12),
                _buildInfoField(
                  label: 'Stream Key',
                  value: _streamKey,
                  icon: Icons.vpn_key_rounded,
                  iconColor: _green,
                  obscure: !_showKey,
                  trailing: GestureDetector(
                    onTap: () => setState(() => _showKey = !_showKey),
                    child: Icon(
                      _showKey
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      size: 16,
                      color: _muted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoField({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    required bool obscure,
    Widget? trailing,
  }) {
    final display = obscure
        ? '•' * (value.length.clamp(8, 24))
        : value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label row
        Row(
          children: [
            Icon(icon, size: 13, color: iconColor),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _muted,
                  letterSpacing: 0.4,
                )),
          ],
        ),
        const SizedBox(height: 6),

        // Value box
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _dark4,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _border, width: 0.8),
          ),
          child: Row(
            children: [
              Expanded(
                child: SelectableText(
                  display,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: obscure ? _muted : _white70,
                    fontFamily: 'monospace',
                    letterSpacing: obscure ? 2 : 0.2,
                  ),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing,
              ],
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _copyToClipboard(value, label),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _white15,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Icon(Icons.copy_rounded,
                      size: 14, color: _white70),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Stop button ──────────────────────────────────────────────────────────────
  Widget _buildStopButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _isStreaming ? _red : _dark3,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isStreaming ? _red : _border,
            width: 0.8,
          ),
          boxShadow: _isStreaming
              ? [
                  BoxShadow(
                    color: _red.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  )
                ]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: _isStreaming ? _stopStreaming : null,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.stop_circle_rounded,
                  color: _isStreaming ? _white : _muted,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  _isStreaming ? 'Stop Stream' : 'Stream Offline',
                  style: TextStyle(
                    color: _isStreaming ? _white : _muted,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}