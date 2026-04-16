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

  @override
  void initState() {
    super.initState();
    // İlk açılışta videoyu başlat
    _playVideo(widget.url);
  }

  @override
  void didUpdateWidget(covariant VideoPlayerView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Eğer prop olarak gelen URL değişmişse (kullanıcı kanal değiştirmişse), hızlıca yeni medyaya geç
    if (oldWidget.url != widget.url) {
      _playVideo(widget.url);
    }
  }

  void _playVideo(String mediaUrl) {
    // Pürüzsüz geçiş için mevcut videoyu durdurup yenisini açar
    player.open(Media(mediaUrl), play: true);
  }

  @override
  void dispose() {
    // Bileşen yok edildiğinde bellek sızıntısını (RAM Kaçağını) önle
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black, // Video kenarlarını siyah tut
      child: Center(
        child: Video(
          controller: controller,
          // Kullanıcı video üzerinde kontrolleri görebilsin (Oynat/Durdur Ses vb.)
          controls: MaterialVideoControls,
        ),
      ),
    );
  }
}
