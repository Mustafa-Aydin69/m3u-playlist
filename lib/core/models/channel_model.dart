class ChannelModel {
  final String name;
  final String group;
  final String logo;
  final String url;

  ChannelModel({
    required this.name,
    required this.group,
    required this.logo,
    required this.url,
  });

  // Hızlı arama veya loglama işlemleri için override
  @override
  String toString() {
    return 'ChannelModel(name: $name, group: $group, url: $url)';
  }
}
