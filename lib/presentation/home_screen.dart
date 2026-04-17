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
        title: const Text('Çöplük', style: TextStyle(fontWeight: FontWeight.bold)),
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
          
          // Arama
          TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            onChanged: (val) => notifier.searchChannel(val),
            decoration: InputDecoration(
              hintText: 'Kanal veya Kategori Ara...',
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon: const Icon(Icons.search, color: Colors.white38),
              filled: true,
              fillColor: const Color(0xFF1E1E2C),
              border: const OutlineInputBorder(borderSide: BorderSide.none),
              suffixIcon: state.searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white38),
                      onPressed: () {
                        _searchController.clear();
                        notifier.searchChannel('');
                      },
                    )
                  : null,
            ),
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
          else if (state.searchQuery.isNotEmpty)
            // Arama Sonuçları
            Expanded(
              child: _buildChannelListView(state, notifier),
            )
          else if (state.selectedGroup == null)
            // Ana Kategori Listesi
            Expanded(
              child: _buildFolderList(state.groups, notifier, isSubGroup: false),
            )
          else if (state.selectedGroup == 'Çöplük' && state.subGroup == null)
            // Çöplük İçindeki Kategoriler
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () {
                          notifier.selectGroup(null);
                        },
                      ),
                      const Expanded(
                        child: Text(
                          '🔞 Çöplük',
                          style: TextStyle(
                            color: Colors.redAccent, 
                            fontWeight: FontWeight.bold, 
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _buildFolderList(state.trashGroups, notifier, isSubGroup: true),
                  ),
                ],
              ),
            )
          else
            // Seçili Kategorideki (veya alt kategorideki) Kanallar
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () {
                          if (state.selectedGroup == 'Çöplük' && state.subGroup != null) {
                            notifier.selectSubGroup(null);
                          } else {
                            notifier.selectGroup(null);
                          }
                        },
                      ),
                      Expanded(
                        child: Text(
                          state.subGroup ?? state.selectedGroup!,
                          style: const TextStyle(
                            color: Colors.white, 
                            fontWeight: FontWeight.bold, 
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _buildChannelListView(state, notifier),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFolderList(List<String> folders, ChannelNotifier notifier, {required bool isSubGroup}) {
    if (folders.isEmpty) {
      return const Center(child: Text('Klasör bulunamadı', style: TextStyle(color: Colors.white54)));
    }
    return ListView.builder(
      itemCount: folders.length,
      itemBuilder: (context, index) {
        final groupName = folders[index];
        final isTrash = groupName == 'Çöplük';
        return Card(
          color: const Color(0xFF1E1E2C),
          margin: const EdgeInsets.only(bottom: 6),
          elevation: 0,
          child: ListTile(
            leading: Icon(
              isTrash ? Icons.delete_outline : Icons.folder, 
              color: isTrash ? Colors.redAccent : Colors.blueAccent,
            ),
            title: Text(
              isTrash ? '🔞 $groupName' : groupName,
              style: TextStyle(
                color: isTrash ? Colors.redAccent : Colors.white, 
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.white54),
            onTap: () {
              if (isSubGroup) {
                notifier.selectSubGroup(groupName);
              } else {
                notifier.selectGroup(groupName);
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildChannelListView(ChannelState state, ChannelNotifier notifier) {
    if (state.filteredChannels.isEmpty) {
      return const Center(
        child: Text(
          'Kanal bulunamadı',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }
    return ListView.builder(
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
            subtitle: state.searchQuery.isNotEmpty
              ? Text(
                  channel.group,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
            onTap: () {
              notifier.selectChannel(channel);
            },
          ),
        );
      },
    );
  }
}
