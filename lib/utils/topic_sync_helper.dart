import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// トピック同期処理の結果を表すクラス
class SyncResult {
  /// 新たに購読成功したトピック一覧
  final Set<String> added;

  /// 新たに購読解除成功したトピック一覧
  final Set<String> removed;

  /// 処理中に発生したエラー一覧（トピック名 -> エラー）
  final Map<String, Object> errors;

  /// 現在端末ローカルに保持されている最新の購読トピック一覧
  final Set<String> currentLocalTopics;

  SyncResult({
    required this.added,
    required this.removed,
    required this.errors,
    required this.currentLocalTopics,
  });

  /// エラーが発生したかどうか
  bool get hasErrors => errors.isNotEmpty;

  @override
  String toString() =>
      'SyncResult(added: ${added.length}, removed: ${removed.length}, errors: ${errors.length}, current: ${currentLocalTopics.length})';
}

/// Firestore の最新データ（Desired）と端末の FCM 購読状態（Current）の
/// 結果整合性を担保する差分同期エンジン
class TopicSyncHelper {
  static const String keySubscribedTopics = 'fcm_local_subscribed_topics';
  static const String keyLastSyncedToken = 'fcm_last_synced_token';

  /// FCM の 1 クライアントあたりの最大トピック購読数（Firebase 公式仕様）
  static const int maxTopicsPerDevice = 2000;

  /// 大量購読時の同時並行リクエスト数（FCM レート制限 3,000 QPS への配慮と高速化）
  static const int defaultBatchSize = 10;

  final FirebaseMessaging? _messaging;
  final SharedPreferences? _prefs;
  final int _batchSize;

  final Future<void> Function(String topic)? _onSubscribe;
  final Future<void> Function(String topic)? _onUnsubscribe;

  TopicSyncHelper({
    FirebaseMessaging? messaging,
    SharedPreferences? prefs,
    int batchSize = defaultBatchSize,
    Future<void> Function(String topic)? onSubscribe,
    Future<void> Function(String topic)? onUnsubscribe,
  })  : _messaging = messaging,
        _prefs = prefs,
        _batchSize = batchSize > 0 ? batchSize : defaultBatchSize,
        _onSubscribe = onSubscribe,
        _onUnsubscribe = onUnsubscribe;

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ?? await SharedPreferences.getInstance();
  }

  /// 現在ローカルに記録されている購読トピック一覧を取得
  Future<Set<String>> getLocalSubscribedTopics() async {
    final prefs = await _getPrefs();
    final list = prefs.getStringList(keySubscribedTopics) ?? [];
    return list.toSet();
  }

  /// トークン変更（再インストール、端末データ消去、トークンリフレッシュ）を検知して同期状態を調整
  ///
  /// トークンが変更された場合、FCMサーバー側は購読ゼロになっているため、
  /// ローカルの購読履歴をリセットして全件再登録が必要な状態にします。
  /// 戻り値: トークン変更が発生したかどうか（bool）
  Future<bool> handleTokenChange(String? currentToken) async {
    if (currentToken == null || currentToken.isEmpty) return false;
    final prefs = await _getPrefs();
    final savedToken = prefs.getString(keyLastSyncedToken);

    if (savedToken != currentToken) {
      debugPrint("FCM token changed: reset local subscribed topics");
      await prefs.setStringList(keySubscribedTopics, []);
      await prefs.setString(keyLastSyncedToken, currentToken);
      return true;
    }
    return false;
  }

  /// チャンク分割して並行処理を行うヘルパー
  Future<void> _processInBatches(
    Iterable<String> topics,
    Future<void> Function(String topic) action,
    void Function(String topic) onSuccess,
    void Function(String topic, Object error) onError,
  ) async {
    final list = topics.toList();
    for (var i = 0; i < list.length; i += _batchSize) {
      final end = (i + _batchSize < list.length) ? i + _batchSize : list.length;
      final chunk = list.sublist(i, end);
      await Future.wait(
        chunk.map((topic) async {
          try {
            await action(topic);
            onSuccess(topic);
          } catch (e) {
            onError(topic, e);
          }
        }),
      );
    }
  }

  /// 理想のトピック一覧（desiredTopics）に合わせて端末のFCM購読を差分同期する
  ///
  /// - FCM の最大2,000トピック制限セーフガード
  /// - 10件ずつのチャンク並行処理（FCM レートリミット回避と高速化）
  /// - 追加分 (desired - current): subscribeToTopic()
  /// - 削除分 (current - desired): unsubscribeFromTopic()
  /// - 個別の購読/解除が成功したトピックのみローカルに反映し、失敗したものは次回リトライ
  Future<SyncResult> syncTopics({
    required Set<String> desiredTopics,
  }) async {
    final prefs = await _getPrefs();
    final currentTopics =
        (prefs.getStringList(keySubscribedTopics) ?? []).toSet();

    // 1. FCM 最大トピック数（2,000件）セーフガード
    Set<String> effectiveDesired = desiredTopics;
    if (desiredTopics.length > maxTopicsPerDevice) {
      debugPrint(
          "[TopicSync] Warning: desired topics (${desiredTopics.length}) exceeds FCM limit ($maxTopicsPerDevice). Clipping to $maxTopicsPerDevice.");
      effectiveDesired = desiredTopics.take(maxTopicsPerDevice).toSet();
    }

    final toSubscribe = effectiveDesired.difference(currentTopics);
    final toUnsubscribe = currentTopics.difference(effectiveDesired);

    // 差分ゼロの場合は早期リターン（無駄な通信を完全スキップ）
    if (toSubscribe.isEmpty && toUnsubscribe.isEmpty) {
      debugPrint(
          "[TopicSync] Up to date (all ${currentTopics.length} topics already synced)");
      return SyncResult(
        added: {},
        removed: {},
        errors: {},
        currentLocalTopics: currentTopics,
      );
    }

    debugPrint(
        "[TopicSync] Start sync: +${toSubscribe.length} to subscribe, -${toUnsubscribe.length} to unsubscribe (batch size: $_batchSize)");

    final subscribed = <String>{};
    final unsubscribed = <String>{};
    final errors = <String, Object>{};

    final subscribeFn = _onSubscribe ??
        (topic) async =>
            await (_messaging ?? FirebaseMessaging.instance).subscribeToTopic(topic);
    final unsubscribeFn = _onUnsubscribe ??
        (topic) async =>
            await (_messaging ?? FirebaseMessaging.instance).unsubscribeFromTopic(topic);

    // 2. 削除トピックの解除（Current - Desired）: チャンク並行実行
    await _processInBatches(
      toUnsubscribe,
      unsubscribeFn,
      (topic) {
        unsubscribed.add(topic);
        debugPrint("[TopicSync] Unsubscribed from topic: $topic");
      },
      (topic, e) {
        debugPrint("Failed to unsubscribe from topic $topic: $e");
        errors[topic] = e;
      },
    );

    // 3. 追加トピックの購読（Desired - Current）: チャンク並行実行
    await _processInBatches(
      toSubscribe,
      subscribeFn,
      (topic) {
        subscribed.add(topic);
        debugPrint("[TopicSync] Subscribed to topic: $topic");
      },
      (topic, e) {
        debugPrint("Failed to subscribe to topic $topic: $e");
        errors[topic] = e;
      },
    );

    // 4. 最新のローカル状態を計算:
    // (元のcurrent - 成功したunsubscribe) + 成功したsubscribe
    final newLocalTopics =
        (currentTopics.difference(unsubscribed))..addAll(subscribed);
    await prefs.setStringList(
        keySubscribedTopics, newLocalTopics.toList()..sort());

    if (subscribed.isNotEmpty || unsubscribed.isNotEmpty) {
      debugPrint(
          "[TopicSync] Sync completed: added=${subscribed.toList()}, removed=${unsubscribed.toList()}, totalCurrent=${newLocalTopics.length}");
    }

    return SyncResult(
      added: subscribed,
      removed: unsubscribed,
      errors: errors,
      currentLocalTopics: newLocalTopics,
    );
  }
}
