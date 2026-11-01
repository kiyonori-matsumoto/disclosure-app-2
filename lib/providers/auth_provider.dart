import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_provider.g.dart';

/// Firebase Authentication の認証状態（ログインユーザー）を監視する Provider
@riverpod
Stream<User?> authState(Ref ref) {
  return FirebaseAuth.instance.userChanges();
}
