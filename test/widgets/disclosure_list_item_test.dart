import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:disclosure_app_fl/widgets/disclosure_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

// ignore: subtype_of_sealed_class
class FakeDocumentSnapshot extends Fake
    implements DocumentSnapshot<Map<String, dynamic>> {
  final Map<String, dynamic> _data;
  final String _id;

  FakeDocumentSnapshot(this._data, [this._id = 'test_id']);

  @override
  String get id => _id;

  @override
  Map<String, dynamic> data() => _data;

  @override
  dynamic operator [](Object? field) => _data[field];

  @override
  dynamic get(Object? field) => _data[field];

  @override
  bool get exists => true;
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ja');
  });

  group('DisclosureListItem Tests', () {
    testWidgets('会社名・コード・タイトル・時刻・タグが正しく表示されること', (tester) async {
      final doc = FakeDocumentSnapshot({
        'company': 'テスト株式会社',
        'code': '7203',
        'title': '2026年3月期 決算短信〔IFRS〕(連結)',
        'time': 1700000000000,
        'tags': {'決算': true, '適時開示': true},
        'view_count': 42,
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DisclosureListItem(item: doc),
            ),
          ),
        ),
      );

      expect(find.text('テスト株式会社 (7203)'), findsOneWidget);
      expect(find.text('2026年3月期 決算短信〔IFRS〕(連結)'), findsOneWidget);
      expect(find.text('決算'), findsOneWidget);
      expect(find.text('適時開示'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
      expect(find.byType(DisclosureListItem), findsOneWidget);
    });

    testWidgets('null項目があってもクラッシュせず安全に表示されること', (tester) async {
      final doc = FakeDocumentSnapshot({
        'company': null,
        'code': null,
        'title': null,
        'time': null,
        'tags': null,
        'viewCount': null,
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DisclosureListItem(item: doc),
            ),
          ),
        ),
      );

      expect(find.byType(DisclosureListItem), findsOneWidget);
    });
  });
}
