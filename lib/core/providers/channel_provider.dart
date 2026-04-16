import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  final String selectedGroup;

  ChannelState({
    this.isLoading = false,
    this.error = '',
    this.allChannels = const [],
    this.filteredChannels = const [],
    this.currentChannel,
    this.groups = const ['Tümü'],
    this.selectedGroup = 'Tümü',
  });

  ChannelState copyWith({
    bool? isLoading,
    String? error,
    List<ChannelModel>? allChannels,
    List<ChannelModel>? filteredChannels,
    ChannelModel? currentChannel,
    List<String>? groups,
    String? selectedGroup,
  }) {
    return ChannelState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      allChannels: allChannels ?? this.allChannels,
      filteredChannels: filteredChannels ?? this.filteredChannels,
      currentChannel: currentChannel ?? this.currentChannel,
      groups: groups ?? this.groups,
      selectedGroup: selectedGroup ?? this.selectedGroup,
    );
  }
}

class ChannelNotifier extends StateNotifier<ChannelState> {
  final M3uService _service;

  ChannelNotifier(this._service) : super(ChannelState());

  Future<void> loadFromUrl(String url) async {
    state = state.copyWith(isLoading: true, error: '');
    try {
      final channels = await _service.fetchFromUrl(url);
      _setupChannels(channels);
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
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void _setupChannels(List<ChannelModel> channels) {
    // Tüm grupları çekip set ile tekilleştiriyoruz
    final groupSet = <String>{'Tümü'};
    for (var ch in channels) {
      groupSet.add(ch.group);
    }

    state = state.copyWith(
      isLoading: false,
      allChannels: channels,
      filteredChannels: channels,
      groups: groupSet.toList()..sort(), // Alfabetik sırala
      selectedGroup: 'Tümü',
      error: '',
    );
  }

  void filterByGroup(String group) {
    if (group == 'Tümü') {
      state = state.copyWith(
        selectedGroup: group,
        filteredChannels: state.allChannels,
      );
    } else {
      final filtered = state.allChannels.where((ch) => ch.group == group).toList();
      state = state.copyWith(
        selectedGroup: group,
        filteredChannels: filtered,
      );
    }
  }

  void searchChannel(String query) {
    final lowerQuery = query.toLowerCase();
    
    // Aramayı hem seçili grup içinde hem de genel yapabiliriz. Şu an grup içinden yapıyoruz.
    List<ChannelModel> baseList;
    if (state.selectedGroup == 'Tümü') {
      baseList = state.allChannels;
    } else {
      baseList = state.allChannels.where((ch) => ch.group == state.selectedGroup).toList();
    }

    if (query.isEmpty) {
      state = state.copyWith(filteredChannels: baseList);
    } else {
      final filtered = baseList.where((ch) => ch.name.toLowerCase().contains(lowerQuery)).toList();
      state = state.copyWith(filteredChannels: filtered);
    }
  }

  void selectChannel(ChannelModel channel) {
    state = state.copyWith(currentChannel: channel);
  }
}

final channelProvider = StateNotifierProvider<ChannelNotifier, ChannelState>((ref) {
  return ChannelNotifier(ref.read(m3uServiceProvider));
});
