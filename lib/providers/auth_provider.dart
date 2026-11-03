import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_provider.g.dart';

/// Firebase Authentication のストリームを監視する内部用 Provider
@Riverpod(keepAlive: true)
Stream<User?> _authState(Ref ref) {
  if (Firebase.apps.isEmpty) {
    return Stream.value(null);
  }
  return FirebaseAuth.instance.userChanges();
}

/// 現在ログイン中のユーザーを同期的に取得・監視できる公開 Provider
@Riverpod(keepAlive: true)
User? currentUser(Ref ref) {
  final authUser = ref.watch(_authStateProvider).value;
  if (authUser != null) return authUser;
  if (Firebase.apps.isNotEmpty) {
    return FirebaseAuth.instance.currentUser;
  }
  return null;
}
