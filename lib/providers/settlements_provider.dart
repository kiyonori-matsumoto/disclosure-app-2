import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:disclosure_app_fl/models/company_settlement.dart';
import 'package:disclosure_app_fl/utils/time.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settlements_provider.g.dart';

/// 決算予定一覧の日付選択 Notifier
@riverpod
class SettlementsSelectedDate extends _$SettlementsSelectedDate {
  @override
  DateTime build() => DateTime.now();

  void setDate(DateTime date) => state = date;
}

/// 特定の日付の決算予定一覧を取得する Family FutureProvider
@riverpod
Future<List<CompanySettlement>> settlementsByDate(
  Ref ref,
  DateTime date,
) async {
  final dateStr = toDateHyphenate(date);

  final snapshot = await FirebaseFirestore.instance
      .collection('settlements')
      .where('schedule', isEqualTo: dateStr)
      .get();

  return snapshot.docs
      .map((doc) => CompanySettlement.fromDocumentSnapshot(doc))
      .toList();
}

/// 現在選択されている日付の決算予定一覧を提供する Provider
@riverpod
Future<List<CompanySettlement>> currentSettlementsList(Ref ref) {
  final date = ref.watch(settlementsSelectedDateProvider);
  return ref.watch(settlementsByDateProvider(date).future);
}
