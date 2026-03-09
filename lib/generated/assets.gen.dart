class Assets {
  const Assets._();

  static const AssetGroup animations = AssetGroup('assets/animations');
  static const AssetGroup icons = AssetGroup('assets/icons');
  static const AssetGroup images = AssetGroup('assets/images');
}

class AssetGroup {
  const AssetGroup(this.path);

  final String path;
}
