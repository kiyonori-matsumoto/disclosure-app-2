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

class FinancialSnapshot {
  final int? revenue; // 売上高 (千円)
  final int? operatingIncome; // 営業利益 (千円)
  final int? netIncome; // 当期純利益 (千円)
  final int? operatingCashFlow; // 営業活動によるキャッシュフロー (千円)
  final double? payoutRatio; // 配当性向 (%)
  final int? totalAssets; // 総資産 (千円)
  final int? tradeReceivables; // 売上債権 (千円)
  final int? inventories; // 棚卸資産 (千円)
  final int? cashAndDeposits; // 現金及び預金 (千円)
  final int? currentAssets; // 流動資産合計 (千円)
  final int? propertyPlantAndEquipment; // 有形固定資産合計 (千円)
  final int? currentLiabilities; // 流動負債合計 (千円)
  final int? netAssets; // 純資産 (千円)
  final int? retainedEarnings; // 利益剰余金 (千円)
  final int? investingCashFlow; // 投資活動によるキャッシュフロー (千円)

  const FinancialSnapshot({
    this.revenue,
    this.operatingIncome,
    this.netIncome,
    this.operatingCashFlow,
    this.payoutRatio,
    this.totalAssets,
    this.tradeReceivables,
    this.inventories,
    this.cashAndDeposits,
    this.currentAssets,
    this.propertyPlantAndEquipment,
    this.currentLiabilities,
    this.netAssets,
    this.retainedEarnings,
    this.investingCashFlow,
  });

  factory FinancialSnapshot.fromMap(Map<String, dynamic> map) {
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

    return FinancialSnapshot(
      revenue: parseInt(map['revenue']),
      operatingIncome: parseInt(map['operatingIncome']),
      netIncome: parseInt(map['netIncome']),
      operatingCashFlow: parseInt(map['operatingCashFlow']),
      payoutRatio: parseDouble(map['payoutRatio']),
      totalAssets: parseInt(map['totalAssets']),
      tradeReceivables: parseInt(map['tradeReceivables']),
      inventories: parseInt(map['inventories']),
      cashAndDeposits: parseInt(map['cashAndDeposits']),
      currentAssets: parseInt(map['currentAssets']),
      propertyPlantAndEquipment: parseInt(map['propertyPlantAndEquipment']),
      currentLiabilities: parseInt(map['currentLiabilities']),
      netAssets: parseInt(map['netAssets']),
      retainedEarnings: parseInt(map['retainedEarnings']),
      investingCashFlow: parseInt(map['investingCashFlow']),
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
      if (tradeReceivables != null) 'tradeReceivables': tradeReceivables,
      if (inventories != null) 'inventories': inventories,
      if (cashAndDeposits != null) 'cashAndDeposits': cashAndDeposits,
      if (currentAssets != null) 'currentAssets': currentAssets,
      if (propertyPlantAndEquipment != null)
        'propertyPlantAndEquipment': propertyPlantAndEquipment,
      if (currentLiabilities != null) 'currentLiabilities': currentLiabilities,
      if (netAssets != null) 'netAssets': netAssets,
      if (retainedEarnings != null) 'retainedEarnings': retainedEarnings,
      if (investingCashFlow != null) 'investingCashFlow': investingCashFlow,
    };
  }
}

class QuantitativeCalculations {
  final double? accrualsRatio; // 総資産アクルーアル比率
  final double? dsri; // 売上債権回転期間指数 (Beneish M-Score)
  final double? dsiIndex; // 棚卸資産回転期間指数
  final double? aqi; // 資産の質指数 (Beneish M-Score)
  final int? fcf; // フリーキャッシュフロー (千円)
  final double? cashCoverage; // 対流動負債現預金比率
  final double? cashDropRate; // 現預金前期比増減率
  final double? equityRatio; // 自己資本比率
  final double? netAssetsDropRate; // 純資産前期比増減率

  const QuantitativeCalculations({
    this.accrualsRatio,
    this.dsri,
    this.dsiIndex,
    this.aqi,
    this.fcf,
    this.cashCoverage,
    this.cashDropRate,
    this.equityRatio,
    this.netAssetsDropRate,
  });

  factory QuantitativeCalculations.fromMap(Map<String, dynamic> map) {
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

    return QuantitativeCalculations(
      accrualsRatio: parseDouble(map['accrualsRatio']),
      dsri: parseDouble(map['dsri']),
      dsiIndex: parseDouble(map['dsiIndex']),
      aqi: parseDouble(map['aqi']),
      fcf: parseInt(map['fcf']),
      cashCoverage: parseDouble(map['cashCoverage']),
      cashDropRate: parseDouble(map['cashDropRate']),
      equityRatio: parseDouble(map['equityRatio']),
      netAssetsDropRate: parseDouble(map['netAssetsDropRate']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (accrualsRatio != null) 'accrualsRatio': accrualsRatio,
      if (dsri != null) 'dsri': dsri,
      if (dsiIndex != null) 'dsiIndex': dsiIndex,
      if (aqi != null) 'aqi': aqi,
      if (fcf != null) 'fcf': fcf,
      if (cashCoverage != null) 'cashCoverage': cashCoverage,
      if (cashDropRate != null) 'cashDropRate': cashDropRate,
      if (equityRatio != null) 'equityRatio': equityRatio,
      if (netAssetsDropRate != null) 'netAssetsDropRate': netAssetsDropRate,
    };
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

  // 定量フォレンジック拡張プロパティ
  final String? standard; // J-GAAP / IFRS / US-GAAP
  final String? periodType; // FY / Q1 / Q2 / Q3
  final bool isFinancialIndustry;
  final FinancialSnapshot? current;
  final FinancialSnapshot? prior;
  final QuantitativeCalculations? calculations;

  const ForensicMetrics({
    this.revenue,
    this.operatingIncome,
    this.netIncome,
    this.operatingCashFlow,
    this.payoutRatio,
    this.totalAssets,
    this.unit = '千円',
    this.standard,
    this.periodType,
    this.isFinancialIndustry = false,
    this.current,
    this.prior,
    this.calculations,
  });

  // フォールバック付き有効値ゲッター
  int? get effectiveRevenue => current?.revenue ?? revenue;
  int? get effectiveOperatingIncome => current?.operatingIncome ?? operatingIncome;
  int? get effectiveNetIncome => current?.netIncome ?? netIncome;
  int? get effectiveOperatingCashFlow => current?.operatingCashFlow ?? operatingCashFlow;
  int? get effectiveTotalAssets => current?.totalAssets ?? totalAssets;
  double? get effectivePayoutRatio => current?.payoutRatio ?? payoutRatio;
  int? get tradeReceivables => current?.tradeReceivables;
  int? get inventories => current?.inventories;
  int? get cashAndDeposits => current?.cashAndDeposits;
  int? get currentAssets => current?.currentAssets;
  int? get propertyPlantAndEquipment => current?.propertyPlantAndEquipment;
  int? get currentLiabilities => current?.currentLiabilities;
  int? get netAssets => current?.netAssets;
  int? get retainedEarnings => current?.retainedEarnings;
  int? get investingCashFlow => current?.investingCashFlow;

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
      standard: map['standard']?.toString(),
      periodType: map['periodType']?.toString(),
      isFinancialIndustry: map['isFinancialIndustry'] == true,
      current: map['current'] is Map<String, dynamic>
          ? FinancialSnapshot.fromMap(map['current'] as Map<String, dynamic>)
          : (map['current'] is Map
              ? FinancialSnapshot.fromMap(
                  Map<String, dynamic>.from(map['current'] as Map))
              : null),
      prior: map['prior'] is Map<String, dynamic>
          ? FinancialSnapshot.fromMap(map['prior'] as Map<String, dynamic>)
          : (map['prior'] is Map
              ? FinancialSnapshot.fromMap(
                  Map<String, dynamic>.from(map['prior'] as Map))
              : null),
      calculations: map['calculations'] is Map<String, dynamic>
          ? QuantitativeCalculations.fromMap(
              map['calculations'] as Map<String, dynamic>)
          : (map['calculations'] is Map
              ? QuantitativeCalculations.fromMap(
                  Map<String, dynamic>.from(map['calculations'] as Map))
              : null),
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
      if (standard != null) 'standard': standard,
      if (periodType != null) 'periodType': periodType,
      if (isFinancialIndustry) 'isFinancialIndustry': isFinancialIndustry,
      if (current != null) 'current': current!.toMap(),
      if (prior != null) 'prior': prior!.toMap(),
      if (calculations != null) 'calculations': calculations!.toMap(),
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
