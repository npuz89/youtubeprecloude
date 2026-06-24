import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:audio_session/audio_session.dart';
import '../services/background_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  YoutubePlayerController? _controller;
  final TextEditingController _urlController = TextEditingController();
  bool _isPlayerReady = false;
  bool _isPlaying = false;
  String _statusMessage = 'Введите ссылку YouTube или ID видео';
  bool _backgroundAudioEnabled = false;

  final List<Map<String, String>> _examples = [
    {'title': 'Lofi Hip Hop Radio', 'id': 'jfKfPfyJRdk'},
    {'title': 'Relaxing Piano Music', 'id': '77ZozI0rw7w'},
    {'title': 'Nature Sounds', 'id': 'eKFTSSKCzWA'},
    {'title': 'Study Music', 'id': 'n61ULEU7CO0'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    BackgroundService.init(); // инициализируем сервис при старте
    _initAudioSession();
  }

  Future<void> _initAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.mixWithOthers,
        avAudioSessionMode: AVAudioSessionMode.defaultMode,
        avAudioSessionRouteSharingPolicy:
            AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.music,
          flags: AndroidAudioFlags.none,
          usage: AndroidAudioUsage.media,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: false,
      ));
    } catch (e) {
      debugPrint('Audio session init error: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null) return;
    if (state == AppLifecycleState.resumed && _isPlayerReady) {
      _controller?.play();
    }
  }

  void _loadVideo(String input) {
    String? videoId;
    if (input.contains('youtube.com') || input.contains('youtu.be')) {
      videoId = YoutubePlayer.convertUrlToId(input);
    } else if (input.length == 11) {
      videoId = input;
    }

    if (videoId == null || videoId.isEmpty) {
      setState(() => _statusMessage = '❌ Неверная ссылка. Попробуйте ещё раз.');
      return;
    }

    setState(() {
      _statusMessage = '▶️ Загрузка видео...';
      _isPlayerReady = false;
    });

    _controller?.dispose();
    _controller = YoutubePlayerController(
      initialVideoId: videoId!,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        loop: false,
        useHybridComposition: true,
        enableCaption: false,
      ),
    );
    _controller!.addListener(_playerListener);
    WakelockPlus.enable();
    setState(() {});
  }

  void _playerListener() {
    if (_controller == null) return;
    if (_controller!.value.isReady && !_isPlayerReady) {
      setState(() {
        _isPlayerReady = true;
        _statusMessage = '✅ Видео загружено';
        _isPlaying = true;
      });
    }
    if (_controller!.value.hasPlayed) {
      setState(() => _isPlaying = _controller!.value.isPlaying);
    }
  }

  void _toggleBackgroundMode() async {
    if (!_backgroundAudioEnabled) {
      final success = await BackgroundService.enableBackground();
      setState(() {
        _backgroundAudioEnabled = success;
        _statusMessage = success
            ? '🔊 Фоновый режим ВКЛЮЧЁН — звук продолжится при блокировке'
            : '⚠️ Не удалось включить фоновый режим';
      });
    } else {
      await BackgroundService.disableBackground();
      setState(() {
        _backgroundAudioEnabled = false;
        _statusMessage = '🔇 Фоновый режим ВЫКЛЮЧЕН';
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Row(children: [
          Icon(Icons.play_circle_filled, color: Color(0xFFFF0000), size: 28),
          SizedBox(width: 8),
          Text('YT Background',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        ]),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: _toggleBackgroundMode,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _backgroundAudioEnabled
                      ? const Color(0xFFFF0000)
                      : const Color(0xFF333333),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(children: [
                  Icon(
                    _backgroundAudioEnabled ? Icons.music_note : Icons.music_off,
                    color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(_backgroundAudioEnabled ? 'ВКЛ' : 'ВЫКЛ',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ]),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_controller != null) _buildPlayer(),
            _buildUrlInput(),
            _buildStatus(),
            _buildBackgroundInfo(),
            _buildExamples(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayer() {
    return Container(
      color: Colors.black,
      child: YoutubePlayer(
        controller: _controller!,
        showVideoProgressIndicator: true,
        progressIndicatorColor: const Color(0xFFFF0000),
        progressColors: const ProgressBarColors(
          playedColor: Color(0xFFFF0000),
          handleColor: Color(0xFFFF0000),
        ),
        onReady: () => setState(() => _isPlayerReady = true),
      ),
    );
  }

  Widget _buildUrlInput() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Вставьте ссылку YouTube',
            style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _urlController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'https://youtube.com/watch?v=... или ID',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFFF0000), width: 1.5)),
                prefixIcon: const Icon(Icons.link, color: Colors.white38),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onSubmitted: (val) => _loadVideo(val.trim()),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _loadVideo(_urlController.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF0000),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Icon(Icons.play_arrow, size: 24),
          ),
        ]),
      ]),
    );
  }

  Widget _buildStatus() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          const Icon(Icons.info_outline, color: Colors.white38, size: 16),
          const SizedBox(width: 8),
          Expanded(
              child: Text(_statusMessage,
                  style: const TextStyle(color: Colors.white60, fontSize: 13))),
        ]),
      ),
    );
  }

  Widget _buildBackgroundInfo() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _backgroundAudioEnabled ? const Color(0xFF1A0A0A) : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _backgroundAudioEnabled
                ? const Color(0xFFFF0000).withOpacity(0.5)
                : Colors.transparent,
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.lock_open,
                color: _backgroundAudioEnabled ? const Color(0xFFFF0000) : Colors.white54,
                size: 18),
            const SizedBox(width: 8),
            Text('Фоновое воспроизведение',
                style: TextStyle(
                    color: _backgroundAudioEnabled ? Colors.white : Colors.white70,
                    fontWeight: FontWeight.w600, fontSize: 14)),
          ]),
          const SizedBox(height: 8),
          const Text(
            '1. Нажмите кнопку "ВЫКЛ" вверху справа\n'
            '2. Запустите видео\n'
            '3. Заблокируйте экран — звук продолжит играть\n'
            '4. Управляйте через шторку уведомлений',
            style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.6),
          ),
        ]),
      ),
    );
  }

  Widget _buildExamples() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Попробуйте эти видео',
            style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        ...(_examples.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () {
                  _urlController.text = e['id']!;
                  _loadVideo(e['id']!);
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(10)),
                  child: Row(children: [
                    const Icon(Icons.play_circle_outline,
                        color: Color(0xFFFF0000), size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(e['title']!,
                            style: const TextStyle(color: Colors.white, fontSize: 14))),
                    Text(e['id']!,
                        style: const TextStyle(
                            color: Colors.white30, fontSize: 11, fontFamily: 'monospace')),
                  ]),
                ),
              ),
            ))),
      ]),
    );
  }
}
