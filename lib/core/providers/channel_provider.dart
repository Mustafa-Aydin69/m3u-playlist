import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/channel_model.dart';
import '../services/m3u_service.dart';

final m3uServiceProvider = Provider<M3uService>((ref) => M3uService());

class ChannelState {
  final bool isLoading;
  final String error;
  final List<ChannelModel> allChannels;
  final List<ChannelModel> filteredChannels;
  final ChannelModel? currentChannel;
  final List<String> groups;
  final List<String> trashGroups;
  final String? selectedGroup;
  final String? subGroup;
  final String searchQuery;
  final Set<String> favoriteUrls;

  ChannelState({
    this.isLoading = false,
    this.error = '',
    this.allChannels = const [],
    this.filteredChannels = const [],
    this.currentChannel,
    this.groups = const [],
    this.trashGroups = const [],
    this.selectedGroup,
    this.subGroup,
    this.searchQuery = '',
    this.favoriteUrls = const {},
  });

  ChannelState copyWith({
    bool? isLoading,
    String? error,
    List<ChannelModel>? allChannels,
    List<ChannelModel>? filteredChannels,
    ChannelModel? currentChannel,
    List<String>? groups,
    List<String>? trashGroups,
    String? selectedGroup,
    String? subGroup,
    String? searchQuery,
    Set<String>? favoriteUrls,
    bool clearGroup = false,
    bool clearSubGroup = false,
  }) {
    return ChannelState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      allChannels: allChannels ?? this.allChannels,
      filteredChannels: filteredChannels ?? this.filteredChannels,
      currentChannel: currentChannel ?? this.currentChannel,
      groups: groups ?? this.groups,
      trashGroups: trashGroups ?? this.trashGroups,
      selectedGroup: clearGroup ? null : (selectedGroup ?? this.selectedGroup),
      subGroup: clearSubGroup ? null : (subGroup ?? this.subGroup),
      searchQuery: searchQuery ?? this.searchQuery,
      favoriteUrls: favoriteUrls ?? this.favoriteUrls,
    );
  }
}

class ChannelNotifier extends StateNotifier<ChannelState> {
  final M3uService _service;
  SharedPreferences? _prefs;

  ChannelNotifier(this._service) : super(ChannelState()) {
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    final favs = _prefs?.getStringList('favorite_urls') ?? [];
    state = state.copyWith(favoriteUrls: favs.toSet());
    
    // Otomatik Yükleme Mantığı
    final lastSourceType = _prefs?.getString('last_source_type');
    final lastSourceValue = _prefs?.getString('last_source_value');
    
    if (lastSourceType == 'url' && lastSourceValue != null && lastSourceValue.isNotEmpty) {
      loadFromUrl(lastSourceValue);
    } else if (lastSourceType == 'file' && lastSourceValue != null && lastSourceValue.isNotEmpty) {
      loadFromPath(lastSourceValue);
    }
  }

  Future<void> toggleFavorite(ChannelModel channel) async {
    final newFavs = Set<String>.from(state.favoriteUrls);
    if (newFavs.contains(channel.url)) {
      newFavs.remove(channel.url);
    } else {
      newFavs.add(channel.url);
    }
    await _prefs?.setStringList('favorite_urls', newFavs.toList());
    
    List<ChannelModel> newFiltered = state.filteredChannels;
    if (state.selectedGroup == '⭐ Favorilerim') {
        newFiltered = state.allChannels.where((ch) => newFavs.contains(ch.url)).toList();
    }
    
    // Update groups if Favorilerim should appear or disappear
    List<String> newGroups = List.from(state.groups);
    final hasFavorites = state.allChannels.any((ch) => newFavs.contains(ch.url));
    
    if (hasFavorites && !newGroups.contains('⭐ Favorilerim')) {
        newGroups.insert(0, '⭐ Favorilerim');
    } else if (!hasFavorites && newGroups.contains('⭐ Favorilerim')) {
        newGroups.remove('⭐ Favorilerim');
        if (state.selectedGroup == '⭐ Favorilerim') {
            // Favoriler boşaldıysa ana menüye dön
            state = state.copyWith(favoriteUrls: newFavs, groups: newGroups, clearGroup: true, clearSubGroup: true, filteredChannels: []);
            return;
        }
    }

    state = state.copyWith(favoriteUrls: newFavs, filteredChannels: newFiltered, groups: newGroups);
  }

  Future<void> loadFromUrl(String url) async {
    state = state.copyWith(isLoading: true, error: '');
    try {
      final channels = await _service.fetchFromUrl(url);
      _setupChannels(channels);
      await _prefs?.setString('last_source_type', 'url');
      await _prefs?.setString('last_source_value', url);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadFromFile() async {
    state = state.copyWith(isLoading: true, error: '');
    try {
      final channels = await _service.loadFromFile();
      if (channels.isEmpty) {
         state = state.copyWith(isLoading: false, error: 'Dosya seçilmedi.');
         return;
      }
      _setupChannels(channels);
      
      if (_service.lastPickedFilePath != null) {
        await _prefs?.setString('last_source_type', 'file');
        await _prefs?.setString('last_source_value', _service.lastPickedFilePath!);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadFromPath(String path) async {
    state = state.copyWith(isLoading: true, error: '');
    try {
      final channels = await _service.loadFromPath(path);
      _setupChannels(channels);
      await _prefs?.setString('last_source_type', 'file');
      await _prefs?.setString('last_source_value', path);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  bool _isAdultGroup(String name) {
    final lower = name.toLowerCase();
    return lower.contains('+18') || 
           lower.contains('18+') || 
           lower.contains('adult') || 
           lower.contains(' porn') ||
           lower.contains('xxx');
  }

  void _setupChannels(List<ChannelModel> channels) {
    final normalGroups = <String>{};
    final adultGroups = <String>{};

    for (var ch in channels) {
      if (_isAdultGroup(ch.group)) {
        adultGroups.add(ch.group);
      } else {
        normalGroups.add(ch.group);
      }
    }

    final sortedGroups = normalGroups.toList()..sort();
    final sortedAdultGroups = adultGroups.toList()..sort();
    
    final hasFavorites = channels.any((ch) => state.favoriteUrls.contains(ch.url));
    if (hasFavorites) {
      sortedGroups.insert(0, '⭐ Favorilerim');
    }

    if (sortedAdultGroups.isNotEmpty) {
      sortedGroups.add('Çöplük');
    }

    state = state.copyWith(
      isLoading: false,
      allChannels: channels,
      filteredChannels: [],
      groups: sortedGroups,
      trashGroups: sortedAdultGroups,
      clearGroup: true,
      clearSubGroup: true,
      searchQuery: '',
      error: '',
    );
  }

  void selectGroup(String? group) {
    if (group == null) {
      state = state.copyWith(
        clearGroup: true, 
        clearSubGroup: true,
        filteredChannels: [],
        searchQuery: '',
      );
    } else if (group == 'Çöplük') {
      state = state.copyWith(
        selectedGroup: group,
        clearSubGroup: true,
        filteredChannels: [],
        searchQuery: '',
      );
    } else if (group == '⭐ Favorilerim') {
      final filtered = state.allChannels.where((ch) => state.favoriteUrls.contains(ch.url)).toList();
      state = state.copyWith(
        selectedGroup: group,
        clearSubGroup: true,
        filteredChannels: filtered,
        searchQuery: '',
      );
    } else {
      final filtered = state.allChannels.where((ch) => ch.group == group).toList();
      state = state.copyWith(
        selectedGroup: group,
        clearSubGroup: true,
        filteredChannels: filtered,
        searchQuery: '',
      );
    }
  }

  void selectSubGroup(String? subGroup) {
    if (subGroup == null) {
      state = state.copyWith(
        clearSubGroup: true,
        filteredChannels: [],
        searchQuery: '',
      );
    } else {
      final filtered = state.allChannels.where((ch) => ch.group == subGroup).toList();
      state = state.copyWith(
        subGroup: subGroup,
        filteredChannels: filtered,
        searchQuery: '',
      );
    }
  }

  void searchChannel(String query) {
    final lowerQuery = query.toLowerCase();
    
    // Aramayı hem seçili grup içinde hem de genel yapabiliriz.
    List<ChannelModel> baseList;
    if (state.selectedGroup == null) {
      baseList = state.allChannels;
    } else if (state.selectedGroup == 'Çöplük') {
      if (state.subGroup == null) {
        // Çöplükte arama yapılıyorsa sadece o klasördekilerde ara
        baseList = state.allChannels.where((ch) => _isAdultGroup(ch.group)).toList();
      } else {
        baseList = state.allChannels.where((ch) => ch.group == state.subGroup).toList();
      }
    } else if (state.selectedGroup == '⭐ Favorilerim') {
      baseList = state.allChannels.where((ch) => state.favoriteUrls.contains(ch.url)).toList();
    } else {
      baseList = state.allChannels.where((ch) => ch.group == state.selectedGroup).toList();
    }

    if (query.isEmpty) {
      if (state.selectedGroup == null) {
         state = state.copyWith(searchQuery: query, filteredChannels: []);
      } else {
         state = state.copyWith(searchQuery: query, filteredChannels: baseList);
      }
    } else {
      final filtered = baseList.where((ch) => ch.name.toLowerCase().contains(lowerQuery)).toList();
      state = state.copyWith(searchQuery: query, filteredChannels: filtered);
    }
  }

  void selectChannel(ChannelModel channel) {
    state = state.copyWith(currentChannel: channel);
  }
}

final channelProvider = StateNotifierProvider<ChannelNotifier, ChannelState>((ref) {
  return ChannelNotifier(ref.read(m3uServiceProvider));
});
