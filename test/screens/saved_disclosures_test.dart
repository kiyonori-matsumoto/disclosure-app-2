import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:disclosure_app_fl/providers/saved_disclosures_provider.dart';
import 'package:disclosure_app_fl/screens/saved_disclosures.dart';
import 'package:disclosure_app_fl/widgets/dismissible_delete_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

// ignore: subtype_of_sealed_class
class FakeQueryDocumentSnapshot extends Fake
    implements QueryDocumentSnapshot<Map<String, dynamic>> {
  final Map<String, dynamic> _data;
  final String _id;

  FakeQueryDocumentSnapshot(this._data, [this._id = 'test_id']);

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

  group('SavedDisclosuresScreen Tests', () {
    testWidgets('保存済みドキュメントが空の場合、空メッセージが表示される', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            savedDisclosuresStreamProvider.overrideWith(
              (ref) => Stream.value([]),
            ),
          ],
          child: const MaterialApp(
            home: SavedDisclosuresScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('保存されたドキュメントはありません'), findsOneWidget);
    });

    testWidgets('データが存在する場合、リストが表示されDismissibleDeleteBackgroundが使われていること',
        (tester) async {
      final fakeDoc = FakeQueryDocumentSnapshot({
        'company': 'テスト株式会社',
        'code': '7203',
        'title': '決算短信',
        'time': 1700000000000,
        'document': 'test_doc_1',
        'add_at': 1700000000000,
      }, 'test_doc_1');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            savedDisclosuresStreamProvider.overrideWith(
              (ref) => Stream.value([fakeDoc]),
            ),
          ],
          child: const MaterialApp(
            home: SavedDisclosuresScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('テスト株式会社'), findsOneWidget);
      expect(find.byType(Dismissible), findsOneWidget);
      final dismissible = tester.widget<Dismissible>(find.byType(Dismissible));
      expect(dismissible.background, isA<DismissibleDeleteBackground>());
      expect(dismissible.secondaryBackground, isA<DismissibleDeleteBackground>());
    });
  });
}
