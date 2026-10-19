import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:haishin_kit/haishin_kit.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/utils/friendly_error.dart';
import '../../data/models/live_stream_model.dart';
import '../../data/services/live_stream_service.dart';
import '../../data/services/match_service.dart';
import 'score_overlay.dart';

enum _Phase { preparing, ready, connecting, live, reconnecting, ended, failed }

/// Broadcasts the phone camera to the stream's RTMP server (YouTube, or the
/// Scores11 RTMP server) with the match score burned into the video, like a
/// TV broadcast. Viewers watch it in the app above the live scorecard.
class LiveBroadcastScreen extends StatefulWidget {
  final LiveStreamModel stream;
  // From GET /live-streams/:id/ingest when resuming (public stream reads
  // never include the key).
  final String? rtmpUrl;
  final String? streamKey;

  const LiveBroadcastScreen({super.key, required this.stream, this.rtmpUrl, this.streamKey});

  @override
  State<LiveBroadcastScreen> createState() => _LiveBroadcastScreenState();
}

class _Quality {
  final String label;
  final int width;
  final int height;
  final int bitrate;
  const _Quality(this.label, this.width, this.height, this.bitrate);
}

// YouTube's recommended bitrates for 30 fps.
const _qualities = [
  _Quality('480p', 854, 480, 1200 * 1000),
  _Quality('720p', 1280, 720, 2500 * 1000),
  _Quality('1080p', 1920, 1080, 4500 * 1000),
];

class _LiveBroadcastScreenState extends State<LiveBroadcastScreen>
    with WidgetsBindingObserver {
  final MatchService _matchService = MatchService();

  MediaMixer? _mixer;
  StreamSession? _session;
  StreamSubscription<StreamSessionReadyState>? _stateSub;
  ImageScreenObject? _scoreImage;

  List<VideoSource> _cameras = const [];
  bool _usingFront = false;
  bool _muted = false;
  bool _showScore = true;
  _Quality _quality = _qualities[1];

  _Phase _phase = _Phase.preparing;
  String? _error;
  bool _wantLive = false;
  bool _markedLive = false;
  bool _ending = false;
  int _reconnectAttempt = 0;
  Timer? _reconnectTimer;

  DateTime? _liveSince;
  DateTime? _endedAt;
  Timer? _clock;
  Timer? _scoreTimer;
  Timer? _healthTimer;
  String _lastScoreSignature = '';
  ScoreOverlayData? _score;
  String _ytHealth = '';
  String _ytStreamStatus = '';
  int _viewers = 0;

  String get _server => (widget.rtmpUrl ?? widget.stream.rtmpUrl ?? '').trim().replaceAll(RegExp(r'/+$'), '');
  String get _key => (widget.streamKey ?? widget.stream.streamKey).trim();
  String get _rtmpTarget => '$_server/$_key';

  bool get _isYoutube => widget.stream.youtubeBroadcastId != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WakelockPlus.enable().catchError((_) {});
    _prepare();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _reconnectTimer?.cancel();
    _clock?.cancel();
    _scoreTimer?.cancel();
    _healthTimer?.cancel();
    _stateSub?.cancel();
    if (_wantLive && !_ending) {
      // Left without pressing End (e.g. system back): stop cleanly.
      LiveStreamService.endStream(widget.stream.id).catchError((_) {});
    }
    _session?.close().catchError((_) {});
    _session?.dispose().catchError((_) {});
    _mixer?.dispose().catchError((_) {});
    WakelockPlus.disable().catchError((_) {});
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && _wantLive && mounted) {
      // Android stops the camera in the background; viewers see a frozen
      // picture until the host comes back.
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Keep Scores11 open while you are live, or the video will pause.'),
      ));
    }
  }

  // ── Setup ─────────────────────────────────────────────────────────────────
  Future<void> _prepare() async {
    if (_key.isEmpty || _server.isEmpty) {
      _fail('This stream has no RTMP server or key. Create the live stream again.');
      return;
    }
    final camera = await Permission.camera.request();
    final mic = await Permission.microphone.request();
    if (!camera.isGranted || !mic.isGranted) {
      _fail('Allow Camera and Microphone access to go live.', permission: true);
      return;
    }

    try {
      _cameras = await _loadCameras();
      final mixer = await MediaMixer.create();
      await mixer.attachAudio(0, AudioSource());
      await mixer.attachVideo(0, _camera(front: false));
      mixer.screen?.size = ScreenObjectSize(width: _quality.width, height: _quality.height);
      await mixer.startRunning();

      final session = await StreamSession.create(_rtmpTarget, StreamSessionMode.publish);
      _applyQuality(session);
      _stateSub = session.readyState.listen(_onReadyState);

      if (!mounted) return;
      setState(() {
        _mixer = mixer;
        _session = session;
        _phase = _Phase.ready;
      });
      await _setupScoreOverlay();
    } catch (e) {
      debugPrint('Broadcast setup failed: $e');
      _fail('Could not start the camera. Close other camera apps and try again.');
    }
  }

  Future<List<VideoSource>> _loadCameras() async {
    try {
      final list = await HaishinKitPlatformInterface.instance.videoSources;
      if (list.isNotEmpty) return list;
    } catch (e) {
      debugPrint('Camera list unavailable, using default ids: $e');
    }
    // Camera ids 0 (back) and 1 (front) exist on practically every phone.
    return const [
      VideoSource(id: '0', position: CameraPosition.back),
      VideoSource(id: '1', position: CameraPosition.front),
    ];
  }

  VideoSource _camera({required bool front}) {
    final wanted = front ? CameraPosition.front : CameraPosition.back;
    return _cameras.firstWhere(
      (c) => c.position == wanted,
      orElse: () => _cameras.length > 1 && front ? _cameras[1] : _cameras.first,
    );
  }

  void _applyQuality(StreamSession session) {
    session.videoSettings = VideoCodecSettings(
      width: _quality.width,
      height: _quality.height,
      bitrate: _quality.bitrate,
      frameInterval: 2, // YouTube asks for a keyframe every 2 seconds
      profileLevel: ProfileLevel.h264MainAutoLevel,
    );
    session.audioSettings = AudioCodecSettings(bitrate: 128 * 1000);
  }

  void _fail(String message, {bool permission = false}) {
    if (!mounted) return;
    setState(() {
      _phase = _Phase.failed;
      _error = message;
      _permissionProblem = permission;
    });
  }

  bool _permissionProblem = false;

  // ── Score overlay ─────────────────────────────────────────────────────────
  Future<void> _setupScoreOverlay() async {
    final matchId = widget.stream.matchId;
    if (matchId == null || matchId.isEmpty) return;
    await _refreshScore();
    _scoreTimer = Timer.periodic(const Duration(seconds: 5), (_) => _refreshScore());
  }

  Future<void> _refreshScore() async {
    final matchId = widget.stream.matchId;
    final screen = _mixer?.screen;
    if (matchId == null || matchId.isEmpty || screen == null) return;
    try {
      final live = await _matchService.getLiveScore(matchId);
      final data = ScoreOverlayData.fromLive(Map<String, dynamic>.from(live));
      if (data == null || !mounted) return;
      setState(() => _score = data);
      if (data.signature == _lastScoreSignature && _scoreImage != null) return;
      _lastScoreSignature = data.signature;

      final width = _quality.width.toDouble();
      final png = await data.renderPng(width: 1280);
      final scale = width / 1280;
      var image = _scoreImage;
      if (image == null) {
        image = ImageScreenObject();
        // Size is only applied when the object is first added.
        image.size = ScreenObjectSize(width: width.round(), height: (96 * scale).round());
        image.verticalAlignment = VerticalAlignment.bottom;
        image.horizontalAlignment = HorizontalAlignment.center;
        image.layoutMargin = ScreenObjectEdgeInsets(
            top: 0, left: 0, bottom: (18 * scale).round(), right: 0);
        image.isVisible = _showScore;
        image.setImage(ImageScreenObjectFormat.png, png.buffer);
        screen.addChild(image);
        _scoreImage = image;
      } else {
        image.setImage(ImageScreenObjectFormat.png, png.buffer);
      }
    } catch (e) {
      debugPrint('Score overlay refresh skipped: $e');
    }
  }

  void _toggleScore() {
    setState(() => _showScore = !_showScore);
    _scoreImage?.isVisible = _showScore;
  }

  // ── Going live ────────────────────────────────────────────────────────────
  Future<void> _goLive() async {
    if (_session == null) return;
    setState(() {
      _wantLive = true;
      _phase = _Phase.connecting;
      _error = null;
    });
    await _connect();
  }

  Future<void> _connect() async {
    final session = _session;
    if (session == null || !_wantLive) return;
    try {
      await session.connect();
    } on StreamSessionException catch (e) {
      debugPrint('RTMP connect failed: ${e.message}');
      _scheduleReconnect();
    } catch (e) {
      debugPrint('RTMP connect error: $e');
      _scheduleReconnect();
    }
  }

  void _onReadyState(StreamSessionReadyState state) {
    if (!mounted) return;
    switch (state) {
      case StreamSessionReadyState.open:
        _reconnectAttempt = 0;
        _reconnectTimer?.cancel();
        setState(() => _phase = _Phase.live);
        _onFirstLive();
        break;
      case StreamSessionReadyState.connecting:
        if (_phase != _Phase.live) {
          setState(() => _phase = _markedLive ? _Phase.reconnecting : _Phase.connecting);
        }
        break;
      case StreamSessionReadyState.closing:
        break;
      case StreamSessionReadyState.closed:
        if (_wantLive && !_ending) {
          // Network dropped: keep the broadcast and keep trying.
          setState(() => _phase = _markedLive ? _Phase.reconnecting : _Phase.connecting);
          _scheduleReconnect();
        }
        break;
    }
  }

  void _scheduleReconnect() {
    if (!_wantLive || _ending || !mounted) return;
    _reconnectTimer?.cancel();
    _reconnectAttempt += 1;
    final delay = Duration(seconds: (_reconnectAttempt * 2).clamp(2, 10));
    setState(() => _phase = _markedLive ? _Phase.reconnecting : _Phase.connecting);
    _reconnectTimer = Timer(delay, _connect);
  }

  Future<void> _onFirstLive() async {
    if (_markedLive) return;
    _markedLive = true;
    _liveSince = DateTime.now();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    try {
      // Shows the WATCH LIVE banner on the match for everyone.
      await LiveStreamService.startStream(widget.stream.id);
    } catch (e) {
      debugPrint('Mark live failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(friendlyError(e, fallback: 'Video is streaming, but Scores11 could not list it yet.')),
        ));
      }
    }
    // 2 YouTube quota units per check, so once a minute.
    _healthTimer = Timer.periodic(const Duration(seconds: 60), (_) => _refreshHealth());
    _refreshHealth();
  }

  Future<void> _refreshHealth() async {
    try {
      final latest = await LiveStreamService.getStream(widget.stream.id);
      if (mounted) setState(() => _viewers = latest.viewerCount);
    } catch (_) {}
    if (!_isYoutube) return;
    try {
      final health = await LiveStreamService.getStreamHealth(widget.stream.id);
      if (!mounted) return;
      setState(() {
        _ytHealth = health['health']?.toString() ?? '';
        _ytStreamStatus = health['streamStatus']?.toString() ?? '';
      });
    } catch (e) {
      debugPrint('YouTube health skipped: $e');
    }
  }

  Future<void> _end() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End live stream?'),
        content: const Text(
            'The broadcast stops for everyone. The full recording is added to this match\'s highlights.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep live')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('End stream'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _stop();
  }

  Future<void> _stop() async {
    setState(() => _ending = true);
    _wantLive = false;
    _endedAt = DateTime.now();
    _reconnectTimer?.cancel();
    _healthTimer?.cancel();
    _clock?.cancel();
    try {
      await _session?.close();
    } catch (_) {}
    try {
      await LiveStreamService.endStream(widget.stream.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(friendlyError(e, fallback: 'Video stopped. Could not update the stream status.')),
        ));
      }
    }
    if (mounted) setState(() => _phase = _Phase.ended);
  }

  Future<bool> _confirmLeave() async {
    if (!_wantLive) {
      // Never went live: drop the unused broadcast.
      if (_phase != _Phase.ended) {
        LiveStreamService.endStream(widget.stream.id).catchError((_) {});
      }
      _ending = true;
      return true;
    }
    await _end();
    return _phase == _Phase.ended;
  }

  // ── Controls ──────────────────────────────────────────────────────────────
  Future<void> _flipCamera() async {
    final mixer = _mixer;
    if (mixer == null || _cameras.length < 2) return;
    final front = !_usingFront;
    try {
      await mixer.attachVideo(0, _camera(front: front));
      setState(() => _usingFront = front);
    } catch (e) {
      debugPrint('Flip camera failed: $e');
    }
  }

  void _toggleMute() {
    final mixer = _mixer;
    if (mixer == null) return;
    final muted = !_muted;
    mixer.audioMixerSettings = AudioMixerSettings(isMuted: muted);
    setState(() => _muted = muted);
  }

  void _pickQuality() async {
    final picked = await showModalBottomSheet<_Quality>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text('Video quality', style: TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text('Use 480p on slow mobile data, 720p on 4G/Wi-Fi.'),
            ),
            ..._qualities.map((q) => ListTile(
                  leading: Icon(q == _quality ? Icons.radio_button_checked : Icons.radio_button_off),
                  title: Text(q.label),
                  subtitle: Text('${(q.bitrate / 1000000).toStringAsFixed(1)} Mbps upload'),
                  onTap: () => Navigator.pop(ctx, q),
                )),
          ],
        ),
      ),
    );
    if (picked == null || picked == _quality || _session == null) return;
    setState(() => _quality = picked);
    _mixer?.screen?.size = ScreenObjectSize(width: picked.width, height: picked.height);
    _applyQuality(_session!);
    // The score image keeps its first size, so rebuild it for the new frame.
    final old = _scoreImage;
    if (old != null) {
      _mixer?.screen?.removeChild(old);
      _scoreImage = null;
      _lastScoreSignature = '';
      _refreshScore();
    }
  }

  void _shareLink() {
    final url = widget.stream.youtubeUrl;
    final text = url != null && url.isNotEmpty
        ? 'Watch ${widget.stream.title} live: $url'
        : 'Watch ${widget.stream.title} live on Scores11';
    Share.share(text);
  }

  // ── UI ────────────────────────────────────────────────────────────────────
  String get _elapsed {
    final since = _liveSince;
    if (since == null) return '00:00';
    final d = (_endedAt ?? DateTime.now()).difference(since);
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await _confirmLeave();
        if (leave && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (_session != null && _phase != _Phase.ended)
              StreamSessionViewTexture(_session, key: ValueKey(_session!.memory))
            else
              const ColoredBox(color: Colors.black),
            if (_phase == _Phase.preparing) _centerNote(loader: true, title: 'Starting camera…'),
            if (_phase == _Phase.failed) _failedView(),
            if (_phase == _Phase.ended) _endedView(),
            if (_phase != _Phase.failed && _phase != _Phase.ended && _phase != _Phase.preparing) ...[
              _topBar(),
              _sideControls(),
              _bottomBar(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    return Positioned(
      top: 12,
      left: 12,
      right: 90,
      child: Row(
        children: [
          _roundButton(Icons.close_rounded, () async {
            final leave = await _confirmLeave();
            if (leave && mounted) Navigator.of(context).pop();
          }),
          const SizedBox(width: 10),
          _statusChip(),
          const SizedBox(width: 8),
          if (_markedLive) _chip(Icons.visibility_rounded, '$_viewers'),
          if (_isYoutube && _ytHealth.isNotEmpty) ...[
            const SizedBox(width: 8),
            _healthChip(),
          ],
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.stream.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, shadows: [
                Shadow(blurRadius: 6, color: Colors.black),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip() {
    late final Color color;
    late final String label;
    switch (_phase) {
      case _Phase.live:
        color = Colors.redAccent;
        label = 'LIVE  $_elapsed';
        break;
      case _Phase.connecting:
        color = Colors.orange;
        label = 'CONNECTING…';
        break;
      case _Phase.reconnecting:
        color = Colors.orange;
        label = 'RECONNECTING…';
        break;
      default:
        color = Colors.white24;
        label = 'PREVIEW';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: Text(label,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.6)),
    );
  }

  Widget _healthChip() {
    final inactive = _ytStreamStatus == 'inactive';
    final label = inactive
        ? 'YouTube: waiting'
        : 'YouTube: ${_ytHealth == 'noData' ? 'starting' : _ytHealth}';
    final color = inactive || _ytHealth == 'noData'
        ? Colors.white24
        : _ytHealth == 'bad'
            ? Colors.redAccent
            : _ytHealth == 'ok'
                ? Colors.orange
                : Colors.green;
    return _chip(Icons.smart_display_rounded, label, color: color);
  }

  Widget _chip(IconData icon, String text, {Color color = Colors.black54}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: Colors.white, size: 14),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _sideControls() {
    final hasMatch = (widget.stream.matchId ?? '').isNotEmpty;
    return Positioned(
      right: 14,
      top: 12,
      bottom: 12,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _roundButton(_muted ? Icons.mic_off_rounded : Icons.mic_rounded, _toggleMute,
              active: _muted, tooltip: _muted ? 'Unmute' : 'Mute'),
          const SizedBox(height: 12),
          _roundButton(Icons.cameraswitch_rounded, _flipCamera, tooltip: 'Switch camera'),
          if (hasMatch) ...[
            const SizedBox(height: 12),
            _roundButton(Icons.scoreboard_rounded, _toggleScore,
                active: !_showScore, tooltip: _showScore ? 'Hide score on video' : 'Show score on video'),
          ],
          const SizedBox(height: 12),
          _roundButton(Icons.share_rounded, _shareLink, tooltip: 'Share'),
          if (!_wantLive) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickQuality,
              child: Container(
                width: 52,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                child: Text(_quality.label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _bottomBar() {
    final score = _score;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_wantLive)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10)),
              child: Text(
                score == null
                    ? 'Hold the phone sideways. Tap Go Live when ready.'
                    : 'Score bar is added to the video automatically. Tap Go Live when ready.',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          _wantLive
              ? ElevatedButton.icon(
                  onPressed: _ending ? null : _end,
                  icon: const Icon(Icons.stop_rounded),
                  label: Text(_ending ? 'Ending…' : 'End live'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                  ),
                )
              : ElevatedButton.icon(
                  onPressed: _session == null ? null : _goLive,
                  icon: const Icon(Icons.sensors_rounded),
                  label: const Text('Go Live'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 14),
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _roundButton(IconData icon, VoidCallback onTap, {bool active = false, String? tooltip}) {
    final button = Material(
      color: active ? Colors.redAccent : Colors.black54,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: 46, height: 46, child: Icon(icon, color: Colors.white, size: 22)),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip, child: button);
  }

  Widget _centerNote({required String title, String? message, bool loader = false, List<Widget> actions = const []}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loader) const CircularProgressIndicator(color: Colors.white),
            if (loader) const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
            ],
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(spacing: 12, children: actions),
            ],
          ],
        ),
      ),
    );
  }

  Widget _failedView() {
    return _centerNote(
      title: 'Could not start live',
      message: _error,
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).maybePop(),
          style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
          child: const Text('Back'),
        ),
        if (_permissionProblem)
          ElevatedButton(onPressed: openAppSettings, child: const Text('Open settings'))
        else
          ElevatedButton(
            onPressed: () {
              setState(() {
                _phase = _Phase.preparing;
                _error = null;
              });
              _prepare();
            },
            child: const Text('Try again'),
          ),
      ],
    );
  }

  Widget _endedView() {
    return _centerNote(
      title: 'Live stream ended',
      message: _liveSince == null
          ? 'The stream did not go live.'
          : 'You were live for $_elapsed. The recording will appear in this match\'s highlights.',
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
