import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/channel_model.dart';
import 'package:file_picker/file_picker.dart';

class M3uService {
  String? lastPickedFilePath;

  /// URL'den M3U listesini güçlü header'lar (Tarayıcı taklidi) ile çeker.
  /// Çekim sonrası ayrıştırır ve List<ChannelModel> döner. (Sadece Bu Oturum Modu)
  Future<List<ChannelModel>> fetchFromUrl(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36',
          'Accept': '*/*',
          'Accept-Language': 'en-US,en;q=0.9,tr;q=0.8',
          'Connection': 'keep-alive',
          // Bazı sağlayıcılar Origin ve Referer kontrolü yapar.
          'Origin': 'https://google.com',
          'Referer': 'https://google.com/',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        // UTF-8 olarak decodeluyoruz ki Türkçe karakterler düzgün gelsin.
        return _parseM3uString(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('Bağlantı hatası: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Link yüklenirken hata oluştu: $e');
    }
  }

  /// Kullanıcının cihazından FilePicker ile seçtiği M3U dosyasını ayrıştırır.
  /// Kota hatası (Storage Limit) yaşanmaması için dosya salt bellekte tutulur, hiçbir yere kaydedilmez.
  Future<List<ChannelModel>> loadFromFile() async {
    try {
      // Platformlardan bağımsız olarak dosyayı alalım (Web için withData: true zorunludur)
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['m3u', 'm3u8', 'txt'],
        withData: true, 
      );

      if (result != null) {
        if (result.files.single.path != null) {
          lastPickedFilePath = result.files.single.path;
        }

        // Eğer cihaz Web ise path her zaman null döner, bu yüzden doğrudan byte (RAM) olarak okuyacağız.
        if (result.files.single.bytes != null) {
          final contents = utf8.decode(result.files.single.bytes!);
          return _parseM3uString(contents);
        } 
        // Masaüstü/Mobil vs. de bytes null dönerse diye klasik path okumasını yedek bırakalım
        else if (result.files.single.path != null) {
          final file = File(result.files.single.path!);
          final contents = await file.readAsString(encoding: utf8);
          return _parseM3uString(contents);
        }
      }
      return []; // Kullanıcı iptal etti veya dosya hatalı

    } catch (e) {
      throw Exception('Dosya okunurken hata okutu: $e');
    }
  }

  /// Verilen doğrudan dosya yolundan (path) okuma yapar.
  Future<List<ChannelModel>> loadFromPath(String path) async {
    try {
      final file = File(path);
      if (!file.existsSync()) {
        throw Exception('Dosya bulunamadı veya konumu değiştirildi.');
      }
      final contents = await file.readAsString(encoding: utf8);
      return _parseM3uString(contents);
    } catch (e) {
      throw Exception('Önbellekteki dosya okunamadı: $e');
    }
  }

  /// M3U metnini satır satır okur ve ChannelModel listesine dönüştürür.
  List<ChannelModel> _parseM3uString(String m3uContent) {
    final List<ChannelModel> channels = [];
    final lines = const LineSplitter().convert(m3uContent);

    String currentName = 'Bilinmeyen Kanal';
    String currentGroup = 'Diğer';
    String currentLogo = '';

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      if (line.startsWith('#EXTINF:')) {
        // Logo regex'i
        final logoMatch = RegExp(r'tvg-logo="([^"]*)"').firstMatch(line);
        if (logoMatch != null) {
          currentLogo = logoMatch.group(1) ?? '';
        } else {
          currentLogo = '';
        }

        // Grup regex'i
        final groupMatch = RegExp(r'group-title="([^"]*)"').firstMatch(line);
        if (groupMatch != null) {
          currentGroup = groupMatch.group(1) ?? 'Diğer';
        } else {
          currentGroup = 'Diğer';
        }

        // Kanal Adı (Virgülden sonraki kısım)
        final commaIndex = line.lastIndexOf(',');
        if (commaIndex != -1 && commaIndex + 1 < line.length) {
          currentName = line.substring(commaIndex + 1).trim();
        } else {
          currentName = 'Bilinmeyen Kanal';
        }
      } else if (!line.startsWith('#')) {
        // URL satırı geldi demektir
        if (line.startsWith('http')) {
           channels.add(
            ChannelModel(
              name: currentName,
              group: currentGroup,
              logo: currentLogo,
              url: line,
            ),
          );
        }
        // Değişkenleri sıfırla ki sonraki kanala sarkmasın
        currentName = 'Bilinmeyen Kanal';
        currentGroup = 'Diğer';
        currentLogo = '';
      }
    }

    return channels;
  }
}
