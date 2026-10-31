import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// 認証関連の処理（GoogleSignIn / FirebaseAuth）を集約したヘルパークラス
class AuthHelper {
  final GoogleSignIn? _googleSignIn;
  final FirebaseAuth? _firebaseAuth;

  AuthHelper({
    GoogleSignIn? googleSignIn,
    FirebaseAuth? firebaseAuth,
  })  : _googleSignIn = googleSignIn,
        _firebaseAuth = firebaseAuth;

  GoogleSignIn get googleSignIn => _googleSignIn ?? GoogleSignIn.instance;
  FirebaseAuth get firebaseAuth => _firebaseAuth ?? FirebaseAuth.instance;

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
  /// Googleの軽量認証（attemptLightweightAuthentication）を試行し、
  /// ログイン済みであればその認証情報でサインイン、
  /// 未ログインまたは失敗時は匿名サインインを実行する。
  Future<void> initializeAuth({
    Future<void> Function(AuthCredential credential)? onSignInWithCredential,
    Future<void> Function()? onSignInAnonymously,
  }) async {
    final signInWithCredential = onSignInWithCredential ??
        (cred) async => await firebaseAuth.signInWithCredential(cred);
    final signInAnonymously = onSignInAnonymously ??
        () async => await firebaseAuth.signInAnonymously();

    try {
      final googleUser =
          await googleSignIn.attemptLightweightAuthentication();
      if (googleUser == null) {
        await signInAnonymously();
        debugPrint("Signed in anonymously");
      } else {
        final googleAuth = googleUser.authentication;
        await signInWithCredential(
          createGoogleCredential(idToken: googleAuth.idToken),
        );
        debugPrint("Signed in with Google user");
      }
    } catch (error) {
      debugPrint("Silent sign in error: $error");
      try {
        await signInAnonymously();
      } catch (e) {
        debugPrint("Anonymous sign in fallback error: $e");
      }
    }
  }

  /// Google アカウントの連携・サインイン処理
  ///
  /// Google認証を行い、現在のユーザーに連携（link）を試みる。
  /// すでに別のFirebaseアカウントに紐付いている場合や連携済みの場合は、そのアカウントでサインインする。
  Future<User?> handleGoogleSignIn({
    @Deprecated('fetchSignInMethodsForEmail is removed in firebase_auth 5+')
    Future<List<String>> Function(String email)? onFetchSignInMethods,
    Future<User?> Function(AuthCredential credential)? onSignInWithCredential,
    Future<User?> Function(AuthCredential credential)? onLinkWithCredential,
    Future<void> Function(User user)? onReloadUser,
  }) async {
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

      User? user;
      try {
        user = await linkWithCred(credential);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'credential-already-in-use' ||
            e.code == 'provider-already-linked') {
          debugPrint("${e.code}, signing in instead");
          user = await signInWithCred(credential);
        } else {
          rethrow;
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
