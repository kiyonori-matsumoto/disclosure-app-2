/// セマンティックバージョニング形式（例: "2.7.1", "2.8.0+12"）のバージョン比較ユーティリティ
class VersionComparator {
  /// 現在のバージョン [current] が、最低必須バージョン [minRequired] 未満かどうかを判定する。
  ///
  /// - [current] < [minRequired] の場合: `true`（強制アップデートが必要）
  /// - [current] >= [minRequired] の場合: `false`（アップデート不要）
  /// - パースに失敗した場合は安全側に倒して `false` を返す。
  static bool isUpdateRequired({
    required String current,
    required String minRequired,
  }) {
    if (minRequired.trim().isEmpty) return false;

    final currentParts = _parseVersion(current);
    final minParts = _parseVersion(minRequired);

    if (currentParts == null || minParts == null) {
      return false;
    }

    final maxLength = currentParts.length > minParts.length
        ? currentParts.length
        : minParts.length;

    for (int i = 0; i < maxLength; i++) {
      final c = i < currentParts.length ? currentParts[i] : 0;
      final m = i < minParts.length ? minParts[i] : 0;

      if (c < m) {
        return true;
      } else if (c > m) {
        return false;
      }
    }

    return false;
  }

  /// バージョン文字列を整数のリストに変換する
  /// 例: "2.7.1+42" -> [2, 7, 1]
  static List<int>? _parseVersion(String version) {
    try {
      final sanitized = version.trim().split('+').first.split('-').first;
      final parts = sanitized.split('.');
      if (parts.isEmpty) return null;

      final numbers = <int>[];
      for (final part in parts) {
        final parsed = int.tryParse(part.trim());
        if (parsed == null) return null;
        numbers.add(parsed);
      }
      return numbers;
    } catch (_) {
      return null;
    }
  }
}
