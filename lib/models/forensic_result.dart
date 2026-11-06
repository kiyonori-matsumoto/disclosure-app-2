enum ForensicRiskLevel {
  critical,
  warning,
  normal;

  static ForensicRiskLevel fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'critical':
        return ForensicRiskLevel.critical;
      case 'warning':
        return ForensicRiskLevel.warning;
      case 'normal':
      default:
        return ForensicRiskLevel.normal;
    }
  }

  String toValue() {
    switch (this) {
      case ForensicRiskLevel.critical:
        return 'critical';
      case ForensicRiskLevel.warning:
        return 'warning';
      case ForensicRiskLevel.normal:
        return 'normal';
    }
  }
}

class ForensicMetrics {
  final int? revenue; // 売上高 (千円)
  final int? operatingIncome; // 営業利益 (千円)
  final int? netIncome; // 当期純利益 (千円)
  final int? operatingCashFlow; // 営業活動によるキャッシュフロー (千円)
  final double? payoutRatio; // 配当性向 (%)
  final int? totalAssets; // 総資産 (千円)
  final String unit; // デフォルト "千円"

  const ForensicMetrics({
    this.revenue,
    this.operatingIncome,
    this.netIncome,
    this.operatingCashFlow,
    this.payoutRatio,
    this.totalAssets,
    this.unit = '千円',
  });

  factory ForensicMetrics.fromMap(Map<String, dynamic> map) {
    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v);
      return null;
    }

    double? parseDouble(dynamic v) {
      if (v == null) return null;
      if (v is double) return v;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    return ForensicMetrics(
      revenue: parseInt(map['revenue']),
      operatingIncome: parseInt(map['operatingIncome']),
      netIncome: parseInt(map['netIncome']),
      operatingCashFlow: parseInt(map['operatingCashFlow']),
      payoutRatio: parseDouble(map['payoutRatio']),
      totalAssets: parseInt(map['totalAssets']),
      unit: map['unit']?.toString() ?? '千円',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (revenue != null) 'revenue': revenue,
      if (operatingIncome != null) 'operatingIncome': operatingIncome,
      if (netIncome != null) 'netIncome': netIncome,
      if (operatingCashFlow != null) 'operatingCashFlow': operatingCashFlow,
      if (payoutRatio != null) 'payoutRatio': payoutRatio,
      if (totalAssets != null) 'totalAssets': totalAssets,
      'unit': unit,
    };
  }
}

class ForensicDetails {
  final String? blameAttribution;
  final bool unfoundedOptimism;
  final bool hasNegativeFactors;

  const ForensicDetails({
    this.blameAttribution,
    this.unfoundedOptimism = false,
    this.hasNegativeFactors = false,
  });

  factory ForensicDetails.fromMap(Map<String, dynamic> map) {
    return ForensicDetails(
      blameAttribution: map['blameAttribution']?.toString(),
      unfoundedOptimism: map['unfoundedOptimism'] == true,
      hasNegativeFactors: map['hasNegativeFactors'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (blameAttribution != null) 'blameAttribution': blameAttribution,
      'unfoundedOptimism': unfoundedOptimism,
      'hasNegativeFactors': hasNegativeFactors,
    };
  }
}

class ForensicResult {
  final int version;
  final DateTime? analyzedAt;
  final ForensicRiskLevel riskLevel;
  final List<String> tags;
  final List<String> causes;
  final ForensicMetrics? metrics;
  final ForensicDetails? details;

  const ForensicResult({
    this.version = 1,
    this.analyzedAt,
    this.riskLevel = ForensicRiskLevel.normal,
    this.tags = const [],
    this.causes = const [],
    this.metrics,
    this.details,
  });

  factory ForensicResult.fromMap(Map<String, dynamic> map) {
    DateTime? parseDateTime(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      if (v is int) {
        // 10桁程度なら秒、13桁程度ならミリ秒
        if (v < 10000000000) {
          return DateTime.fromMillisecondsSinceEpoch(v * 1000);
        }
        return DateTime.fromMillisecondsSinceEpoch(v);
      }
      // Firestore Timestamp 等
      try {
        if (v.toDate != null && v.toDate is Function) {
          return v.toDate() as DateTime;
        }
      } catch (_) {}
      return null;
    }

    List<String> parseStringList(dynamic v) {
      if (v is List) {
        return v.map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList();
      }
      return const [];
    }

    return ForensicResult(
      version: (map['version'] is int) ? map['version'] as int : 1,
      analyzedAt: parseDateTime(map['analyzedAt']),
      riskLevel: ForensicRiskLevel.fromString(map['riskLevel']?.toString()),
      tags: parseStringList(map['tags']),
      causes: parseStringList(map['causes']),
      metrics: map['metrics'] is Map<String, dynamic>
          ? ForensicMetrics.fromMap(map['metrics'] as Map<String, dynamic>)
          : (map['metrics'] is Map
              ? ForensicMetrics.fromMap(Map<String, dynamic>.from(map['metrics'] as Map))
              : null),
      details: map['details'] is Map<String, dynamic>
          ? ForensicDetails.fromMap(map['details'] as Map<String, dynamic>)
          : (map['details'] is Map
              ? ForensicDetails.fromMap(Map<String, dynamic>.from(map['details'] as Map))
              : null),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'version': version,
      if (analyzedAt != null)
        'analyzedAt': (analyzedAt!.millisecondsSinceEpoch / 1000).round(),
      'riskLevel': riskLevel.toValue(),
      'tags': tags,
      'causes': causes,
      if (metrics != null) 'metrics': metrics!.toMap(),
      if (details != null) 'details': details!.toMap(),
    };
  }
}
