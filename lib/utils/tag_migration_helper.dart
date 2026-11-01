import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:disclosure_app_fl/utils/notification_topic_helper.dart';

/// 過去の FCM トピック (listTopicsV2) から Firestore (notification_tags) への
/// タグ通知マイグレーションを行うヘルパー
class TagMigrationHelper {
  static const String defaultListTopicsUrl =
      'https://asia-northeast1-disclosure-app.cloudfunctions.net/listTopicsV2';

  final http.Client? _httpClient;
  final String _listTopicsUrl;
  final Future<Map<String, dynamic>?> Function(String uid)? _onGetUserDoc;
  final Future<void> Function(String uid, List<String> tags)? _onSaveTags;

  TagMigrationHelper({
    http.Client? httpClient,
    String? listTopicsUrl,
    Future<Map<String, dynamic>?> Function(String uid)? onGetUserDoc,
    Future<void> Function(String uid, List<String> tags)? onSaveTags,
  })  : _httpClient = httpClient,
        _listTopicsUrl = listTopicsUrl ?? defaultListTopicsUrl,
        _onGetUserDoc = onGetUserDoc,
        _onSaveTags = onSaveTags;

  http.Client get _http => _httpClient ?? http.Client();

  Future<Map<String, dynamic>?> _getUserDoc(String uid) async {
    if (_onGetUserDoc != null) {
      return await _onGetUserDoc!(uid);
    }
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.data();
  }

  Future<void> _saveTags(String uid, List<String> tags) async {
    if (_onSaveTags != null) {
      await _onSaveTags!(uid, tags);
      return;
    }
    await FirebaseFirestore.instance.collection('users').doc(uid).set(
      {'notification_tags': tags},
      SetOptions(merge: true),
    );
  }

  /// ユーザーの Firestore ドキュメントを確認し、未マイグレーションであれば 1 度だけ
  /// listTopicsV2 を呼び出して購読タグを Firestore に移行する。
  ///
  /// - `userDocData` に 'notification_tags' が存在する場合は移行済みとみなし HTTP 通信を行わない。
  /// - 未存在の場合は listTopicsV2 を呼び出し、タグ一覧を Firestore に書き込む。
  /// - 通信エラーやレスポンス不正時は空リスト [] を書き込んでマイグレーション完了扱いとし、
  ///   二度と listTopicsV2 を呼ばないようにする。
  Future<List<String>> ensureTagsMigrated({
    required String uid,
    String? fcmToken,
    Map<String, dynamic>? userDocData,
  }) async {
    // 1. すでに Firestore に notification_tags フィールドが存在する場合はマイグレーション不要
    if (userDocData != null && userDocData.containsKey('notification_tags')) {
      final tags = userDocData['notification_tags'];
      if (tags is List) {
        return tags.map((e) => e.toString()).toList();
      }
      return [];
    }

    // userDocData が渡されなかった場合は Firestore から最新を取得して確認
    if (userDocData == null) {
      try {
        final data = await _getUserDoc(uid);
        if (data != null && data.containsKey('notification_tags')) {
          final tags = data['notification_tags'];
          if (tags is List) {
            return tags.map((e) => e.toString()).toList();
          }
          return [];
        }
      } catch (e) {
        debugPrint("Failed to fetch user doc for tag migration check: $e");
      }
    }

    // 2. 未マイグレーションのため、listTopicsV2 からタグ情報を取得
    final migratedTags = <String>[];
    if (fcmToken != null && fcmToken.isNotEmpty) {
      try {
        final response = await _http.post(
          Uri.parse(_listTopicsUrl),
          body: json.encode({'IID_TOKEN': fcmToken}),
          headers: {'Content-Type': 'application/json'},
        ).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200 && response.body.isNotEmpty) {
          final data = json.decode(response.body);
          if (data is Map<String, dynamic> && data['topics'] is Map) {
            final topicsMap = data['topics'] as Map<String, dynamic>;
            for (final topic in topicsMap.keys) {
              if (NotificationTopicHelper.isTagTopic(topic)) {
                try {
                  migratedTags.add(NotificationTopicHelper.toTag(topic));
                } catch (e) {
                  debugPrint("Failed to decode tag topic $topic: $e");
                }
              }
            }
          }
        }
      } catch (e) {
        debugPrint("listTopicsV2 failed during migration (fallback to empty): $e");
      }
    }

    // 3. Firestore に保存してマイグレーションを完了（次回以降 HTTP を呼ばないようにする）
    try {
      await _saveTags(uid, migratedTags);
      debugPrint("Tag migration completed for uid=$uid with ${migratedTags.length} tags");
    } catch (e) {
      debugPrint("Failed to save migrated tags to Firestore: $e");
    }

    return migratedTags;
  }
}
