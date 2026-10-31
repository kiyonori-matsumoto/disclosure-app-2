import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// 認証関連の処理（GoogleSignIn / FirebaseAuth）を集約したヘルパークラス
class AuthHelper {
  final GoogleSignIn? _googleSignIn;
  final FirebaseAuth? _firebaseAuth;
  final User? Function()? _currentUserGetter;

  AuthHelper({
    GoogleSignIn? googleSignIn,
    FirebaseAuth? firebaseAuth,
    User? Function()? currentUserGetter,
  })  : _googleSignIn = googleSignIn,
        _firebaseAuth = firebaseAuth,
        _currentUserGetter = currentUserGetter;

  GoogleSignIn get googleSignIn => _googleSignIn ?? GoogleSignIn.instance;
  FirebaseAuth get firebaseAuth => _firebaseAuth ?? FirebaseAuth.instance;
  User? get currentUser {
    if (_currentUserGetter != null) return _currentUserGetter!();
    final auth = _firebaseAuth;
    if (auth != null) return auth.currentUser;
    if (Firebase.apps.isNotEmpty) return FirebaseAuth.instance.currentUser;
    return null;
  }

  /// Google ID Token から Firebase AuthCredential を生成する
  static AuthCredential createGoogleCredential({required String? idToken}) {
    return GoogleAuthProvider.credential(idToken: idToken);
  }

  /// 既存プロバイダ一覧に google.com が含まれているかを判定する
  static bool hasGoogleProvider(List<String> signInMethods) {
    return signInMethods.contains('google.com');
  }

  /// アプリ起動時の認証初期化処理
  ///
  /// すでにログイン中（Firebaseのセッションが保持されている）の場合は何もしない。
  /// 未ログインの場合のみ匿名サインインを実行する。
  /// ※ google_sign_in v7 の attemptLightweightAuthentication() は
  ///   起動時に毎回アカウント選択UIを表示してしまうため、
  ///   起動時は自動で呼ばず設定画面での明示的な操作のみとする。
  Future<void> initializeAuth({
    Future<void> Function(AuthCredential credential)? onSignInWithCredential,
    Future<void> Function()? onSignInAnonymously,
  }) async {
    if (currentUser != null) {
      debugPrint("User already authenticated: ${currentUser?.uid}");
      return;
    }

    final signInAnonymously = onSignInAnonymously ??
        () async => await firebaseAuth.signInAnonymously();

    try {
      await signInAnonymously();
      debugPrint("Signed in anonymously");
    } catch (e) {
      debugPrint("Anonymous sign in error: $e");
    }
  }

  /// Google アカウントの連携・サインイン処理
  ///
  /// Google認証を行い、既存のGoogle連携済みアカウントがあればサインイン、
  /// なければ現在のユーザーに連携（link）する。
  Future<User?> handleGoogleSignIn({
    Future<List<String>> Function(String email)? onFetchSignInMethods,
    Future<User?> Function(AuthCredential credential)? onSignInWithCredential,
    Future<User?> Function(AuthCredential credential)? onLinkWithCredential,
    Future<void> Function(User user)? onReloadUser,
  }) async {
    final fetchMethods = onFetchSignInMethods ??
        (email) => firebaseAuth.fetchSignInMethodsForEmail(email);
    final signInWithCred = onSignInWithCredential ??
        (cred) async {
          final res = await firebaseAuth.signInWithCredential(cred);
          return res.user;
        };
    final linkWithCred = onLinkWithCredential ??
        (cred) async {
          final currentUser = firebaseAuth.currentUser;
          if (currentUser != null) {
            final res = await currentUser.linkWithCredential(cred);
            return res.user;
          } else {
            final res = await firebaseAuth.signInWithCredential(cred);
            return res.user;
          }
        };
    final reloadUser = onReloadUser ??
        (user) async {
          await user.reload();
        };

    try {
      final googleUser = await googleSignIn.authenticate();
      final googleAuth = googleUser.authentication;
      final credential = createGoogleCredential(idToken: googleAuth.idToken);
      final providers = await fetchMethods(googleUser.email);

      User? user;
      if (hasGoogleProvider(providers)) {
        user = await signInWithCred(credential);
      } else {
        try {
          user = await linkWithCred(credential);
        } on FirebaseAuthException catch (e) {
          if (e.code == 'credential-already-in-use') {
            debugPrint("Credential already in use, signing in instead");
            user = await signInWithCred(credential);
          } else {
            rethrow;
          }
        }
      }

      if (user != null) {
        await reloadUser(user);
      }
      return user;
    } catch (e) {
      debugPrint("Handle Google sign in error: $e");
      return null;
    }
  }
}
