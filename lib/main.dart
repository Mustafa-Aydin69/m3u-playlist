import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'presentation/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Hızlı oynatıcı altyapısı cihazda başlatılıyor. VLC alt tabakası kullanır.
  MediaKit.ensureInitialized();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hızlı IPTV Oynatıcı',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1E1E2C),
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
