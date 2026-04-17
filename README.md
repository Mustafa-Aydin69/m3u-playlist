# 📺 Çöplük - Gelişmiş IPTV Oynatıcı

Çöplük; Flutter tabanlı, son derece hafif, donanım hızlandırma destekli ve yüksek performanslı modern bir çapraz platform IPTV oynatıcısıdır. Kullanıcıların `.m3u` veya `.m3u8` oynatma listelerini temiz, pürüzsüz ve donmayan bir arayüz ile izlemelerine olanak tanır. 

Uygulama; Windows, Linux, Android ve macOS platformlarının tümünde tam optimizasyon ve native (doğal) performansla çalışmaktadır.

## 🚀 Öne Çıkan Özellikler

- **VLC Altyapısıyla Donanım Hızlandırma:** Uygulama saf `media_kit` kütüphanesi altyapısına sahiptir. Arka planda donanım destekli (Hardware Decoding) video işleme teknolojisi sayesine hiçbir IP kamerasında veya yayında darboğaz yaşanmaz.
- **Akıllı Çekmece Kategorizasyonu:** Binlerce kanalı tek ekrana yığarak sistemin RAM/Kasma sınırlarına takılmasını engeller. M3U dosyasındaki `group-title` özelliklerini tespit eden algoritması sayesinde kanalları gruplandırır. (TV Kanalları, Filmler, S Sport vb.)
- **🔞 Otomatik Çöplük Sistemi:** Liste içerisindeki (18+, adult, xxx, vb.) uygunsuz grupları veya kanalları aradan ayıklar, onları ana ekranda barındırmak yerine en alttaki `🔞 Çöplük` klasöründe derin bir klasöre sıkıştırır. Merak eden tıklayıp girebilir ancak genel ekran temiz tutulur.
- **Kusursuz State Management:** Riverpod mimarisi sayesinde anlık kanal takibi, state ve gecikmesiz *Güçlü Arama (Search)* özelliği tek satırda kusursuz çalışır.
- **Hızlı Erişim & Quota Bypass:** Dosyaları belleğe fiziki olarak kaydetmez. Tarayıcı/Kota limitlerine (Storage Limit) çözüm olarak dosyayı anlık RAM'de çözer ve ekrana basar. File Picker ile lokal cihazdan veya direkt internet linki üzerinden anında entegrasyon sağlanabilir.

## 🛠️ Teknik Altyapı ve Kütüphaneler

- **Arayüz (UI) Framework:** [Flutter](https://flutter.dev/) (Material 3)
- **State Mimari Yönetimi:** [Flutter Riverpod](https://riverpod.dev/) ^2.5.1
- **Medya Motoru:** [MediaKit](https://github.com/media-kit/media-kit) ^1.1.10
- **Lokal Veri Aktarımı:** [File Picker](https://pub.dev/packages/file_picker) ^8.0.3

## 🔒 Gerekli İzinler (Özellikle Android Yapılarında)
Android veya mobil sürümlerde yayın kalitesinin düşmemesi ve kesintisiz akış sağlamak için projeye gömülmüş olan resmi izinler şunlardır:
* `INTERNET` - Yayını canlı m3u listelerinden indirmek için mutlak ağ erişimi.
* `READ_EXTERNAL_STORAGE` vb. - Uygulama içinde manuel olarak ".m3u" dosyanızı File Picker ile içeri aktarması için medyaya erişim imkânı.
* `usesCleartextTraffic="true"` - HTTP tabanlı IPTV şifresiz ağ engeline takılmamak ve yayın kapanmalarını durdurmak için.

## ⚙️ Kurulum & Geliştirici Kodları (Build)

Projeyi kendi cihazınızda derleyebilmek için makinenizde [Flutter SDK](https://docs.flutter.dev/get-started/install) yüklü olmalıdır.

**Terminalde uygulamanın testini başlatmak için:**
```bash
# Mevcut cihaza göre otomatik çalıştırır
flutter run 

# Özel olarak Linux veya Windows emülasyonu çalıştırmak için:
flutter run -d linux
flutter run -d windows
```

**Telefona Yüklemek İçin (Release APK Çıktısı Alma):**
```bash
flutter build apk
```
_Bu komut bittiğinde derlenmiş APK dosyası uygulamanın kurulu olduğu dizindeki `build/app/outputs/flutter-apk/app-release.apk` içerisine düşecektir. Onu alıp anında Android cihazınızda kurabilirsiniz.
