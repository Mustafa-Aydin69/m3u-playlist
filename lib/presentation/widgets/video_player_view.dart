import 'dart:async';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class VideoPlayerView extends StatefulWidget {
  final String url;
  
  const VideoPlayerView({Key? key, required this.url}) : super(key: key);

  @override
  State<VideoPlayerView> createState() => _VideoPlayerViewState();
}

class _VideoPlayerViewState extends State<VideoPlayerView> {
  // Oynatıcı nesnesi
  late final player = Player();
  // Video render kontrolcüsü
  late final controller = VideoController(
    player, 
    configuration: const VideoControllerConfiguration(
      enableHardwareAcceleration: false, // Ekran kartı HW çökmesini önler
    )
  );

  double _volume = 100.0;
  double _brightnessUi = 1.0; // 1.0 tam parlaklık, 0.0 zifiri karanlık
  
  bool _showIndicator = false;
  String _indicatorText = "";
  IconData _indicatorIcon = Icons.volume_up;
  Timer? _indicatorTimer;

  @override
  void initState() {
    super.initState();
    _playVideo(widget.url);
    player.setVolume(_volume);
  }

  @override
  void didUpdateWidget(covariant VideoPlayerView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _playVideo(widget.url);
    }
  }

  void _playVideo(String mediaUrl) {
    player.open(Media(mediaUrl), play: true);
  }

  void _showOverlayIndicator(String text, IconData icon) {
    setState(() {
      _indicatorText = text;
      _indicatorIcon = icon;
      _showIndicator = true;
    });
    _indicatorTimer?.cancel();
    _indicatorTimer = Timer(const Duration(seconds: 1, milliseconds: 500), () {
      if (mounted) {
         setState(() => _showIndicator = false);
      }
    });
  }

  void _handleVerticalDragUpdate(DragUpdateDetails details, double screenWidth) {
    // Ekranın sağ yarısı: Ses kontrolü
    if (details.globalPosition.dx > screenWidth / 2) {
      setState(() {
        _volume -= details.primaryDelta! * 0.5;
        _volume = _volume.clamp(0.0, 100.0);
      });
      player.setVolume(_volume);
      _showOverlayIndicator("Ses: ${_volume.toInt()}%", _volume > 0 ? Icons.volume_up : Icons.volume_off);
    } 
    // Ekranın sol yarısı: Yazılımsal Parlaklık (Çapraz platform uyumluluğu için siyah katman opaklığı kullanır)
    else {
      setState(() {
        _brightnessUi -= details.primaryDelta! * 0.005;
        _brightnessUi = _brightnessUi.clamp(0.1, 1.0); 
      });
      _showOverlayIndicator("Parlaklık: ${(_brightnessUi * 100).toInt()}%", Icons.brightness_6);
    }
  }

  void _handleDoubleTap(TapDownDetails details, double screenWidth) {
    if (details.globalPosition.dx > screenWidth / 2) {
      // İleri Sar
      final position = player.state.position;
      player.seek(position + const Duration(seconds: 10));
      _showOverlayIndicator("+10 Saniye", Icons.fast_forward);
    } else {
      // Geri Sar
      final position = player.state.position;
      final newPos = position - const Duration(seconds: 10);
      player.seek(newPos.isNegative ? Duration.zero : newPos);
      _showOverlayIndicator("-10 Saniye", Icons.fast_rewind);
    }
  }

  @override
  void dispose() {
    _indicatorTimer?.cancel();
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold gibi sarmalayıcının genişliği, widget ağacına bağlı
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        
        return Stack(
          children: [
            // Alt Katman: Video Oynatıcı
            Container(
              color: Colors.black, // Video kenarlarını siyah tut
              child: Center(
                child: Video(
                  controller: controller,
                  controls: MaterialVideoControls,
                ),
              ),
            ),
            
            // Orta Katman: Gestures (Ekran kaydırma, tıklamalar)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 80, // Material Controls çubuğuyla (Seekbar vb.) çakışmaması için aşağıda pay bırakıyoruz
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onVerticalDragUpdate: (details) => _handleVerticalDragUpdate(details, width),
                onDoubleTapDown: (details) => _handleDoubleTap(details, width),
                child: Container(), // Boş widget transparan tıklama yüzeyi yaratır
              ),
            ),
            
            // Parlaklık Katmanı (Sadece Sol Yarı için Simüle Edilen Işık Kısımı)
            IgnorePointer(
              child: Container(
                color: Colors.black.withOpacity(1.0 - _brightnessUi),
              ),
            ),
            
            // Üst Katman: OSD (Ses, Parlaklık vb için gösterge)
            if (_showIndicator)
              Positioned.fill(
                child: IgnorePointer(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_indicatorIcon, color: Colors.white, size: 48),
                          const SizedBox(height: 8),
                          Text(
                            _indicatorText, 
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      }
    );
  }
}
