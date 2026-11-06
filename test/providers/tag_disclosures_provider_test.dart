import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:disclosure_app_fl/providers/tag_disclosures_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ignore: subtype_of_sealed_class
class FakeDocumentSnapshot extends Fake
    implements QueryDocumentSnapshot<Map<String, dynamic>> {
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

// ignore: subtype_of_sealed_class
class FakeQuerySnapshot extends Fake
    implements QuerySnapshot<Map<String, dynamic>> {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> _docs;

  FakeQuerySnapshot(this._docs);

  @override
  List<QueryDocumentSnapshot<Map<String, dynamic>>> get docs => _docs;

  @override
  int get size => _docs.length;
}

// ignore: subtype_of_sealed_class
class FakeQuery extends Fake implements Query<Map<String, dynamic>> {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> results;

  FakeQuery(List<QueryDocumentSnapshot<Map<String, dynamic>>> results)
      : results = List.from(results);

  @override
  Query<Map<String, dynamic>> where(
    Object field, {
    Object? isEqualTo,
    Object? isNotEqualTo,
    Object? isLessThan,
    Object? isLessThanOrEqualTo,
    Object? isGreaterThan,
    Object? isGreaterThanOrEqualTo,
    Object? arrayContains,
    Iterable<Object?>? arrayContainsAny,
    Iterable<Object?>? whereIn,
    Iterable<Object?>? whereNotIn,
    bool? isNull,
  }) {
    return this;
  }

  @override
  Query<Map<String, dynamic>> orderBy(Object field, {bool descending = false}) {
    return this;
  }

  @override
  Query<Map<String, dynamic>> limit(int limit) {
    return this;
  }

  @override
  Query<Map<String, dynamic>> startAfterDocument(
      DocumentSnapshot<Object?> documentSnapshot) {
    return this;
  }

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get(
      [GetOptions? options]) async {
    return FakeQuerySnapshot(List.from(results));
  }
}

// ignore: subtype_of_sealed_class
class FakeCollectionReference extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  final FakeQuery query;

  FakeCollectionReference(this.query);

  @override
  Query<Map<String, dynamic>> where(
    Object field, {
    Object? isEqualTo,
    Object? isNotEqualTo,
    Object? isLessThan,
    Object? isLessThanOrEqualTo,
    Object? isGreaterThan,
    Object? isGreaterThanOrEqualTo,
    Object? arrayContains,
    Iterable<Object?>? arrayContainsAny,
    Iterable<Object?>? whereIn,
    Iterable<Object?>? whereNotIn,
    bool? isNull,
  }) {
    return query.where(field, arrayContains: arrayContains);
  }
}

// ignore: subtype_of_sealed_class
class FakeFirestore extends Fake implements FirebaseFirestore {
  final FakeQuery query;

  FakeFirestore(this.query);

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    return FakeCollectionReference(query);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TagDisclosures Notifier Tests', () {
    test('空文字のタグを渡した場合、即座に空のリストと hasMore: false を返す', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = await container.read(tagDisclosuresProvider('').future);

      expect(state.docs, isEmpty);
      expect(state.hasMore, isFalse);
      expect(state.isLoadingMore, isFalse);
    });

    test('空白文字のみのタグを渡した場合、空のリストを返す', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = await container.read(tagDisclosuresProvider('   ').future);

      expect(state.docs, isEmpty);
      expect(state.hasMore, isFalse);
    });

    test('初回取得でpageSize未満の件数だった場合、hasMore は false になる', () async {
      final fakeDocs = [
        FakeDocumentSnapshot('doc1', {'title': '開示1', 'time': 1000}),
        FakeDocumentSnapshot('doc2', {'title': '開示2', 'time': 2000}),
      ];
      final fakeFirestore = FakeFirestore(FakeQuery(fakeDocs));

      final container = ProviderContainer(
        overrides: [
          tagDisclosuresFirestoreProvider.overrideWithValue(fakeFirestore),
        ],
      );
      addTearDown(container.dispose);

      final state = await container.read(tagDisclosuresProvider('決算').future);

      expect(state.docs.length, 2);
      expect(state.docs[0].id, 'doc1');
      expect(state.docs[1].id, 'doc2');
      expect(state.hasMore, isFalse); // 2件 < 20件
      expect(state.isLoadingMore, isFalse);
    });

    test('初回取得でpageSize以上の件数だった場合、hasMore は true になる', () async {
      final fakeDocs = List.generate(
        20,
        (i) => FakeDocumentSnapshot('doc$i', {'title': '開示$i', 'time': i}),
      );
      final fakeFirestore = FakeFirestore(FakeQuery(fakeDocs));

      final container = ProviderContainer(
        overrides: [
          tagDisclosuresFirestoreProvider.overrideWithValue(fakeFirestore),
        ],
      );
      addTearDown(container.dispose);

      final state = await container.read(tagDisclosuresProvider('業績予想').future);

      expect(state.docs.length, 20);
      expect(state.hasMore, isTrue); // 20件 >= 20件
    });

    test('loadMore: 次ページが正常に追加蓄積されること', () async {
      final initialDocs = List.generate(
        20,
        (i) => FakeDocumentSnapshot('doc$i', {'title': '開示$i', 'time': i}),
      );
      final nextDocs = [
        FakeDocumentSnapshot('doc20', {'title': '開示20', 'time': 20}),
      ];

      // 初期取得用クエリ
      final fakeQuery = FakeQuery(initialDocs);
      final fakeFirestore = FakeFirestore(fakeQuery);

      final container = ProviderContainer(
        overrides: [
          tagDisclosuresFirestoreProvider.overrideWithValue(fakeFirestore),
        ],
      );
      addTearDown(container.dispose);

      // 初回ロード
      final initial =
          await container.read(tagDisclosuresProvider('配当').future);
      expect(initial.docs.length, 20);
      expect(initial.hasMore, isTrue);

      // 次ページ結果に差し替え
      fakeQuery.results.clear();
      fakeQuery.results.addAll(nextDocs);

      // loadMore 実行
      await container.read(tagDisclosuresProvider('配当').notifier).loadMore();

      final updated = container.read(tagDisclosuresProvider('配当')).value!;
      expect(updated.docs.length, 21);
      expect(updated.docs.last.id, 'doc20');
      expect(updated.hasMore, isFalse); // 1件 < 20件なので hasMore は false
    });

    test('hasMore が false の場合、loadMore を呼んでも追加リクエストは実行されない', () async {
      final initialDocs = [
        FakeDocumentSnapshot('doc1', {'title': '開示1', 'time': 1000}),
      ];
      final fakeQuery = FakeQuery(initialDocs);
      final fakeFirestore = FakeFirestore(fakeQuery);

      final container = ProviderContainer(
        overrides: [
          tagDisclosuresFirestoreProvider.overrideWithValue(fakeFirestore),
        ],
      );
      addTearDown(container.dispose);

      await container.read(tagDisclosuresProvider('新製品').future);

      // loadMore を実行
      await container.read(tagDisclosuresProvider('新製品').notifier).loadMore();

      final state = container.read(tagDisclosuresProvider('新製品')).value!;
      expect(state.docs.length, 1);
    });

    test('refresh: 状態が再取得されること', () async {
      final initialDocs = [
        FakeDocumentSnapshot('doc1', {'title': '開示1', 'time': 1000}),
      ];
      final fakeQuery = FakeQuery(initialDocs);
      final fakeFirestore = FakeFirestore(fakeQuery);

      final container = ProviderContainer(
        overrides: [
          tagDisclosuresFirestoreProvider.overrideWithValue(fakeFirestore),
        ],
      );
      addTearDown(container.dispose);

      await container.read(tagDisclosuresProvider('自社株買い').future);

      // 新しいデータに差し替え
      final refreshedDocs = [
        FakeDocumentSnapshot('doc_new', {'title': '新着開示', 'time': 2000}),
        FakeDocumentSnapshot('doc1', {'title': '開示1', 'time': 1000}),
      ];
      fakeQuery.results.clear();
      fakeQuery.results.addAll(refreshedDocs);

      // refresh 実行
      await container.read(tagDisclosuresProvider('自社株買い').notifier).refresh();

      final state =
          container.read(tagDisclosuresProvider('自社株買い')).value!;
      expect(state.docs.length, 2);
      expect(state.docs.first.id, 'doc_new');
    });
  });
}
