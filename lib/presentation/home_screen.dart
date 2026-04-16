import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/channel_provider.dart';
import 'widgets/video_player_view.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _urlController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(channelProvider);
    final notifier = ref.read(channelProvider.notifier);

    // Koyu, modern tasarım
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C), // Koyu arka plan
      appBar: AppBar(
        title: const Text('Gelişmiş IPTV Oynatıcı', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF252538),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Sadece Bu Oturum: M3U Dosyası Seç (Kotayı Aşmaz)',
            icon: const Icon(Icons.file_upload),
            onPressed: () {
              notifier.loadFromFile();
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: isDesktop
          ? _buildDesktopLayout(state, notifier)
          : _buildMobileLayout(state, notifier),
    );
  }

  Widget _buildDesktopLayout(ChannelState state, ChannelNotifier notifier) {
    return Row(
      children: [
        // Sol Panel (Kanallar)
        Expanded(
          flex: 2,
          child: _buildSidePanel(state, notifier),
        ),
        // Sağ Panel (Video Oynatıcı)
        Expanded(
          flex: 5,
          child: _buildVideoArea(state),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(ChannelState state, ChannelNotifier notifier) {
    return Column(
      children: [
        // Üst Kısım (Video Oynatıcı)
        SizedBox(
          height: 250,
          child: _buildVideoArea(state),
        ),
        // Alt Kısım (Kanallar)
        Expanded(
          child: _buildSidePanel(state, notifier),
        ),
      ],
    );
  }

  Widget _buildVideoArea(ChannelState state) {
    if (state.currentChannel == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Text(
            'Bir kanal seçin...',
            style: TextStyle(color: Colors.white54, fontSize: 18),
          ),
        ),
      );
    }

    return VideoPlayerView(
      // URL değiştiğinde widget kendini yenileyecek ve Player hızlıca yeni medyayı açacak
      key: ValueKey(state.currentChannel!.url),
      url: state.currentChannel!.url,
    );
  }

  Widget _buildSidePanel(ChannelState state, ChannelNotifier notifier) {
    return Container(
      color: const Color(0xFF252538),
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          // URL Giriş
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _urlController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'M3U Linki Yapıştırın...',
                    hintStyle: TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Color(0xFF1E1E2C),
                    border: OutlineInputBorder(borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.all(16),
                ),
                onPressed: () {
                  if (_urlController.text.isNotEmpty) {
                    notifier.loadFromUrl(_urlController.text);
                  }
                },
                child: const Icon(Icons.download, color: Colors.white),
              )
            ],
          ),
          const SizedBox(height: 12),
          
          // Filtreler (Grup Seçimi + Arama)
          Row(
            children: [
              Expanded(
                flex: 2,
                child: DropdownButtonHideUnderline(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E2C),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: DropdownButton<String>(
                      isExpanded: true,
                      dropdownColor: const Color(0xFF1E1E2C),
                      value: state.groups.contains(state.selectedGroup) ? state.selectedGroup : 'Tümü',
                      style: const TextStyle(color: Colors.white),
                      items: state.groups.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          notifier.filterByGroup(val);
                          // Grup değiştiğinde arama kutusunu da sıfırlayalım
                          _searchController.clear();
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  onChanged: (val) => notifier.searchChannel(val),
                  decoration: const InputDecoration(
                    hintText: 'Kanal Ara...',
                    hintStyle: TextStyle(color: Colors.white38),
                    prefixIcon: Icon(Icons.search, color: Colors.white38),
                    filled: true,
                    fillColor: Color(0xFF1E1E2C),
                    border: OutlineInputBorder(borderSide: BorderSide.none),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Durum / Hata Gösterimi
          if (state.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (state.error.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                state.error,
                style: const TextStyle(color: Colors.redAccent),
                textAlign: TextAlign.center,
              ),
            )
          else
            // Kanal Listesi
            Expanded(
              child: ListView.builder(
                itemCount: state.filteredChannels.length,
                itemBuilder: (context, index) {
                  final channel = state.filteredChannels[index];
                  final isSelected = state.currentChannel?.url == channel.url;
                  
                  return Card(
                    color: isSelected ? Colors.blueAccent.withOpacity(0.3) : const Color(0xFF1E1E2C),
                    margin: const EdgeInsets.only(bottom: 6),
                    elevation: 0,
                    child: ListTile(
                      leading: channel.logo.isNotEmpty 
                        ? Image.network(
                            channel.logo, 
                            width: 40, 
                            height: 40,
                            errorBuilder: (_, __, ___) => const Icon(Icons.tv, color: Colors.white54, size: 30),
                          )
                        : const Icon(Icons.tv, color: Colors.white54, size: 30),
                      title: Text(
                        channel.name,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        channel.group,
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                        maxLines: 1,
                      ),
                      onTap: () {
                        // Kanala tıklandığında anında Riverpod ile bildirir, oynatıcı hızlıca açar.
                        notifier.selectChannel(channel);
                      },
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
