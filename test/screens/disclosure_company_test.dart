import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:disclosure_app_fl/models/company.dart';
import 'package:disclosure_app_fl/models/company_settlement.dart';
import 'package:disclosure_app_fl/models/edinet.dart';
import 'package:disclosure_app_fl/providers/auth_provider.dart';
import 'package:disclosure_app_fl/providers/company_disclosures_provider.dart';
import 'package:disclosure_app_fl/providers/company_provider.dart';
import 'package:disclosure_app_fl/providers/favorites_provider.dart';
import 'package:disclosure_app_fl/providers/saved_disclosures_provider.dart';
import 'package:disclosure_app_fl/screens/disclosure_company.dart';
import 'package:disclosure_app_fl/widgets/no_disclosures.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

class MockUser extends Fake implements User {
  @override
  String get uid => 'test_uid_disclosure';
}

class MockFavoritesAction extends FavoritesAction {
  final List<(String, String, bool)> toggled = [];

  @override
  void build() {}

  @override
  Future<void> toggle(String uid, String code, {required bool isFavorite}) async {
    toggled.add((uid, code, isFavorite));
  }
}

// ignore: subtype_of_sealed_class
class FakeDocumentSnapshot extends Fake
    implements DocumentSnapshot<Map<String, dynamic>> {
  final Map<String, dynamic> _data;
  final String _id;

  FakeDocumentSnapshot(this._id, this._data);

  @override
  String get id => _id;

  @override
  Map<String, dynamic> data() => _data;

  @override
  dynamic operator [](Object? key) => _data[key];

  @override
  bool get exists => true;
}

class FakeCompanyDisclosures extends CompanyDisclosures {
  final Future<PaginatedDisclosuresState> Function() _buildFn;
  FakeCompanyDisclosures(PaginatedDisclosuresState stateToReturn)
      : _buildFn = (() async => stateToReturn);
  FakeCompanyDisclosures.loading()
      : _buildFn = (() => Completer<PaginatedDisclosuresState>().future);
  FakeCompanyDisclosures.error(Object error)
      : _buildFn = (() => Future.error(error));

  @override
  Future<PaginatedDisclosuresState> build(String code) => _buildFn();
}

class FakeCompanyEdinets extends CompanyEdinets {
  final Future<PaginatedEdinetsState> Function() _buildFn;
  FakeCompanyEdinets(PaginatedEdinetsState stateToReturn)
      : _buildFn = (() async => stateToReturn);
  FakeCompanyEdinets.loading()
      : _buildFn = (() => Completer<PaginatedEdinetsState>().future);
  FakeCompanyEdinets.error(Object error)
      : _buildFn = (() => Future.error(error));

  @override
  Future<PaginatedEdinetsState> build(String edinetCode) => _buildFn();
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ja');
  });

  Widget createTestWidget({
    required Company? company,
    List overrides = const [],
    PaginatedDisclosuresState? disclosuresState,
    CompanyDisclosures Function()? disclosuresBuilder,
    CompanySettlement? settlement,
    PaginatedEdinetsState? edinetsState,
    CompanyEdinets Function()? edinetsBuilder,
  }) {
    final code = company?.code ?? '';
    final edinetCode = company?.edinetCode ?? '';

    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWith((ref) => MockUser()),
        savedDisclosuresStreamProvider.overrideWith((ref) => Stream.value([])),
        if (code.isNotEmpty) ...[
          companySettlementProvider(code)
              .overrideWith((ref) => Future.value(settlement)),
          companyDisclosuresProvider(code).overrideWith(
            disclosuresBuilder ??
                () => FakeCompanyDisclosures(
                    disclosuresState ?? const PaginatedDisclosuresState(docs: [])),
          ),
        ],
        if (edinetCode.isNotEmpty) ...[
          companyEdinetsProvider(edinetCode).overrideWith(
            edinetsBuilder ??
                () => FakeCompanyEdinets(
                    edinetsState ?? const PaginatedEdinetsState(items: [])),
          ),
        ],
        ...overrides.cast(),
      ],
      child: MaterialApp(
        home: DisclosureCompanyScreen(company: company),
      ),
    );
  }

  group('タイトルバーの表示', () {
    testWidgets('企業名とコードがある場合は「企業名 (コード)」が表示される',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        company: Company('7203', name: 'トヨタ自動車'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('トヨタ自動車 (7203)'), findsOneWidget);
    });

    testWidgets('企業名のみの場合は企業名が表示される', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        company: Company(null, name: 'トヨタ自動車'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('トヨタ自動車'), findsOneWidget);
    });

    testWidgets('コードのみの場合はコードが表示される', (WidgetTester tester) async {
      final comp = Company('7203', name: '');
      await tester.pumpWidget(createTestWidget(company: comp));
      await tester.pumpAndSettle();

      expect(find.text('7203'), findsOneWidget);
    });

    testWidgets('企業情報がない場合は「会社詳細」が表示される', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(company: null));
      await tester.pumpAndSettle();

      expect(find.text('会社詳細'), findsOneWidget);
    });
  });

  group('タブ表示', () {
    testWidgets('edinetCode がない場合は TDNET タブのみ表示される',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        company: Company('7203', name: 'トヨタ自動車'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('TDNET'), findsOneWidget);
      expect(find.text('EDINET'), findsNothing);
    });

    testWidgets('edinetCode がある場合は TDNET と EDINET タブが表示される',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        company: Company('7203', name: 'トヨタ自動車', edinetCode: 'E02144'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('TDNET'), findsOneWidget);
      expect(find.text('EDINET'), findsOneWidget);
    });
  });

  group('お気に入り星アイコン', () {
    testWidgets('お気に入り未登録時は枠線星アイコンが表示され、タップでお気に入り追加される',
        (WidgetTester tester) async {
      final mockFavoritesAction = MockFavoritesAction();

      await tester.pumpWidget(createTestWidget(
        company: Company('7203', name: 'トヨタ自動車'),
        overrides: [
          isFavoriteProvider('7203').overrideWithValue(false),
          favoritesActionProvider.overrideWith(() => mockFavoritesAction),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.star_border), findsOneWidget);

      await tester.tap(find.byIcon(Icons.star_border));
      await tester.pumpAndSettle();

      expect(mockFavoritesAction.toggled.length, 1);
      expect(mockFavoritesAction.toggled.first,
          ('test_uid_disclosure', '7203', false));
      expect(find.text('お気に入りに追加しました'), findsOneWidget);
    });

    testWidgets('お気に入り登録済み時は塗りつぶし星アイコンが表示され、タップでお気に入り解除される',
        (WidgetTester tester) async {
      final mockFavoritesAction = MockFavoritesAction();

      await tester.pumpWidget(createTestWidget(
        company: Company('7203', name: 'トヨタ自動車'),
        overrides: [
          isFavoriteProvider('7203').overrideWithValue(true),
          favoritesActionProvider.overrideWith(() => mockFavoritesAction),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.star), findsOneWidget);

      await tester.tap(find.byIcon(Icons.star));
      await tester.pumpAndSettle();

      expect(mockFavoritesAction.toggled.length, 1);
      expect(mockFavoritesAction.toggled.first,
          ('test_uid_disclosure', '7203', true));
      expect(find.text('お気に入りを解除しました'), findsOneWidget);
    });
  });

  group('決算予告カード', () {
    testWidgets('直近の決算発表予定がある場合、アナウンスカードが表示される',
        (WidgetTester tester) async {
      final futureDate = DateTime.now().add(const Duration(days: 7));
      final settlement = CompanySettlement(
        schedule: futureDate,
        quote: '第2四半期決算',
        name: 'トヨタ自動車',
        code: '7203',
      );

      final fakeDoc = FakeDocumentSnapshot('doc1', {
        'document': 'doc1',
        'company': 'トヨタ自動車',
        'code': '7203',
        'title': '決算短信',
        'time': 123456789,
      });

      await tester.pumpWidget(createTestWidget(
        company: Company('7203', name: 'トヨタ自動車'),
        settlement: settlement,
        disclosuresState: PaginatedDisclosuresState(docs: [fakeDoc]),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.announcement), findsOneWidget);
      expect(find.text(settlement.toMessage()), findsOneWidget);
    });

    testWidgets('過去の決算発表予定（1日以上前）の場合はアナウンスカードが表示されない',
        (WidgetTester tester) async {
      final pastDate = DateTime.now().subtract(const Duration(days: 2));
      final settlement = CompanySettlement(
        schedule: pastDate,
        quote: '第1四半期決算',
        name: 'トヨタ自動車',
        code: '7203',
      );

      final fakeDoc = FakeDocumentSnapshot('doc1', {
        'document': 'doc1',
        'company': 'トヨタ自動車',
        'code': '7203',
        'title': '適時開示情報',
        'time': 123456789,
      });

      await tester.pumpWidget(createTestWidget(
        company: Company('7203', name: 'トヨタ自動車'),
        settlement: settlement,
        disclosuresState: PaginatedDisclosuresState(docs: [fakeDoc]),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.announcement), findsNothing);
    });

    testWidgets('決算発表予定がない場合はアナウンスカードが表示されない',
        (WidgetTester tester) async {
      final fakeDoc = FakeDocumentSnapshot('doc1', {
        'document': 'doc1',
        'company': 'トヨタ自動車',
        'code': '7203',
        'title': '適時開示情報',
        'time': 123456789,
      });

      await tester.pumpWidget(createTestWidget(
        company: Company('7203', name: 'トヨタ自動車'),
        settlement: null,
        disclosuresState: PaginatedDisclosuresState(docs: [fakeDoc]),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.announcement), findsNothing);
    });
  });

  group('開示情報リストとページネーション', () {
    testWidgets('開示情報取得中は LinearProgressIndicator が表示される',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        company: Company('7203', name: 'トヨタ自動車'),
        disclosuresBuilder: () => FakeCompanyDisclosures.loading(),
      ));
      await tester.pump();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('開示情報取得失敗時はエラーUIが表示される',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        company: Company('7203', name: 'トヨタ自動車'),
        disclosuresBuilder: () => FakeCompanyDisclosures.error(Exception('Firestore error')),
      ));
      await tester.pumpAndSettle();

      expect(find.text('開示情報の取得に失敗しました'), findsOneWidget);
    });

    testWidgets('開示情報が0件の場合は NoDisclosures が表示される',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        company: Company('7203', name: 'トヨタ自動車'),
        disclosuresState: const PaginatedDisclosuresState(docs: []),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(NoDisclosures), findsOneWidget);
    });

    testWidgets('開示情報が存在し hasMore: true の場合は「更に読み込む」ボタンが表示される',
        (WidgetTester tester) async {
      final fakeDoc = FakeDocumentSnapshot('doc1', {
        'document': 'doc1',
        'company': 'トヨタ自動車',
        'code': '7203',
        'title': '業績予想の修正に関するお知らせ',
        'time': 123456789,
      });

      await tester.pumpWidget(createTestWidget(
        company: Company('7203', name: 'トヨタ自動車'),
        disclosuresState:
            PaginatedDisclosuresState(docs: [fakeDoc], hasMore: true),
      ));
      await tester.pumpAndSettle();

      expect(find.text('業績予想の修正に関するお知らせ'), findsOneWidget);
      expect(find.text('更に読み込む'), findsOneWidget);
    });

    testWidgets('isLoadingMore: true の場合はプログレスインジケータが表示されボタンが無効化される',
        (WidgetTester tester) async {
      final fakeDoc = FakeDocumentSnapshot('doc1', {
        'document': 'doc1',
        'company': 'トヨタ自動車',
        'code': '7203',
        'title': '開示タイトル',
        'time': 123456789,
      });

      await tester.pumpWidget(createTestWidget(
        company: Company('7203', name: 'トヨタ自動車'),
        disclosuresState: PaginatedDisclosuresState(
          docs: [fakeDoc],
          hasMore: true,
          isLoadingMore: true,
        ),
      ));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('hasMore: false の場合は「更に読み込む」ボタンが表示されない',
        (WidgetTester tester) async {
      final fakeDoc = FakeDocumentSnapshot('doc1', {
        'document': 'doc1',
        'company': 'トヨタ自動車',
        'code': '7203',
        'title': '自己株式の取得に関するお知らせ',
        'time': 123456789,
      });

      await tester.pumpWidget(createTestWidget(
        company: Company('7203', name: 'トヨタ自動車'),
        disclosuresState:
            PaginatedDisclosuresState(docs: [fakeDoc], hasMore: false),
      ));
      await tester.pumpAndSettle();

      expect(find.text('自己株式の取得に関するお知らせ'), findsOneWidget);
      expect(find.text('更に読み込む'), findsNothing);
    });
  });

  group('EDINET タブの表示', () {
    testWidgets('EDINET 開示情報取得中は LinearProgressIndicator が表示される',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        company: Company('7203', name: 'トヨタ自動車', edinetCode: 'E02144'),
        edinetsBuilder: () => FakeCompanyEdinets.loading(),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('EDINET'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('EDINET 開示情報取得失敗時はエラーUIが表示される',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        company: Company('7203', name: 'トヨタ自動車', edinetCode: 'E02144'),
        edinetsBuilder: () =>
            FakeCompanyEdinets.error(Exception('Edinet fetch error')),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('EDINET'));
      await tester.pumpAndSettle();

      expect(find.text('EDINET開示の取得に失敗しました'), findsOneWidget);
    });

    testWidgets('EDINET 開示情報が0件の場合は空メッセージが表示される',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        company: Company('7203', name: 'トヨタ自動車', edinetCode: 'E02144'),
        edinetsState: const PaginatedEdinetsState(items: []),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('EDINET'));
      await tester.pumpAndSettle();

      expect(find.text('選択した条件の適時開示は0件です'), findsOneWidget);
    });

    testWidgets('EDINET タブで開示文書一覧が表示される', (WidgetTester tester) async {
      final edinet = Edinet(
        docDescription: '有価証券報告書（第80期）',
        docId: 'S100TEST',
        filerName: 'トヨタ自動車',
        time: 123456789,
        edinetCode: 'E02144',
      );

      await tester.pumpWidget(createTestWidget(
        company: Company('7203', name: 'トヨタ自動車', edinetCode: 'E02144'),
        edinetsState:
            PaginatedEdinetsState(items: [edinet], hasMore: false),
      ));
      await tester.pumpAndSettle();

      // EDINET タブをタップして切り替える
      await tester.tap(find.text('EDINET'));
      await tester.pumpAndSettle();

      expect(find.text('有価証券報告書（第80期）'), findsOneWidget);
    });

    testWidgets('EDINET で hasMore: true の場合は「更に読み込む」ボタンが表示される',
        (WidgetTester tester) async {
      final edinet = Edinet(
        docDescription: '大量保有報告書',
        docId: 'S100TEST2',
        filerName: 'トヨタ自動車',
        time: 123456789,
        edinetCode: 'E02144',
      );

      await tester.pumpWidget(createTestWidget(
        company: Company('7203', name: 'トヨタ自動車', edinetCode: 'E02144'),
        edinetsState:
            PaginatedEdinetsState(items: [edinet], hasMore: true),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('EDINET'));
      await tester.pumpAndSettle();

      expect(find.text('大量保有報告書'), findsOneWidget);
      expect(find.text('更に読み込む'), findsOneWidget);
    });

    testWidgets('EDINET で isLoadingMore: true の場合はプログレスインジケータが表示されボタンが無効化される',
        (WidgetTester tester) async {
      final edinet = Edinet(
        docDescription: '臨時報告書',
        docId: 'S100TEST3',
        filerName: 'トヨタ自動車',
        time: 123456789,
        edinetCode: 'E02144',
      );

      await tester.pumpWidget(createTestWidget(
        company: Company('7203', name: 'トヨタ自動車', edinetCode: 'E02144'),
        edinetsState: PaginatedEdinetsState(
          items: [edinet],
          hasMore: true,
          isLoadingMore: true,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('EDINET'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('渡された Company の edinetCode が空でもマスタ（companyCodeMapProvider）に存在すれば EDINET タブが表示される',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        company: Company('7203', name: 'トヨタ自動車'), // edinetCode は空
        overrides: [
          companyCodeMapProvider.overrideWith((ref) => {
                '7203': Company('7203', name: 'トヨタ自動車', edinetCode: 'E02144'),
              }),
          companyEdinetsProvider('E02144').overrideWith(
            () => FakeCompanyEdinets(const PaginatedEdinetsState(items: [])),
          ),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('EDINET'), findsOneWidget);
    });
  });
}
