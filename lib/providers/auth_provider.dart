import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_provider.g.dart';

/// Firebase Authentication の認証状態（ログインユーザー）を監視する Provider
/// アプリ全体で共有するため常駐（keepAlive: true）とする
@Riverpod(keepAlive: true)
Stream<User?> authState(Ref ref) {
  if (Firebase.apps.isEmpty) {
    return Stream.value(null);
  }
  return FirebaseAuth.instance.userChanges();
}

/// 現在ログイン中のユーザーを同期的に取得・監視できる Provider
@Riverpod(keepAlive: true)
User? currentUser(Ref ref) {
  final authUser = ref.watch(authStateProvider).value;
  if (authUser != null) return authUser;
  if (Firebase.apps.isNotEmpty) {
    return FirebaseAuth.instance.currentUser;
  }
  return null;
}
